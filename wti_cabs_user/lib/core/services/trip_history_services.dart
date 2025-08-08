import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TripHistoryService {
  static const String _key = 'recent_trips';

  // Save or update trip
  static Future<void> recordTrip(
      String pickupTitle,
      String pickupPlaceId,
      String dropTitle,
      String dropPlaceId,
      ) async {
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

    // Save all trips without trimming
    await prefs.setString(_key, jsonEncode(trips));
  }

  // Get all stored trips
  static Future<List<Map<String, dynamic>>> getAllTrips() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  // Optional: clear history
  static Future<void> clearHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
