import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/api_services.dart';
import 'package:wti_cabs_user/core/controller/choose_drop/choose_drop_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/inventory/search_cab_inventory_controller.dart';

import '../../model/fetch_coupon/fetch_coupon_response.dart';

class CouponController extends GetxController {
  RxList<CouponData> coupons = <CouponData>[].obs;
  RxBool isLoading = false.obs;
  final SearchCabInventoryController searchCabInventoryController = Get.put(SearchCabInventoryController());
  final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController = Get.put(DropPlaceSearchController());

  Future<void> fetchCoupons(
    BuildContext context, {
    required String vehicleType,
    String? tripCode,
    String userId = '',
    String role = 'CUSTOMER',
    String applicationType = 'APP',
  }) async {
    isLoading.value = true;
    try {
      // Ensure backend never receives "null" (string) for tripCode.
      // If India booking API provides empty/missing tripCode, we must send "".
      final normalizedTripCode = ((tripCode ?? '').trim().toLowerCase() == 'null')
          ? ''
          : (tripCode ?? '').trim();

      final response = await ApiService().postRequestNew<FetchCouponResponse>(
        'couponCodes/getGlobalCouponCodes',
        {
          "userID": userId,
          "role": role,
          "applicationType": applicationType,
          "vehicleType": vehicleType.trim().toLowerCase(),
          "sourceCity": placeSearchController.getPlacesLatLng.value?.city.toString() ?? '',
          "destinationCity": dropPlaceSearchController.dropLatLng.value?.city.toString() ?? '',
          "tripCode": searchCabInventoryController.indiaData.value?.result?.tripType?.currentTripCode,
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
