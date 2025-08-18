import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'booking_validation.dart';

class BookingRideController extends GetxController {
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Core datetime values
  Rx<DateTime> localStartTime = DateTime.now().obs;
  Rx<DateTime> utcStartTime = DateTime.now().obs;
  Rx<DateTime> localEndTime = DateTime.now().obs;
  Rx<DateTime> utcEndTime = DateTime.now().obs;

  // Prefilled text
  RxString prefilled = "".obs;
  RxString prefilledDrop = "".obs;

  // New: pickup & drop
  Rx<DateTime?> pickupDateTime = Rx<DateTime?>(null);
  Rx<DateTime?> dropDateTime = Rx<DateTime?>(null);

  var selectedIndex = 0.obs;
  final tabNames = ["airport", "outstation", "rental"];

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  var selectedPackage = '4 hrs 40 kms'.obs;


  void setTabByName(String name) {
    final index = tabNames.indexOf(name.toLowerCase());
    if (index != -1) {
      selectedIndex.value = index;
    }
  }

  String get currentTabName => tabNames[0];
  final BookingValidation controller = Get.put(BookingValidation());

  void showErrorSnackbar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }



  @override
  void onInit() {
    super.onInit();
  }

  // ✅ Update local start time from string
  void updateLocalStartTimeFromString(String dateTimeString) {
    try {
      localStartTime.value = DateTime.parse(dateTimeString);
    } catch (e) {
      errorMessage.value = "Invalid date time string: $e";
    }
  }

  // ✅ Set or update pickup datetime
  void updatePickupDateTime(DateTime newPickupDateTime) {
    pickupDateTime.value = newPickupDateTime;

    final currentDrop = dropDateTime.value;
    final minValidDrop = newPickupDateTime.add(const Duration(hours: 4));

    // Reset drop only if it's invalid
    if (currentDrop != null && currentDrop.isBefore(minValidDrop)) {
      dropDateTime.value = minValidDrop;
    }

    // First-time set
    if (dropDateTime.value == null) {
      dropDateTime.value = minValidDrop;
    }
  }

  // // ✅ Update drop date, keeping time
  // void updateDropDate(DateTime newDate) {
  //   final oldDrop = dropDateTime.value ?? pickupDateTime.value?.add(Duration(hours: 4)) ?? DateTime.now();
  //   final updatedDrop = DateTime(newDate.year, newDate.month, newDate.day, oldDrop.hour, oldDrop.minute);
  //   updateDropDateTime(updatedDrop);
  // }
  //
  // // ✅ Update drop time, keeping date
  // void updateDropTime(TimeOfDay newTime) {
  //   final oldDrop = dropDateTime.value ?? pickupDateTime.value?.add(Duration(hours: 4)) ?? DateTime.now();
  //   final updatedDrop = DateTime(oldDrop.year, oldDrop.month, oldDrop.day, newTime.hour, newTime.minute);
  //   updateDropDateTime(updatedDrop);
  // }
  //
  // // ✅ Final drop datetime validation
  // void updateDropDateTime(DateTime newDropDateTime) {
  //   final pickup = pickupDateTime.value;
  //   if (pickup != null && newDropDateTime.isBefore(pickup.add(Duration(hours: 4)))) {
  //     errorMessage.value = "Drop must be at least 4 hours after pickup";
  //     return;
  //   }
  //   dropDateTime.value = newDropDateTime;
  // }
}
