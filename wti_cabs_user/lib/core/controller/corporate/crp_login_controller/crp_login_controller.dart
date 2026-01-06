import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_login_response/crp_login_response.dart';
import 'package:wti_cabs_user/common_widget/snackbar/custom_snackbar.dart';
import '../../../api/corporate/cpr_api_services.dart';
import '../../../services/storage_services.dart';

class LoginInfoController extends GetxController {
  final CprApiService crpApiService = CprApiService();

  Rx<CrpLoginResponse?> crpLoginInfo = Rx<CrpLoginResponse?>(null);
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _restoreLoginInfoFromStorage();
  }

  /// Restore login info from storage after app restart
  Future<void> _restoreLoginInfoFromStorage() async {
    try {
      final storage = StorageServices.instance;
      final crpKey = await storage.read('crpKey');
      
      // Only restore if we have a valid token
      if (crpKey != null && crpKey.isNotEmpty) {
        final guestId = await storage.read('guestId');
        final guestName = await storage.read('guestName') ?? '';
        final branchId = await storage.read('branchId') ?? '0';
        final corpId = await storage.read('crpId') ?? '0';
        final genderIdStr = await storage.read('crpGenderId') ?? '1';
        final entityIdStr = await storage.read('crpEntityId') ?? '1';
        final payModeId = await storage.read('crpPayModeId') ?? '0';
        final carProviders = await storage.read('crpCarProviders') ?? '0';
        final advancedHourStr = await storage.read('crpAdvancedHourToConfirm') ?? '4';

        // Reconstruct CrpLoginResponse from stored data
        crpLoginInfo.value = CrpLoginResponse(
          key: crpKey,
          bStatus: true,
          sMessage: '',
          guestID: int.tryParse(guestId ?? '0') ?? 0,
          guestName: guestName,
          branchID: branchId,
          subbranchID: 0,
          lastRideBookingRatingFlag: false,
          corpID: corpId,
          payModeID: payModeId,
          carProviders: carProviders,
          logoPath: '',
          genderId: int.tryParse(genderIdStr) ?? 1,
          entityId: int.tryParse(entityIdStr) ?? 1,
          advancedHourToConfirm: int.tryParse(advancedHourStr) ?? 4,
        );
        
        debugPrint('✅ Restored crpLoginInfo from storage: guestName=${crpLoginInfo.value?.guestName}');
      }
    } catch (e) {
      debugPrint('⚠️ Error restoring login info from storage: $e');
    }
  }

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

      // Show SnackBar based on status
      if (crpLoginInfo.value?.bStatus == true) {
        // CustomSuccessSnackbar.show(context, 'Successfully Login!');
      } else if (crpLoginInfo.value?.bStatus == false) {
        CustomFailureSnackbar.show(context, 'Oops Login Failed!');
      }
    } catch (e, st) {
      debugPrint('❌ Error fetching LoginInfo: $e');
      debugPrint('📄 Stacktrace: $st');
    } finally {
      isLoading.value = false;
    }
  }
}
