import 'dart:convert';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/controller/inventory/search_cab_inventory_controller.dart';
import 'package:wti_cabs_user/core/model/apply_coupon/apply_coupon.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';
import 'package:wti_cabs_user/main.dart' show navigatorKey;

import '../../../../common_widget/loader/popup_loader.dart';
import '../../../api/api_services.dart';
import '../../analytics_tracking/analytics_tracking.dart';
import '../../cab_booking/cab_booking_controller.dart';
import '../../fetch_reservation_booking_data/fetch_reservation_booking_data.dart';

class IndiaPaymentController extends GetxController {
  RxBool isLoading = false.obs;

  late Razorpay _razorpay;
  late BuildContext _currentContext;
  final currencyController = Get.find<CurrencyController>();
  Map<String, dynamic>? lastProvisionalRequest;
  RxString? orderId;
  final CabBookingController cabBookingController =
      Get.isRegistered<CabBookingController>()
          ? Get.find<CabBookingController>()
          : Get.put(CabBookingController());

  final SearchCabInventoryController searchCabInventoryController = Get.put(SearchCabInventoryController());

  Map<String, dynamic>? registeredUser;
  Map<String, dynamic>? provisionalBooking;
  Map<String, dynamic>? paymentVerification;
  RxString passengerId = ''.obs;
  final FetchReservationBookingData fetchReservationBookingData =
      Get.put(FetchReservationBookingData());

  // Prevent a "double push" to PaymentFailure that can happen when multiple
  // async callbacks (razorpay error + verification exception) try to navigate.
  bool _didNavigateToPaymentFailure = false;

  void _resetPaymentFailureGuard() {
    _didNavigateToPaymentFailure = false;
  }

