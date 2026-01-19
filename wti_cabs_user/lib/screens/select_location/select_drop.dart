import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';
import '../../common_widget/textformfield/drop_google_place_text_field.dart';
import '../../core/controller/choose_drop/choose_drop_controller.dart';
import '../../core/controller/drop_location_controller/drop_location_controller.dart';
import '../../core/services/storage_services.dart';
import '../../core/services/trip_history_services.dart';
import '../bottom_nav/bottom_nav.dart';
import '../booking_ride/booking_ride.dart';
import '../trip_history_controller/trip_history_controller.dart';

class SelectDrop extends StatefulWidget {
  final bool? fromInventoryScreen;
  const SelectDrop({super.key, this.fromInventoryScreen});

  @override
  State<SelectDrop> createState() => _SelectDropState();
}

class _SelectDropState extends State<SelectDrop> {
  late final BookingRideController bookingRideController;
  late final DropPlaceSearchController dropPlaceSearchController;
  late final PlaceSearchController placeSearchController;
  late final TripHistoryController tripController;
  late final DestinationLocationController destinationController;
  final TextEditingController dropController = TextEditingController();
  bool _isProcessingTap = false; // Prevent multiple onTap executions

  @override
  void initState() {
    super.initState();
    // Initialize controllers with Get.find or Get.put
    try {
      bookingRideController = Get.find<BookingRideController>();
    } catch (_) {
      bookingRideController = Get.put(BookingRideController());
    }
    try {
      placeSearchController = Get.find<PlaceSearchController>();
    } catch (_) {
      placeSearchController = Get.put(PlaceSearchController());
    }
    try {
      destinationController = Get.find<DestinationLocationController>();
    } catch (_) {
      destinationController = Get.put(DestinationLocationController());
    }
    // IMPORTANT: DropPlaceSearchController depends on PlaceSearchController + DestinationLocationController,
    // so ensure those are registered first.
    try {
      dropPlaceSearchController = Get.find<DropPlaceSearchController>();
    } catch (_) {
      dropPlaceSearchController = Get.put(DropPlaceSearchController());
    }
    try {
      tripController = Get.find<TripHistoryController>();
    } catch (_) {
      tripController = Get.put(TripHistoryController());
    }

    // Set initial text for dropController
    dropController.text = bookingRideController.prefilledDrop.value;


    // Load recent searches
    _loadRecentSearches();
  }
  void _loadRecentSearches() {
    // Placeholder for preloading recent searches
    // Example: dropPlaceSearchController.loadRecentSearches();
  }

  @override
  void dispose() {
    dropController.dispose();
    // GetX manages controller disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return; // Already popped, nothing to do
        
        bookingRideController.selectedIndex.value = 0;
        bookingRideController.fromHomePage.value = false;
        
        // Navigate back to bottomNav
        Future.microtask(() {
          if (!mounted) return;
          GoRouter.of(context).push(AppRoutes.bookingRide);
        });
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.scaffoldBgPrimary1,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.scaffoldBgPrimary1,
          iconTheme: IconThemeData(color: AppColors.blue4),
          title: Text("Choose Drop", style: CommonFonts.appBarText),
          centerTitle: false,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropGooglePlacesTextField(
                  hintText: "Enter drop location",
                  controller: dropController,
                  onPlaceSelected: (newSuggestion) {
                    dropController.text = newSuggestion.primaryText;
                    bookingRideController.prefilledDrop.value = newSuggestion.primaryText;
                    FocusScope.of(context).unfocus();
                    // Navigate to BookingRide after place selection
                    _handlePlaceSelection(context, newSuggestion);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.bgGrey1,
                child: const Row(
                  // mainAxisSize: MainAxisSize.min,
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
              Obx(() {
                final suggestions = dropPlaceSearchController.dropSuggestions.value;
                if (suggestions.isEmpty) return const SizedBox.shrink();
                return ListView.separated(
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
                      title: Text(
                        place.primaryText.split(',').first.trim(),
                        style: CommonFonts.bodyText1Black,
                      ),
                      subtitle: Text(
                        place.secondaryText,
                        style: CommonFonts.bodyText6Black,
                      ),
                      onTap: () {
                        if (_isProcessingTap) return; // Prevent double tap
                        setState(() => _isProcessingTap = true);
                        dropController.text = place.primaryText;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _handlePlaceSelection(context, place);
                          setState(() => _isProcessingTap = false);
                        });
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

  void _handlePlaceSelection(BuildContext context, SuggestionPlacesResponse place) {
    // Update Rx variables
    bookingRideController.prefilledDrop.value = place.primaryText;
    dropPlaceSearchController.dropPlaceId.value = place.placeId;

    print('fromInventoryPage = ${widget.fromInventoryScreen}');
    FocusScope.of(context).unfocus();

    // Always navigate to BookingRide after place selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure airport tab is selected when returning to BookingRide from SelectDrop
      bookingRideController.setTabByName('airport');
      Navigator.of(context).push(
        Platform.isIOS
            ? CupertinoPageRoute(
          builder: (context) => const BookingRide(initialTab: 'airport'),
        )
            : MaterialPageRoute(
          builder: (context) => const BookingRide(initialTab: 'airport'),
        ),
      );
    });

    // Background tasks
    Future.microtask(() {
      print('API Call: getLatLngForDrop for placeId: ${place.placeId}');
      dropPlaceSearchController.getLatLngForDrop(place.placeId, context);

      final pickupPlaceId = placeSearchController.placeId.value;
      if (pickupPlaceId.isNotEmpty) {
        print('API Call: getLatLngDetails for pickupPlaceId: $pickupPlaceId');
        placeSearchController.getLatLngDetails(pickupPlaceId, context);
      }

      // Record trip
      tripController.recordTrip(
        bookingRideController.prefilled.value,
        pickupPlaceId,
        place.primaryText,
        place.placeId,
        context,
      );

      // Storage operations
      StorageServices.instance.save('destinationPlaceId', place.placeId);
      StorageServices.instance.save('destinationTitle', place.primaryText);
      if (place.types.isNotEmpty) {
        StorageServices.instance.save('destinationTypes', jsonEncode(place.types));
      }
      if (place.terms.isNotEmpty) {
        StorageServices.instance.save('destinationTerms', jsonEncode(place.terms));
      }

      // Update destination controller
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
}