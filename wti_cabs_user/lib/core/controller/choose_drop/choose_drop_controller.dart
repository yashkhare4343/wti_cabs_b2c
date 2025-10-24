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
  final apiService = ApiService(); // Reuse single instance
  final storage = StorageServices.instance; // Reuse storage instance

  var dropLatLng = Rxn<GetLatLngResponse>();
  var dropDateTimeResponse = Rxn<FindCntryDateTimeResponse>();

  RxString prefilledDrop = "".obs;
  final Rx<DateTime> currentDateTime = Rx<DateTime>(DateTime.now());
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString dropPlaceId = ''.obs;

  Timer? _debounce;
  String? _cachedTimeZone; // Cache timezone to avoid repeated lookups

  @override
  void onInit() {
    super.onInit();
    _initializeCurrentDateTime();
  }

  void _initializeCurrentDateTime() {
    try {
      tz.initializeTimeZones();
      _cachedTimeZone = getCurrentTimeZoneName();
      final location = tz.getLocation(_cachedTimeZone!);
      currentDateTime.value = tz.TZDateTime.from(DateTime.now().toUtc(), location);
    } catch (e) {
      currentDateTime.value = DateTime.now();
    }
  }

  String getCurrentTimeZoneName() {
    if (_cachedTimeZone != null) return _cachedTimeZone!;

    tz.initializeTimeZones();
    final localOffset = DateTime.now().timeZoneOffset;
    for (final entry in tz.timeZoneDatabase.locations.entries) {
      if (tz.TZDateTime.now(tz.getLocation(entry.key)).timeZoneOffset == localOffset) {
        _cachedTimeZone = entry.key;
        return entry.key;
      }
    }
    _cachedTimeZone = 'UTC';
    return 'UTC';
  }

  int getOffsetFromTimeZone(String timeZoneName) {
    try {
      return -tz.TZDateTime.now(tz.getLocation(timeZoneName)).timeZoneOffset.inMinutes;
    } catch (e) {
      return -DateTime.now().timeZoneOffset.inMinutes;
    }
  }

  String convertDateTimeToUtcString(DateTime localDateTime) {
    final timezone = _cachedTimeZone ?? dropDateTimeResponse.value?.timeZone ?? getCurrentTimeZoneName();
    final offset = getOffsetFromTimeZone(timezone);
    final utcDateTime = localDateTime.subtract(Duration(minutes: -offset));
    return '${utcDateTime.toIso8601String().split('.').first}.000Z';
  }

  Future<void> searchDropPlaces(String searchedText, BuildContext context) async {
    _debounce?.cancel();
    if (searchedText.isEmpty) {
      dropSuggestions.clear();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        isLoading.value = true;
        final responseData = await apiService.postRequest(
          'google/ind/$searchedText?isMobileApp=true',
          {},
          context,
        );

        final results = responseData['result'] as List?;
        dropSuggestions.value = results?.map((e) => SuggestionPlacesResponse.fromJson(e)).toList() ?? [];
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
      final response = await apiService.postRequest(
        'google/getLatLongChauffeur?isMobileApp=true',
        {"place_id": placeId, "isLatLngAvailable": false},
        context,
      );

      dropLatLng.value = GetLatLngResponse.fromJson(response);
      if (dropLatLng.value == null) return;

      // Batch storage operations
      final latLng = dropLatLng.value!.latLong;
      final storageFutures = [
        storage.save('destinationLat', latLng.lat.toString()),
        storage.save('destinationLng', latLng.lng.toString()),
        storage.save('destinationCountry', dropLatLng.value!.country),
        storage.save('destinationCity', dropLatLng.value!.city),
      ];
      await Future.wait(storageFutures);

      // Cache values for logging
      final savedValues = await Future.wait([
        storage.read('destinationLat'),
        storage.read('destinationLng'),
        storage.read('destinationCountry'),
        storage.read('destinationCity'),
      ]);

      // Log only in debug mode
      debugPrint('📍 Saved Destination:');
      debugPrint('Latitude: ${savedValues[0]}');
      debugPrint('Longitude: ${savedValues[1]}');
      debugPrint('Country: ${savedValues[2]}');
      debugPrint('City: ${savedValues[3]}');
      debugPrint('======== from model direct ======');
      debugPrint('Latitude: ${latLng.lat}');
      debugPrint('Longitude: ${latLng.lng}');
      debugPrint('Country: ${dropLatLng.value!.country}');
      debugPrint('City: ${dropLatLng.value!.city}');

      final timeZone = _cachedTimeZone ?? dropDateTimeResponse.value?.timeZone ?? getCurrentTimeZoneName();
      final offset = getOffsetFromTimeZone(timeZone);

      await findCountryDateTimeForDrop(
        latLng.lat,
        latLng.lng,
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
    final pickupLatLng = pickupController.getPlacesLatLng.value;

    final requestData = {
      "sourceLat": pickupLatLng?.latLong.lat,
      "sourceLng": pickupLatLng?.latLong.lng,
      "sourceCountry": pickupLatLng?.country,
      "destinationLat": dLat,
      "destinationLng": dLng,
      "destinationCountry": dCountry,
      "dateTime": dateTime,
      "offset": offset,
      "timeZone": timezone,
      "tripCode": tripCode,
    };
    print('yash choose drop request body : $requestData');
    if (pickupLatLng == null) throw Exception('Pickup LatLng not available for drop time calculation');
    try {
      debugPrint('🚀 Request body for findCountryDateTimeForDrop: $requestData');

      final response = await apiService.postRequest(
        'globalSearch/findCountryAndDateTime',
        requestData,
        context,
      );

      dropDateTimeResponse.value = FindCntryDateTimeResponse.fromJson(response);
      if (dropDateTimeResponse.value?.userDateTimeObject?.userDateTime != null) {
        final timeZone = dropDateTimeResponse.value!.timeZone ?? timezone;
        _cachedTimeZone = timeZone; // Update cache
        currentDateTime.value = tz.TZDateTime.from(
          DateTime.parse(dropDateTimeResponse.value!.userDateTimeObject!.userDateTime!),
          tz.getLocation(timeZone),
        );
      }
    } catch (e) {
      errorMessage.value = 'Drop DateTime API Error: $e';
      debugPrint(errorMessage.value);
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}