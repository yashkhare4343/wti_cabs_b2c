import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class DateTimePickerTile extends StatefulWidget {
  final String label;
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onDateTimeSelected;
  final DateTime? minimumDate;

  const DateTimePickerTile({
    super.key,
    required this.label,
    required this.initialDateTime,
    required this.onDateTimeSelected,
    this.minimumDate,
  });

  @override
  State<DateTimePickerTile> createState() => _DateTimePickerTileState();
}

class _DateTimePickerTileState extends State<DateTimePickerTile> {
  late DateTime selectedDateTime;

  @override
  void initState() {
    super.initState();
    final min = widget.minimumDate;
    if (min != null && widget.initialDateTime.isBefore(min)) {
      selectedDateTime = min;
    } else {
      selectedDateTime = widget.initialDateTime;
    }
  }

  @override
  void didUpdateWidget(covariant DateTimePickerTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    final min = widget.minimumDate;
    final newInitial = widget.initialDateTime;

    // ✅ Update only if changed from outside
    if (newInitial != selectedDateTime) {
      if (min != null && newInitial.isBefore(min)) {
        selectedDateTime = min;
      } else {
        selectedDateTime = newInitial;
      }
    }
  }

  void _showCupertinoDateTimePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                use24hFormat: false,
                minimumDate: widget.minimumDate ?? DateTime.now(),
                initialDateTime: selectedDateTime,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() => selectedDateTime = newDateTime);
                  widget.onDateTimeSelected(newDateTime);
                },
              ),
            ),
            CupertinoButton(
              child: const Text("Done"),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
    DateFormat('dd MMM yyyy').format(selectedDateTime);
    final formattedTime =
    DateFormat('hh:mm a').format(selectedDateTime);

    return GestureDetector(
      onTap: () => _showCupertinoDateTimePicker(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.lightBlueBorder, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.bgGrey3, size: 15),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Drop Date', style: CommonFonts.bodyText5Black),
                    Text('$formattedDate',
                        style: CommonFonts.bodyText1Black),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 16,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.lightBlueBorder, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.watch_later_outlined,
                    color: AppColors.bgGrey3, size: 15),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Drop Time', style: CommonFonts.bodyText5Black),
                    Text('$formattedTime',
                        style: CommonFonts.bodyText1Black),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
