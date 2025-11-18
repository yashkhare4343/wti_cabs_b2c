import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/corporate/cpr_api_services.dart';
import '../../../model/corporate/crp_services/crp_services_response.dart';

class CrpServicesController extends GetxController {
  final CprApiService apiService = CprApiService();

  /// Holds the final parsed API response
  Rxn<RunTypeResponse> runTypes = Rxn<RunTypeResponse>();

  /// Loading state
  RxBool isLoading = false.obs;

  /// Error message
  RxString errorMessage = ''.obs;

  /// Fetch Run Types from the API
  Future<void> fetchRunTypes(Map<String, dynamic> params, BuildContext? context) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final response = await apiService.getRequestCrp<RunTypeResponse>(
        "GetRunType",
        params,
        // {},
            (json) => RunTypeResponse.fromJson(json),
        context!,                              // required
      );


      runTypes.value = response;

    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('RunType API Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // /// Reload Run Types
  // Future<void> refreshRunTypes() async {
  //   await fetchRunTypes();
  // }
}
