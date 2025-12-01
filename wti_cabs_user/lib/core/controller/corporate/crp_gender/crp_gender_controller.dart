import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/api/corporate/cpr_api_services.dart';

import '../../../model/corporate/crp_gender_response/crp_gender_response.dart';

class GenderController extends GetxController {
  RxList<GenderModel> genderList = <GenderModel>[].obs;
  Rx<GenderModel?> selectedGender = Rx<GenderModel?>(null);

  Future<void> fetchGender(BuildContext context) async {
    await CprApiService().getRequestCrp<List<GenderModel>>(
      "GetGender",
      {}, // No params required
      (body) {
        return GenderModel.listFromJson(body);
      },
      context,
    ).then((data) {
      // Remove duplicates based on genderID
      final uniqueGenders = <int, GenderModel>{};
      for (final gender in data) {
        if (gender.genderID != null) {
          uniqueGenders[gender.genderID!] = gender;
        }
      }
      genderList.value = uniqueGenders.values.toList();
    });
  }

  void selectGender(GenderModel? model) {
    selectedGender.value = model;
  }
}
