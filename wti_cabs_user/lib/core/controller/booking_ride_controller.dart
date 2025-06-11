

// Update with the correct path

import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class BookingRideController extends GetxController {
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  RxString localStartTime = "Loading...".obs;
  RxString prefilled = "".obs;
  RxString prefilledDrop = "".obs;


  @override
  void onInit() {
    super.onInit();// Initialize timezone data
  }
}
