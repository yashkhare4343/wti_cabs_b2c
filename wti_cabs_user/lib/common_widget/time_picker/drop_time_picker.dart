import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utility/constants/colors/app_colors.dart';
import '../../../utility/constants/fonts/common_fonts.dart';

class DropTimePickerTile extends StatefulWidget {
  final String label;
  final DateTime initialTime;
  final DateTime? minimumTime;
  final ValueChanged<DateTime> onTimeSelected;

  const DropTimePickerTile({
    super.key,
    required this.label,
    required this.initialTime,
    required this.onTimeSelected,
    this.minimumTime,
  });

  @override
  State<DropTimePickerTile> createState() => _DropTimePickerTileState();
}

class _DropTimePickerTileState extends State<DropTimePickerTile> {
  late DateTime selectedTime;

  @override
  void initState() {
    super.initState();
    final min = widget.minimumTime;
    if (min != null && widget.initialTime.isBefore(min)) {
      selectedTime = min;
    } else {
      selectedTime = widget.initialTime;
    }
  }

  void _showCupertinoTimePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                minimumDate: widget.minimumTime,
                initialDateTime: selectedTime,
                onDateTimeChanged: (DateTime newTime) {
                  final updatedTime = DateTime(
                    selectedTime.year,
                    selectedTime.month,
                    selectedTime.day,
                    newTime.hour,
                    newTime.minute,
                  );
                  setState(() => selectedTime = updatedTime);
                  widget.onTimeSelected(updatedTime);
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
    final formattedTime = DateFormat('hh:mm a').format(selectedTime);

    return GestureDetector(
      onTap: () => _showCupertinoTimePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.lightBlueBorder),
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
  }
}
