import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/controller/choose_drop/choose_drop_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/model/booking_reservation/booking_reservation_response.dart';

import '../../api/api_services.dart';
import '../../model/rental_response/fetch_package_response.dart';
import '../../services/storage_services.dart';

class FetchReservationBookingData extends GetxController {
  Rx<ChauffeurReservationsResponse?> chaufferReservationResponse = Rx<ChauffeurReservationsResponse?>(null);
  final DropPlaceSearchController dropPlaceSearchController = DropPlaceSearchController();
  RxBool isLoading = false.obs;
  RxInt gatewayCode = 1.obs;
  RxString reservationId = ''.obs;

  Future<void> fetchReservationData() async {
    isLoading.value = true;
    final gatewayUsed = await StorageServices.instance.read('country');
    gatewayCode.value = dropPlaceSearchController.dropLatLng.value?.country.toLowerCase() == 'india' ? 0 : 1;
    String reservationID = await StorageServices.instance.read(dropPlaceSearchController.dropLatLng.value?.country.toLowerCase() == 'india'? 'orderReferenceNo': 'reservationId') ?? '';
    reservationId.value = await StorageServices.instance.read(dropPlaceSearchController.dropLatLng.value?.country.toLowerCase() == 'india'? 'orderReferenceNo': 'reservationId') ?? '';
    print('yash success reservation country ${dropPlaceSearchController.dropLatLng.value?.country.toLowerCase()}');
    try {
      final result = await ApiService().getRequestNew<ChauffeurReservationsResponse>(
        'chaufferReservation/getConfirmedReservationAndReceipts/${reservationId.value}?gatewayUsed=${gatewayCode.value}&role=CUSTOMER',
        ChauffeurReservationsResponse.fromJson,
      );
      chaufferReservationResponse.value = result;
      await StorageServices.instance.save('bookingId', chaufferReservationResponse.value?.result?.first.id??'');

    } catch (e, s) {
      print("Failed to fetch packages: $e");
      print ('📍Failed to fetch packages STACK: $s');


    } finally {
      isLoading.value = false;
    }
  }
}