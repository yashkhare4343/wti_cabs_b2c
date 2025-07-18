import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import 'package:wti_cabs_user/core/model/auth/otp/otp_response.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../../api/api_services.dart';
import '../../services/storage_services.dart';

class OtpController extends GetxController {
  Rx<OtpResponse?> otpData = Rx<OtpResponse?>(null);
  RxBool isLoading = false.obs;

  /// Fetch booking data based on the given country and request body
  Future<void> verifyOtp({
    required String mobile, required String otp,
    required BuildContext context,
  }) async {
    final Map<String, dynamic> requestData = {
      "contact": mobile,
      "otp": otp
    };
    isLoading.value = true;
    try {
      final response = await ApiService().postRequestNew<OtpResponse>(
        'user/verifyOtpViaSms',
        requestData,
        OtpResponse.fromJson,
        context,
      );
      otpData.value = response;
      print('print otp data : ${otpData.value}');
       await StorageServices.instance.save('refreshToken', otpData.value?.refreshToken??'');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Otp verified successfully', style: CommonFonts.primaryButtonText,),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 800), // Very short duration
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );


    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: CommonFonts.primaryButtonText,),
          backgroundColor: Colors.redAccent,
          duration: const Duration(milliseconds: 800), // Very short duration
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    finally {
      isLoading.value = false;
    }
  }


}
