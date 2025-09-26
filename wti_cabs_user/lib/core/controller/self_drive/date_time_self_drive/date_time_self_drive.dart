import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Controller to manage From and To date/time
class DateTimeController {
  DateTime fromDate;
  TimeOfDay fromTime;
  DateTime toDate;
  TimeOfDay toTime;

  DateTimeController({
    required this.fromDate,
    required this.fromTime,
  }) : toDate = fromDate.add(Duration(days: 1)), // Initialize toDate 1 day after fromDate
        toTime = fromTime; // Keep same time as fromTime initially

  void updateFromDateTime(DateTime newDate, TimeOfDay newTime) {
    fromDate = newDate;
    fromTime = newTime;
    // Ensure toDate is at least 1 day after fromDate
    if (toDate.isBefore(fromDate.add(Duration(days: 1)))) {
      toDate = fromDate.add(Duration(days: 1));
      toTime = fromTime; // Keep same time as fromTime
    }
  }

  void updateToDateTime(DateTime newDate, TimeOfDay newTime) {
    toDate = newDate;
    toTime = newTime;
  }
}