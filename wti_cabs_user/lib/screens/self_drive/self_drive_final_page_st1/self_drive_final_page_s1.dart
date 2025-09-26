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
import 'package:wti_cabs_user/screens/self_drive/self_drive_popular_location/self_drive_most_popular_location.dart';

import '../../../core/controller/self_drive/google_lat_lng_controller/google_lat_lng_controller.dart';
import '../../../core/controller/self_drive/search_inventory_sd_controller/search_inventory_sd_controller.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../self_drive_popular_location/self_drive_return_popular_location.dart';

class SelfDriveFinalPageS1 extends StatefulWidget {
  final String? vehicleId;
  final bool? isHomePage;
  const SelfDriveFinalPageS1({super.key, this.vehicleId, this.isHomePage});

  @override
  State<SelfDriveFinalPageS1> createState() => _SelfDriveFinalPageS1State();
}

class _SelfDriveFinalPageS1State extends State<SelfDriveFinalPageS1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      body: SafeArea(child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  InkWell(
                    onTap:(){
                      GoRouter.of(context).pop();
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16,
                      child: Icon(Icons.arrow_back, color: Colors.black, size: 22),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                          child: Text(
                            'Step 1 of 2',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
              child: BookYourCarScreen(vehicleId: widget.vehicleId??'', isHomePage: widget.isHomePage??false,),
            ),
            CarRentalCard(vehicleId: widget.vehicleId??'', isHomePage: widget.isHomePage??false),
            PricingTiles(vehicleId: widget.vehicleId??'', isHomePage: widget.isHomePage??false),
            SizedBox(height: 12,),
            CarServiceOverview(vehicleId: widget.vehicleId??'', isHomePage: widget.isHomePage??false),
            InsuranceOptions(vehicleId: widget.vehicleId??'', isHomePage: widget.isHomePage??false),
            ImportantInfoCard(),
            PickupReturnLocationPage(vehicleId: widget.vehicleId??'', isHomePage: widget.isHomePage??false,)
          ],
        ),
      )),
    );
  }
}

class BookYourCarScreen extends StatefulWidget {
  final String vehicleId;
  final bool isHomePage;
  const BookYourCarScreen({Key? key, required this.vehicleId, required this.isHomePage}) : super(key: key);

  @override
  State<BookYourCarScreen> createState() => _BookYourCarScreenState();
}

