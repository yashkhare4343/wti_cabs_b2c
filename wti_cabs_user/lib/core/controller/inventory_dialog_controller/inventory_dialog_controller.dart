import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common_widget/buttons/main_button.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../../services/storage_services.dart';
import '../inventory/search_cab_inventory_controller.dart';

class TripController extends GetxController {
  final searchCabInventoryController = Get.find<SearchCabInventoryController>();

  final number = "".obs;
  final _hasShownDialogForTrip = <String>{}; // Tracks popups for current session
  String? lastStoredTripCode; // Trip code saved in storage

  final tripMessages = {
    '0': 'Your selected trip type has changed to Outstation One Trip.',
    '1': 'Your selected trip type has changed to Outstation Round Trip.',
    '2': 'Your selected trip type has changed to Airport Trip.',
    '3': 'Your selected trip type has changed to Local.',
  };

  @override
  void onInit() {
    super.onInit();
    _loadStoredTripCode();
  }

  /// Loads last stored trip code from persistent storage
  Future<void> _loadStoredTripCode() async {
    lastStoredTripCode = await StorageServices.instance.read('currentTripCode');
    debugPrint('🔹 Loaded last stored trip code: $lastStoredTripCode');
  }

  /// Resets the in-session popup tracker
  void resetTripDialogState() {
    _hasShownDialogForTrip.clear();
  }

  Future<void> loadInitialData(BuildContext context) async {
    final tripType = searchCabInventoryController.indiaData.value?.result?.tripType;

    final tripCode = tripType?.currentTripCode;
    final packageId = tripType?.packageId;
    final previousTripCode = tripType?.previousTripCode;

    // Skip if no valid trip data
    if (tripCode == null || previousTripCode == null) return;

    // Skip if same as last stored trip code (avoids "last search" popup)
    if (tripCode == lastStoredTripCode) {
      debugPrint('⚠ Skipping popup — same as last stored trip code');
      return;
    }

    // Show dialog only if trip actually changed AND not shown this session
    if (tripCode != previousTripCode && !_hasShownDialogForTrip.contains(tripCode)) {
      _hasShownDialogForTrip.add(tripCode);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final message = tripMessages[tripCode] ?? 'Your selected trip type has changed.';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            elevation: 10,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: [
                const Icon(Icons.update_outlined, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 10),
                Text(
                  'Trip Updated',
                  style: CommonFonts.greyText3Bold,
                ),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: MainButton(
                  text: 'Okay',
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      });

      // Save new trip code to storage so it won't show next time
      await StorageServices.instance.save('currentTripCode', tripCode);
      lastStoredTripCode = tripCode;
    }

    // Parse packageId if Local (3)
    if (tripCode == '3' && packageId != null) {
      try {
        number.value = packageId.split('_')[1];
      } catch (e) {
        debugPrint("❌ Error parsing packageId: $e");
      }
    }
  }
}
