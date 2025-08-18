import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:wti_cabs_user/common_widget/loader/popup_loader.dart';

import '../../core/controller/booking_ride_controller.dart';
import '../../core/controller/choose_pickup/choose_pickup_controller.dart';
import '../../core/controller/popular_destination/popular_destination.dart';
import '../../core/controller/source_controller/source_controller.dart';
import '../../core/controller/usp_controller/usp_controller.dart';
import '../../core/services/storage_services.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../trip_history_controller/trip_history_controller.dart';
final BookingRideController bookingRideController =
Get.put(BookingRideController());
final PopularDestinationController popularDestinationController = Get.put(PopularDestinationController());
final UspController uspController = Get.put(UspController());

final TripHistoryController tripController = Get.put(TripHistoryController());
final PlaceSearchController searchController = Get.put(PlaceSearchController());
final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
final SourceLocationController sourceController = Get.put(SourceLocationController());



class MapPickerScreen extends StatefulWidget {
  final Function(double lat, double lng, String address) onLocationSelected;

  MapPickerScreen({required this.onLocationSelected});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? mapController;
  LatLng currentLocation = LatLng(28.7041, 77.1025);
  LatLng selectedLocation = LatLng(28.7041, 77.1025);
  String selectedAddress = 'Fetching address...';
  BitmapDescriptor? customMarkerIcon;
  bool isFetchingAddress = false;
  bool isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _preloadCustomMarker();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _preloadCustomMarker() async {
    customMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/source.png',
    );
  }

  Future<void> _getCurrentLocation() async {
    location.Location loc = location.Location();

    bool serviceEnabled = await loc.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await loc.requestService();
      if (!serviceEnabled) return;
    }

    location.PermissionStatus permissionGranted = await loc.hasPermission();
    if (permissionGranted == location.PermissionStatus.denied) {
      permissionGranted = await loc.requestPermission();
      if (permissionGranted != location.PermissionStatus.granted) return;
    }

    final locData = await loc.getLocation();
    if (locData.latitude != null && locData.longitude != null) {
      setState(() {
        currentLocation = LatLng(locData.latitude!, locData.longitude!);
        selectedLocation = currentLocation;
        isLoading = false;
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLng(currentLocation),
      );

      _getAddressFromLatLng(currentLocation);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    if (isFetchingAddress) return;

    setState(() {
      isFetchingAddress = true;
      selectedAddress = 'Fetching address...';
    });

    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks.first;
        setState(() {
          selectedAddress =
          '${place.locality}';
          bookingRideController.prefilled.value = place.name??'';
        });
      } else {
        setState(() {
          selectedAddress = 'Address not found';
        });
      }
    } catch (e) {
      setState(() {
        selectedAddress = 'Error fetching address';
      });
    } finally {
      setState(() {
        isFetchingAddress = false;
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        selectedLocation = position.target;
        selectedAddress = 'Fetching address...';
      });
      _getAddressFromLatLng(selectedLocation);
    });
  }

  Future<void> _getAddressAndPrefillFromLatLng(LatLng latLng) async {
    try {
      List<geocoding.Placemark> placemarks =
      await geocoding.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isEmpty) {
        return;
      }

      final place = placemarks.first;
      final components = <String>[
        place.name ?? '',
        place.street ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.administrativeArea ?? '',
        place.postalCode ?? '',
        place.country ?? '',
      ];
      final fullAddress =
      components.where((s) => s.trim().isNotEmpty).join(', ');

      await searchController.searchPlaces(fullAddress, context);

      final suggestion = placeSearchController.suggestions.first;

      bookingRideController.prefilled.value = suggestion.primaryText;
      placeSearchController.placeId.value = suggestion.placeId;

      placeSearchController.getLatLngDetails(suggestion.placeId, context);

      await StorageServices.instance.save(
          'sourcePlaceId', suggestion.placeId);
      await StorageServices.instance.save(
          'sourceTitle', suggestion.primaryText);
      await StorageServices.instance.save(
          'sourceCity', suggestion.city);
      await StorageServices.instance.save(
          'sourceState', suggestion.state);
      await StorageServices.instance.save(
          'sourceCountry', suggestion.country);

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
        await StorageServices.instance.save(
            'sourceTypes', jsonEncode(suggestion.types));
      }
      if (suggestion.terms.isNotEmpty) {
        await StorageServices.instance.save(
            'sourceTerms', jsonEncode(suggestion.terms));
      }

      print('Saved country: ${suggestion.country}');
    } catch (e) {
      print('Error in prefill: $e');
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Choose location", style: CommonFonts.appBarText),
      ),
      body: isLoading
          ? const Center(child: PopupLoader(message: 'Loading...'))
          : Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.93,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            offset: Offset(0, 3),
                            blurRadius: 12.0,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 8.0),
                        leading: Icon(
                          Icons.location_on,
                          color: Color(0xFFE5383F),
                        ),
                        title: Text(
                          selectedAddress,
                          style: CommonFonts.prefixTextAuth,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                            onPressed: () {
                              GoRouter.of(context).pop();
                            },
                            icon: Icon(
                              Icons.cancel_outlined,
                              color: AppColors.greyText2,
                            )),
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: selectedLocation,
                          zoom: 14,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        onCameraMove: _onCameraMove,
                        markers: {},
                        onMapCreated: (controller) {
                          mapController = controller;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                margin: EdgeInsets.only(
                    bottom: 16, left: 16, right: 16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await PopupLoader(message: 'Saving Location...');
                    await _getAddressAndPrefillFromLatLng(
                        selectedLocation);
                    Navigator.pop(context); // close loader
                    widget.onLocationSelected(
                      selectedLocation.latitude,
                      selectedLocation.longitude,
                      selectedAddress,
                    );
                    Navigator.pop(context); // close screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Confirm Location",
                    style: CommonFonts.primaryButtonText,
                  ),
                ),
              ),
            ],
          ),

          // Marker
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 24,
            left: MediaQuery.of(context).size.width / 2 - 24,
            child: Image.asset(
              'assets/images/source.png',
              height: 50,
            ),
          ),

          Positioned(
            right: 12,
            bottom: MediaQuery.of(context).size.height * 0.24,
            child: SizedBox(
              width: 40,
              height: 40,
              child: FloatingActionButton(
                onPressed: () {
                  mapController?.animateCamera(
                    CameraUpdate.newLatLng(currentLocation),
                  );
                  setState(() {
                    selectedLocation = currentLocation;
                  });
                },
                backgroundColor: AppColors.bgGreen2,
                child: Icon(
                  Icons.my_location,
                  color: AppColors.prefixAuthText,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
