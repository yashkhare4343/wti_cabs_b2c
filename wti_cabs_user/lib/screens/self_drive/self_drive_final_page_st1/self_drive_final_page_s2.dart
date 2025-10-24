import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/controller/self_drive/self_drive_booking_details/self_drive_booking_details_controller.dart';
import 'package:wti_cabs_user/core/controller/self_drive/self_drive_manage_booking/self_drive_manage_booking_controller.dart';
import 'package:wti_cabs_user/core/controller/self_drive/service_hub/service_hub_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_all_inventory/self_drive_all_inventory.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_popular_location/self_drive_most_popular_location.dart';

import '../../../core/controller/cab_booking/cab_booking_controller.dart';
import '../../../core/controller/profile_controller/profile_controller.dart';
import '../../../core/controller/self_drive/file_upload_controller/file_upload_controller.dart';
import '../../../core/controller/self_drive/google_lat_lng_controller/google_lat_lng_controller.dart';
import '../../../core/controller/self_drive/search_inventory_sd_controller/search_inventory_sd_controller.dart';
import '../../../core/controller/self_drive/self_drive_stripe_payment/sd_create_stripe_payment.dart';
import '../../../core/controller/self_drive/self_drive_upload_file_controller/self_drive_upload_file_controller.dart';
import '../../../core/services/storage_services.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../../booking_details_final/booking_details_final.dart';
import '../self_drive_popular_location/self_drive_return_popular_location.dart';

class SelfDriveFinalPageS2 extends StatefulWidget {
  final String? vehicleId;
  final bool? isHomePage;
  final bool? fromReturnMapPage;
  final bool? fromPaymentFailurePage;
  const SelfDriveFinalPageS2(
      {super.key,
      this.vehicleId,
      this.isHomePage,
      this.fromReturnMapPage,
      this.fromPaymentFailurePage});

  @override
  State<SelfDriveFinalPageS2> createState() => _SelfDriveFinalPageS2State();
}

class _SelfDriveFinalPageS2State extends State<SelfDriveFinalPageS2> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
      Get.put(FetchSdBookingDetailsController());
  final SdCreateStripePaymentController sdCreateStripePaymentController =
      Get.put(SdCreateStripePaymentController());
  final FileUploadValidController fileUploadValidController =
      Get.find<FileUploadValidController>();
  final CurrencyController currencyController = Get.put(CurrencyController());
  int? _selectedTab;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSdBookingDetailsController.isSameLocation.value =
          widget.fromReturnMapPage == true ? false : true;
    });
    return Scaffold(
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
                      GoRouter.of(context).pop();
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
                            'Step 2 of 2',
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
              height: 260,
              child: BookYourCarScreen(
                vehicleId: widget.vehicleId ?? '',
                isHomePage: widget.isHomePage ?? false,
              ),
            ),
            CarRentalCard(
                vehicleId: widget.vehicleId ?? '',
                isHomePage: widget.isHomePage ?? false),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TravelerDetailsForm(
                formKey: fetchSdBookingDetailsController.formKey,
                fromPaymentFailurePage: widget.fromPaymentFailurePage,
              ),
            ),
            UploadDocumentsScreen()
          ],
        ),
      )),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, -2),
              blurRadius: 12,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fare Container
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
              const SizedBox(width: 12),
              // Continue Button
              Obx(() {
                final isValid = fetchSdBookingDetailsController.isFormValid.value;
                return SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isValid
                        ? () {
                      final isUploadsValid = fileUploadValidController.validateUploads(fileUploadValidController.selectedTab.value);
                      if (isUploadsValid) {
                        sdCreateStripePaymentController.createUser(context: context);
                      } else {
                        Flushbar(
                          flushbarPosition: FlushbarPosition.TOP,
                          margin: const EdgeInsets.all(12),
                          borderRadius: BorderRadius.circular(12),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                          icon: const Icon(Icons.error, color: Colors.white),
                          messageText: const Text(
                            "Please upload documents to continue",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ).show(context);
                      }
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isValid ? Colors.redAccent : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
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
                );
              }),            ],
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

class TravelerDetailsForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final bool? fromPaymentFailurePage;

  const TravelerDetailsForm({
    super.key,
    required this.formKey,
    this.fromPaymentFailurePage,
  });

  @override
  _TravelerDetailsFormState createState() => _TravelerDetailsFormState();
}

class _TravelerDetailsFormState extends State<TravelerDetailsForm> {
  String selectedTitle = 'Mr.';
  final List<String> titles = ['Mr.', 'Ms.', 'Mrs.'];

  final ProfileController profileController = Get.put(ProfileController());
  final SdCreateStripePaymentController sdCreateStripePaymentController =
  Get.put(SdCreateStripePaymentController());
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
  Get.put(FetchSdBookingDetailsController());

  PhoneNumber number = PhoneNumber(isoCode: 'IN');

  String? _country;
  String? token;
  String? firstName;
  String? email;
  String? contact;
  String? contactCode;
  String? tripCode;

