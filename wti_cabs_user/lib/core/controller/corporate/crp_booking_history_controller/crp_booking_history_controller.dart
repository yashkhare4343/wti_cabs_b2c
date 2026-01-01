import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/corporate/cpr_api_services.dart';
import '../../../model/corporate/crp_booking_history/crp_booking_history_response.dart';
import '../../../services/storage_services.dart';
import '../crp_login_controller/crp_login_controller.dart';

class CrpBookingHistoryController extends GetxController {
  final CprApiService apiService = CprApiService();
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());

  var isLoading = false.obs;
  var bookings = <CrpBookingHistoryItem>[].obs;

  Future<void> fetchBookingHistory(
    BuildContext context, {
    String? branchId,
    int? monthId,
    int status = -1,
    int startRowIndex = 0,
    int maximumRows = 40,
    int providerId = 0,
    int fiscalYear = 0,
    String criteria = "",
  }) async {
    try {
      isLoading.value = true;

      // Use provided branchId or default to '0', don't fallback to storage
      final resolvedBranchId = branchId ?? '0';
      // Resolve guest id from storage or in-memory login info to avoid sending 0
      String? guestId = await StorageServices.instance.read('guestId');
      final loginGuestId = loginInfoController.crpLoginInfo.value?.guestID;
      if (guestId == null ||
          guestId.isEmpty ||
          guestId == '0' ||
          guestId == 'null') {
        if (loginGuestId != null && loginGuestId != 0) {
          guestId = loginGuestId.toString();
          await StorageServices.instance.save('guestId', guestId);
        }
      }

      final storedToken = await StorageServices.instance.read('crpKey');
      final loginToken = loginInfoController.crpLoginInfo.value?.key;
      final token = (storedToken != null && storedToken.isNotEmpty)
          ? storedToken
          : loginToken;
      final userEmail = await StorageServices.instance.read('email');

      // Use provided values or default to 0
      final resolvedMonthId = monthId ?? 0;
      final resolvedFiscal = fiscalYear;

      final params = {
        'branchID': resolvedBranchId,
        'uID': guestId ?? '0',
        'monthID': resolvedMonthId,
        'providerID': providerId,
        'status': status,
        'criteria': criteria.trim(),
        'fiscal': resolvedFiscal,
        'startRowIndex': startRowIndex,
        'maximumRows': maximumRows,
        if (token != null && token.isNotEmpty) 'token': token,
        if (userEmail != null && userEmail.isNotEmpty) 'user': userEmail,
      };

      final result = await apiService.getRequestCrp<CrpBookingHistoryResponse>(
        'GetBookingHistory',
        params,
        (json) => CrpBookingHistoryResponse.fromJson(json),
        context,
      );

      // Handle bStatus == false or null/empty array
      if (result.bStatus == false || result.history == null || result.history!.isEmpty) {
        bookings.clear();
      } else {
        bookings.assignAll(result.history!);
      }
    } catch (e) {
      debugPrint('CRP Booking History Fetch Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}



