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
import '../choose_drop/choose_drop_controller.dart'; // import is required

class PlaceSearchController extends GetxController {
  final RxList<SuggestionPlacesResponse> suggestions = <SuggestionPlacesResponse>[].obs;
  final BookingRideController bookingRideController = Get.find<BookingRideController>();

  var getPlacesLatLng = Rxn<GetLatLngResponse>();
  var findCntryDateTimeResponse = Rxn<FindCntryDateTimeResponse>();

  DropPlaceSearchController? dropController; // ✅ SAFE

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

    // ✅ Safely access DropPlaceSearchController if it exists
    if (Get.isRegistered<DropPlaceSearchController>()) {
      dropController = Get.find<DropPlaceSearchController>();
    }
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

  // convert utc to ISO
  String convertToIsoWithOffset(String time, int offsetInMinutes) {
    final utcTime = DateTime.parse(time); // already UTC
    final localTime = utcTime.add(Duration(minutes: offsetInMinutes));

    final sign = offsetInMinutes >= 0 ? '+' : '-';
    final hours = offsetInMinutes.abs() ~/ 60;
    final minutes = offsetInMinutes.abs() % 60;
    final formattedOffset = '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

    final isoTime = localTime.toIso8601String().split('.').first;

    return '$isoTime$formattedOffset';
  }



  void updateDateTimeFromApi(FindCntryDateTimeResponse response) {
    try {
      if (response.userDateTimeObject?.userDateTime != null) {
        final utcDateTime = DateTime.parse(response.userDateTimeObject!.userDateTime!);
        final timezoneName = response.timeZone ?? getCurrentTimeZoneName();
        final location = tz.getLocation(timezoneName);
        currentDateTime.value = tz.TZDateTime.from(utcDateTime, location);
        bookingRideController.localStartTime.value = currentDateTime.value;
      }
    } catch (e) {
      errorMessage.value = 'Failed to update time: $e';
    }
  }

  String convertDateTimeToUtcString(DateTime localDateTime) {
    final timezone = findCntryDateTimeResponse.value?.timeZone ?? getCurrentTimeZoneName();
    final offset = getOffsetFromTimeZone(timezone);
    final utcDateTime = localDateTime.subtract(Duration(minutes: -(offset)));
    return '${utcDateTime.toIso8601String().split('.').first}.000Z';
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
          'google/ind/$searchedText?isMobileApp=true',
          {},
          context,
        );

        final results = responseData['result'] as List?;
        if (results == null) throw Exception('No "result" key in response');

        suggestions.value = results.map((e) => SuggestionPlacesResponse.fromJson(e)).toList();
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
      final apiService = ApiService();

      final responseData = await apiService.postRequest(
        'google/getLatLongChauffeur?isMobileApp=true',
        { "place_id": placeId, "isLatLngAvailable": false },
        context,
      );

      getPlacesLatLng.value = GetLatLngResponse.fromJson(responseData);
      if (getPlacesLatLng.value == null) return;

      await StorageServices.instance.save('sourceLat', getPlacesLatLng.value!.latLong.lat.toString());
      await StorageServices.instance.save('sourceLng', getPlacesLatLng.value!.latLong.lng.toString());
      await StorageServices.instance.save('sourceCountry', getPlacesLatLng.value!.country);
      await StorageServices.instance.save('sourceCity', getPlacesLatLng.value!.city);

      final savedLat = await StorageServices.instance.read('sourceLat');
      final savedLng = await StorageServices.instance.read('sourceLng');
      final savedCountry = await StorageServices.instance.read('sourceCountry');
      final savedCity = await StorageServices.instance.read('sourceCity');

      print("📍 Saved Source place:");
      print("Latitude: $savedLat");
      print("Longitude: $savedLng");
      print("Country: $savedCountry");
      print("City: $savedCity");

      print('======== from model direct source======' );
      print("Latitude: ${getPlacesLatLng.value!.latLong.lat.toString()}");
      print("Longitude: ${getPlacesLatLng.value!.latLong.lng.toString()}");
      print("Country: ${getPlacesLatLng.value!.country}");
      print("City: ${getPlacesLatLng.value!.city}");

      final timeZone = findCntryDateTimeResponse.value?.timeZone ?? getCurrentTimeZoneName();
      final offset = getOffsetFromTimeZone(timeZone);

      await findCountryDateTime(
        getPlacesLatLng.value!.latLong.lat,
        getPlacesLatLng.value!.latLong.lng,
        getPlacesLatLng.value!.country,
        dropController?.dropLatLng.value?.country ?? getPlacesLatLng.value!.country,
        dropController?.dropLatLng.value?.latLong.lat ?? getPlacesLatLng.value!.latLong.lat,
        dropController?.dropLatLng.value?.latLong.lng ?? getPlacesLatLng.value!.latLong.lng,
        convertDateTimeToUtcString(bookingRideController.localStartTime.value),
        offset,
        timeZone,
        2,
        context,
      );

      await StorageServices.instance.save('sourceLat', getPlacesLatLng.value!.latLong.lat.toString());
      await StorageServices.instance.save('sourceLng', getPlacesLatLng.value!.latLong.lng.toString());
      await StorageServices.instance.save('country', getPlacesLatLng.value!.country);
      await StorageServices.instance.save('sourceCity', getPlacesLatLng.value!.city);



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
      final apiService = ApiService();

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

      debugPrint('request data :  $requestData');

      findCntryDateTimeResponse.value = FindCntryDateTimeResponse.fromJson(responseData);
      if (findCntryDateTimeResponse.value != null) {
        updateDateTimeFromApi(findCntryDateTimeResponse.value!);
      }
      debugPrint('response data :  $responseData');
      await StorageServices.instance.save('actualDateTime', findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime??'');
      await StorageServices.instance.save('actualOffset', findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet.toString()??'');

      await StorageServices.instance.save('userDateTime', findCntryDateTimeResponse.value?.userDateTimeObject?.userDateTime??'');
      await StorageServices.instance.save('userOffset', findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet.toString()??'');
      await StorageServices.instance.save('timeZone', findCntryDateTimeResponse.value?.timeZone??'');

      String actualTimeWithOffset = convertToIsoWithOffset(findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime??'', -(findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet??0));
      String userTimeWithOffset = convertToIsoWithOffset(findCntryDateTimeResponse.value?.userDateTimeObject?.userDateTime??'', -(findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet??0));

      await StorageServices.instance.save('actualTimeWithOffset', actualTimeWithOffset);
      await StorageServices.instance.save('userTimeWithOffset', userTimeWithOffset);


    } catch (error) {
      print("Error in findCountryDateTime: $error");
    } finally {
      isLoading.value = false;
    }
  }
}
