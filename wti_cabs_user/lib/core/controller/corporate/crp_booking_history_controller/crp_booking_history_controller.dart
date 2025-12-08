import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/corporate/cpr_api_services.dart';
import '../../../model/corporate/crp_booking_history/crp_booking_history_response.dart';
import '../../../services/storage_services.dart';

class CrpBookingHistoryController extends GetxController {
  final CprApiService apiService = CprApiService();

  var isLoading = false.obs;
  var bookings = <CrpBookingHistoryItem>[].obs;

  Future<void> fetchBookingHistory(
    BuildContext context, {
    int? monthId,
    int status = -1,
    int startRowIndex = 0,
    int maximumRows = 10,
    int providerId = 1,
    int fiscalYear = 2026,
    String criteria = "",
  }) async {
    try {
      isLoading.value = true;

      final branchId = await StorageServices.instance.read('branchId');
      final userId = await StorageServices.instance.read('guestId');
      final token = await StorageServices.instance.read('crpKey');
      final userEmail = await StorageServices.instance.read('email');

      final now = DateTime.now();
      final resolvedMonthId = monthId ?? now.month;
      final resolvedFiscal = fiscalYear == 0 ? now.year : fiscalYear;

      final params = {
        'branchID': branchId ?? '0',
        'uID': userId ?? '0',
        'monthID': resolvedMonthId,
        'providerID': providerId,
        'status': status,
        'criteria': criteria,
        'fiscal': 2026,
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

      bookings.assignAll(result.history ?? []);
    } catch (e) {
      debugPrint('CRP Booking History Fetch Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

