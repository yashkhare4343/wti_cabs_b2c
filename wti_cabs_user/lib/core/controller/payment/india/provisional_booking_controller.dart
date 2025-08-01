import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';

import '../../../../common_widget/loader/popup_loader.dart';
import '../../fetch_reservation_booking_data/fetch_reservation_booking_data.dart';

class IndiaPaymentController extends GetxController {
  RxBool isLoading = false.obs;

  late Razorpay _razorpay;
  late BuildContext _currentContext;

  Map<String, dynamic>? registeredUser;
  Map<String, dynamic>? provisionalBooking;
  Map<String, dynamic>? paymentVerification;
  RxString passengerId = ''.obs;
  final FetchReservationBookingData fetchReservationBookingData = Get.put(FetchReservationBookingData());

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  Future<void> verifySignup({
    required Map<String, dynamic> requestData,
    required Map<String, dynamic> provisionalRequestData,
    required BuildContext context,
  }) async {
    _currentContext = context; // ✅ Save context early

    isLoading.value = true;
    try {
      print("📤 Signup request: $requestData");

      final res = await http.post(
        Uri.parse('https://test.wticabs.com:5001/global/app/v1/user/createUser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        body: jsonEncode(requestData),
      );

      if (res.statusCode == 200) {
        registeredUser = jsonDecode(res.body);
        await StorageServices.instance.save('userObjId', registeredUser?['user_obj_id']);
        print("✅ Signup success: $registeredUser");

        await Future.delayed(Duration(milliseconds: 1000));

        await provisionalBookingMethod(
          requestData: provisionalRequestData,
          context: context,
          passengerId: registeredUser?['user_obj_id'],
        );
      } else {
        print("❌ Signup failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("❌ Signup exception: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> provisionalBookingMethod({
    required Map<String, dynamic> requestData,
    required BuildContext context,
    required String passengerId,
  }) async {
    isLoading.value = true;
    try {
      requestData['reservation']['passenger'] = passengerId;

      final res = await http.post(
        Uri.parse('https://test.wticabs.com:5001/global/app/v1/chaufferReservation/createProvisionalReservation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        body: jsonEncode(requestData),
      );

      print("📤 provision request: $requestData");


      if (res.statusCode == 201) {
        provisionalBooking = jsonDecode(res.body);
        final order = provisionalBooking?['order'];

        if (order?['id'] != null && order?['amount'] != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const PopupLoader(
              message: ''
                  'Please wait...Do not close!',
            ),
          );
          _openRazorpayCheckout(order);
        } else {
          print("⚠️ Missing Razorpay order ID or amount");
        }
      } else {
        print("❌ Booking failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("❌ Provisional booking exception: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _openRazorpayCheckout(Map<String, dynamic> order) {
    final options = {
      'key': 'rzp_test_Ymyq5LXpYAetuR',
      'amount': (order['amount'] ?? 0).toInt(),
      'name': 'WTI Cabs',
      'description': 'Cab Booking Payment',
      'order_id': order['id'],
      'prefill': {
        'contact': registeredUser?['number']?.toString() ?? '',
        'email': registeredUser?['email'] ?? '',
      },
      'theme': {'color': '#212F62'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('❌ Razorpay open error: $e');
    }
  }

  // ✅ FIXED: No context in method signature, using stored _currentContext
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("✅ Payment Success:");
    print("🧾 Order ID: ${response.orderId}");
    print("💸 Payment ID: ${response.paymentId}");

    final verifyPayload = {
      "razorpay_order_id": response.orderId,
      "razorpay_payment_id": response.paymentId,
      "razorpay_signature": response.signature
    };

    await verifyPaymentStatus(verifyPayload).then((value){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(_currentContext).push(AppRoutes.paymentSuccess);
      });
    }).then((value){
      fetchReservationBookingData.fetchReservationData();

    });
  }

  // ✅ FIXED: No context in method signature, using stored _currentContext
  void _handlePaymentError(PaymentFailureResponse response) {
    print("❌ Payment Error: ${response.code} - ${response.message}");
    fetchReservationBookingData.fetchReservationData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoRouter.of(_currentContext).push(AppRoutes.paymentFailure);
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("ℹ️ Wallet Selected: ${response.walletName}");
    Get.snackbar("Wallet", "Using: ${response.walletName}",
        snackPosition: SnackPosition.BOTTOM);
  }

  // ✅ FIXED: context taken from _currentContext
  Future<void> verifyPaymentStatus(Map<String, dynamic> requestData) async {
    isLoading.value = true;
    try {
      print("📤 Verifying payment with: $requestData");

      final res = await http.post(
        Uri.parse('https://test.wticabs.com:5001/global/app/v1/razorpay/chauffer/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        body: jsonEncode(requestData),
      );

      if (res.statusCode == 200) {
        paymentVerification = jsonDecode(res.body);
        await StorageServices.instance.save('reservationId', paymentVerification?['isUpdated']['reservationId']);

        print("✅ Payment Verified: $paymentVerification");
      }
    } catch (e) {
      print("❌ Verification exception: $e");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(_currentContext).push(AppRoutes.paymentFailure);
      });
    } finally {
      isLoading.value = false;
    }
  }
}
