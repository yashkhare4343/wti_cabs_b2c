import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_get_entity_all/crp_get_entity_list_controller.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import 'package:wti_cabs_user/core/model/auth/register/register_response.dart';

import '../../../api/corporate/cpr_api_services.dart';
import '../../../model/corporate/crp_verify_response/crp_verify_response.dart';
import '../../../services/storage_services.dart';
import '../crp_branch_list_controller/crp_branch_list_controller.dart';


class VerifyCorporateController extends GetxController {
  Rx<CprVerifyResponse?> cprVerifyResponse = Rx<CprVerifyResponse?>(null);
  // final CrpGetEntityListController crpGetEntityListController = Get.find<CrpGetEntityListController>();
  // final CrpBranchListController crpBranchListController = Get.find<CrpBranchListController>();
  RxBool isLoading = false.obs;
  RxString cprName = ''.obs;
  RxString cprID = ''.obs;

  Map<String, String> parseCorporateString(String input) {
    final parts = input.split('|');
    if (parts.length != 2) {
      return {'crpName': '', 'crpId': ''};
    }

    return {
      'crpName': parts[0].trim(),
      'crpId': parts[1].trim(),
    };
  }


  /// Fetch booking data based on the given country and request body
  Future<void> verifyCorporate(String email, String cprId) async {
    isLoading.value = true;
    try {
      final result = await CprApiService().getRequestNew<CprVerifyResponse>(
        'GetCorporateName?email=$email',
        CprVerifyResponse.fromJson,
      );
      cprVerifyResponse.value = result;
      final parsed = parseCorporateString(cprVerifyResponse.value?.corporateName??'');

      cprName.value = parsed['crpName']??'';
      cprID.value = parsed['crpId']??'';



    } catch (e) {
      print("Failed to verify corporate: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
