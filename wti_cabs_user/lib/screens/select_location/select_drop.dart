import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';
import '../../common_widget/buttons/quick_action_button.dart';
import '../../common_widget/loader/popup_loader.dart';
import '../../common_widget/textformfield/drop_google_place_text_field.dart';
import '../../common_widget/textformfield/google_places_text_field.dart';
import '../../core/controller/choose_drop/choose_drop_controller.dart';
import '../../core/controller/drop_location_controller/drop_location_controller.dart';
import '../../core/services/storage_services.dart';
import '../../core/services/trip_history_services.dart';
import '../trip_history_controller/trip_history_controller.dart';

class SelectDrop extends StatefulWidget {
  const SelectDrop({super.key});

  @override
  State<SelectDrop> createState() => _SelectDropState();
}

class _SelectDropState extends State<SelectDrop> {
  final BookingRideController bookingRideController = Get.find<BookingRideController>();
  final DropPlaceSearchController dropPlaceSearchController = Get.put(DropPlaceSearchController());
  final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
  final TextEditingController dropController = TextEditingController();
  final TripHistoryController tripController = Get.put(TripHistoryController());
  final DestinationLocationController destinationController = Get.put(DestinationLocationController());

  List<String> _topRecentTrips = [];

  @override
  void initState() {
    super.initState();
    bookingRideController.prefilledDrop.value = '';
  }



  @override
  Widget build(BuildContext context) {
    dropController.text = bookingRideController.prefilledDrop.value;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.scaffoldBgPrimary1,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.scaffoldBgPrimary1,
        iconTheme: const IconThemeData(color: AppColors.blue4),
        title: Text("Choose Drop", style: CommonFonts.appBarText),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Drop Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropGooglePlacesTextField(
                hintText: "Enter drop location",
                controller: dropController,
                onPlaceSelected: (newSuggestion) {
                  setState(() {
                    dropController.text = newSuggestion.primaryText;
                    bookingRideController.prefilledDrop.value = newSuggestion.primaryText;
                    FocusScope.of(context).unfocus();
                    GoRouter.of(context).pop();
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // 📍 Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    QuickAddLocationTile(
                      icon: Icons.home,
                      label: "Home",
                      onTap: () => print("🏠 Home tapped"),
                    ),
                    const SizedBox(width: 12),
                    QuickAddLocationTile(
                      icon: Icons.business,
                      label: "Office",
                      onTap: () => print("🏢 Office tapped"),
                    ),
                    const SizedBox(width: 12),
                    QuickAddLocationTile(
                      icon: Icons.add_location_alt,
                      label: "Add Place",
                      onTap: () => print("📍 Add Location tapped"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🌍 Set on Map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.location_searching_outlined, size: 18, color: AppColors.blue4),
                  const SizedBox(width: 6),
                  Text('Set Location on Map', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.blue4)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🕘 Recent Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.bgGrey1,
              child: Row(
                children: [
                  Icon(Icons.history_outlined, size: 18, color: Colors.black),
                  const SizedBox(width: 6),
                  Text('Recent Searches', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 📃 Drop Suggestions
            Obx(() {
              final suggestions = dropPlaceSearchController.dropSuggestions.value;

              return suggestions.isNotEmpty
                  ? ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.bgGrey2),
                itemBuilder: (context, index) {
                  final place = suggestions[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    leading: const Icon(Icons.location_on, size: 20),
                    title: Text(place.primaryText.split(',').first.trim(), style: CommonFonts.bodyText1Black),
                    subtitle: Text(place.secondaryText, style: CommonFonts.bodyText6Black),
                      onTap: () {
                        // 🚀 1. Instant UI updates (no waiting)
                        dropController.text = place.primaryText;
                        bookingRideController.prefilledDrop.value = place.primaryText;
                        dropPlaceSearchController.dropPlaceId.value = place.placeId;

                        // 🚀 2. Navigate immediately
                        FocusScope.of(context).unfocus();
                        GoRouter.of(context).push(AppRoutes.bookingRide);

                        // 🧠 3. Background work (fire-and-forget, non-blocking)
                        Future.microtask(() {
                          // LatLng for drop (non-blocking)
                          dropPlaceSearchController.getLatLngForDrop(place.placeId, context);

                          // Optional: recordTrip + pickup lat/lng in parallel
                          final pickupTitle = bookingRideController.prefilled.value;
                          final pickupPlaceId = placeSearchController.placeId.value;

                          if (pickupPlaceId.isNotEmpty) {
                            placeSearchController.getLatLngDetails(pickupPlaceId, context);
                          }

                          tripController.recordTrip(
                            pickupTitle,
                            pickupPlaceId,
                            place.primaryText,
                            place.placeId,
                          );

                          // Storage (fast, no await)
                          StorageServices.instance.save('destinationPlaceId', place.placeId);
                          StorageServices.instance.save('destinationTitle', place.primaryText);
                          StorageServices.instance.save('destinationCity', place.city);
                          StorageServices.instance.save('destinationState', place.state);
                          StorageServices.instance.save('destinationCountry', place.country);

                          if (place.types.isNotEmpty) {
                            StorageServices.instance.save('destinationTypes', jsonEncode(place.types));
                          }

                          if (place.terms.isNotEmpty) {
                            StorageServices.instance.save('destinationTerms', jsonEncode(place.terms));
                          }

                          // Set in controller
                          destinationController.setPlace(
                            placeId: place.placeId,
                            title: place.primaryText,
                            city: place.city,
                            state: place.state,
                            country: place.country,
                            types: place.types,
                            terms: place.terms,
                          );
                        });
                      }


                  );
                },
              )
                  : const SizedBox();
            }),
          ],
        ),
      ),
    );
  }
}
