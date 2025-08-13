import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
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

class SelectPickup extends StatefulWidget {
  const SelectPickup({super.key});

  @override
  State<SelectPickup> createState() => _SelectPickupState();
}

class _SelectPickupState extends State<SelectPickup> {
  final BookingRideController bookingRideController = Get.put(BookingRideController());
  final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController = Get.put(DropPlaceSearchController());
  List<String> suggestions = [];
  final TextEditingController pickupController = TextEditingController();
 final SourceLocationController sourceController = Get.put(SourceLocationController());

  List<String> _topRecentTrips = [];

  @override
  void initState() {
    super.initState();
  }



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
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: SingleChildScrollView(
            //     scrollDirection: Axis.horizontal,
            //     child: Row(
            //       children: [
            //         QuickAddLocationTile(
            //           icon: Icons.home,
            //           label: "Home",
            //           onTap: () {
            //             print("🏠 Home tapped");
            //           },
            //         ),
            //         const SizedBox(width: 12),
            //         QuickAddLocationTile(
            //           icon: Icons.business,
            //           label: "Office",
            //           onTap: () {
            //             print("🏢 Office tapped");
            //           },
            //         ),
            //         const SizedBox(width: 12),
            //         QuickAddLocationTile(
            //           icon: Icons.add_location_alt,
            //           label: "Add Place",
            //           onTap: () {
            //             print("📍 Add Location tapped");
            //           },
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 16),
            InkWell(
              splashColor:Colors.transparent,
              onTap: () async{
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MapPickerScreen(
                        onLocationSelected: (double lat, double lng, String address) {
                        if(pickupController.text.isEmpty){
                          pickupController.text = address;
                        }
                      },
                      )
                  ),
                );
              },

              child: Padding(
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
                              onTap: () {
                                // 🚀 1. Immediate UI update only
                                pickupController.text = place.primaryText;
                                bookingRideController.prefilled.value = place.primaryText;
                                placeSearchController.placeId.value = place.placeId;

                                // 🚀 2. Immediate navigation (unfocus + close current screen)
                                FocusScope.of(context).unfocus();
                                final tabName = Get.find<BookingRideController>().currentTabName;
                                if(bookingRideController.selectedIndex.value == 2){
                                  bookingRideController.selectedIndex.value = 2;
                                  GoRouter.of(context).go(
                                    '${AppRoutes.bookingRide}?tab=rental',
                                  );
                                }
                                else{
                                  bookingRideController.selectedIndex.value = 0;

                                  GoRouter.of(context).go(
                                    '${AppRoutes.bookingRide}?tab=airport',
                                  );
                                }

                                // 🧠 3. Background processing (does not block navigation)
                                Future.microtask(() {
                                  // Fire-and-forget — don't await unless required later

                                  placeSearchController.getLatLngDetails(place.placeId, context);

                                  dropPlaceSearchController.dropPlaceId.value.isNotEmpty
                                      ? dropPlaceSearchController.getLatLngForDrop(
                                      dropPlaceSearchController.dropPlaceId.value, context)
                                      : null;

                                  // Storage & controller update (no await — fastest possible)
                                  StorageServices.instance.save('sourcePlaceId', place.placeId);
                                  StorageServices.instance.save('sourceTitle', place.primaryText);
                                  StorageServices.instance.save('sourceCity', place.city);
                                  StorageServices.instance.save('sourceState', place.state);
                                  StorageServices.instance.save('sourceCountry', place.country);
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

                                  print('akash country: ${place.country}');
                                });
                              }

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