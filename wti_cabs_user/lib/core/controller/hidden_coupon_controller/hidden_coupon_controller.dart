import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/controller/cab_booking/cab_booking_controller.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import 'package:wti_cabs_user/core/model/auth/register/register_response.dart';
import 'package:wti_cabs_user/core/model/hidden_coupon_response/hidden_coupon_response.dart';
import '../../api/api_services.dart';
import '../../services/storage_services.dart';
import '../booking_ride_controller.dart';
import '../inventory/search_cab_inventory_controller.dart';

class HiddenCouponController extends GetxController {
  Rx<HiddenCouponResponse?> hiddenCouponResponse = Rx<HiddenCouponResponse?>(null);
  final CabBookingController cabBookingController =
  Get.isRegistered<CabBookingController>()
      ? Get.find<CabBookingController>()
      : Get.put(CabBookingController());  final BookingRideController bookingRideController =
  Get.isRegistered<BookingRideController>()
      ? Get.find<BookingRideController>()
      : Get.put(BookingRideController());
  final SearchCabInventoryController searchCabInventoryController =
  Get.isRegistered<SearchCabInventoryController>()
      ? Get.find<SearchCabInventoryController>()
      : Get.put(SearchCabInventoryController());
  RxBool isLoading = false.obs;
  RxBool? isHiddenCouponSuccess = false.obs;

  /// Fetch booking data based on the given country and request body
  Future<void> verifyHiddenCoupon({
    required final Map<String, dynamic> requestData,
    required BuildContext context,
  }) async {

    isLoading.value = true;
    try {
      final response = await ApiService().postRequestNew<HiddenCouponResponse>(
        'couponCodes/searchCouponByCode',
        requestData,
        HiddenCouponResponse.fromJson,
        context,
      );
      hiddenCouponResponse.value = response;
      cabBookingController.setSelectedCoupon(
        couponId: hiddenCouponResponse.value?.data?.id ?? '',
        couponCode: hiddenCouponResponse.value?.data?.codeName,
      );


      // Call applyCoupon API to validate and show success dialog
      try {
        final token = await StorageServices.instance.read('token');
        final Map<String, dynamic> requestData = {
          "userID": null,
          "couponID": hiddenCouponResponse.value?.data?.id,
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
        isHiddenCouponSuccess?.value = true;

      } catch (e) {
        debugPrint('Error applying coupon: $e');
        isHiddenCouponSuccess?.value = false;
        // If API fails, still allow coupon selection but don't show dialog
      }




    }
    finally {
      isLoading.value = false;
    }
  }

}
