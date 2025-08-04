import 'dart:convert';
import 'package:wti_cabs_user/core/services/storage_services.dart';

class TripHistoryService {
  static const String _recentTripsKey = 'recent_trips';
  static const String _tripCountMapKey = 'trip_count_map';

  static Future<void> recordTrip(String pickup, String drop) async {
    final tripKey = '$drop';

    final recentJson = await StorageServices.instance.read(_recentTripsKey);
    final List<String> recentTrips = recentJson != null
        ? List<String>.from(json.decode(recentJson))
        : [];

    final countJson = await StorageServices.instance.read(_tripCountMapKey);
    final Map<String, int> tripCountMap = countJson != null
        ? Map<String, dynamic>.from(json.decode(countJson))
        .map((k, v) => MapEntry(k, v as int))
        : {};

    tripCountMap[tripKey] = (tripCountMap[tripKey] ?? 0) + 1;

    recentTrips.remove(tripKey);
    recentTrips.insert(0, tripKey);
    if (recentTrips.length > 10) {
      recentTrips.removeLast();
    }

    await StorageServices.instance.save(_tripCountMapKey, json.encode(tripCountMap));
    await StorageServices.instance.save(_recentTripsKey, json.encode(recentTrips));
  }

  static Future<List<String>> getTop2Trips() async {
    final recentJson = await StorageServices.instance.read(_recentTripsKey);
    final List<String> recentTrips = recentJson != null
        ? List<String>.from(json.decode(recentJson))
        : [];

    final countJson = await StorageServices.instance.read(_tripCountMapKey);
    final Map<String, int> tripCountMap = countJson != null
        ? Map<String, dynamic>.from(json.decode(countJson))
        .map((k, v) => MapEntry(k, v as int))
        : {};

    final sorted = recentTrips.toList()
      ..sort((a, b) {
        final countA = tripCountMap[a] ?? 0;
        final countB = tripCountMap[b] ?? 0;
        return countB.compareTo(countA);
      });

    return sorted.take(2).toList();
  }

  static Future<void> clearHistory() async {
    await StorageServices.instance.delete(_recentTripsKey);
    await StorageServices.instance.delete(_tripCountMapKey);
  }
}
