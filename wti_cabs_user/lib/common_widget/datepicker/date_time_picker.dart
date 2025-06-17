import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    selectedDateTime = widget.initialDateTime;
  }

  void _showDateTimePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          selectedDateTime = newDateTime;
        });
        widget.onDateTimeSelected(newDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localDateTime = selectedDateTime.toLocal();
    final formattedDateTime = DateFormat('dd MMM yyyy hh:mm a').format(localDateTime);

    return GestureDetector(
      onTap: () => _showDateTimePicker(context),
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
                Text(formattedDateTime, style: CommonFonts.bodyText1Black),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
