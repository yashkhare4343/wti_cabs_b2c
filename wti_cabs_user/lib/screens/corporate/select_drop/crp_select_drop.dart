import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_select_drop_controller/crp_select_drop_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_select_pickup_controller/crp_select_pickup_controller.dart';
import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/route_management/corporate_page_transitions.dart';
import 'package:wti_cabs_user/common_widget/snackbar/custom_snackbar.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

import 'crp_drop_map_screen.dart';


class CrpSelectDropScreen extends StatefulWidget {
  final String? selectedPickupType;
  
  const CrpSelectDropScreen({super.key, this.selectedPickupType});

  @override
  State<CrpSelectDropScreen> createState() => _CrpSelectDropScreenState();
}

class _CrpSelectDropScreenState extends State<CrpSelectDropScreen> {
  final CrpSelectDropController controller =
  Get.put(CrpSelectDropController());
  final CrpSelectPickupController pickupController =
  Get.put(CrpSelectPickupController());

  bool _isProcessingTap = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Drop Location',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      // ---------------- BODY ----------------
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Type Location button (current screen)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // No-op: we are already on the type-location screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainButtonBg,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Type location',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Select on Map button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final SuggestionPlacesResponse? place =
                          await Navigator.push<SuggestionPlacesResponse?>(
                        context,
                        CorporatePageTransitions.pushRoute(
                          context,
                          const CrpDropMapScreen(),
                        ),
                      );
                      if (place != null) {
                        _handlePlaceSelection(context, place);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.mainButtonBg,
                        width: 1,
                      ),
                      foregroundColor: AppColors.mainButtonBg,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Select on map',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ---------------- SEARCH BAR (PLAIN TEXT) ----------------
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller.searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Enter drop location...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.edit_location_alt_outlined,
                    color: Colors.grey.shade600,
                    size: 22,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onPressed: () {
                      controller.searchController.clear();
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),

          const Spacer(),

          // ---------------- CONFIRM BUTTON FOR TYPED LOCATION ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final text = controller.searchController.text.trim();
                  if (text.isEmpty) {
                    CustomFailureSnackbar.show(context, 'Please enter a drop location', duration: const Duration(seconds: 2));
                    return;
                  }

                  final place = SuggestionPlacesResponse(
                    primaryText: text,
                    secondaryText: '',
                    placeId: '',
                    types: const [],
                    terms: const [],
                    city: '',
                    state: '',
                    country: '',
                    isAirport: false,
                    latitude: null,
                    longitude: null,
                    placeName: text,
                  );

                  // Update controller first
                  controller.selectedPlace.value = place;

                  // Navigate to booking engine with the selected place
                  // This works whether coming from booking engine or home screen
                  final currentPickup = pickupController.selectedPlace.value;
                  
                  GoRouter.of(context).go(
                    AppRoutes.cprBookingEngine,
                    extra: {
                      'selectedPickupType': widget.selectedPickupType,
                      'selectedDropPlace': place.toJson(),
                      if (currentPickup != null) 'selectedPickupPlace': currentPickup.toJson(),
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainButtonBg,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Confirm drop',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HANDLE SELECTION ----------------
  Future<void> _handlePlaceSelection(
      BuildContext context, SuggestionPlacesResponse place) async {
    // Fetch place details and store lat/lng
    FocusScope.of(context).unfocus();

    // Update the controller first
    await controller.selectPlace(place);
    
    // Navigate to booking engine with the selected place
    // This works whether coming from booking engine or home screen
    if (context.mounted) {
      final updatedPlace = controller.selectedPlace.value;
      final currentPickup = pickupController.selectedPlace.value;
      final placeToUse = updatedPlace ?? place;
      
      GoRouter.of(context).go(
        AppRoutes.cprBookingEngine,
        extra: {
          'selectedPickupType': widget.selectedPickupType,
          'selectedDropPlace': placeToUse.toJson(),
          if (currentPickup != null) 'selectedPickupPlace': currentPickup.toJson(),
        },
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}



