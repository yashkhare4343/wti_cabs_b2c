import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/corporate/cpr_api_services.dart';
import '../../../model/corporate/crp_car_models/crp_car_models_response.dart';

class CrpInventoryListController extends GetxController {
  final CprApiService apiService = CprApiService();

  var isLoading = false.obs;
  var models = <CrpCarModel>[].obs;
  var selectedModel = Rx<CrpCarModel?>(null);

  Future<void> fetchCarModels(
    Map<String, dynamic> params,
    BuildContext? context, {
    bool skipAutoSelection = false,
  }) async {
    try {
      isLoading.value = true;

      final result =
          await apiService.getRequestCrp<CrpCarModelsResponse>(
        'GetAllCarModelsV1',
        params,
        (json) => CrpCarModelsResponse.fromJson(json),
        context!,
      );

      models.assignAll(result.models ?? []);

      // Only auto-select first model if not skipping auto-selection
      if (models.isNotEmpty && !skipAutoSelection) {
        selectedModel.value = models.first;
      }
    } catch (e) {
      debugPrint('CRP Car Models Fetch Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateSelected(CrpCarModel? item) {
    selectedModel.value = item;
  }
}


