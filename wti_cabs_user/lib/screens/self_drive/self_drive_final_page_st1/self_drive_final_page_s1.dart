import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/controller/self_drive/self_drive_booking_details/self_drive_booking_details_controller.dart';
import 'package:wti_cabs_user/core/controller/self_drive/service_hub/service_hub_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_all_inventory/self_drive_all_inventory.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_final_page_st1/self_drive_final_page_s2.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_popular_location/self_drive_most_popular_location.dart';

import '../../../core/controller/self_drive/file_upload_controller/file_upload_controller.dart';
import '../../../core/controller/self_drive/google_lat_lng_controller/google_lat_lng_controller.dart';
import '../../../core/controller/self_drive/search_inventory_sd_controller/search_inventory_sd_controller.dart';
import '../../../core/controller/self_drive/self_drive_stripe_payment/sd_create_stripe_payment.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../self_drive_popular_location/self_drive_return_popular_location.dart';

class SelfDriveFinalPageS1 extends StatefulWidget {
  final String? vehicleId;
  final bool? isHomePage;
  final bool? fromReturnMapPage;
  const SelfDriveFinalPageS1(
      {super.key, this.vehicleId, this.isHomePage, this.fromReturnMapPage});

  @override
  State<SelfDriveFinalPageS1> createState() => _SelfDriveFinalPageS1State();
}

