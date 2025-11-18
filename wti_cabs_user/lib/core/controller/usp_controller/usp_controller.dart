import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/model/usp/usp_response.dart';

import '../../api/api_services.dart';

class UspController extends GetxController {
  Rx<UspResponse?> uspResponse = Rx<UspResponse?>(null);
  RxBool isLoading = false.obs;
  RxInt gatewayCode = 0.obs;

  Future<void> fetchUsps({bool forceRefresh = false}) async {
    // 👇 Guard: only fetch if we don't already have data (unless force refresh)
    if (!forceRefresh && 
        uspResponse.value?.data != null &&
        uspResponse.value!.data!.isNotEmpty) {
      return;
    }

    // ✅ Prevent multiple simultaneous fetches
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final result = await ApiService().getRequestNew<UspResponse>(
        'usp/getOurUSP',
        UspResponse.fromJson,
      );
      uspResponse.value = result;
      print('✅ USP data fetched (${uspResponse.value?.data?.length ?? 0} items)');

    } catch (e) {
      print("❌ Failed to fetch USP: $e");
      // ✅ Don't set to null on error, keep existing data if available
    } finally {
      isLoading.value = false;
    }
  }
}



