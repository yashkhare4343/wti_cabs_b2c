import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/apply_coupon/apply_coupon.dart';
import 'package:wti_cabs_user/core/model/auth/register/register_response.dart';
import '../../api/api_services.dart';

class ApplyCouponController extends GetxController {
  Rx<ApplyCouponResponse?> applyCouponResponse = Rx<ApplyCouponResponse?>(null);
  RxBool isLoading = false.obs;
  RxBool isCouponApplied = false.obs;
  RxnString selectedCouponId = RxnString();

  /// Keep track of discount
  RxDouble discountAmount = 0.0.obs;

  void removeCoupon() {
    selectedCouponId.value = null;
    discountAmount.value = 0.0;
    isCouponApplied.value = false;
    applyCouponResponse.value = null;
  }

  void showCouponAppliedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/coupon_2.gif',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> applyCoupon({
    required final Map<String, dynamic> requestData,
    required BuildContext context,
  }) async {
    isLoading.value = true;
    try {
      final response = await ApiService().postRequestNew<ApplyCouponResponse>(
        'couponCodes/couponFinalValidation',
        requestData,
        ApplyCouponResponse.fromJson,
        context,
      );
      applyCouponResponse.value = response;
      isCouponApplied.value = true;

      /// update discount amount
      discountAmount.value = response.discountAmount?.toDouble() ?? 0.0;

      showCouponAppliedDialog(
        context,
        'Woohoo! ₹${discountAmount.value} off added. Have a great trip!',
      );

    } finally {
      isLoading.value = false;
    }
  }

  /// Final fare after applying discount
  double calculateFinalFare({
    required double baseFare,
    required double tax,
  }) {
    final total = baseFare + tax;
    final finalFare = total - discountAmount.value;
    return finalFare > 0 ? finalFare : 0.0; // safeguard
  }
}
