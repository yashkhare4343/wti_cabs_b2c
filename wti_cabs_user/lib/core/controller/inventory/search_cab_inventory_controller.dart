import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_services.dart';
import '../../model/inventory/global_response.dart';
import '../../model/inventory/india_response.dart';
import '../../services/storage_services.dart';

class SearchCabInventoryController extends GetxController {
  Rx<IndiaResponse?> indiaData = Rx<IndiaResponse?>(null);
  Rx<GlobalResponse?> globalData = Rx<GlobalResponse?>(null);
  RxBool isLoading = false.obs;

  var tripCode = ''.obs;
  var previousTripCode = ''.obs;

  static const Map<String, String> tripMessages = {
    '0': 'Your trip type changed to Outstation One Trip.',
    '1': 'Your trip type changed to Outstation Round Trip.',
    '2': 'Your trip type changed to Airport Trip.',
    '3': 'Your trip type changed to Local.',
  };

  Future<void> loadTripCode() async {
    tripCode.value = await StorageServices.instance.read('currentTripCode') ?? '';
    previousTripCode.value = await StorageServices.instance.read('previousTripCode') ?? '';
  }

  /// 🔹 Show trip changed dialog instead of snackbar
  void showTripChangedDialog(BuildContext context, String newTripCode) {
    final message = tripMessages[newTripCode] ?? "Trip type updated.";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.update_outlined, color: Colors.blueAccent, size: 22),
            SizedBox(width: 8),
            Text(
              "Trip Updated",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Check if trip code changed
  Future<void> checkTripCodeChange(BuildContext context) async {
    await loadTripCode();

    if (tripCode.isNotEmpty &&
        tripCode.value != previousTripCode.value) {
      // showTripChangedDialog(context, tripCode.value);
    }
  }

  /// 🔹 Fetch booking data
  Future<void> fetchBookingData({
    required String country,
    required Map<String, dynamic> requestData,
    required BuildContext context,
    bool isSecondPage = false,
  }) async {
    isLoading.value = true;

    try {
      // Old trip codes
      final oldCurrent = await StorageServices.instance.read('currentTripCode') ?? '';
      final oldPrevious = await StorageServices.instance.read('previousTripCode') ?? '';

      String newCurrent = '';
      String newPrevious = '';

      if (country.toLowerCase() == 'india') {
        final response = await ApiService().postRequestNew<IndiaResponse>(
          'globalSearch/searchSwitchBasedOnCountry',
          requestData,
          IndiaResponse.fromJson,
          context,
        );
        indiaData.value = response;
        globalData.value = null;

        newCurrent = response.result?.tripType?.currentTripCode ?? '';
        newPrevious = response.result?.tripType?.previousTripCode ?? '';
      } else {
        final response = await ApiService().postRequestNew<GlobalResponse>(
          'globalSearch/searchSwitchBasedOnCountry',
          requestData,
          GlobalResponse.fromJson,
          context,
        );
        globalData.value = response;
        indiaData.value = null;

        // Extract from global response
        final resultList = response.result;
        if (resultList != null && resultList.isNotEmpty) {
          for (var outer in resultList) {
            for (var item in outer) {
              newCurrent = item.tripDetails?.currentTripCode.toString() ?? newCurrent;
              newPrevious = item.tripDetails?.previousTripCode ?? newPrevious;
            }
          }
        }
      }

      // ✅ Compare & show dialog if trip changed
      if (newCurrent.isNotEmpty && newCurrent != oldCurrent) {
        // showTripChangedDialog(context, newCurrent);
      }

      // Save updated codes
      await StorageServices.instance.save('currentTripCode', newCurrent);
      await StorageServices.instance.save('previousTripCode', newPrevious);

      tripCode.value = newCurrent;
      previousTripCode.value = newPrevious;

    } catch (e) {
      debugPrint("❌ Error fetching booking data: $e");
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      Get.snackbar("Error", "Something went wrong, please try again.",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
