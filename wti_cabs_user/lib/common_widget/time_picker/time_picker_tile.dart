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
  late DateTime selectedTime;
  late dynamic timeZoneController;
  late Rx<DateTime> timeObservable;
  bool isInvalidTime = false;
  final BookingRideController bookingRideController = Get.put(BookingRideController());

  @override
  void initState() {
    super.initState();
    timeZoneController = widget.controller;
    timeObservable = widget.controllerTime ?? Get.find<BookingRideController>().localStartTime;
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

    print("🟡 _initializeSelectedTime() called");
    print("➡️ userDateTime: $userDateTime");
    print("➡️ actualDateTime: $actualDateTime");

    if (userDateTime != null && actualDateTime != null) {
      selectedTime = userDateTime.isBefore(actualDateTime) ? actualDateTime : userDateTime;
    } else {
      selectedTime = widget.initialTime;
    }

    print("✅ selectedTime set to: $selectedTime");
  }

  DateTime? _getUserLocalDateTime() {
    final utcIsoString = timeZoneController.findCntryDateTimeResponse.value
        ?.userDateTimeObject?.userDateTime;

    final offsetMinutes = timeZoneController.findCntryDateTimeResponse.value
        ?.userDateTimeObject?.userOffSet;

    return _convertUtcWithOffsetToLocal(utcIsoString, offsetMinutes);
  }

  DateTime? _getActualLocalDateTime() {
    final utcIsoString = timeZoneController.findCntryDateTimeResponse.value
        ?.actualDateTimeObject?.actualDateTime;

    final offsetMinutes = timeZoneController.findCntryDateTimeResponse.value
        ?.actualDateTimeObject?.actualOffSet;


    return _convertUtcWithOffsetToLocal(utcIsoString, offsetMinutes);
  }

  DateTime? _convertUtcWithOffsetToLocal(String? utcIsoString, int? offsetMinutes) {
    if (utcIsoString == null || offsetMinutes == null) return null;
    try {
      final utc = DateTime.parse(utcIsoString).toUtc();
      final local = utc.add(Duration(minutes: -offsetMinutes));
      print("🌐 Converting UTC ($utcIsoString) with offset ($offsetMinutes) to local: $local");
      return local;
    } catch (e) {
      print("❌ Error converting time: $e");
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
    final isSameDayAsActual = _isSameDate(timeObservable.value, actualDateTime);

    final Duration minimumDuration = isSameDayAsActual
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
                    final actualDateTime = _getActualLocalDateTime() ?? DateTime.now();
                    final selectedDate = timeObservable.value;

                    // Selected date + selected time from picker
                    final selectedDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      newDuration.inHours,
                      newDuration.inMinutes % 60,
                    );

                    print('yash 22 aug $selectedDateTime');

                    final bool isSameDay = _isSameDate(selectedDateTime, actualDateTime);

                    /// 👇 Truncate seconds and milliseconds from actualDateTime to ensure fair comparison
                    final actualComparable = DateTime(
                      actualDateTime.year,
                      actualDateTime.month,
                      actualDateTime.day,
                      actualDateTime.hour,
                      actualDateTime.minute,
                    );

                    setState(() {
                      isInvalidTime = isSameDay && selectedDateTime.isBefore(actualComparable);

                    });


                    bookingRideController.isInvalidTime.value = isSameDay && selectedDateTime.isBefore(actualComparable);

                    final offsetMinutes = timeZoneController.findCntryDateTimeResponse.value
                        ?.actualDateTimeObject?.actualOffSet;
                    bookingRideController.offsetMinutes?.value = offsetMinutes;
                    // Round to nearest 30 min as per your logic
                    final clampedDuration = roundToNearestInterval(newDuration, 30);

                    final adjustedDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      clampedDuration.inHours,
                      clampedDuration.inMinutes % 60,
                    );

                    setState(() => selectedTime = adjustedDateTime);
                    timeObservable.value = adjustedDateTime;
                    bookingRideController.selectedDateTime.value = adjustedDateTime;

                    widget.onTimeSelected(adjustedDateTime);
                    print('yash adjusted selected time : $adjustedDateTime');

                  }
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
            border: Border.all(color:(isInvalidTime == true)? Colors.redAccent : AppColors.lightBlueBorder, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: (isInvalidTime == true) ? Colors.redAccent : AppColors.bgGrey3, size: 15),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (isInvalidTime == true) ? Text(widget.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.redAccent)) :  Text(widget.label, style: CommonFonts.bodyText5Black),
                  (isInvalidTime == true) ? Text(formattedTime, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent)) : Text(formattedTime, style: CommonFonts.bodyText1Black),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}