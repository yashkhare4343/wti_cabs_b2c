import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class DatePickerTile extends StatefulWidget {
  final String label;
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  /// Accepts either PlaceSearchController or DropPlaceSearchController
  final dynamic controller;

  const DatePickerTile({
    super.key,
    required this.label,
    required this.initialDate,
    required this.onDateSelected,
    required this.controller,
  });

  @override
  State<DatePickerTile> createState() => _DatePickerTileState();
}

class _DatePickerTileState extends State<DatePickerTile> {
  late DateTime selectedDate;
  late dynamic controller;
  final BookingRideController bookingRideController = Get.put(BookingRideController());

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
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
    final userDate = controller.findCntryDateTimeResponse.value
        ?.userDateTimeObject?.userDateTime;

    if (userDate != null) {
      selectedDate = DateTime.parse(userDate).toLocal();
    } else {
      selectedDate = widget.initialDate;
    }
  }

  DateTime _getMinimumSelectableDate() {
    final actualDate = controller.findCntryDateTimeResponse.value
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
                mode: CupertinoDatePickerMode.date,
                minimumDate: minDate,
                maximumYear:( minDate.year + 1),
                initialDateTime: selectedDate.isBefore(minDate) ? minDate : selectedDate,
                use24hFormat: true,
                minuteInterval: 1,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() => selectedDate = newDateTime);
                  widget.onDateSelected(newDateTime);
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
    selectedDate = widget.initialDate;
    final formattedDate = DateFormat('dd MMM yyyy').format(selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bookingRideController.selectedLocalDate.value = formattedDate;
    });

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
            const Icon(Icons.calendar_month_outlined, color: AppColors.bgGrey3, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup Date',
                  style: CommonFonts.bodyText5Black,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // "Fri 08 Aug"

                    Text(
                      formattedDate,
                      style: CommonFonts.bodyText1Black,
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
