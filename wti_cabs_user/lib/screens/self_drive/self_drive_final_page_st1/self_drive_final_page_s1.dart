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
import 'package:wti_cabs_user/common_widget/loader/shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
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
  final bool? shouldScrollToBottom;
  final bool? isNavigateFromHome;
  const SelfDriveFinalPageS1(
      {super.key,
      this.vehicleId,
      this.isHomePage,
      this.fromReturnMapPage,
      this.shouldScrollToBottom, this.isNavigateFromHome});

  @override
  State<SelfDriveFinalPageS1> createState() => _SelfDriveFinalPageS1State();
}

class _SelfDriveFinalPageS1State extends State<SelfDriveFinalPageS1> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
      Get.put(FetchSdBookingDetailsController());
  final SearchInventorySdController searchInventorySdController =
      Get.put(SearchInventorySdController());
  final FileUploadValidController fileUploadController =
      Get.put(FileUploadValidController());
  final CurrencyController currencyController = Get.put(CurrencyController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSdBookingDetailsController.isSameLocation.value =
          widget.fromReturnMapPage == true ? false : true;

      if (widget.shouldScrollToBottom ?? false) scrollToBottom();
    });
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void showFareBreakdownSheet(
      BuildContext context, FetchSdBookingDetailsController controller) {
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

          Widget convertedFare(double amount) {
            return FutureBuilder<double>(
              future: currencyController.convertPrice(amount),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    "Error in conversion",
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  );
                }
                final convertedPrice = snapshot.data ?? 0.0;
                return Text(
                  "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
                );
              },
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if ((fareDetails.baseFare ?? 0) != 0)
                  _fareRow("Base fare", convertedFare(fareDetails.baseFare?.toDouble() ?? 0)),

                if (fetchSdBookingDetailsController.cdw == true &&
                    (selectedTariff?.collisionDamageWaiver ?? 0) != 0)
                  _fareRow(
                    "Collision Damage Waiver",
                    convertedFare(selectedTariff?.collisionDamageWaiver?.toDouble() ?? 0),
                  ),

                if (fetchSdBookingDetailsController.pai == true &&
                    (selectedTariff?.parsonalAccidentalInsurance ?? 0) != 0)
                  _fareRow(
                    "Personal Accidental Insurance",
                    convertedFare(
                        selectedTariff?.parsonalAccidentalInsurance?.toDouble() ?? 0),
                  ),

                if ((fareDetails.delivery_charges ?? 0) != 0)
                  _fareRow("Delivery Charge",
                      convertedFare(fareDetails.delivery_charges?.toDouble() ?? 0)),

                if ((fareDetails.collection_charges ?? 0) != 0)
                  _fareRow("Collection Charge",
                      convertedFare(fareDetails.collection_charges?.toDouble() ?? 0)),

                if ((fareDetails.tax ?? 0) != 0)
                  _fareRow("Tax", convertedFare(fareDetails.tax?.toDouble() ?? 0)),

                if ((fareDetails.deposit_free_ride ?? 0) != 0)
                  _fareRow("Deposite Free Rides",
                      convertedFare(fareDetails.deposit_free_ride?.toDouble() ?? 0)),



                const Divider(height: 24, thickness: 1),

                _fareRow(
                  "Grand Total",
                  convertedFare(fareDetails.grandTotal?.toDouble() ?? 0),
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


  Widget _fareRow(String title, Widget amount, {bool isTotal = false}) {
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
          amount
        ],
      ),
    );
  }

  void validateAndProceed(BuildContext context) async {
    final controller = fetchSdBookingDetailsController;

    // ✅ Validate pickup
    controller.showPickupError.value =
        controller.selectedPickupOption.value.isEmpty;

    // ✅ Validate dropoff only if "Return to same location" is OFF
    if (!controller.isSameLocation.value) {
      controller.showDropoffError.value =
          controller.selectedDropoffOption.value.isEmpty;
    } else {
      controller.showDropoffError.value = false;
    }

    // ✅ If validation fails
    if (controller.showPickupError.value || controller.showDropoffError.value) {
      // Wait for UI to rebuild after state changes
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    // ✅ Validation passed — show shimmer overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FullPageShimmer(),
    );

    // ✅ Wait a frame to ensure the dialog is displayed
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Simulate loading
      await Future.delayed(const Duration(seconds: 1));

      // Navigate to next page
      if (context.mounted) {
        Navigator.of(context).pop(); // close shimmer first
        Navigator.of(context).push(
          Platform.isIOS
              ? CupertinoPageRoute(
            builder: (_) =>
                SelfDriveFinalPageS2(vehicleId: widget.vehicleId, isHomePage: false),
          )
              : MaterialPageRoute(
            builder: (_) =>
                SelfDriveFinalPageS2(vehicleId: widget.vehicleId, isHomePage: false),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      rethrow;
    }
  }



  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSdBookingDetailsController.isSameLocation.value =
          widget.fromReturnMapPage == true ? false : true;
    });

    return PopScope(
      canPop: true, // 🚀 Stops the default "pop and close app"
      onPopInvoked: (didPop) {
        if(widget.isHomePage == true){
          GoRouter.of(context).push(AppRoutes.selfDriveBottomSheet);
        }
        else if(widget.isHomePage == false) {
          searchInventorySdController.fetchAllInventory(context: context);
        }

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
          controller: _scrollController, // ✅ attach here
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        searchInventorySdController.fetchAllInventory(
                            context: context);
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 16,
                        child: Icon(Icons.arrow_back,
                            color: Colors.black, size: 22),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Book your car',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Total Fare | ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Obx(() {
                            if (fetchSdBookingDetailsController
                                    .getAllBookingData
                                    .value
                                    ?.result
                                    ?.tarrifSelected ==
                                'Daily') {
                              return FutureBuilder<double>(
                                future: currencyController.convertPrice(
                                  (fetchSdBookingDetailsController
                                      .getAllBookingData.value
                                      ?.result
                                      ?.tarrifs
                                      ?.first
                                      .fareDetails
                                      ?.grandTotal ??
                                      0)
                                      .toDouble(),
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Text(
                                      "Error in conversion",
                                      style: TextStyle(color: Colors.red, fontSize: 11),
                                    );
                                  }

                                  final convertedPrice = snapshot.data ?? 0.0;

                                  return Text(
                                    "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  );
                                },
                              );

                            } else if (fetchSdBookingDetailsController
                                    .getAllBookingData
                                    .value
                                    ?.result
                                    ?.tarrifSelected ==
                                'Weekly') {
                              return FutureBuilder<double>(
                                future: currencyController.convertPrice(
                                  (fetchSdBookingDetailsController
                                      .getAllBookingData.value
                                      ?.result
                                      ?.tarrifs?[1]
                                      .fareDetails
                                      ?.grandTotal ??
                                      0)
                                      .toDouble(),
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Text(
                                      "Error in conversion",
                                      style: TextStyle(color: Colors.red, fontSize: 11),
                                    );
                                  }

                                  final convertedPrice = snapshot.data ?? 0.0;

                                  return Text(
                                    "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  );
                                },
                              );

                            } else if (fetchSdBookingDetailsController
                                    .getAllBookingData
                                    .value
                                    ?.result
                                    ?.tarrifSelected ==
                                'Monthly') {
                              return FutureBuilder<double>(
                                future: currencyController.convertPrice(
                                  (fetchSdBookingDetailsController
                                      .getAllBookingData.value
                                      ?.result
                                      ?.tarrifs?[2]
                                      .fareDetails
                                      ?.grandTotal ??
                                      0)
                                      .toDouble(),
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Text(
                                      "Error in conversion",
                                      style: TextStyle(color: Colors.red, fontSize: 11),
                                    );
                                  }

                                  final convertedPrice = snapshot.data ?? 0.0;

                                  return Text(
                                    "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  );
                                },
                              );
                            }
                            return FutureBuilder<double>(
                              future: currencyController.convertPrice(
                                (fetchSdBookingDetailsController
                                    .getAllBookingData.value
                                    ?.result
                                    ?.tarrifs
                                    ?.first
                                    .fareDetails
                                    ?.grandTotal ??
                                    0)
                                    .toDouble(),
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Text(
                                    "Error in conversion",
                                    style: TextStyle(color: Colors.red, fontSize: 11),
                                  );
                                }

                                final convertedPrice = snapshot.data ?? 0.0;

                                return Text(
                                  "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    SizedBox(width: 4,),
                    InkWell(
                        splashColor: Colors.transparent,
                        onTap: () {
                          showFareBreakdownSheet(
                              context, fetchSdBookingDetailsController);
                        },
                        child: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.grey,
                        )),
                  ],
                ),

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
          bottom: Radius.circular(20),
        ),
        child: SizedBox(
          width: double.infinity, // full screen width
          height: 800,            // fixed height
          child: Stack(
            children: [
              // Image carousel
              CarouselSlider.builder(
                itemCount: images.length,
                itemBuilder: (context, imgIndex, realIndex) {
                  final img = images[imgIndex];
                  return CachedNetworkImage(
                    imageUrl: img ?? '',
                    fit: BoxFit.fill, // fills container without stretching
                    width: double.infinity,
                    alignment: Alignment.center,
                    useOldImageOnUrlChange: true,
                    memCacheHeight: 800,
                    memCacheWidth: 1200,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: double.infinity,
                        height: 1000,
                        color: Colors.grey,
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.error, size: 50),
                  );
                },
                options: CarouselOptions(
                  height: 1000, // same as container height
                  viewportFraction: 1.0,
                  enableInfiniteScroll: false,
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

              // Overlay text aligned at bottom
              if (_currentIndex >= 1 && _showOverlayText)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black87.withOpacity(0.7),
                      borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].pickup?.date ?? '')} '
                            '${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].pickup?.time} - '
                            '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].drop?.date ?? '')} '
                            '${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].drop?.time} | ',
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          margin: EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.blueAccent,
                            ),
                          ),
                          child: Text(
                            '${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].days} Days',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (fetchSdBookingDetailsController
                        .getAllBookingData.value?.result?.tarrifSelected ==
                    'Weekly')
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].pickup?.date ?? '')} '
                            '${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].pickup?.time} - '
                            '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].drop?.date ?? '')} '
                            '${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].drop?.time} | ',
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          margin: EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.blueAccent,
                            ),
                          ),
                          child: Text(
                            '${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].days} Days',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (fetchSdBookingDetailsController
                        .getAllBookingData.value?.result?.tarrifSelected ==
                    'Monthly')
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].pickup?.date ?? '')} '
                            '${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].pickup?.time} - '
                            '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].drop?.date ?? '')} '
                            '${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].drop?.time} | ',
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          margin: EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.blueAccent,
                            ),
                          ),
                          child: Text(
                            '${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].days} Days',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
  final CurrencyController currencyController = Get.put(CurrencyController());

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
                            FutureBuilder<double>(
                              future: currencyController.convertPrice(
                                (item?.base ?? 0).toDouble(),
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Text(
                                    "Error in conversion",
                                    style: TextStyle(color: Colors.red, fontSize: 11),
                                  );
                                }

                                final convertedPrice = snapshot.data ?? 0;

                                return Text(
                                  "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                );
                              },
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
                              fetchSdBookingDetailsController
                                          .getAllBookingData
                                          .value
                                          ?.result
                                          ?.tarrifs?[0]
                                          .isMileageUnlimited ==
                                      true
                                  ? "Unlimited Mileage"
                                  : "${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].mileageLimit} km",
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
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(
        widget.vehicleId, widget.isHomePage);
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Filter out unwanted labels (like _id)
    final specs = fetchSdBookingDetailsController
            .getAllBookingData.value?.result?.vehicleId?.specs
            ?.where((item) => item.label?.toLowerCase() != "_id") // skip _id
            .toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.white,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Heading row inside card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
                    child: Row(
                      children: [
                        const Text(
                          "CAR OVERVIEW",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            CupertinoIcons.chevron_down,
                            color: CupertinoColors.inactiveGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expandable rows
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isExpanded
                        ? Column(
                      children: List.generate(
                        specs.length,
                            (index) {
                          final items = specs[index];
                          final isLast = index == specs.length - 1;

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: isLast
                                    ? BorderSide.none
                                    : const BorderSide(
                                  color: CupertinoColors.systemGrey5,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(
                                    getIconForLabel(items.label ?? ''),
                                    size: 20,
                                    color: CupertinoColors.black,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      items.label ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: CupertinoColors.black,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    items.value.toString(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData getIconForLabel(String label) {
    switch (label.toLowerCase()) {
    // 🔥 Fuel type
      case 'fuel type':
      case 'fuel':
        return Icons.local_gas_station_rounded;

    // ⚙️ Transmission
      case 'transmission':
        return Icons.settings_input_component_rounded;

    // 🧠 Engine
      case 'engine':
        return Icons.engineering_rounded;

    // 🛞 Mileage / Speed
      case 'mileage':
      case 'average':
        return Icons.speed_rounded;

    // 🧍‍♂️ Seats
      case 'seating capacity':
      case 'seats':
        return Icons.event_seat_rounded;

    // 🌬️ Air Conditioning
      case 'air conditioning':
      case 'ac':
        return Icons.ac_unit_rounded;

    // 🧳 Luggage
      case 'luggage':
      case 'boot space':
        return Icons.card_travel_rounded;

    // 🚪 Doors
      case 'doors':
        return Icons.door_back_door;

    // 🎨 Color
      case 'color':
        return Icons.color_lens_rounded;

    // 📅 Year / Model Year
      case 'year':
      case 'model year':
        return Icons.calendar_today_rounded;

    // ⚡ Power / BHP
      case 'power':
      case 'bhp':
        return Icons.flash_on_rounded;

    // 🔁 Torque
      case 'torque':
        return Icons.sync_rounded;

    // 🚘 Default generic car
      default:
        return Icons.directions_car_rounded;
    }
  }

  // Cupertino-specific icons
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

            // Collision Damage Waiver (CDW)
            Obx(() {
              final result = fetchSdBookingDetailsController
                  .getAllBookingData.value?.result;
              final tarrifs = result?.tarrifs;
              final selected = result?.tarrifSelected;

              String? amount;
              if (selected == 'Daily') {
                amount = tarrifs?[0].collisionDamageWaiver?.toString();
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
              final selected = result?.tarrifSelected;

              // Get the correct amount
              String? amount;
              if (selected == 'Daily') {
                amount = tarrifs?[0].securityDeposit?.amount?.toString();
              } else if (selected == 'Weekly') {
                amount = tarrifs?[1].securityDeposit?.amount?.toString();
              } else if (selected == 'Monthly') {
                amount = tarrifs?[2].securityDeposit?.amount?.toString();
              } else {
                amount = tarrifs?[0].securityDeposit?.amount?.toString();
              }

              return buildOptionTile(
                "Enjoy a deposit-free ride for",
                "",
                fetchSdBookingDetailsController.freeDeposit.value,
                (val) {
                  setState(() =>
                      fetchSdBookingDetailsController.freeDeposit.value = val);
                  fetchSdBookingDetailsController.fetchBookingDetails(
                      widget.vehicleId, false);
                },
                trailing: priceChipUI(amount),
              );
            }),
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.only(
                  top: 4, left: 16, right: 16, bottom: 12),
              child: Text(
                'You can rent a car without any deposit by including the additional service fee in your rental price',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOptionTile(
    dynamic title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    Widget? trailing,
  }) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: title is String
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            if (subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                if (trailing != null) ...[
                  trailing,
                  const SizedBox(width: 8),
                ],
                CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 0.6,
            color: Color(0xFFDDDDDD),
            indent: 16,
            endIndent: 16,
          ),
        ],
      ),
    );
  }

  Widget priceChipUI(String? amount) {
    final CurrencyController currencyController = Get.put(CurrencyController());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.systemGreen,
          width: 0.8,
        ),
      ),
      child: FutureBuilder<double>(
        future: currencyController.convertPrice((double.parse(amount??'') ?? 0)),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              "Error in conversion",
              style: TextStyle(color: Colors.red, fontSize: 11),
            );
          }

          final convertedPrice = snapshot.data ?? 0;

          return Text(
            "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGreen,
            ),
          );
        },
      )

    );
  }
}

