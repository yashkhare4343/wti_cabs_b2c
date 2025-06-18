 // All imports unchanged...
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';
import '../../utility/constants/colors/app_colors.dart';

class TimePickerTile extends StatefulWidget {
  final String label;
  final DateTime initialTime;
  final ValueChanged<DateTime> onTimeSelected;

  const TimePickerTile({
    super.key,
    required this.label,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<TimePickerTile> createState() => _TimePickerTileState();
}

class _TimePickerTileState extends State<TimePickerTile> {
  late DateTime selectedTime;
  final PlaceSearchController placeSearchController = Get.find<PlaceSearchController>();
  final BookingRideController choosePickupController = Get.find<BookingRideController>();

  @override
  void initState() {
    super.initState();
    _initializeSelectedTime();
  }

  @override
  void didUpdateWidget(TimePickerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTime != oldWidget.initialTime) {
      _initializeSelectedTime();
    }
  }

  void _initializeSelectedTime() {
    final userDateTime = _getUserLocalDateTime();
    final actualDateTime = _getActualLocalDateTime();

    if (userDateTime != null && actualDateTime != null) {
      selectedTime = userDateTime.isBefore(actualDateTime) ? actualDateTime : userDateTime;
    } else {
      selectedTime = widget.initialTime;
    }
  }

  DateTime? _getUserLocalDateTime() {
    final utcIsoString = placeSearchController.findCntryDateTimeResponse.value
        ?.userDateTimeObject
        ?.userDateTime;

    final offsetMinutes = placeSearchController.findCntryDateTimeResponse.value
        ?.userDateTimeObject
        ?.userOffSet;

    return _convertUtcWithOffsetToLocal(utcIsoString, offsetMinutes);
  }

  DateTime? _getActualLocalDateTime() {
    final utcIsoString = placeSearchController.findCntryDateTimeResponse.value
        ?.actualDateTimeObject
        ?.actualDateTime;

    final offsetMinutes = placeSearchController.findCntryDateTimeResponse.value
        ?.actualDateTimeObject
        ?.actualOffSet;

    return _convertUtcWithOffsetToLocal(utcIsoString, offsetMinutes);
  }

  DateTime? _convertUtcWithOffsetToLocal(String? utcIsoString, int? offsetMinutes) {
    if (utcIsoString == null || offsetMinutes == null) return null;
    try {
      final utc = DateTime.parse(utcIsoString).toUtc();
      return utc.add(Duration(minutes: -(offsetMinutes)));
    } catch (_) {
      return null;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Duration roundToNearestInterval(Duration duration, int interval) {
    final minutes = duration.inMinutes;
    final remainder = minutes % interval;
    final roundedMinutes = remainder == 0 ? minutes : minutes + (interval - remainder);
    return Duration(minutes: roundedMinutes);
  }

  void _showCupertinoTimePicker(BuildContext context) {
    final actualDateTime = _getActualLocalDateTime() ?? DateTime.now();
    final userDateTime = _getUserLocalDateTime() ?? DateTime.now();

    final isToday = _isSameDate(selectedTime, userDateTime);
    final Duration minimumDuration = isToday
        ? Duration(hours: actualDateTime.hour, minutes: actualDateTime.minute)
        : Duration.zero;

    final Duration initialDuration = Duration(
      hours: selectedTime.hour,
      minutes: selectedTime.minute,
    );

    final Duration clampedInitialDuration = roundToNearestInterval(
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
                  final Duration clampedDuration = roundToNearestInterval(
                    isToday && newDuration < minimumDuration ? minimumDuration : newDuration,
                    30,
                  );

                  final currentDate = choosePickupController.localStartTime.value;

                  final newTime = DateTime(
                    currentDate.year,
                    currentDate.month,
                    currentDate.day,
                    clampedDuration.inHours,
                    clampedDuration.inMinutes % 60,
                  );

                  setState(() => selectedTime = newTime);
                  widget.onTimeSelected(newTime);
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
      final controllerTime = choosePickupController.localStartTime.value;
      final formattedTime = DateFormat('hh:mm a').format(controllerTime);

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
