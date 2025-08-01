import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // ✅ Required for launching browser
import 'package:wti_cabs_user/core/services/storage_services.dart';

import '../../../../common_widget/loader/popup_loader.dart';

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
    showLoader(context);
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
        await StorageServices.instance.save('userObjId', registeredUser?['user_obj_id']);

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
      "name": registeredUser?['name'],
      "phone": registeredUser?['number'],
      "email": registeredUser?['email'],
      "address": ""
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

  // add passenger from here
  Future<void> provisionalBookingMethod(
      Map<String, dynamic> requestData,
      Map<String, dynamic> checkoutRequestData,
      BuildContext context,
      ) async {
    isLoading.value = true;
    try {

      requestData['reservation']['passenger'] = registeredUser?['user_obj_id'];
      requestData.forEach((key, value) {
        requestData[key] = value;
      });
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
      requestData['order_reference_number'] = provisionalBooking?['order_reference_number'];
      requestData['customerId'] = createCustomer?['customerID'];
      requestData['userID'] = registeredUser?['user_obj_id'];



      // Then: insert all other fields in order
      requestData.forEach((key, value) {
        requestData[key] = value;
      });
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
      hideLoader(context);

    }
  }

  Future<void> _launchStripeCheckout(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } else {
      throw Exception('❌ Could not launch Stripe Checkout URL');
    }
  }
  void showLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopupLoader(
        message: "Go to Payment Page",
      ),
    );
  }

  void hideLoader(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

}

