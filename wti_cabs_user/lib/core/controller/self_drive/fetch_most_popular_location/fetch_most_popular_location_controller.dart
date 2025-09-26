import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/model/booking_reservation/booking_reservation_response.dart';
import 'package:wti_cabs_user/core/model/self_drive/service_hub_response/service_hub_response.dart';

import '../../../api/api_services.dart';
import '../../../model/self_drive/get_all_cities/get_all_cities_response.dart';
import '../../../model/self_drive/self_drive_most_popular_location/self_drive_most_popular_location.dart';
import '../search_inventory_sd_controller/search_inventory_sd_controller.dart';


class FetchMostPopularLocationController extends GetxController {
  Rx<SelfDriveMostPopularLocationResponse?> mostPopularLocationResponse = Rx<SelfDriveMostPopularLocationResponse?>(null);
  RxBool isLoading = false.obs;
  final SearchInventorySdController searchInventorySdController =
  Get.put(SearchInventorySdController());

  Future<void> fetchMostPopularLocation() async {
    isLoading.value = true;
    try {
      final result = await SelfDriveApiService().getRequestNew<SelfDriveMostPopularLocationResponse>(
        'car-rental-locations/mostPopularLocationsOnCountry/AE/${searchInventorySdController.city.value.toLowerCase()}',
        SelfDriveMostPopularLocationResponse.fromJson,
      );
      mostPopularLocationResponse.value = result;
    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }
}