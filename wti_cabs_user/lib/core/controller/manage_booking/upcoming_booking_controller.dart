import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/model/booking_reservation/booking_reservation_response.dart';

import '../../api/api_services.dart';
import '../../model/manage_booking/upcoming_booking_response.dart';
import '../../model/rental_response/fetch_package_response.dart';
import '../../services/storage_services.dart';

class UpcomingBookingController extends GetxController {
  Rx<UpcomingBookingResponse?> upcomingBookingResponse = Rx<UpcomingBookingResponse?>(null);
  RxList<ChauffeurResult> confirmedBookings = <ChauffeurResult>[].obs; // 🔹 Filtered list
  RxList<ChauffeurResult> completedBookings = <ChauffeurResult>[].obs; // 🔹 Filtered list
  RxList<ChauffeurResult> cancelledBookings = <ChauffeurResult>[].obs; // 🔹 Filtered list
  RxBool isLoading = false.obs;

  // upcoming bookings

  Future<void> fetchUpcomingBookingsData() async {
    isLoading.value = true;

    try {
      final result = await ApiService().getRequestNew<UpcomingBookingResponse>(
        'chaufferReservation/getFinalReservationAndReceipts/674997b606bfbb86625443de',
        UpcomingBookingResponse.fromJson,
      );

      upcomingBookingResponse.value = result;

      // 🔹 Apply filter here and store in separate list
      confirmedBookings.value = result.result
          ?.where((booking) => booking.bookingStatus == "CONFIRMED")
          .toList() ??
          [];

      completedBookings.value = result.result
          ?.where((booking) => booking.bookingStatus == "COMPLETED")
          .toList() ??
          [];
      cancelledBookings.value = result.result
          ?.where((booking) => booking.bookingStatus == "CANCELLED")
          .toList() ??
          [];

      print('yash cancelled bookings : ${cancelledBookings.value}');

    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }

}
