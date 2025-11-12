import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'booking_validation.dart';
import 'package:timezone/timezone.dart' as tz;

import 'choose_pickup/choose_pickup_controller.dart';

class BookingRideController extends GetxController {
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  final RxBool isSwitching = false.obs;
  Rx<DateTime?> selectedDateTime = Rx<DateTime?>(null);
  RxInt? offsetMinutes = RxInt(0);// ✅ stores timezone offset
  RxString selectedLocalDate = ''.obs;
  RxString selectedLocalTime = ''.obs;
  RxBool isInventoryPage =  false.obs;
  RxBool fromHomePage = false.obs;
  final RxBool isPopupOpen = false.obs;
  final RxBool shouldShowPopup = true.obs;
  // inventory req data
  final RxMap<String, dynamic> requestData = <String, dynamic>{}.obs;


  // Core datetime values
  Rx<DateTime> localStartTime = DateTime.now().obs;
  Rx<DateTime> utcStartTime = DateTime.now().obs;
  Rx<DateTime> localEndTime = DateTime.now().obs;
  Rx<DateTime> utcEndTime = DateTime.now().obs;

  // Prefilled text
  RxString prefilled = "".obs;
  RxString prefilledDrop = "".obs;
  RxBool isInvalidTime = false.obs;

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

  /// Trigger to reset the date picker from anywhere
  var resetDateTrigger = false.obs;

  void resetDate() {
    resetDateTrigger.value = true;
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

  // convert local to utc based on timezone
  String convertLocalToUtc() {
    // Get location by name (e.g. Asia/Kolkata, Europe/London)
    final placeSearchController = Get.find<PlaceSearchController>();

    // read timezone from API response stored in controller
    final timeZone = placeSearchController.findCntryDateTimeResponse.value?.timeZone;
    final location = tz.getLocation(timeZone!);

    // Interpret the localDateTime as being in that timezone
    final tz.TZDateTime tzDateTime = tz.TZDateTime.from(localStartTime.value, location);

    // Convert to UTC
    final utcDateTime = tzDateTime.toUtc();

    // Format as ISO8601 and force `Z` at the end
    return utcDateTime.toIso8601String();
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
