import 'dart:convert';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/common_widget/loader/shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/controller/cab_booking/cab_booking_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_drop/choose_drop_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/coupons/fetch_coupons_controller.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/controller/drop_location_controller/drop_location_controller.dart';
import 'package:wti_cabs_user/core/controller/payment/global/global_provisional_booking.dart';
import 'package:wti_cabs_user/core/controller/payment/india/provisional_booking_controller.dart';
import 'package:wti_cabs_user/core/controller/profile_controller/profile_controller.dart';
import 'package:wti_cabs_user/core/model/fetch_coupon/fetch_coupon_response.dart';
import 'package:wti_cabs_user/screens/map_picker/map_picker.dart';
import '../../core/api/api_services.dart';
import '../../core/controller/analytics_tracking/analytics_tracking.dart';
import '../../core/controller/booking_ride_controller.dart';
import '../../core/controller/country/country_controller.dart';
import '../../core/controller/coupons/apply_coupon_controller.dart';
import '../../core/controller/fetch_reservation_booking_data/fetch_reservation_booking_data.dart';
import '../../core/controller/inventory/search_cab_inventory_controller.dart';
import '../../core/controller/rental_controller/fetch_package_controller.dart';
import '../../core/controller/source_controller/source_controller.dart';
import '../../core/model/cab_booking/india_cab_booking.dart';
import '../../core/route_management/app_routes.dart';
import '../../core/services/storage_services.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../inventory_list_screen/inventory_list.dart';
import 'package:timezone/timezone.dart' as tz;

class BookingDetailsFinal extends StatefulWidget {
  final num? totalKms;
  final String? endTime;
  final bool? fromPaymentFailure;
  const BookingDetailsFinal(
      {super.key, this.totalKms, this.endTime, this.fromPaymentFailure});

  @override
  State<BookingDetailsFinal> createState() => _BookingDetailsFinalState();
}

final CabBookingController cabBookingController =
    Get.put(CabBookingController());

class _BookingDetailsFinalState extends State<BookingDetailsFinal> {
  String? _country;
  String? token;
  String? firstName;
  String? email;
  String? contact;
  String? contactCode;
  final CabBookingController cabBookingController =
      Get.put(CabBookingController());
  final ProfileController profileController = Get.put(ProfileController());
  final CouponController couponController = Get.put(CouponController());
  final GlobalKey<FormState> travelerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final FetchPackageController fetchPackageController =
      Get.put(FetchPackageController());
  final CouponController fetchCouponController = Get.put(CouponController());
  final DropPlaceSearchController dropPlaceSearchController =
      Get.put(DropPlaceSearchController());
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadInitialData();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> logCabViewItemList() async {
    final selectedTripController = Get.find<SelectedTripController>();
    final currencyController = Get.find<CurrencyController>();
    final convertedPartialAmount = await currencyController
        .convertPrice(cabBookingController.partFare.toDouble());
    final convertFullAmount = await currencyController
        .convertPrice(cabBookingController.totalFare.toDouble());
    // 🧩 Add or merge custom keys (including converted amount)
    // 🧾 Get stored values
    final storedItem = selectedTripController.selectedItem.value;
    final storedParams = selectedTripController.parameters;

    if (storedItem == null || storedParams.isEmpty) {
      print('⚠️ No trip data found in controller, skipping log.');
      return;
    }

    // 🧩 You can modify or add new keys if needed
    selectedTripController.addCustomParameters({
      'event': 'view_item',
      'screen_name': 'Booking Details Screen',
      'partial_amount': convertedPartialAmount,
      'payment_option':
          cabBookingController.selectedOption.value == 1 ? "FULL" : "PART",
      'total_amount': convertFullAmount
    });

    // ✅ Prepare final parameters to send
    final updatedParams =
        Map<String, Object>.from(selectedTripController.parameters);

    // ✅ Log to Firebase Analytics
    await FirebaseAnalytics.instance.logViewItem(
      items: [storedItem],
      parameters: updatedParams,
    );

    print('✅ Logged view_item for ${storedItem.itemName}');
    print('📦 Parameters sent: $updatedParams');
  }