class _SelfDriveFinalPageS1State extends State<SelfDriveFinalPageS1> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
      Get.put(FetchSdBookingDetailsController());
  final SearchInventorySdController searchInventorySdController = Get.put(SearchInventorySdController());
  final FileUploadValidController fileUploadController = Get.put(FileUploadValidController());


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void showFareBreakdownSheet(BuildContext context,
      FetchSdBookingDetailsController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Obx(() {
          final selectedType =
              controller.getAllBookingData.value?.result?.tarrifSelected;

          // Pick index based on selection
          int index = 0;
          if (selectedType == 'Daily') {
            index = 0;
          } else if (selectedType == 'Weekly') {
            index = 1;
          } else if (selectedType == 'Monthly') {
            index = 2;
          }

          final selectedTariff =
          controller.getAllBookingData.value?.result?.tarrifs?[index];
          final fareDetails = selectedTariff?.fareDetails;

          if (fareDetails == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text("No fare details available"),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  "$selectedType Fare Breakdown",
                  style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _fareRow("Base fare", "AED ${fareDetails.baseFare ?? 0}"),
                _fareRow("Delivery Charge", "AED ${fareDetails.delivery_charges ?? 0}"),
                _fareRow("Collection Charge", "AED ${fareDetails.collection_charges ?? 0}"),
                _fareRow("Deposite Free Rides", "AED ${fareDetails.deposit_free_ride ?? 0}"),
                _fareRow("Tax", "AED ${fareDetails.tax ?? 0}"),



                const Divider(height: 24, thickness: 1),

                _fareRow(
                  "Grand Total",
                  "AED ${fareDetails.grandTotal ?? 0}",
                  isTotal: true,
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _fareRow(String title, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }



  void validateAndProceed(BuildContext context) {
    // ✅ Validate pickup
    fetchSdBookingDetailsController.showPickupError.value =
        fetchSdBookingDetailsController.selectedPickupOption.value.isEmpty;

    // ✅ Validate dropoff only if "Return to same location" is OFF
    if (!fetchSdBookingDetailsController.isSameLocation.value) {
      fetchSdBookingDetailsController.showDropoffError.value =
          fetchSdBookingDetailsController.selectedDropoffOption.value.isEmpty;
    } else {
      fetchSdBookingDetailsController.showDropoffError.value = false;
    }

    // ✅ If both are valid, navigate
    if (!fetchSdBookingDetailsController.showPickupError.value &&
        !fetchSdBookingDetailsController.showDropoffError.value) {
      Navigator.of(context).push(
        Platform.isIOS
            ? CupertinoPageRoute(
          builder: (_) => SelfDriveFinalPageS2(
              vehicleId: widget.vehicleId, isHomePage: false),
        )
            : MaterialPageRoute(
          builder: (_) => SelfDriveFinalPageS2(
              vehicleId: widget.vehicleId, isHomePage: false),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSdBookingDetailsController.isSameLocation.value =
          widget.fromReturnMapPage == true ? false : true;
    });

    return PopScope(
      canPop: false, // 🚀 Stops the default "pop and close app"
      onPopInvoked: (didPop) {
         searchInventorySdController.fetchAllInventory(context: context);

        // Navigator.of(context).push(
        //   Platform.isIOS
        //       ? CupertinoPageRoute(
        //     builder: (_) => SelfDriveAllInventory(
        //       city: searchInventorySdController.city.value,
        //       fromDate: "${searchInventorySdController.fromDate.value.day}/${searchInventorySdController.fromDate.value.month}",
        //       fromTime:
        //       "${searchInventorySdController.fromTime.value.hour.toString().padLeft(2, '0')}:${searchInventorySdController.fromTime.value.minute.toString().padLeft(2, '0')}",
        //       toDate: "${searchInventorySdController.toDate.value.day}/${searchInventorySdController.toDate.value.month}",
        //       toTime:
        //       "${searchInventorySdController.toTime.value.hour.toString().padLeft(2, '0')}:${searchInventorySdController.toTime.value.minute.toString().padLeft(2, '0')}",
        //       selectedMonth: searchInventorySdController.selectedMonth.value.toString(),
        //     ),
        //   )
        //       : MaterialPageRoute(
        //     builder: (_) => SelfDriveAllInventory(
        //       city: searchInventorySdController.city.value,
        //       fromDate: "${searchInventorySdController.fromDate.value.day}/${searchInventorySdController.fromDate.value.month}",
        //       fromTime:
        //       "${searchInventorySdController.fromTime.value.hour.toString().padLeft(2, '0')}:${searchInventorySdController.fromTime.value.minute.toString().padLeft(2, '0')}",
        //       toDate: "${searchInventorySdController.toDate.value.day}/${searchInventorySdController.toDate.value.month}",
        //       toTime:
        //       "${searchInventorySdController.toTime.value.hour.toString().padLeft(2, '0')}:${searchInventorySdController.toTime.value.minute.toString().padLeft(2, '0')}",
        //       selectedMonth: searchInventorySdController.selectedMonth.value.toString(),
        //     ),
        //   ),
        // );
        // This will be called for hardware back and gesture
        // GoRouter.of(context).push(AppRoutes.inventoryList);
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBgPrimary1,
        body: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        searchInventorySdController.fetchAllInventory(context: context);
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 16,
                        child:
                            Icon(Icons.arrow_back, color: Colors.black, size: 22),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 2),
                            child: Text(
                              'Step 1 of 2',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Book your car',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BookYourCarScreen(
                  vehicleId: widget.vehicleId ?? '',
                  isHomePage: widget.isHomePage ?? false,
                ),
              ),
              CarRentalCard(
                  vehicleId: widget.vehicleId ?? '',
                  isHomePage: widget.isHomePage ?? false),
              PricingTiles(
                  vehicleId: widget.vehicleId ?? '',
                  isHomePage: widget.isHomePage ?? false),
              SizedBox(
                height: 12,
              ),
              CarServiceOverview(
                  vehicleId: widget.vehicleId ?? '',
                  isHomePage: widget.isHomePage ?? false),
              InsuranceOptions(
                  vehicleId: widget.vehicleId ?? '',
                  isHomePage: widget.isHomePage ?? false),
              ImportantInfoCard(),
              PickupReturnLocationPage(
                vehicleId: widget.vehicleId ?? '',
                isHomePage: widget.isHomePage ?? false,
              )
            ],
          ),
        )),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                offset: const Offset(0, -3),
                blurRadius: 10,
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children:  [
                      Text(
                        "Total Fare | ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Obx(() {
                        if (fetchSdBookingDetailsController.getAllBookingData
                            .value?.result?.tarrifSelected ==
                            'Daily'){
                          return Text(
                            "AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?.first.fareDetails?.grandTotal}", // Bind dynamically
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          );
                        }
                        else if (fetchSdBookingDetailsController.getAllBookingData
                            .value?.result?.tarrifSelected ==
                            'Weekly'){
                          return Text(
                            "AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].fareDetails?.grandTotal}", // Bind dynamically
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          );
                        }
                        else if (fetchSdBookingDetailsController.getAllBookingData
                            .value?.result?.tarrifSelected ==
                            'Monthly'){
                          return Text(
                            "AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].fareDetails?.grandTotal}", // Bind dynamically
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          );
                        }
                        return Text(
                          "AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?.first.fareDetails?.grandTotal}", // Bind dynamically
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      }),                  ],
                  ),
                ),
                InkWell(
                    splashColor: Colors.transparent,
                    onTap: (){
                      showFareBreakdownSheet(context, fetchSdBookingDetailsController);
                    },
                    child: Icon(Icons.info_outline, size: 20, color: Colors.grey,)),
                // Continue Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                     validateAndProceed(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0.3,
                      shadowColor: Colors.redAccent.withOpacity(0.4),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookYourCarScreen extends StatefulWidget {
  final String vehicleId;
  final bool isHomePage;
  const BookYourCarScreen(
      {Key? key, required this.vehicleId, required this.isHomePage})
      : super(key: key);

  @override
  State<BookYourCarScreen> createState() => _BookYourCarScreenState();
}

class _BookYourCarScreenState extends State<BookYourCarScreen> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
  Get.put(FetchSdBookingDetailsController());
  int _currentIndex = 0;
  bool _showOverlayText = true; // Track if text box should be visible

  @override
  void initState() {
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(
        widget.vehicleId, widget.isHomePage);
  }

  @override
  Widget build(BuildContext context) {
    final images = fetchSdBookingDetailsController
        .getAllBookingData.value?.result?.vehicleId?.images ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.circular(20),
                  ),
                  child: CarouselSlider.builder(
                    itemCount: images.length,
                    itemBuilder: (context, imgIndex, realIndex) {
                      final img = images[imgIndex];
                      return SizedBox(
                        width: double.infinity,
                        height: 350,
                        child: CachedNetworkImage(
                          imageUrl: img ?? '',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          useOldImageOnUrlChange: true,
                          memCacheHeight: 320,
                          memCacheWidth: 550,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: double.infinity,
                              height: 320,
                              color: Colors.grey,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.error, size: 50),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 320,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: true,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      autoPlayAnimationDuration:
                      const Duration(milliseconds: 800),
                      onPageChanged: (imgIndex, reason) {
                        setState(() {
                          _currentIndex = imgIndex;
                        });
                      },
                    ),
                  ),
                ),
                // Show overlay text only from 2nd slide and if not dismissed
                if (_currentIndex >= 1 && _showOverlayText)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87.withOpacity(0.7),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text(
                              "We’ll try to provide the model you chose, but the car may vary in make, model, or color within the same category",
                              style:
                              TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showOverlayText = false; // dismiss text
                              });
                            },
                            child: Icon(Icons.close,
                                color: Colors.white.withOpacity(0.75), size: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CarRentalCard extends StatefulWidget {
  final String vehicleId;
  final bool isHomePage;
  const CarRentalCard(
      {super.key, required this.vehicleId, required this.isHomePage});

  @override
  State<CarRentalCard> createState() => _CarRentalCardState();
}

class _CarRentalCardState extends State<CarRentalCard> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
      Get.put(FetchSdBookingDetailsController());

  @override
  void initState() {
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(
        widget.vehicleId, widget.isHomePage);
  }

  String formatToDayMonth(String inputDate) {
    try {
      DateTime date = DateFormat("dd/MM/yyyy").parse(inputDate);
      return DateFormat("dd MMM").format(date);
    } catch (e) {
      return inputDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.directions_car,
                size: 20,
                color: Color(0xFF000000),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                          fetchSdBookingDetailsController.getAllBookingData
                                  .value?.result?.vehicleId?.modelName ??
                              '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                  ],
                ),
              )
            ],
          ),
          const Divider(),
          Obx(() {
            return Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18),
                SizedBox(width: 8),
                if (fetchSdBookingDetailsController
                        .getAllBookingData.value?.result?.tarrifSelected ==
                    'Daily')
                  Expanded(
                    child: Text(
                      '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].pickup?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].pickup?.time} - ${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].drop?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].drop?.time}',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                if (fetchSdBookingDetailsController
                        .getAllBookingData.value?.result?.tarrifSelected ==
                    'Weekly')
                  Expanded(
                    child: Text(
                      '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].pickup?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].pickup?.time} - ${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].drop?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].drop?.time}',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                if (fetchSdBookingDetailsController
                        .getAllBookingData.value?.result?.tarrifSelected ==
                    'Monthly')
                  Expanded(
                    child: Text(
                      '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].pickup?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].pickup?.time} - ${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].drop?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].drop?.time}',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class PricingTiles extends StatefulWidget {
  final String vehicleId;
  final bool isHomePage;
  const PricingTiles(
      {Key? key, required this.vehicleId, required this.isHomePage})
      : super(key: key);

  @override
  State<PricingTiles> createState() => _PricingTilesState();
}

class _PricingTilesState extends State<PricingTiles> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
      Get.put(FetchSdBookingDetailsController());
  final SearchInventorySdController searchInventorySdController =
      Get.put(SearchInventorySdController());

  int selectedIndex = 0;
  final List<String> tariffTypes = ["Daily", "Weekly", "Monthly"];

  @override
  void initState() {
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(
        widget.vehicleId, widget.isHomePage);
    selectedIndex = tariffTypes.indexOf(fetchSdBookingDetailsController
            .getAllBookingData.value?.result?.tarrifSelected ??
        '');
    if (selectedIndex == -1) selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() => Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: List.generate(
                    fetchSdBookingDetailsController
                            .getAllBookingData.value?.result?.tarrifs?.length ??
                        0, (index) {
                  final item = fetchSdBookingDetailsController
                      .getAllBookingData.value?.result?.tarrifs?[index];
                  final isSelected = index == selectedIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                          if (selectedIndex == 0) {
                            searchInventorySdController.selectedIndex.value = 0;
                            List<String> parts = fetchSdBookingDetailsController
                                    .getAllBookingData
                                    .value
                                    ?.result
                                    ?.tarrifs?[0]
                                    .drop
                                    ?.date
                                    ?.split("/") ??
                                [];

                            int day = int.parse(parts[0]); // 2
                            int month = int.parse(parts[1]); // 10
                            int year = int.parse(parts[2]); // 2025
                            String timeStr = fetchSdBookingDetailsController
                                    .getAllBookingData
                                    .value
                                    ?.result
                                    ?.tarrifs?[0]
                                    .drop
                                    ?.time ??
                                ''; // HH:mm format
                            List<String> partsTime = timeStr.split(":");

                            int hours = int.parse(partsTime[0]); // 0
                            int minutes = int.parse(partsTime[1]); // 0

// Update fromDate correctly
                            searchInventorySdController.toDate.value =
                                DateTime(year, month, day);

                            // Update your reactive TimeOfDay
                            searchInventorySdController.toTime.value =
                                TimeOfDay(hour: hours, minute: minutes);
                          }
                          if (selectedIndex == 1) {
                            searchInventorySdController.selectedIndex.value = 0;
                            List<String> parts = fetchSdBookingDetailsController
                                    .getAllBookingData
                                    .value
                                    ?.result
                                    ?.tarrifs?[1]
                                    .drop
                                    ?.date
                                    ?.split("/") ??
                                [];

                            int day = int.parse(parts[0]); // 2
                            int month = int.parse(parts[1]); // 10
                            int year = int.parse(parts[2]); // 2025
                            String timeStr = fetchSdBookingDetailsController
                                    .getAllBookingData
                                    .value
                                    ?.result
                                    ?.tarrifs?[1]
                                    .drop
                                    ?.time ??
                                ''; // HH:mm format
                            List<String> partsTime = timeStr.split(":");

                            int hours = int.parse(partsTime[0]); // 0
                            int minutes = int.parse(partsTime[1]); // 0

// Update fromDate correctly
                            searchInventorySdController.toDate.value =
                                DateTime(year, month, day);

                            // Update your reactive TimeOfDay
                            searchInventorySdController.toTime.value =
                                TimeOfDay(hour: hours, minute: minutes);
                          }
                          if (selectedIndex == 2) {
                            searchInventorySdController.selectedIndex.value = 1;
                            List<String> parts = fetchSdBookingDetailsController
                                    .getAllBookingData
                                    .value
                                    ?.result
                                    ?.tarrifs?[2]
                                    .drop
                                    ?.date
                                    ?.split("/") ??
                                [];

                            int day = int.parse(parts[0]); // 2
                            int month = int.parse(parts[1]); // 10
                            int year = int.parse(parts[2]); // 2025
                            String timeStr = fetchSdBookingDetailsController
                                    .getAllBookingData
                                    .value
                                    ?.result
                                    ?.tarrifs?[2]
                                    .drop
                                    ?.time ??
                                ''; // HH:mm format
                            List<String> partsTime = timeStr.split(":");

                            int hours = int.parse(partsTime[0]); // 0
                            int minutes = int.parse(partsTime[1]); // 0

// Update fromDate correctly
                            searchInventorySdController.toDate.value =
                                DateTime(year, month, day);

                            // Update your reactive TimeOfDay
                            searchInventorySdController.toTime.value =
                                TimeOfDay(hour: hours, minute: minutes);
                          }
                          fetchSdBookingDetailsController.fetchBookingDetails(
                              widget.vehicleId, false);
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.deepOrange
                                : Colors.transparent,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'AED ${item?.base.toString() ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '/ ${item?.tariffType}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            )),
        const SizedBox(height: 12),
        Obx(() => Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Included mileage limit",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      if (fetchSdBookingDetailsController.getAllBookingData
                              .value?.result?.tarrifSelected ==
                          'Daily')
                        Obx(() => Text(
                              "${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].mileageLimit} km",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                      if (fetchSdBookingDetailsController.getAllBookingData
                              .value?.result?.tarrifSelected ==
                          'Weekly')
                        Obx(() => Text(
                              "${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].mileageLimit} km",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                      if (fetchSdBookingDetailsController.getAllBookingData
                              .value?.result?.tarrifSelected ==
                          'Monthly')
                        Obx(() => Text(
                              "${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].mileageLimit} km",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                    ],
                  ),
                  SizedBox(height: 8),
                  Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Additional mileage charge",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.overrunCostPerKm}0/Km",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ))
      ],
    );
  }
}

class CarServiceOverview extends StatefulWidget {
  final String vehicleId;
  final bool isHomePage;
  const CarServiceOverview(
      {super.key, required this.vehicleId, required this.isHomePage});

  @override
  State<CarServiceOverview> createState() => _CarServiceOverviewState();
}

class _CarServiceOverviewState extends State<CarServiceOverview>
    with SingleTickerProviderStateMixin {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
      Get.put(FetchSdBookingDetailsController());
  bool _isExpanded = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(
        widget.vehicleId, widget.isHomePage);
  }

  Widget buildTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          // const SizedBox(width: 8),
          // const Icon(Icons.chevron_right, size: 20, color: Colors.black45),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> overviewData = [
    {
      "icon": Icons.payment,
      "title": "Payment Modes",
      "value": "Crypto, Cash & more"
    },
    {"icon": Icons.directions_car, "title": "Body Type", "value": "Sports Car"},
    {
      "icon": Icons.local_taxi,
      "title": "Salik / Toll Charges",
      "value": "AED 5"
    },
    {"icon": Icons.directions_car_filled, "title": "Make", "value": "Audi"},
    {
      "icon": Icons.directions_car_outlined,
      "title": "Model",
      "value": "R8 Performance Spyder"
    },
    {"icon": Icons.settings, "title": "Gearbox", "value": "Auto"},
    {
      "icon": Icons.event_seat,
      "title": "Seating Capacity",
      "value": "2 passengers"
    },
    {"icon": Icons.sensor_door, "title": "No. of Doors", "value": "2"},
    {"icon": Icons.work_outline, "title": "Fits No. of Bags", "value": "1"},
    {"icon": Icons.local_gas_station, "title": "Fuel Type", "value": "Petrol"},
    {
      "icon": Icons.color_lens,
      "title": "Exterior / Interior Color",
      "value": "Yellow / Black"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header (tap to expand/collapse)
                ListTile(
                  title: const Text(
                    "CAR & SERVICE OVERVIEW",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  trailing: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.black54),
                  ),
                  onTap: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                ),

                // Expandable content
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: fetchSdBookingDetailsController
                                .getAllBookingData
                                .value
                                ?.result
                                ?.vehicleId
                                ?.specs
                                ?.length,
                            itemBuilder: (context, index) {
                              final items = fetchSdBookingDetailsController
                                  .getAllBookingData
                                  .value
                                  ?.result
                                  ?.vehicleId
                                  ?.specs?[index];
                              return buildTile(
                                items?.label ?? '',
                                items?.value.toString() ?? '',
                              );
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InsuranceOptions extends StatefulWidget {
  final String vehicleId;
  final bool isHomePage;

  const InsuranceOptions(
      {super.key, required this.vehicleId, required this.isHomePage});

  @override
  State<InsuranceOptions> createState() => _InsuranceOptionsState();
}

class _InsuranceOptionsState extends State<InsuranceOptions> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
      Get.put(FetchSdBookingDetailsController());

  @override
  void initState() {
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(
        widget.vehicleId, widget.isHomePage);
  }

  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              "Insurance & options",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Green Info Blocks
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          "Free cancellation up to 48 hours before pickup",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Icon(Icons.check, color: Colors.green, size: 20),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: const [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Available for your dates",
                                style: TextStyle(fontSize: 14)),
                            SizedBox(height: 2),
                            Text(
                              "Get instant booking confirmation from a rental company",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check, color: Colors.green, size: 20),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Insurance Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Comprehensive insurance",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Excess amount of 20% of the damage cost.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.shield_outlined, color: Colors.green, size: 22),
              ],
            ),
            const SizedBox(height: 20),

            // Collision Damage Waiver (CDW)
            Obx(() {
              final result = fetchSdBookingDetailsController
                  .getAllBookingData.value?.result;
              final tarrifs = result?.tarrifs;
              final selected = result?.tarrifSelected;

              String? amount;
              if (selected == 'Daily') {
                amount = tarrifs?[0].collisionDamageWaiver?.toStringAsFixed(2);
              } else if (selected == 'Weekly') {
                amount = tarrifs?[1].collisionDamageWaiver?.toString();
              } else if (selected == 'Monthly') {
                amount = tarrifs?[2].collisionDamageWaiver?.toString();
              } else {
                amount = tarrifs?[0].collisionDamageWaiver?.toString();
              }

              return buildOptionTile(
                "Collision Damage Waiver",
                "",
                fetchSdBookingDetailsController.cdw.value,
                (val) {
                  setState(
                      () => fetchSdBookingDetailsController.cdw.value = val);
                  fetchSdBookingDetailsController.fetchBookingDetails(
                      widget.vehicleId, false);
                },
                trailing: priceChipUI(amount),
              );
            }),

            // Personal Accidental Insurance (PAI)
            Obx(() {
              final result = fetchSdBookingDetailsController
                  .getAllBookingData.value?.result;
              final tarrifs = result?.tarrifs;
              final selected = result?.tarrifSelected;

              String? amount;
              if (selected == 'Daily') {
                amount = tarrifs?[0].parsonalAccidentalInsurance?.toString();
              } else if (selected == 'Weekly') {
                amount = tarrifs?[1].parsonalAccidentalInsurance?.toString();
              } else if (selected == 'Monthly') {
                amount = tarrifs?[2].parsonalAccidentalInsurance?.toString();
              } else {
                amount = tarrifs?[0].parsonalAccidentalInsurance?.toString();
              }

              return buildOptionTile(
                "Personal Accidental Insurance",
                "",
                fetchSdBookingDetailsController.pai.value,
                (val) {
                  setState(
                      () => fetchSdBookingDetailsController.pai.value = val);
                  fetchSdBookingDetailsController.fetchBookingDetails(
                      widget.vehicleId, false);
                },
                trailing: priceChipUI(amount),
              );
            }),

            // Deposit Free Ride
            Obx(() {
              final result = fetchSdBookingDetailsController
                  .getAllBookingData.value?.result;
              final tarrifs = result?.tarrifs;

              Widget buildTitleWithChip(String? amount) {
                return Row(
                  children: [
                    const Text(
                      "Enjoy a deposit-free ride for ",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (amount != null) priceChipUI(amount),
                  ],
                );
              }

              if (result?.tarrifSelected == 'Daily') {
                return buildOptionTile(
                  buildTitleWithChip(
                      tarrifs?[0].securityDeposit?.amount?.toString()),
                  "You can rent a car without any deposit by including the additional service fee in your rental price",
                  fetchSdBookingDetailsController.freeDeposit.value,
                  (val) {
                    setState(() => fetchSdBookingDetailsController
                        .freeDeposit.value = val);
                    fetchSdBookingDetailsController.fetchBookingDetails(
                        widget.vehicleId, false);
                  },
                );
              } else if (result?.tarrifSelected == 'Weekly') {
                return buildOptionTile(
                  buildTitleWithChip(
                      tarrifs?[1].securityDeposit?.amount?.toString()),
                  "You can rent a car without any deposit by including the additional service fee in your rental price",
                  fetchSdBookingDetailsController.freeDeposit.value,
                  (val) {
                    setState(() => fetchSdBookingDetailsController
                        .freeDeposit.value = val);
                    fetchSdBookingDetailsController.fetchBookingDetails(
                        widget.vehicleId, false);
                  },
                );
              } else if (result?.tarrifSelected == 'Monthly') {
                return buildOptionTile(
                  buildTitleWithChip(
                      tarrifs?[2].securityDeposit?.amount?.toString()),
                  "You can rent a car without any deposit by including the additional service fee in your rental price",
                  fetchSdBookingDetailsController.freeDeposit.value,
                  (val) {
                    setState(() => fetchSdBookingDetailsController
                        .freeDeposit.value = val);
                    fetchSdBookingDetailsController.fetchBookingDetails(
                        widget.vehicleId, false);
                  },
                );
              }

              // Default
              return buildOptionTile(
                buildTitleWithChip(
                    tarrifs?[0].securityDeposit?.amount?.toString()),
                "You can rent a car without any deposit by including the additional service fee in your rental price",
                fetchSdBookingDetailsController.freeDeposit.value,
                (val) => setState(() =>
                    fetchSdBookingDetailsController.freeDeposit.value = val),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildOptionTile(
      dynamic title, String subtitle, bool value, Function(bool) onChanged,
      {Widget? trailing}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: title is String
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        if (subtitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title, // Row with chip
                        if (subtitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ),
                      ],
                    ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.green,
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Widget priceChipUI(String? amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Text(
        "AED $amount",
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }
}

// important info
class ImportantInfoCard extends StatefulWidget {
  const ImportantInfoCard({Key? key}) : super(key: key);

  @override
  State<ImportantInfoCard> createState() => _ImportantInfoCardState();
}

class _ImportantInfoCardState extends State<ImportantInfoCard> {
  void showInfoBottomSheet(BuildContext context,
      {required String title, required String body}) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Body text
              Text(
                body,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE8262B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Important info",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          InfoTile(
            icon: Icons.account_balance_wallet_outlined,
            title: "Payment on pickup",
            subtitle: "Credit card, Debit card (Visa, Mastercard)",
            linkText: "Other options?",
            onTap: () {
              showInfoBottomSheet(context,
                  title: 'Payment',
                  body:
                      'Other payment options include Debit Card, Credit Card, Net Banking, etc.');
            },
          ),
          const Divider(height: 1),
          InfoTile(
            icon: Icons.person_outline,
            title: "Minimum age",
            subtitle: "21 y.o.",
            linkText: "Other age?",
            onTap: () {
              showInfoBottomSheet(context,
                  title: 'Minimum age',
                  body:
                      'Drivers must be at least 25 years old. Age requirements may vary depending on the location and vehicle type.');
            },
          ),
          const Divider(height: 1),
          InfoTile(
            icon: Icons.sports_motorsports_outlined,
            title: "Minimum driving experience",
            subtitle: "1 year",
            linkText: "Less experienced?",
            onTap: () {
              showInfoBottomSheet(context,
                  title: 'Minimum driving experience',
                  body:
                      'A minimum of 6 months of driving experience is required. If you have less experience, additional conditions may apply.');
            },
          ),
          const Divider(height: 1),
          InfoTile(
            icon: Icons.description_outlined,
            title: "Required documents",
            trailing: const Icon(Icons.chevron_right, color: Colors.black54),
            onTap: () {
              showInfoBottomSheet(context,
                  title: 'Required documents',
                  body:
                      'Required documents include your driving license or international driving license, identity proof (passport, emirates id), and a valid visa document in case of non resident.');
            },
          ),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? linkText;
  final Widget? trailing;
  final VoidCallback? onTap;

  const InfoTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.linkText,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (linkText != null)
                          GestureDetector(
                            onTap: onTap,
                            child: Text(
                              linkText!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}


class PickupReturnLocationPage extends StatefulWidget {
  final String vehicleId;
  final bool isHomePage;

  const PickupReturnLocationPage({
    super.key,
    required this.vehicleId,
    required this.isHomePage,
  });

  @override
  State<PickupReturnLocationPage> createState() =>
      _PickupReturnLocationPageState();
}

class _PickupReturnLocationPageState extends State<PickupReturnLocationPage> {
  final ServiceHubController serviceHubController =
  Get.put(ServiceHubController());
  final GoogleLatLngController googleLatLngController =
  Get.put(GoogleLatLngController());
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
  Get.put(FetchSdBookingDetailsController());
  final SdCreateStripePaymentController sdCreateStripePaymentController =
  Get.put(SdCreateStripePaymentController());

  bool returnToSameLocation = false;

  @override
  void initState() {
    super.initState();
    serviceHubController.fetchServicehub();

    // Keep them empty initially → no selection
    fetchSdBookingDetailsController.selectedPickupOption.value =
        fetchSdBookingDetailsController.selectedPickupOption.value;
    fetchSdBookingDetailsController.selectedDropoffOption.value =
        fetchSdBookingDetailsController.selectedDropoffOption.value;

    returnToSameLocation = fetchSdBookingDetailsController.isSameLocation.value;
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Bring the car to me",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Delivery option
              Obx(() => _buildOptionTile(
                title: sdCreateStripePaymentController.sourceCity.value ==
                    ''
                    ? "Select delivery address"
                    : sdCreateStripePaymentController.sourceCity.value,
                subtitle: sdCreateStripePaymentController.sourceCity.value ==
                    ''
                    ? "AED 0.0"
                    : 'AED ${fetchSdBookingDetailsController.delivery_charge.value.toString()}',
                value: "delivery_address",
                groupValue: fetchSdBookingDetailsController
                    .selectedPickupOption.value.isEmpty
                    ? null
                    : fetchSdBookingDetailsController.selectedPickupOption.value,
                error: fetchSdBookingDetailsController.showPickupError.value,
                onChanged: (val) {
                  fetchSdBookingDetailsController.selectedPickupOption.value =
                      val ?? "";
                  fetchSdBookingDetailsController.showPickupError.value = false;
                  Navigator.of(context).push(
                    Platform.isIOS
                        ? CupertinoPageRoute(
                      builder: (_) => SelfDriveMostPopularLocation(
                        vehicleId: widget.vehicleId,
                        isHomePage: widget.isHomePage,
                      ),
                    )
                        : MaterialPageRoute(
                      builder: (_) => SelfDriveMostPopularLocation(
                        vehicleId: widget.vehicleId,
                        isHomePage: widget.isHomePage,
                      ),
                    ),
                  );
                },
              )),

              const SizedBox(height: 16),
              const Text(
                "Free pickup locations",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),

              Obx(() => _buildLocationTile(
                address: serviceHubController
                    .serviceHubResponse.value?.result?.first.address ??
                    '',
                value: "pickup_location_1",
                price: 'AED 0.0',
                groupValue: fetchSdBookingDetailsController
                    .selectedPickupOption.value.isEmpty
                    ? null
                    : fetchSdBookingDetailsController.selectedPickupOption.value,
                error: fetchSdBookingDetailsController.showPickupError.value,
                onChanged: (val) {
                  fetchSdBookingDetailsController.selectedPickupOption.value =
                      val ?? "";
                  fetchSdBookingDetailsController.showPickupError.value = false;
                  fetchSdBookingDetailsController.isFreePickup.value = true;
                  fetchSdBookingDetailsController.fetchBookingDetails(
                      widget.vehicleId, false);
                },
              )),

              const SizedBox(height: 16),

              // Return to same location
              Obx(() => SwitchListTile(
                value: fetchSdBookingDetailsController.isSameLocation.value,
                onChanged: (val) {
                  fetchSdBookingDetailsController.isSameLocation.value = val;
                  returnToSameLocation = val;
                  fetchSdBookingDetailsController.fetchBookingDetails(
                      widget.vehicleId, false);
                },
                title: const Text(
                  "Return to the same location",
                  style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              )),

              // Dropoff section only if not same
              Obx(() =>
              fetchSdBookingDetailsController.isSameLocation.value == false
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "Take the car from me",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  _buildOptionTile(
                    title: sdCreateStripePaymentController
                        .destinationCity.value ==
                        ''
                        ? "Select return delivery address"
                        : sdCreateStripePaymentController
                        .destinationCity.value,
                    subtitle:
                    'AED ${fetchSdBookingDetailsController.collection_charges.value.toString()}',
                    value: "return_address",
                    groupValue: fetchSdBookingDetailsController
                        .selectedDropoffOption.value.isEmpty
                        ? null
                        : fetchSdBookingDetailsController
                        .selectedDropoffOption.value,
                    error: fetchSdBookingDetailsController
                        .showDropoffError.value,
                    onChanged: (val) {
                      fetchSdBookingDetailsController
                          .selectedDropoffOption.value = val ?? "";
                      fetchSdBookingDetailsController
                          .showDropoffError.value = false;
                      fetchSdBookingDetailsController
                          .isSameLocation.value = false;
                      Navigator.of(context).push(
                        Platform.isIOS
                            ? CupertinoPageRoute(
                          builder: (_) =>
                              SelfDriveReturnPopularLocation(
                                  vehicleId:
                                  widget.vehicleId,
                                  isHomePage:
                                  widget.isHomePage),
                        )
                            : MaterialPageRoute(
                          builder: (_) =>
                              SelfDriveReturnPopularLocation(
                                  vehicleId:
                                  widget.vehicleId,
                                  isHomePage:
                                  widget.isHomePage),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    "Free dropoff locations",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  Obx(() => _buildLocationTile(
                    address: serviceHubController.serviceHubResponse
                        .value?.result?.first.address ??
                        '',
                    value: "pickup_location_1",
                    price: 'AED 0.0',
                    groupValue: fetchSdBookingDetailsController
                        .selectedDropoffOption.value.isEmpty
                        ? null
                        : fetchSdBookingDetailsController
                        .selectedDropoffOption.value,
                    error: fetchSdBookingDetailsController
                        .showDropoffError.value,
                    onChanged: (val) {
                      fetchSdBookingDetailsController
                          .selectedDropoffOption.value = val ?? "";
                      fetchSdBookingDetailsController
                          .showDropoffError.value = false;
                      fetchSdBookingDetailsController.isFreeDrop.value =
                      true;
                      fetchSdBookingDetailsController.isSameLocation.value =
                      false;
                      fetchSdBookingDetailsController.fetchBookingDetails(
                          widget.vehicleId, false);
                    },
                  )),
                ],
              )
                  : const SizedBox()),

              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }

  // ==================== Widgets with error display ====================

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required String value,
    required String? groupValue,
    required bool error,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(
                  color: error ? Colors.red : Colors.transparent, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Radio<String>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: error ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.blue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error)
          const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 4),
            child: Text(
              "Please select an option to continue",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationTile({
    required String address,
    required String value,
    required String? price,
    required String? groupValue,
    required bool error,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(
                  color: error ? Colors.red : Colors.transparent, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio<String>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: error ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      if (price != null && price.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text("AED 0.0",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.blue)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error)
          const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 4),
            child: Text(
              "Please select an option to continue",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

