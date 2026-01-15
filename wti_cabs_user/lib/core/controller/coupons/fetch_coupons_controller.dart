import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/api_services.dart';

import '../../model/fetch_coupon/fetch_coupon_response.dart';

class CouponController extends GetxController {
  RxList<CouponData> coupons = <CouponData>[].obs;
  RxBool isLoading = false.obs;

  Future<void> fetchCoupons(
    BuildContext context, {
    required String vehicleType,
    String userId = '',
    String role = 'CUSTOMER',
    String applicationType = 'APP',
  }) async {
    isLoading.value = true;
    try {
      final response = await ApiService().postRequestNew<FetchCouponResponse>(
        'couponCodes/getGlobalCouponCodes',
        {
          "userID": userId,
          "role": role,
          "applicationType": applicationType,
          "vehicleType": vehicleType.trim().toLowerCase(),
        },
        (json) => FetchCouponResponse.fromJson(json),
        context,
      );

      if (response?.couponCodesFetched == true && response?.data != null) {
        coupons.value = response?.data ?? [];
      } else {
        coupons.clear();
      }
    } catch (e) {
      debugPrint('Coupon fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
