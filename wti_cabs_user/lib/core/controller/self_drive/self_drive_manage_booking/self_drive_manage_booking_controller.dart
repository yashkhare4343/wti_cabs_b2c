import 'package:flutter/cupertino.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/model/booking_reservation/booking_reservation_response.dart';
import 'package:wti_cabs_user/core/model/self_drive/self_drive_manage_booking/self_drive_manage_booking_response.dart';

import '../../../api/api_services.dart';
import '../../../model/self_drive/get_all_cities/get_all_cities_response.dart';


class SelfDriveManageBookingController extends GetxController {
  /// Per-status cache so tab switches don't overwrite each other.
  final RxMap<String, SelfDriveManageBookingResponse?> bookingsByStatus =
      <String, SelfDriveManageBookingResponse?>{}.obs;

  /// Per-status loading state (so one tab loading doesn't blank others).
  final RxMap<String, bool> loadingByStatus = <String, bool>{}.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  var isFormValid = false.obs;

  void validateForm() {
    final isValid = formKey.currentState?.validate() ?? false;
    isFormValid.value = isValid;
  }

  bool isLoadingFor(String status) => loadingByStatus[status] ?? false;

  List<ReservationResult> resultsFor(String status) =>
      bookingsByStatus[status]?.result ?? const <ReservationResult>[];

  Future<void> fetchMangeBooking(String status, {bool force = false}) async {
    // If we already have data for this status, don't refetch unless forced.
    if (!force && bookingsByStatus.containsKey(status)) return;

    loadingByStatus[status] = true;
    try {
      final result = await SelfDriveApiService()
          .getRequestNewToken<SelfDriveManageBookingResponse>(
        'reservations/getFinalReservationAndReceipts/$status',
        SelfDriveManageBookingResponse.fromJson,
      );
      bookingsByStatus[status] = result;
    } catch (e) {
      // Keep existing cached data (if any) on error.
      print("Failed to fetch packages: $e");
    } finally {
      loadingByStatus[status] = false;
    }
  }
}