class _BookYourCarScreenState extends State<BookYourCarScreen> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController = Get.put(FetchSdBookingDetailsController());
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, widget.isHomePage);
  }

  @override
  Widget build(BuildContext context) {
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
                    itemCount: fetchSdBookingDetailsController
                        .getAllBookingData.value
                        ?.result
                        ?.vehicleId
                        ?.images
                        ?.length ??
                        0,
                    itemBuilder: (context, imgIndex, realIndex) {
                      final img = fetchSdBookingDetailsController
                          .getAllBookingData
                          .value
                          ?.result
                          ?.vehicleId
                          ?.images![imgIndex];
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
                      autoPlayAnimationDuration: const Duration(milliseconds: 800),
                      onPageChanged: (imgIndex, reason) {
                        setState(() {
                          _currentIndex = imgIndex;
                        });
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black87.withOpacity(0.7),
                      borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            "We’ll try to provide the model you chose, but the car may vary in make, model, or color within the same category",
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.close,
                            color: Colors.white.withOpacity(0.75), size: 24),
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
  const CarRentalCard({super.key, required this.vehicleId, required this.isHomePage});

  @override
  State<CarRentalCard> createState() => _CarRentalCardState();
}

class _CarRentalCardState extends State<CarRentalCard> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController = Get.put(FetchSdBookingDetailsController());

  @override
  void initState() {
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, widget.isHomePage);
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
              const Icon(Icons.directions_car, size: 20, color: Color(0xFF000000),),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                      fetchSdBookingDetailsController.getAllBookingData.value?.result?.vehicleId?.modelName ?? '',
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
                if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Daily')  Expanded(
                  child: Text(
                    '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].pickup?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].pickup?.time} - ${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].drop?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].drop?.time}',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Weekly')  Expanded(
                  child: Text(
                    '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].pickup?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].pickup?.time} - ${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].drop?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].drop?.time}',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Monthly')  Expanded(
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
  const PricingTiles({Key? key, required this.vehicleId, required this.isHomePage}) : super(key: key);

  @override
  State<PricingTiles> createState() => _PricingTilesState();
}

class _PricingTilesState extends State<PricingTiles> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController = Get.put(FetchSdBookingDetailsController());
  final SearchInventorySdController searchInventorySdController = Get.put(SearchInventorySdController());

  int selectedIndex = 0;
  final List<String> tariffTypes = ["Daily", "Weekly", "Monthly"];

  @override
  void initState() {
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, widget.isHomePage);
    selectedIndex = tariffTypes.indexOf(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected ?? '');
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
            children: List.generate(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?.length ?? 0, (index) {
              final item = fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[index];
              final isSelected = index == selectedIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                      if(selectedIndex == 0){
                        searchInventorySdController.selectedIndex.value = 0;
                      }
                      if(selectedIndex == 1){
                        searchInventorySdController.selectedIndex.value = 0;
                      }
                      if(selectedIndex == 2){
                        searchInventorySdController.selectedIndex.value = 1;
                      }
                      fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.deepOrange : Colors.transparent,
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
                  if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Daily') Obx(() => Text(
                    "${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].mileageLimit} km",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
                  if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Weekly') Obx(() => Text(
                    "${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].mileageLimit} km",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
                  if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Monthly') Obx(() => Text(
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
  const CarServiceOverview({super.key, required this.vehicleId, required this.isHomePage});

  @override
  State<CarServiceOverview> createState() => _CarServiceOverviewState();
}

class _CarServiceOverviewState extends State<CarServiceOverview>
    with SingleTickerProviderStateMixin {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController = Get.put(FetchSdBookingDetailsController());
  bool _isExpanded = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, widget.isHomePage);
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
    {"icon": Icons.payment, "title": "Payment Modes", "value": "Crypto, Cash & more"},
    {"icon": Icons.directions_car, "title": "Body Type", "value": "Sports Car"},
    {"icon": Icons.local_taxi, "title": "Salik / Toll Charges", "value": "AED 5"},
    {"icon": Icons.directions_car_filled, "title": "Make", "value": "Audi"},
    {"icon": Icons.directions_car_outlined, "title": "Model", "value": "R8 Performance Spyder"},
    {"icon": Icons.settings, "title": "Gearbox", "value": "Auto"},
    {"icon": Icons.event_seat, "title": "Seating Capacity", "value": "2 passengers"},
    {"icon": Icons.sensor_door, "title": "No. of Doors", "value": "2"},
    {"icon": Icons.work_outline, "title": "Fits No. of Bags", "value": "1"},
    {"icon": Icons.local_gas_station, "title": "Fuel Type", "value": "Petrol"},
    {"icon": Icons.color_lens, "title": "Exterior / Interior Color", "value": "Yellow / Black"},
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
                      itemCount: fetchSdBookingDetailsController.getAllBookingData.value?.result?.vehicleId?.specs?.length,
                      itemBuilder: (context, index) {
                        final items = fetchSdBookingDetailsController.getAllBookingData.value?.result?.vehicleId?.specs?[index];
                        return buildTile(
                          items?.label??'',
                          items?.value.toString()??'',
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

  const InsuranceOptions({super.key, required this.vehicleId, required this.isHomePage});

  @override
  State<InsuranceOptions> createState() => _InsuranceOptionsState();
}

class _InsuranceOptionsState extends State<InsuranceOptions> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController = Get.put(FetchSdBookingDetailsController());
  @override
  void initState() {
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, widget.isHomePage);
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

            // Add-ons with toggles
          Obx(() {
            if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Daily'){
              return buildOptionTile("Collison Damage Waiver · AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].collisionDamageWaiver}", "", fetchSdBookingDetailsController.cdw.value,
                  (val) {
                    setState(() => fetchSdBookingDetailsController.cdw.value = val);
                    fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);

                  });
            }
            else if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Weekly'){
              return buildOptionTile("Collison Damage Waiver · AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].collisionDamageWaiver}", "", fetchSdBookingDetailsController.cdw.value,
                  (val) {
                    setState(() => fetchSdBookingDetailsController.cdw.value = val);
                    fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);

                  });
            }
            else if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Monthly'){
              return buildOptionTile("Collison Damage Waiver · AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].collisionDamageWaiver}", "", fetchSdBookingDetailsController.cdw.value,
                  (val) {
                    setState(() => fetchSdBookingDetailsController.cdw.value = val);
                    fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);

                  });
            }
            return buildOptionTile("Collison Damage Waiver · AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].collisionDamageWaiver}", "", fetchSdBookingDetailsController.cdw.value,
                    (val) {
                      setState(() => fetchSdBookingDetailsController.cdw.value = val);
                      fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);

                    });

          }),
          Obx(() {
            if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Daily'){
              return buildOptionTile("Personal Accidental Insurance · AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].parsonalAccidentalInsurance}", "", fetchSdBookingDetailsController.pai.value,
                      (val) {
                        setState(() => fetchSdBookingDetailsController.pai.value = val);
                        fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);
                      });
            }
            if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Weekly'){
              return buildOptionTile("Personal Accidental Insurance · AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].parsonalAccidentalInsurance}", "", fetchSdBookingDetailsController.pai.value,
                      (val) {
                        setState(() => fetchSdBookingDetailsController.pai.value = val);
                        fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);

                      });
            }
            if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Monthly'){
              return buildOptionTile("Personal Accidental Insurance · AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].parsonalAccidentalInsurance}", "", fetchSdBookingDetailsController.pai.value,
                      (val) {
                        setState(() => fetchSdBookingDetailsController.pai.value = val);
                        fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);
                      });
            }
            return buildOptionTile("Personal Accidental Insurance · AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].parsonalAccidentalInsurance}", "", fetchSdBookingDetailsController.pai.value,
                  (val) {
                    setState(() => fetchSdBookingDetailsController.pai.value = val);
                    fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);
                  });
          }),
          Obx(() {
            if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Daily'){
             return buildOptionTile(
                "Enjoy a deposit-free ride for AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].securityDeposit?.amount}",
                "You can rent a car without any deposit by including the additional service fee in your rental price",
               fetchSdBookingDetailsController.freeDeposit.value,
                    (val) {
                      setState(() => fetchSdBookingDetailsController.freeDeposit.value = val);
                      fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);
                    },
              );
            }
            else if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Weekly'){
             return buildOptionTile(
                "Enjoy a deposit-free ride for AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].securityDeposit?.amount}",
                "You can rent a car without any deposit by including the additional service fee in your rental price",
               fetchSdBookingDetailsController.freeDeposit.value,
                    (val) {
                      setState(() => fetchSdBookingDetailsController.freeDeposit.value = val);
                      fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);
                    },
              );
            }
            else if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Monthly'){
            return  buildOptionTile(
                "Enjoy a deposit-free ride for AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].securityDeposit?.amount}",
                "You can rent a car without any deposit by including the additional service fee in your rental price",
              fetchSdBookingDetailsController.freeDeposit.value,
                    (val) {
                      setState(() => fetchSdBookingDetailsController.freeDeposit.value = val);
                      fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);

                    },
              );
            }
            return buildOptionTile(
              "Enjoy a deposit-free ride for AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].securityDeposit?.amount}",
              "You can rent a car without any deposit by including the additional service fee in your rental price",
              fetchSdBookingDetailsController.freeDeposit.value,
                  (val) => setState(() => fetchSdBookingDetailsController.freeDeposit.value = val),
            );
          }),
          ],
        ),
      ),
    );
  }

  Widget buildOptionTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
              showInfoBottomSheet(context, title: 'Payment', body: 'Other payment options include Debit Card, Credit Card, Net Banking, etc.');
            },
          ),
          const Divider(height: 1),
          InfoTile(
            icon: Icons.person_outline,
            title: "Minimum age",
            subtitle: "21 y.o.",
            linkText: "Other age?",
            onTap: () {
              showInfoBottomSheet(context, title: 'Minimum age', body: 'Drivers must be at least 25 years old. Age requirements may vary depending on the location and vehicle type.');
            },
          ),
          const Divider(height: 1),
          InfoTile(
            icon: Icons.sports_motorsports_outlined,
            title: "Minimum driving experience",
            subtitle: "1 year",
            linkText: "Less experienced?",
            onTap: () {
              showInfoBottomSheet(context, title: 'Minimum driving experience', body: 'A minimum of 6 months of driving experience is required. If you have less experience, additional conditions may apply.');
            },
          ),
          const Divider(height: 1),
          InfoTile(
            icon: Icons.description_outlined,
            title: "Required documents",
            trailing: const Icon(Icons.chevron_right, color: Colors.black54),
            onTap: () {
              showInfoBottomSheet(context, title: 'Required documents', body:'Required documents include your driving license or international driving license, identity proof (passport, emirates id), and a valid visa document in case of non resident.');
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

  const PickupReturnLocationPage({super.key, required this.vehicleId, required this.isHomePage,});

  @override
  State<PickupReturnLocationPage> createState() =>
      _PickupReturnLocationPageState();
}

class _PickupReturnLocationPageState extends State<PickupReturnLocationPage> {
  final ServiceHubController serviceHubController = Get.put(ServiceHubController());
  final GoogleLatLngController googleLatLngController =
  Get.put(GoogleLatLngController());
  final FetchSdBookingDetailsController fetchSdBookingDetailsController = Get.put(FetchSdBookingDetailsController());

  @override
  void initState() {
    super.initState();
    serviceHubController.fetchServicehub();
  }

  String? selectedPickupOption;
  String? selectedDropoffOption;
  bool returnToSameLocation = true;

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
              _buildOptionTile(
                title: "Select delivery address",
                subtitle: "Delivery policy",
                value: "delivery_address",
                groupValue: selectedPickupOption,
                onChanged: (val) async{
                  setState(() => selectedPickupOption = val);
                  Navigator.of(context).push(
                    Platform.isIOS
                        ? CupertinoPageRoute(
                      builder: (_) =>  SelfDriveMostPopularLocation(vehicleId: widget.vehicleId, isHomePage: widget.isHomePage,),
                    )
                        : MaterialPageRoute(
                      builder: (_) =>  SelfDriveMostPopularLocation(vehicleId: widget.vehicleId, isHomePage: widget.isHomePage,),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                "Free pickup locations",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Obx(()=>  _buildLocationTile(
                address: serviceHubController.serviceHubResponse.value?.result?.first.address??'',
                value: "pickup_location_1",
                groupValue: selectedPickupOption,
                onChanged: (val) {
                  setState(() => selectedPickupOption = val);
                  fetchSdBookingDetailsController
                      .isFreePickup.value = true;
                  fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);
                },
              )),
              const SizedBox(height: 16),
              SwitchListTile(
                value: returnToSameLocation,
                onChanged: (val) {
                  setState(() => returnToSameLocation = val);
                  fetchSdBookingDetailsController.isSameLocation.value = !fetchSdBookingDetailsController.isSameLocation.value;
                  fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);

                },
                title: const Text(
                  "Return to the same location",
                  style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              fetchSdBookingDetailsController.isSameLocation.value == false ?   Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "Take the car from me",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildOptionTile(
                    title: "Select return delivery address",
                    subtitle: "Return policy",
                    value: "return_address",
                    groupValue: selectedDropoffOption,
                    onChanged: (val) {
                      setState(() => selectedDropoffOption = val);
                      fetchSdBookingDetailsController.isSameLocation.value = false; // important
                      Navigator.of(context).push(
                        Platform.isIOS
                            ? CupertinoPageRoute(
                          builder: (_) =>  SelfDriveReturnPopularLocation(vehicleId: widget.vehicleId, isHomePage: widget.isHomePage,),
                        )
                            : MaterialPageRoute(
                          builder: (_) =>  SelfDriveReturnPopularLocation(vehicleId: widget.vehicleId, isHomePage: widget.isHomePage,),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Free dropoff locations",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Obx(()=>  _buildLocationTile(
                    address: serviceHubController.serviceHubResponse.value?.result?.first.address??'',
                    value: "pickup_location_1",
                    groupValue: selectedDropoffOption,
                    onChanged: (val) {
                      setState(() => selectedDropoffOption = val);
                      fetchSdBookingDetailsController
                          .isFreeDrop.value = true;
                      fetchSdBookingDetailsController.isSameLocation.value = false; // important

                      fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, false);
                    },
                  )),
                ],
              ) : SizedBox()

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required String value,
    required String? groupValue,
    required Function(String?) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[100], // Grey background like location tile
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
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
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile({
    required String address,
    required String value,
    required String? groupValue,
    required Function(String?) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[100], // Same grey shade
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}

