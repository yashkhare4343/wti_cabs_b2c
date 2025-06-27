import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_services.dart';
import '../../model/inventory/global_response.dart';
import '../../model/inventory/india_response.dart';

class SearchCabInventoryController extends GetxController {
  Rx<IndiaResponse?> indiaData = Rx<IndiaResponse?>(null);
  Rx<GlobalResponse?> globalData = Rx<GlobalResponse?>(null);
  RxBool isLoading = false.obs;

  /// Fetch booking data based on the given country and request body
  Future<void> fetchBookingData({
    required String country,
    required Map<String, dynamic> requestData,
    required BuildContext context,
  }) async {
    isLoading.value = true;

    try {
      print('fetch cab inventory $requestData');

      if (country.toLowerCase() == 'india') {
        final response = await ApiService().postRequestNew<IndiaResponse>(
          'globalSearch/searchSwitchBasedOnCountry',
          requestData,
          IndiaResponse.fromJson,
          context,
        );
        indiaData.value = response;
        globalData.value = null;
        print('✅ India response parsed: ${indiaData.value}');
      } else {
        final response = await ApiService().postRequestNew<GlobalResponse>(
          'globalSearch/searchSwitchBasedOnCountry',
          requestData,
          GlobalResponse.fromJson,
          context,
        );
        globalData.value = response;
        indiaData.value = null;
        print('✅ Global response parsed: ${globalData.value}');
      }
    } catch (e) {
      print("❌ Error fetching booking data: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
