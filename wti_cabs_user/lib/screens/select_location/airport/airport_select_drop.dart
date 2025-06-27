import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

import '../../../common_widget/buttons/quick_action_button.dart';
import '../../../common_widget/textformfield/drop_google_place_text_field.dart';
import '../../../core/controller/choose_drop/choose_drop_controller.dart';
import '../../../core/services/storage_services.dart';


class AirportSelectDrop extends StatefulWidget {
  const AirportSelectDrop({super.key});

  @override
  State<AirportSelectDrop> createState() => _AirportSelectDropState();
}

class _AirportSelectDropState extends State<AirportSelectDrop> {
  final BookingRideController bookingRideController = Get.find<BookingRideController>();
  final DropPlaceSearchController dropPlaceSearchController = Get.put(DropPlaceSearchController());
  final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
  final TextEditingController dropController = TextEditingController();

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
                    onTap: () async{
                      dropController.text = place.primaryText;
                      bookingRideController.prefilledDrop.value = place.primaryText;
                      dropPlaceSearchController.dropPlaceId.value = place.placeId;
                      dropPlaceSearchController.getLatLngForDrop(place.placeId, context);
                      if(placeSearchController.placeId.value.isNotEmpty){
                      placeSearchController.getLatLngDetails(placeSearchController.placeId.value, context);}

                      await StorageServices.instance.save('destinationPlaceId', place.placeId);
                      await StorageServices.instance.save('destinationTitle', place.primaryText);
                      await StorageServices.instance.save('destinationCity', place.city);
                      await StorageServices.instance.save('destinationState', place.state);
                      await StorageServices.instance.save('destinationCountry', place.country);
                      await StorageServices.instance.save('destinationTypes', jsonEncode(place.types));
                      await StorageServices.instance.save('destinationTerms', jsonEncode(place.terms));


                      FocusScope.of(context).unfocus();
                      GoRouter.of(context).pop();
                    },
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
