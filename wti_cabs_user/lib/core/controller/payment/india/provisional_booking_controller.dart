import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';

import '../../../../common_widget/loader/popup_loader.dart';
import '../../../api/api_services.dart';
import '../../fetch_reservation_booking_data/fetch_reservation_booking_data.dart';

class IndiaPaymentController extends GetxController {
  RxBool isLoading = false.obs;

  late Razorpay _razorpay;
  late BuildContext _currentContext;
  final currencyController = Get.find<CurrencyController>();
  Map<String, dynamic>? lastProvisionalRequest;
  RxString ? orderId;


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
        Uri.parse('${ApiService().baseUrl}/user/createUser?isMobile=true'),
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
      lastProvisionalRequest = requestData;
      print('provision request data : ${requestData}');
      final res = await http.post(
        Uri.parse('${ApiService().baseUrl}/chaufferReservation/createProvisionalReservation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
          'X-Platform': 'APP'
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

  void _openRazorpayCheckout(Map<String, dynamic> order) async {
    try {
      // 🔹 Convert amount to selected currency
      final rawAmount = (order['amount'] ?? 0).toDouble();
      orderId?.value = order['id'];
      final options = {
        // test key
        // 'key': 'rzp_test_Ymyq5LXpYAetuR',
        //live key
        'key': 'rzp_live_swV8qRrgmiVPpJ',
        // Razorpay expects amount in paise for INR, multiply by 100 if needed
        'amount': (rawAmount * 100),
        'currency': currencyController.selectedCurrency.value.code, // "INR", "USD", etc.
        'name': 'WTI Cabs',
        'description': 'Cab Booking Payment',
        'order_id': order['id'],
        'prefill': {
          'contact': registeredUser?['number']?.toString() ?? '',
          'email': registeredUser?['email'] ?? '',
        },
        'theme': {'color': '#212F62'},
      };

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
    await StorageServices.instance.save('reservationId', response.orderId??'');

    await verifyPaymentStatus(verifyPayload).then((value){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(_currentContext).push(AppRoutes.paymentSuccess);
      });
      GoRouter.of(_currentContext).pop();
    }).then((value){
      fetchReservationBookingData.fetchReservationData();

    });
  }

  // ✅ FIXED: No context in method signature, using stored _currentContext
  void _handlePaymentError(PaymentFailureResponse response) async{
    print("❌ Payment Error: ${response.code} - ${response.message}");
    fetchReservationBookingData.fetchReservationData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoRouter.of(_currentContext).push(
        AppRoutes.paymentFailure,
        extra: lastProvisionalRequest, // ✅ Pass request data
      );
    });

    GoRouter.of(_currentContext).pop();
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
        Uri.parse('${ApiService().baseUrl}/razorpay/chauffer/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        body: jsonEncode(requestData),
      );

      if (res.statusCode == 200) {
        paymentVerification = jsonDecode(res.body);

        print("✅ Payment Verified: $paymentVerification");
      }
    } catch (e) {
      print("❌ Verification exception: $e");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(_currentContext).push(AppRoutes.paymentFailure);
      });
      GoRouter.of(_currentContext).pop();

    } finally {
      isLoading.value = false;
    }
  }
}
