import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import 'package:wti_cabs_user/core/model/auth/register/register_response.dart';

import '../api/api_services.dart';
import '../model/reservation_cancel_response/reservation_cancel_booking.dart';
import '../services/storage_services.dart';


class ReservationCancellationController extends GetxController {
  Rx<ReservationCancelResponse?> reservationCancelResponse = Rx<ReservationCancelResponse?>(null);
  RxBool isLoading = false.obs;

  /// Fetch booking data based on the given country and request body
  Future<bool> verifyCancelReservation({
    required final Map<String, dynamic> requestData,
    required BuildContext context,
  }) async {

    isLoading.value = true;
    try {
      reservationCancelResponse.value = null;
      final response = await ApiService().postRequestNew<ReservationCancelResponse>(
        'chaufferReservation/cancelChauffeurReservation',
        requestData,
        ReservationCancelResponse.fromJson,
        context,
      );
      reservationCancelResponse.value = response;
      return response != null;
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Some thing went wrong, Please try again', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return false;
    }
    finally {
      isLoading.value = false;
    }
  }

}
