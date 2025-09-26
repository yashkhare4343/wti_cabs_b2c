import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/model/self_drive/self_drive_booking_details/self_drive_booking_details_response.dart';

import '../../../../screens/self_drive/self_drive_all_inventory/self_drive_all_inventory.dart';
import '../search_inventory_sd_controller/search_inventory_sd_controller.dart';

class FetchSdBookingDetailsController extends GetxController {
  Rx<SelfDriveBookingDetailsResponse?> getAllBookingData =
      Rx<SelfDriveBookingDetailsResponse?>(null);
  RxBool isLoading = false.obs;
  RxBool cdw = false.obs;
  RxBool pai = false.obs;
  RxBool freeDeposit = true.obs;
  RxDouble delivery_charge = 0.0.obs;
  RxDouble collection_charges = 0.0.obs;
  RxBool isFreePickup = false.obs;
  RxBool isFreeDrop = false.obs;
  RxBool isSameLocation = true.obs;

  Future<void> fetchBookingDetails(String vehicleId, bool isHomePage) async {
    final SearchInventorySdController searchInventorySdController =
        Get.find<SearchInventorySdController>();
    isLoading.value = true;
    try {
      // Base query
      String query = 'inventory/getSingleInventory'
          '?source={"_id":"${searchInventorySdController.cityId.value}","city":"${searchInventorySdController.city.value}","countryId":"68835bbacd2ef39904163d27","countryCode":"${searchInventorySdController.countryCode.value}","timezone":"Asia/Dubai"}'
          '&vehicle_id=$vehicleId'
          '&pickup={"date":"${searchInventorySdController.fromDate.value.day}/${searchInventorySdController.fromDate.value.month}/${searchInventorySdController.fromDate.value.year}","time":"${searchInventorySdController.fromTime.value.hour.toString().padLeft(2, '0')}:${searchInventorySdController.fromTime.value.minute.toString().padLeft(2, '0')}"}'
          '&drop={"date":"${searchInventorySdController.toDate.value.day}/${searchInventorySdController.toDate.value.month}/${searchInventorySdController.toDate.value.year}","time":"${searchInventorySdController.toTime.value.hour.toString().padLeft(2, '0')}:${searchInventorySdController.toTime.value.minute.toString().padLeft(2, '0')}"}'
          '&is_home_page=$isHomePage'
          '&plan_type=${searchInventorySdController.selectedIndex.value == 1 ? 2 : 1}'
          '&timeZone=Asia/Calcutta';

      // ✅ Conditionally add duration_months
      if (searchInventorySdController.selectedIndex.value == 1) {
        query +=
            '&duration_months=${searchInventorySdController.selectedMonth.value}';
      }

        if (cdw.value == true) {
          query += '&cdw=${true}';
        }
      if (pai.value == true) {
        query += '&pai=${true}';
      }
      if (freeDeposit.value == true) {
        query += '&security_deposit=${true}';
      }
//  Delivery charges
      if (isFreePickup.value) {
        query += '&delivery_charges=0';
      } else {
        query += '&delivery_charges=${delivery_charge.value}';
      }

//  Collection charges
      if (isFreeDrop.value) {
        query += '&collection_charges=0';
      }
      else if (isSameLocation.value) {
        // If drop = pickup, treat collection as delivery
        query += '&collection_charges=${delivery_charge.value}';
      }
      else {
        // Explicitly use collection_charges if provided
        query += '&collection_charges=${collection_charges.value}';
      }




      final result = await SelfDriveApiService()
          .getRequestNew<SelfDriveBookingDetailsResponse>(
        query,
        SelfDriveBookingDetailsResponse.fromJson,
      );

      getAllBookingData.value = result;
    } catch (e) {
      print("Failed to fetch booking details: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
