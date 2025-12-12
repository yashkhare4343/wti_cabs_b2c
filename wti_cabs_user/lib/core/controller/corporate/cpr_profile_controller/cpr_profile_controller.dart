import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_login_response/crp_login_response.dart';
import 'package:wti_cabs_user/screens/corporate/cpr_profile_response/cpr_profile_response.dart';
import '../../../api/corporate/cpr_api_services.dart';

class CprProfileController extends GetxController {
  final CprApiService crpApiService = CprApiService();

  Rx<CprProfileResponse?> crpProfileInfo = Rx<CprProfileResponse?>(null);
  RxBool isLoading = false.obs;

  Future<void> fetchProfileInfo(
      Map<String, dynamic> params,
      BuildContext context
      ) async {
    isLoading.value = true;
    try {
      // 🔹 Print request info
      debugPrint('📤 GET API: Info/GetUserProfileWeb');
      debugPrint('📦 Query Params: $params');

      final result = await crpApiService.getRequestCrp<CprProfileResponse>(
        'GetUserProfileWeb',
        params,
            (data) {
          // 🔹 Print raw response
          debugPrint('📥 Raw Response: $data');

          if (data is String) {
            debugPrint('🔹 Response is String, converting to JSON...');
            return CprProfileResponse.fromJson({'sMessage': data});
          }

          if (data is Map<String, dynamic>) {
            debugPrint('🔹 Response is Map, parsing normally.');
            return CprProfileResponse.fromJson(data);
          }

          debugPrint('🔹 Response is unknown type, parsing empty.');
          return CprProfileResponse.fromJson({});
        },
        context,
      );

      // 🔹 Print parsed result
      debugPrint('✅ Parsed Response: ${result.toJson()}');

      crpProfileInfo.value = result;

      // // Show SnackBar based on status
      // if (crpLoginInfo.value?.bStatus == true) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Successfully Login!' ?? ''),
      //       backgroundColor: Colors.green,
      //     ),
      //   );
      // } else
      if (crpProfileInfo.value?.bStatus == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong!' ?? ''),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('❌ Error fetching LoginInfo: $e');
      debugPrint('📄 Stacktrace: $st');
    } finally {
      isLoading.value = false;
    }
  }
}
