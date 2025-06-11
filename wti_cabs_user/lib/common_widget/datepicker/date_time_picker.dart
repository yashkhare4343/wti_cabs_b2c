import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';
import '../../utility/constants/colors/app_colors.dart';

class DateTimePickerTile extends StatefulWidget {
  final String label;
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onDateTimeSelected;

  const DateTimePickerTile({
    super.key,
    required this.label,
    required this.initialDateTime,
    required this.onDateTimeSelected,
  });

  @override
  State<DateTimePickerTile> createState() => _DateTimePickerTileState();
}

class _DateTimePickerTileState extends State<DateTimePickerTile> {
  late DateTime selectedDateTime;
  final PlaceSearchController placeSearchController = Get.find<PlaceSearchController>();

  @override
  void initState() {
    super.initState();
    _initializeSelectedDateTime();
  }

  @override
  void didUpdateWidget(DateTimePickerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDateTime != oldWidget.initialDateTime) {
      _initializeSelectedDateTime();
    }
  }

  void _initializeSelectedDateTime() {
    final now = placeSearchController.currentDateTime.value;
    selectedDateTime = widget.initialDateTime.isBefore(now) ? now : widget.initialDateTime;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showCupertinoDateTimePicker(BuildContext context) {
    final DateTime now = placeSearchController.currentDateTime.value;

    DateTime tempPickedDateTime = selectedDateTime.isBefore(now) ? now : selectedDateTime;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: Colors.white,
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: tempPickedDateTime,
                mode: CupertinoDatePickerMode.dateAndTime,
                use24hFormat: false,
                minimumDate: now,
                onDateTimeChanged: (newDateTime) {
                  if (_isSameDate(newDateTime, now) && newDateTime.isBefore(now)) {
                    tempPickedDateTime = now;
                  } else {
                    tempPickedDateTime = newDateTime;
                  }
                },
              ),
            ),
            CupertinoButton(
              child: const Text("Done"),
              onPressed: () {
                setState(() {
                  selectedDateTime = tempPickedDateTime;
                });
                widget.onDateTimeSelected(selectedDateTime);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM, yyyy').format(selectedDateTime);
    final formattedTime = DateFormat('hh:mm a').format(selectedDateTime);

    return GestureDetector(
      onTap: () => _showCupertinoDateTimePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.lightBlueBorder, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.bgGrey3, size: 15),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: CommonFonts.bodyText5Black),
                Text(formattedDate, style: CommonFonts.bodyText1Black),
                Text(formattedTime, style: CommonFonts.bodyText1Black),
              ],
            ),
          ],
        ),
      ),
    );
  }
}