import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:http/http.dart' as http;

import '../../../core/controller/corporate/crp_select_drop_controller/crp_select_drop_controller.dart';
import '../../../core/model/booking_engine/suggestions_places_response.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../../../common_widget/loader/popup_loader.dart';
import 'crp_drop_search_screen.dart';

class CrpDropMapScreen extends StatefulWidget {
  const CrpDropMapScreen({super.key});

  @override
  State<CrpDropMapScreen> createState() => _CrpDropMapScreenState();
}

class _CrpDropMapScreenState extends State<CrpDropMapScreen> {
  final CrpSelectDropController crpSelectDropController =
      Get.put(CrpSelectDropController());

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
      debugPrint('Error getting current location (drop map): $e');
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
      debugPrint('Error fetching address (drop map): $e');
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

  /// Open Google Places search on a separate screen
  Future<void> _openPlaceSearch() async {
    // Clear any old search text/suggestions before opening search UI
    crpSelectDropController.searchController.clear();
    crpSelectDropController.suggestions.clear();
    crpSelectDropController.hasSearchText.value = false;

    final SuggestionPlacesResponse? selected =
        await Navigator.of(context).push<SuggestionPlacesResponse?>(
      MaterialPageRoute(
        builder: (_) => const CrpDropSearchScreen(),
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

  /// Build SuggestionPlacesResponse for the selected drop and return it
  Future<void> _confirmLocation() async {
    try {
      // Basic reverse-geocoded string is already in selectedAddress.
      final formattedAddress = selectedAddress;
      if (formattedAddress.isEmpty ||
          formattedAddress == 'Fetching address...' ||
          formattedAddress == 'Error fetching address') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get address for selected location'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final place = SuggestionPlacesResponse(
        primaryText: formattedAddress.split(',').first.trim(),
        secondaryText: formattedAddress,
        placeId: '',
        types: const [],
        terms: const [],
        city: '',
        state: '',
        country: '',
        isAirport: false,
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
        placeName: formattedAddress,
      );

      // Update drop controller so booking engine can also read it if needed
      crpSelectDropController.selectedPlace.value = place;

      if (!mounted) return;
      Navigator.of(context).pop<SuggestionPlacesResponse>(place);
    } catch (e) {
      debugPrint('Error confirming drop location: $e');
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Choose drop location", style: CommonFonts.appBarText),
      ),
      body: isLoading
          ? const Center(child: PopupLoader(message: 'Loading map...'))
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
                          onPressed: () => Navigator.pop(context),
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
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Confirm Drop Location",
                        style: CommonFonts.primaryButtonText,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Image.asset('assets/images/custom_marker.png', height: 50),
                ),
                Positioned(
                  right: 12,
                  bottom: MediaQuery.of(context).size.height * 0.24,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () async {
                      await _getCurrentLocation();
                    },
                    backgroundColor: AppColors.bgGreen2,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.prefixAuthText,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}


