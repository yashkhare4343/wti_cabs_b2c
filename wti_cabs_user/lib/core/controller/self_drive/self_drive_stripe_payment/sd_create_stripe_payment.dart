import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/model/self_drive/create_user/self_drive_user_response.dart';
import 'package:wti_cabs_user/core/model/self_drive/sd_provision_response/sd_provision_response.dart';
import 'package:http/http.dart' as http;
import 'package:wti_cabs_user/screens/self_drive/self_drive_payment_status/self_drive_payment_success.dart';


import '../../../../common_widget/loader/popup_loader.dart';
import '../../../../screens/self_drive/self_drive_payment_failure/self_drive_payment_failure.dart';
import '../../../route_management/app_routes.dart';
import '../../../services/storage_services.dart';
import '../self_drive_booking_details/self_drive_booking_details_controller.dart';

class SdCreateStripePaymentController extends GetxController {
  Rx<SelfDriveUserResponse?> selfDriveUserResponse =
  Rx<SelfDriveUserResponse?>(null);
  Rx<SdProvisionResponse?> selfDriveProvisionResponse =
  Rx<SdProvisionResponse?>(null);
  final fetchSdBookingDetailsController = Get.find<FetchSdBookingDetailsController>();
  RxString sourceCity = ''.obs;
   RxDouble sourceLat = 0.0.obs;
   RxDouble sourceLng = 0.0.obs;
   RxString destinationCity = ''.obs;
   RxDouble destinationLat = 0.0.obs;
   RxDouble destinationLng = 0.0.obs;
  RxString orderReferenceNo = ''.obs;
  RxBool isLoading = false.obs;

  // Reactive TextEditingControllers
  var firstNameController = TextEditingController();
  var contactController = TextEditingController();
  var emailController = TextEditingController();
  String? contactCode = '';

  @override
  void onClose() {
    // Dispose controllers to prevent memory leaks
    firstNameController.dispose();
    contactController.dispose();
    emailController.dispose();
    super.onClose();
  }

  // Other reactive fields
  var selectedTitle = 'Mr.'.obs;
  var isGstSelected = false.obs;
  var country = ''.obs;
  var token = ''.obs;
  var tripCode = ''.obs;
  Map<String, dynamic>? stripeCheckout;


  /// create user
  Future<void> createUser({
    required BuildContext context,
  }) async {
    final Map<String, dynamic> requestData = {
      "firstName": firstNameController.text,
      "contact": contactController.text,
      "contactCode": contactCode,
      "emailID": emailController.text,
      "userType": "CUSTOMER",
      "service_using": 'SELF_DRIVE',
      "platform_using": "APP",
      "auth_type": "WTI"
    };

    isLoading.value = true;
    try {
      final response =
      await SelfDriveApiService().postRequestNew<SelfDriveUserResponse>(
        'user/createUser',
        requestData,
        SelfDriveUserResponse.fromJson,
        context,
      );

      selfDriveUserResponse.value = response;

      await openStripeCheckout(
        userID: selfDriveUserResponse.value?.result?.userObjId ?? '',
        context: context,
      );

      await StorageServices.instance.save(
        'userObjId',
        selfDriveUserResponse.value?.result?.userObjId ?? '',
      );
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> openStripeCheckout({
    required String userID,
    required BuildContext context,
  }) async {
    isLoading.value = true;
      final Map<String, dynamic> requestData = {
        "isMobileApp": true,
        "reqResId": fetchSdBookingDetailsController.getAllBookingData.value?.result?.reqResId??'',
        "userType": "CUSTOMER",
        "user_id": userID,
        "extrasSelected": [],
        "paymentType": "FULL",
        "user_documents": [],
        "currencyRate": 1,
        "currency": "AED",
        "selectedTarrif": fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected??'',
        "source": {
          "address":
          sourceCity.value,
          "city":
          sourceCity.value,
          "latlng": {
            "lat": sourceLat.value,
            "lng": sourceLng.value,
          }
        },
        "destination": {
          "address":
          destinationCity.value,
          "city":
          destinationCity.value,
          "latlng": {
            "lat": destinationLat.value,
            "lng": destinationLng.value,
          }
        }
      };
    print("🔄 Starting openStripeCheckout...");

    print('yash self drive proviosion: $requestData');
    try {
      final res = await http.post(
        Uri.parse('${SelfDriveApiService().baseUrl}/reservations/createProvisionalReservation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        body: jsonEncode(requestData),
      );

      print("📥 Received response: ${res.statusCode} ${res.body}");

      if (res.statusCode == 201) {
        stripeCheckout = jsonDecode(res.body);
        print("✅ Stripe checkout response decoded: $stripeCheckout");
        //         selfDriveProvisionResponse.value?.result?.orderData?.result?.clientSecret;

        final String clientSecret = stripeCheckout?['result']['orderData']['result']['clientSecret']?? '';
        orderReferenceNo.value = stripeCheckout?['result']['order_reference_number'];
        print('yash clientSecret key : $clientSecret');
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
              GoRouter.of(context).push(AppRoutes.selfDrivePaymentSuccess);
            });// replace with your page

          } on StripeException catch (e) {
            print("❌ StripeException occurred: ${e.error.localizedMessage}");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).push(AppRoutes.selfDrivePaymentFailure);

            });

            // GoRouter.of(context).pop();
          } catch (e) {
            print("❌ Unknown error presenting payment sheet: $e");
            // WidgetsBinding.instance.addPostFrameCallback((_) {
            //   GoRouter.of(context).push(
            //     AppRoutes.paymentFailure,
            //     extra: lastProvisionalRequest, // ✅ Pass request data
            //   );
            // });


            // GoRouter.of(context).pop();
          }

        } else {
          print("⚠️ clientSecret is empty or null!");
          Future.delayed(Duration(milliseconds: 1000), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).push(AppRoutes.selfDrivePaymentFailure);

            });

            // GoRouter.of(context).pop();
          });        }

      } else {
        print("❌ Stripe API call failed with status: ${res.statusCode}, body: ${res.body}");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).push(AppRoutes.selfDrivePaymentFailure);

        });

        // GoRouter.of(context).pop();
      }

    } catch (e) {
      print("❌ Exception during Stripe checkout: $e");
      Future.delayed(Duration(milliseconds: 1000), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).push(AppRoutes.selfDrivePaymentFailure);
        });

        // GoRouter.of(context).pop();
      });    } finally {
      isLoading.value = false;
      // hideLoader(context);
      print("✅ Finished openStripeCheckout");
    }
  }

}
