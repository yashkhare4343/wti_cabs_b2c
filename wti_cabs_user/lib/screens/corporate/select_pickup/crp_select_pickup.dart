import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_select_pickup_controller/crp_select_pickup_controller.dart';
import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

import '../../../core/route_management/app_routes.dart';

class CrpSelectPickupScreen extends StatefulWidget {
  final String? selectedPickupType;
  
  const CrpSelectPickupScreen({super.key, this.selectedPickupType});

  @override
  State<CrpSelectPickupScreen> createState() => _CrpSelectPickupScreenState();
}

class _CrpSelectPickupScreenState extends State<CrpSelectPickupScreen> {

  final CrpSelectPickupController controller =
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
          'Select Pickup Location',
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
          // ---------------- SEARCH BAR ----------------
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
                  hintText: "Search for a location...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 22,
                  ),

                  // CLEAR BUTTON
                  suffixIcon: Obx(() =>
                  controller.hasSearchText.value
                      ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onPressed: () {
                      controller.searchController.clear();
                      controller.suggestions.clear();
                    },
                  )
                      : const SizedBox()),
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

          // ---------------- LOADING INDICATOR ----------------
          Obx(() => controller.isLoading.value
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
              : const SizedBox.shrink()),

          // ---------------- ERROR MESSAGE ----------------
          Obx(() => controller.errorMessage.value.isNotEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.errorMessage.value,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              : const SizedBox.shrink()),

          // ---------------- SUGGESTIONS LIST ----------------
          Expanded(
            child: Obx(() {
              final suggestions = controller.suggestions.value;

              // No results
              if (suggestions.isEmpty &&
                  controller.hasSearchText.value &&
                  !controller.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No locations found",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try searching with a different term",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Initial State
              if (suggestions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Search for a pickup location",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Start typing to see suggestions",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Show list
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.bgGrey2),
                itemBuilder: (context, index) {
                  final place = suggestions[index];
                  final isSelected =
                      controller.selectedPlace.value?.placeId == place.placeId;


                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isProcessingTap
                          ? null
                          : () {
                        if (_isProcessingTap) return;
                        setState(() => _isProcessingTap = true);

                        _handlePlaceSelection(context, place);

                        Future.delayed(
                            const Duration(milliseconds: 300), () {
                          if (mounted) {
                            setState(() => _isProcessingTap = false);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.mainButtonBg.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.mainButtonBg
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                place.isAirport
                                    ? Icons.flight_takeoff
                                    : Icons.location_on_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.primaryText.split(',').first.trim(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.mainButtonBg
                                          : const Color(0xFF1A1A1A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (place.secondaryText.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      place.secondaryText,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.mainButtonBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
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

    await controller.selectPlace(place);
    
    // Get the updated place with latitude and longitude from controller
    final updatedPlace = controller.selectedPlace.value;
    if (updatedPlace == null) {
      // If for some reason the place is null, use the original
      if (context.mounted) {
        GoRouter.of(context).pushReplacement(
          AppRoutes.cprBookingEngine,
          extra: {
            'selectedPickupType': widget.selectedPickupType,
            'selectedPickupPlace': place.toJson(),
          },
        );
      }
      return;
    }
    
    // Navigate back to booking engine and pass the selected place explicitly
    // This ensures the selected place with lat/lng is displayed correctly
    if (context.mounted) {
      GoRouter.of(context).pushReplacement(
        AppRoutes.cprBookingEngine,
        extra: {
          'selectedPickupType': widget.selectedPickupType,
          'selectedPickupPlace': updatedPlace.toJson(),
        },
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
