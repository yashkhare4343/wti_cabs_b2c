import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import 'package:wti_cabs_user/core/model/auth/register/register_response.dart';
import 'package:wti_cabs_user/core/model/self_drive/self_drive_cancel_reservation/self_drive_cancel_response.dart';

import '../../../api/api_services.dart';
import '../../../route_management/app_routes.dart';




class SelfDriveCancelReservationController extends GetxController {
  Rx<SelfDriveCancelReservationResponse?> reservationCancelResponse = Rx<SelfDriveCancelReservationResponse?>(null);
  RxBool isLoading = false.obs;

  void _successLoader(
      String message,
      BuildContext outerContext,
      VoidCallback onComplete,
      ) {
    showDialog(
      context: outerContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(seconds: 1), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop(); // Close dialog
          }
          onComplete(); // 🚀 Call back
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message, // ✅ Use dynamic message
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This action was completed successfully.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Fetch booking data based on the given country and request body
  Future<void> verifyCancelReservation({
    required final Map<String, dynamic> requestData,
    required BuildContext context,
  }) async {

    isLoading.value = true;
    try {
      final response = await SelfDriveApiService().postRequestNew<SelfDriveCancelReservationResponse>(
        'reservations/cancelReservation',
        requestData,
        SelfDriveCancelReservationResponse.fromJson,
        context,
      );
      reservationCancelResponse.value = response;

      // GoRouter.of(context).pop();
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
    }
    finally {
      isLoading.value = false;
    }
  }

}

