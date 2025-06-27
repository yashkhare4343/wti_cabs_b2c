import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../../api/api_services.dart';
import '../../model/rental_response/fetch_package_response.dart';

class FetchPackageController extends GetxController {
  Rx<PackageResponse?> packageModel = Rx<PackageResponse?>(null);
  RxBool isLoading = false.obs;

  Future<void> fetchPackages() async {
    isLoading.value = true;
    try {
      final result = await ApiService().getRequestNew<PackageResponse>(
        'inventory/getAllPackages',
        PackageResponse.fromJson,
      );
      packageModel.value = result;
    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
