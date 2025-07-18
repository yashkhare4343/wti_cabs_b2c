import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/apply_coupon/apply_coupon.dart';
import 'package:wti_cabs_user/core/model/auth/register/register_response.dart';
import '../../api/api_services.dart';

class ApplyCouponController extends GetxController {
  Rx<ApplyCouponResponse?> applyCouponResponse = Rx<ApplyCouponResponse?>(null);
  RxBool isLoading = false.obs;
  RxBool isCouponApplied = false.obs;

  void showCouponAppliedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent dismissing by tapping outside
      builder: (context) {
        Future.delayed(Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // auto-close after 3 seconds
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Fetch booking data based on the given country and request body
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
      print('print apply coupon data : ${ApplyCouponResponse.fromJson(applyCouponResponse.value?.toJson()??{})}');
      showCouponAppliedDialog(context, 'Woohoo! ₹${applyCouponResponse.value?.discountAmount} off added. Have a great trip!');

    } finally {
      isLoading.value = false;
    }
  }


}
