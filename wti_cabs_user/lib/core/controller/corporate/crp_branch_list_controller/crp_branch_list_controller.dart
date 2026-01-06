import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:wti_cabs_user/core/controller/corporate/verify_corporate/verify_corporate_controller.dart';

import '../../../api/corporate/cpr_api_services.dart';
import '../../../services/storage_services.dart';

class CrpBranchListController extends GetxController {
  var isLoading = false.obs;
  var branches = <Map<String, dynamic>>[].obs;
  var branchNames = <String>[].obs;
  var selectedBranchName = RxnString();
  var selectedBranchId = RxnString();
  var count = 0.obs;
  final VerifyCorporateController verifyCorporateController = Get.put(VerifyCorporateController());

  @override
  void onInit() {
    super.onInit();
    _restoreSelectedBranch();
  }

  /// Restore selected branch from storage
  Future<void> _restoreSelectedBranch() async {
    try {
      final storedBranchName = await StorageServices.instance.read('selectedBranchName');
      final storedBranchId = await StorageServices.instance.read('selectedBranchId');
      
      if (storedBranchName != null && storedBranchName.isNotEmpty) {
        selectedBranchName.value = storedBranchName;
        if (storedBranchId != null && storedBranchId.isNotEmpty) {
          selectedBranchId.value = storedBranchId;
        }
        print('✅ Restored selected branch from storage: $storedBranchName');
      }
    } catch (e) {
      print('⚠️ Error restoring branch from storage: $e');
    }
  }

  Future<void> fetchBranches(String corpId) async {
    isLoading.value = true;
    // if(verifyCorporateController.cprVerifyResponse.value?.code == 1){
    //    branches = <Map<String, dynamic>>[].obs;
    //   branchNames = <String>[].obs;
    //   return;
    // }
    try {
      final url = Uri.parse("${CprApiService().baseUrl}/GetBranches_Reg?CorpID=$corpId");
      print("📡 Fetching from: $url");

      // Use centralized retry + 401 auto re-login logic
      final response = await CprApiService()
          .sendRequestWithRetry(() => http.get(url));
      print("📥 Raw API Response: ${response.body}");

      if (response.statusCode == 200) {
        dynamic decoded = jsonDecode(response.body);

        // 🔄 If API returns a string (like "\"[...]\""), decode again
        if (decoded is String) {
          print("⚠️ Response is a stringified JSON — decoding again...");
          decoded = jsonDecode(decoded);
        }

        if (decoded is List) {
          branches.value = List<Map<String, dynamic>>.from(decoded);
          branchNames.value =
              branches.map((b) => b['BranchName'].toString()).toList();

          print("🏢 Found ${branches.length} branches");
          for (final b in branches) {
            print("➡️ ${b['BranchName']} (ID: ${b['BranchID']})");
          }
        } else {
          print("❌ Unexpected response format: ${decoded.runtimeType}");
        }
      } else {
        print("❌ Server error: ${response.statusCode}");
      }
    } catch (e, stack) {
      print("💥 Exception while fetching branches: $e");
      print(stack);
    } finally {
      isLoading.value = false;
    }
  }

  void selectBranch(String? branchName) {
    selectedBranchName.value = branchName;

    if (branchName != null) {
      final branch = branches.firstWhere(
            (b) => b['BranchName'] == branchName,
        orElse: () => branches.first,
      );

      selectedBranchId.value = branch['BranchID'].toString();

      // Persist to storage
      _saveSelectedBranch(branchName, selectedBranchId.value);

      print("✅ Selected Branch: $branchName");
      print("🏢 Branch ID: ${selectedBranchId.value}");
    } else {
      // Clear storage if branch is deselected
      _clearSelectedBranch();
    }
  }

  /// Save selected branch to storage
  Future<void> _saveSelectedBranch(String branchName, String? branchId) async {
    try {
      await StorageServices.instance.save('selectedBranchName', branchName);
      if (branchId != null) {
        await StorageServices.instance.save('selectedBranchId', branchId);
      }
    } catch (e) {
      print('⚠️ Error saving branch to storage: $e');
    }
  }

  /// Clear selected branch from storage
  Future<void> _clearSelectedBranch() async {
    try {
      await StorageServices.instance.delete('selectedBranchName');
      await StorageServices.instance.delete('selectedBranchId');
    } catch (e) {
      print('⚠️ Error clearing branch from storage: $e');
    }
  }
}
