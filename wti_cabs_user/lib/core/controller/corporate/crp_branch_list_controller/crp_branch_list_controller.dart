import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:wti_cabs_user/core/controller/corporate/verify_corporate/verify_corporate_controller.dart';

import '../../../api/corporate/cpr_api_services.dart';

class CrpBranchListController extends GetxController {
  var isLoading = false.obs;
  var branches = <Map<String, dynamic>>[].obs;
  var branchNames = <String>[].obs;
  var selectedBranchName = RxnString();
  var selectedBranchId = RxnString();
  var count = 0.obs;
  final VerifyCorporateController verifyCorporateController = Get.put(VerifyCorporateController());

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

      print("✅ Selected Branch: $branchName");
      print("🏢 Branch ID: ${selectedBranchId.value}");
    }
  }
}
