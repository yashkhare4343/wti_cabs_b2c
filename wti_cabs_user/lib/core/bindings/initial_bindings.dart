import 'package:get/get.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_drop/choose_drop_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/drop_location_controller/drop_location_controller.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Core controllers used across many routes/screens. Register once so Get.find()
    // is safe even on cold starts / deep links.
    if (!Get.isRegistered<BookingRideController>()) {
      Get.put(BookingRideController(), permanent: true);
    }
    if (!Get.isRegistered<DestinationLocationController>()) {
      Get.put(DestinationLocationController(), permanent: true);
    }
    if (!Get.isRegistered<PlaceSearchController>()) {
      Get.put(PlaceSearchController(), permanent: true);
    }
    // Prefer lazy creation here to avoid lifecycle running before the UI is ready.
    if (!Get.isRegistered<DropPlaceSearchController>()) {
      Get.lazyPut<DropPlaceSearchController>(() => DropPlaceSearchController());
    }
  }
}

