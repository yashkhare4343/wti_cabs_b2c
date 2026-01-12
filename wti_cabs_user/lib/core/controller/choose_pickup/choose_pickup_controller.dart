import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/model/booking_engine/get_lat_lng_response.dart';
import '../../api/api_services.dart';
import '../../model/booking_engine/findCntryDateTimeResponse.dart';
import '../../model/booking_engine/suggestions_places_response.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../services/storage_services.dart';
import '../choose_drop/choose_drop_controller.dart';

class PlaceSearchController extends GetxController {
  final RxList<SuggestionPlacesResponse> suggestions = <SuggestionPlacesResponse>[].obs;
  final BookingRideController bookingRideController = Get.find<BookingRideController>();
  final apiService = ApiService(); // Reuse single instance
  final storage = StorageServices.instance; // Reuse storage instance

  var getPlacesLatLng = Rxn<GetLatLngResponse>();
  var findCntryDateTimeResponse = Rxn<FindCntryDateTimeResponse>();
  DropPlaceSearchController? dropController;

  RxString prefilledDrop = "".obs;
  final Rx<DateTime> currentDateTime = Rx<DateTime>(DateTime.now());
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString placeId = ''.obs;

  Timer? _debounce;
  String? _cachedTimeZone; // Cache timezone to avoid repeated lookups

