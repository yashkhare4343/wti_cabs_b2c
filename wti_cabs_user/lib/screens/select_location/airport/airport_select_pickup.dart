import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_drop/choose_drop_controller.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

import '../../../common_widget/buttons/quick_action_button.dart';
import '../../../common_widget/textformfield/google_places_text_field.dart';
import '../../../core/controller/choose_pickup/choose_pickup_controller.dart';
import '../../../core/services/storage_services.dart';
import '../../../utility/constants/fonts/common_fonts.dart';



class AirportSelectPickup extends StatefulWidget {
  const AirportSelectPickup({super.key});

  @override
  State<AirportSelectPickup> createState() => _AirportSelectPickupState();
}

class _AirportSelectPickupState extends State<AirportSelectPickup> {
  final BookingRideController bookingRideController = Get.put(BookingRideController());
  final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController = Get.put(DropPlaceSearchController());
  List<String> suggestions = [];
  final TextEditingController pickupController = TextEditingController();

  // @override
  // void dispose() {
  //   pickupController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    pickupController.text = bookingRideController.prefilled.value;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.scaffoldBgPrimary1,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.scaffoldBgPrimary1,
        iconTheme: const IconThemeData(
          color: AppColors.blue4,
        ),
        title: Text(
          "Choose Pickup",
          style: CommonFonts.appBarText,
        ),
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
                onPlaceSelected: (newSuggestion) {
                  setState(() {
                    pickupController.text = newSuggestion.primaryText;
                    bookingRideController.prefilled.value = newSuggestion.primaryText;
                    FocusScope.of(context).unfocus();
                    GoRouter.of(context).pop();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    QuickAddLocationTile(
                      icon: Icons.home,
                      label: "Home",
                      onTap: () {
                        print("🏠 Home tapped");
                      },
                    ),
                    const SizedBox(width: 12),
                    QuickAddLocationTile(
                      icon: Icons.business,
                      label: "Office",
                      onTap: () {
                        print("🏢 Office tapped");
                      },
                    ),
                    const SizedBox(width: 12),
                    QuickAddLocationTile(
                      icon: Icons.add_location_alt,
                      label: "Add Place",
                      onTap: () {
                        print("📍 Add Location tapped");
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_searching_outlined,
                      size: 18, color: AppColors.blue4),
                  const SizedBox(width: 6),
                  Text(
                    'Set Location on Map',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blue4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.bgGrey1,
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_outlined, size: 18, color: Colors.black),
                    const SizedBox(width: 6),
                    Text(
                      'Recent Searches',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            // Recent Searches

            Obx(() {
              final suggestions = placeSearchController.suggestions.value;
              return suggestions != [] ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                            leading: Icon(Icons.location_on, size: 20),
                            title: Text(
                              place.primaryText.split(',').first.trim(),
                              style: CommonFonts.bodyText1Black,
                            ),
                            subtitle: Text(
                              place.secondaryText,
                              style: CommonFonts.bodyText6Black,
                            ),
                            onTap: () async{
                              pickupController.text = place.primaryText;
                              bookingRideController.prefilled.value = place.primaryText;
                              placeSearchController.placeId.value = place.placeId;
                              placeSearchController.getLatLngDetails(place.placeId, context);
                              // store values
                              await StorageServices.instance.save('sourcePlaceId', place.placeId);
                              await StorageServices.instance.save('sourceTitle', place.primaryText);
                              await StorageServices.instance.save('sourceCity', place.city);
                              await StorageServices.instance.save('sourceState', place.state);
                              await StorageServices.instance.save('sourceCountry', place.country);
                              if (place.types.isNotEmpty) {
                                await StorageServices.instance.save('sourceTypes', jsonEncode(place.types));
                              }
                              if (place.terms.isNotEmpty) {
                                await StorageServices.instance.save('sourceTerms', jsonEncode(place.terms));
                              }




                              FocusScope.of(context).unfocus();
                              if(dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
                                dropPlaceSearchController.getLatLngForDrop(
                                    dropPlaceSearchController.dropPlaceId.value,
                                    context);
                              }
                              GoRouter.of(context).pop();
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              height: 1,
                              color: AppColors.bgGrey2,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ): SizedBox();
            })
          ],
        ),
      ),
    );
  }
}