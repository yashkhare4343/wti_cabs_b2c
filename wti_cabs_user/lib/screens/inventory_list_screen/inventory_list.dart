import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/common_widget/loader/shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/inventory/search_cab_inventory_controller.dart';
import 'package:wti_cabs_user/core/model/inventory/global_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/booking_ride/booking_ride.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

import '../../core/controller/cab_booking/cab_booking_controller.dart';
import '../../core/controller/inventory_dialog_controller/inventory_dialog_controller.dart';
import '../../core/model/inventory/india_response.dart';
import '../../core/services/storage_services.dart';

class InventoryList extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const InventoryList({super.key, required this.requestData});

  @override
  State<InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends State<InventoryList> {
  final SearchCabInventoryController searchCabInventoryController = Get.find();
  final TripController tripController = Get.put(TripController());

 static const Map<String, String> tripMessages = {
    '0': 'Your selected trip type has changed to Outstation One Trip.',
    '1': 'Your selected trip type has changed to Outstation Round Trip.',
    '2': 'Your selected trip type has changed to Airport Trip.',
    '3': 'Your selected trip type has changed to Local.',
  };

  String? _country;
  bool isLoading = true;
  dynamic results;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchData();
      await loadInitialData();
    });
  }

  /// Load the country and check trip code change dialog
  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');
    await loadTripCode(context);
    setState(() {
      isLoading = false;
    });
  }

  /// Check for trip code changes and show dialog if needed
  Future<void> loadTripCode(BuildContext context) async {
    final current = await StorageServices.instance.read('currentTripCode') ?? '';
    final previous = await StorageServices.instance.read('previousTripCode') ?? '';

    // Show dialog only if codes differ and current is not empty
    if (mounted && current.isNotEmpty && current != previous) {
      final message = tripMessages[current] ?? 'Your selected trip type has changed.';

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            elevation: 10,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: const [
                Icon(Icons.update_outlined, color: Colors.blueAccent, size: 20),
                SizedBox(width: 10),
                Text('Trip Updated',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.mainButtonBg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      isLoading = false;
                    });
                  },
                  child: const Text('OK'),

                ),
              ),
            ],
          );
        },
      );
    }
  }

  /// Fetches booking data and handles loading/error state
  Future<void> _fetchData() async {
    setState(() => isLoading = true);

    try {
      await searchCabInventoryController.fetchBookingData(
        country: widget.requestData['countryName'],
        requestData: widget.requestData,
        context: context,
        isSecondPage: true,
      );

    } catch (e) {
      // Maybe log the error
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted){
          Navigator.pop(context);
          setState(() {
            isLoading = false;
          });
        }

      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

// Utilities remain the same
  num getFakePriceWithPercent(num baseFare, num percent) =>
      (baseFare * 100) / (100 - percent);

  num getFivePercentOfBaseFare(num baseFare) => baseFare * 0.05;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBgPrimary1,
        body: FullPageShimmer(),
      );
    }
    final isIndia = _country?.toLowerCase() == 'india';
    final indiaData = searchCabInventoryController.indiaData.value;
    final globalData = searchCabInventoryController.globalData.value;

    if (_country == null ||
        (isIndia && indiaData == null) ||
        (!isIndia && globalData == null)) {
      return Scaffold(
        body: Center(child: FullPageShimmer()),
      );
    }

    final indiaCarTypes = indiaData?.result?.inventory?.carTypes ?? [];
    final globalList = globalData?.result ?? [];


    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      body: isLoading
          ? FullPageShimmer()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookingTopBar(),
                    SizedBox(
                      height: 16,
                    ),
                    Expanded(
                      child: Obx(() {
                        final isIndia =
                            searchCabInventoryController.indiaData.value !=
                                null;
                        final indiaCarTypes = searchCabInventoryController
                                .indiaData.value?.result?.inventory?.carTypes ??
                            [];
                        final globalList = searchCabInventoryController
                                .globalData.value?.result ??
                            [];

                        final isEmptyList =
                            (isIndia && indiaCarTypes.isEmpty) ||
                                (!isIndia && globalList.isEmpty);

                        if (isEmptyList) {
                          return const Center(
                            child: Text(
                              "No cabs available on this route",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                                children: [
                                  TextSpan(text: 'Rates for '),
                                  TextSpan(
                                    text:
                                        '${searchCabInventoryController.indiaData.value?.result?.inventory?.carTypes?.first.baseKm} Kms',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: ' approx distance | '),
                                  TextSpan(
                                    text: '4.5 hr(s)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: ' approx time'),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: isIndia
                                    ? indiaCarTypes.length
                                    : globalList.length,
                                itemBuilder: (context, index) {
                                  if (isIndia) {
                                    final carType = indiaCarTypes[index];
                                    return _buildIndiaCard(carType);
                                  } else {
                                    final globalListItem = globalList[index];
                                    final tripDetails = globalListItem
                                        .firstWhereOrNull(
                                            (e) => e.tripDetails != null)
                                        ?.tripDetails;
                                    final fareDetails = globalListItem
                                        .firstWhereOrNull(
                                            (e) => e.fareDetails != null)
                                        ?.fareDetails;
                                    final vehicleDetails = globalListItem
                                        .firstWhereOrNull(
                                            (e) => e.vehicleDetails != null)
                                        ?.vehicleDetails;

                                    if (tripDetails == null ||
                                        fareDetails == null ||
                                        vehicleDetails == null) {
                                      return const SizedBox();
                                    }

                                    return _buildGlobalCard(tripDetails,
                                        fareDetails, vehicleDetails);
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIndiaCard(CarType carType) {
    final tripCode = searchCabInventoryController
        .indiaData.value?.result?.tripType?.currentTripCode;
    final CabBookingController cabBookingController =
        Get.put(CabBookingController());
    final tripTypeDetails =
        searchCabInventoryController.indiaData.value?.result?.tripType;

    num calculateOriginalPrice(num baseFare, num discountPercent) {
      return baseFare + (baseFare * discountPercent / 100);
    }

    num originalPrice = calculateOriginalPrice(
        carType.fareDetails?.baseFare ?? 0, carType.fakePercentageOff ?? 0);

    Text(
      '₹${originalPrice.toStringAsFixed(0)}',
      style: TextStyle(
        decoration: TextDecoration.lineThrough,
        color: Colors.grey,
        fontSize: 14,
      ),
    );
    Text(
      '₹${originalPrice.toStringAsFixed(0)}',
      style: TextStyle(
        decoration: TextDecoration.lineThrough,
        color: Colors.grey,
        fontSize: 14,
      ),
    );
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () async {
        final country = await StorageServices.instance.read('country');

        Future<bool> isGlobal() async {
          final country = await StorageServices.instance.read('country');
          return country?.toLowerCase() != 'india';
        }

        print(
            "inventory start time and endtime : ${tripTypeDetails?.startTime?.toIso8601String() ?? ''}, ${tripTypeDetails?.endTime?.toIso8601String() ?? ''}");

        final Map<String, dynamic> requestData = {
          "isGlobal": false,
          "country": country,
          "routeInventoryId": carType.routeId,
          "vehicleId": null,
          "trip_type": carType.tripType,
          "pickUpDateTime": tripTypeDetails?.startTime?.toIso8601String() ?? '',
          "dropDateTime": tripTypeDetails?.endTime?.toIso8601String() ?? '',
          "totalKilometers": tripTypeDetails?.distanceBooked ?? 0,
          "package_id": tripTypeDetails?.packageId ?? '',
          "source": {
            "address": tripTypeDetails?.source?.address ?? '',
            "latitude": tripTypeDetails?.source?.latitude,
            "longitude": tripTypeDetails?.source?.longitude,
            "city": tripTypeDetails?.source?.city
          },
          "destination": {
            "address": tripTypeDetails?.destination?.address ?? '',
            "latitude": tripTypeDetails?.destination?.latitude,
            "longitude": tripTypeDetails?.destination?.longitude,
            "city": tripTypeDetails?.destination?.city
          },
          "tripCode": tripCode,
          // Conditional key based on global/india
          "trip_type_details": {
            "basic_trip_type":
                tripTypeDetails?.tripTypeDetails?.basicTripType ?? '',
            "airport_type": tripTypeDetails?.tripTypeDetails?.airportType ?? ''
          },
        };

        cabBookingController.fetchBookingData(
            country: country ?? '', requestData: requestData, context: context);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              elevation: 0.3,
              margin: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Image.network(
                          carType.carImageUrl ?? '',
                          width: 80,
                          height: 50,
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Color(0xFFE3F2FD),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            side: const BorderSide(
                                color: Colors.transparent, width: 1),
                            foregroundColor: Color(0xFF1565C0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            carType.type ?? '',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        )
                      ],
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  carType.carTagLine ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18),
                                  overflow: TextOverflow.clip,
                                  maxLines: 1,
                                ),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.mainButtonBg,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  side: const BorderSide(
                                      color: AppColors.mainButtonBg, width: 1),
                                  foregroundColor: Colors.white,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () {},
                                child: Text(
                                  carType.combustionType != null
                                      ? carType.combustionType ?? ''
                                      : "",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              )
                            ],
                          ),
                          Text('or similar',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: Colors.grey[600])),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Text("${carType.seats} Seats",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                      color: Colors.grey[700])),
                              SizedBox(width: 8),
                              Text("• ${carType.luggageCapacity}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                      color: Colors.grey[700])),
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text(
                                      "${carType.fakePercentageOff.toString() ?? ''}%",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 6),
                                  Text(
                                    "₹${originalPrice}",
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    "₹ ${carType.fareDetails?.baseFare?.toInt() ?? ''}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                  '+ ${getFivePercentOfBaseFare(carType.fareDetails?.baseFare?.toInt() ?? 0).truncate()} (taxes & charges)',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.greyBorder1, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.network(
                    carType.carImageUrl ?? '',
                    width: 66,
                    height: 66,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/inventory_car.png',
                        height: 66,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Transform.translate(
                                  offset: Offset(0, -5),
                                  child: Text(carType.carTagLine ?? '',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.mainButtonBg))),
                              Transform.translate(
                                offset: Offset(0, -5),
                                child: Row(
                                  children: [
                                    Text(
                                        carType.rating?.ratePoints.toString() ??
                                            '',
                                        style: CommonFonts.bodyText1),
                                    const SizedBox(width: 4),
                                    Icon(Icons.star,
                                        color: AppColors.yellow1, size: 12),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    Icon(Icons.airline_seat_recline_extra,
                                        size: 13),
                                    const SizedBox(width: 4),
                                    Text('${carType.seats} Seat',
                                        style: CommonFonts.bodyTextXS),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.luggage_outlined, size: 13),
                                  const SizedBox(width: 4),
                                  Text('${carType.luggageCapacity}',
                                      style: CommonFonts.bodyTextXS),
                                  const SizedBox(width: 8),
                                  Icon(Icons.speed_outlined, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    tripCode != "3"
                                        ? '${searchCabInventoryController.indiaData.value?.result?.inventory?.distanceBooked} km'
                                        : ' km',
                                    style: CommonFonts.bodyTextXS,
                                  ),
                                ],
                              )
                              // const SizedBox(height: 6),
                              // Row(
                              //   children: [
                              //     Icon(Icons.airline_seat_recline_extra, size: 13),
                              //     const SizedBox(width: 4),
                              //     Text('${carType.seats} Seat', style: CommonFonts.bodyTextXS),
                              //     const SizedBox(width: 8),
                              //     Icon(Icons.luggage_outlined, size: 13),
                              //     const SizedBox(width: 4),
                              //     Text('${carType.luggageCapacity}', style: CommonFonts.bodyTextXS),
                              //     const SizedBox(width: 8),
                              //     Icon(Icons.speed_outlined, size: 13),
                              //     const SizedBox(width: 4),
                              //
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(10, 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                      "₹ ${carType.fareDetails?.baseFare?.toString() ?? ''}",
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black)),
                                ],
                              ),

                              Text(
                                  '+ ${getFivePercentOfBaseFare(carType.fareDetails?.baseFare ?? 0).truncate()} (taxes & charges)',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.greyText4)),
                              SizedBox(
                                height: 8,
                              ),
                              SizedBox(
                                height: 25,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    side: const BorderSide(
                                        color: AppColors.mainButtonBg,
                                        width: 1),
                                    foregroundColor: Colors.white,
                                    backgroundColor: AppColors.mainButtonBg,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final country = await StorageServices
                                        .instance
                                        .read('country');

                                    Future<bool> isGlobal() async {
                                      final country = await StorageServices
                                          .instance
                                          .read('country');
                                      return country?.toLowerCase() != 'india';
                                    }

                                    print(
                                        "inventory start time and endtime : ${tripTypeDetails?.startTime?.toIso8601String() ?? ''}, ${tripTypeDetails?.endTime?.toIso8601String() ?? ''}");

                                    final Map<String, dynamic> requestData = {
                                      "isGlobal": false,
                                      "country": country,
                                      "routeInventoryId": carType.routeId,
                                      "vehicleId": null,
                                      "trip_type": carType.tripType,
                                      "pickUpDateTime": tripTypeDetails
                                              ?.startTime
                                              ?.toIso8601String() ??
                                          '',
                                      "dropDateTime": tripTypeDetails?.endTime
                                              ?.toIso8601String() ??
                                          '',
                                      "totalKilometers":
                                          tripTypeDetails?.distanceBooked ?? 0,
                                      "package_id":
                                          tripTypeDetails?.packageId ?? '',
                                      "source": {
                                        "address":
                                            tripTypeDetails?.source?.address ??
                                                '',
                                        "latitude":
                                            tripTypeDetails?.source?.latitude,
                                        "longitude":
                                            tripTypeDetails?.source?.longitude,
                                        "city": tripTypeDetails?.source?.city
                                      },
                                      "destination": {
                                        "address": tripTypeDetails
                                                ?.destination?.address ??
                                            '',
                                        "latitude": tripTypeDetails
                                            ?.destination?.latitude,
                                        "longitude": tripTypeDetails
                                            ?.destination?.longitude,
                                        "city":
                                            tripTypeDetails?.destination?.city
                                      },
                                      "tripCode": tripCode,
                                      // Conditional key based on global/india
                                      "trip_type_details": {
                                        "basic_trip_type": tripTypeDetails
                                                ?.tripTypeDetails
                                                ?.basicTripType ??
                                            '',
                                        "airport_type": tripTypeDetails
                                                ?.tripTypeDetails
                                                ?.airportType ??
                                            ''
                                      },
                                    };

                                    cabBookingController.fetchBookingData(
                                        country: country ?? '',
                                        requestData: requestData,
                                        context: context);
                                  },
                                  child: const Text(
                                    'Book Now',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              )

                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //   children: [
                              //     Column(
                              //       crossAxisAlignment: CrossAxisAlignment.start,
                              //       children: [
                              //         Text("₹ ${carType.fareDetails?.baseFare?.toString() ?? ''}", style: CommonFonts.greyText3Bold),
                              //         Text('+ ${getFivePercentOfBaseFare(carType.fareDetails?.baseFare ?? 0).truncate()} (taxes & charges)', style: CommonFonts.greyText3),
                              //
                              //       ],
                              //     ),
                              //     MainButton(text: 'Book Now', onPressed: () async{
                              //       final country = await StorageServices.instance
                              //           .read('country');
                              //
                              //       Future<bool> isGlobal() async {
                              //         final country = await StorageServices.instance.read('country');
                              //         return country?.toLowerCase() != 'india';
                              //       }
                              //
                              //       print("inventory start time and endtime : ${tripTypeDetails?.startTime?.toIso8601String()??''}, ${tripTypeDetails?.endTime?.toIso8601String()??''}");
                              //
                              //     final Map<String, dynamic> requestData = {
                              //       "isGlobal": false,
                              //       "country": country,
                              //       "routeInventoryId": carType.routeId,
                              //       "vehicleId": null,
                              //       "trip_type": carType.tripType,
                              //       "pickUpDateTime": tripTypeDetails?.startTime?.toIso8601String()??'',
                              //       "dropDateTime": tripTypeDetails?.endTime?.toIso8601String()??'',
                              //       "totalKilometers": tripTypeDetails?.distanceBooked??0,
                              //       "package_id": tripTypeDetails?.packageId??'',
                              //       "source": {
                              //         "address": tripTypeDetails?.source?.address??'',
                              //         "latitude": tripTypeDetails?.source?.latitude,
                              //         "longitude": tripTypeDetails?.source?.longitude,
                              //         "city": tripTypeDetails?.source?.city
                              //       },
                              //       "destination": {
                              //         "address": tripTypeDetails?.destination?.address??'',
                              //         "latitude": tripTypeDetails?.destination?.latitude,
                              //         "longitude": tripTypeDetails?.destination?.longitude,
                              //         "city": tripTypeDetails?.destination?.city
                              //       },
                              //       "tripCode": tripCode,
                              //       // Conditional key based on global/india
                              //       "trip_type_details": {
                              //       "basic_trip_type": tripTypeDetails?.tripTypeDetails?.basicTripType??'',
                              //       "airport_type": tripTypeDetails?.tripTypeDetails?.airportType??''
                              //       },
                              //     };
                              //
                              //
                              //       cabBookingController.fetchBookingData(country: country??'', requestData: requestData, context: context);
                              //     }),
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const Icon(Icons.info_outline, size: 16),
                ],
              ),
              // const Divider(height: 16),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text("₹ ${carType.fareDetails?.baseFare?.toString() ?? ''}", style: CommonFonts.greyText3Bold),
              //         Text('+ ${getFivePercentOfBaseFare(carType.fareDetails?.baseFare ?? 0).truncate()} (taxes & charges)', style: CommonFonts.greyText3),
              //
              //       ],
              //     ),
              //     MainButton(text: 'Book Now', onPressed: () async{
              //       final country = await StorageServices.instance
              //           .read('country');
              //
              //       Future<bool> isGlobal() async {
              //         final country = await StorageServices.instance.read('country');
              //         return country?.toLowerCase() != 'india';
              //       }
              //
              //       print("inventory start time and endtime : ${tripTypeDetails?.startTime?.toIso8601String()??''}, ${tripTypeDetails?.endTime?.toIso8601String()??''}");
              //
              //     final Map<String, dynamic> requestData = {
              //       "isGlobal": false,
              //       "country": country,
              //       "routeInventoryId": carType.routeId,
              //       "vehicleId": null,
              //       "trip_type": carType.tripType,
              //       "pickUpDateTime": tripTypeDetails?.startTime?.toIso8601String()??'',
              //       "dropDateTime": tripTypeDetails?.endTime?.toIso8601String()??'',
              //       "totalKilometers": tripTypeDetails?.distanceBooked??0,
              //       "package_id": tripTypeDetails?.packageId??'',
              //       "source": {
              //         "address": tripTypeDetails?.source?.address??'',
              //         "latitude": tripTypeDetails?.source?.latitude,
              //         "longitude": tripTypeDetails?.source?.longitude,
              //         "city": tripTypeDetails?.source?.city
              //       },
              //       "destination": {
              //         "address": tripTypeDetails?.destination?.address??'',
              //         "latitude": tripTypeDetails?.destination?.latitude,
              //         "longitude": tripTypeDetails?.destination?.longitude,
              //         "city": tripTypeDetails?.destination?.city
              //       },
              //       "tripCode": tripCode,
              //       // Conditional key based on global/india
              //       "trip_type_details": {
              //       "basic_trip_type": tripTypeDetails?.tripTypeDetails?.basicTripType??'',
              //       "airport_type": tripTypeDetails?.tripTypeDetails?.airportType??''
              //       },
              //     };
              //
              //
              //       cabBookingController.fetchBookingData(country: country??'', requestData: requestData, context: context);
              //     }),
              //   ],
              // ),
              SizedBox(
                height: 8,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalCard(GlobalTripDetails tripDetails,
      GlobalFareDetails fareDetails, GlobalVehicleDetails vehicleDetails) {
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () async {
        final country = await StorageServices.instance.read('country');
        final CabBookingController cabBookingController =
            Get.put(CabBookingController());
        final Map<String, dynamic> requestData = {
          "isGlobal": false,
          "country": country,
          "routeInventoryId": fareDetails.id,
          "vehicleId": vehicleDetails.id,
          "trip_type": fareDetails.tripType,
          "pickUpDateTime": tripDetails?.pickupDateTime ?? '',
          "dropDateTime": tripDetails.dropDateTime ?? '',
          "totalKilometers": tripDetails.totalDistance ?? 0,
          "package_id": null,
          "source": {},
          "destination": {},
          "tripCode": tripDetails.currentTripCode,
          // Conditional key based on global/india
          "trip_type_details": {
            "basic_trip_type": searchCabInventoryController
                    .globalData.value?.tripTypeDetails?.basicTripType ??
                '',
            "airport_type": searchCabInventoryController
                    .globalData.value?.tripTypeDetails?.airportType ??
                ''
          },
        };
        cabBookingController.fetchBookingData(
            country: country ?? '', requestData: requestData, context: context);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text.rich(
            //   TextSpan(
            //     style: TextStyle(
            //       fontSize: 12,
            //       fontWeight: FontWeight.w500,
            //       color: Color(0xFF333333),
            //     ),
            //     children: [
            //       TextSpan(text: 'Rates for '),
            //       TextSpan(
            //         text: '${carType.baseKm} Kms',
            //         style: TextStyle(fontWeight: FontWeight.bold),
            //       ),
            //       TextSpan(text: ' approx distance | '),
            //       TextSpan(
            //         text: '4.5 hr(s)',
            //         style: TextStyle(fontWeight: FontWeight.bold),
            //       ),
            //       TextSpan(text: ' approx time'),
            //     ],
            //   ),
            // ),

            SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 0.3,
              margin: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Image.network(
                          vehicleDetails.vehicleImageLink ?? '',
                          width: 80,
                          height: 50,
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Color(0xFFE3F2FD),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            side: const BorderSide(
                                color: Colors.transparent, width: 1),
                            foregroundColor: Color(0xFF1565C0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            vehicleDetails.filterCategory ?? '',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        )
                      ],
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  vehicleDetails.title ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                  overflow: TextOverflow.clip,
                                  maxLines: 1,
                                ),
                              ),

                              SizedBox(width: 6),
                              // OutlinedButton(
                              //   style: OutlinedButton.styleFrom(
                              //     backgroundColor: AppColors.mainButtonBg,
                              //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              //     minimumSize: Size.zero,
                              //     side: const BorderSide(color: AppColors.mainButtonBg, width: 1),
                              //     foregroundColor: Colors.white,
                              //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              //     visualDensity: VisualDensity.compact,
                              //     shape: RoundedRectangleBorder(
                              //       borderRadius: BorderRadius.circular(6),
                              //     ),
                              //   ),
                              //   onPressed: (){},
                              //   child: Text(
                              //     vehicleDetails.fuelType,
                              //     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              //   ),
                              // )
                            ],
                          ),
                          // Text('or similar', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12, color: Colors.grey[600])),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.mainButtonBg,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              side: const BorderSide(
                                  color: AppColors.mainButtonBg, width: 1),
                              foregroundColor: Colors.white,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () {},
                            child: Text(
                              vehicleDetails.fuelType,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),

                          SizedBox(height: 6),
                          Row(
                            children: [
                              Text("${vehicleDetails.passengerCapacity} Seats",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                      color: Colors.grey[700])),
                              SizedBox(width: 8),
                              Text(
                                  "• ${vehicleDetails.checkinLuggageCapacity} bags",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                      color: Colors.grey[700])),
                            ],
                          )
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Row(
                        //   children: [
                        //     Text("${}%",
                        //         style: TextStyle(
                        //             fontSize: 12,
                        //             color: Colors.green, fontWeight: FontWeight.w500)),
                        //     SizedBox(width: 6),
                        //
                        //     Text(
                        //       "₹${originalPrice}",
                        //       style: TextStyle(
                        //         decoration: TextDecoration.lineThrough,
                        //         color: Colors.grey,
                        //         fontSize: 11,
                        //       ),
                        //     ),
                        //
                        //   ],
                        // ),
                        SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "USD ${fareDetails.baseFare ?? ''}",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                            '+ ${getFivePercentOfBaseFare(fareDetails.baseFare ?? 0).truncate()} (taxes & charges)',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 11)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Widget _buildGlobalCard(GlobalTripDetails tripDetails, GlobalFareDetails fareDetails, GlobalVehicleDetails vehicleDetails) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16.0),
  //     child: Card(
  //       color: Colors.white,
  //       elevation: 0,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         side: BorderSide(color: AppColors.greyBorder1, width: 1),
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  //         child: Column(
  //           children: [
  //             Row(
  //               crossAxisAlignment: CrossAxisAlignment.end,
  //               children: [
  //                 Image.network(
  //                   vehicleDetails?.vehicleImageLink??'',
  //                   width: 66,
  //                   height: 66,
  //                   fit: BoxFit.contain,
  //                   errorBuilder: (context, error, stackTrace) {
  //                     return Image.asset(
  //                       'assets/images/inventory_car.png',
  //                       width: 66,
  //                       height: 66,
  //                       fit: BoxFit.contain,
  //                     );
  //                   },
  //                 ),                    const SizedBox(width: 16),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(vehicleDetails.title ?? '', style: CommonFonts.bodyText1Bold),
  //                       const SizedBox(height: 4),
  //                       Row(
  //                         children: [
  //                           Text(vehicleDetails.rating.toString(), style: CommonFonts.bodyText1),
  //                           const SizedBox(width: 4),
  //                           Icon(Icons.star, color: AppColors.yellow1, size: 12),
  //                           const SizedBox(width: 4),
  //                           Text('${vehicleDetails.reviews.toString()} Reviews', style: CommonFonts.bodyText1),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 6),
  //                       Row(
  //                         children: [
  //                           Icon(Icons.luggage_outlined, size: 13),
  //                           const SizedBox(width: 4),
  //                           Text('${vehicleDetails.checkinLuggageCapacity} Check-in Luggage', style: CommonFonts.bodyTextXS),
  //                           const SizedBox(width: 8),
  //                           Icon(Icons.airline_seat_recline_extra, size: 13),
  //                           const SizedBox(width: 4),
  //                           Text('${vehicleDetails.passengerCapacity} Passenger', style: CommonFonts.bodyTextXS),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 const Icon(Icons.info_outline, size: 16),
  //               ],
  //             ),
  //             const Divider(height: 16),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text("USD ${tripDetails.totalFare.toString()}", style: CommonFonts.greyText3Bold),
  //                     Text('+ ${getFivePercentOfBaseFare(tripDetails.totalFare).truncate()} (taxes & charges)', style: CommonFonts.greyText3),
  //                     const SizedBox(height: 6),
  //                     Text(
  //                       'Book Now and Get Rs ${(getFakePriceWithPercent(tripDetails.totalFare ?? 0, 20).truncate()) - (tripDetails.totalFare ?? 0)} OFF*',
  //                       style: CommonFonts.organgeText1,
  //                     ),
  //                   ],
  //                 ),
  //                 MainButton(text: 'Book Now', onPressed: () async{
  //                   final country = await StorageServices.instance
  //                       .read('country');
  //                   final CabBookingController cabBookingController = Get.put(CabBookingController());
  //                   final Map<String, dynamic> requestData = {
  //                     "isGlobal": false,
  //                     "country": country,
  //                     "routeInventoryId": fareDetails.id,
  //                     "vehicleId": vehicleDetails.id,
  //                     "trip_type": fareDetails.tripType,
  //                     "pickUpDateTime": tripDetails?.pickupDateTime??'',
  //                     "dropDateTime": tripDetails.dropDateTime??'',
  //                     "totalKilometers": tripDetails.totalDistance??0,
  //                     "package_id": null,
  //                     "source": {},
  //                     "destination": {},
  //                     "tripCode": tripDetails.currentTripCode,
  //                     // Conditional key based on global/india
  //                     "trip_type_details": {
  //                       "basic_trip_type": searchCabInventoryController.globalData.value?.tripTypeDetails?.basicTripType??'',
  //                       "airport_type": searchCabInventoryController.globalData.value?.tripTypeDetails?.airportType??''
  //                     },
  //                   };
  //                   cabBookingController.fetchBookingData(country: country??'', requestData: requestData, context: context);
  //                 }),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