  void _pushPaymentFailureOnce() {
    if (_didNavigateToPaymentFailure) return;
    _didNavigateToPaymentFailure = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext ?? _currentContext;
      try {
        GoRouter.of(ctx).push(
          AppRoutes.paymentFailure,
          extra: lastProvisionalRequest,
        );
      } catch (_) {
        // If ctx is stale/unmounted, ignore; guard prevents navigation loops.
      }
    });
  }

  String? _safeTrim(dynamic v) => v == null ? null : v.toString().trim();

  String? _toIsoUtcString(dynamic value) {
    final s = _safeTrim(value);
    if (s == null || s.isEmpty || s.toLowerCase() == 'null') return null;
    try {
      final dt = DateTime.parse(s);
      return dt.toUtc().toIso8601String();
    } catch (_) {
      // If it's not parseable, send as-is.
      return s;
    }
  }

  Future<ApplyCouponResponse?> _finalValidateCoupon({
    required String userId,
    required String couponId,
  }) async {
    try {
      final sourceLocation =
          _safeTrim(await StorageServices.instance.read('pickupAddress')) ??
              _safeTrim(await StorageServices.instance.read('sourceTitle')) ??
              '';
      final destinationLocation =
          _safeTrim(await StorageServices.instance.read('dropAddress')) ??
              _safeTrim(await StorageServices.instance.read('destinationTitle')) ??
              '';
      final bookingDateTime = _toIsoUtcString(
        cabBookingController.indiaData.value?.tripType?.pickUpDateTime?.toIso8601String() ??
            await StorageServices.instance.read('userDateTime'),
      );
      final vehicleType =
          cabBookingController.indiaData.value?.inventory?.carTypes?.type ?? '';

      final payload = <String, dynamic>{
        "userID": userId,
        "couponID": couponId,
        "totalAmount": cabBookingController.totalFare,
        "sourceLocation": sourceLocation,
        "destinationLocation": destinationLocation,
        "serviceType": "",
        "bankName": "",
        "userType": "CUSTOMER",
        "bookingDateTime": bookingDateTime,
        "tripType":
        int.parse(searchCabInventoryController.indiaData.value?.result?.tripType?.currentTripCode??''),
        "vehicleType": vehicleType,
      };

      // Use shared API helper so headers/auth/platform are centralized.
      // Also: preserve backend-provided message/errorCode even when status != 200.
      final res = await ApiService().postRequestWithStatus(
        endpoint: 'couponCodes/couponFinalValidation',
        data: payload,
      );

      final body = res['body'];
      if (body is Map<String, dynamic>) {
        return ApplyCouponResponse.fromJson(body);
      }
      if (body is Map) {
        return ApplyCouponResponse.fromJson(Map<String, dynamic>.from(body));
      }
      debugPrint('yash coupon final validation: $payload');

      return ApplyCouponResponse(
        message: 'Unable to validate coupon. Please try again.',
        discountAmount: 0,
        newTotalAmount: cabBookingController.totalFare,
        errorCode: 1,
      );
    } catch (e) {
      return ApplyCouponResponse(
        message: 'Unable to validate coupon. Please try again.',
        discountAmount: 0,
        newTotalAmount: cabBookingController.totalFare,
        errorCode: 1,
      );
    }
  }

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

  Future<void> logAddToCart() async {
    final selectedTripController = Get.find<SelectedTripController>();
    final currencyController = Get.find<CurrencyController>();
    final convertedPartialAmount = await currencyController
        .convertPrice(cabBookingController.partFare.toDouble());
    final convertFullAmount = await currencyController
        .convertPrice(cabBookingController.totalFare.toDouble());
    // 🧩 Add or merge custom keys (including converted amount)
    // 🧾 Get stored values
    final storedItem = selectedTripController.selectedItem.value;
    final storedParams = selectedTripController.parameters;

    if (storedItem == null || storedParams.isEmpty) {
      print('⚠️ No trip data found in controller, skipping log.');
      return;
    }

    // 🧩 You can modify or add new keys if needed
    selectedTripController.addCustomParameters({
      'event': 'add_to_cart',
      'screen_name': 'Booking Details Screen',
      'partial_amount': convertedPartialAmount,
      'payment_option':
          cabBookingController.selectedOption.value == 1 ? "FULL" : "PART",
      'total_amount': convertFullAmount
    });

    // ✅ Prepare final parameters to send
    final updatedParams =
        Map<String, Object>.from(selectedTripController.parameters);

    // ✅ Log to Firebase Analytics
    await FirebaseAnalytics.instance.logAddToCart(
      items: [storedItem],
      parameters: updatedParams,
    );

    print('✅ Logged add to cart for ${storedItem.itemName}');
    print('📦 Parameters sent: $updatedParams');
  }

  Future<void> verifySignup({
    required Map<String, dynamic> requestData,
    required Map<String, dynamic> provisionalRequestData,
    required BuildContext context,
  }) async {
    _currentContext = context; // ✅ Save context early
    _resetPaymentFailureGuard();

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
        await StorageServices.instance
            .save('userObjId', registeredUser?['user_obj_id']);
        print("✅ Signup success: $registeredUser");

        await Future.delayed(Duration(milliseconds: 1000));

        // ✅ Final coupon validation (pay time) before provisional booking.
        final selectedCouponId = cabBookingController.selectedCouponId.value;
        if (selectedCouponId != null && selectedCouponId.trim().isNotEmpty) {
          final userObjId = _safeTrim(registeredUser?['user_obj_id']) ?? '';
          if (userObjId.isNotEmpty) {
            final couponRes = await _finalValidateCoupon(
              userId: userObjId,
              couponId: selectedCouponId.trim(),
            );
            if ((couponRes?.errorCode ?? 0) == 1) {
              // Unselect coupon but keep error so UI can show it under that coupon.
              cabBookingController.clearSelectedCoupon(clearValidationError: false);
              cabBookingController.setCouponValidationError(
                couponId: selectedCouponId.trim(),
                message: couponRes?.message ?? 'Coupon validation failed',
                errorCode: couponRes?.errorCode,
              );
              // Also refetch fare details WITHOUT couponID so pricing reflects removal.
              final base = cabBookingController.lastIndiaFareRequestData;
              if (base != null) {
                final payload = Map<String, dynamic>.from(base);
                payload.remove('couponID'); // ensure it's not passed accidentally
                await cabBookingController.fetchIndiaFareDetails(
                  requestData: payload,
                  context: context,
                );
              }
              return;
            }
          }
        }

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
    _resetPaymentFailureGuard();
    isLoading.value = true;
    try {
      requestData['reservation']['passenger'] = passengerId;
      lastProvisionalRequest = requestData;
      print('provision request data : ${requestData}');
      // Do NOT send UI-only keys to backend.
      final Map<String, dynamic> apiPayload =
          Map<String, dynamic>.from(requestData);
      apiPayload.remove('ui');
      final res = await http.post(
        Uri.parse(
            '${ApiService().baseUrl}/chaufferReservation/createProvisionalReservationRefactored'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
          'X-Platform': 'APP'
        },
        body: jsonEncode(apiPayload),
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
        // 'key': 'rzp_test_RiIBKSoVh36jSP',
        //live key
        'key': 'rzp_live_swV8qRrgmiVPpJ',
        // Razorpay expects amount in paise for INR, multiply by 100 if needed
        'amount': (rawAmount * 100),
        'currency': currencyController
            .selectedCurrency.value.code, // "INR", "USD", etc.
        'name': 'WTI',
        'description': 'Cab Booking Payment',
        'order_id': order['id'],
        'notes': {
          'project': "WTICABS",
          'platform_using': "APP",
          'OS': Platform.isAndroid ? "ANDROID" : "IOS", // ANDROID / IOS
          'comingFrom': "INITIAL_FLOW",
        },
        'prefill': {
          'contact': registeredUser?['number']?.toString() ?? '',
          'email': registeredUser?['email'] ?? '',
        },
        'theme': {'color': '#212F62'},
      };

      _razorpay.open(options);
      logAddToCart();
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
      // "razorpay_payment_id": response.paymentId,
      // "razorpay_signature": response.signature
    };
    await StorageServices.instance
        .save('reservationId', response.orderId ?? '');
    print(
        'reservationID yash: ${await StorageServices.instance.read('reservationId')}');

    await verifyPaymentStatus(verifyPayload).then((value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(_currentContext).push(AppRoutes.paymentSuccess);
      });
      GoRouter.of(_currentContext).pop();
    }).then((value) {
      fetchReservationBookingData.fetchReservationData();
    });
  }

  // ✅ FIXED: No context in method signature, using stored _currentContext
  void _handlePaymentError(PaymentFailureResponse response) async {
    print("❌ Payment Error: ${response.code} - ${response.message}");
    fetchReservationBookingData.fetchReservationData();
    _pushPaymentFailureOnce();

    // Best-effort pop to close any loader/dialog route.
    try {
      final router = GoRouter.of(navigatorKey.currentContext ?? _currentContext);
      if (router.canPop()) router.pop();
    } catch (_) {}
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("ℹ️ Wallet Selected: ${response.walletName}");
    Get.snackbar("Wallet", "Using: ${response.walletName}",
        snackPosition: SnackPosition.BOTTOM);
  }

  // ✅ FIXED: context taken from _currentContext
  Future<void> verifyPaymentStatus(Map<String, dynamic> requestData) async {
    _resetPaymentFailureGuard();
    isLoading.value = true;
    try {
      print("📤 Verifying payment with: $requestData");

      final res = await http.post(
        Uri.parse(
            '${ApiService().baseUrl}/razorpay/chauffer/checkRazorpayPaymentStatus'),
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
      _pushPaymentFailureOnce();
      // Best-effort pop to close any loader/dialog route.
      try {
        final router = GoRouter.of(navigatorKey.currentContext ?? _currentContext);
        if (router.canPop()) router.pop();
      } catch (_) {}
    } finally {
      isLoading.value = false;
    }
  }
}
