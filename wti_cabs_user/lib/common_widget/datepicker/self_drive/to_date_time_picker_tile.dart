import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';

import '../../../core/controller/self_drive/search_inventory_sd_controller/search_inventory_sd_controller.dart';

class ToDateTimePicker extends StatefulWidget {
  final DateTime fromDate; // Required to set minimum date for ToDateTimePicker

  const ToDateTimePicker({Key? key, required this.fromDate}) : super(key: key);

  @override
  _ToDateTimePickerState createState() => _ToDateTimePickerState();
}

class _ToDateTimePickerState extends State<ToDateTimePicker> {
  final SearchInventorySdController searchInventorySdController = Get.put(SearchInventorySdController());

  // Initialize toDate to next day's midnight from fromDate
  late DateTime toDate;
  late TimeOfDay toTime;
  DateTime? tempDateTime;

  @override
  void initState() {
    super.initState();
    toDate = widget.fromDate.add(Duration(days: 1)).copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    toTime = TimeOfDay(hour: 0, minute: 0);
  }

  // Function to get month abbreviation
  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Function to show Cupertino DateTime picker with submit button
  void _showDateTimePicker(BuildContext context) {
    tempDateTime = toDate; // Initialize with current toDate
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: toDate,
                  minimumDate: widget.fromDate.add(Duration(days: 1)).copyWith(
                    hour: 0,
                    minute: 0,
                    second: 0,
                    millisecond: 0,
                    microsecond: 0,
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDateTime = newDateTime; // Update temp variable
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    if (tempDateTime != null) {
                      setState(() {
                        toDate = tempDateTime!;
                        toTime = TimeOfDay.fromDateTime(tempDateTime!);
                      });

                    }
                    Navigator.pop(context); // Close the picker
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF333333),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showDateTimePicker(context),
          child: Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 7),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 1,
                    offset: Offset(0, 0.1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "To",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "${toDate.day} ${_monthAbbr(toDate.month)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Time",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        "${toTime.format(context)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                      ),
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