  @override
  void initState() {
    super.initState();
    loadInitialData();
    getCurrentTripCode();
  }

  void getCurrentTripCode() async {
    tripCode = await StorageServices.instance.read('currentTripCode');
    setState(() {});
    debugPrint('🛑 Current Trip Code: $tripCode');
  }

  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');
    token = await StorageServices.instance.read('token');

    await profileController.fetchData();

    if (widget.fromPaymentFailurePage == true ||
        (widget.fromPaymentFailurePage == null && token == null)) {
      firstName = await StorageServices.instance.read('firstName') ?? '';
      contact = await StorageServices.instance.read('contact') ?? '';
      email = await StorageServices.instance.read('emailId') ?? '';
    } else {
      firstName =
          profileController.profileResponse.value?.result?.firstName ?? '';
      contact =
          profileController.profileResponse.value?.result?.contact?.toString() ??
              '';
      contactCode =
          profileController.profileResponse.value?.result?.contactCode ?? '';
      email = profileController.profileResponse.value?.result?.emailID ?? '';
    }

    sdCreateStripePaymentController.firstNameController.text = firstName ?? '';
    sdCreateStripePaymentController.emailController.text = email ?? '';
    sdCreateStripePaymentController.contactController.text = contact ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        fetchSdBookingDetailsController.validateForm();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.greyBorder1, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              const Text(
                "Traveler Details",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              /// Title Chips
              Row(
                children: titles.map((title) {
                  final isSelected = selectedTitle == title;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(title),
                      selected: isSelected,
                      selectedColor: AppColors.mainButtonBg,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: AppColors.mainButtonBg),
                      ),
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => selectedTitle = title);
                        fetchSdBookingDetailsController.validateForm();
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              /// Full Name
              _buildTextField(
                label: 'Full Name',
                hint: "Enter full name",
                controller: sdCreateStripePaymentController.firstNameController,
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Full name is required" : null,
                onSaved: (value) async {
                  firstName = value;
                  await StorageServices.instance.save('firstName', value ?? '');
                },
              ),

              /// Email
              _buildTextField(
                label: 'Email',
                hint: "Enter email id",
                controller: sdCreateStripePaymentController.emailController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Email is required";
                  }
                  final regex =
                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  return !regex.hasMatch(v.trim())
                      ? "Enter a valid email"
                      : null;
                },
                onSaved: (value) async {
                  email = value;
                  await StorageServices.instance.save('emailId', value ?? '');
                },
              ),

              /// Phone Number
              const Text(
                'Mobile no',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black38),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InternationalPhoneNumberInput(
                  selectorConfig: const SelectorConfig(
                    selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                    useBottomSheetSafeArea: true,
                    showFlags: true,
                  ),
                  selectorTextStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  initialValue: number,
                  textFieldController:
                  sdCreateStripePaymentController.contactController,
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  keyboardType:
                  const TextInputType.numberWithOptions(signed: true),
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Mobile number is required";
                    }
                    if (value.length != 10 ||
                        !RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return "Enter valid 10-digit mobile number";
                    }
                    return null;
                  },
                  inputDecoration: const InputDecoration(
                    hintText: "ENTER MOBILE NUMBER",
                    hintStyle: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                    counterText: "",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  formatInput: false,
                  onInputChanged: (PhoneNumber value) async {
                    fetchSdBookingDetailsController.validateForm();
                    contact = value.phoneNumber
                        ?.replaceAll(' ', '')
                        .replaceFirst(value.dialCode ?? '', '') ??
                        '';
                    sdCreateStripePaymentController.contactCode =
                        value.dialCode?.replaceAll('+', '');
                    contactCode = value.dialCode?.replaceAll('+', '');

                    await StorageServices.instance
                        .save('contactCode', contactCode ?? '');
                    await StorageServices.instance
                        .save('contact', contact ?? '');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    Future<void> Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black38)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint.toUpperCase(),
              hintStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                const BorderSide(color: Colors.black54, width: 1.2),
              ),
            ),
            validator: validator,
            onChanged: (value) async {
              await onSaved?.call(value);
              fetchSdBookingDetailsController.validateForm();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}


class UploadDocumentsScreen extends StatefulWidget {

   UploadDocumentsScreen({super.key,});
  @override
  _UploadDocumentsScreenState createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final FileUploadValidController fileUploadValidController =
      Get.put(FileUploadValidController());


