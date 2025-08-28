import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;

import '../../common_widget/loader/popup_loader.dart';
import '../../core/controller/booking_ride_controller.dart';
import '../../core/controller/choose_pickup/choose_pickup_controller.dart';
import '../../core/controller/get_place_name_controller/get_place_name_controller.dart';
import '../../core/controller/popular_destination/popular_destination.dart';
import '../../core/controller/source_controller/source_controller.dart';
import '../../core/controller/usp_controller/usp_controller.dart';
import '../../core/route_management/app_routes.dart';
import '../../core/services/storage_services.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../trip_history_controller/trip_history_controller.dart';

/// Initialize controllers
final bookingRideController = Get.put(BookingRideController());
final popularDestinationController = Get.put(PopularDestinationController());
final uspController = Get.put(UspController());
final tripController = Get.put(TripHistoryController());
final placeSearchController = Get.put(PlaceSearchController());
final sourceController = Get.put(SourceLocationController());
final getPlaceNameController = Get.put(GetPlaceNameController()); // Add controller

class MapPickerScreen extends StatefulWidget {
  final Function(double lat, double lng, String address) onLocationSelected;

  const MapPickerScreen({required this.onLocationSelected, super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? mapController;
  LatLng currentLocation = const LatLng(28.7041, 77.1025);
  LatLng selectedLocation = const LatLng(28.7041, 77.1025);
  String selectedAddress = 'Fetching address...';
  bool isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  /// Get current location & center map
  Future<void> _getCurrentLocation() async {
    final loc = location.Location();
    try {
      if (!(await loc.serviceEnabled()) && !(await loc.requestService())) return;

      var permission = await loc.hasPermission();
      if (permission == location.PermissionStatus.denied) {
        permission = await loc.requestPermission();
        if (permission != location.PermissionStatus.granted) return;
      }

      final locData = await loc.getLocation();
      if (locData.latitude == null || locData.longitude == null) return;

      setState(() {
        currentLocation = LatLng(locData.latitude!, locData.longitude!);
        selectedLocation = currentLocation;
        isLoading = false;
      });

      mapController?.animateCamera(CameraUpdate.newLatLng(currentLocation));
      await _getAddressFromLatLng(currentLocation);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      setState(() => isLoading = false);
    }
  }

  /// Get address from LatLng using getPlaceNameController
  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    setState(() {
      selectedAddress = 'Fetching address...';
    });

    try {
      await getPlaceNameController.fetchPlaceName(
        lat: latLng.latitude,
        lng: latLng.longitude,
        context: context,
      );
      final address = getPlaceNameController.getPlaceNameResponse.value?.nearestAddress;
      setState(() {
        selectedAddress = address ?? 'Address not found';
        bookingRideController.prefilled.value = selectedAddress;
      });
    } catch (e) {
      setState(() {
        selectedAddress = 'Error fetching address';
      });
      debugPrint('Error fetching address: $e');
    }
  }

  /// Debounced map movement handler
  void _onCameraMove(CameraPosition position) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        selectedLocation = position.target;
      });
      _getAddressFromLatLng(selectedLocation);
    });
  }

  /// Save location and prefill controllers
  Future<void> _saveLocation(LatLng latLng) async {
    try {
      await getPlaceNameController.fetchPlaceName(
        lat: latLng.latitude,
        lng: latLng.longitude,
        context: context,
      );
      final address = getPlaceNameController.getPlaceNameResponse.value?.nearestAddress;
      if (address == null) return;

      // Use the address for search API
      await placeSearchController.searchPlaces(address, context);
      final suggestion = placeSearchController.suggestions.firstOrNull;

      if (suggestion == null) return;

      bookingRideController.prefilled.value = suggestion.primaryText;
      placeSearchController.placeId.value = suggestion.placeId;
      await placeSearchController.getLatLngDetails(suggestion.placeId, context);

      /// Persist data
      final storage = StorageServices.instance;
      await storage.save('sourcePlaceId', suggestion.placeId);
      await storage.save('sourceTitle', suggestion.primaryText);
      await storage.save('sourceCity', suggestion.city);
      await storage.save('sourceState', suggestion.state);
      await storage.save('sourceCountry', suggestion.country);

      sourceController.setPlace(
        placeId: suggestion.placeId,
        title: suggestion.primaryText,
        city: suggestion.city,
        state: suggestion.state,
        country: suggestion.country,
        types: suggestion.types,
        terms: suggestion.terms,
      );

      if (suggestion.types.isNotEmpty) {
        await storage.save('sourceTypes', jsonEncode(suggestion.types));
      }
      if (suggestion.terms.isNotEmpty) {
        await storage.save('sourceTerms', jsonEncode(suggestion.terms));
      }
    } catch (e) {
      debugPrint('Error saving location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.8,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.polylineGrey),
          onPressed: () => context.pop(),
        ),
        title: Text("Choose location", style: CommonFonts.appBarText),
      ),
      body: isLoading
          ? const Center(child: PopupLoader(message: 'Loading...'))
          : Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: MediaQuery.of(context).size.width * 0.93,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      offset: Offset(0, 3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: const Icon(Icons.location_on, color: Color(0xFFE5383F)),
                  title: Text(
                    selectedAddress,
                    style: CommonFonts.prefixTextAuth,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.greyText2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedLocation,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onCameraMove: _onCameraMove,
                  markers: const {},
                  onMapCreated: (controller) => mapController = controller,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const PopupLoader(message: 'Saving...'),
                  );
                  await _saveLocation(selectedLocation);
                  if (context.mounted) Navigator.pop(context);
                  widget.onLocationSelected(
                    selectedLocation.latitude,
                    selectedLocation.longitude,
                    selectedAddress,
                  );
                  bookingRideController.prefilled.value = selectedAddress;
                  print('booking ride controller prefilled address : ${bookingRideController.prefilled.value}');
                  final tabName = Get.find<BookingRideController>().currentTabName;
                  if (context.mounted){
                    if(bookingRideController.selectedIndex.value == 3){
                    bookingRideController.selectedIndex.value = 3;
                    GoRouter.of(context).go(
                      '${AppRoutes.bookingRide}?tab=rental',
                    );
                  }
                  else{

                    GoRouter.of(context).go(
                      '${AppRoutes.bookingRide}?tab=$tabName',
                    );
                  }}

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text("Confirm Location", style: CommonFonts.primaryButtonText),
              ),
            ),
          ),
          Center(
            child: Image.asset('assets/images/source.png', height: 50),
          ),
          Positioned(
            right: 12,
            bottom: MediaQuery.of(context).size.height * 0.24,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                mapController?.animateCamera(CameraUpdate.newLatLng(currentLocation));
                setState(() => selectedLocation = currentLocation);
                _getAddressFromLatLng(currentLocation);
              },
              backgroundColor: AppColors.bgGreen2,
              child: const Icon(Icons.my_location, color: AppColors.prefixAuthText, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}