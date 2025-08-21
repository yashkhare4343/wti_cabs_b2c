import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_rx/src/rx_workers/rx_workers.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../booking_ride_controller.dart';
import '../choose_drop/choose_drop_controller.dart';
import '../choose_pickup/choose_pickup_controller.dart';

class ButtonStateController extends GetxController {
  final PlaceSearchController placeSearchController;
  final DropPlaceSearchController dropPlaceSearchController;
  final BookingRideController bookingRideController;

  ButtonStateController({
    required this.placeSearchController,
    required this.dropPlaceSearchController,
    required this.bookingRideController,
  });

  // single reactive bool for the button
  RxBool isEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();

    // auto-disposed workers
    everAll([
      placeSearchController.placeId,
      dropPlaceSearchController.dropPlaceId,
      placeSearchController.findCntryDateTimeResponse,
      dropPlaceSearchController.dropDateTimeResponse,
      bookingRideController.isInvalidTime,
    ], (_) => validate());
  }

  void validate() {
    final pickupId = placeSearchController.placeId.value;
    final dropId = dropPlaceSearchController.dropPlaceId.value;

    final samePlace = pickupId.isNotEmpty && dropId.isNotEmpty && pickupId == dropId;
    final differntCountry = pickupId.isNotEmpty && dropId.isNotEmpty && placeSearchController.getPlacesLatLng.value?.country != dropPlaceSearchController.dropLatLng.value?.country;

    final hasSourceError = (placeSearchController.findCntryDateTimeResponse.value?.sourceInput ?? false) ||
        (dropPlaceSearchController.dropDateTimeResponse.value?.sourceInput ?? false);

    final hasDestinationError = (placeSearchController.findCntryDateTimeResponse.value?.destinationInputFalse ?? false) ||
        (dropPlaceSearchController.dropDateTimeResponse.value?.destinationInputFalse ?? false);

    final isPlaceMissing = pickupId.isEmpty || dropId.isEmpty;

    final canProceed = !samePlace &&
        !hasSourceError &&
        !hasDestinationError &&
        !differntCountry &&
        !isPlaceMissing &&
        (
            (placeSearchController.findCntryDateTimeResponse.value?.goToNextPage ?? false) ||
                (placeSearchController.findCntryDateTimeResponse.value?.sameCountry ?? false) ||
                (dropPlaceSearchController.dropDateTimeResponse.value?.sameCountry ?? false) ||
                (dropPlaceSearchController.dropDateTimeResponse.value?.goToNextPage ?? false)
        );

    final forceDisable = samePlace || hasSourceError || hasDestinationError;

    isEnabled.value = canProceed && !forceDisable && !bookingRideController.isInvalidTime.value;
  }
}
