import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_drop/choose_drop_controller.dart';
import 'package:wti_cabs_user/core/controller/source_controller/source_controller.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import '../../common_widget/buttons/quick_action_button.dart';
import '../../common_widget/textformfield/google_places_text_field.dart';
import '../../core/controller/choose_pickup/choose_pickup_controller.dart';
import '../../core/model/booking_engine/suggestions_places_response.dart';
import '../../core/route_management/app_routes.dart';
import '../../core/services/storage_services.dart';
import '../../core/services/trip_history_services.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../map_picker/map_picker.dart';

class PopupSelectPickup extends StatefulWidget {
  final bool? fromInventoryScreen;

  const PopupSelectPickup({super.key, this.fromInventoryScreen});

  @override
  State<PopupSelectPickup> createState() => _PopupSelectPickupState();
}

class _PopupSelectPickupState extends State<PopupSelectPickup> {
  late final BookingRideController bookingRideController;
  late final PlaceSearchController placeSearchController;
  late final DropPlaceSearchController dropPlaceSearchController;
  late final SourceLocationController sourceController;
  final TextEditingController pickupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with Get.put to ensure single instance
    bookingRideController = Get.put(BookingRideController());
    placeSearchController = Get.put(PlaceSearchController());
    dropPlaceSearchController = Get.put(DropPlaceSearchController());
    sourceController = Get.put(SourceLocationController());

    // Set initial text for pickupController
    pickupController.text = bookingRideController.prefilled.value;
    // Load recent searches (if needed)
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    // Placeholder for preloading recent searches
    // Example: placeSearchController.loadRecentSearches();
  }

  @override
  void dispose() {
    pickupController.dispose();
    // GetX manages controller disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.scaffoldBgPrimary1,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.scaffoldBgPrimary1,
        iconTheme: IconThemeData(color: AppColors.blue4),
        title: Text("Choose Pickup", style: CommonFonts.appBarText),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GooglePlacesTextField(
                hintText: "Enter pickup location",
                controller: pickupController,
                onPlaceSelected: (newSuggestion) async {
                  pickupController.text = newSuggestion.primaryText;
                  bookingRideController.prefilled.value = newSuggestion.primaryText;
                  FocusScope.of(context).unfocus();
                  _handlePlaceSelection(context, newSuggestion);
                },
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              splashColor: Colors.transparent,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPickerScreen(
                      onLocationSelected: (double lat, double lng, String address) {
                        if (pickupController.text.isEmpty) {
                          pickupController.text = address;
                          bookingRideController.prefilled.value = address;
                        }
                      },
                    ),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_searching_outlined, size: 18, color: AppColors.blue4),
                    SizedBox(width: 6),
                    Text(
                      'Set Location on Map',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.blue4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.bgGrey1,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_outlined, size: 18, color: Colors.black),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pickup places Suggestions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              final suggestions = placeSearchController.suggestions.value;
              if (suggestions.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Material(
                  color: AppColors.scaffoldBgPrimary1,
                  borderRadius: BorderRadius.circular(8),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final place = suggestions[index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            leading: const Icon(Icons.location_on, size: 20),
                            title: Text(
                              place.primaryText.split(',').first.trim(),
                              style: CommonFonts.bodyText1Black,
                            ),
                            subtitle: Text(
                              place.secondaryText,
                              style: CommonFonts.bodyText6Black,
                            ),
                            onTap: () {
                              pickupController.text = place.primaryText;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _handlePlaceSelection(context, place);
                              });
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1, color: AppColors.bgGrey2),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _handlePlaceSelection(BuildContext context, SuggestionPlacesResponse place) async {
    bookingRideController.prefilled.value = place.primaryText;
    placeSearchController.placeId.value = place.placeId;
    FocusScope.of(context).unfocus();

    if (widget.fromInventoryScreen == false) {
      final tabName = bookingRideController.currentTabName;
      final route = '${AppRoutes.bookingRide}?tab=$tabName';
      GoRouter.of(context).go(route);
    } else {
      GoRouter.of(context).pop();
    }

    final dropPlaceId = dropPlaceSearchController.dropPlaceId.value;

    try {
      print('API Sync Start: Pickup=${place.placeId}, Drop=$dropPlaceId');
      await Future.wait([
        placeSearchController.getLatLngDetails(place.placeId, context),
        if (dropPlaceId.isNotEmpty)
          dropPlaceSearchController.getLatLngForDrop(dropPlaceId, context),
      ]);
      print('API Sync Complete ✅ Both pickup & drop coordinates ready');
    } catch (e) {
      print('❌ Error fetching lat/lng details: $e');
    }

    // Save pickup info
    StorageServices.instance.save('sourcePlaceId', place.placeId);
    StorageServices.instance.save('sourceTitle', place.primaryText);
    if (place.types.isNotEmpty) {
      StorageServices.instance.save('sourceTypes', jsonEncode(place.types));
    }
    if (place.terms.isNotEmpty) {
      StorageServices.instance.save('sourceTerms', jsonEncode(place.terms));
    }

    sourceController.setPlace(
      placeId: place.placeId,
      title: place.primaryText,
      city: place.city,
      state: place.state,
      country: place.country,
      types: place.types,
      terms: place.terms,
    );
  }
}