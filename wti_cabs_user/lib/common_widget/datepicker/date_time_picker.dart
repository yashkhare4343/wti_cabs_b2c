import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/storage_services.dart';
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

  String formatDateTimeWithOffset(DateTime dt) {
    final offset = dt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

    final formatted =
        '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}'
        '$sign$hours:$minutes';

    return formatted;
  }


  String formatUtcIso(DateTime dt) {
    return dt.toUtc().toIso8601String();
  }

  @override
  void initState() {
    super.initState();
    final min = widget.minimumDate;
    if (min != null && widget.initialDateTime.isBefore(min)) {
      selectedDateTime = min;
    } else {
      selectedDateTime = widget.initialDateTime;
    }

    debugPrint('[initState] Store ISO with offset: ${formatDateTimeWithOffset(selectedDateTime)}');
     StorageServices.instance.save('drop_round_trip_iso', formatDateTimeWithOffset(selectedDateTime));
     StorageServices.instance.save('drop_round_trip_utc', formatUtcIso(selectedDateTime));
    debugPrint('[initState] Store Utc: ${formatUtcIso(selectedDateTime)}');

  }

  @override
  void didUpdateWidget(covariant DateTimePickerTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    final min = widget.minimumDate;
    final newInitial = widget.initialDateTime;

    if (newInitial != selectedDateTime) {
      if (min != null && newInitial.isBefore(min)) {
        selectedDateTime = min;
      } else {
        selectedDateTime = newInitial;
      }

      debugPrint('[initState] Store ISO with offset: ${formatDateTimeWithOffset(selectedDateTime)}');
      StorageServices.instance.save('drop_round_trip_iso', formatDateTimeWithOffset(selectedDateTime));
      StorageServices.instance.save('drop_round_trip_utc', formatUtcIso(selectedDateTime));
      debugPrint('[initState] Store Utc: ${formatUtcIso(selectedDateTime)}');    }
  }

  void _showCupertinoPicker(BuildContext context, CupertinoDatePickerMode mode) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                mode: mode,
                use24hFormat: false,
                minimumDate: widget.minimumDate ?? DateTime.now(),
                initialDateTime: selectedDateTime,
                onDateTimeChanged: (DateTime newDateTime) {
                  // ✅ Clamp minutes to nearest 00 or 30
                  int clampedMinute = newDateTime.minute < 15
                      ? 0
                      : newDateTime.minute < 45
                      ? 30
                      : 0;

                  int clampedHour = newDateTime.minute >= 45
                      ? (newDateTime.hour + 1) % 24
                      : newDateTime.hour;

                  final clampedDateTime = DateTime(
                    newDateTime.year,
                    newDateTime.month,
                    newDateTime.day,
                    clampedHour,
                    clampedMinute,
                  );

                  setState(() => selectedDateTime = clampedDateTime);
                  widget.onDateTimeSelected(clampedDateTime);

                  final isoWithOffset = formatDateTimeWithOffset(clampedDateTime);
                  final utcIso = formatUtcIso(clampedDateTime);

                  debugPrint('[onDateTimeChanged] ISO with offset: $isoWithOffset');
                  debugPrint('[onDateTimeChanged] UTC ISO:          $utcIso');

                  StorageServices.instance.save('drop_round_trip_iso', isoWithOffset);
                  StorageServices.instance.save('drop_round_trip_utc', utcIso);
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

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showCupertinoPicker(context, CupertinoDatePickerMode.date),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.lightBlueBorder, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: AppColors.bgGrey3, size: 20),

                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Drop Date', style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),),
                      Text(formattedDate, style: CommonFonts.bodyText1Black,),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => _showCupertinoPicker(context, CupertinoDatePickerMode.time),
            child: Container(
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
                      Text('Drop Time', style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),),
                      Text(formattedTime, style: CommonFonts.bodyText1Black,),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
