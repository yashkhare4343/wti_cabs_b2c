import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:wti_cabs_user/core/api/corporate/cpr_api_services.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_cab_tracking/crp_cab_tracking_response.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';

class CrpCabTrackingController extends GetxController {
  final CprApiService _apiService = CprApiService();
  
  // Google API Key
  final String googleApiKey = "AIzaSyCWbmCiquOta1iF6um7_5_NFh6YM5wPL30";
  
  // Observable state
  var isLoading = true.obs;
  var trackingResponse = Rxn<CrpCabTrackingResponse>();
  var errorMessage = ''.obs;
  var isPolling = false.obs;
  var routePoints = <LatLng>[].obs;
  var isLoadingRoute = false.obs;
  
  // Timer for polling
  Timer? _pollingTimer;
  
  // Booking ID
  String? _bookingId;
  
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }

  /// Start tracking for a booking
  Future<void> startTracking(String bookingId) async {
    _bookingId = bookingId;
    isLoading.value = true;
    errorMessage.value = '';
    
    // Fetch initial data
    await fetchTrackingData();
    
    // Start polling if ride is active
    if (trackingResponse.value?.isRideActive == true) {
      startPolling();
    }
  }

  /// Fetch tracking data from API
  Future<void> fetchTrackingData() async {
    if (_bookingId == null || _bookingId!.isEmpty) {
      errorMessage.value = 'Booking ID is required';
      isLoading.value = false;
      return;
    }

    try {
      // Only set loading on first fetch
      if (trackingResponse.value == null) {
        isLoading.value = true;
      }

      // Cab tracking API expects `user` and `token` in query payload as well.
      final token = await StorageServices.instance.read('crpKey');
      final userEmail = await StorageServices.instance.read('email');

      final params = <String, String>{
        'BookingID': _bookingId!,
        if (token != null && token.isNotEmpty && token != 'null') 'token': token,
        if (userEmail != null && userEmail.isNotEmpty && userEmail != 'null')
          'user': userEmail,
      };

      final endpoint = Uri.parse('CabTrackingV1')
          .replace(queryParameters: params)
          .toString();

      final response = await _apiService.getRequest(endpoint);
      
      final trackingData = CrpCabTrackingResponse.fromJson(response);
      trackingResponse.value = trackingData;
      
      // Stop polling if ride is completed
      if (trackingData.isRideCompleted) {
        stopPolling();
      }
      
      errorMessage.value = '';
    } catch (e) {
      debugPrint('❌ Error fetching tracking data: $e');
      errorMessage.value = e.toString();
      
      // Don't update trackingResponse on error to keep last known position
    } finally {
      isLoading.value = false;
    }
  }

  /// Start polling every 5 seconds
  void startPolling() {
    if (isPolling.value) {
      return; // Already polling
    }
    
    isPolling.value = true;
    
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        // Keep polling while tracking is active; fetchTrackingData will stopPolling on completion
        if (trackingResponse.value?.isRideActive == true) {
          await fetchTrackingData();
        } else {
          stopPolling();
        }
      },
    );
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    isPolling.value = false;
  }

  /// Fetch route from Google Directions API
  Future<void> fetchRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      isLoadingRoute.value = true;

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
            '?origin=$originLat,$originLng'
            '&destination=$destLat,$destLng'
            '&key=$googleApiKey',
      );

      final response = await _apiService.sendRequestWithRetry(() => http.get(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final overviewPolyline = route['overview_polyline'];
          final encodedPolyline = overviewPolyline['points'] as String;

          // Decode the polyline
          final decodedPoints = _decodePolyline(encodedPolyline);
          routePoints.value = decodedPoints;
        } else {
          debugPrint('Directions API error: ${data['status']}');
          routePoints.value = [];
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        routePoints.value = [];
      }
    } catch (e) {
      debugPrint('Error fetching directions: $e');
      routePoints.value = [];
    } finally {
      isLoadingRoute.value = false;
    }
  }

  /// Decodes Google's encoded polyline string into a list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      // Decode latitude
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;

      // Decode longitude
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  /// Reset controller state
  void reset() {
    stopPolling();
    trackingResponse.value = null;
    errorMessage.value = '';
    isLoading.value = true;
    routePoints.value = [];
    _bookingId = null;
  }
}

