import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/common_widget/loader/shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/inventory/search_cab_inventory_controller.dart';
import 'package:wti_cabs_user/core/model/inventory/global_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/booking_details_final/booking_details_final.dart';
import 'package:wti_cabs_user/screens/booking_ride/booking_ride.dart';
import 'package:wti_cabs_user/screens/map_picker/map_picker.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

import '../../common_widget/dropdown/common_dropdown.dart';
import '../../core/controller/cab_booking/cab_booking_controller.dart';
import '../../core/controller/choose_drop/choose_drop_controller.dart';
import '../../core/controller/currency_controller/currency_controller.dart';
import '../../core/controller/inventory_dialog_controller/inventory_dialog_controller.dart';
import '../../core/controller/rental_controller/fetch_package_controller.dart';
import '../../core/model/inventory/india_response.dart';
import '../../core/services/storage_services.dart';
import 'package:timezone/timezone.dart' as tz;

import '../bottom_nav/bottom_nav.dart';

class InventoryList extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final bool? fromFinalBookingPage;

  const InventoryList({super.key, required this.requestData, this.fromFinalBookingPage});

  @override
  State<InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends State<InventoryList> {
  final SearchCabInventoryController searchCabInventoryController = Get.find();
  final TripController tripController = Get.put(TripController());
  final FetchPackageController fetchPackageController =
      Get.put(FetchPackageController());
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());

  static const Map<String, String> tripMessages = {
    '0': 'Your selected trip type has changed to Outstation One Way Trip.',
    '1': 'Your selected trip type has changed to Outstation Round Way Trip.',
    '2': 'Your selected trip type has changed to Airport Trip.',
    '3': 'Your selected trip type has changed to Local.',
  };

  String? _country;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchData();
      await loadInitialData();
      bookingRideController.requestData.value = widget.requestData;
    });
  }

  /// Load the country and check trip code change dialog after UI is rendered
  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');
    setState(() {
      isLoading = false;
    });
    // Show dialog after data is loaded and UI is rendered
    if (mounted) {
     widget.fromFinalBookingPage == true ? null : await loadTripCode(context);
    }
  }

  /// Check for trip code changes and show dialog if needed
  Future<void> loadTripCode(BuildContext context) async {
    final current =
        await StorageServices.instance.read('currentTripCode') ?? '';
    final previous =
        await StorageServices.instance.read('previousTripCode') ?? '';

    if (mounted && current.isNotEmpty && current != previous) {
      final message =
          tripMessages[current] ?? 'Your selected trip type has changed.';
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
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

  /// Fetches booking data and handles loading/error state
  Future<void> _fetchData() async {
    try {
      await searchCabInventoryController.fetchBookingData(
        country: widget.requestData['countryName'],
        requestData: widget.requestData,
        context: context,
        isSecondPage: true,
      );
    } catch (e) {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(context);
      }
    }
  }

  num getFakePriceWithPercent(num baseFare, num percent) =>
      (baseFare * 100) / (100 - percent);
  num getFivePercentOfBaseFare(num baseFare) => baseFare * 0.05;
  final DropPlaceSearchController dropPlaceSearchController =
      Get.put(DropPlaceSearchController());
  final CurrencyController currencyController = Get.find<CurrencyController>();

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          bookingRideController.selectedIndex.value = 0;
          final tabName = bookingRideController.currentTabName;
          final route = tabName == 'rental'
              ? '${AppRoutes.bookingRide}?tab=airport'
              : '${AppRoutes.bookingRide}?tab=airport';
          GoRouter.of(context).push(
              route,
              extra: (context) => Platform.isIOS
              ? CupertinoPage(child: const BottomNavScreen())
              : MaterialPage(child: const BottomNavScreen()));
        },
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBgPrimary1,
          body: FullPageShimmer(),
        ),
      );
    }

    final isIndia = _country?.toLowerCase() == 'india';
    final indiaData = searchCabInventoryController.indiaData.value;
    final globalData = searchCabInventoryController.globalData.value;

    if (_country == null ||
        (isIndia && indiaData == null) ||
        (!isIndia && globalData == null)) {
      return PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          bookingRideController.selectedIndex.value = 0;
          final tabName = bookingRideController.currentTabName;
          final route = tabName == 'rental'
              ? '${AppRoutes.bookingRide}?tab=airport'
              : '${AppRoutes.bookingRide}?tab=airport';
          GoRouter.of(context).push(
              route,
              extra: (context) => Platform.isIOS
                  ? CupertinoPage(child: const BottomNavScreen())
                  : MaterialPage(child: const BottomNavScreen()));
        },
        child: Scaffold(
          body: Center(child: FullPageShimmer()),
        ),
      );
    }

    final indiaCarTypes = indiaData?.result?.inventory?.carTypes ?? [];
    final globalList = globalData?.result ?? [];

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        bookingRideController.selectedIndex.value = 0;
        final tabName = bookingRideController.currentTabName;
        final route = tabName == 'rental'
            ? '${AppRoutes.bookingRide}?tab=airport'
            : '${AppRoutes.bookingRide}?tab=airport';
        GoRouter.of(context).push(
            route,
            extra: (context) => Platform.isIOS
                ? CupertinoPage(child: const BottomNavScreen())
                : MaterialPage(child: const BottomNavScreen()));

      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBgPrimary1,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookingTopBar(),
                // Column(
                //   children: [
                //     SelectedPackageCard(controller: fetchPackageController),
                //   ],
                // ),
                Expanded(
                  child: Obx(() {
                    final isIndia =
                        searchCabInventoryController.indiaData.value != null;
                    final indiaCarTypes = searchCabInventoryController
                            .indiaData.value?.result?.inventory?.carTypes ??
                        [];
                    final globalList =
                        searchCabInventoryController.globalData.value?.result ??
                            [];
                    final isEmptyList = (isIndia && indiaCarTypes.isEmpty) ||
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

                    if ((placeSearchController.getPlacesLatLng.value?.country !=
                            dropPlaceSearchController
                                .dropLatLng.value?.country) &&
                        (indiaCarTypes.isNotEmpty &&
                            indiaCarTypes.first.tripType != 'LOCAL_RENTAL')) {
                      return const Center(
                        child: Text(
                          "No cabs available on this route, Please search on same country for pickup and drop",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                            children: [
                              const TextSpan(text: 'Rates for '),
                              _country?.toLowerCase() == 'india'
                                  ? TextSpan(
                                      text:
                                          '${searchCabInventoryController.indiaData.value?.result?.tripType?.distanceBooked ?? int.parse(searchCabInventoryController.indiaData.value?.result?.tripType?.packageId?.split("_")[1] ?? '0')} Kms',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  : TextSpan(
                                      text:
                                          '${searchCabInventoryController.globalData.value?.result.first.first.tripDetails?.totalDistance} kms'),
                              const TextSpan(text: ' approx distance | '),
                              _country?.toLowerCase() == 'india'
                                  ? TextSpan(
                                      text:
                                          '${(DateTime.parse(searchCabInventoryController.indiaData.value?.result?.tripType?.endTime.toString() ?? '').difference(DateTime.parse(searchCabInventoryController.indiaData.value?.result?.tripType?.startTime.toString() ?? '')).inMinutes / 60).toStringAsFixed(2)} hrs',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  : TextSpan(
                                      text:
                                          '${(DateTime.parse(searchCabInventoryController.globalData.value?.result.first.first.tripDetails?.dropDateTime ?? '').difference(DateTime.parse(searchCabInventoryController.globalData.value?.result.first.first.tripDetails?.pickupDateTime ?? '')).inMinutes / 60).toStringAsFixed(2)} hrs',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                              const TextSpan(text: ' approx time'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
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

                                return _buildGlobalCard(
                                    tripDetails, fareDetails, vehicleDetails);
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
      ),
    );
  }

  Widget _buildIndiaCard(CarType carType) {
    final tripCode = searchCabInventoryController
        .indiaData.value?.result?.tripType?.currentTripCode;
    final CabBookingController cabBookingController =
        Get.put(CabBookingController());
    final CurrencyController currencyController = Get.put(CurrencyController());
    final tripTypeDetails =
        searchCabInventoryController.indiaData.value?.result?.tripType;

    num calculateOriginalPrice(num baseFare, num discountPercent) {
      return baseFare + (baseFare * discountPercent / 100);
    }

    num originalPrice = calculateOriginalPrice(
        carType.fareDetails?.baseFare ?? 0, carType.fakePercentageOff ?? 0);

    return InkWell(
      splashColor: Colors.transparent,
      onTap: () async {
        final country = await StorageServices.instance.read('country');
        final Map<String, dynamic> requestData = {
          "isGlobal": false,
          "country": country,
          "routeInventoryId": carType.routeId,
          "vehicleId": null,
          "trip_type": carType.tripType,
          "pickUpDateTime": tripTypeDetails?.startTime?.toIso8601String() ?? '',
          "dropDateTime": tripTypeDetails?.endTime?.toIso8601String() ?? '',
          "totalKilometers": tripTypeDetails?.distanceBooked ??
              int.parse(searchCabInventoryController
                      .indiaData.value?.result?.tripType?.packageId
                      ?.split("_")[1] ??
                  '0'),
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
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Card(
          color: Colors.white,
          elevation: 0.3,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Image.network(
                          carType.carImageUrl ?? '',
                          width: 60,
                          height: 50,
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3F2FD),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            side: const BorderSide(
                                color: Colors.transparent, width: 1),
                            foregroundColor: const Color(0xFF1565C0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            carType.type ?? '',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      flex: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 55,
                                child: Text(
                                  carType.carTagLine ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 16),
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
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () {},
                                child: Text(
                                  carType.combustionType ?? '',
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              )
                            ],
                          ),
                          Text('or similar',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colors.grey[600])),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text("${carType.seats} Seater",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 10,
                                      color: Colors.grey[700])),
                              const SizedBox(width: 7),
                              Text("• ${carType.luggageCapacity}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 10,
                                      color: Colors.grey[700])),
                            ],
                          ),


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
                                          fontSize: 13,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  buildConvertedPrice(
                                    originalPrice.toDouble(),
                                    prefix: currencyController
                                        .selectedCurrency.value.symbol,
                                    style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                        fontSize: 12),
                                  )
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  buildConvertedPrice(
                                    carType.fareDetails?.baseFare?.toDouble() ??
                                        0.0,
                                    prefix: currencyController
                                        .selectedCurrency.value.symbol,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<double>(
                                future: currencyController.convertPrice(
                                    getFivePercentOfBaseFare(
                                            carType.fareDetails?.baseFare ?? 0)
                                        .toDouble()),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Text("Error in conversion",
                                        style: TextStyle(
                                            color: Colors.red, fontSize: 11));
                                  }
                                  final convertedTaxes = snapshot.data ??
                                      getFivePercentOfBaseFare(
                                              carType.fareDetails?.baseFare ?? 0)
                                          .toDouble();
                                  return Text(
                                    '+ ${currencyController.selectedCurrency.value.symbol}${convertedTaxes.toStringAsFixed(2)} (taxes & charges)',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 11),
                                  );
                                },
                              )
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 8,),
                SizedBox(
                  height: 20,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: carType.amenities?.features?.vehicle?.length ?? 0,
                    itemBuilder: (context, index) {
                      final iconUrl = carType.amenities?.features?.vehicleIcons?[index] ?? '';
                      final label = carType.amenities?.features?.vehicle?[index] ?? '';
                  
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade400, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // load icon from API (SVG or PNG)
                            if (iconUrl.isNotEmpty)
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: SvgPicture.network(
                                  'https://www.wticabs.com:3001$iconUrl',
                                ),
                              ),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalCard(GlobalTripDetails tripDetails,
      GlobalFareDetails fareDetails, GlobalVehicleDetails vehicleDetails) {
    final CurrencyController currencyController = Get.put(CurrencyController());
    final List<IconData> amenityIcons = [
      Icons.cleaning_services, // Tissue
      Icons.sanitizer,         // Sanitizer
    ];
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
          "trip_type_details": {
            "basic_trip_type": searchCabInventoryController
                    .globalData.value?.tripTypeDetails?.basicTripType ??
                '',
            "airport_type": searchCabInventoryController
                    .globalData.value?.tripTypeDetails?.airportType ??
                ''
          },
        };
        cabBookingController
            .fetchBookingData(
                country: country ?? '',
                requestData: requestData,
                context: context)
            .then((value) {
          Navigator.push(
            context,
            Platform.isIOS
                ? CupertinoPageRoute(
              builder: (context) => BookingDetailsFinal(
                totalKms: tripDetails.totalDistance ?? 0.0,
                endTime: tripDetails.dropDateTime,
              ),
            )
                : MaterialPageRoute(
              builder: (context) => BookingDetailsFinal(
                totalKms: tripDetails.totalDistance ?? 0.0,
                endTime: tripDetails.dropDateTime,
              ),
            ),
          );
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              elevation: 0.3,
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            Image.network(
                              vehicleDetails.vehicleImageLink ?? '',
                              width: 65,
                              height: 50,
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3F2FD),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                side: const BorderSide(
                                    color: Colors.transparent, width: 1),
                                foregroundColor: const Color(0xFF1565C0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {},
                              child: Text(
                                vehicleDetails.filterCategory ?? '',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(width: 14),
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
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16),
                                      overflow: TextOverflow.clip,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4,),
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
                                  vehicleDetails.fuelType??'',
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text("${vehicleDetails.passengerCapacity} Seater",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 10,
                                          color: Colors.grey[700])),
                                  const SizedBox(width: 8),
                                  Text(
                                      "• ${vehicleDetails.checkinLuggageCapacity.toString()} bags",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 10,
                                          color: Colors.grey[700])),
                                ],
                              )
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                    "20%",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 6),
                                FutureBuilder<double>(
                                  future: currencyController.convertPrice(
                                    getFakePriceWithPercent(tripDetails.totalFare, 20).toDouble(),
                                  ),
                                  builder: (context, snapshot) {
                                    final convertedValue = snapshot.data ??
                                        getFakePriceWithPercent(tripDetails.totalFare, 20).toDouble();

                                    return Text(
                                      '${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Colors.grey, // lighter color for cut-off price
                                        decoration: TextDecoration.lineThrough, // 👈 adds cutoff
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                FutureBuilder<double>(
                                  future: currencyController.convertPrice(
                                      tripDetails.totalFare?.toDouble() ?? 0),
                                  builder: (context, snapshot) {
                                    final convertedValue =
                                        snapshot.data ?? tripDetails.totalFare;
                                    return Text(
                                      '${currencyController.selectedCurrency.value.symbol}${convertedValue?.toDouble().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                    );
                                  },
                                ),
                              ],
                            ),
                            // Text(
                            //   'All Inclusions',
                            //   style: const TextStyle(
                            //     fontWeight: FontWeight.w600,
                            //     fontSize: 10,
                            //     color: Colors.grey, // lighter color for cut-off price
                            //   ),
                            // ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50, // light background
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green, width: 1),
                              ),
                              child: const Text(
                                "Free Cancellation",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // const SizedBox(height: 4),
                            // FutureBuilder<double>(
                            //   future: currencyController.convertPrice(
                            //       getFivePercentOfBaseFare(
                            //               fareDetails.baseFare ?? 0)
                            //           .toDouble()),
                            //   builder: (context, snapshot) {
                            //     final convertedTaxes = snapshot.data ??
                            //         getFivePercentOfBaseFare(
                            //                 fareDetails.baseFare ?? 0)
                            //             .toDouble();
                            //     return Text(
                            //       '+ ${currencyController.selectedCurrency.value.symbol}${convertedTaxes.toStringAsFixed(2)} (taxes & charges)',
                            //       style: TextStyle(
                            //           color: Colors.grey[600], fontSize: 10),
                            //     );
                            //   },
                            // ),
                          ],
                        )
                      ],
                    ),
                    SizedBox(height: 8,),
                    SizedBox(
                      height: 20,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vehicleDetails.extras?.length ?? 0,
                        itemBuilder: (context, index) {
                          final iconUrl = amenityIcons[index] ?? '';
                          final label = vehicleDetails.extras?[index] ?? '';

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade400, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // load icon from API (SVG or PNG)
                                  Icon(
                                    amenityIcons[index],
                                    size: 11,
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                 label,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildConvertedPrice(double value,
      {TextStyle? style, bool strikeThrough = false, String prefix = "₹"}) {
    final CurrencyController currencyController = Get.put(CurrencyController());
    return FutureBuilder<double>(
      future: currencyController.convertPrice(value),
      builder: (context, snapshot) {
        final converted = snapshot.data ?? value;
        return Text(
          "$prefix${converted.toStringAsFixed(2)}",
          style: style?.copyWith(
                  decoration: strikeThrough
                      ? TextDecoration.lineThrough
                      : TextDecoration.none) ??
              TextStyle(
                  decoration: strikeThrough
                      ? TextDecoration.lineThrough
                      : TextDecoration.none),
        );
      },
    );
  }
}

class BookingTopBar extends StatefulWidget {
  @override
  State<BookingTopBar> createState() => _BookingTopBarState();
}

class _BookingTopBarState extends State<BookingTopBar> {
  final SearchCabInventoryController searchCabInventoryController = Get.put(SearchCabInventoryController());
  final BookingRideController bookingRideController = Get.put(BookingRideController());
  final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
  final FetchPackageController fetchPackageController = Get.put(FetchPackageController());

  String? tripCode;
  String? previousCode;

  @override
  void initState() {
    super.initState();
    getCurrentTripCode();
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }

  String formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthName(dateTime.month);
    final year = dateTime.year;

    int hour = dateTime.hour % 12;
    hour = hour == 0 ? 12 : hour; // handle midnight & noon
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$day $month, $hour:$minute $period';
  }


  void getCurrentTripCode() async {
    tripCode = await StorageServices.instance.read('currentTripCode') ??
        await StorageServices.instance.read('previousTripCode');
    previousCode = await StorageServices.instance.read('previousTripCode') ?? '';
    setState(() {});
  }

  String trimAfterTwoSpaces(String input) {
    final parts = input.split(' ');
    if (parts.length <= 2) return input;
    return parts.take(2).join(' ');
  }

  Widget _buildTripTypeTag(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.mainButtonBg.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.mainButtonBg),
      ),
    );
  }

  String convertUtcToLocal(String utcTimeString, String timezoneString) {
    // Parse UTC time
    DateTime utcTime = DateTime.parse(utcTimeString);

    // Get the location based on timezone string like "Asia/Kolkata"
    final location = tz.getLocation(timezoneString);

    // Convert UTC to local time in given timezone
    final localTime = tz.TZDateTime.from(utcTime, location);

    // Format as "3 Sep, 07:30 AM"
    final formatted = DateFormat("d MMM, hh:mm a").format(localTime);

    return formatted;
  }


  @override
  Widget build(BuildContext context) {
    final pickupDateTime = bookingRideController.localStartTime.value;
    final formattedPickup = formatDateTime(pickupDateTime);
    DateTime localEndUtc = bookingRideController.localEndTime.value.toUtc();
    DateTime? backendEndUtc = searchCabInventoryController.indiaData.value?.result?.tripType?.endTime;

// Compare in UTC, pick the greater one
    DateTime finalDropUtc = (backendEndUtc != null && backendEndUtc.isAfter(localEndUtc))
        ? backendEndUtc
        : localEndUtc;

// Convert chosen UTC time back to local with timezone handling
    final formattedDrop = convertUtcToLocal(
      finalDropUtc.toIso8601String(),
      placeSearchController.findCntryDateTimeResponse.value?.timeZone ?? '',
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: GestureDetector(
          onTap: () {
            final tabName = bookingRideController.currentTabName;
            final route = tabName == 'rental'
                ? '${AppRoutes.bookingRide}?tab=airport'
                : '${AppRoutes.bookingRide}?tab=airport';
            GoRouter.of(context).push(
                route,
                extra: (context) => Platform.isIOS
                    ? CupertinoPage(child: const BottomNavScreen())
                    : MaterialPage(child: const BottomNavScreen()));
            GoRouter.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 16, color: AppColors.mainButtonBg),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                tripCode == '3'
                    ? bookingRideController.prefilled.value
                    : '${trimAfterTwoSpaces(bookingRideController.prefilled.value)} to ${trimAfterTwoSpaces(bookingRideController.prefilledDrop.value)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!(tripCode?.isEmpty ?? true))
              GestureDetector(
                onTap: () {
                  bookingRideController.isInventoryPage.value = true;
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => TopBookingDialogWrapper(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  decoration: BoxDecoration(
                    color: AppColors.mainButtonBg.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit, size: 14, color: AppColors.mainButtonBg),
                      SizedBox(width: 4),
                      Text(
                        "Edit",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mainButtonBg,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )

              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
               (tripCode == '1') ? '$formattedPickup - $formattedDrop' : '$formattedPickup',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.greyText5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (tripCode == '3')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectedPackageCard(controller: fetchPackageController),
              ),
            // if (tripCode == '0') _buildTripTypeTag('Outstation One Way Trip'),
            // if (tripCode == '1') _buildTripTypeTag('Outstation Round Way Trip'),
            // if (tripCode == '2') _buildTripTypeTag('Airport Trip'),
            // if (tripCode == '3') _buildTripTypeTag('Rental Trip'),
          ],
        ),
      ),
    );
  }
}

