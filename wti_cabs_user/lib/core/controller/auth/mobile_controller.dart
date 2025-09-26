import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../../api/api_services.dart';
import '../../services/storage_services.dart';

class MobileController extends GetxController {
  Rx<MobileResponse?> mobileData = Rx<MobileResponse?>(null);
  RxBool isLoading = false.obs;
  /// Fetch booking data based on the given country and request body
  Future<void> verifyMobile({
    required String mobile,
    required BuildContext context,
  }) async {
    final Map<String, dynamic> requestData = {
      "contact": mobile
    };
    isLoading.value = true;
    try {
        final response = await ApiService().postRequestNew<MobileResponse>(
          'user/loginViaSms',
          requestData,
          MobileResponse.fromJson,
          context,
        );
        mobileData.value = response;
        print('print mobile data : ${mobileData.value}');
        await StorageServices.instance.save('mobileNo', mobile);

    }
    catch(e){
      Flushbar(
        flushbarPosition: FlushbarPosition.TOP, // ✅ Show at top
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
        messageText: const Text(
          "User does not exist, Please register first.",
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ).show(context);
    }
    finally {
      isLoading.value = false;
    }
  }
}
