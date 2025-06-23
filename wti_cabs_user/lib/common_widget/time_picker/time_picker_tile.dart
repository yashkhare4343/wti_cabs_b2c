import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/controller/booking_ride_controller.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class TimePickerTile extends StatefulWidget {
  final String label;
  final DateTime initialTime;
  final ValueChanged<DateTime> onTimeSelected;

  /// Accepts either PlaceSearchController or DropPlaceSearchController
  final dynamic controller;

  /// Optionally override booking controller (pickup/drop separation)
  final Rx<DateTime>? controllerTime;

  const TimePickerTile({
    super.key,
    required this.label,
    required this.initialTime,
    required this.onTimeSelected,
    required this.controller,
    this.controllerTime,
  });

  @override
  State<TimePickerTile> createState() => _TimePickerTileState();
}

class _TimePickerTileState extends State<TimePickerTile> {
  late dynamic controller;
  late Rx<DateTime> timeObservable;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    timeObservable = widget.controllerTime ?? Get.find<BookingRideController>().localStartTime;
  }

  DateTime? _getActualLocalDateTime() {
    final actualTimeStr = controller.findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime;
    final offset = controller.findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet;
    if (actualTimeStr != null && offset != null) {
      try {
        final utc = DateTime.parse(actualTimeStr).toUtc();
        return utc.add(Duration(minutes: -offset));
      } catch (e) {
        debugPrint('Error parsing actualDateTime: $e');
      }
    }
    return null;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Duration _roundToNearestInterval(Duration duration, int interval) {
    final minutes = duration.inMinutes;
    final roundedMinutes = ((minutes + interval ~/ 2) ~/ interval) * interval;
    return Duration(minutes: roundedMinutes);
  }

  void _showCupertinoTimePicker(BuildContext context) {
    final actualLocal = _getActualLocalDateTime() ?? DateTime.now();
    final current = timeObservable.value;

    final isToday = _isSameDate(current, actualLocal);
    final Duration minimumDuration = isToday
        ? Duration(hours: actualLocal.hour, minutes: actualLocal.minute)
        : Duration.zero;

    final Duration initialDuration = Duration(
      hours: current.hour,
      minutes: current.minute,
    );

    final Duration clampedInitialDuration = _roundToNearestInterval(
      initialDuration < minimumDuration ? minimumDuration : initialDuration,
      30,
    );

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                minuteInterval: 30,
                initialTimerDuration: clampedInitialDuration,
                onTimerDurationChanged: (Duration newDuration) {
                  final Duration clamped = _roundToNearestInterval(
                    newDuration < minimumDuration ? minimumDuration : newDuration,
                    30,
                  );

                  final DateTime updated = DateTime(
                    current.year,
                    current.month,
                    current.day,
                    clamped.inHours,
                    clamped.inMinutes % 60,
                  );

                  timeObservable.value = updated;
                  widget.onTimeSelected(updated);
                },
              ),
            ),
            CupertinoButton(
              child: const Text("Done"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final formattedTime = DateFormat('hh:mm a').format(timeObservable.value);

      return GestureDetector(
        onTap: () => _showCupertinoTimePicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.lightBlueBorder, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.bgGrey3, size: 15),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: CommonFonts.bodyText5Black),
                  Text(formattedTime, style: CommonFonts.bodyText1Black),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
