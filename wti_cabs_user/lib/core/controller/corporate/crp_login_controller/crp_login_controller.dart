import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_login_response/crp_login_response.dart';
import '../../../api/corporate/cpr_api_services.dart';
import '../../../services/storage_services.dart';

class LoginInfoController extends GetxController {
  final CprApiService crpApiService = CprApiService();

  Rx<CrpLoginResponse?> crpLoginInfo = Rx<CrpLoginResponse?>(null);
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load saved corporate login info from storage
    loadFromStorage();
  }

  /// Load corporate login info from storage
  Future<void> loadFromStorage() async {
    try {
      final crpKey = await StorageServices.instance.read('crpKey');
      final crpId = await StorageServices.instance.read('crpId');
      final branchId = await StorageServices.instance.read('branchId');
      final guestId = await StorageServices.instance.read('guestId');
      final guestName = await StorageServices.instance.read('guestName');

      // If crpKey exists, reconstruct the response object
      if (crpKey != null && crpKey.isNotEmpty) {
        crpLoginInfo.value = CrpLoginResponse(
          key: crpKey,
          bStatus: true,
          sMessage: '',
          guestID: int.tryParse(guestId ?? '0') ?? 0,
          guestName: guestName ?? '',
          branchID: branchId ?? '0',
          subbranchID: 0,
          lastRideBookingRatingFlag: false,
          corpID: crpId ?? '0',
          payModeID: '0',
          carProviders: '0',
          logoPath: '',
        );
        debugPrint('✅ Loaded corporate login info from storage');
      }
    } catch (e) {
      debugPrint('❌ Error loading corporate login info from storage: $e');
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
        'GetLoginInfo',
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
