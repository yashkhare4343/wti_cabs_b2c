import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
class LocationController extends GetxController {
  // For displaying/editing the address in a TextField
  final TextEditingController addressController = TextEditingController();

  // If you want a reactive string instead of controller:
  // var address = ''.obs;

  Future<void> fetchCurrentLocationAndAddress(BuildContext context) async {
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
      final LatLng latLng = LatLng(locData.latitude!, locData.longitude!);
      await _getAddressAndPrefillFromLatLng(latLng, context);
    }
  }

  Future<void> _getAddressAndPrefillFromLatLng(LatLng latLng, BuildContext context) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      print('Current lat/lng is ${latLng.latitude},${latLng.longitude}');

      if (placemarks.isEmpty) {
        addressController.text = 'Address not found';
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
      final fullAddress = components.where((s) => s.trim().isNotEmpty).join(', ');

      // Update controller text directly instead of setState
      addressController.text = fullAddress;

    } catch (e) {
      print('Error fetching location/address: $e');
      addressController.text = 'Error fetching address';
    }
  }
}
