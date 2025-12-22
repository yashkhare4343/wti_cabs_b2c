import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:http/http.dart' as http;

import '../../../common_widget/loader/popup_loader.dart';
import '../../../core/controller/corporate/crp_select_pickup_controller/crp_select_pickup_controller.dart';
import '../../../core/model/booking_engine/suggestions_places_response.dart';
import '../../../core/route_management/app_routes.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../../../core/services/storage_services.dart';
import 'crp_pickup_search_screen.dart';

class CrpSelectPickupScreen extends StatefulWidget {
  final String? selectedPickupType;

  const CrpSelectPickupScreen({super.key, this.selectedPickupType});

  @override
  State<CrpSelectPickupScreen> createState() => _CrpSelectPickupScreenState();
}

class _CrpSelectPickupScreenState extends State<CrpSelectPickupScreen> {
  final CrpSelectPickupController crpSelectPickupController =
      Get.put(CrpSelectPickupController());

  GoogleMapController? mapController;
  LatLng currentLocation = const LatLng(28.7041, 77.1025);
  LatLng selectedLocation = const LatLng(28.7041, 77.1025);
  String selectedAddress = 'Fetching address...';
  bool isLoading = true;
  Timer? _debounce;

  // Google API Key
  final String googleApiKey = "AIzaSyCWbmCiquOta1iF6um7_5_NFh6YM5wPL30";

  @override
  void initState() {
    super.initState();
    _loadLastSelectedOrCurrent();
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
      if (!(await loc.serviceEnabled()) && !(await loc.requestService())) {
        setState(() => isLoading = false);
        return;
      }

      var permission = await loc.hasPermission();
      if (permission == location.PermissionStatus.denied) {
        permission = await loc.requestPermission();
        if (permission != location.PermissionStatus.granted) {
          setState(() => isLoading = false);
          return;
        }
      }

      final locData = await loc.getLocation();
      if (locData.latitude == null || locData.longitude == null) {
        setState(() => isLoading = false);
        return;
      }

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

  /// Get address from LatLng using Google Maps Geocoding API
  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    setState(() {
      selectedAddress = 'Fetching address...';
    });

    try {
      final url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleApiKey";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final results = jsonData["results"] as List;

        if (results.isNotEmpty) {
          final formattedAddress = results[0]["formatted_address"] ?? "";
          setState(() {
            selectedAddress = formattedAddress;
          });
        } else {
          setState(() {
            selectedAddress = 'Address not found';
          });
        }
      } else {
        setState(() {
          selectedAddress = 'Error fetching address';
        });
      }
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

  /// Load last selected place from storage; fall back to current location on first time
  Future<void> _loadLastSelectedOrCurrent() async {
    // For corporate booking flow, always start from the device's
    // current GPS location when opening the pickup map screen.
    await _getCurrentLocation();
  }

  /// Open Google Places search on a separate screen
  Future<void> _openPlaceSearch() async {
    // Clear any old search text/suggestions before opening search UI,
    // while keeping the currently selected pickup location intact.
    crpSelectPickupController.searchController.clear();
    crpSelectPickupController.suggestions.clear();
    crpSelectPickupController.hasSearchText.value = false;

    final SuggestionPlacesResponse? selected =
        await Navigator.of(context).push<SuggestionPlacesResponse?>(
      MaterialPageRoute(
        builder: (_) => CrpPickupSearchScreen(),
      ),
    );

    if (selected != null) {
      final lat = selected.latitude;
      final lng = selected.longitude;

      if (lat != null && lng != null) {
        final newLatLng = LatLng(lat, lng);
        setState(() {
          selectedLocation = newLatLng;
        });
        mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
        await _getAddressFromLatLng(newLatLng);
      } else {
        setState(() {
          selectedAddress = selected.secondaryText.isNotEmpty
              ? selected.secondaryText
              : selected.primaryText;
        });
      }
    }
  }

  /// Save location and update controller
  Future<void> _saveLocation(LatLng latLng) async {
    try {
      // Get address from lat/lng
      await _getAddressFromLatLng(latLng);

      // Get place details using Google Places API
      final placeDetailsUrl =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleApiKey";

      final response = await http.get(Uri.parse(placeDetailsUrl));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final results = jsonData["results"] as List;

        if (results.isNotEmpty) {
          final result = results[0];
          final formattedAddress = result["formatted_address"] ?? "";
          final placeId = result["place_id"] ?? "";

          // Extract address components
          final addressComponents = result["address_components"] as List;
          String city = '';
          String state = '';
          String country = '';

          for (var component in addressComponents) {
            final types = component["types"] as List;
            if (types.contains("locality")) {
              city = component["long_name"] ?? "";
            } else if (types.contains("administrative_area_level_1")) {
              state = component["long_name"] ?? "";
            } else if (types.contains("country")) {
              country = component["long_name"] ?? "";
            }
          }

          // Create SuggestionPlacesResponse object
          final place = SuggestionPlacesResponse(
            primaryText: formattedAddress.split(',').first.trim(),
            secondaryText: formattedAddress,
            placeId: placeId,
            types: [],
            terms: [],
            city: city,
            state: state,
            country: country,
            isAirport: false,
            latitude: latLng.latitude,
            longitude: latLng.longitude,
            placeName: formattedAddress,
          );

          // Update controller with selected place
          crpSelectPickupController.selectedPlace.value = place;
          crpSelectPickupController.searchController.text = place.primaryText;

          // Persist last selected pickup for future sessions
          final storage = StorageServices.instance;
          await Future.wait([
            storage.save('sourceTitle', place.primaryText),
            storage.save('sourcePlaceId', place.placeId),
            storage.save('sourceLat', latLng.latitude.toString()),
            storage.save('sourceLng', latLng.longitude.toString()),
          ]);

          debugPrint('📍 Saved Corporate Pickup Location:');
          debugPrint('Latitude: ${latLng.latitude}');
          debugPrint('Longitude: ${latLng.longitude}');
          debugPrint('Address: $formattedAddress');
          debugPrint('Place ID: $placeId');
        }
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
        title: Text("Choose pickup location", style: CommonFonts.appBarText),
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
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        leading: const Icon(
                          Icons.location_on,
                          color: Color(0xFFE5383F),
                        ),
                        title: Text(
                          selectedAddress,
                          style: CommonFonts.prefixTextAuth,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: AppColors.greyText2,
                          ),
                        ),
                        onTap: _openPlaceSearch,
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
                        if (context.mounted) {
                          context.pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text("Confirm Location",
                          style: CommonFonts.primaryButtonText),
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
                    onPressed: () async {
                      // Refresh device GPS location and move camera there
                      await _getCurrentLocation();
                    },
                    backgroundColor: AppColors.bgGreen2,
                    child: const Icon(Icons.my_location,
                        color: AppColors.prefixAuthText, size: 20),
                  ),
                ),
              ],
            ),
    );
  }
}

