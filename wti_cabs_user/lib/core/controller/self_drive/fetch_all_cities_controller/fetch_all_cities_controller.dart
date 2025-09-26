import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/model/booking_reservation/booking_reservation_response.dart';

import '../../../api/api_services.dart';
import '../../../model/self_drive/get_all_cities/get_all_cities_response.dart';


class FetchAllCitiesController extends GetxController {
  Rx<GetAllCitiesResponse?> getAllCitiesResponse = Rx<GetAllCitiesResponse?>(null);
  RxBool isLoading = false.obs;

  Future<void> fetchAllCities() async {
    isLoading.value = true;
    try {
      final result = await SelfDriveApiService().getRequestNew<GetAllCitiesResponse>(
        'car-rental-locations/getAllCarRentalLocationsOnCountry/AE',
        GetAllCitiesResponse.fromJson,
      );
      getAllCitiesResponse.value = result;
    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }
}