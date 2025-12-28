import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/controller/corporate/crp_select_pickup_controller/crp_select_pickup_controller.dart';
import '../../../core/controller/corporate/crp_select_drop_controller/crp_select_drop_controller.dart';
import '../../../core/model/booking_engine/suggestions_places_response.dart';
import '../../../core/route_management/app_routes.dart';
import '../../../core/route_management/corporate_page_transitions.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import 'crp_select_pickup.dart';

class CrpPickupSearchScreen extends StatefulWidget {
  final String? selectedPickupType;
  
  const CrpPickupSearchScreen({super.key, this.selectedPickupType});

  @override
  State<CrpPickupSearchScreen> createState() => _CrpPickupSearchScreenState();
}

class _CrpPickupSearchScreenState extends State<CrpPickupSearchScreen> {
  final CrpSelectPickupController crpSelectPickupController =
      Get.put(CrpSelectPickupController());
  final CrpSelectDropController dropController =
      Get.put(CrpSelectDropController());


  Future<void> _handlePlaceSelection(SuggestionPlacesResponse place) async {
    // Update the controller first
    await crpSelectPickupController.selectPlace(place);
    
    // Navigate back to booking engine
    // The booking engine will read from the controller via Obx()
    if (context.mounted) {
      if (GoRouter.of(context).canPop()) {
        GoRouter.of(context).pop();
      } else {
        // Fallback: navigate to booking engine with data
        final selected = crpSelectPickupController.selectedPlace.value;
        final currentDrop = dropController.selectedPlace.value;
        if (selected != null) {
          GoRouter.of(context).go(
            AppRoutes.cprBookingEngine,
            extra: {
              'selectedPickupType': widget.selectedPickupType,
              'selectedPickupPlace': selected.toJson(),
              if (currentDrop != null) 'selectedDropPlace': currentDrop.toJson(),
            },
          );
        }
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
          'Search pickup location',
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
                controller: crpSelectPickupController.searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter pickup location',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      crpSelectPickupController.hasSearchText.value &&
                              crpSelectPickupController
                                  .searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: AppColors.greyText2,
                              ),
                              onPressed: () {
                                crpSelectPickupController.clearSelection();
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
                      CrpSelectPickupScreen(
                        selectedPickupType: widget.selectedPickupType,
                      ),
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
              if (crpSelectPickupController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final suggestions =
                  crpSelectPickupController.suggestions.toList();

              if (suggestions.isEmpty) {
                if (crpSelectPickupController.hasSearchText.value) {
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


