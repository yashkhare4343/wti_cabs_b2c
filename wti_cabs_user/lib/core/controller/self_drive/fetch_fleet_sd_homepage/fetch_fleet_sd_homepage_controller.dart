import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/model/booking_reservation/booking_reservation_response.dart';

import '../../../api/api_services.dart';
import '../../../model/self_drive/fleet_self_drive_home/fleet_self_drive_home.dart';
import '../../../model/self_drive/get_all_cities/get_all_cities_response.dart';


class FetchAllFleetsController extends GetxController {
  Rx<FleetResponse?> getAllFleetResponse = Rx<FleetResponse?>(null);
  RxBool isLoading = false.obs;

  Future<void> fetchAllFleets() async {
    isLoading.value = true;
    try {
      final result = await SelfDriveApiService().getRequestNew<FleetResponse>(
        'inventory/getAllVehicleClasses',
        FleetResponse.fromJson,
      );
      getAllFleetResponse.value = result;
    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }
}