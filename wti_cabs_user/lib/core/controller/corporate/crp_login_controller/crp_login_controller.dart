import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_login_response/crp_login_response.dart';
import '../../../api/corporate/cpr_api_services.dart';
import '../../../services/storage_services.dart';

class LoginInfoController extends GetxController {
  final CprApiService crpApiService = CprApiService();

  Rx<CrpLoginResponse?> crpLoginInfo = Rx<CrpLoginResponse?>(null);
  RxBool isLoading = false.obs;

  Future<void> fetchLoginInfo(
      Map<String, dynamic> params,
      BuildContext context
      ) async {
    isLoading.value = true;
    try {
      // 🔹 Print request info
      debugPrint('📤 GET API: Info/GetLoginInfo');
      debugPrint('📦 Query Params: $params');

      final result = await crpApiService.getRequestCrp<CrpLoginResponse>(
        'GetLoginInfoV1',
        params,
            (data) {
          // 🔹 Print raw response
          debugPrint('📥 Raw Response: $data');

          if (data is String) {
            debugPrint('🔹 Response is String, converting to JSON...');
            return CrpLoginResponse.fromJson({'sMessage': data});
          }

          if (data is Map<String, dynamic>) {
            debugPrint('🔹 Response is Map, parsing normally.');
            return CrpLoginResponse.fromJson(data);
          }

          debugPrint('🔹 Response is unknown type, parsing empty.');
          return CrpLoginResponse.fromJson({});
        },
        context,
      );

      // 🔹 Print parsed result
      debugPrint('✅ Parsed Response: ${result.toJson()}');

      crpLoginInfo.value = result;

      // Store EntityId and GenderId for prefilling in booking engine
      if (result.bStatus == true) {
        final storage = StorageServices.instance;
        // Store EntityId
        if (result.entityId != null && result.entityId != 0) {
          await storage.save('crpEntityId', result.entityId.toString());
          debugPrint('💾 Stored EntityId: ${result.entityId}');
        }
        // Store GenderId
        if (result.genderId != null && result.genderId != 0) {
          await storage.save('crpGenderId', result.genderId.toString());
          debugPrint('💾 Stored GenderId: ${result.genderId}');
        }
      }

      // // Show SnackBar based on status
      // if (crpLoginInfo.value?.bStatus == true) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Successfully Login!' ?? ''),
      //       backgroundColor: Colors.green,
      //     ),
      //   );
      // } else
        if (crpLoginInfo.value?.bStatus == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oops Login Failed!' ?? ''),
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
