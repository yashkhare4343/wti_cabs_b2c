import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import 'package:wti_cabs_user/core/model/auth/register/register_response.dart';
import 'package:wti_cabs_user/core/model/version_check/version_check_response.dart';
import '../../api/api_services.dart';
import '../../services/storage_services.dart';

class VersionCheckController extends GetxController {
  Rx<VersionCheckResponse?> versionCheckResponse = Rx<VersionCheckResponse?>(null);
  RxBool isLoading = false.obs;
  RxBool isAppCompatible = true.obs;
  RxString fcmToken = ''.obs;

  /// Fetch booking data based on the given country and request body
  Future<void> verifyAppCompatibity({
    required BuildContext context,
  }) async {

    isLoading.value = true;
    Future<Map<String, dynamic>> buildRequestData() async {
      final packageInfo = await PackageInfo.fromPlatform();

      return {
        "platform": Platform.isAndroid ? "android" : "ios",
        "currentVersion": packageInfo.version, // e.g. "4.1.0"
      };
    }
    try {
      final response = await ApiService().postRequestNew<VersionCheckResponse>(
        'app-version/versionCheck',
        await buildRequestData(),
        VersionCheckResponse.fromJson,
        context,
      );
      versionCheckResponse.value = response;
      isAppCompatible.value = versionCheckResponse.value?.isCompatible??true;
      print('app compitable : ${isAppCompatible.value}');
    } finally {
      isLoading.value = false;
    }
  }

}
