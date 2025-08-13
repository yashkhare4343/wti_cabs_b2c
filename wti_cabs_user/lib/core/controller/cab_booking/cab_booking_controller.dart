import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/coupons/apply_coupon_controller.dart';
import 'package:wti_cabs_user/core/model/cab_booking/india_cab_booking.dart';
import 'package:wti_cabs_user/core/model/cab_booking/global_cab_booking.dart';
import 'package:wti_cabs_user/common_widget/loader/popup_loader.dart';
import 'package:wti_cabs_user/core/api/api_services.dart';

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
      final couponAmount = applyCouponController.applyCouponResponse.value?.newTotalAmount ?? 0;
      subtotal = couponAmount.toDouble() + extraFacilityCharges;
      debugPrint('Coupon applied. New total after coupon: $couponAmount, with extras: $subtotal');
    }

    final total = isIndia ?  subtotal + (subtotal * 0.05) : subtotal;
    debugPrint('Total Fare (with 5% tax if India): $total');
    return total;
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
    isFormValid.value = formKey.currentState?.validate() ?? false;
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
      builder: (_) => const PopupLoader(message: 'Fetching Booking Data',),
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
