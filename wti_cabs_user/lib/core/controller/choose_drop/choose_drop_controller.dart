import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/drop_location_controller/drop_location_controller.dart';
import '../../api/api_services.dart';
import '../../model/booking_engine/findCntryDateTimeResponse.dart';
import '../../model/booking_engine/suggestions_places_response.dart';
import '../../model/booking_engine/get_lat_lng_response.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../services/storage_services.dart';
import '../choose_pickup/choose_pickup_controller.dart';

class DropPlaceSearchController extends GetxController {
  final RxList<SuggestionPlacesResponse> dropSuggestions = <SuggestionPlacesResponse>[].obs;
  final BookingRideController bookingRideController = Get.find<BookingRideController>();
  final PlaceSearchController pickupController = Get.find<PlaceSearchController>();
  final DestinationLocationController destinationLocationController = Get.find<DestinationLocationController>();

  var dropLatLng = Rxn<GetLatLngResponse>();
  var dropDateTimeResponse = Rxn<FindCntryDateTimeResponse>();

  RxString prefilledDrop = "".obs;
  final Rx<DateTime> currentDateTime = Rx<DateTime>(DateTime.now());
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString dropPlaceId = ''.obs;


  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    _initializeCurrentDateTime();
  }

  void _initializeCurrentDateTime() {
    try {
      tz.initializeTimeZones();
      final timezoneName = getCurrentTimeZoneName();
      final location = tz.getLocation(timezoneName);
      final utcDateTime = DateTime.now().toUtc();
      currentDateTime.value = tz.TZDateTime.from(utcDateTime, location);
    } catch (e) {
      currentDateTime.value = DateTime.now();
    }
  }

  String getCurrentTimeZoneName() {
    tz.initializeTimeZones();
    final localOffset = DateTime.now().timeZoneOffset;
    final locations = tz.timeZoneDatabase.locations;

    for (final entry in locations.entries) {
      final location = tz.getLocation(entry.key);
      final now = tz.TZDateTime.now(location);
      if (now.timeZoneOffset == localOffset) {
        return entry.key;
      }
    }
    return 'UTC';
  }

  int getOffsetFromTimeZone(String timeZoneName) {
    try {
      final location = tz.getLocation(timeZoneName);
      final now = tz.TZDateTime.now(location);
      return -now.timeZoneOffset.inMinutes;
    } catch (e) {
      return -DateTime.now().timeZoneOffset.inMinutes;
    }
  }

  String convertDateTimeToUtcString(DateTime localDateTime) {
    final timezone = dropDateTimeResponse.value?.timeZone ?? getCurrentTimeZoneName();
    final offset = getOffsetFromTimeZone(timezone);
    final utcDateTime = localDateTime.subtract(Duration(minutes: -(offset)));
    return '${utcDateTime.toIso8601String().split('.').first}.000Z';
  }

  Future<void> searchDropPlaces(String searchedText, BuildContext context) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (searchedText.isEmpty) {
        dropSuggestions.clear();
        return;
      }

      try {
        isLoading.value = true;
        final apiService = ApiService();
        final responseData = await apiService.postRequest(
          'google/ind/$searchedText?isMobileApp=true',
          {},
          context,
        );

        final results = responseData['result'] as List?;
        if (results == null) throw Exception('No "result" key in response');

        dropSuggestions.value = results.map((e) => SuggestionPlacesResponse.fromJson(e)).toList();
      } catch (e) {
        errorMessage.value = e.toString();
        dropSuggestions.clear();
      } finally {
        isLoading.value = false;
      }
    });
  }

  Future<void> getLatLngForDrop(String placeId, BuildContext context) async {
    try {
      isLoading.value = true;
      final apiService = ApiService();

      final response = await apiService.postRequest(
        'google/getLatLongChauffeur?isMobileApp=true',
        {"place_id": placeId, "isLatLngAvailable": false},
        context,
      );

      dropLatLng.value = GetLatLngResponse.fromJson(response);
      if (dropLatLng.value == null) return;

      final timeZone = dropDateTimeResponse.value?.timeZone ?? getCurrentTimeZoneName();
      final offset = getOffsetFromTimeZone(timeZone);

      await StorageServices.instance.save('destinationLat', dropLatLng.value!.latLong.lat.toString());
      await StorageServices.instance.save('destinationLng', dropLatLng.value!.latLong.lng.toString());
      await StorageServices.instance.save('destinationCountry', dropLatLng.value!.country);
      await StorageServices.instance.save('destinationCity', dropLatLng.value!.city);

      final savedLat = await StorageServices.instance.read('destinationLat');
      final savedLng = await StorageServices.instance.read('destinationLng');
      final savedCountry = await StorageServices.instance.read('destinationCountry');
      final savedCity = await StorageServices.instance.read('destinationCity');

      print("📍 Saved Destination:");
      print("Latitude: $savedLat");
      print("Longitude: $savedLng");
      print("Country: $savedCountry");
      print("City: $savedCity");

      print('======== from model direct======' );
      print("Latitude: ${dropLatLng.value!.latLong.lat.toString()}");
      print("Longitude: ${dropLatLng.value!.latLong.lng.toString()}");
      print("Country: ${dropLatLng.value!.country}");
      print("City: ${dropLatLng.value!.city}");


      await findCountryDateTimeForDrop(
        dropLatLng.value!.latLong.lat,
        dropLatLng.value!.latLong.lng,
        dropLatLng.value!.country,
        convertDateTimeToUtcString(bookingRideController.localStartTime.value),
        offset,
        timeZone,
        2,
        context,
      );
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> findCountryDateTimeForDrop(
      double dLat,
      double dLng,
      String dCountry,
      String dateTime,
      int offset,
      String timezone,
      int tripCode,
      BuildContext context,
      ) async {
    try {
      final apiService = ApiService();
      final pickupLatLng = pickupController.getPlacesLatLng.value;

      if (pickupLatLng == null) throw Exception('Pickup LatLng not available for drop time calculation');

      final requestData = {
        "sourceLat": pickupLatLng.latLong.lat,
        "sourceLng": pickupLatLng.latLong.lng,
        "sourceCountry": pickupLatLng.country,
        "destinationLat": dLat,
        "destinationLng": dLng,
        "destinationCountry": dCountry,
        "dateTime": dateTime,
        "offset": offset,
        "timeZone": timezone,
        "tripCode": tripCode,
      };

      print('🚀 Request body for findCountryDateTimeForDrop: $requestData');

      final response = await apiService.postRequest(
        'globalSearch/findCountryAndDateTime',
        requestData,
        context,
      );

      dropDateTimeResponse.value = FindCntryDateTimeResponse.fromJson(response);

      if (dropDateTimeResponse.value != null) {
        final utcDateTime = DateTime.parse(dropDateTimeResponse.value!.userDateTimeObject!.userDateTime!);
        final location = tz.getLocation(dropDateTimeResponse.value!.timeZone ?? timezone);
        currentDateTime.value = tz.TZDateTime.from(utcDateTime, location);
      }
    } catch (e) {
      errorMessage.value = 'Drop DateTime API Error: $e';
      print(errorMessage.value);
    }
  }
}
