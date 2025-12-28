import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/controller/corporate/crp_select_drop_controller/crp_select_drop_controller.dart';
import '../../../core/controller/corporate/crp_select_pickup_controller/crp_select_pickup_controller.dart';
import '../../../core/model/booking_engine/suggestions_places_response.dart';
import '../../../core/route_management/app_routes.dart';
import '../../../core/route_management/corporate_page_transitions.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import 'crp_drop_map_screen.dart';

class CrpDropSearchScreen extends StatefulWidget {
  final bool? fromCrpHomeScreen;
  
  const CrpDropSearchScreen({super.key, this.fromCrpHomeScreen});

  @override
  State<CrpDropSearchScreen> createState() => _CrpDropSearchScreenState();
}

class _CrpDropSearchScreenState extends State<CrpDropSearchScreen> {
  final CrpSelectDropController crpSelectDropController =
      Get.put(CrpSelectDropController());
  final CrpSelectPickupController pickupController =
      Get.put(CrpSelectPickupController());

  Future<void> _handlePlaceSelection(SuggestionPlacesResponse place) async {
    // Update the controller first
    await crpSelectDropController.selectPlace(place);
    
    // Navigate based on where we came from
    if (context.mounted) {
      // Get the updated place from controller, or use the passed place as fallback
      final selected = crpSelectDropController.selectedPlace.value ?? place;
      final currentPickup = pickupController.selectedPlace.value;
      
      // Check if coming from home screen
      if (widget.fromCrpHomeScreen == true) {
        // Coming from home screen - navigate to booking engine with drop location
        GoRouter.of(context).push(
          AppRoutes.cprBookingEngine,
          extra: {
            'selectedDropPlace': selected.toJson(),
            if (currentPickup != null) 'selectedPickupPlace': currentPickup.toJson(),
          },
        );
      } else {
        // Coming from booking engine - pop back
        // The booking engine will read from the controller via Obx()
        GoRouter.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.8,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.polylineGrey),
        title: Text(
          'Search drop location',
          style: CommonFonts.appBarText,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Choose location on map button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Obx(
              () => TextField(
                controller: crpSelectDropController.searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter drop location',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      crpSelectDropController.hasSearchText.value &&
                              crpSelectDropController
                                  .searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: AppColors.greyText2,
                              ),
                              onPressed: () {
                                crpSelectDropController.clearSelection();
                              },
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final SuggestionPlacesResponse? place =
                  await Navigator.push<SuggestionPlacesResponse?>(
                    context,
                    CorporatePageTransitions.pushRoute(
                      context,
                      const CrpDropMapScreen(),
                    ),
                  );

                  if (place != null && context.mounted) {
                    // Handle the place selection and navigate back to booking engine
                    await _handlePlaceSelection(place);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Icon(
                        Icons.pin_drop_outlined,
                        color: AppColors.mainButtonBg,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Choose location on map',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainButtonBg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (crpSelectDropController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final suggestions =
                  crpSelectDropController.suggestions.toList();

              if (suggestions.isEmpty) {
                if (crpSelectDropController.hasSearchText.value) {
                  return const Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.greyText2,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.separated(
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.bgGrey2,
                  ),
                  itemBuilder: (context, index) {
                    final SuggestionPlacesResponse place = suggestions[index];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        place.primaryText.split(',').first.trim(),
                        style: CommonFonts.bodyText1Black,
                      ),
                      subtitle: Text(
                        place.secondaryText,
                        style: CommonFonts.bodyText6Black,
                      ),
                      onTap: () async {
                        await _handlePlaceSelection(place);
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

