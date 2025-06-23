import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class DatePickerTile extends StatefulWidget {
  final String label;
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;
  final dynamic controller;

  /// Accepts a shared Rx<DateTime> so both date and time are synced
  final Rx<DateTime>? controllerDate;

  const DatePickerTile({
    super.key,
    required this.label,
    required this.initialDate,
    required this.onDateSelected,
    required this.controller,
    this.controllerDate,
  });

  @override
  State<DatePickerTile> createState() => _DatePickerTileState();
}

class _DatePickerTileState extends State<DatePickerTile> {
  late dynamic timeZoneController;
  late Rx<DateTime> dateObservable;

  @override
  void initState() {
    super.initState();
    timeZoneController = widget.controller;
    dateObservable = widget.controllerDate ?? Rx<DateTime>(widget.initialDate);
  }

  DateTime _getMinimumSelectableDate() {
    final actualDate = timeZoneController.findCntryDateTimeResponse.value
        ?.actualDateTimeObject?.actualDateTime;

    if (actualDate != null) {
      return DateTime.parse(actualDate).toLocal();
    }
    return DateTime.now();
  }

  void _showCupertinoDatePicker(BuildContext context) {
    final minDate = _getMinimumSelectableDate();
    final currentDate = dateObservable.value;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                minimumDate: minDate,
                initialDateTime: currentDate.isBefore(minDate) ? minDate : currentDate,
                use24hFormat: true,
                minuteInterval: 1,
                onDateTimeChanged: (DateTime newDate) {
                  final updatedDateTime = DateTime(
                    newDate.year,
                    newDate.month,
                    newDate.day,
                    currentDate.hour,
                    currentDate.minute,
                  );
                  dateObservable.value = updatedDateTime;
                  widget.onDateSelected(updatedDateTime);
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
      final formattedDate = DateFormat('dd MMM yyyy').format(dateObservable.value);

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
              const Icon(Icons.calendar_today, color: AppColors.bgGrey3, size: 15),
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
    });
  }
}