// Booking Top Bar

class BookingTopBar extends StatefulWidget {
  @override
  State<BookingTopBar> createState() => _BookingTopBarState();
}

class _BookingTopBarState extends State<BookingTopBar> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentTripCode();
  }

  String _monthName(int month) {
    const months = [
      '', // 0th index unused
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  String formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthName(dateTime.month);
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month, $year, $hour:$minute hrs';
  }

  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  String? tripCode;

  void getCurrentTripCode() async {
    tripCode = await StorageServices.instance.read('currentTripCode');
    setState(() {});
    print('yash trip code : $tripCode');
  }

  String trimAfterTwoSpaces(String input) {
    final parts = input.split(' ');
    if (parts.length <= 2)
      return input; // less than or equal to two spaces, keep as is
    return parts.take(2).join(' '); // first 3 words (2 spaces)
  }
  Future<void> loadTripCode(BuildContext context) async {
    final current = await StorageServices.instance.read('currentTripCode') ?? '';
    final previous = await StorageServices.instance.read('previousTripCode') ?? '';

    final tripMessages = {
      '0': 'Your selected trip type has changed to Outstation One Trip.',
      '1': 'Your selected trip type has changed to Outstation Round Trip.',
      '2': 'Your selected trip type has changed to Airport Trip.',
      '3': 'Your selected trip type has changed to Local.',
    };

    // Show dialog only if codes differ and current is not empty
    if (current.isNotEmpty && current != previous) {
      final message = tripMessages[current] ?? 'Your selected trip type has changed.';

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            elevation: 10,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: const [
                Icon(Icons.update_outlined, color: Colors.blueAccent, size: 20),
                SizedBox(width: 10),
                Text(
                  'Trip Updated',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          );
        },
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final pickupDateTime = bookingRideController.localStartTime.value;
    final formattedPickup = formatDateTime(pickupDateTime);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // 8px radius
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000), // #0000000A with 4% opacity
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        leading: GestureDetector(
            onTap: () {
              GoRouter.of(context).pop();
            },
            child: Icon(Icons.arrow_back, size: 20)),
        title: Row(
          children: [
            Text(
              '${trimAfterTwoSpaces(bookingRideController.prefilled.value)} To ${trimAfterTwoSpaces(bookingRideController.prefilledDrop.value)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
            SizedBox(
              width: 8,
            ),
            GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => TopBookingDialogWrapper(),
                  );
                },
                child:
                    Icon(Icons.edit, size: 16, color: AppColors.mainButtonBg)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Row(
            children: [
              Text(
                formattedPickup,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.greyText5,
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
              const SizedBox(width: 8),
              if (tripCode == '0')
                Text(
                  'Outstation One Way Trip',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mainButtonBg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (tripCode == '1')
                Text(
                  'Outstation One Way Trip',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mainButtonBg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (tripCode == '2')
                Text(
                  'Airport Trip',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mainButtonBg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (tripCode == '3')
                Text(
                  'Rental Trip',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mainButtonBg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopBookingDialogWrapper extends StatefulWidget {
  const TopBookingDialogWrapper({super.key});

  @override
  State<TopBookingDialogWrapper> createState() =>
      _TopBookingDialogWrapperState();
}

class _TopBookingDialogWrapperState extends State<TopBookingDialogWrapper> {
  final SearchCabInventoryController searchCabInventoryController = Get.find();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    searchCabInventoryController.loadTripCode();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
          child: SizedBox(
            width: double.infinity, // almost full screen
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(
                  () => Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.13,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (searchCabInventoryController.tripCode.value ==
                                  '0')
                                Text(
                                  'OutStation One Way',
                                  style: CommonFonts.greyText3Bold,
                                ),
                              if (searchCabInventoryController.tripCode.value ==
                                  '1')
                                Text(
                                  'OutStation Round Way',
                                  style: CommonFonts.greyText3Bold,
                                ),
                              if (searchCabInventoryController.tripCode.value ==
                                  '2')
                                Text(
                                  'Airport',
                                  style: CommonFonts.greyText3Bold,
                                ),
                              if (searchCabInventoryController.tripCode.value ==
                                  '3')
                                Text(
                                  'Rental',
                                  style: CommonFonts.greyText3Bold,
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      if (searchCabInventoryController.tripCode.value == '0')
                        OutStation(),
                      if (searchCabInventoryController.tripCode.value == '1')
                        OutStation(),
                      if (searchCabInventoryController.tripCode.value == '2')
                        Rides(),
                      if (searchCabInventoryController.tripCode.value == '3')
                        Rental(),
                      SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                )),
          ),
        ),
      ],
    );
  }
}

class BookNowChipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const BookNowChipButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: const Text(
        'Book Now',
        style: TextStyle(
          fontSize: 8,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppColors.mainButtonBg,
      onPressed: onPressed,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

Widget _buildShimmer() {
  return Column(
    children: [
      SizedBox(
        height: 40,
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: ShimmerWidget.rectangular(
          height: 50,
          width: double.infinity,
        ),
      ),
      SizedBox(
        height: 16,
      ),
      Expanded(
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.all(8),
            child: ShimmerWidget.rectangular(
              height: 50,
              width: double.infinity,
            ),
          ),
        ),
      ),
    ],
  );
}

class ShimmerWidget extends StatelessWidget {
  final double height;
  final double width;

  const ShimmerWidget.rectangular({
    super.key,
    required this.height,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
}

class StaticBookingTopBar extends StatelessWidget {
  const StaticBookingTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pickup Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pickup",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Connaught Place, Delhi",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  "Sat, 10 Aug · 09:00 AM",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Swap Icon
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.swap_vert,
              size: 20,
              color: Colors.black54,
            ),
          ),

          // Drop Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Drop",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Jaipur, Rajasthan",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  "Sat, 10 Aug · 02:00 PM",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