class ImportantInfoCard extends StatefulWidget {
  const ImportantInfoCard({Key? key}) : super(key: key);

  @override
  State<ImportantInfoCard> createState() => _ImportantInfoCardState();
}

class _ImportantInfoCardState extends State<ImportantInfoCard> {
  void showInfoBottomSheet(BuildContext context,
      {required String title, required String body}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8262B),
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
        color: Colors.white, // card-like background
        borderRadius: BorderRadius.circular(16),
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
          const Divider(height: 1, thickness: 0.6),
          InfoTile(
            icon: Icons.account_balance_wallet_outlined,
            title: "Payment on pickup",
            subtitle:
                "Cash, Credit card, Crypto, Debit card (Visa, Mastercard), DepositFree",
            linkText: "Other options?",
            onTap: () {
              showInfoBottomSheet(
                context,
                title: 'Payment',
                body:
                    "• Other payment options include Debit Card\n• Credit Card\n• Net Banking\n• etc.",
              );
            },
          ),
          const Divider(height: 1, thickness: 0.6),
          InfoTile(
            icon: Icons.person_outline,
            title: "Minimum age",
            subtitle: "23 y.o.",
            linkText: "Other age?",
            onTap: () {
              showInfoBottomSheet(
                context,
                title: 'Minimum age',
                body:
                    "• Drivers must be at least 25 years old\n• Age requirements may vary depending on location and vehicle type",
              );
            },
          ),
          const Divider(height: 1, thickness: 0.6),
          InfoTile(
            icon: Icons.sports_motorsports_outlined,
            title: "Minimum driving experience",
            subtitle: "1 year",
            linkText: "Less experienced?",
            onTap: () {
              showInfoBottomSheet(
                context,
                title: 'Minimum driving experience',
                body:
                    "• A minimum of 6 months of driving experience is required\n• If you have less experience, additional conditions may apply",
              );
            },
          ),
          const Divider(height: 1, thickness: 0.6),
          InfoTile(
            icon: Icons.description_outlined,
            title: "Required documents",
            subtitle: "Driving license, Identity proof, Valid visa document",
            trailing: const Icon(Icons.chevron_right,
                color: Colors.black54, size: 20),
            onTap: () {
              showInfoBottomSheet(
                context,
                title: 'Required documents',
                body:
                    "• Driving license or international driving license\n• Identity proof (passport, emirates id)\n• Valid visa document (for non-residents)",
              );
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ],
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
  final CurrencyController currencyController = Get.put(CurrencyController());

  bool returnToSameLocation = false;

  @override
  void initState() {
    super.initState();
    serviceHubController.fetchServicehub();
    returnToSameLocation = fetchSdBookingDetailsController.isSameLocation.value;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16.0),
          child: CupertinoScrollbar(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const Text(
                  "Bring the car to me",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: CupertinoColors.black),
                ),
                const SizedBox(height: 8),

                // Delivery option
                Obx(() => _buildOptionTile(
                      title: sdCreateStripePaymentController.sourceCity.value ==
                              ''
                          ? "Select delivery address"
                          : sdCreateStripePaymentController.sourceCity.value,
                      subtitle: FutureBuilder<double>(
                        future: currencyController.convertPrice(
                          (sdCreateStripePaymentController.sourceCity.value == ''
                              ? 0.0
                              : (double.tryParse(
                            fetchSdBookingDetailsController.delivery_charge.value.toString(),
                          ) ??
                              0.0)),
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text(
                              "Error in conversion",
                              style: TextStyle(color: Colors.red, fontSize: 11),
                            );
                          }

                          final convertedPrice = snapshot.data ?? 0.0;

                          return Text(
                            "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.activeBlue)
                          );
                        },
                      ),
                  value: "delivery_address",
                      groupValue: fetchSdBookingDetailsController
                              .selectedPickupOption.value.isEmpty
                          ? null
                          : fetchSdBookingDetailsController
                              .selectedPickupOption.value,
                      error:
                          fetchSdBookingDetailsController.showPickupError.value,
                      onChanged: (val) {
                        fetchSdBookingDetailsController
                            .selectedPickupOption.value = val ?? "";
                        fetchSdBookingDetailsController.showPickupError.value =
                            false;
                        Navigator.of(context).push(
                          CupertinoPageRoute(
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
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: CupertinoColors.black),
                ),
                const SizedBox(height: 8),

                Obx(() => _buildLocationTile(
                      address: serviceHubController.serviceHubResponse.value
                              ?.result?.first.address ??
                          '',
                      value: "pickup_location_1",
                      price: FutureBuilder<double>(
                        future: currencyController.convertPrice(0.0),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text(
                              "Error in conversion",
                              style: TextStyle(color: Colors.red, fontSize: 11),
                            );
                          }

                          final convertedPrice = snapshot.data ?? 0.0;

                          return Text(
                            "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.activeBlue),
                          );
                        },
                      ),
                      groupValue: fetchSdBookingDetailsController
                              .selectedPickupOption.value.isEmpty
                          ? null
                          : fetchSdBookingDetailsController
                              .selectedPickupOption.value,
                      error:
                          fetchSdBookingDetailsController.showPickupError.value,
                      onChanged: (val) {
                        fetchSdBookingDetailsController
                            .selectedPickupOption.value = val ?? "";
                        fetchSdBookingDetailsController.showPickupError.value =
                            false;
                        fetchSdBookingDetailsController.isFreePickup.value =
                            true;
                        fetchSdBookingDetailsController.fetchBookingDetails(
                            widget.vehicleId, false);
                      },
                    )),

                const SizedBox(height: 16),

                // Return to same location toggle
                Obx(() => CupertinoFormRow(
                      prefix: const Text(
                        "Return to the same location",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: CupertinoColors.black),
                      ),
                      child: CupertinoSwitch(
                        value: fetchSdBookingDetailsController
                            .isSameLocation.value,
                        onChanged: (val) {
                          fetchSdBookingDetailsController.isSameLocation.value =
                              val;
                          returnToSameLocation = val;
                          fetchSdBookingDetailsController.fetchBookingDetails(
                              widget.vehicleId, false);
                        },
                      ),
                    )),

