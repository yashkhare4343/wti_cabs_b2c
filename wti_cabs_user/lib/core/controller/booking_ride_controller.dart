import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class BookingRideController extends GetxController {
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();// Initialize timezone data
  }
  // ✅ Correct type — DateTime not String
  Rx<DateTime> localStartTime = DateTime.now().obs;
  Rx<DateTime> utcStartTime = DateTime.now().obs;
  RxString prefilled = "".obs;
  RxString prefilledDrop = "".obs;



  // ✅ Always parse string when assigning
  void updateLocalStartTimeFromString(String dateTimeString) {
    try {
      localStartTime.value = DateTime.parse(dateTimeString);
    } catch (e) {
      errorMessage.value = "Invalid date time string: $e";
    }
  }

}
