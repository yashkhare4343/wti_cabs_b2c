import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/corporate/cpr_api_services.dart';
import '../../../model/corporate/crp_car_models/crp_car_models_response.dart';

class CrpInventoryListController extends GetxController {
  final CprApiService apiService = CprApiService();

  var isLoading = false.obs;
  var models = <CrpCarModel>[].obs;
  var selectedModel = Rx<CrpCarModel?>(null);

  // #region agent log
  void _agentLog({
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, dynamic>? data,
    String runId = 'run1',
  }) {
    try {
      final payload = <String, dynamic>{
        'sessionId': 'debug-session',
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data ?? <String, dynamic>{},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      // 1) Best-effort local file write
      try {
        File('/Users/asndtechnologies/Documents/yash/wti_cabs_b2c/wti_cabs_user/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(payload)}\n',
                mode: FileMode.append, flush: true);
      } catch (_) {}

      // 2) Best-effort HTTP ingest
      try {
        final baseUri = Uri.parse(
            'http://127.0.0.1:7242/ingest/7d4e7254-f04b-431d-ae17-5bdc7357e72b');
        final effectiveUri =
            Platform.isAndroid ? baseUri.replace(host: '10.0.2.2') : baseUri;
        http
            .post(
              effectiveUri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .catchError((_) {});
      } catch (_) {}
    } catch (_) {}
  }
  // #endregion

  Future<void> fetchCarModels(
    Map<String, dynamic> params,
    BuildContext? context, {
    bool skipAutoSelection = false,
  }) async {
    try {
      isLoading.value = true;

      // #region agent log
      _agentLog(
        hypothesisId: 'C',
        location: 'crp_inventory_list_controller.dart:fetchCarModels',
        message: 'Fetching car models',
        data: {
          'paramsKeys': params.keys.toList(),
          'runTypeID': params['RunTypeID'],
          'runTypeID_lower': params['runTypeID'],
          'corpId': params['CorpID'],
          'branchId': params['BranchID'],
          'skipAutoSelection': skipAutoSelection,
        },
      );
      // #endregion

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

      // #region agent log
      _agentLog(
        hypothesisId: 'C',
        location: 'crp_inventory_list_controller.dart:fetchCarModels',
        message: 'Fetched car models result',
        data: {
          'modelsCount': models.length,
          'uniqueMakeIds': models.map((m) => m.makeId).toSet().length,
          'selectedMakeId': selectedModel.value?.makeId,
        },
      );
      // #endregion
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


