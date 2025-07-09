import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import 'package:wti_cabs_user/core/model/auth/register/register_response.dart';
import '../../api/api_services.dart';
import '../../services/storage_services.dart';

class RegisterController extends GetxController {
  Rx<RegisterResponse?> registerResponse = Rx<RegisterResponse?>(null);
  RxBool isLoading = false.obs;

  /// Fetch booking data based on the given country and request body
  Future<void> verifySignup({
   required final Map<String, dynamic> requestData,
    required BuildContext context,
  }) async {

    isLoading.value = true;
    try {
      final response = await ApiService().postRequestNew<RegisterResponse>(
        'user/createUser',
        requestData,
        RegisterResponse.fromJson,
        context,
      );
      registerResponse.value = response;
      print('print mobile data : ${registerResponse.value}');

    } finally {
      isLoading.value = false;
    }
  }


}