                // Dropoff section only if not same
                Obx(() => fetchSdBookingDetailsController.isSameLocation.value
                    ? const SizedBox()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            "Take the car from me",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: CupertinoColors.black),
                          ),
                          const SizedBox(height: 8),
                          _buildOptionTile(
                            title: sdCreateStripePaymentController
                                        .destinationCity.value ==
                                    ''
                                ? "Select return delivery address"
                                : sdCreateStripePaymentController
                                    .destinationCity.value,
                            subtitle: FutureBuilder<double>(
                              future: currencyController.convertPrice(
                                (double.tryParse(
                                  fetchSdBookingDetailsController.collection_charges.value.toString(),
                                ) ??
                                    0.0),
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Text(
                                    "Error in conversion",
                                    style: TextStyle(color: Colors.red, fontSize: 11),
                                  );
                                }

                                final convertedPrice = snapshot.data ?? 0.0;

                                return Text(
                                  "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
                                 style: const TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.activeBlue),
                                );
                              },
                            ),
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
                                CupertinoPageRoute(
                                  builder: (_) =>
                                      SelfDriveReturnPopularLocation(
                                    vehicleId: widget.vehicleId,
                                    isHomePage: widget.isHomePage,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Free dropoff locations",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: CupertinoColors.black),
                          ),
                          const SizedBox(height: 8),
                          Obx(() => _buildLocationTile(
                                address: serviceHubController.serviceHubResponse
                                        .value?.result?.first.address ??
                                    '',
                                value: "drop_location_1",
                                price: FutureBuilder<double>(
                                  future: currencyController.convertPrice(0.0),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return const Text(
                                        "Error in conversion",
                                        style: TextStyle(color: Colors.red, fontSize: 11),
                                      );
                                    }

                                    final convertedPrice = snapshot.data ?? 0.0;

                                    return Text(
                                      "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: CupertinoColors.activeBlue),
                                    );
                                  },
                                ),
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
                                      .isFreeDrop.value = true;
                                  fetchSdBookingDetailsController
                                      .isSameLocation.value = false;
                                  fetchSdBookingDetailsController
                                      .fetchBookingDetails(
                                          widget.vehicleId, false);
                                },
                              )),
                        ],
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Cupertino Option Tile ====================

  Widget _buildOptionTile({
    required String title,
    required Widget subtitle,
    required String value,
    required String? groupValue,
    required bool error,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error ? CupertinoColors.systemRed : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                CupertinoRadio(
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
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      subtitle
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
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationTile({
    required String address,
    required String value,
    required Widget price,
    required String? groupValue,
    required bool error,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error ? CupertinoColors.systemRed : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                CupertinoRadio(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w400)),
                        const SizedBox(height: 2),
                        price
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
              style: TextStyle(color: CupertinoColors.systemRed, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
