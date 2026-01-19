import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // ✅ Required for launching browser
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';

import '../../../../common_widget/loader/popup_loader.dart';
import '../../../api/api_services.dart';

class GlobalPaymentController extends GetxController {
  RxBool isLoading = false.obs;
  Map<String, dynamic>? registeredUser;
  Map<String, dynamic>? createCustomer;
  Map<String, dynamic>? provisionalBooking;
  Map<String, dynamic>? stripeCheckout;
  Map<String, dynamic>? lastProvisionalRequest;

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
        Uri.parse(
            '${ApiService().baseUrl}/user/createUser'),
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
        await StorageServices.instance
            .save('userObjId', registeredUser?['user_obj_id']);
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
      lastProvisionalRequest = requestData;

      final res = await http.post(
        Uri.parse(
            '${ApiService().baseUrl}/stripe/createCustomer'),
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
      // Keep a copy for payment failure UI, but strip UI-only keys before sending to backend.
      lastProvisionalRequest = requestData;
      final Map<String, dynamic> apiPayload =
          Map<String, dynamic>.from(requestData);
      apiPayload.remove('ui');
      requestData.forEach((key, value) {
        requestData[key] = value;
      });
      print("📤 Provisional booking request: $requestData");

      final res = await http.post(
        Uri.parse(
            '${ApiService().baseUrl}/chaufferReservation/createProvisionalReservation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
          'X-Platform': 'APP'
        },
        body: jsonEncode(apiPayload),
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
    print("🔄 Starting openStripeCheckout...");

    try {
      print("📤 Sending stripe checkout request with data: $requestData");

      requestData['order_reference_number'] = provisionalBooking?['order_reference_number'];
      await StorageServices.instance.save('orderReferenceNo', requestData['order_reference_number']);
      requestData['customerId'] = createCustomer?['customerID'];
      requestData['userID'] = registeredUser?['user_obj_id'];

      final res = await http.post(
        Uri.parse('${ApiService().baseUrl}/stripe/checkOutSessionForMobileSDK'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        body: jsonEncode(requestData),
      );

      print("📥 Received response: ${res.statusCode} ${res.body}");

      if (res.statusCode == 200) {
        stripeCheckout = jsonDecode(res.body);
        print("✅ Stripe checkout response decoded: $stripeCheckout");

        final String clientSecret = stripeCheckout?['clientSecret'] ?? '';
        if (clientSecret.isNotEmpty) {
          print("🔐 Initializing payment sheet with clientSecret: $clientSecret");

          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'WTI CABS',
              style: ThemeMode.light,
              appearance: PaymentSheetAppearance(
                colors: PaymentSheetAppearanceColors(
                  background: Colors.white,
                  primary: Colors.green,
                  componentText: Colors.black,
                ),
              ),
              allowsDelayedPaymentMethods: false,
            ),
          );

          try {
            print("🧾 Presenting payment sheet...");
            await Stripe.instance.presentPaymentSheet();

            print("✅ Payment successful. Navigating to success page...");
            Future.delayed(Duration(milliseconds: 1000), () {
              GoRouter.of(context).push(AppRoutes.paymentSuccess);
            });// replace with your page

          } on StripeException catch (e) {
            print("❌ StripeException occurred: ${e.error.localizedMessage}");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).push(
                AppRoutes.paymentFailure,
                extra: lastProvisionalRequest, // ✅ Pass request data
              );
            });

            GoRouter.of(context).pop();
          } catch (e) {
            print("❌ Unknown error presenting payment sheet: $e");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).push(
                AppRoutes.paymentFailure,
                extra: lastProvisionalRequest, // ✅ Pass request data
              );
            });

            GoRouter.of(context).pop();          }

        } else {
          print("⚠️ clientSecret is empty or null!");
          Future.delayed(Duration(milliseconds: 1000), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).push(
                AppRoutes.paymentFailure,
                extra: lastProvisionalRequest, // ✅ Pass request data
              );
            });

            GoRouter.of(context).pop();           });        }

      } else {
        print("❌ Stripe API call failed with status: ${res.statusCode}, body: ${res.body}");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).push(
            AppRoutes.paymentFailure,
            extra: lastProvisionalRequest, // ✅ Pass request data
          );
        });

        GoRouter.of(context).pop();       }

    } catch (e) {
      print("❌ Exception during Stripe checkout: $e");
      Future.delayed(Duration(milliseconds: 1000), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).push(
            AppRoutes.paymentFailure,
            extra: lastProvisionalRequest, // ✅ Pass request data
          );
        });

        GoRouter.of(context).pop();       });    } finally {
      isLoading.value = false;
      hideLoader(context);
      print("✅ Finished openStripeCheckout");
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
