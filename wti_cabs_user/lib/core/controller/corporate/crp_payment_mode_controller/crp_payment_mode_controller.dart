import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../api/corporate/cpr_api_services.dart';
import '../../../model/corporate/crp_payment_method/crp_payment_mode.dart';

class PaymentModeController extends GetxController {
  var isLoading = false.obs;
  var modes = <PaymentModeItem>[].obs;
  var selectedMode = Rx<PaymentModeItem?>(null);

  final CprApiService apiService = CprApiService();

  Future<void> fetchPaymentModes(Map<String,dynamic> params, BuildContext? context) async {
    try {
      isLoading.value = true;

      final result = await apiService.getRequestCrp<PaymentModeResponse>(
        "GetPayMode",
        params,
            (json) => PaymentModeResponse.fromJson(json),
        context!,
      );

      modes.assignAll(result.modes ?? []);

      if (modes.isNotEmpty) {
        selectedMode.value = modes.first; // Default
      }
    } catch (e) {
      debugPrint("Payment Mode Fetch Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void updateSelected(PaymentModeItem? item) {
    selectedMode.value = item;
  }
}