  @override
  void onInit() {
    super.onInit();
    _initializeCurrentDateTime();
    if (Get.isRegistered<DropPlaceSearchController>()) {
      dropController = Get.find<DropPlaceSearchController>();
    }
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

  String convertToIsoWithOffset(String time, int offsetInMinutes) {
    final utcTime = DateTime.parse(time);
    final localTime = utcTime.add(Duration(minutes: offsetInMinutes));
    final sign = offsetInMinutes >= 0 ? '+' : '-';
    final hours = offsetInMinutes.abs() ~/ 60;
    final minutes = offsetInMinutes.abs() % 60;
    return '${localTime.toIso8601String().split('.').first}$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  void updateDateTimeFromApi(FindCntryDateTimeResponse response) {
    try {
      if (response.userDateTimeObject?.userDateTime != null) {
        _cachedTimeZone = response.timeZone ?? _cachedTimeZone ?? getCurrentTimeZoneName();
        final location = tz.getLocation(_cachedTimeZone!);
        currentDateTime.value = tz.TZDateTime.from(
          DateTime.parse(response.userDateTimeObject!.userDateTime!),
          location,
        );
        bookingRideController.localStartTime.value = currentDateTime.value;
      }
    } catch (e) {
      errorMessage.value = 'Failed to update time: $e';
    }
  }

  String convertDateTimeToUtcString(DateTime localDateTime) {
    final timezone = _cachedTimeZone ?? findCntryDateTimeResponse.value?.timeZone ?? getCurrentTimeZoneName();
    final offset = getOffsetFromTimeZone(timezone);
    final utcDateTime = localDateTime.subtract(Duration(minutes: -offset));
    return '${utcDateTime.toIso8601String().split('.').first}.000Z';
  }

  int getOffsetFromTimeZone(String timeZoneName) {
    try {
      final location = tz.getLocation(timeZoneName);
      return -tz.TZDateTime.now(location).timeZoneOffset.inMinutes;
    } catch (e) {
      return -DateTime.now().timeZoneOffset.inMinutes;
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

  Future<void> searchPlaces(String searchedText, BuildContext context) async {
    _debounce?.cancel();
    if (searchedText.isEmpty) {
      suggestions.clear();
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
        suggestions.value = results?.map((e) => SuggestionPlacesResponse.fromJson(e)).toList() ?? [];
      } catch (e) {
        errorMessage.value = e.toString();
        suggestions.clear();
      } finally {
        isLoading.value = false;
      }
    });
  }

  Future<void> getLatLngDetails(String placeId, BuildContext context) async {
    try {
      isLoading.value = true;
      final responseData = await apiService.postRequest(
        'google/getLatLongChauffeur?isMobileApp=true',
        {"place_id": placeId, "isLatLngAvailable": false},
        context,
      );

      getPlacesLatLng.value = GetLatLngResponse.fromJson(responseData);
      if (getPlacesLatLng.value == null) return;

      // Batch storage operations
      final latLng = getPlacesLatLng.value!.latLong;
      final storageFutures = [
        storage.save('sourceLat', latLng.lat.toString()),
        storage.save('sourceLng', latLng.lng.toString()),
        storage.save('sourceCountry', getPlacesLatLng.value!.country),
        storage.save('sourceCity', getPlacesLatLng.value!.city),
        storage.save('country', getPlacesLatLng.value!.country),
      ];
      await Future.wait(storageFutures);

      // Cache values for logging
      final savedValues = await Future.wait([
        storage.read('sourceLat'),
        storage.read('sourceLng'),
        storage.read('sourceCountry'),
        storage.read('sourceCity'),
      ]);

      // Log only in debug mode
      debugPrint('📍 Saved Source place:');
      debugPrint('Latitude: ${savedValues[0]}');
      debugPrint('Longitude: ${savedValues[1]}');
      debugPrint('Country: ${savedValues[2]}');
      debugPrint('City: ${savedValues[3]}');
      debugPrint('======== from model direct source ======');
      debugPrint('Latitude: ${latLng.lat}');
      debugPrint('Longitude: ${latLng.lng}');
      debugPrint('Country: ${getPlacesLatLng.value!.country}');
      debugPrint('City: ${getPlacesLatLng.value!.city}');

      final timeZone = _cachedTimeZone ?? findCntryDateTimeResponse.value?.timeZone ?? getCurrentTimeZoneName();
      final offset = getOffsetFromTimeZone(timeZone);

      await findCountryDateTime(
        latLng.lat,
        latLng.lng,
        getPlacesLatLng.value!.country,
        dropController?.dropLatLng.value?.country ?? getPlacesLatLng.value!.country,
        dropController?.dropLatLng.value?.latLong.lat ?? latLng.lat,
        dropController?.dropLatLng.value?.latLong.lng ?? latLng.lng,
        convertDateTimeToUtcString(bookingRideController.localStartTime.value),
        offset,
        timeZone,
        2,
        context,
      );
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> findCountryDateTime(
      double sLat,
      double sLng,
      String sCountry,
      String dCountry,
      double dLat,
      double dLng,
      String dateTime,
      int offset,
      String timezone,
      int tripCode,
      BuildContext context,
      ) async {
    try {
      isLoading.value = true;
      final requestData = {
        "sourceLat": sLat,
        "sourceLng": sLng,
        "sourceCountry": sCountry,
        "destinationLat": dLat,
        "destinationLng": dLng,
        "destinationCountry": dCountry,
        "dateTime": dateTime,
        "offset": offset,
        "timeZone": timezone,
        "tripCode": tripCode,
      };

      final responseData = await apiService.postRequest(
        'globalSearch/findCountryAndDateTime',
        requestData,
        context,
      );

      findCntryDateTimeResponse.value = FindCntryDateTimeResponse.fromJson(responseData);
      if (findCntryDateTimeResponse.value == null) return;

      updateDateTimeFromApi(findCntryDateTimeResponse.value!);

      // Batch storage operations
      final response = findCntryDateTimeResponse.value!;
      final actualDateTime = response.actualDateTimeObject?.actualDateTime ?? '';
      final userDateTime = response.userDateTimeObject?.userDateTime ?? '';
      final storageFutures = [
        storage.save('actualDateTime', actualDateTime),
        storage.save('actualOffset', response.actualDateTimeObject?.actualOffSet.toString() ?? ''),
        storage.save('userDateTime', userDateTime),
        storage.save('userOffset', response.userDateTimeObject?.userOffSet.toString() ?? ''),
        storage.save('timeZone', response.timeZone ?? ''),
        storage.save('actualTimeWithOffset', convertToIsoWithOffset(actualDateTime, -(response.actualDateTimeObject?.actualOffSet ?? 0))),
        storage.save('userTimeWithOffset', convertToIsoWithOffset(userDateTime, -(response.userDateTimeObject?.userOffSet ?? 0))),
      ];
      await Future.wait(storageFutures);

      debugPrint('request data: $requestData');
      debugPrint('response data: $responseData');
    } catch (error) {
      debugPrint("Error in findCountryDateTime: $error");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}