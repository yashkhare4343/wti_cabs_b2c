import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/common_widget/loader/full_screen_gif/full_screen_gif.dart';
import 'package:wti_cabs_user/core/controller/coupons/apply_coupon_controller.dart';
import 'package:wti_cabs_user/core/model/cab_booking/india_cab_booking.dart';
import 'package:wti_cabs_user/core/model/cab_booking/global_cab_booking.dart';
import 'package:wti_cabs_user/common_widget/loader/popup_loader.dart';
import 'package:wti_cabs_user/core/api/api_services.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

import '../../model/inventory/global_response.dart';
import '../../route_management/app_routes.dart';

class CabBookingController extends GetxController {
  Rx<IndiaCabBooking?> indiaData = Rx<IndiaCabBooking?>(null);
  Rx<GlobalBookingFlat?> globalData = Rx<GlobalBookingFlat?>(null);
  final ApplyCouponController applyCouponController = Get.put(ApplyCouponController());
  RxBool isLoading = false.obs;

  // NEW: Extra selected facilities (label -> price)
  RxMap<String, double> selectedExtras = <String, double>{}.obs;

  // Assume country is stored separately
  String? country;

              double get baseFare {
                final value = isIndia
                    ? (indiaData.value?.inventory?.carTypes?.fareDetails?.baseFare?.toDouble() ?? 0.0)
                    : (globalData.value?.totalFare ?? 0.0);
                debugPrint('baseFare: $value');
                return value;
              }

  double get nightCharges {
    final included = indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.nightCharges?.isIncludedInGrandTotal == true;
    final amount = included ? (indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.nightCharges?.amount?.toDouble() ?? 0.0) : 0.0;
    debugPrint('nightCharges (included: $included): $amount');
    return isIndia ? amount : 0.0;
  }

  double get tollCharges {
    final included = indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.tollCharges?.isIncludedInGrandTotal == true;
    final amount = included ? (indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.tollCharges?.amount?.toDouble() ?? 0.0) : 0.0;
    debugPrint('tollCharges (included: $included): $amount');
    return isIndia ? amount : 0.0;
  }

  double get waitingCharges {
    final included = indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.waitingCharges?.isIncludedInGrandTotal == true;
    final amount = included ? (indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.waitingCharges?.amount?.toDouble() ?? 0.0) : 0.0;
    debugPrint('waitingCharges (included: $included): $amount');
    return isIndia ? amount : 0.0;
  }

  double get parkingCharges {
    final included = indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.parkingCharges?.isIncludedInGrandTotal == true;
    final amount = included ? (indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.parkingCharges?.amount?.toDouble() ?? 0.0) : 0.0;
    debugPrint('parkingCharges (included: $included): $amount');
    return isIndia ? amount : 0.0;
  }

  double get stateTax {
    final included = indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.stateTax?.isIncludedInGrandTotal == true;
    final amount = included ? (indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.stateTax?.amount?.toDouble() ?? 0.0) : 0.0;
    debugPrint('stateTax (included: $included): $amount');
    return isIndia ? amount : 0.0;
  }

  double get driverCharge {
    final value = isIndia
        ? (indiaData.value?.inventory?.carTypes?.fareDetails?.totalDriverCharges?.toDouble() ?? 0.0)
        : 0.0;
    debugPrint('driverCharge: $value');
    return value;
  }

  double get extraFacilityCharges {
    final value = selectedExtras.values.fold(0.0, (sum, item) => sum + item);
    debugPrint('extraFacilityCharges: $value');
    return value;
  }


  double get actualFare {
    final subtotal = baseFare +
        nightCharges +
        tollCharges +
        waitingCharges +
        parkingCharges +
        stateTax +
        driverCharge+
        extraFacilityCharges;

    debugPrint('actualFare subtotal: $subtotal');
    return subtotal;
  }

  double get totalFare {
    double subtotal;

    if (applyCouponController.isCouponApplied == false) {
      // No coupon → just sum all charges
      subtotal = baseFare +
          nightCharges +
          tollCharges +
          waitingCharges +
          parkingCharges +
          stateTax +
          driverCharge +
          extraFacilityCharges;
      debugPrint('Coupon not applied. Subtotal: $subtotal');
    } else {

      // Coupon applied → take discounted amount (without tax from API)
      final discountedFare =
          applyCouponController.applyCouponResponse.value?.newTotalAmount ??
              baseFare +
                  nightCharges +
                  tollCharges +
                  waitingCharges +
                  parkingCharges +
                  stateTax +
                  driverCharge +
                  extraFacilityCharges;

      subtotal = discountedFare.toDouble();

      debugPrint('Coupon applied. Discounted subtotal (before tax): $subtotal');
    }

    // Add tax locally (only once, based on subtotal)
    final tax = isIndia ? subtotal * 0.05 : 0;
    final total = subtotal + tax;

    debugPrint('Tax (5% if India): $tax');
    debugPrint('Total Fare: $total');

    return total;
  }

  double get taxCharge{
    double subtotal;

    if (applyCouponController.isCouponApplied == false) {
      // No coupon → just sum all charges
      subtotal = baseFare +
          nightCharges +
          tollCharges +
          waitingCharges +
          parkingCharges +
          stateTax +
          driverCharge +
          extraFacilityCharges;
      debugPrint('Coupon not applied. Subtotal: $subtotal');
    } else {
      // Coupon applied → take discounted amount (without tax from API)
      final discountedFare =
          applyCouponController.applyCouponResponse.value?.newTotalAmount ??
              baseFare;

      subtotal = discountedFare +
          nightCharges +
          tollCharges +
          waitingCharges +
          parkingCharges +
          stateTax +
          driverCharge +
          extraFacilityCharges;

      debugPrint('Coupon applied. Discounted subtotal (before tax): $subtotal');
    }

    final tax = isIndia ? subtotal * 0.05 : 0;
    print('yash tAX : $tax');

    return tax.toDouble();
  }

