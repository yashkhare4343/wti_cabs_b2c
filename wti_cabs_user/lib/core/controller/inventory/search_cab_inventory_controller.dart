import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';

import '../../../common_widget/loader/popup_loader.dart';
import '../../api/api_services.dart';
import '../../model/inventory/global_response.dart';
import '../../model/inventory/india_response.dart';
import '../../services/storage_services.dart';

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

    // ✅ Show loader (PopupLoader should be lightweight)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopupLoader(),
    );

    try {
      if (country.toLowerCase() == 'india') {
        final response = await ApiService().postRequestNew<IndiaResponse>(
          'globalSearch/searchSwitchBasedOnCountry',
          requestData,
          IndiaResponse.fromJson,
          context,
        );
        indiaData.value = response;
        globalData.value = null;
        await StorageServices.instance.save('currentTripCode', indiaData.value?.result?.tripType?.currentTripCode??'');


      }
      else {
        final response = await ApiService().postRequestNew<GlobalResponse>(
          'globalSearch/searchSwitchBasedOnCountry',
          requestData,
          GlobalResponse.fromJson,
          context,
        );
        globalData.value = response;
        indiaData.value = null;
        String currentTripCode = '';
        final resultList = globalData.value?.result;
        if (resultList != null && resultList.isNotEmpty) {
          for (var outer in resultList) {
            for (var item in outer) {
              final code = item.tripDetails?.currentTripCode;
              if (code != null && code.toString().isNotEmpty) {
                currentTripCode = code.toString();
                break;
              }
            }
            if (currentTripCode.isNotEmpty) break;
          }
        }
        // ✅ Store it
        await StorageServices.instance.save('currentTripCode', currentTripCode ?? '');
      }
      // ✅ Safely dismiss loader
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
        await Future.delayed(const Duration(milliseconds: 100)); // Let UI settle
      }

      // ✅ Navigate
      if (context.mounted) {
        GoRouter.of(context).push(AppRoutes.inventoryList);
      }
    } catch (e) {
      print("❌ Error fetching booking data: $e");

      // ✅ Ensure loader is dismissed on error
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Optional: show error
      Get.snackbar("Error", "Something went wrong, please try again.",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }


}
