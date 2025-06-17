import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';

import '../../core/controller/choose_pickup/choose_pickup_controller.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class DatePickerTile extends StatefulWidget {
  final String label;
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const DatePickerTile({
    super.key,
    required this.label,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<DatePickerTile> createState() => _DatePickerTileState();
}

class _DatePickerTileState extends State<DatePickerTile> {
  late DateTime selectedDate;
  final PlaceSearchController placeSearchController = Get.find<PlaceSearchController>();

  @override
  void initState() {
    super.initState();
    _initializeSelectedDate();
  }

  @override
  void didUpdateWidget(DatePickerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _initializeSelectedDate();
    }
  }

  void _initializeSelectedDate() {
    final now = placeSearchController.currentDateTime.value;
    selectedDate = widget.initialDate.isBefore(now) ? now : widget.initialDate;
  }


  /// Used in UI — converted user-selected time
  DateTime? _getUserLocalDateTime() {
    final utcIsoString = placeSearchController.findCntryDateTimeResponse.value
        ?.userDateTimeObject
        ?.userDateTime;

    final offsetMinutes = placeSearchController.findCntryDateTimeResponse.value
        ?.userDateTimeObject
        ?.userOffSet;

    return _convertUtcWithOffsetToLocal(utcIsoString, offsetMinutes);
  }

  /// Used for logic like minDate — actual server time
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
      return utc.add(Duration(minutes: offsetMinutes));
    } catch (e) {
      print("❌ Error converting UTC to local: $e");
      return null;
    }
  }

  void _showCupertinoDatePicker(BuildContext context) {
    final DateTime now = placeSearchController.currentDateTime.value;
    final DateTime minDate = _getActualLocalDateTime() ?? now;

    // Use selectedDate, but ensure it's not earlier than minDate
    final DateTime initialDateTime =
    selectedDate.isBefore(minDate) ? minDate : selectedDate;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: Colors.white,
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: _getActualLocalDateTime(),
                mode: CupertinoDatePickerMode.date,
                minimumDate: minDate,
                onDateTimeChanged: (newDate) {
                  setState(() => selectedDate = newDate);
                  widget.onDateSelected(newDate);
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
    final formattedDate = DateFormat('dd MMM, yyyy').format(selectedDate);

    return GestureDetector(
      onTap: () => _showCupertinoDatePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.lightBlueBorder, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: AppColors.bgGrey3, size: 15),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: CommonFonts.bodyText5Black),
                Text(formattedDate, style: CommonFonts.bodyText1Black),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
