import 'package:flutter/cupertino.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/model/booking_reservation/booking_reservation_response.dart';
import 'package:wti_cabs_user/core/model/self_drive/self_drive_manage_booking/self_drive_manage_booking_response.dart';

import '../../../api/api_services.dart';
import '../../../model/self_drive/get_all_cities/get_all_cities_response.dart';


class SelfDriveManageBookingController extends GetxController {
  Rx<SelfDriveManageBookingResponse?> sdManageBooking = Rx<SelfDriveManageBookingResponse?>(null);
  RxBool isLoading = false.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  var isFormValid = false.obs;

  void validateForm() {
    final isValid = formKey.currentState?.validate() ?? false;
    isFormValid.value = isValid;
  }

  Future<void> fetchMangeBooking(String status) async {
    isLoading.value = true;
    try {
      final result = await SelfDriveApiService().getRequestNewToken<SelfDriveManageBookingResponse>(
        'reservations/getFinalReservationAndReceipts/$status',
        SelfDriveManageBookingResponse.fromJson,
      );
      sdManageBooking.value = result;
    } catch (e) {
      print("Failed to fetch packages: $e");
    } finally {
      isLoading.value = false;
    }
  }
}