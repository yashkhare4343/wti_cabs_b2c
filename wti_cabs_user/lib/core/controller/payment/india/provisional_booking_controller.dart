import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';

class IndiaPaymentController extends GetxController {
  RxBool isLoading = false.obs;

  late Razorpay _razorpay;

  Map<String, dynamic>? registeredUser;
  Map<String, dynamic>? provisionalBooking;
  Map<String, dynamic>? paymentVerification;
  RxString passengerId = ''.obs;

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
        print('signup passenger id : ${passengerId.value.toString()}');
        await Future.delayed(Duration(milliseconds: 1000));

        await provisionalBookingMethod(
          requestData: provisionalRequestData,
          context: context, passengerId: registeredUser?['user_obj_id'],
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
    required String passengerId
  }) async {
    isLoading.value = true;
    try {
      // Build request map with preserved order
      // First: insert passenger at the top (or wherever you want)
      requestData['reservation']['passenger'] = passengerId;

      // Then: insert all other fields in order
      requestData.forEach((key, value) {
        requestData[key] = value;
      });

      print('📦 Ordered Request Body: ${jsonEncode(requestData)}');
      final encoder = JsonEncoder.withIndent('  ');
      debugPrint('📦Provisional Request Body:\n${encoder.convert(requestData)}');
      final res = await http.post(
        Uri.parse('https://test.wticabs.com:5001/global/app/v1/chaufferReservation/createProvisionalReservation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        body: jsonEncode(requestData),
      );

      if (res.statusCode == 201) {
        provisionalBooking = jsonDecode(res.body);
        final order = provisionalBooking?['order'];

        print("✅ Provisional booking response: $order");

        if (order?['id'] != null && order?['amount'] != null) {
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
      'key': 'rzp_test_Ymyq5LXpYAetuR', // ✅ Replace with actual key in production
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

    print("🧾 Opening Razorpay with: $options");

    try {
      _razorpay.open(options);
    } catch (e) {
      print('❌ Razorpay open error: $e');
    }
  }

  /// ✅ Razorpay success handler (must only take PaymentSuccessResponse)
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("✅ Payment Success:");
    print("🧾 Order ID: ${response.orderId}");
    print("💸 Payment ID: ${response.paymentId}");

    final verifyPayload = {
      "razorpay_order_id": response.orderId,
      "razorpay_payment_id": response.paymentId,
      "razorpay_signature": response.signature
    };

    await verifyPaymentStatus(verifyPayload);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("❌ Payment Error: ${response.code} - ${response.message}");
    Get.snackbar("Payment Failed", response.message ?? "Unknown error",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("ℹ️ Wallet Selected: ${response.walletName}");
    Get.snackbar("Wallet", "Using: ${response.walletName}",
        snackPosition: SnackPosition.BOTTOM);
  }

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
        print("✅ Payment Verified: $paymentVerification");

        Get.snackbar("Success", "Payment Verified Successfully",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      } else {
        print("❌ Verification Failed: ${res.statusCode} ${res.body}");
        Get.snackbar("Failed", "Verification failed from server",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } catch (e) {
      print("❌ Verification exception: $e");
    } finally {
      isLoading.value = false;
    }
  }
}