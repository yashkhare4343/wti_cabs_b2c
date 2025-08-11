import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/model/home_page_images/home_page_image_response.dart';
import 'package:wti_cabs_user/core/model/usp/usp_response.dart';

import '../../api/api_services.dart';

class BannerController extends GetxController {
  Rx<HomePageImageResponse?> homepageImageResponse = Rx<HomePageImageResponse?>(null);
  RxBool isLoading = false.obs;

  Future<void> fetchImages() async {
    isLoading.value = true;
    try {
      final result = await ApiService().getRequestNew<HomePageImageResponse>(
        'mobile-app/banner-images-homepage/getBannerImagesData/india',
        HomePageImageResponse.fromJson,
      );
      homepageImageResponse.value = result;
      print('yash usp response body : ${homepageImageResponse.value}');

    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
