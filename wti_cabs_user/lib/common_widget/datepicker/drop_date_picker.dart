import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utility/constants/colors/app_colors.dart';
import '../../../utility/constants/fonts/common_fonts.dart';

class DropDatePickerTile extends StatefulWidget {
  final String label;
  final DateTime initialDate;
  final DateTime? minimumDate;
  final ValueChanged<DateTime> onDateSelected;

  const DropDatePickerTile({
    super.key,
    required this.label,
    required this.initialDate,
    required this.onDateSelected,
    this.minimumDate,
  });

  @override
  State<DropDatePickerTile> createState() => _DropDatePickerTileState();
}

class _DropDatePickerTileState extends State<DropDatePickerTile> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    final min = widget.minimumDate;
    if (min != null && widget.initialDate.isBefore(min)) {
      selectedDate = min;
    } else {
      selectedDate = widget.initialDate;
    }
  }

  void _showCupertinoDatePicker(BuildContext context) {
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
                minimumDate: widget.minimumDate ?? DateTime.now(),
                initialDateTime: selectedDate,
                onDateTimeChanged: (DateTime newDate) {
                  final updatedDate = DateTime(
                    newDate.year,
                    newDate.month,
                    newDate.day,
                    selectedDate.hour,
                    selectedDate.minute,
                  );
                  setState(() => selectedDate = updatedDate);
                  widget.onDateSelected(updatedDate);
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
    final formattedDate = DateFormat('dd MMM yyyy').format(selectedDate);

    return GestureDetector(
      onTap: () => _showCupertinoDatePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.lightBlueBorder),
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
