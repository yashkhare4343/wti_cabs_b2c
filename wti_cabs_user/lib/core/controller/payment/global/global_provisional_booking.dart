import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // ✅ Required for launching browser
import 'package:wti_cabs_user/core/services/storage_services.dart';

class GlobalPaymentController extends GetxController {
  RxBool isLoading = false.obs;
  Map<String, dynamic>? registeredUser;
  Map<String, dynamic>? createCustomer;
  Map<String, dynamic>? provisionalBooking;
  Map<String, dynamic>? stripeCheckout;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> verifySignup({
    required Map<String, dynamic> requestData,
    required Map<String, dynamic> provisionalRequestData,
    required Map<String, dynamic> checkoutRequestData,
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
        print("✅ Signup success: $registeredUser");

        await createCustomerStripe(
          provisionalRequestData: provisionalRequestData,
          context: context,
          checkoutRequestData: checkoutRequestData,
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

  Future<void> createCustomerStripe({
    required Map<String, dynamic> provisionalRequestData,
    required Map<String, dynamic> checkoutRequestData,
    required BuildContext context,
  }) async {
    Map<String, dynamic> requestData = {
      "name": "yash",
      "phone": 9179419377,
      "email": "yash.khare@aaveg.com",
      "address": {
        "line1": "125 mudchute",
        "postal_code": 1111,
        "city": "london"
      }
    };

    isLoading.value = true;
    try {
      print("📤 create customer request: $requestData");

      final res = await http.post(
        Uri.parse('https://test.wticabs.com:5001/global/app/v1/stripe/createCustomer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        body: jsonEncode(requestData),
      );

      if (res.statusCode == 200) {
        createCustomer = jsonDecode(res.body);
        print("✅ create customer success: $createCustomer");

        await provisionalBookingMethod(
          provisionalRequestData,
          checkoutRequestData,
          context,
        );
      } else {
        print("❌ create customer failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("❌ create customer exception: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> provisionalBookingMethod(
      Map<String, dynamic> requestData,
      Map<String, dynamic> checkoutRequestData,
      BuildContext context,
      ) async {
    isLoading.value = true;
    try {
      print("📤 Provisional booking request: $requestData");

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
        print("✅ Provisional booking success");

        // Proceed to payment
        await openStripeCheckout(
          requestData: checkoutRequestData,
          context: context,
        );
      } else {
        print("❌ Booking failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("❌ Provisional booking exception: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openStripeCheckout({
    required Map<String, dynamic> requestData,
    required BuildContext context,
  }) async {
    isLoading.value = true;
    try {
      print("📤 stripe checkout request: $requestData");

      final res = await http.post(
        Uri.parse('https://test.wticabs.com:5001/global/app/v1/stripe/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        body: jsonEncode(requestData),
      );

      if (res.statusCode == 200) {
        stripeCheckout = jsonDecode(res.body);
        print("✅ stripe checkout success: $stripeCheckout");

        final url = stripeCheckout?['sessionURL'];
        if (url != null && url.toString().isNotEmpty) {
          await _launchStripeCheckout(url);
        } else {
          print("⚠️ Missing checkout_url");
        }
      } else {
        print("❌ Stripe failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("❌ Stripe exception: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _launchStripeCheckout(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('❌ Could not launch Stripe Checkout URL');
    }
  }
}
