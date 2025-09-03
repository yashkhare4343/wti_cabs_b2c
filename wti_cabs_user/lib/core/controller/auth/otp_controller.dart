import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import 'package:wti_cabs_user/core/model/auth/otp/otp_response.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../../api/api_services.dart';
import '../../services/storage_services.dart';

class OtpController extends GetxController {
  Rx<OtpResponse?> otpData = Rx<OtpResponse?>(null);
  RxBool isLoading = false.obs;

  RxnBool isAuth = RxnBool(null); // 🔹 nullable by default
  RxString otpMessage = ''.obs; // message text (error or success)
  RxBool hasError = false.obs;   // true if error, false if success

  Future<bool> verifyOtp({
    required String mobile,
    required String otp,
    required BuildContext context,
  }) async {
    isLoading.value = true;

    try {
      final result = await ApiService().postRequestWithStatus(
        endpoint: 'user/verifyOtpViaSms',
        data: {
          "contact": mobile,
          "otp": otp,
        },
      );

      final statusCode = result["statusCode"];
      final body = result["body"];

      if (statusCode == 200 && body != null) {
        isAuth.value = body["auth"]; // 🔹 true or false from API

        if (body["auth"] == true) {
          otpData.value = OtpResponse.fromJson(body);
          decodeRefreshToken(otpData.value?.refreshToken ?? '');
          await StorageServices.instance.save('refreshToken', otpData.value?.refreshToken ?? '');
          await StorageServices.instance.save('token', otpData.value?.accessToken ?? '');
          otpMessage.value = body["description"] ?? "OTP verified successfully";
          // GoRouter.of(context).pop();
          return true;
        } else {
          otpMessage.value = body["description"] ?? "OTP verification failed";
          return false;
        }
      } else {
        isAuth.value = false;
        otpMessage.value = "Incorrect response from server";
        return false;
      }
    } catch (e) {
      isAuth.value = false;
      otpMessage.value = "Incorrect OTP! Please try again.";
      return false;
    } finally {
      isLoading.value = false;
    }
  }



// ... rest of your code ...



  void decodeRefreshToken(String refreshToken) async{
    // 1. Get all decoded details as Map
    Map<String, dynamic> decodedToken = JwtDecoder.decode(refreshToken);

    print("Decoded Refresh Token: $decodedToken");

    // 2. Get specific claim values
    print("User obj id: ${decodedToken['user_obj_id']}");

    await StorageServices.instance.save('userObjId', decodedToken['user_obj_id']);

    // 3. Check expiry
    bool isExpired = JwtDecoder.isExpired(refreshToken);
    print("Refresh Token Expired? $isExpired");

    // 4. Get remaining time
    Duration timeLeft = JwtDecoder.getRemainingTime(refreshToken);
    print("Time Left: $timeLeft");
  }


}