  String? _eidFrontPath;
  String? _eidBackPath;
  String? _dlFrontPath;
  String? _dlBackPath;
  String? _passportPath;
  String? _touristPassportPath;
  String? _touristVisaPath;
  String? _touristhcdlPath;
  String? _touristidlPath;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String field) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (fileUploadValidController.selectedTab.value == 0) {
          switch (field) {
            case 'eidFront':
              _eidFrontPath = image.path;
              break;
            case 'eidBack':
              _eidBackPath = image.path;
              break;
            case 'dlFront':
              _dlFrontPath = image.path;
              break;
            case 'dlBack':
              _dlBackPath = image.path;
              break;
            case 'passport':
              _passportPath = image.path;
              break;
          }
        } else {
          _touristPassportPath = image.path;
        }
      });
      await fileUploadValidController.handleFileChange(field, image: image);
    }
  }

  Future<void> _removeImage(String field) async {
    setState(() {
      if (fileUploadValidController.selectedTab.value == 0) {
        switch (field) {
          case 'eidFront':
            _eidFrontPath = null;
            break;
          case 'eidBack':
            _eidBackPath = null;
            break;
          case 'dlFront':
            _dlFrontPath = null;
            break;
          case 'dlBack':
            _dlBackPath = null;
            break;
          case 'passport':
            _passportPath = null;
            break;
        }
      } else {
        _touristPassportPath = null;
      }
      fileUploadValidController.clearField(field);
    });
  }

  Widget _buildUploadField(
      String label, String? localPath, String field, IconData icon) {
    return Obx(() {
      final localPreview = fileUploadValidController.localPreviews[field];
      final uploadedPreview = fileUploadValidController.uploadedPreviews[field];
      final uploading = fileUploadValidController.uploadingField.value == field;
      final error = fileUploadValidController.errors[field] ?? '';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload / Preview
          (localPreview == null && uploadedPreview == null)
              ? GestureDetector(
            onTap: uploading ? null : () => _pickImage(field),
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: error.isNotEmpty
                      ? Colors.red
                      : Colors.blue.shade200,
                  width: error.isNotEmpty ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 25,
                    color: Colors.blue.shade400,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    uploading ? 'Uploading...' : 'Tap to upload',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
              : Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: error.isNotEmpty
                          ? Colors.red
                          : Colors.transparent,
                      width: error.isNotEmpty ? 1.5 : 0,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: uploading ? null : () => _pickImage(field),
                    child: uploadedPreview != null
                        ? Image.network(
                      uploadedPreview,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                          _buildErrorImage(),
                    )
                        : Image.file(
                      File(localPreview ?? localPath ?? ''),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                          _buildErrorImage(),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(
                    Icons.cancel_rounded,
                    size: 26,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    uploading ? null : _removeImage(field);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (fileUploadValidController.selectedTab.value == 0)
            Text(
              '$label *',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          // Error message
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }


// Helper widget for image loading errors
  Widget _buildErrorImage() {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.red,
          size: 40,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Document Type',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Please select whether you are an Emirates Resident or a Tourist to upload the required documents.',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 0,
                label:
                    Text('Emirates Resident', style: TextStyle(fontSize: 13)),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('Tourist', style: TextStyle(fontSize: 13)),
              ),
            ],
            selected: {fileUploadValidController.selectedTab.value},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                fileUploadValidController.selectedTab.value = newSelection.first;
              });
              print('selected tab is : $widget.selectedTab');
            },
            showSelectedIcon: false,
          ),
          const SizedBox(height: 16),
          if (fileUploadValidController.selectedTab.value == 0)
            ..._buildResidentSections()
          else
            ..._buildTouristSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildResidentSections() {
    return [
      _sectionCard('Emirates ID', [
        Row(
          children: [
            Expanded(
              child: _buildUploadField(
                'Emirates ID Front',
                _eidFrontPath,
                'eidFront',
                Icons.badge,
              ),
            ),

            const SizedBox(width: 8), // small gap after divider
            Expanded(
              child: _buildUploadField(
                'Emirates ID Back',
                _eidBackPath,
                'eidBack',
                Icons.badge,
              ),
            ),
          ],
        )
      ]),
      // const SizedBox(height: 24),
      _sectionCard('Driving License', [
      Row(
      children: [
      Expanded(
      child: _buildUploadField(
      'Driving License Front',
      _dlFrontPath,
      'dlFront',
      Icons.drive_eta,
      ),
      ),

      const SizedBox(width: 8), // small gap after divider
      Expanded(
      child: _buildUploadField(
      'Driving License Back',
      _dlBackPath,
      'dlBack',
      Icons.drive_eta,
    ),
    ),
    ],
    ),
    ]),

    // const SizedBox(height: 24),
      _sectionCard('Passport', [
        _buildUploadField('Passport', _passportPath, 'passport', Icons.book),
      ]),
    ];
  }

  List<Widget> _buildTouristSection() {
    return [
      _sectionCard('Passport', [
        _buildUploadField(
            'Passport', _touristPassportPath, 'passport', Icons.book),
      ]),
      _sectionCard('Visa', [
        _buildUploadField(
            'Visa', _touristVisaPath, 'visa', Icons.book),
      ]),
      _sectionCard('Home Country Driving Licence', [
        _buildUploadField(
            'Home Country Driving Licence', _touristhcdlPath, 'hcdl', Icons.book),
      ]),      _sectionCard('International Driving Permit', [
        _buildUploadField(
            'International Driving Permit', _touristidlPath, 'idp', Icons.book),
      ]),
    ];
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: children),
        ),
      ],
    );
  }
}
