import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_drop/choose_drop_controller.dart';
import 'package:wti_cabs_user/core/controller/drop_location_controller/drop_location_controller.dart';
import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';
import 'package:wti_cabs_user/core/services/trip_history_services.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';
import '../../common_widget/textformfield/drop_google_place_text_field.dart';
import '../trip_history_controller/trip_history_controller.dart';

class PopupSelectDrop extends StatefulWidget {
  final bool? fromInventoryScreen;
  const PopupSelectDrop({super.key, this.fromInventoryScreen});

  @override
  State<PopupSelectDrop> createState() => _PopupSelectDropState();
}

class _PopupSelectDropState extends State<PopupSelectDrop> {
  late final BookingRideController bookingRideController;
  late final DropPlaceSearchController dropPlaceSearchController;
  late final PlaceSearchController placeSearchController;
  late final TripHistoryController tripController;
  late final DestinationLocationController destinationController;
  final TextEditingController dropController = TextEditingController();

  bool _isProcessingTap = false; // Prevent multiple tap executions

  @override
  void initState() {
    super.initState();
    _initControllers();
    dropController.text = bookingRideController.prefilledDrop.value;
  }

  void _initControllers() {
    bookingRideController = Get.put(BookingRideController(), permanent: true);
    dropPlaceSearchController = Get.put(DropPlaceSearchController(), permanent: true);
    placeSearchController = Get.put(PlaceSearchController(), permanent: true);
    tripController = Get.put(TripHistoryController(), permanent: true);
    destinationController = Get.put(DestinationLocationController(), permanent: true);
  }

  @override
  void dispose() {
    dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && context.mounted) {
          GoRouter.of(context).pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.scaffoldBgPrimary1,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.scaffoldBgPrimary1,
          iconTheme: IconThemeData(color: AppColors.blue4),
          title: Text("Choose Drop", style: CommonFonts.appBarText),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drop Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropGooglePlacesTextField(
                  hintText: "Enter drop location",
                  controller: dropController,
                  onPlaceSelected: (suggestion) async {
                     _handlePlaceSelection(context, suggestion);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Suggestions Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.bgGrey1,
                child: const Row(
                  children: [
                    Icon(Icons.history_outlined, size: 18, color: Colors.black),
                    SizedBox(width: 6),
                    Text(
                      'Drop Places Suggestions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Suggestions List
              Obx(() {
                final suggestions = dropPlaceSearchController.dropSuggestions.value;
                if (suggestions.isEmpty) return const SizedBox.shrink();

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.bgGrey2),
                  itemBuilder: (context, index) {
                    final place = suggestions[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      leading: const Icon(Icons.location_on, size: 20),
                      title: Text(
                        place.primaryText.split(',').first.trim(),
                        style: CommonFonts.bodyText1Black,
                      ),
                      subtitle: Text(
                        place.secondaryText,
                        style: CommonFonts.bodyText6Black,
                      ),
                      onTap: () async {
                        if (_isProcessingTap) return;
                        setState(() => _isProcessingTap = true);

                         _handlePlaceSelection(context, place);

                        if (mounted) {
                          setState(() => _isProcessingTap = false);
                        }
                      },
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles when user selects a place from list or search
  void _handlePlaceSelection(BuildContext context, SuggestionPlacesResponse place) async {
    bookingRideController.prefilledDrop.value = place.primaryText;
    dropPlaceSearchController.dropPlaceId.value = place.placeId;
    FocusScope.of(context).unfocus();

    // Navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.fromInventoryScreen == true) {
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else {
          // Always use push to preserve back stack.
          GoRouter.of(context).push(AppRoutes.bookingRide);
        }
      } else {
        // Always use push to preserve back stack.
        GoRouter.of(context).push(AppRoutes.bookingRide);
      }
    });

    // 🧠 SYNCED BACKGROUND TASKS
    final pickupPlaceId = placeSearchController.placeId.value;

    try {
      print('API Sync Start: Pickup=$pickupPlaceId, Drop=${place.placeId}');
      // Fetch both in parallel and wait for both results
      await Future.wait([
        dropPlaceSearchController.getLatLngForDrop(place.placeId, context),
        if (pickupPlaceId.isNotEmpty)
          placeSearchController.getLatLngDetails(pickupPlaceId, context),
      ]);
      print('API Sync Complete ✅ Both pickup & drop coordinates ready');
    } catch (e) {
      print('❌ Error fetching lat/lng details: $e');
    }

    // Record trip only when both ready
    if (pickupPlaceId.isNotEmpty) {
      tripController.recordTrip(
        bookingRideController.prefilled.value,
        pickupPlaceId,
        place.primaryText,
        place.placeId,
        context,
      );
    }

    // Save to storage
    StorageServices.instance.save('destinationPlaceId', place.placeId);
    StorageServices.instance.save('destinationTitle', place.primaryText);
    if (place.types.isNotEmpty) {
      StorageServices.instance.save('destinationTypes', jsonEncode(place.types));
    }
    if (place.terms.isNotEmpty) {
      StorageServices.instance.save('destinationTerms', jsonEncode(place.terms));
    }

    // Update controller state
    destinationController.setPlace(
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
