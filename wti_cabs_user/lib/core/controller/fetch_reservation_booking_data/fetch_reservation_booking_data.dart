import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/model/booking_reservation/booking_reservation_response.dart';

import '../../api/api_services.dart';
import '../../model/rental_response/fetch_package_response.dart';
import '../../services/storage_services.dart';

class FetchReservationBookingData extends GetxController {
  Rx<ChauffeurReservationsResponse?> chaufferReservationResponse = Rx<ChauffeurReservationsResponse?>(null);
  RxBool isLoading = false.obs;
  RxInt gatewayCode = 0.obs;
  RxString reservationId = ''.obs;

  Future<void> fetchReservationData() async {
    isLoading.value = true;
    final gatewayUsed = await StorageServices.instance.read('country');
    gatewayCode.value =  gatewayUsed?.toLowerCase() == 'india' ? 1 : 0;
    String reservationID = await StorageServices.instance.read(gatewayUsed?.toLowerCase() != 'india'? 'orderReferenceNo': 'reservationId') ?? '';
    reservationId.value = await StorageServices.instance.read(gatewayUsed?.toLowerCase() != 'india'? 'orderReferenceNo': 'reservationId') ?? '';
    try {
      final result = await ApiService().getRequestNew<ChauffeurReservationsResponse>(
        'chaufferReservation/getConfirmedReservationAndReceipts/$reservationID?gatewayUsed=$gatewayCode&role=CUSTOMER',
        ChauffeurReservationsResponse.fromJson,
      );
      chaufferReservationResponse.value = result;
      await StorageServices.instance.save('bookingId', chaufferReservationResponse.value?.result?.first.id??'');

    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }
}