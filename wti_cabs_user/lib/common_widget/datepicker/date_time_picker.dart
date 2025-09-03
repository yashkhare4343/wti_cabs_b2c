import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/inventory/search_cab_inventory_controller.dart';
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
  final BookingRideController bookingRideController = Get.put(BookingRideController());
  final SearchCabInventoryController searchCabInventoryController = Get.put(SearchCabInventoryController());
  DateTime? _lastBackendEndUtc; // Store last backend time for comparison

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
    // Get local and backend end times
    DateTime localEndUtc = bookingRideController.localEndTime.value.toUtc();
    DateTime? backendEndUtc = searchCabInventoryController.indiaData.value?.result?.tripType?.endTime;

    debugPrint('[initState] InitialDateTime (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(widget.initialDateTime)}');
    debugPrint('[initState] Local End Time (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(bookingRideController.localEndTime.value)}');
    debugPrint('[initState] Local End UTC: ${formatUtcIso(localEndUtc)}');
    debugPrint('[initState] Backend End UTC: ${backendEndUtc?.toIso8601String() ?? 'null'}');

    // Compare times: use local time if later or equal, otherwise use backend time
    if (backendEndUtc != null && backendEndUtc.isAfter(localEndUtc)) {
      selectedDateTime = backendEndUtc.toLocal(); // Convert backend UTC to local for display
      bookingRideController.localEndTime.value = selectedDateTime; // Sync controller
      debugPrint('[initState] Selected backend time (UTC): ${formatUtcIso(backendEndUtc)}');
      debugPrint('[initState] Selected backend time (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(selectedDateTime)}');
    } else {
      selectedDateTime = bookingRideController.localEndTime.value; // Use local time
      debugPrint('[initState] Selected local time (UTC): ${formatUtcIso(localEndUtc)}');
      debugPrint('[initState] Selected local time (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(selectedDateTime)}');
    }

    // Apply minimum date constraint
    final min = widget.minimumDate;
    if (min != null && selectedDateTime.isBefore(min)) {
      selectedDateTime = min;
      bookingRideController.localEndTime.value = min; // Update GetX variable
      debugPrint('[initState] Adjusted to minimum date (UTC): ${formatUtcIso(min)}');
      debugPrint('[initState] Adjusted to minimum date (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(min)}');
    }

    _lastBackendEndUtc = backendEndUtc; // Store for didUpdateWidget comparison

    debugPrint('[initState] Final selected ISO with offset: ${formatDateTimeWithOffset(selectedDateTime)}');
    debugPrint('[initState] Final selected UTC ISO: ${formatUtcIso(selectedDateTime)}');
    debugPrint('[initState] Final selected Local: ${DateFormat('dd MMM yyyy hh:mm a').format(selectedDateTime)}');
  }

  @override
  void didUpdateWidget(covariant DateTimePickerTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Get current backend time
    DateTime? backendEndUtc = searchCabInventoryController.indiaData.value?.result?.tripType?.endTime;

    // Only update if initialDateTime or backendEndUtc has changed
    if (oldWidget.initialDateTime != widget.initialDateTime || _lastBackendEndUtc != backendEndUtc) {
      debugPrint('[didUpdateWidget] Triggered due to change');
      debugPrint('[didUpdateWidget] Old initialDateTime: ${DateFormat('dd MMM yyyy hh:mm a').format(oldWidget.initialDateTime)}');
      debugPrint('[didUpdateWidget] New initialDateTime: ${DateFormat('dd MMM yyyy hh:mm a').format(widget.initialDateTime)}');
      debugPrint('[didUpdateWidget] Old Backend End UTC: ${_lastBackendEndUtc?.toIso8601String() ?? 'null'}');
      debugPrint('[didUpdateWidget] New Backend End UTC: ${backendEndUtc?.toIso8601String() ?? 'null'}');
      debugPrint('[didUpdateWidget] Local End Time (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(bookingRideController.localEndTime.value)}');
      debugPrint('[didUpdateWidget] Local End UTC: ${formatUtcIso(bookingRideController.localEndTime.value.toUtc())}');

      // Compare times: use local time if later or equal, otherwise use backend time
      DateTime localEndUtc = bookingRideController.localEndTime.value.toUtc();
      if (backendEndUtc != null && backendEndUtc.isAfter(localEndUtc)) {
        selectedDateTime = backendEndUtc.toLocal(); // Convert backend UTC to local for display
        bookingRideController.localEndTime.value = selectedDateTime; // Sync controller
        debugPrint('[didUpdateWidget] Selected backend time (UTC): ${formatUtcIso(backendEndUtc)}');
        debugPrint('[didUpdateWidget] Selected backend time (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(selectedDateTime)}');
      } else {
        selectedDateTime = bookingRideController.localEndTime.value; // Use local time
        debugPrint('[didUpdateWidget] Selected local time (UTC): ${formatUtcIso(localEndUtc)}');
        debugPrint('[didUpdateWidget] Selected local time (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(selectedDateTime)}');
      }

      // Apply minimum date constraint
      final min = widget.minimumDate;
      if (min != null && selectedDateTime.isBefore(min)) {
        selectedDateTime = min;
        bookingRideController.localEndTime.value = min; // Update GetX variable
        debugPrint('[didUpdateWidget] Adjusted to minimum date (UTC): ${formatUtcIso(min)}');
        debugPrint('[didUpdateWidget] Adjusted to minimum date (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(min)}');
      }

      _lastBackendEndUtc = backendEndUtc; // Update last backend time

      debugPrint('[didUpdateWidget] Final selected ISO with offset: ${formatDateTimeWithOffset(selectedDateTime)}');
      debugPrint('[didUpdateWidget] Final selected UTC ISO: ${formatUtcIso(selectedDateTime)}');
      debugPrint('[didUpdateWidget] Final selected Local: ${DateFormat('dd MMM yyyy hh:mm a').format(selectedDateTime)}');
    } else {
      debugPrint('[didUpdateWidget] No significant change (initialDateTime and backendEndUtc unchanged), keeping current selectedDateTime');
      debugPrint('[didUpdateWidget] Current selectedDateTime (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(selectedDateTime)}');
      debugPrint('[didUpdateWidget] Current selectedDateTime (UTC): ${formatUtcIso(selectedDateTime)}');
    }
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
                  // Clamp minutes to nearest 00 or 30
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

                  debugPrint('[onDateTimeChanged] User selected time (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(clampedDateTime)}');
                  debugPrint('[onDateTimeChanged] User selected time (UTC): ${formatUtcIso(clampedDateTime)}');

                  setState(() => selectedDateTime = clampedDateTime);
                  widget.onDateTimeSelected(clampedDateTime);
                  bookingRideController.localEndTime.value = clampedDateTime; // Update GetX variable

                  debugPrint('[onDateTimeChanged] Updated localEndTime (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(bookingRideController.localEndTime.value)}');
                  debugPrint('[onDateTimeChanged] Updated localEndTime (UTC): ${formatUtcIso(bookingRideController.localEndTime.value)}');
                  debugPrint('[onDateTimeChanged] ISO with offset: ${formatDateTimeWithOffset(clampedDateTime)}');
                  debugPrint('[onDateTimeChanged] UTC ISO: ${formatUtcIso(clampedDateTime)}');
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
    final formattedDate = DateFormat('dd MMM yyyy').format(selectedDateTime);
    final formattedTime = DateFormat('hh:mm a').format(selectedDateTime);

    debugPrint('[build] Rendering with selectedDateTime (Local): ${DateFormat('dd MMM yyyy hh:mm a').format(selectedDateTime)}');
    debugPrint('[build] Rendering with selectedDateTime (UTC): ${formatUtcIso(selectedDateTime)}');

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
                      Text(
                        'Drop Date',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(formattedDate, style: CommonFonts.bodyText1Black),
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
                  const Icon(Icons.watch_later_outlined, color: AppColors.bgGrey3, size: 15),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Drop Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(formattedTime, style: CommonFonts.bodyText1Black),
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