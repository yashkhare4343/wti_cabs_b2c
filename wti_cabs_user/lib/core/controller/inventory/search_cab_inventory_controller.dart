// controllers/booking_response_controller.dart
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
      final response = await ApiService().postRequest('globalSearch/searchSwitchBasedOnCountry', requestData, context);
      print('fetch cab inventory $requestData');

      if (country.toLowerCase() == 'india') {
        indiaData.value = IndiaResponse.fromJson(response);
        globalData.value = null;
        print('response india body is : $indiaData');
      } else {
        globalData.value = GlobalResponse.fromJson(response);
        indiaData.value = null;
        print('response global body is : $globalData');

      }
    } catch (e) {
      print("❌ Error fetching booking data: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