Widget _buildTripTypeTag(String text) {
  return Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.mainButtonBg.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.mainButtonBg,
      ),
    ),
  );
}

class TopBookingDialogWrapper extends StatefulWidget {
  const TopBookingDialogWrapper({super.key});

  @override
  State<TopBookingDialogWrapper> createState() => _TopBookingDialogWrapperState();
}

class _TopBookingDialogWrapperState extends State<TopBookingDialogWrapper> {
  final SearchCabInventoryController searchCabInventoryController = Get.find();
  final FetchPackageController fetchPackageController = Get.find();

  @override
  void initState() {
    super.initState();
    // Defer loadTripCode to ensure it runs after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Calling loadTripCode at ${DateTime.now()}');
      searchCabInventoryController.loadTripCode();
    });
    // Monitor tripCode changes for debugging
    ever(searchCabInventoryController.tripCode, (value) {
      print('tripCode changed to $value at ${DateTime.now()}');
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white, // Status bar color set to white
      statusBarIconBrightness: Brightness.dark, // Dark icons for visibility
    ));
    print('Building TopBookingDialogWrapper at ${DateTime.now()}');
    return Column(
      children: [
        Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Obx(() {
                print('Obx rebuild triggered at ${DateTime.now()}');
                // Capture the current tripCode value to avoid direct reactive access
                final tripCode = searchCabInventoryController.tripCode.value;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            GoRouter.of(context).pop();
                          },
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.13),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (tripCode == '0')
                              Text('OutStation One Way',
                                  style: CommonFonts.greyText3Bold),
                            if (tripCode == '1')
                              Text('OutStation Round Way',
                                  style: CommonFonts.greyText3Bold),
                            if (tripCode == '2')
                              Text('Airport',
                                  style: CommonFonts.greyText3Bold),
                            if (tripCode == '3')
                              Text('Rental',
                                  style: CommonFonts.greyText3Bold),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (tripCode == '0') OutStation(selectedTrip: 'oneWay',),
                    if (tripCode == '1') OutStation(selectedTrip: 'roundTrip',),
                    if (tripCode == '2') Rides(),
                    if (tripCode == '3') Rental(),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ),
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
            fontSize: 8, color: Colors.white, fontWeight: FontWeight.w500),
      ),
      backgroundColor: AppColors.mainButtonBg,
      onPressed: onPressed,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

