import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/model/usp/usp_response.dart';

import '../../api/api_services.dart';

class UspController extends GetxController {
  Rx<UspResponse?> uspResponse = Rx<UspResponse?>(null);
  RxBool isLoading = false.obs;
  RxInt gatewayCode = 0.obs;

  Future<void> fetchUsps() async {
    isLoading.value = true;
    try {
      final result = await ApiService().getRequestNew<UspResponse>(
        'usp/getOurUSP',
        UspResponse.fromJson,
      );
      uspResponse.value = result;
      print('yash usp response body : ${uspResponse.value}');

    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
