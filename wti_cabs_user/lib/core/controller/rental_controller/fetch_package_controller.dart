import 'package:get/get.dart';
import '../../api/api_services.dart';
import '../../model/rental_response/fetch_package_response.dart';

class FetchPackageController extends GetxController {
  Rx<PackageResponse?> packageModel = Rx<PackageResponse?>(null);
  RxBool isLoading = false.obs;
  RxInt selectedHours = 0.obs;
  RxInt selectedKms = 0.obs;


  // ✅ Global selected package
  RxString selectedPackage = ''.obs;

  Future<void> fetchPackages() async {
    isLoading.value = true;
    try {
      final result = await ApiService().getRequestNew<PackageResponse>(
        'inventory/getAllPackages',
        PackageResponse.fromJson,
      );

      if (result != null && result.data.isNotEmpty) {
        // ✅ sort list by hours
        result.data.sort((a, b) => a.hours?.compareTo(b.hours?.toInt()??0)??0);

        packageModel.value = result;

        // ✅ preselect the smallest package (after sorting)
        selectedPackage.value =
        '${result.data[0].hours} hrs, ${result.data[0].kilometers} kms';
      }
    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ method to update selection globally
  void updateSelectedPackage(String value) {
    selectedPackage.value = value;
  }
}
