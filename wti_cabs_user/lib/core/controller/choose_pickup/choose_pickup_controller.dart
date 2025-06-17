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

class PlaceSearchController extends GetxController {
  final RxList<SuggestionPlacesResponse> suggestions = <SuggestionPlacesResponse>[].obs;
  final BookingRideController bookingRideController = Get.find<BookingRideController>();

  var getPlacesLatLng = Rxn<GetLatLngResponse>();
  var findCntryDateTimeResponse = Rxn<FindCntryDateTimeResponse>();

  RxString prefilledDrop = "".obs;
  final Rx<DateTime> currentDateTime = Rx<DateTime>(DateTime.now());
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString placeId = ''.obs;

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

      print('Initialized currentDateTime: ${currentDateTime.value} in $timezoneName');
    } catch (e) {
      print('Error initializing currentDateTime: $e, using device time');
      currentDateTime.value = DateTime.now();
    }
  }

  void updateDateTimeFromApi(FindCntryDateTimeResponse response) {
    try {
      if (response.userDateTimeObject?.userDateTime != null) {
        final utcDateTime = DateTime.parse(response.userDateTimeObject!.userDateTime!);
        final timezoneName = response.timeZone ?? getCurrentTimeZoneName();
        final location = tz.getLocation(timezoneName);
        currentDateTime.value = tz.TZDateTime.from(utcDateTime, location);

        // ✅ Directly assign DateTime
        bookingRideController.localStartTime.value = currentDateTime.value;

        // ✅ You can still print formatted string for logs
        final formattedLocalTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentDateTime.value);
        print('Updated currentDateTime: ${currentDateTime.value} in $timezoneName');
        print('Updated local time in BookingRideController: $formattedLocalTime');
      } else {
        print('No valid actualDateTimeObject in API response, retaining current time');
      }
    } catch (e) {
      print('Error updating currentDateTime from API: $e');
      errorMessage.value = 'Failed to update time: $e';
    }
  }

  String convertDateTimeToUtcString(DateTime localDateTime) {
    final utcDateTime = localDateTime.toUtc();
    return '${utcDateTime.toIso8601String().split('.').first}.000Z';
  }

  int getBackendCompatibleOffset() {
    return -currentDateTime.value.timeZoneOffset.inMinutes;
  }

  String getCurrentTimeZoneName() {
    tz.initializeTimeZones();
    final localOffset = DateTime.now().timeZoneOffset;
    final locations = tz.timeZoneDatabase.locations;

    for (final entry in locations.entries) {
      final location = tz.getLocation(entry.key);
      final now = tz.TZDateTime.now(location);
      if (now.timeZoneOffset == localOffset) {
        print("Matched timezone: ${entry.key}");
        return entry.key;
      }
    }
    return 'UTC';
  }

  Future<void> searchPlaces(String searchedText, BuildContext context) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (searchedText.isEmpty) {
        suggestions.clear();
        return;
      }

      try {
        isLoading.value = true;
        final apiService = ApiService();
        final responseData = await apiService.postRequest(
            'google/ind/$searchedText?isMobileView=false',
            {},
            context);

        final results = responseData['result'] as List?;
        if (results == null) throw Exception('No "result" key in response');

        suggestions.value = results.map((e) => SuggestionPlacesResponse.fromJson(e)).toList();
        print('Suggestions: ${suggestions.map((s) => s.toJson()).toList()}');
      } catch (e) {
        print("Error fetching suggestions: $e");
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
      final apiService = ApiService();

      final responseData = await apiService.postRequest(
          'google/getLatLongChauffeur',
          { "place_id": placeId, "isLatLngAvailable": false },
          context);

      getPlacesLatLng.value = GetLatLngResponse.fromJson(responseData);
      print('Parsed getPlacesLatLng: ${getPlacesLatLng.value}');

      if (getPlacesLatLng.value == null) {
        print('LatLng is null, skipping findCountryDateTime');
        return;
      }

      await findCountryDateTime(
        getPlacesLatLng.value!.latLong.lat,
        getPlacesLatLng.value!.latLong.lng,
        getPlacesLatLng.value!.country,
        getPlacesLatLng.value!.country,
        getPlacesLatLng.value!.latLong.lat,
        getPlacesLatLng.value!.latLong.lng,
        convertDateTimeToUtcString(currentDateTime.value),
        getBackendCompatibleOffset(),
        getCurrentTimeZoneName(),
        2,
        context,
      );

    } catch (error) {
      print("Error fetching lat/lng details: $error");
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }


  // abhi time to sahi ja rha hai but wo utc time hi ho rha hai usko local date time mein show karna hai
  // and wapas usko selected local time ko utc mein convert karke send krna hai.


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
      BuildContext context) async {
    try {
      isLoading.value = true;
      final apiService = ApiService();

      // Use response timezone if available, else fall back to provided timezone
      final requestTimezone = findCntryDateTimeResponse.value?.timeZone ?? timezone;

      final requestData = {
        "sourceLat": bookingRideController.prefilled.value.isNotEmpty && getPlacesLatLng.value != null
            ? getPlacesLatLng.value!.latLong.lat
            : sLat,
        "sourceLng": bookingRideController.prefilled.value.isNotEmpty && getPlacesLatLng.value != null
            ? getPlacesLatLng.value!.latLong.lng
            : sLng,
        "sourceCountry": bookingRideController.prefilled.value.isNotEmpty && getPlacesLatLng.value != null
            ? getPlacesLatLng.value!.country
            : sCountry,
        "destinationCountry": prefilledDrop.value.isNotEmpty && getPlacesLatLng.value != null
            ? getPlacesLatLng.value!.country
            : dCountry,
        "destinationLat": prefilledDrop.value.isNotEmpty && getPlacesLatLng.value != null
            ? getPlacesLatLng.value!.latLong.lat
            : dLat,
        "destinationLng": prefilledDrop.value.isNotEmpty && getPlacesLatLng.value != null
            ? getPlacesLatLng.value!.latLong.lng
            : dLng,
        "dateTime": dateTime,
        "offset": offset,
        "timeZone": requestTimezone,
        "tripCode": tripCode,
      };

      print('Request data: $requestData');

      final responseData = await apiService.postRequest(
          'globalSearch/findCountryAndDateTime', requestData, context);

      findCntryDateTimeResponse.value = FindCntryDateTimeResponse.fromJson(responseData);
      print('API response: ${findCntryDateTimeResponse.value?.toJson()}');

      if (findCntryDateTimeResponse.value != null) {
        updateDateTimeFromApi(findCntryDateTimeResponse.value!);
      }

    } catch (error) {
      print("Error in findCountryDateTime: $error");
    } finally {
      isLoading.value = false;
    }
  }
}