Widget _buildShimmer() {
  return Column(
    children: [
      const SizedBox(height: 40),
      Padding(
        padding: const EdgeInsets.all(8),
        child: ShimmerWidget.rectangular(height: 50, width: double.infinity),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.all(8),
            child:
                ShimmerWidget.rectangular(height: 50, width: double.infinity),
          ),
        ),
      ),
    ],
  );
}

class ShimmerWidget extends StatelessWidget {
  final double height;
  final double width;

  const ShimmerWidget.rectangular(
      {super.key, required this.height, this.width = double.infinity});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8)),
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
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pickup",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                const Text("Connaught Place, Delhi",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                const Text("Sat, 10 Aug · 09:00 AM",
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.swap_vert, size: 20, color: Colors.black54),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Drop",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                const Text("Jaipur, Rajasthan",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                const Text("Sat, 10 Aug · 02:00 PM",
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedPackageCard extends StatelessWidget {
  final FetchPackageController controller;
  final SearchCabInventoryController searchCabInventoryController =
      Get.put(SearchCabInventoryController());

  SelectedPackageCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedPackage.value.isEmpty ||
          searchCabInventoryController.tripCode.value.toString() != '3') {
        return const SizedBox();
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selected Package -",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600)),
                const SizedBox(width: 8),
                Text(controller.selectedPackage.value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainButtonBg)),
              ],
            ),
          ),
        ],
      );
    });
  }
}
