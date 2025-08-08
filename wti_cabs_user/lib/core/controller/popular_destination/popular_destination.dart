import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/model/usp/usp_response.dart';

import '../../api/api_services.dart';
import '../../model/popular_destination/popular_destination_response.dart';
import '../../services/storage_services.dart';

class PopularDestinationController extends GetxController {
  Rx<PopularResponse?> popularResponse = Rx<PopularResponse?>(null);
  RxBool isLoading = false.obs;

  Future<void> fetchPopularDestinations() async {
    isLoading.value = true;
    try {
      final result = await ApiService().getRequestNew<PopularResponse>(
        'popularCityRoute/mostSearchesApi/india?userObjID=${await StorageServices.instance.read('userObjId')}',
        PopularResponse.fromJson,
      );
      popularResponse.value = result;

    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
