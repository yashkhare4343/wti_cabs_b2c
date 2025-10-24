import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import '../../../model/self_drive/self_drive_payment_status/self_drive_payment_status_response.dart';
import '../self_drive_stripe_payment/sd_create_stripe_payment.dart';

class SelfDriveFetchReservationController extends GetxController {
  Rx<PaymentReservationResponse?> sdPaymentBookingResponse =
  Rx<PaymentReservationResponse?>(null);
  final SdCreateStripePaymentController sdCreateStripePaymentController = Get.put(SdCreateStripePaymentController());

  RxBool isLoading = false.obs;

  // Success
  Future<void> fetchReservationDetails(String orderRefNo) async {
    print("🔄 [fetchPaymentBookingDetails] Started for orderRef: ${orderRefNo}");
    isLoading.value = true;

    try {
      print("📡 Sending request -> reservations/getConfirmedReservation/${sdCreateStripePaymentController.orderReferenceNo.value}");
      final result = await SelfDriveApiService().getRequestNew<PaymentReservationResponse>(
        'reservations/getConfirmedReservation/${sdCreateStripePaymentController.orderReferenceNo.value}',
        PaymentReservationResponse.fromJson,
      );

      print("✅ Response received (Confirmed Reservation)");
      print("📦 Parsed result: $result");
      sdPaymentBookingResponse.value = result;
    } catch (e, stack) {
      print("❌ Failed to fetch confirmed reservation: $e");
      print("🪵 Stack trace: $stack");
    } finally {
      isLoading.value = false;
      print("✅ [fetchPaymentBookingDetails] Completed for orderRef: ${sdCreateStripePaymentController.orderReferenceNo.value}");
    }
  }

  // Failure
  Future<void> fetchPaymentFailureBookingDetails() async {
    print("🔄 [fetchPaymentFailureBookingDetails] Started for orderRef: ${sdCreateStripePaymentController.orderReferenceNo.value}");
    isLoading.value = true;

    try {
      print("📡 Sending request -> reservations/getFailedReservation/${sdCreateStripePaymentController.orderReferenceNo.value}");
      final result = await SelfDriveApiService().getRequestNew<PaymentReservationResponse>(
        'reservations/getFailedReservation/${sdCreateStripePaymentController.orderReferenceNo.value}',
        PaymentReservationResponse.fromJson,
      );

      print("✅ Response received (Failed Reservation)");
      print("📦 Parsed result: $result");
      sdPaymentBookingResponse.value = result;
    } catch (e, stack) {
      print("❌ Failed to fetch failed reservation: $e");
      print("🪵 Stack trace: $stack");
    } finally {
      isLoading.value = false;
      print("✅ [fetchPaymentFailureBookingDetails] Completed for orderRef: ${sdCreateStripePaymentController.orderReferenceNo.value}");
    }
  }
}
