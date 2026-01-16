import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_drop/choose_drop_controller.dart';

import '../../core/controller/drop_location_controller/drop_location_controller.dart';
import '../../core/services/storage_services.dart';

class TripHistoryController extends GetxController {
  static const String _key = 'recent_trips';
  var topRecentTrips = <Map<String, dynamic>>[].obs;
  final DropPlaceSearchController dropPlaceSearchController =
      Get.put(DropPlaceSearchController());
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  final DestinationLocationController destinationLocationController =
      Get.put(DestinationLocationController());

  @override
  void onInit() {
    super.onInit();
    loadRecentTrips();
  }

  Future<void> loadRecentTrips() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) {
      topRecentTrips.value = [];
      return;
    }

    final trips = List<Map<String, dynamic>>.from(jsonDecode(data));

    // Sort by count descending
    trips.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Filter out duplicate pickup-drop combinations AND duplicate text
    final seenCombinations = <String>{};
    final seenTitles = <String>{};
    final uniqueTrips = <Map<String, dynamic>>[];

    for (final trip in trips) {
      final pickupTitle = trip['pickup']['title'];
      final dropTitle = trip['drop']['title'];
      final combinationKey = '$pickupTitle->$dropTitle';

      if (!seenCombinations.contains(combinationKey) &&
          !seenTitles.contains(pickupTitle) &&
          !seenTitles.contains(dropTitle)) {
        seenCombinations.add(combinationKey);
        seenTitles.add(pickupTitle);
        seenTitles.add(dropTitle);
        uniqueTrips.add(trip);
      }
    }

    topRecentTrips.value = uniqueTrips.take(4).toList();
  }

  Future<void> recordTrip(String pickupTitle, String pickupPlaceId,
      String dropTitle, String dropPlaceId, BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> trips = [];

    final existing = prefs.getString(_key);
    if (existing != null) {
      trips = List<Map<String, dynamic>>.from(jsonDecode(existing));
    }

    final index = trips.indexWhere((trip) =>
        trip['pickup']['title'] == pickupTitle &&
        trip['drop']['title'] == dropTitle);

    if (index != -1) {
      trips[index]['count'] += 1;
    } else {
      trips.add({
        'pickup': {'title': pickupTitle, 'placeId': pickupPlaceId},
        'drop': {'title': dropTitle, 'placeId': dropPlaceId},
        'count': 1,
      });
    }

    await prefs.setString(_key, jsonEncode(trips));
    await loadRecentTrips();

    // reload after saving
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    topRecentTrips.clear();
  }
}
