import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
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
  void didUpdateWidget(covariant DatePickerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _initializeSelectedDate();
    }
  }

  void _initializeSelectedDate() {
    final userDate = placeSearchController.findCntryDateTimeResponse.value
        ?.userDateTimeObject?.userDateTime;

    if (userDate != null) {
      selectedDate = DateTime.parse(userDate).toLocal();
    } else {
      selectedDate = widget.initialDate;
    }
  }

  DateTime _getMinimumSelectableDate() {
    final actualDate = placeSearchController.findCntryDateTimeResponse.value
        ?.actualDateTimeObject?.actualDateTime;

    if (actualDate != null) {
      return DateTime.parse(actualDate).toLocal();
    }
    return DateTime.now();
  }

  void _showCupertinoDatePicker(BuildContext context) {
    final minDate = _getMinimumSelectableDate();

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date, // 🔄 Changed to dateAndTime
                minimumDate: minDate,
                initialDateTime: selectedDate.isBefore(minDate) ? minDate : selectedDate,
                use24hFormat: true,
                minuteInterval: 1,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() => selectedDate = newDateTime);
                  widget.onDateSelected(newDateTime); // 🔄 Correctly update parent
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
    selectedDate = widget.initialDate; // Ensures always synced
    final formattedDate = DateFormat('dd MMM yyyy') // 🔄 Show full date + time
        .format(selectedDate);

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
  }
}
