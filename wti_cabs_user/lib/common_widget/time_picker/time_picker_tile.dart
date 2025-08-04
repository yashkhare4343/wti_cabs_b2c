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

  Future<void> _showMaterialTimePicker(BuildContext context) async {
    final actualDateTime = _getActualLocalDateTime() ?? DateTime.now();
    final currentDate = timeObservable.value;
    final isSameDay = _isSameDate(currentDate, actualDateTime);

    final TimeOfDay initial = TimeOfDay.fromDateTime(selectedTime);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final pickedDateTime = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        picked.hour,
        picked.minute,
      );

      // Restrict time selection
      if (isSameDay && pickedDateTime.isBefore(actualDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a time after ${DateFormat('hh:mm a').format(actualDateTime)}")),
        );
        return;
      }

      setState(() => selectedTime = pickedDateTime);
      timeObservable.value = pickedDateTime;
      widget.onTimeSelected(pickedDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final formattedTime = DateFormat('hh:mm a').format(timeObservable.value);

      return GestureDetector(
        onTap: () => _showMaterialTimePicker(context),
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