  double get partFare {
    final value = totalFare * 0.20;
    debugPrint('Part fare (20% of totalFare): $value');
    return value;
  }

  double get amountTobeCollected {
    final value = totalFare - partFare;
    debugPrint('Amount to be collected (totalFare - partFare): $value');
    return value;
  }



  bool get isIndia => (country?.toLowerCase() ?? '') == 'india';

  void toggleExtraFacility(String label, double amount, bool isSelected) {
    if (isSelected) {
      selectedExtras[label] = amount;
    } else {
      selectedExtras.remove(label);
    }
  }

  // store choose extras id in array
  RxList<String> selectedExtrasIds = <String>[].obs;

  void toggleExtraId(String id, bool isSelected) {
    if (isSelected) {
      if (!selectedExtrasIds.contains(id)) {
        selectedExtrasIds.add(id);
      }
    } else {
      selectedExtrasIds.remove(id);
    }
    print("🆔 Selected Extras: $selectedExtrasIds");
  }

  // Optional: clear all
  void clearSelectedExtras() {
    selectedExtrasIds.clear();
  }

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  var isFormValid = false.obs;

  void validateForm() {
    final isValid = formKey.currentState?.validate() ?? false;
    isFormValid.value = isValid;
  }

  void showAllChargesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true, // ✅ makes sheet scrollable if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
        builder: (_) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, controller) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  controller: controller,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Text(
                      "Fare Breakdown",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // ✅ Only wrap where reactive values are used
                    Obx(() => _buildRow("Base Fare", "₹${baseFare.toStringAsFixed(2)}")),
                    Obx(() => _buildRow("Night Charges", "₹${nightCharges.toStringAsFixed(2)}")),
                    Obx(() => _buildRow("Toll Charges", "₹${tollCharges.toStringAsFixed(2)}")),
                    Obx(() => _buildRow("Waiting Charges", "₹${waitingCharges.toStringAsFixed(2)}")),
                    Obx(() => _buildRow("Parking Charges", "₹${parkingCharges.toStringAsFixed(2)}")),
                    Obx(() => _buildRow("State Tax", "₹${stateTax.toStringAsFixed(2)}")),
                    Obx(() => _buildRow("Driver Charge", "₹${driverCharge.toStringAsFixed(2)}")),
                    Obx(() => _buildRow("Extras", "₹${extraFacilityCharges.toStringAsFixed(2)}")),

                    const Divider(thickness: 1, height: 24),

                    Obx(() => _buildRow("Subtotal", "₹${actualFare.toStringAsFixed(2)}", isBold: true)),
                    Obx(() => _buildRow("Tax include (5%)", "₹${taxCharge.toStringAsFixed(2)}", isBold: true)),

                    Obx(() {
                      if (applyCouponController.isCouponApplied.value) {
                        return _buildRow(
                          "Coupon Applied",
                          "-₹${applyCouponController.applyCouponResponse.value?.discountAmount ?? 0}",
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    Obx(() => _buildRow("Total Fare", "₹${totalFare.toStringAsFixed(2)}",
                        isBold: true, highlight: true)),

                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        }
    );
  }

  /// Helper row widget
  Widget _buildRow(String label, String value,
      {bool isBold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w400)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
              color: highlight ? AppColors.mainButtonBg : Colors.black,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> fetchBookingData({
    required String country,
    required Map<String, dynamic> requestData,
    required BuildContext context,
    bool isSecondPage = false,
  }) async {
    isLoading.value = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FullScreenGifLoader(),
    );

    print('📤 Booking request: $requestData');

    try {
      if (country.toLowerCase() == 'india') {
        final response = await ApiService().postRequest(
          'globalSearch/getFinalGlobalVehicleData',
          requestData,
          context,
        );

        final result = response['result'];
        if (result != null && result is Map<String, dynamic>) {
          indiaData.value = IndiaCabBooking.fromJson(result);
          print('✅ India booking response: ${indiaData.value?.toJson()}');
        } else {
          print('⚠️ India: Response["result"] is null or invalid.');
        }

        globalData.value = null;
        if (context.mounted) {
          GoRouter.of(context).push(AppRoutes.bookingDetailsFinal);
        }
      } else {
        final response = await ApiService().postRequest(
          'globalSearch/getFinalGlobalVehicleData',
          requestData,
          context,
        );

        // Handle global booking with optional tripTypeDetails
        globalData.value = GlobalBookingFlat.fromJson({
          'result': response['result'] ?? {},
          'tripTypeDetails': response['tripTypeDetails'],
        });

        if (context.mounted) {
          GoRouter.of(context).push(AppRoutes.bookingDetailsFinal);
        }
        print('✅ Global booking result count: ${globalData.value?.vehicleDetails}');
        print('📌 tripTypeDetails: ${globalData.value?.tripTypeDetails?.tripType ?? "N/A"}');
            }
    } catch (e) {
      print("❌ Error fetching booking data: $e");

      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      Get.snackbar("Error", "Something went wrong, please try again.",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      isLoading.value = false;
    }
  }
}