  Future<void> loadInitialData() async {
    _country = dropPlaceSearchController.dropLatLng.value?.country;
    token = await StorageServices.instance.read('token');

    await profileController.fetchData();
    if ((_country ?? '').toLowerCase() == 'india') {
      final vehicleType =
          cabBookingController.indiaData.value?.inventory?.carTypes?.type ?? '';
      await fetchCouponController.fetchCoupons(
        context,
        vehicleType: vehicleType,
      );
    } else {
      fetchCouponController.coupons.clear();
    }

    print('📦 3rd page country: $_country');
    firstName =
        profileController.profileResponse.value?.result?.firstName ?? '';
    contact =
        profileController.profileResponse.value?.result?.contact.toString() ??
            '';
    contactCode =
        profileController.profileResponse.value?.result?.contactCode ?? '';
    email = profileController.profileResponse.value?.result?.emailID ?? '';

    print('First Name: $firstName');
    print('Contact: $contact');
    print('Contact Code: $contactCode');
    print('Email: $email');

    // ✅ Trigger validation once after prefill
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        // ensure controllers are in sync with UI
      });
      final cabBookingController = Get.find<CabBookingController>();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        // small delay to let TextEditingControllers update in the tree
        cabBookingController.validateForm();
      });
    }); // to trigger rebuild once _country is loaded
    await logCabViewItemList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // 🚀 Stops the default "pop and close app"
      onPopInvoked: (didPop) {
        // This will be called for hardware back and gesture
        // Avoid pushing while Navigator is in the middle of a pop (!_debugLocked)
        if (didPop) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.push(
            context,
            Platform.isIOS
                ? CupertinoPageRoute(
                    builder: (context) => InventoryList(
                      requestData: bookingRideController.requestData.value,
                      fromFinalBookingPage: true,
                    ),
                  )
                : MaterialPageRoute(
                    builder: (context) => InventoryList(
                      requestData: bookingRideController.requestData.value,
                      fromFinalBookingPage: true,
                    ),
                  ),
          );
        }); // GoRouter.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBgPrimary1,
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: FullPageShimmer(), // fake loader
                )
              : Padding(
                  padding: const EdgeInsets.only(
                      top: 12.0, left: 12.0, right: 12.0, bottom: 70),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        BookingTopBar(),

                        const SizedBox(height: 16),
                        GetBuilder<CabBookingController>(
                          builder: (cabBookingController) {
                            if (_country == null) {
                              return Center(child: buildShimmer());
                            }

                            if (_country!.toLowerCase() == 'india') {
                              final indiaData =
                                  cabBookingController.indiaData.value;
                              if (indiaData == null ||
                                  indiaData.inventory == null) {
                                return const Center(
                                    child: Text(
                                        'No India booking data available.'));
                              }
                              return _buildIndiaCard(indiaData);
                            }

                            final globalData =
                                cabBookingController.globalData.value;
                            if (globalData == null ||
                                globalData.vehicleDetails == null) {
                              return const Center(
                                  child: Text(
                                      'No Global booking data available.'));
                            }

                            return _buildGlobalCard(widget.totalKms.toString());
                          },
                        ),
                        //inclusion/exclusion (india)
                        (_country?.toLowerCase() == 'india')
                            ? GetBuilder<CabBookingController>(
                                builder: (cabBookingController) {
                                  final currencyController =
                                      Get.find<CurrencyController>();
                                  final indiaData =
                                      cabBookingController.indiaData.value;
                                  if (indiaData == null) {
                                    return Center(child: buildShimmer());
                                  }

                                  final extraCharges = indiaData.inventory
                                      ?.carTypes?.fareDetails?.extraCharges;

                                  // Dynamic charge checks
                                  final stateTax = extraCharges?.stateTax;
                                  final isStateChargeExcluded =
                                      stateTax?.isIncludedInBaseFare == false &&
                                          stateTax?.isIncludedInGrandTotal ==
                                              false;

                                  final tollTax = extraCharges?.tollCharges;
                                  final isTollExcluded =
                                      tollTax?.isIncludedInBaseFare == false &&
                                          tollTax?.isIncludedInGrandTotal ==
                                              false;

                                  final nightTax = extraCharges?.nightCharges;
                                  final isNightExcluded =
                                      nightTax?.isIncludedInBaseFare == false &&
                                          nightTax?.isIncludedInGrandTotal ==
                                              false;

                                  final waitingTax =
                                      extraCharges?.waitingCharges;
                                  final isWaitingExcluded =
                                      waitingTax?.isIncludedInBaseFare ==
                                              false &&
                                          waitingTax?.isIncludedInGrandTotal ==
                                              false;

                                  final parkingTax =
                                      extraCharges?.parkingCharges;
                                  final isParkingExcluded =
                                      parkingTax?.isIncludedInBaseFare ==
                                              false &&
                                          parkingTax?.isIncludedInGrandTotal ==
                                              false;

                                  // Build dynamic lists
                                  final inclusions = <Widget>[
                                    FutureBuilder<double>(
                                      future: currencyController.convertPrice(
                                          indiaData
                                                  .inventory
                                                  ?.carTypes
                                                  ?.fareDetails
                                                  ?.perKmExtraCharge
                                                  ?.toDouble() ??
                                              0.0),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return SizedBox(
                                            height: 12,
                                            width: 20,
                                            child: Center(
                                              child: SizedBox(
                                                height: 10,
                                                width: 10,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          Colors.grey.shade400),
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        if (snapshot.hasError) {
                                          return const Text(
                                            "--",
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                          );
                                        }
                                        final convertedValue = snapshot.data ??
                                            indiaData.inventory?.carTypes
                                                ?.fareDetails?.perKmExtraCharge
                                                ?.toDouble();
                                        return _buildInclusionItem(
                                          icon: Icons.speed,
                                          title:
                                              "${indiaData.inventory?.distanceBooked} Km included ",
                                          subtitle:
                                              "${currencyController.selectedCurrency.value.symbol}${convertedValue?.toDouble().toStringAsFixed(2)}/km will apply beyond the included kms",
                                        );
                                      },
                                    ),
                                    _buildInclusionItem(
                                      icon: Icons.person,
                                      title: "Driver allowance",
                                      subtitle:
                                          "Driver food and accommodation(stay) charges are included",
                                    ),
                                  ];

                                  final exclusions = <Widget>[
                                    // _buildExclusionItem(
                                    //   icon: Icons.location_off,
                                    //   title: "Sightseeing not included",
                                    //   subtitle:
                                    //   "Visiting tourist places or stopping more than once for refreshments isn’t allowed",
                                    // ),
                                  ];

                                  // Handle dynamic inclusions/exclusions
                                  if (isStateChargeExcluded) {
                                    exclusions.add(_buildExclusionItem(
                                      icon: Icons.receipt_long,
                                      title: "State Tax excluded",
                                      subtitle:
                                          "State tax is not covered in base fare",
                                    ));
                                  } else {
                                    inclusions.add(_buildInclusionItem(
                                      icon: Icons.receipt_long,
                                      title: "State Tax included",
                                      subtitle: "State tax is included",
                                    ));
                                  }

                                  if (isTollExcluded) {
                                    exclusions.add(_buildExclusionItem(
                                      icon: Icons.local_taxi,
                                      title: "Toll Charges excluded",
                                      subtitle:
                                          "Toll charges need to be paid separately",
                                    ));
                                  } else {
                                    inclusions.add(_buildInclusionItem(
                                      icon: Icons.local_taxi,
                                      title: "Toll Charges included",
                                      subtitle: "Toll charges are included",
                                    ));
                                  }

                                  if (isParkingExcluded) {
                                    exclusions.add(_buildExclusionItem(
                                      icon: Icons.local_parking,
                                      title:
                                          "Parking Charges excluded (Airport Parking)",
                                      subtitle:
                                          "Parking charges need to be paid separately",
                                    ));
                                  } else {
                                    inclusions.add(_buildInclusionItem(
                                      icon: Icons.local_parking,
                                      title:
                                          "Parking Charges included (Airport Parking)",
                                      subtitle: "Parking charges are included",
                                    ));
                                  }

                                  if (isNightExcluded) {
                                    exclusions.add(_buildExclusionItem(
                                      icon: Icons.nightlight_round,
                                      title: "Night Charges excluded",
                                      subtitle:
                                          "Night travel charges are extra",
                                    ));
                                  } else {
                                    inclusions.add(_buildInclusionItem(
                                      icon: Icons.nightlight_round,
                                      title: "Night Charges included",
                                      subtitle: "Night charges are covered",
                                    ));
                                  }

                                  if (isWaitingExcluded) {
                                    exclusions.add(
                                      FutureBuilder<double>(
                                        future: currencyController.convertPrice(
                                          extraCharges?.waitingCharges?.amount
                                                  ?.toDouble() ??
                                              0.0,
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return SizedBox(
                                              height: 12,
                                              width: 20,
                                              child: Center(
                                                child: SizedBox(
                                                  height: 10,
                                                  width: 10,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors
                                                                .grey.shade400),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          if (snapshot.hasError) {
                                            return const Text(
                                              "--",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600),
                                            );
                                          }
                                          final convertedValue =
                                              snapshot.data ??
                                                  extraCharges
                                                      ?.waitingCharges?.amount
                                                      ?.toDouble();

                                          return _buildExclusionItem(
                                            icon: Icons.access_time,
                                            title: "Waiting Charges excluded",
                                            subtitle:
                                                "${currencyController.selectedCurrency.value.symbol} ${convertedValue?.toStringAsFixed(2)}/${extraCharges?.waitingCharges?.applicableTime} mins post ${extraCharges?.waitingCharges?.freeWaitingTime} mins",
                                          );
                                        },
                                      ),
                                    );
                                  } else {
                                    inclusions.add(
                                      FutureBuilder<double>(
                                        future: currencyController.convertPrice(
                                          extraCharges?.waitingCharges?.amount
                                                  ?.toDouble() ??
                                              0.0,
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return SizedBox(
                                              height: 12,
                                              width: 20,
                                              child: Center(
                                                child: SizedBox(
                                                  height: 10,
                                                  width: 10,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors
                                                                .grey.shade400),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          if (snapshot.hasError) {
                                            return const Text(
                                              "--",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600),
                                            );
                                          }
                                          final convertedValue =
                                              snapshot.data ??
                                                  extraCharges
                                                      ?.waitingCharges?.amount
                                                      ?.toDouble();

                                          return _buildInclusionItem(
                                            icon: Icons.access_time,
                                            title:
                                                "Waiting time upto 45 mins for pickup",
                                            subtitle:
                                                "${currencyController.selectedCurrency.value.symbol} ${convertedValue?.toStringAsFixed(2)}/${extraCharges?.waitingCharges?.applicableTime} mins post ${extraCharges?.waitingCharges?.freeWaitingTime} mins",
                                          );
                                        },
                                      ),
                                    );
                                  }

                                  return Card(
                                    color: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                          color: AppColors.greyBorder1,
                                          width: 1),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // ✅ Inclusions Section
                                          Text(
                                            "INCLUSIONS",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...inclusions,

                                          // ✅ Exclusions Section
                                          Text(
                                            "EXCLUSIONS",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...exclusions,
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Obx(() {
                                final globalBooking =
                                    cabBookingController.globalData.value;
                                final results = globalBooking?.vehicleDetails;
                                final fareDetails =
                                    globalBooking?.fareBreakUpDetails;
                                final SearchCabInventoryController
                                    searchCabInventoryController =
                                    Get.put(SearchCabInventoryController());
                                final CurrencyController currencyController =
                                    Get.put(CurrencyController());

                                if (results == null) {
                                  return const Center(
                                      child: Text(
                                          'No Global booking data available.'));
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 12.0), // ⬅️ less spacing
                                  child: Card(
                                    color: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          10), // ⬅️ slightly smaller radius
                                      side: BorderSide(
                                          color: AppColors.greyBorder1,
                                          width: 0.8), // ⬅️ thinner border
                                    ),
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                            vertical:
                                                10.0), // ⬅️ reduced padding
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text('Inclusions',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            _buildGlobalInclusionItem(
                                                icon: Icons.speed,
                                                title: "Km included ",
                                                subtitle:
                                                    "${widget.totalKms} Km included "),
                                            searchCabInventoryController
                                                        .globalData
                                                        .value
                                                        ?.result
                                                        .first
                                                        .first
                                                        .tripDetails
                                                        ?.currentTripCode
                                                        .toInt() ==
                                                    2
                                                ? _buildGlobalInclusionItem(
                                                    icon: Icons.money,
                                                    title:
                                                        "Airport Pickup Charge included upto ${cabBookingController.globalData.value?.fareBreakUpDetails?.airportWaitingCharges?.first.minTime} minutes)",
                                                    subtitle:
                                                        "Airport Pickup Charge( upto ${cabBookingController.globalData.value?.fareBreakUpDetails?.airportWaitingCharges?.first.minTime} minutes",
                                                  )
                                                : SizedBox(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text('Exclusions',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            searchCabInventoryController
                                                        .globalData
                                                        .value
                                                        ?.result
                                                        .first
                                                        .first
                                                        .tripDetails
                                                        ?.currentTripCode
                                                        .toInt() ==
                                                    2
                                                ? SizedBox(
                                                    height: 126,
                                                    child: ListView.builder(
                                                      itemCount: cabBookingController
                                                          .globalData
                                                          .value
                                                          ?.fareBreakUpDetails
                                                          ?.airportWaitingCharges
                                                          ?.length, // total items
                                                      itemBuilder:
                                                          (context, index) {
                                                        // build each item
                                                        return _buildGlobalExclusionItem(
                                                          icon: Icons.label,
                                                          title:
                                                              'Airport Charges Slab (in mins)',
                                                          subtitle:
                                                              '"${cabBookingController.globalData.value?.fareBreakUpDetails?.airportWaitingCharges?[index].minTime}" - "${cabBookingController.globalData.value?.fareBreakUpDetails?.airportWaitingCharges?[index].maxTime}" : ${currencyController.selectedCurrency.value.symbol} ${cabBookingController.globalData.value?.fareBreakUpDetails?.airportWaitingCharges?[index].charge}',
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : SizedBox(),
                                            FutureBuilder<double>(
                                              future: currencyController
                                                  .convertPrice(
                                                cabBookingController
                                                        .globalData
                                                        .value
                                                        ?.fareBreakUpDetails
                                                        ?.waitingCharge
                                                        ?.toDouble() ??
                                                    0.0,
                                              ),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return SizedBox(
                                                    height: 12,
                                                    width: 20,
                                                    child: Center(
                                                      child: SizedBox(
                                                        height: 10,
                                                        width: 10,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 1.5,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  Colors.grey
                                                                      .shade400),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }

                                                if (snapshot.hasError) {
                                                  return const Text(
                                                    "--",
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  );
                                                }
                                                final convertedValue =
                                                    snapshot.data ??
                                                        cabBookingController
                                                            .globalData
                                                            .value
                                                            ?.fareBreakUpDetails
                                                            ?.waitingCharge
                                                            ?.toDouble() ??
                                                        0.0;

                                                return _buildGlobalExclusionItem(
                                                  icon: Icons.person,
                                                  title:
                                                      'Driver Waiting Charge (After ${cabBookingController.globalData.value?.fareBreakUpDetails?.freeWaitingTime} mins)',
                                                  subtitle:
                                                      "${currencyController.selectedCurrency.value.symbol} ${convertedValue.toStringAsFixed(2)} per ${cabBookingController.globalData.value?.fareBreakUpDetails?.waitingInterval} mins",
                                                );
                                              },
                                            )
                                          ],
                                        )),
                                  ),
                                );
                              }),

                        // Coupon & Offers (India only) - shown below Inclusion/Exclusion
                        if ((_country ?? '').toLowerCase() == 'india') ...[
                          const SizedBox(height: 12),
                          const CouponOffersCard(),
                        ],

                        SizedBox(
                          height: 12,
                        ),
                        ExtrasSelectionCard(),
                        SizedBox(
                          height: 8,
                        ),

                        // CouponScreen(),
                        // SizedBox(
                        //   height: 16,
                        // ),
                        TravelerDetailsForm(
                          formKey: cabBookingController.formKey,
                          fromPaymentFailurePage: widget.fromPaymentFailure,
                        ),
                        // DiscountCouponsCard(),
                      ],
                    ),
                  )),
        ),
        bottomSheet: BottomPaymentBar(
          endtime: widget.endTime,
        ),
      ),
    );
  }

  Widget buildShimmer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 96,
                  height: 66,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(height: 12, width: 40, color: Colors.white),
                          const SizedBox(width: 8),
                          Container(height: 12, width: 40, color: Colors.white),
                          const SizedBox(width: 8),
                          Container(height: 12, width: 60, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 16, height: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildIndiaCard(IndiaCabBooking data) {
  final carInventory = data.inventory;
  final carTripType = data.tripType;
  final carOffer = data.offerObject;
  final SearchCabInventoryController searchCabInventoryController =
      Get.put(SearchCabInventoryController());

  num calculateOriginalPrice(num baseFare, num discountPercent) {
    return baseFare + (baseFare * discountPercent / 100);
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 14.0), // slightly smaller gap
    child: Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // slightly smaller radius
        side: BorderSide(color: AppColors.greyBorder1, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14.0, vertical: 10.0), // reduced padding
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car image & type
                Transform.translate(
                  offset: const Offset(0, -5),
                  child: Column(
                    children: [
                      Image.network(
                        carInventory?.carTypes?.carImageUrl ?? '',
                        width: 70, // shrinked
                        height: 45,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/inventory_car.png',
                            width: 70,
                            height: 45,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFE3F2FD),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3), // smaller padding
                          minimumSize: Size.zero,
                          side: const BorderSide(
                              color: Colors.transparent, width: 1),
                          foregroundColor: const Color(0xFF1565C0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          carInventory?.carTypes?.type ?? '',
                          style: const TextStyle(
                            fontSize: 11, // slightly smaller
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car Tagline
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              carInventory?.carTypes?.carTagLine ?? '',
                              style: const TextStyle(
                                fontSize: 16, // main focus (kept bold)
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.mainButtonBg,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              minimumSize: Size.zero,
                              side: const BorderSide(
                                  color: AppColors.mainButtonBg, width: 1),
                              foregroundColor: Colors.white,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: () {},
                            child: Text(
                              carInventory?.carTypes?.combustionType ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'or similar',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Rating + details
                      Row(
                        children: [
                          Text(
                            carInventory?.carTypes?.rating?.ratePoints
                                    .toString() ??
                                '',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.star, color: AppColors.yellow1, size: 11),
                          const SizedBox(width: 3),
                          Icon(Icons.airline_seat_recline_extra, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '${carInventory?.carTypes?.seats} Seat',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.luggage_outlined, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '${carInventory?.carTypes?.luggageCapacity}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.speed_outlined, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '${carInventory?.distanceBooked} km',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),

                // Price & Book Button will go here
              ],
            ),
            SizedBox(
              height: 8,
            ),
            SizedBox(
              height: 20,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: carInventory
                        ?.carTypes?.amenities?.features?.vehicle?.length ??
                    0,
                itemBuilder: (context, index) {
                  final iconUrl = carInventory?.carTypes?.amenities?.features
                          ?.vehicleIcons?[index] ??
                      '';
                  final label = carInventory
                          ?.carTypes?.amenities?.features?.vehicle?[index] ??
                      '';

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: Colors.grey.shade400, width: 0.8),
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
  );
}

Widget _buildGlobalCard(String totalDistance) {
  final CabBookingController cabBookingController =
      Get.find<CabBookingController>();
  final List<IconData> amenityIcons = [
    Icons.cleaning_services, // Tissue
    Icons.sanitizer, // Sanitizer
  ];
  return Obx(() {
    final globalBooking = cabBookingController.globalData.value;
    final results = globalBooking?.vehicleDetails;
    final fareDetails = globalBooking?.fareBreakUpDetails;

    if (results == null) {
      return const Center(child: Text('No Global booking data available.'));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // ⬅️ less spacing
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // ⬅️ slightly smaller radius
          side: BorderSide(
              color: AppColors.greyBorder1, width: 0.8), // ⬅️ thinner border
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12.0, vertical: 10.0), // ⬅️ reduced padding
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Image.network(
                        results.vehicleImageLink ?? '',
                        width: 70, // ⬅️ smaller image
                        height: 45,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/inventory_car.png',
                            width: 70,
                            height: 45,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFE3F2FD),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2), // ⬅️ smaller padding
                          minimumSize: Size.zero,
                          side: BorderSide.none,
                          foregroundColor: const Color(0xFF1565C0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          fareDetails?.vehicleCategory ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500), // ⬅️ smaller font
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          results.title ?? '',
                          style: TextStyle(
                            fontSize: 16, // ⬅️ slightly smaller
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainButtonBg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'or similar',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                  color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.mainButtonBg,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2), // ⬅️ smaller padding
                                minimumSize: Size.zero,
                                side: const BorderSide(
                                    color: AppColors.mainButtonBg, width: 1),
                                foregroundColor: Colors.white,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              onPressed: () {},
                              child: Text(
                                fareDetails?.fuelType ?? '',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(results.rating?.toString() ?? '',
                                style: CommonFonts.bodyTextXS),
                            const SizedBox(width: 3),
                            const Icon(Icons.star,
                                color: AppColors.yellow1,
                                size: 11), // ⬅️ smaller
                            const SizedBox(width: 3),
                            const Icon(Icons.airline_seat_recline_extra,
                                size: 12),
                            const SizedBox(width: 3),
                            Text('${results.passengerCapacity ?? '-'} Seat',
                                style: CommonFonts.bodyTextXS),
                            const SizedBox(width: 6),
                            const Icon(Icons.luggage_outlined, size: 12),
                            const SizedBox(width: 3),
                            Text(
                                '${results.cabinLuggageCapacity ?? '-'} cabin luggage',
                                style: CommonFonts.bodyTextXS),
                            const SizedBox(width: 6),
                            const Icon(Icons.speed_outlined, size: 12),
                            const SizedBox(width: 3),
                            Text('${totalDistance ?? '-'} km',
                                style: CommonFonts.bodyTextXS),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              SizedBox(
                height: 20,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: results.extras?.length ?? 0,
                  itemBuilder: (context, index) {
                    final iconUrl = amenityIcons[index] ?? '';
                    final label = results.extras?[index] ?? '';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: Colors.grey.shade400, width: 0.8),
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
              )
            ],
          ),
        ),
      ),
    );
  });
}

class BookingTopBar extends StatefulWidget {
  @override
  State<BookingTopBar> createState() => _BookingTopBarState();
}

class _BookingTopBarState extends State<BookingTopBar> {
  final SearchCabInventoryController searchCabInventoryController =
      Get.put(SearchCabInventoryController());
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  final PlaceSearchController placeSearchController =
      Get.put(PlaceSearchController());
  final FetchPackageController fetchPackageController =
      Get.put(FetchPackageController());

  String? tripCode;
  String? previousCode;

  @override
  void initState() {
    super.initState();
    getCurrentTripCode();
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
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
    previousCode =
        await StorageServices.instance.read('previousTripCode') ?? '';
    setState(() {});
  }

  String trimAfterTwoSpaces(String input) {
    final parts = input.split(' ');
    if (parts.length <= 2) return input;
    return parts.take(3).join(' ');
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
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.mainButtonBg),
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
    DateTime? backendEndUtc =
        searchCabInventoryController.indiaData.value?.result?.tripType?.endTime;

// Compare in UTC, pick the greater one
    DateTime finalDropUtc =
        (backendEndUtc != null && backendEndUtc.isAfter(localEndUtc))
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
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InventoryList(
                  requestData: bookingRideController.requestData.value,
                  fromFinalBookingPage: true,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              // color: AppColors.mainButtonBg.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back,
                size: 16, color: AppColors.mainButtonBg),
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
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (tripCode == '1')
                  ? '$formattedPickup - $formattedDrop'
                  : '$formattedPickup',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greyText5),
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

class ExtrasSelectionCard extends StatefulWidget {
  @override
  _ExtrasSelectionCardState createState() => _ExtrasSelectionCardState();
}

class _ExtrasSelectionCardState extends State<ExtrasSelectionCard> {
  List<SelectableExtra> indiaExtras = [];
  List<SelectableExtra> globalExtras = [];
  bool isLoading = true;
  String? _country;
  String? _errorMessage;

  final DropPlaceSearchController dropPlaceSearchController =
      Get.put(DropPlaceSearchController());
  final CabBookingController cabBookingController =
      Get.find<CabBookingController>();
  final CurrencyController currencyController = Get.find<CurrencyController>();

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      _country = dropPlaceSearchController.dropLatLng.value?.country;

      final isIndiaCountry = (_country?.toLowerCase() ?? '') == 'india';
      // 🇮🇳 India: ensure extras come from India inventory details API.
      // 🌍 Non-India: keep existing global flow unchanged.
      if (isIndiaCountry) {
        final existingIndiaExtras = cabBookingController
                .indiaData.value?.inventory?.carTypes?.extrasIdArray ??
            [];
        if (existingIndiaExtras.isEmpty &&
            cabBookingController.lastIndiaFareRequestData != null) {
          await cabBookingController.fetchIndiaInventoryData(
            requestData: Map<String, dynamic>.from(
                cabBookingController.lastIndiaFareRequestData!),
            context: context,
          );
        }
      }

      final rawIndiaExtras = cabBookingController
              .indiaData.value?.inventory?.carTypes?.extrasIdArray ??
          [];
      final rawGlobalExtras =
          cabBookingController.globalData.value?.vehicleDetails?.extraArray ??
              [];

      if (mounted) {
        setState(() {
          indiaExtras = rawIndiaExtras.map((e) {
            return SelectableExtra(
              id: e.id ?? '',
              label: e.title ?? '',
              price: e.price?.daily ?? 0,
            );
          }).toList();

          globalExtras = rawGlobalExtras.map((e) {
            return SelectableExtra(
              id: e.id ?? '',
              label: e.name ?? '',
              price: e.price?.daily ?? 0,
            );
          }).toList();

          isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _errorMessage = 'Failed to load extras: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: buildShimmer());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_country == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Country information not available',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    final isIndia = _country!.toLowerCase() == 'india';
    final extras = isIndia ? indiaExtras : globalExtras;
    final title = "Choose Extras";

    return _buildExtrasCard(title: title, extras: extras);
  }

  Widget _buildExtrasCard({
    required String title,
    required List<SelectableExtra> extras,
  }) {
    final isIndiaCountry = (_country?.toLowerCase() ?? '') == 'india';

    Future<void> refreshIndiaFareDetails() async {
      if (!isIndiaCountry) return;
      final base = cabBookingController.lastIndiaFareRequestData;
      if (base == null) return;

      // Pass extrasIdsArray when user checks/unchecks extras.
      final payload = Map<String, dynamic>.from(base);
      payload['extrasIdsArray'] =
          cabBookingController.selectedExtrasIds.toList(growable: false);

      // Refresh inventory when extras are selected/unselected to update extras list
      await cabBookingController.fetchIndiaFareDetails(
        requestData: payload,
        context: context,
        refreshInventory: true, // Also refresh inventory to update extras list
      );
      
      // Update the extras list from refreshed inventory data
      if (mounted) {
        setState(() {
          final rawIndiaExtras = cabBookingController
                  .indiaData.value?.inventory?.carTypes?.extrasIdArray ??
              [];
          indiaExtras = rawIndiaExtras.map((e) {
            return SelectableExtra(
              id: e.id ?? '',
              label: e.title ?? '',
              price: e.price?.daily ?? 0,
              isSelected: cabBookingController.selectedExtrasIds.contains(e.id),
            );
          }).toList();
        });
      }
    }

    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12), // smaller margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // smaller radius
          side: BorderSide(color: Colors.grey.shade300, width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10), // tighter padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(), // keep consistent with forms
                style: const TextStyle(
                  fontSize: 12, // smaller title
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (extras.isEmpty)
                const Text(
                  "No extras available",
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: extras.length,
                  itemBuilder: (context, index) {
                    final item = extras[index];

                    return InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        setState(() {
                          final newVal = !item.isSelected;
                          extras[index].isSelected = newVal;

                          cabBookingController.toggleExtraId(item.id, newVal);
                          cabBookingController.toggleExtraFacility(
                            item.label,
                            item.price.toDouble(),
                            newVal,
                          );
                        });

                        // 🇮🇳 India only: refresh fare details with extrasIdsArray.
                        if (isIndiaCountry) {
                          refreshIndiaFareDetails();
                        }
                      },
                      child: Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10.0), // less spacing
                          child: Row(
                            children: [
                              CustomCheckbox(
                                value: item.isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    extras[index].isSelected = val;
                                    cabBookingController.toggleExtraId(
                                        item.id, val);
                                    cabBookingController.toggleExtraFacility(
                                      item.label,
                                      item.price.toDouble(),
                                      val,
                                    );
                                  });

                                  // 🇮🇳 India only: refresh fare details with extrasIdsArray.
                                  if (isIndiaCountry) {
                                    refreshIndiaFareDetails();
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              FutureBuilder<double>(
                                future: currencyController
                                    .convertPrice(item.price.toDouble()),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return SizedBox(
                                      height: 12,
                                      width: 20,
                                      child: Center(
                                        child: SizedBox(
                                          height: 10,
                                          width: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.grey.shade400),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Text(
                                      "${currencyController.selectedCurrency.value.symbol}${item.price.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    );
                                  }

                                  final convertedValue =
                                      snapshot.data ?? item.price.toDouble();

                                  return Text(
                                    "${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              const Padding(
                                padding: EdgeInsets.only(right: 4.0),
                                child: Text(
                                  'per day',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          )),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExtraItem {
  String label;
  int price;
  bool isSelected;

  ExtraItem({
    required this.label,
    required this.price,
    this.isSelected = false,
  });
}

class TravelerDetailsForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final bool? fromPaymentFailurePage;

  const TravelerDetailsForm(
      {super.key,
      required this.formKey,
      this.fromPaymentFailurePage}); // ✅ Accept form key from parent
  @override
  _TravelerDetailsFormState createState() => _TravelerDetailsFormState();
}

class _TravelerDetailsFormState extends State<TravelerDetailsForm> {
  String selectedTitle = 'Mr.';
  final List<String> titles = ['Mr.', 'Ms.', 'Mrs.'];
  final ProfileController profileController = Get.put(ProfileController());
  final TextEditingController mobileController = TextEditingController();
  PhoneNumber number = PhoneNumber(isoCode: 'IN');
  String? _country;
  String? token;
  String? firstName;
  String? email;
  String? contact;
  String? contactCode;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController sourceController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController flightNoController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  final SearchCabInventoryController searchCabInventoryController =
      Get.put(SearchCabInventoryController());
  final CabBookingController cabBookingController =
      Get.put(CabBookingController());
  bool isGstSelected = false;
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
    print('yash trip code : $tripCode');
  }

  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');
    token = await StorageServices.instance.read('token');

    await profileController.fetchData();
    print('📦 3rd page country: $_country');

    if (widget.fromPaymentFailurePage == true) {
      firstName = await StorageServices.instance.read('firstName') ?? '';
      contact = await StorageServices.instance.read('contact') ?? '';
      email = await StorageServices.instance.read('emailId') ?? '';
    } else if (widget.fromPaymentFailurePage == null &&
        await StorageServices.instance.read('token') == null) {
      firstName = await StorageServices.instance.read('firstName') ?? '';
      contact = await StorageServices.instance.read('contact') ?? '';
      email = await StorageServices.instance.read('emailId') ?? '';
    } else {
      firstName =
          profileController.profileResponse.value?.result?.firstName ?? '';
      contact =
          profileController.profileResponse.value?.result?.contact.toString() ??
              '';
      contactCode =
          profileController.profileResponse.value?.result?.contactCode ?? '';
      email = profileController.profileResponse.value?.result?.emailID ?? '';
    }

    //fromPaymentFailurePagefromPaymentFailurePage logic yahi se karna hai.

    firstNameController.text = firstName ?? '';
    emailController.text = email ?? '';
    contactController.text = contact ?? '';
    sourceController.text = bookingRideController.prefilled.value;
    destinationController.text =
        tripCode == '3' ? '' : bookingRideController.prefilledDrop.value;

    print('First Name: $firstName');
    print('Contact: $contact');
    print('Contact Code: $contactCode');
    print('Email: $email');
    print(
        'yash current trip code for fight no is : ${searchCabInventoryController.indiaData.value?.result?.tripType?.currentTripCode}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // ensure controllers are in sync with UI
      });
      final cabBookingController = Get.find<CabBookingController>();
      Future.delayed(Duration(milliseconds: 100), () {
        // small delay to let TextEditingControllers update in the tree
        cabBookingController.validateForm();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      // ✅ Wrap form
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled, // ✅ show on change

      child: Card(
        color: Colors.white,
        margin: EdgeInsets.only(bottom: 20),
        elevation: 0,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Travelers Details",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 8),

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
                      onSelected: (_) => setState(() => selectedTitle = title),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 8),

              /// Fields
              _buildTextField(
                label: 'Full Name',
                hint: "Enter full name",
                controller: firstNameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Full name is required";
                  }
                  return null;
                },
              ),

              _buildTextField(
                label: 'Email',
                hint: "Enter email id",
                controller: emailController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Email is required";
                  }
                  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  return !regex.hasMatch(v.trim())
                      ? "Enter a valid email"
                      : null;
                },
              ),

              /// Phone
              Text(
                'Mobile no',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small label above the field

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    child: Row(
                      children: [
                        const SizedBox(
                            width: 6), // spacing between icon and field

                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: InternationalPhoneNumberInput(
                              selectorConfig: const SelectorConfig(
                                selectorType:
                                    PhoneInputSelectorType.BOTTOM_SHEET,
                                useBottomSheetSafeArea: true,
                                showFlags: true,
                              ),
                              selectorTextStyle: const TextStyle(
                                // ✅ smaller selector text
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              initialValue: number,
                              textFieldController: contactController,
                              textStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              onFieldSubmitted: (value) {
                                cabBookingController.validateForm();
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  Form.of(context).validate();
                                });
                              },
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      signed: true),
                              maxLength: 10,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Mobile number is required";
                                }
                                if (value.length != 10 ||
                                    !RegExp(r'^[0-9]+$').hasMatch(value)) {
                                  return "Enter valid 10-digit mobile number";
                                }
                                // trigger validation manually

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
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                              formatInput: false,
                              onInputChanged: (PhoneNumber value) async {
                                cabBookingController.validateForm();
                                contact = (value.phoneNumber
                                        ?.replaceAll(' ', '')
                                        .replaceFirst(
                                            value.dialCode ?? '', '')) ??
                                    '';
                                contactCode =
                                    value.dialCode?.replaceAll('+', '');
                                await StorageServices.instance
                                    .save('contactCode', contactCode ?? '');
                                await StorageServices.instance
                                    .save('contact', contact ?? '');
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              _buildTextField(
                  label: 'Pickup Address',
                  hint: "Enter Pickup Address",
                  controller: sourceController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Pickup address is required";
                    }
                    return null;
                  },
                  isReadOnly: true),

              _buildTextField(
                  label: 'Destination Address',
                  hint: "Enter Dropping Address",
                  controller: destinationController,
                  // validator: (v) {
                  //   if (v == null || v.trim().isEmpty) {
                  //     return "Drop address is required";
                  //   }
                  //   return null;
                  // },
                  isReadOnly: true),

              /// Flight No only for trip code 2
              if (searchCabInventoryController
                      .indiaData.value?.result?.tripType?.currentTripCode ==
                  '2')
                _buildTextField(
                  label: 'Enter Flight Number',
                  hint: "Enter Flight Number",
                  controller: flightNoController,
                  validator: (v) => null,
                ),

              _buildTextField(
                  label: 'Remarks',
                  hint: "Remarks",
                  controller: remarkController,
                  validator: (v) => null),

              SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => isGstSelected = !isGstSelected),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CustomCheckbox(
                          value: isGstSelected,
                          onChanged: (val) =>
                              setState(() => isGstSelected = val)),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('I have a GST number (Optional)',
                            style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),

              if (isGstSelected)
                _buildTextField(
                  label: 'GST Number',
                  hint: "Enter GST Number",
                  controller: gstController,
                  validator: null,
                ),

              SizedBox(height: 6)

              /// Submit Button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required String hint,
      required TextEditingController controller,
      String? Function(String?)? validator,
      String? tag,
      bool? isReadOnly}) {
    final CabBookingController cabBookingController =
        Get.put(CabBookingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permanent label
          Text(
            label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black38),
          ),
          const SizedBox(height: 4), // Small space between label and field
          TextFormField(
            controller: controller,
            readOnly: isReadOnly ?? false,
            style: const TextStyle(
              fontSize: 12, // smaller font
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint.toUpperCase(),
              hintStyle: const TextStyle(
                fontSize: 11.5, // smaller placeholder font
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              isDense: true, // makes height smaller
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8, // reduced vertical padding
                horizontal: 10, // reduced horizontal padding
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(6), // slightly smaller radius
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.black54, width: 1.2),
              ),
            ),
            validator: validator,
            onChanged: (value) async {
              // 🔄 Your existing logic
              if (controller == firstNameController) {
                firstName = value;
                await StorageServices.instance.save('firstName', value);
                print("📝 First Name updated: $value");
              } else if (controller == emailController) {
                email = value;
                await StorageServices.instance.save('emailId', value);
                print("📧 Email updated: $value");
              } else if (controller == sourceController) {
                bookingRideController.prefilled.value = value;
                await StorageServices.instance.save('pickupAddress', value);
                print("📍 Pickup Address updated: $value");
              } else if (controller == destinationController) {
                bookingRideController.prefilledDrop.value = value;
                await StorageServices.instance.save('dropAddress', value);
                print("🏁 Drop Address updated: $value");
              } else if (controller == flightNoController) {
                await StorageServices.instance.save('flightNo', value);
                print("✈️ Flight no updated: $value");
              } else if (controller == remarkController) {
                await StorageServices.instance.save('remark', value);
                print("📝 Remark updated: $value");
              } else if (controller == gstController) {
                await StorageServices.instance.save('gstValue', value);
                print("💳 GST updated: $value");
              }
              cabBookingController.validateForm();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class SelectableExtra {
  final String id;
  final String label;
  final num price;
  bool isSelected;

  SelectableExtra({
    required this.id,
    required this.label,
    required this.price,
    this.isSelected = false,
  });
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Create rounded rectangle path
    final borderPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    // Draw dotted border along the path
    final dashWidth = 4.0;
    final dashSpace = 3.0;
    final pathMetrics = borderPath.computeMetrics();

    for (final pathMetric in pathMetrics) {
      var distance = 0.0;
      while (distance < pathMetric.length) {
        final start = pathMetric.getTangentForOffset(distance)?.position;
        final dashEndDistance = (distance + dashWidth).clamp(0.0, pathMetric.length);
        final end = pathMetric.getTangentForOffset(dashEndDistance)?.position;

        if (start != null && end != null) {
          canvas.drawLine(start, end, paint);
        }

        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

// UI custom checkbox
class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? AppColors.mainButtonBg : Colors.white,
          border: Border.all(
            color: AppColors.mainButtonBg,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: value
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

class CouponOffersCard extends StatefulWidget {
  const CouponOffersCard({super.key});

  @override
  State<CouponOffersCard> createState() => _CouponOffersCardState();
}

class _CouponOffersCardState extends State<CouponOffersCard> {
  bool _isExpanded = false;
  bool _fetchRequested = false;

  void _maybeFetchCoupons() {
    // Don’t spam requests; also skip if already have data.
    final CouponController fetchCouponController =
    Get.isRegistered<CouponController>()
        ? Get.find<CouponController>()
        : Get.put(CouponController());

    if (fetchCouponController.isLoading.value) return;
    if (fetchCouponController.coupons.isNotEmpty) {
      _fetchRequested = true;
      return;
    }
    if (_fetchRequested) return;

    final CabBookingController cabBookingController =
    Get.isRegistered<CabBookingController>()
        ? Get.find<CabBookingController>()
        : Get.put(CabBookingController());

    final vehicleType =
        cabBookingController.indiaData.value?.inventory?.carTypes?.type ?? '';
    if (vehicleType.trim().isEmpty) return; // wait until available

    _fetchRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fetchCouponController.fetchCoupons(context, vehicleType: vehicleType);
    });
  }

  @override
  void initState() {
    super.initState();
    _maybeFetchCoupons();
  }

  Future<void> _applyOrToggleCoupon(CouponData coupon) async {
    final CabBookingController cabBookingController =
    Get.isRegistered<CabBookingController>()
        ? Get.find<CabBookingController>()
        : Get.put(CabBookingController());
    final BookingRideController bookingRideController =
    Get.isRegistered<BookingRideController>()
        ? Get.find<BookingRideController>()
        : Get.put(BookingRideController());
    final SearchCabInventoryController searchCabInventoryController =
    Get.isRegistered<SearchCabInventoryController>()
        ? Get.find<SearchCabInventoryController>()
        : Get.put(SearchCabInventoryController());
    final ApplyCouponController applyCouponController =
    Get.isRegistered<ApplyCouponController>()
        ? Get.find<ApplyCouponController>()
        : Get.put(ApplyCouponController());

    final isSelected = cabBookingController.selectedCouponId.value == coupon.id;
    if (isSelected) {
      cabBookingController.clearSelectedCoupon();
    } else {
      cabBookingController.setSelectedCoupon(
        couponId: coupon.id ?? '',
        couponCode: coupon.codeName,
      );

      // Call applyCoupon API to validate and show success dialog
      try {
        final token = await StorageServices.instance.read('token');
        final Map<String, dynamic> requestData = {
          "userID": null,
          "couponID": coupon.id,
          "totalAmount": cabBookingController.totalFare,
          "sourceLocation": bookingRideController.prefilled.value,
          "destinationLocation": bookingRideController.prefilledDrop.value,
          "serviceType": null,
          "bankName": null,
          "userType": "CUSTOMER",
          "bookingDateTime": await StorageServices.instance.read('userDateTime'),
          "appliedCoupon": token != null ? 1 : 0,
          "payNow": cabBookingController.actualFare,
          "tripType": searchCabInventoryController
              .indiaData.value?.result?.tripType?.currentTripCode,
          "vehicleType":
          cabBookingController.indiaData.value?.inventory?.carTypes?.type ??
              ''
        };
        await applyCouponController.applyCoupon(
          requestData: requestData,
          context: context,
        );
      } catch (e) {
        print('Error applying coupon: $e');
        // If API fails, still allow coupon selection but don't show dialog
      }
    }

    // Refresh fare details after coupon selection/unselection
    final isIndiaCountry = (cabBookingController.country?.toLowerCase() ?? '') == 'india';
    if (isIndiaCountry && cabBookingController.lastIndiaFareRequestData != null) {
      final payload = Map<String, dynamic>.from(cabBookingController.lastIndiaFareRequestData!);
      if (cabBookingController.selectedExtrasIds.isNotEmpty) {
        payload['extrasIdsArray'] =
            cabBookingController.selectedExtrasIds.toList(growable: false);
      }
      await cabBookingController.fetchIndiaFareDetails(
        requestData: payload,
        context: context,
      );
    }
  }

  Widget _couponRow({
    required CouponData coupon,
    required bool selected,
  }) {
    final borderColor = selected ? const Color(0xFF4082F1) : Color(0xFF7B7B7B);
    return InkWell(
      onTap: () => _applyOrToggleCoupon(coupon),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
          color: selected ? const Color(0xFFEFF6FF) : Color(0xFFF3F3F3),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 15,
                color:
                selected ? const Color(0xFF4082F1) : Color(0xFF7B7B7B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: const Color(0xFFFFFFFF),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset('assets/images/coupon_tag.png', width: 16,height: 16,fit: BoxFit.cover,),
                                const SizedBox(width: 6),
                                Text(
                                  (coupon.codeName ?? '').toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF484848),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DottedBorderPainter(
                                color: const Color(0xFF7CC521),
                                strokeWidth: 1.5,
                                borderRadius: 5,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  // Text(
                  //   coupon.codeName ?? '',
                  //   style: const TextStyle(
                  //     fontSize: 13,
                  //     fontWeight: FontWeight.w600,
                  //     color: Colors.black87,
                  //   ),
                  // ),
                  // const SizedBox(height: 2),
                  Text(
                    coupon.codeDescription ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF585858),
                      height: 1.25,
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

  @override
  Widget build(BuildContext context) {
    final CouponController fetchCouponController =
    Get.isRegistered<CouponController>()
        ? Get.find<CouponController>()
        : Get.put(CouponController());

    // If coupons weren't fetched due to timing (vehicleType late), retry.
    _maybeFetchCoupons();

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.greyBorder1, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final isLoading = fetchCouponController.isLoading.value;
          final coupons = fetchCouponController.coupons;
          final CabBookingController cabBookingController =
          Get.isRegistered<CabBookingController>()
              ? Get.find<CabBookingController>()
              : Get.put(CabBookingController());
          final selectedCode = cabBookingController.selectedCouponCode.value;

          final list = _isExpanded
              ? coupons.toList()
              : (coupons.isNotEmpty ? <CouponData>[coupons.first] : <CouponData>[]);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Coupon & Offers',
                      style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF484848)),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset('assets/images/coupon_header.png',width: 41, height: 30, fit: BoxFit.cover),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (selectedCode != null && selectedCode.isNotEmpty) ...[
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B7B7B),
                          ),
                        ),
                      ),
                      Text(
                        'Applied',
                        style:  const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7B7B7B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              ] else if (coupons.isEmpty) ...[
                Text(
                  'No coupons available right now.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ] else ...[
                ...list.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _couponRow(
                    coupon: c,
                    selected: cabBookingController.selectedCouponId.value == c.id,
                  ),
                )),
              ],

              if (coupons.length > 1) ...[
                const SizedBox(height: 2),
                Center(
                  child: InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Text(
                      _isExpanded ? 'View Less' : 'View All Coupons',
                      style: const TextStyle(
                        color: Color(0xFF2F6BFF),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

// coupon ui
class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  String? selectedCouponCode;
  final TextEditingController couponController = TextEditingController();
  final CouponController fetchCouponController = Get.put(CouponController());
  final CabBookingController cabBookingController = Get.put(CabBookingController());

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Available Coupons",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Scrollbar(
                thickness: 2,
                thumbVisibility: true,
                radius: const Radius.circular(4),
                trackVisibility: false,
                interactive: true,
                scrollbarOrientation: ScrollbarOrientation.right,
                child: ListView.builder(
                  itemCount: fetchCouponController.coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = fetchCouponController.coupons[index];
                    return _buildCouponCard(coupon);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Have a coupon code?",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: couponController,
                    decoration: InputDecoration(
                      hintText: "Enter Coupon Code",
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final inputCode = couponController.text.trim();
                    if (inputCode.isNotEmpty) {
                      setState(() {
                        selectedCouponCode = inputCode;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Apply"),
                )
              ],
            ),
            if (selectedCouponCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(Icons.discount, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Coupon "$selectedCouponCode" applied',
                        style:
                        const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                    Chip(
                      label: const Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // avatar: const Icon(
                      //   Icons.close,
                      //   size: 16,
                      //   color: Colors.redAccent,
                      // ),
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 0),
                      deleteIcon: null,
                      deleteIconColor: Colors.redAccent,
                      onDeleted: () async {
                        setState(() {
                          selectedCouponCode = null;
                          couponController.clear();
                          cabBookingController.clearSelectedCoupon();
                        });

                        // Refresh fare details after coupon removal
                        final isIndiaCountry = (cabBookingController.country?.toLowerCase() ?? '') == 'india';
                        if (isIndiaCountry && cabBookingController.lastIndiaFareRequestData != null) {
                          final payload = Map<String, dynamic>.from(cabBookingController.lastIndiaFareRequestData!);
                          if (cabBookingController.selectedExtrasIds.isNotEmpty) {
                            payload['extrasIdsArray'] =
                                cabBookingController.selectedExtrasIds.toList(growable: false);
                          }
                          await cabBookingController.fetchIndiaFareDetails(
                            requestData: payload,
                            context: context,
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(CouponData coupon) {
    final CabBookingController cabBookingController = Get.put(CabBookingController());
    final isSelected = selectedCouponCode == coupon.codeName;
    return GestureDetector(
        onTap: () async {
          setState(() {
            if (isSelected) {
              selectedCouponCode = null;
              couponController.clear();
              cabBookingController.clearSelectedCoupon();
            } else {
              selectedCouponCode = coupon.codeName;
              couponController.text = coupon.codeName ?? "";
              cabBookingController.setSelectedCoupon(
                couponId: coupon.id ?? '',
                couponCode: coupon.codeName,
              );
            }
          });

          // Refresh fare details after coupon selection/unselection
          final isIndiaCountry = (cabBookingController.country?.toLowerCase() ?? '') == 'india';
          if (isIndiaCountry && cabBookingController.lastIndiaFareRequestData != null) {
            final payload = Map<String, dynamic>.from(cabBookingController.lastIndiaFareRequestData!);
            if (cabBookingController.selectedExtrasIds.isNotEmpty) {
              payload['extrasIdsArray'] =
                  cabBookingController.selectedExtrasIds.toList(growable: false);
            }
            await cabBookingController.fetchIndiaFareDetails(
              requestData: payload,
              context: context,
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey.shade100 : Colors.grey.shade100,
            border: Border.all(
              color: isSelected ? AppColors.mainButtonBg : Colors.grey.shade300,
              width: 1.3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.local_offer_outlined,
                color: isSelected ? AppColors.mainButtonBg : Colors.black54,
                size: 24,
              ),
              const SizedBox(width: 12),
              // Expanded(
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         coupon.codeDescription ?? '',
              //         style: const TextStyle(
              //           fontSize: 15,
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //       const SizedBox(height: 4),
              //       // Text(
              //       //   coupon.description,
              //       //   style: const TextStyle(fontSize: 13),
              //       // ),
              //       const SizedBox(height: 6),
              //       Container(
              //         padding: const EdgeInsets.symmetric(
              //             horizontal: 8, vertical: 4),
              //         decoration: BoxDecoration(
              //           color: Colors.white,
              //           border: Border.all(
              //             color: isSelected
              //                 ? AppColors.mainButtonBg
              //                 : Colors.grey.shade400,
              //           ),
              //           borderRadius: BorderRadius.circular(6),
              //         ),
              //         child: Text(
              //           coupon.codeName ?? '',
              //           style: TextStyle(
              //             fontFamily: 'monospace',
              //             fontSize: 13,
              //             fontWeight: FontWeight.w600,
              //             letterSpacing: 1,
              //             color: isSelected
              //                 ? AppColors.mainButtonBg
              //                 : Colors.black87,
              //           ),
              //         ),
              //       )
              //     ],
              //   ),
              // )
            ],
          ),
        ));
  }
}


class BottomPaymentBar extends StatefulWidget {
  final String? endtime;
  const BottomPaymentBar({super.key, this.endtime});

  @override
  _BottomPaymentBarState createState() => _BottomPaymentBarState();
}

class _BottomPaymentBarState extends State<BottomPaymentBar> {
  final cabBookingController = Get.find<CabBookingController>();
  final FetchReservationBookingData fetchReservationBookingData =
      Get.put(FetchReservationBookingData());
  final SourceLocationController sourceController =
      Get.put(SourceLocationController());
  final DestinationLocationController destinationController =
      Get.put(DestinationLocationController());

  int selectedOption = 0;

  String? _country;
  final IndiaPaymentController indiaPaymentController =
      Get.put(IndiaPaymentController());
  final GlobalPaymentController globalPaymentController =
      Get.put(GlobalPaymentController());
  final SearchCabInventoryController searchCabInventoryController =
      Get.put(SearchCabInventoryController());
  final DropPlaceSearchController dropPlaceSearchController =
      Get.put(DropPlaceSearchController());
  final currencyController = Get.find<CurrencyController>();

  String? token,
      firstName,
      email,
      contact,
      contactCode,
      flightNo,
      remark,
      gstValue;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _country = dropPlaceSearchController.dropLatLng.value?.country;
    cabBookingController.country = _country;
    token = await StorageServices.instance.read('token');
    firstName = await StorageServices.instance.read('firstName');
    contact = await StorageServices.instance.read('contact');
    contactCode = await StorageServices.instance.read('contactCode');
    email = await StorageServices.instance.read('emailId');
    flightNo = await StorageServices.instance.read('flightNo');
    remark = await StorageServices.instance.read('remark');
    gstValue = await StorageServices.instance.read('gstValue');
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Platform.isIOS
          ? const EdgeInsets.only(top: 8, bottom: 24, left: 12, right: 12)
          : const EdgeInsets.only(
              top: 8, bottom: 8, left: 12, right: 12), // reduced
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: Platform.isAndroid ? 48 : 48,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Obx(() {
                final isIndia = (cabBookingController.country ??
                            _country ??
                            '')
                        .toLowerCase()
                        .trim() ==
                    'india';

                // India part-payment flag from inventory response (fallback: true)
                final isPartPaymentAllowed = (cabBookingController
                            .indiaData.value?.inventory?.isPartPaymentAllowed ??
                        true) ==
                    true;

                // For India: Use fare details from new API, otherwise use old way
                final totalFareValue = isIndia &&
                        cabBookingController.indiaFareDetails.value?.fareDetails
                                ?.totalFare !=
                            null
                    ? cabBookingController
                        .indiaFareDetails.value!.fareDetails!.totalFare!
                        .toDouble()
                    : cabBookingController.totalFare.toDouble();

                final partFareValue = isIndia &&
                        cabBookingController.indiaFareDetails.value?.fareDetails
                                ?.totalFare !=
                            null
                    ? (cabBookingController
                            .indiaFareDetails.value!.fareDetails!.totalFare!
                            .toDouble() *
                        0.20)
                    : cabBookingController.partFare.toDouble();

                return Row(
                  children: [
                    // 🔹 Part Pay
                    if (isIndia && isPartPaymentAllowed)
                      Expanded(
                        child: FutureBuilder<double>(
                          future:
                              currencyController.convertPrice(partFareValue),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox(
                                height: 12,
                                width: 20,
                                child: Center(
                                  child: SizedBox(
                                    height: 10,
                                    width: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return const Text(
                                "--",
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600),
                              );
                            }
                            final convertedValue =
                                snapshot.data ?? partFareValue;

                            return _buildRadioOption(
                              index: 0,
                              title: 'Part Pay',
                              amount:
                                  "${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(2)}",
                            );
                          },
                        ),
                      ),

                    VerticalDivider(width: 1, color: Colors.grey.shade300),

                    // 🔹 Full Pay
                    Expanded(
                      child: FutureBuilder<double>(
                        future: currencyController.convertPrice(totalFareValue),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(
                              height: 12,
                              width: 20,
                              child: Center(
                                child: SizedBox(
                                  height: 10,
                                  width: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey.shade400),
                                  ),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return const Text(
                              "--",
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            );
                          }
                          final convertedValue =
                              snapshot.data ?? totalFareValue;

                          return _buildRadioOption(
                            index: 1,
                            title: 'Full Pay',
                            amount:
                                "${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(2)}",
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          IconButton(
            onPressed: () {
              final controller = Get.find<CabBookingController>();
              if (currencyController.isLoading.value) {
                Center(
                  child: buildShimmer(),
                );
              }
              controller.showAllChargesBottomSheet(context);
            },
            icon: const Icon(Icons.info_outline, size: 16),
            color: Colors.black87,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final canProceed = cabBookingController.isFormValid.value;
            return SizedBox(
              width: 110, // shrink button
              height: 46,
              child: Opacity(
                opacity: canProceed ? 1.0 : 0.4,
                child: MainButton(
                  text: 'Pay',
                  onPressed: canProceed
                      ? _country?.toLowerCase() == 'india'
                          ? () async {
                              final destinationKeys = [
                                'destinationPlaceId',
                                'destinationTitle',
                                'destinationCity',
                                'destinationState',
                                'destinationCountry',
                                'destinationTypes',
                                'destinationTerms',
                                'destinationLat',
                                'destinationLng',
                              ];

                              final destinationValues = await Future.wait(
                                destinationKeys
                                    .map(StorageServices.instance.read),
                              );

                              final destinationData = Map.fromIterables(
                                  destinationKeys, destinationValues);
                              showRazorpaySkeletonLoader(context);
                              print(
                                  'yash amountToBeCollected ids : ${double.parse(cabBookingController.amountTobeCollected.toStringAsFixed(2))}');
                              print(
                                  'yash fare details : ${cabBookingController.indiaData.value?.inventory?.carTypes?.fareDetails?.toJson()}');
                              final timeZone = await StorageServices.instance
                                  .read('timeZone');
                              final sourceTitle = await StorageServices.instance
                                  .read('sourceTitle');
                              final sourcePlaceId = await StorageServices
                                  .instance
                                  .read('sourcePlaceId');
                              final sourceCity = await StorageServices.instance
                                  .read('sourceCity');
                              final sourceState = await StorageServices.instance
                                  .read('sourceState');
                              final sourceCountry = await StorageServices
                                  .instance
                                  .read('country');
                              final sourceLat = await StorageServices.instance
                                  .read('sourceLat');
                              final sourceLng = await StorageServices.instance
                                  .read('sourceLng');
                              // source type and terms
                              final typesJson = await StorageServices.instance
                                  .read('sourceTypes');
                              final List<String> sourceTypes =
                                  typesJson != null && typesJson.isNotEmpty
                                      ? List<String>.from(jsonDecode(typesJson))
                                      : [];

                              final termsJson = await StorageServices.instance
                                  .read('sourceTerms');
                              final List<Map<String, dynamic>> sourceTerms =
                                  termsJson != null && termsJson.isNotEmpty
                                      ? List<Map<String, dynamic>>.from(
                                          jsonDecode(termsJson))
                                      : [];

                              //destination type and terms
                              final destinationPlaceId = await StorageServices
                                  .instance
                                  .read('destinationPlaceId');
                              final destinationTitle = await StorageServices
                                  .instance
                                  .read('destinationTitle');
                              final destinationCity = await StorageServices
                                  .instance
                                  .read('destinationCity');
                              final destinationState = await StorageServices
                                  .instance
                                  .read('destinationState');
                              final destinationCountry = await StorageServices
                                  .instance
                                  .read('destinationCountry');

                              final destinationTypesJson = await StorageServices
                                  .instance
                                  .read('destinationTypes');
                              final destinationTermsJson = await StorageServices
                                  .instance
                                  .read('destinationTerms');

                              // Decode JSON strings to actual List or Map types (if applicable)
                              final List<String> destinationType =
                                  destinationTypesJson != null &&
                                          destinationTypesJson.isNotEmpty
                                      ? List<String>.from(
                                          jsonDecode(destinationTypesJson))
                                      : [];
                              final List<Map<String, dynamic>>
                                  destinationTerms =
                                  destinationTermsJson != null &&
                                          destinationTermsJson.isNotEmpty
                                      ? List<Map<String, dynamic>>.from(
                                          jsonDecode(destinationTermsJson))
                                      : [];
                              final destinationLat = await StorageServices
                                  .instance
                                  .read('destinationLat');
                              final destinationLng = await StorageServices
                                  .instance
                                  .read('destinationLng');

                              final Map<String, dynamic> requestData = {
                                "firstName": await StorageServices.instance
                                    .read('firstName'),
                                "contactCode": await StorageServices.instance
                                    .read('contactCode'),
                                "contact": await StorageServices.instance
                                    .read('contact'),
                                "countryName": _country,
                                "userType": "CUSTOMER",
                                "gender": 'MALE',
                                "emailID": await StorageServices.instance
                                    .read('emailId')
                              };
                              final Map<String, dynamic>
                                  provisionalRequestData = {
                                "reservation": {
                                  "flightNumber": flightNo ?? "",
                                  "remarks": remark ?? "",
                                  "gst_number": gstValue ?? "",
                                  "payment_gateway_used": 1,
                                  "countryName": _country,
                                  "search_id": "",
                                  "partnername": "wti",
                                  "start_time": cabBookingController
                                      .indiaData.value?.tripType?.pickUpDateTime
                                      ?.toIso8601String(),
                                  "end_time": cabBookingController
                                      .indiaData.value?.tripType?.dropDateTime
                                      ?.toIso8601String(),
                                  "platform_fee": 0,
                                  "booking_gst": 0,
                                  "one_way_distance": cabBookingController
                                      .indiaData
                                      .value
                                      ?.inventory
                                      ?.distanceBooked
                                      ?.toInt(),
                                  "distance": cabBookingController.indiaData
                                      .value?.inventory?.distanceBooked
                                      ?.toInt(),
                                  "package": await StorageServices.instance
                                              .read('currentTripCode') ==
                                          '3'
                                      ? cabBookingController
                                              .indiaData
                                              .value
                                              ?.inventory
                                              ?.carTypes
                                              ?.packageId ??
                                          ''
                                      : null,
                                  "flags": [],
                                  "base_km": cabBookingController.indiaData
                                      .value?.inventory?.carTypes?.baseKm
                                      ?.toInt(),
                                  "vehicle_details": {
                                    "sku_id": cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.skuId ??
                                        '',
                                    "fleet_id": cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.fleetId ??
                                        '',
                                    "type": cabBookingController.indiaData.value
                                            ?.inventory?.carTypes?.type ??
                                        '',
                                    "subcategory": cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.subcategory ??
                                        '',
                                    "combustion_type": cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.combustionType ??
                                        '',
                                    "model": cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.model ??
                                        '',
                                    "carrier": cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.carrier ??
                                        false,
                                    "make_year_type": cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.makeYearType ??
                                        '',
                                    "make_year": ""
                                  },
                                  "source": {
                                    "address": sourceController.title.value,
                                    "latitude": placeSearchController
                                        .getPlacesLatLng.value?.latLong.lat,
                                    "longitude": placeSearchController
                                        .getPlacesLatLng.value?.latLong.lng,
                                    "city": sourceController.city.value,
                                    "place_id": sourceController.placeId.value,
                                    "types": sourceController.types.toList(),
                                    "state": sourceController.state.value,
                                    "country": sourceController.country.value
                                  },
                                  "destination": await StorageServices.instance
                                              .read('currentTripCode') ==
                                          '3'
                                      ? {}
                                      : {
                                          "address": destinationController
                                                  .title.value.isEmpty
                                              ? destinationData[
                                                  'destinationTitle']
                                              : destinationController
                                                  .title.value,
                                          "latitude": dropPlaceSearchController
                                              .dropLatLng.value?.latLong.lat,
                                          "longitude": dropPlaceSearchController
                                              .dropLatLng.value?.latLong.lng,
                                          "city": destinationController
                                                  .city.value.isEmpty
                                              ? destinationData[
                                                  'destinationCity']
                                              : destinationController
                                                  .city.value,
                                          "place_id": destinationController
                                                  .placeId.value.isNotEmpty
                                              ? destinationData[
                                                  'destinationPlaceId']
                                              : destinationController
                                                  .placeId.value,
                                          "types": destinationController
                                                  .types.isEmpty
                                              ? List<String>.from(jsonDecode(
                                                  destinationData[
                                                          'destinationTypes'] ??
                                                      ''))
                                              : destinationController.types
                                                  .toList(),
                                          "state": destinationController
                                                  .state.value.isEmpty
                                              ? destinationData[
                                                  'destinationState']
                                              : destinationController
                                                  .state.value,
                                          "country": destinationController
                                                  .country.value.isEmpty
                                              ? destinationData[
                                                  'destinationCountry']
                                              : destinationController
                                                  .country.value
                                        },
                                  "stopovers": [],
                                  "trip_type_details": {
                                    "basic_trip_type": cabBookingController
                                            .indiaData
                                            .value
                                            ?.tripType
                                            ?.tripTypeDetails
                                            ?.basicTripType ??
                                        '',
                                    "trip_type": cabBookingController
                                        .indiaData.value?.tripType?.tripType,
                                    cabBookingController
                                                .indiaData
                                                .value
                                                ?.tripType
                                                ?.tripTypeDetails
                                                ?.airportType !=
                                            null
                                        ? "airport_type"
                                        : cabBookingController
                                                .indiaData
                                                .value
                                                ?.tripType
                                                ?.tripTypeDetails
                                                ?.basicTripType ??
                                            '': null
                                  },
                                  "paid": false,
                                  "extrasSelected":
                                      cabBookingController.selectedExtrasIds,
                                  "total_fare": cabBookingController.totalFare,
                                  "amount_to_be_collected": double.parse(
                                      cabBookingController.amountTobeCollected
                                          .toStringAsFixed(2)),
                                  "cancelled_by": null,
                                  "cancellation_reason": null,
                                  "canceltime": null,
                                  "couponCodeUsed": null,
                                  "offerUsed": null,
                                  "userType": "CUSTOMER",
                                  "timezone": "Asia/Kolkata",
                                  "guest_id": null
                                },
                                "order": {
                                  "currency": currencyController
                                      .selectedCurrency.value.code,
                                  "amount": selectedOption == 0
                                      ? await currencyController.convertPrice(
                                          cabBookingController.partFare)
                                      : await currencyController.convertPrice(
                                          cabBookingController
                                              .totalFare), //(part payment or full paymenmt)
                                },
                                "receiptData": {
                                  "countryName":
                                      currencyController.country.value,
                                  "baseCurrency": currencyController
                                      .fromCurrency.value.code,
                                  "currency": {
                                    "currencyName": currencyController
                                        .selectedCurrency.value.code,
                                    "currencyRate": currencyController
                                            .convertedRate.value ??
                                        1
                                  },
                                  "addon_charges":
                                      cabBookingController.extraFacilityCharges,
                                  "isOffer": false,
                                  "fare_details": {
                                    "actual_fare":
                                        cabBookingController.actualFare,
                                    "seller_discount": 0,
                                    // ⬇️ Use new India fareDetails API when available, fallback to old inventory data
                                    "per_km_charge": cabBookingController
                                            .indiaFareDetails
                                            .value
                                            ?.fareDetails
                                            ?.perKmCharge
                                            ?.toDouble() ??
                                        cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.fareDetails
                                            ?.perKmCharge ??
                                        0,
                                    "per_km_extra_charge": cabBookingController
                                            .indiaFareDetails
                                            .value
                                            ?.fareDetails
                                            ?.perKmExtraCharge
                                            ?.toDouble() ??
                                        cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.fareDetails
                                            ?.perKmExtraCharge ??
                                        0,
                                    "amount_paid": selectedOption == 0
                                        ? cabBookingController.partFare
                                        : cabBookingController
                                            .totalFare, //(part payment or full paymenmt)
                                    "total_driver_charges": cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.fareDetails
                                            ?.totalDriverCharges ??
                                        0,
                                    "base_fare": cabBookingController
                                            .indiaFareDetails
                                            .value
                                            ?.fareDetails
                                            ?.baseFare
                                            ?.toDouble() ??
                                        cabBookingController
                                            .indiaData
                                            .value
                                            ?.inventory
                                            ?.carTypes
                                            ?.fareDetails
                                            ?.baseFare ??
                                        0,
                                    "total_fare": cabBookingController
                                        .totalFare, //(full payment, already uses API when available)
                                    "total_tax": double.parse(
                                        cabBookingController.taxCharge
                                            .toStringAsFixed(2)),
                                    "extra_time_fare": cabBookingController
                                        .indiaData
                                        .value
                                        ?.inventory
                                        ?.carTypes
                                        ?.fareDetails
                                        ?.extraTimeFare
                                        ?.toJson(),
                                    "extra_charges": cabBookingController
                                        .indiaData
                                        .value
                                        ?.inventory
                                        ?.carTypes
                                        ?.fareDetails
                                        ?.extraCharges
                                        ?.toJson(),
                                    "amount_to_be_collected": double.parse(
                                        cabBookingController.amountTobeCollected
                                            .toStringAsFixed(2))
                                  },
                                  // "fare_details": cabBookingController.indiaData.value?.inventory?.carTypes?.fareDetails?.toJson(),

                                  "paymentType":
                                      selectedOption == 1 ? "FULL" : "PART"
                                }
                              };

                              cabBookingController.selectedOption.value =
                                  selectedOption;

                              await indiaPaymentController
                                  .verifySignup(
                                      requestData: requestData,
                                      provisionalRequestData:
                                          provisionalRequestData,
                                      context: context)
                                  .then((value) {});
                              GoRouter.of(context).pop();
                            }
                          : () async {
                              globalPaymentController.showLoader(context);

                              print(
                                  'yash amountToBeCollected ids : ${double.parse(cabBookingController.amountTobeCollected.toStringAsFixed(2))}');
                              print(
                                  'yash fare details : ${cabBookingController.indiaData.value?.inventory?.carTypes?.fareDetails?.toJson()}');
                              final timeZone = await StorageServices.instance
                                  .read('timeZone');
                              final sourceTitle = await StorageServices.instance
                                  .read('sourceTitle');
                              final sourcePlaceId = await StorageServices
                                  .instance
                                  .read('sourcePlaceId');
                              final sourceCity = await StorageServices.instance
                                  .read('sourceCity');
                              final sourceState = await StorageServices.instance
                                  .read('sourceState');
                              final sourceCountry = await StorageServices
                                  .instance
                                  .read('country');
                              final sourceLat = await StorageServices.instance
                                  .read('sourceLat');
                              final sourceLng = await StorageServices.instance
                                  .read('sourceLng');
                              // source type and terms
                              final typesJson = await StorageServices.instance
                                  .read('sourceTypes');
                              final List<String> sourceTypes =
                                  typesJson != null && typesJson.isNotEmpty
                                      ? List<String>.from(jsonDecode(typesJson))
                                      : [];

                              final termsJson = await StorageServices.instance
                                  .read('sourceTerms');
                              final List<Map<String, dynamic>> sourceTerms =
                                  termsJson != null && termsJson.isNotEmpty
                                      ? List<Map<String, dynamic>>.from(
                                          jsonDecode(termsJson))
                                      : [];

                              //destination type and terms
                              final destinationPlaceId = await StorageServices
                                  .instance
                                  .read('destinationPlaceId');
                              final destinationTitle = await StorageServices
                                  .instance
                                  .read('destinationTitle');
                              final destinationCity = await StorageServices
                                  .instance
                                  .read('destinationCity');
                              final destinationState = await StorageServices
                                  .instance
                                  .read('destinationState');
                              final destinationCountry = await StorageServices
                                  .instance
                                  .read('destinationCountry');

                              final destinationTypesJson = await StorageServices
                                  .instance
                                  .read('destinationTypes');
                              final destinationTermsJson = await StorageServices
                                  .instance
                                  .read('destinationTerms');

                              // Decode JSON strings to actual List or Map types (if applicable)
                              final List<String> destinationType =
                                  destinationTypesJson != null &&
                                          destinationTypesJson.isNotEmpty
                                      ? List<String>.from(
                                          jsonDecode(destinationTypesJson))
                                      : [];
                              final List<Map<String, dynamic>>
                                  destinationTerms =
                                  destinationTermsJson != null &&
                                          destinationTermsJson.isNotEmpty
                                      ? List<Map<String, dynamic>>.from(
                                          jsonDecode(destinationTermsJson))
                                      : [];
                              final destinationLat = await StorageServices
                                  .instance
                                  .read('destinationLat');
                              final destinationLng = await StorageServices
                                  .instance
                                  .read('destinationLng');

                              final Map<String, dynamic> requestData = {
                                "firstName": await StorageServices.instance
                                    .read('firstName'),
                                "contactCode": await StorageServices.instance
                                    .read('contactCode'),
                                "contact": await StorageServices.instance
                                    .read('contact'),
                                "countryName": _country,
                                "userType": "CUSTOMER",
                                "gender": 'MALE',
                                "emailID": await StorageServices.instance
                                    .read('emailId')
                              };

                              final Map<String, dynamic>
                                  provisionalRequestData = {
                                "reservation": {
                                  "flightNumber": "",
                                  "remarks": "",
                                  "gst_number": "",
                                  "payment_gateway_used": 0,
                                  "countryName": _country,
                                  "search_id": "",
                                  "partnername": "wti",
                                  "start_time": await StorageServices.instance
                                      .read('userDateTime'),
                                  "end_time": widget.endtime,
                                  "platform_fee": 0,
                                  "booking_gst": 0,
                                  "one_way_distance": cabBookingController
                                      .globalData
                                      .value
                                      ?.fareBreakUpDetails
                                      ?.baseKm
                                      ?.toInt(),
                                  "distance": 0,
                                  "package": null,
                                  "flags": [],
                                  "base_km": cabBookingController.globalData
                                      .value?.fareBreakUpDetails?.baseKm
                                      ?.toInt(),
                                  "vehicle_details": {
                                    // abhi global m nhi aa rhi hai
                                    "sku_id": null,
                                    "fleet_id": cabBookingController.globalData
                                            .value?.vehicleDetails?.id ??
                                        '',
                                    "type": cabBookingController
                                            .globalData
                                            .value
                                            ?.fareBreakUpDetails
                                            ?.vehicleCategory ??
                                        '',
                                    "subcategory": null,
                                    "combustion_type": cabBookingController
                                            .globalData
                                            .value
                                            ?.vehicleDetails
                                            ?.fuelType ??
                                        '',
                                    "model": cabBookingController
                                            .globalData
                                            .value
                                            ?.vehicleDetails
                                            ?.carCategoryName ??
                                        '',
                                    "carrier": null,
                                    "make_year_type": null,
                                    "make_year": "",
                                    "title": cabBookingController.globalData
                                            .value?.vehicleDetails?.title ??
                                        ''
                                  },
                                  "source": {
                                    "address": sourceController.title.value,
                                    "latitude": placeSearchController
                                        .getPlacesLatLng.value?.latLong.lat,
                                    "longitude": placeSearchController
                                        .getPlacesLatLng.value?.latLong.lng,
                                    "city": sourceController.city.value,
                                    "place_id": sourceController.placeId.value,
                                    "types": sourceController.types.toList(),
                                    "state": sourceController.state.value,
                                    "country": sourceController.country.value
                                  },
                                  "destination": {
                                    "address":
                                        destinationController.title.value,
                                    "latitude": dropPlaceSearchController
                                        .dropLatLng.value?.latLong.lat,
                                    "longitude": dropPlaceSearchController
                                        .dropLatLng.value?.latLong.lng,
                                    "city": destinationController.city.value,
                                    "place_id":
                                        destinationController.placeId.value,
                                    "types":
                                        destinationController.types.toList(),
                                    "state": destinationController.state.value,
                                    "country":
                                        destinationController.country.value
                                  },
                                  "stopovers": [],
                                  "trip_type_details":
                                      searchCabInventoryController
                                          .globalData.value?.tripTypeDetails
                                          ?.toJson(),
                                  "paid": false,
                                  "extrasSelected":
                                      cabBookingController.selectedExtrasIds,
                                  "total_fare": cabBookingController.totalFare,
                                  "amount_to_be_collected": double.parse(
                                      cabBookingController.amountTobeCollected
                                          .toStringAsFixed(2)),
                                  "cancelled_by": null,
                                  "cancellation_reason": null,
                                  "canceltime": null,
                                  "couponCodeUsed": null,
                                  "offerUsed": null,
                                  "userType": "CUSTOMER",
                                  "timezone": await StorageServices.instance
                                      .read('timeZone'),
                                  "guest_id": null
                                },
                                "order": {
                                  "currency": currencyController
                                      .selectedCurrency.value.code,
                                  "amount": await currencyController
                                      .convertPrice(cabBookingController
                                          .totalFare), //(part payment or full paymenmt)
                                },
                                "receiptData": {
                                  "paymentType": "FULL",
                                  "countryName":
                                      currencyController.country.value,
                                  "baseCurrency": currencyController
                                      .fromCurrency.value.code,
                                  "currency": {
                                    "currencyName": currencyController
                                        .selectedCurrency.value.code,
                                    "currencyRate": currencyController
                                            .convertedRate.value ??
                                        1
                                  },
                                  "addon_charges":
                                      cabBookingController.extraFacilityCharges,
                                  "freeWaitingTime": cabBookingController
                                      .globalData
                                      .value
                                      ?.fareBreakUpDetails
                                      ?.freeWaitingTime,
                                  "waitingInterval": cabBookingController
                                      .globalData
                                      .value
                                      ?.fareBreakUpDetails
                                      ?.waitingInterval,
                                  "normalWaitingCharge": cabBookingController
                                      .globalData
                                      .value
                                      ?.fareBreakUpDetails
                                      ?.waitingCharge,
                                  "airportWaitingChargeSlab": [],
                                  "congestion_charges": 0,
                                  "extra_global_charge": 0,
                                  "fare_details": {
                                    "actual_fare":
                                        cabBookingController.actualFare,
                                    "seller_discount": 0,
                                    "base_fare": cabBookingController.baseFare,
                                    "total_driver_charges": 0,
                                    "state_tax": 0,
                                    "toll_charges": 0,
                                    "night_charges": 0,
                                    "holiday_charges": 0,
                                    "total_tax": 0,
                                    "amount_paid":
                                        await currencyController.convertPrice(
                                            cabBookingController.totalFare),
                                    "amount_to_be_collected": 0,
                                    "total_fare":
                                        cabBookingController.actualFare,
                                    "per_km_charge": cabBookingController
                                            .globalData
                                            .value
                                            ?.fareBreakUpDetails
                                            ?.perKmCharge ??
                                        0,
                                    "extra_time_fare": {
                                      "rate": cabBookingController
                                          .globalData
                                          .value
                                          ?.fareBreakUpDetails
                                          ?.waitingCharge,
                                      "applicable_time": cabBookingController
                                          .globalData
                                          .value
                                          ?.fareBreakUpDetails
                                          ?.waitingInterval
                                    },
                                    "extra_charges": {}
                                  }
                                }
                              };

                              final Map<String, dynamic> checkoutRequestData = {
                                "amount": await currencyController.convertPrice(
                                    cabBookingController.totalFare),
                                "currency": currencyController
                                    .selectedCurrency.value.code,
                                "carType": cabBookingController.globalData.value
                                    ?.fareBreakUpDetails?.vehicleCategory,
                                "description":
                                    'WTI cabs booking for mobile chauffer app',
                                "userType": "CUSTOMER",
                              };

                              if (!cabBookingController.isFormValid.value) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        "Please fill all required fields correctly."),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (cabBookingController.isFormValid.value) {
                                await globalPaymentController
                                    .verifySignup(
                                        requestData: requestData,
                                        provisionalRequestData:
                                            provisionalRequestData,
                                        checkoutRequestData:
                                            checkoutRequestData,
                                        context: context)
                                    .then((value) {
                                  GoRouter.of(context).pop();
                                });
                              }
                            }
                      : () {},
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required int index,
    required String title,
    required String amount,
  }) {
    final isSelected = selectedOption == index;
    return InkWell(
      onTap: () => setState(() => selectedOption = index),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? Colors.blue.shade700 : Colors.grey,
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildShimmerBox() {
  return Expanded(
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        height: 16,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
  );
}

void showRazorpaySkeletonLoader(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // disables tapping outside to dismiss
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false, // disables back button
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Payment Processing...',
                    style: CommonFonts.bodyText3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class DiscountCouponsCard extends StatefulWidget {
  const DiscountCouponsCard({super.key});

  @override
  State<DiscountCouponsCard> createState() => _DiscountCouponsCardState();
}

class _DiscountCouponsCardState extends State<DiscountCouponsCard> {
  String? selectedCoupon;
  final CouponController fetchCouponController = Get.put(CouponController());
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  final CabBookingController cabBookingController =
      Get.put(CabBookingController());

  void _showConfettiOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Auto-dismiss after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Full screen GIF overlay
              Positioned.fill(
                child: Image.asset(
                  'assets/images/congrat_conffeti.gif',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if GIF fails to load
                    return Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: Text(
                          '🎉 Coupon Applied!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Tap to dismiss
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  final SearchCabInventoryController searchCabInventoryController =
      Get.put(SearchCabInventoryController());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.scaffoldBgPrimary1, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discounts Coupons',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.black),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCoupon ?? 'No coupon applied',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF333333)),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Container(
                            height: 1,
                            color: Color(0xFFE8E8E8),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Opacity(
                      opacity: 0.3,
                      child: SizedBox(
                        height: 28,
                        child: TextButton(
                          onPressed: () async {
                            setState(() {
                              selectedCoupon = null;
                            });
                            cabBookingController.clearSelectedCoupon();
                            
                            // Refresh fare details after coupon removal
                            final isIndiaCountry = (cabBookingController.country?.toLowerCase() ?? '') == 'india';
                            if (isIndiaCountry && cabBookingController.lastIndiaFareRequestData != null) {
                              final payload = Map<String, dynamic>.from(cabBookingController.lastIndiaFareRequestData!);
                              if (cabBookingController.selectedExtrasIds.isNotEmpty) {
                                payload['extrasIdsArray'] =
                                    cabBookingController.selectedExtrasIds.toList(growable: false);
                              }
                              await cabBookingController.fetchIndiaFareDetails(
                                requestData: payload,
                                context: context,
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFF333333)),
                            ),
                          ),
                          child: const Text(
                            'CLEAR',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedCoupon != null) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Congratulations! Your discount has been applied successfully.',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF00C310)),
                  ),
                ],
                const SizedBox(height: 16),
                // for (final coupon in fetchCouponController.coupons)
                //   _buildCouponOption(
                //     title: coupon.codeName ?? '',
                //     subtitle: coupon.codeDescription!,
                //     selected: selectedCoupon == coupon.codeName.toString(),
                //     onTap: () async{
                //       final token = await StorageServices.instance.read('token');
                //       final Map<String, dynamic> requestData = {
                //         "userID": null,
                //         "couponID": coupon.id,
                //         "totalAmount": cabBookingController.totalFare,
                //         "sourceLocation": bookingRideController.prefilled.value,
                //         "destinationLocation": bookingRideController.prefilledDrop.value,
                //         "serviceType": null,
                //         "bankName": null,
                //         "userType": "CUSTOMER",
                //         "bookingDateTime":
                //         await StorageServices.instance.read('userDateTime'),
                //         "appliedCoupon": token != null ? 1 : 0,
                //         "payNow": cabBookingController.actualFare,
                //         "tripType": searchCabInventoryController
                //             .indiaData.value?.result?.tripType?.currentTripCode,
                //         "vehicleType":
                //         cabBookingController.indiaData.value?.inventory?.carTypes?.type ??
                //             ''
                //       };
                //       await applyCouponController.applyCoupon(
                //           requestData: requestData, context: context);
                //       setState(() {
                //         selectedCoupon = coupon.codeName.toString();
                //       });
                //
                //     },
                //   ),

                Container(
                  height: 280,
                  color: Colors.transparent,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 0),
                    itemCount: fetchCouponController.coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = fetchCouponController.coupons[index];
                      // return CouponCard(
                      //   code: coupon.codeName!,
                      //   id: coupon.id??'',
                      //   title: coupon.codeDescription!,
                      //   subtitle: coupon.codePercentage.toString()!,
                      //   imageUrl: 'https://test.wticabs.com:5001${coupon.imageUrl!}',
                      //   selectedCoupon: selectedCoupon ?? '',
                      //   onApply: () {
                      //     // Show a snackbar on apply
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       SnackBar(
                      //         content: Text('Coupon ${coupon.codeName} applied!'),
                      //       ),
                      //     );
                      //   },
                      //   onSelected: (String code) {
                      //     setState(() {
                      //       selectedCoupon = code;
                      //     });
                      //   },
                      // );
                      return CouponCardLatest(
                        id: coupon.id ?? '',
                        code: coupon.codeName!,
                        description: coupon.codeDescription ?? '',
                        codePercentage: coupon.codePercentage?.toInt() ?? 0,
                        onApply: () {
                          print("Coupon Applied!");
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponOption({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom circular checkbox
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.mainButtonBg : Colors.grey,
                      width: 2,
                    ),
                    color:
                        selected ? AppColors.mainButtonBg : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),

                // Coupon title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xFF333333))),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF727272)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 1,
          color: Color(0xFFE8E8E8),
        )
      ],
    );
  }
}

// class CouponCard extends StatefulWidget {
//   final String code;
//   final String id;
//   final String title;
//   final String subtitle;
//   final String imageUrl;
//   String selectedCoupon;
//   final VoidCallback onApply;
//   final ValueChanged<String> onSelected;
//
//   CouponCard({
//     Key? key,
//     required this.code,
//     required this.title,
//     required this.subtitle,
//     required this.imageUrl,
//     required this.onApply,
//     required this.selectedCoupon,
//     required this.onSelected, required this.id,
//   }) : super(key: key);
//
//   @override
//   State<CouponCard> createState() => _CouponCardState();
// }
//
// class _CouponCardState extends State<CouponCard> {
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       splashColor: Colors.transparent,
//       onTap: () async{
//         final token = await StorageServices.instance.read('token');
//         final Map<String, dynamic> requestData = {
//           "userID": null,
//           "couponID": widget.id,
//           "totalAmount": cabBookingController.totalFare,
//           "sourceLocation": bookingRideController.prefilled.value,
//           "destinationLocation": bookingRideController.prefilledDrop.value,
//           "serviceType": null,
//           "bankName": null,
//           "userType": "CUSTOMER",
//           "bookingDateTime":
//           await StorageServices.instance.read('userDateTime'),
//           "appliedCoupon": token != null ? 1 : 0,
//           "payNow": cabBookingController.actualFare,
//           "tripType": searchCabInventoryController
//               .indiaData.value?.result?.tripType?.currentTripCode,
//           "vehicleType":
//           cabBookingController.indiaData.value?.inventory?.carTypes?.type ??
//               ''
//         };
//         await applyCouponController.applyCoupon(
//             requestData: requestData, context: context);
//         widget.onSelected(widget.code);
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         color: Colors.transparent,
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Card with gradient and content
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: widget.selectedCoupon == widget.code
//                       ? const LinearGradient(
//                     colors: [Color(0xFF92FF8A), Color(0xFFA0EEFF)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   )
//                       : null,
//                   color: widget.selectedCoupon == widget.code ? null : Colors.white,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(12),
//                     bottomLeft: Radius.circular(12),
//                   ),
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Coupon image
//                     Padding(
//                       padding: EdgeInsets.only(left: 16, top: 16),
//                       child: ClipRRect(
//                         borderRadius: const BorderRadius.all(Radius.circular(12)),
//                         child: Image.asset(
//                           'assets/images/coupon_image.png',
//                           width: 64,
//                           height: 64,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//
//                     // Coupon content
//                     Expanded(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.code,
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                                 color: Color(0xFF002CC0),
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               widget.title,
//                               style: const TextStyle(
//                                 color: Color(0xFF363636),
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 12,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                               maxLines: 1,
//                             ),
//
//                             const SizedBox(height: 2),
//                             Text('Save ₹25 on all transactions above ₹250.', style: TextStyle(
//                                 fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF676767)
//
//                             ), overflow: TextOverflow.ellipsis,
//                               maxLines: 1,),
//                             const SizedBox(height: 2),
//                             Text(
//                               '*Terms & conditions applicable',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w400,
//                                 color: Color(0xFFE99F00),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
//                       margin: EdgeInsets.only(top: 16, left: 16),
//                       decoration: BoxDecoration(
//                         color: widget.selectedCoupon == widget.code ? Color(0xFF00C400) :  Color(0xFFBBBBBB),
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                       child: Text(
//                         widget.selectedCoupon == widget.code ? 'Applied' : 'Apply',
//                         style: const TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.white,
//                         ),
//                       ),
//                     )
//
//
//                     // Apply button
//                   ],
//                 ),
//               ),
//             ),
//
//             // Right cut image
//             Image.asset(
//               widget.selectedCoupon == widget.code ? 'assets/images/coupon_gradient.png' : 'assets/images/coupon_white_cut.png',
//               width: 30,
//               height: 95,
//               fit: BoxFit.fill,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

Widget buildShimmer() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 96,
                height: 66,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(height: 12, width: 40, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 40, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 60, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 16, height: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    ),
  );
}

// 🔹 Compact inclusion widget
Widget _buildInclusionItem({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8), // 🔹 less vertical space
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 18), // 🔹 smaller icon
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
        )
      ],
    ),
  );
}

Widget _buildGlobalInclusionItem({
  required IconData icon,
  required String? title,
  required String subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8), // 🔹 less vertical space
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 18), // 🔹 smaller icon
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title != null
                  ? Text(title ?? '',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 12))
                  : SizedBox(),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
        )
      ],
    ),
  );
}

// 🔹 Compact exclusion widget
Widget _buildExclusionItem({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8), // 🔹 less vertical space
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.redAccent, size: 18), // 🔹 smaller icon
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
        )
      ],
    ),
  );
}

Widget _buildGlobalExclusionItem({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8), // 🔹 less vertical space
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.redAccent, size: 18), // 🔹 smaller icon
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
        )
      ],
    ),
  );
}

class CouponCardLatest extends StatefulWidget {
  final String id;
  final String code;
  final String description;
  final int codePercentage;
  final VoidCallback onApply;

  const CouponCardLatest({
    Key? key,
    required this.id,
    required this.code,
    required this.description,
    required this.codePercentage,
    required this.onApply,
  }) : super(key: key);

  @override
  State<CouponCardLatest> createState() => _CouponCardLatestState();
}

class _CouponCardLatestState extends State<CouponCardLatest> {
  final CabBookingController cabBookingController =
      Get.put(CabBookingController());

  void _showConfettiOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Auto-dismiss after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Full screen GIF overlay
              Positioned.fill(
                child: Image.asset(
                  'assets/images/congrat_conffeti.gif',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if GIF fails to load
                    return Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: Text(
                          '🎉 Coupon Applied!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Tap to dismiss
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(color: Colors.transparent),
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
    return Obx(() {
      final isApplied =
          cabBookingController.selectedCouponId.value == widget.id;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isApplied ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isApplied ? Colors.green : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Discount strip
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              width: 40,
              height: 97,
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  "${widget.codePercentage.toString()}% OFF",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.code,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          backgroundColor: isApplied
                              ? Colors.red.shade100
                              : Colors.grey[200],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () async {
                          final bool wasApplying = !isApplied; // Track if we're applying (not removing)
                          
                          if (isApplied) {
                            cabBookingController.clearSelectedCoupon();
                          } else {
                            cabBookingController.setSelectedCoupon(
                              couponId: widget.id,
                              couponCode: widget.code,
                            );
                            widget.onApply();
                          }
                          
                          // Refresh fare details after coupon selection/unselection
                          final isIndiaCountry = (cabBookingController.country?.toLowerCase() ?? '') == 'india';
                          if (isIndiaCountry && cabBookingController.lastIndiaFareRequestData != null) {
                            final payload = Map<String, dynamic>.from(cabBookingController.lastIndiaFareRequestData!);
                            if (cabBookingController.selectedExtrasIds.isNotEmpty) {
                              payload['extrasIdsArray'] =
                                  cabBookingController.selectedExtrasIds.toList(growable: false);
                            }
                            await cabBookingController.fetchIndiaFareDetails(
                              requestData: payload,
                              context: context,
                            );
                            
                            // Show confetti overlay after successful coupon application
                            if (wasApplying && cabBookingController.indiaFareDetails.value != null) {
                              _showConfettiOverlay();
                            }
                          }
                        },
                        child: Text(
                          isApplied ? "Remove Code" : "Apply Code",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}
