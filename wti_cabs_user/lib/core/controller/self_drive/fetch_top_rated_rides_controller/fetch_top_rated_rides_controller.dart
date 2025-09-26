import 'package:get/get.dart';

import '../../../api/self_drive_api_services.dart';
import '../../../model/self_drive/top_rated_rides_model/top_rated_rides_response.dart';

class FetchTopRatedRidesController extends GetxController {
  Rx<TopRatedRidesResponse?> getAllTopRidesResponse = Rx<TopRatedRidesResponse?>(null);
  RxBool isLoading = false.obs;

  Future<void> fetchAllRides() async {
    isLoading.value = true;
    try {
      final result = await SelfDriveApiService().getRequestNew<TopRatedRidesResponse>(
        'inventory/getAllInventoryByCountry/68835bbacd2ef39904163d27',
        TopRatedRidesResponse.fromJson,
      );
      getAllTopRidesResponse.value = result;
    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }
}