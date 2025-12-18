import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../api/corporate/cpr_api_services.dart';
import '../../../model/corporate/register_response/register_response.dart';

class CrpRegisterController extends GetxController {
  final CprApiService crpApiService = CprApiService();

  Rx<CrpRegisterResponse?> crpRegisterResponse = Rx<CrpRegisterResponse?>(null);
  RxBool isLoading = false.obs;

  /// Verify corporate email using query parameters
  Future<void> verifyCrpRegister( Map<String, dynamic> params, BuildContext context) async {
    isLoading.value = true;
    try {
      // Construct query parameters as Map
      debugPrint('📤 [POST] validate-email');
      debugPrint('📦 Query Params: $params');

      final result = await crpApiService.postRequestParamsNew<CrpRegisterResponse>(
        'PostUpdateProfile_V2',   // endpoint
        params,             // send as query parameters
            (data) {            // fromJson callback
          if (data is String) return CrpRegisterResponse.fromString(data);
          if (data is Map && data['msg'] != null) {
            return CrpRegisterResponse.fromString(data['msg']);
          }
          return CrpRegisterResponse.fromString(data.toString());
        },
        context,
      );

      crpRegisterResponse.value = result;


      debugPrint('✅ [POST] validate-email Success');
      debugPrint('🧾 Response: ${result.toJson()}');
    } catch (e, st) {
      debugPrint('❌ [POST] validate-email Failed');
      debugPrint('Error: $e');
      debugPrint('Stack: $st');
    } finally {
      isLoading.value = false;
    }
  }
}
