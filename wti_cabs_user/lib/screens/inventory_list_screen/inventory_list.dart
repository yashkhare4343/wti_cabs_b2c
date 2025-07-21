import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/inventory/search_cab_inventory_controller.dart';
import 'package:wti_cabs_user/core/model/inventory/global_response.dart';
import 'package:wti_cabs_user/screens/booking_ride/booking_ride.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

import '../../core/controller/cab_booking/cab_booking_controller.dart';
import '../../core/model/inventory/india_response.dart';
import '../../core/services/storage_services.dart';

class InventoryList extends StatefulWidget {
  const InventoryList({super.key});

  @override
  State<InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends State<InventoryList> {
  final SearchCabInventoryController searchCabInventoryController = Get.find();

  String? _country;
  String number = '0';

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');
    final tripCode = searchCabInventoryController.indiaData.value?.result?.tripType?.currentTripCode;
    final packageId = searchCabInventoryController.indiaData.value?.result?.tripType?.packageId;
    final previousTripCode = searchCabInventoryController.indiaData.value?.result?.tripType?.previousTripCode;

    final Map<String, String> tripMessages = {
      '0': 'Your selected trip type has changed to Outstation One Way Trip.',
      '1': 'Your selected trip type has changed to Outstation Round Trip.',
      '2': 'Your selected trip type has changed to Airport.',
      '3': 'Your selected trip type has changed to Local.',
    };
    // Check and show popup if trip code changed
    if (tripCode != null && previousTripCode != null && tripCode != previousTripCode) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final message = tripMessages[tripCode] ?? 'Your selected trip type has changed.';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 12.0,vertical: 0.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            elevation: 10,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: [
                const Icon(Icons.update_outlined, color: Colors.blueAccent, size: 16,),
                const SizedBox(width: 10),
                Text(
                  'Trip Updated',
                  style: CommonFonts.greyText3Bold,
                ),
              ],
            ),
            content: Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: MainButton(text: 'Okay', onPressed: (){
                  Navigator.pop(context);
                })
              ),
            ],
          ),
        );

      });
    }

    if (tripCode == '3' && packageId != null) {
      try {
        number = packageId.split('_')[1];
      } catch (e) {
        print("❌ Error parsing packageId: $e");
      }
    }

    setState(() {});
  }

  num getFakePriceWithPercent(num baseFare, num percent) {
    return (baseFare * 100) / (100 - percent);
  }

  num getFivePercentOfBaseFare(num baseFare) {
    return baseFare * 0.05;
  }

  @override
  Widget build(BuildContext context) {
    final isIndia = _country?.toLowerCase() == 'india';
    final indiaData = searchCabInventoryController.indiaData.value;
    final globalData = searchCabInventoryController.globalData.value;

    if (_country == null || (isIndia && indiaData == null) || (!isIndia && globalData == null)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final indiaCarTypes = indiaData?.result?.inventory?.carTypes ?? [];
    final globalList = globalData?.result ?? [];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              BookingTopBar(),
              SizedBox(
                height: 16,
              ),
              Expanded(
                child: Obx(() {
                  final isIndia = searchCabInventoryController.indiaData.value != null;
                  final indiaCarTypes = searchCabInventoryController.indiaData.value?.result?.inventory?.carTypes ?? [];
                  final globalList = searchCabInventoryController.globalData.value?.result ?? [];

                  final isEmptyList = (isIndia && indiaCarTypes.isEmpty) || (!isIndia && globalList.isEmpty);

                  if (isEmptyList) {
                    return const Center(
                      child: Text(
                        "No cabs available on this route",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: isIndia ? indiaCarTypes.length : globalList.length,
                    itemBuilder: (context, index) {
                      if (isIndia) {
                        final carType = indiaCarTypes[index];
                        return _buildIndiaCard(carType);
                      } else {
                        final globalListItem = globalList[index];
                        final tripDetails = globalListItem.firstWhereOrNull((e) => e.tripDetails != null)?.tripDetails;
                        final fareDetails = globalListItem.firstWhereOrNull((e) => e.fareDetails != null)?.fareDetails;
                        final vehicleDetails = globalListItem.firstWhereOrNull((e) => e.vehicleDetails != null)?.vehicleDetails;

                        if (tripDetails == null || fareDetails == null || vehicleDetails == null) {
                          return const SizedBox();
                        }

                        return _buildGlobalCard(tripDetails, fareDetails, vehicleDetails);
                      }
                    },
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
    final tripCode = searchCabInventoryController.indiaData.value?.result?.tripType?.currentTripCode;
    final CabBookingController cabBookingController = Get.put(CabBookingController());
    final tripTypeDetails = searchCabInventoryController.indiaData.value?.result?.tripType;

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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.network(
                    carType.carImageUrl??'',
                    width: 96,
                    height: 66,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/inventory_car.png',
                        width: 96,
                        height: 66,
                        fit: BoxFit.contain,
                      );
                    },
                  ),                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(carType.carTagLine ?? '', style: CommonFonts.bodyText1Bold),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(carType.rating?.ratePoints.toString() ?? '', style: CommonFonts.bodyText1),
                            const SizedBox(width: 4),
                            Icon(Icons.star, color: AppColors.yellow1, size: 12),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.airline_seat_recline_extra, size: 13),
                            const SizedBox(width: 4),
                            Text('${carType.seats} Seat', style: CommonFonts.bodyTextXS),
                            const SizedBox(width: 8),
                            Icon(Icons.luggage_outlined, size: 13),
                            const SizedBox(width: 4),
                            Text('${carType.luggageCapacity}', style: CommonFonts.bodyTextXS),
                            const SizedBox(width: 8),
                            Icon(Icons.speed_outlined, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              tripCode != "3" ? '${searchCabInventoryController.indiaData.value?.result?.inventory?.distanceBooked} km' : '$number km',
                              style: CommonFonts.bodyTextXS,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.info_outline, size: 16),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("₹ ${carType.fareDetails?.baseFare?.toString() ?? ''}", style: CommonFonts.greyText3Bold),
                      Text('+ ${getFivePercentOfBaseFare(carType.fareDetails?.baseFare ?? 0).truncate()} (taxes & charges)', style: CommonFonts.greyText3),
                      const SizedBox(height: 6),
                      Text(
                        'Book Now and Get Rs ${(getFakePriceWithPercent(carType.fareDetails?.baseFare ?? 0, carType.fakePercentageOff ?? 0).truncate()) - (carType.fareDetails?.baseFare ?? 0)} OFF*',
                        style: CommonFonts.organgeText1,
                      ),
                    ],
                  ),
                  MainButton(text: 'Book Now', onPressed: () async{
                    final country = await StorageServices.instance
                        .read('country');

                    Future<bool> isGlobal() async {
                      final country = await StorageServices.instance.read('country');
                      return country?.toLowerCase() != 'india';
                    }

                    print("inventory start time and endtime : ${tripTypeDetails?.startTime?.toIso8601String()??''}, ${tripTypeDetails?.endTime?.toIso8601String()??''}");

                  final Map<String, dynamic> requestData = {
                    "isGlobal": false,
                    "country": country,
                    "routeInventoryId": carType.routeId,
                    "vehicleId": null,
                    "trip_type": carType.tripType,
                    "pickUpDateTime": tripTypeDetails?.startTime?.toIso8601String()??'',
                    "dropDateTime": tripTypeDetails?.endTime?.toIso8601String()??'',
                    "totalKilometers": tripTypeDetails?.distanceBooked??0,
                    "package_id": tripTypeDetails?.packageId??'',
                    "source": {
                      "address": tripTypeDetails?.source?.address??'',
                      "latitude": tripTypeDetails?.source?.latitude,
                      "longitude": tripTypeDetails?.source?.longitude,
                      "city": tripTypeDetails?.source?.city
                    },
                    "destination": {
                      "address": tripTypeDetails?.destination?.address??'',
                      "latitude": tripTypeDetails?.destination?.latitude,
                      "longitude": tripTypeDetails?.destination?.longitude,
                      "city": tripTypeDetails?.destination?.city
                    },
                    "tripCode": tripCode,
                    // Conditional key based on global/india
                    "trip_type_details": {
                    "basic_trip_type": tripTypeDetails?.tripTypeDetails?.basicTripType??'',
                    "airport_type": tripTypeDetails?.tripTypeDetails?.airportType??''
                    },
                  };


                    cabBookingController.fetchBookingData(country: country??'', requestData: requestData, context: context);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalCard(GlobalTripDetails tripDetails, GlobalFareDetails fareDetails, GlobalVehicleDetails vehicleDetails) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.network(
                    vehicleDetails?.vehicleImageLink??'',
                    width: 66,
                    height: 66,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/inventory_car.png',
                        width: 66,
                        height: 66,
                        fit: BoxFit.contain,
                      );
                    },
                  ),                    const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicleDetails.title ?? '', style: CommonFonts.bodyText1Bold),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(vehicleDetails.rating.toString(), style: CommonFonts.bodyText1),
                            const SizedBox(width: 4),
                            Icon(Icons.star, color: AppColors.yellow1, size: 12),
                            const SizedBox(width: 4),
                            Text('${vehicleDetails.reviews.toString()} Reviews', style: CommonFonts.bodyText1),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.luggage_outlined, size: 13),
                            const SizedBox(width: 4),
                            Text('${vehicleDetails.checkinLuggageCapacity} Check-in Luggage', style: CommonFonts.bodyTextXS),
                            const SizedBox(width: 8),
                            Icon(Icons.airline_seat_recline_extra, size: 13),
                            const SizedBox(width: 4),
                            Text('${vehicleDetails.passengerCapacity} Passenger', style: CommonFonts.bodyTextXS),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.info_outline, size: 16),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("USD ${tripDetails.totalFare.toString()}", style: CommonFonts.greyText3Bold),
                      Text('+ ${getFivePercentOfBaseFare(tripDetails.totalFare).truncate()} (taxes & charges)', style: CommonFonts.greyText3),
                      const SizedBox(height: 6),
                      Text(
                        'Book Now and Get Rs ${(getFakePriceWithPercent(tripDetails.totalFare ?? 0, 20).truncate()) - (tripDetails.totalFare ?? 0)} OFF*',
                        style: CommonFonts.organgeText1,
                      ),
                    ],
                  ),
                  MainButton(text: 'Book Now', onPressed: () async{
                    final country = await StorageServices.instance
                        .read('country');
                    final CabBookingController cabBookingController = Get.put(CabBookingController());
                    final Map<String, dynamic> requestData = {
                      "isGlobal": false,
                      "country": country,
                      "routeInventoryId": fareDetails.id,
                      "vehicleId": vehicleDetails.id,
                      "trip_type": fareDetails.tripType,
                      "pickUpDateTime": tripDetails?.pickupDateTime??'',
                      "dropDateTime": tripDetails.dropDateTime??'',
                      "totalKilometers": tripDetails.totalDistance??0,
                      "package_id": null,
                      "source": {},
                      "destination": {},
                      "tripCode": tripDetails.currentTripCode,
                      // Conditional key based on global/india
                      "trip_type_details": {
                        "basic_trip_type": searchCabInventoryController.globalData.value?.tripTypeDetails?.basicTripType??'',
                        "airport_type": searchCabInventoryController.globalData.value?.tripTypeDetails?.airportType??''
                      },
                    };
                    cabBookingController.fetchBookingData(country: country??'', requestData: requestData, context: context);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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

  final BookingRideController bookingRideController = Get.put(BookingRideController());
  String? tripCode;

  void getCurrentTripCode() async{

    tripCode =  await StorageServices.instance.read(
        'currentTripCode');
    setState(() {
    });
    print('yash trip code : $tripCode');
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
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        leading: GestureDetector(
            onTap: (){
              GoRouter.of(context).pop();
            },
            child: Icon(Icons.arrow_back, size: 20)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${bookingRideController.prefilled.value} to ${bookingRideController.prefilledDrop.value}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: (){
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => TopBookingDialogWrapper(),
                );
              },
                child: Icon(Icons.edit, size: 16, color: AppColors.mainButtonBg)),
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
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              if(tripCode == '0')  Text(
                'Outstation One Way Trip',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mainButtonBg,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if(tripCode == '1')  Text(
                'Outstation One Way Trip',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mainButtonBg,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if(tripCode == '2')  Text(
                'Airport Trip',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mainButtonBg,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if(tripCode == '3')  Text(
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
  State<TopBookingDialogWrapper> createState() => _TopBookingDialogWrapperState();
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
              child: Obx(()=>Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width*0.13,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if(searchCabInventoryController.tripCode.value == '0') Text('OutStation One Way', style: CommonFonts.greyText3Bold,),
                          if(searchCabInventoryController.tripCode.value == '1') Text('OutStation Round Way', style: CommonFonts.greyText3Bold,),
                          if(searchCabInventoryController.tripCode.value == '2') Text('Airport', style: CommonFonts.greyText3Bold,),
                          if(searchCabInventoryController.tripCode.value == '3') Text('Rental', style: CommonFonts.greyText3Bold,),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16,),
                  if(searchCabInventoryController.tripCode.value == '0') OutStation(),
                  if(searchCabInventoryController.tripCode.value == '1') OutStation(),
                  if(searchCabInventoryController.tripCode.value == '2') Rides(),
                  if(searchCabInventoryController.tripCode.value == '3') Rental(),
                  SizedBox(height: 8,),

                ],
              ),)
            ),
          ),
        ),
      ],
    );
  }
}
