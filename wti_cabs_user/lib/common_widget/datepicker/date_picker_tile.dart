import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';
import '../../utility/constants/colors/app_colors.dart';

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

  void _showCupertinoDatePicker(BuildContext context) {
    final DateTime minDate = placeSearchController.currentDateTime.value;
    final DateTime initialDateTime = selectedDate.isBefore(minDate) ? minDate : selectedDate;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: Colors.white,
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: initialDateTime,
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