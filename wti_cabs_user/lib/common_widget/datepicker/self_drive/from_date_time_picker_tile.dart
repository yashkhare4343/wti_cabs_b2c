import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/self_drive/search_inventory_sd_controller/search_inventory_sd_controller.dart';

class FromDateTimePicker extends StatefulWidget {
  final Function(DateTime) onDateChanged;

  const FromDateTimePicker({Key? key, required this.onDateChanged})
      : super(key: key);

  @override
  _FromDateTimePickerState createState() => _FromDateTimePickerState();
}

class _FromDateTimePickerState extends State<FromDateTimePicker> {
  final SearchInventorySdController searchInventorySdController =
  Get.find<SearchInventorySdController>();

  DateTime? tempDateTime;

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _showDateTimePicker(BuildContext context) {
    tempDateTime = searchInventorySdController.fromDate.value;
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
                  initialDateTime: searchInventorySdController.fromDate.value,
                  minimumDate: DateTime.now().add(const Duration(days: 1))
                      .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0),
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDateTime = newDateTime;
                  },
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    if (tempDateTime != null) {
                      setState(() {
                        searchInventorySdController.fromDate.value =
                        tempDateTime!;
                        searchInventorySdController.fromTime.value =
                            TimeOfDay.fromDateTime(tempDateTime!);

                        widget.onDateChanged(
                            searchInventorySdController.fromDate.value);
                      });
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize only once if not already set
    if (searchInventorySdController.fromDate.value == DateTime(0)) {
      searchInventorySdController.fromDate.value =
          DateTime.now().add(const Duration(days: 1))
              .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
      searchInventorySdController.fromTime.value =
      const TimeOfDay(hour: 0, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fromDate = searchInventorySdController.fromDate.value;
      final fromTime = searchInventorySdController.fromTime.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showDateTimePicker(context),
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "From",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${fromDate.day} ${_monthAbbr(fromDate.month)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Time",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        fromTime.format(context),
                        style: const TextStyle(
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
        ],
      );
    });
  }
}

class ToDateTimePicker extends StatefulWidget {
  final DateTime fromDate;
  final Function(DateTime) onDateChanged;

  const ToDateTimePicker({Key? key, required this.fromDate, required this.onDateChanged}) : super(key: key);

  @override
  _ToDateTimePickerState createState() => _ToDateTimePickerState();
}

class _ToDateTimePickerState extends State<ToDateTimePicker> {
  final SearchInventorySdController searchInventorySdController = Get.find<SearchInventorySdController>();
  DateTime? tempDateTime;

  @override
  void initState() {
    super.initState();
    _initializeToDate();
  }

  void _initializeToDate() {
    final minimumToDate = widget.fromDate.add(const Duration(days: 1)).copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    if (searchInventorySdController.toDate.value == DateTime(0)) {
      searchInventorySdController.toDate.value = minimumToDate;
      searchInventorySdController.toTime.value = const TimeOfDay(hour: 0, minute: 0);
    }
  }

  @override
  void didUpdateWidget(ToDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final minimumToDate = widget.fromDate.add(const Duration(days: 1)).copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    if (searchInventorySdController.toDate.value.isBefore(minimumToDate)) {
      searchInventorySdController.toDate.value = minimumToDate;
      searchInventorySdController.toTime.value = TimeOfDay.fromDateTime(minimumToDate);
    }
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _showDateTimePicker(BuildContext context) {
    tempDateTime = searchInventorySdController.toDate.value;
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
                  initialDateTime: searchInventorySdController.toDate.value,
                  minimumDate: widget.fromDate.add(const Duration(days: 1)).copyWith(
                    hour: 0,
                    minute: 0,
                    second: 0,
                    millisecond: 0,
                    microsecond: 0,
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDateTime = newDateTime;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    if (tempDateTime != null) {
                      searchInventorySdController.toDate.value = tempDateTime!;
                      searchInventorySdController.toTime.value = TimeOfDay.fromDateTime(tempDateTime!);
                      widget.onDateChanged(searchInventorySdController.toDate.value);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Submit'),
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
    return Obx(() {
      final toDate = searchInventorySdController.toDate.value;
      final toTime = searchInventorySdController.toTime.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showDateTimePicker(context),
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "To",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${toDate.day} ${_monthAbbr(toDate.month)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Time",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        toTime.format(context),
                        style: const TextStyle(
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
        ],
      );
    });
  }
}


class DateTimeRangePicker extends StatefulWidget {
  final bool isMonthlyRental;
  const DateTimeRangePicker({Key? key, required this.isMonthlyRental}) : super(key: key);

  @override
  _DateTimeRangePickerState createState() => _DateTimeRangePickerState();
}

class _DateTimeRangePickerState extends State<DateTimeRangePicker> {
  final SearchInventorySdController searchInventorySdController = Get.find<SearchInventorySdController>();

  @override
  void initState() {
    super.initState();
    // Initialize fromDate if not set
    if (searchInventorySdController.fromDate.value == DateTime(0)) {
      final defaultFromDate = DateTime.now().add(const Duration(days: 1))
          .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
      searchInventorySdController.fromDate.value = defaultFromDate;
      searchInventorySdController.fromTime.value = const TimeOfDay(hour: 0, minute: 0);
    }
  }

  void _updateFromDate(DateTime newFromDate) {
    searchInventorySdController.fromDate.value = newFromDate;
    searchInventorySdController.fromTime.value = TimeOfDay.fromDateTime(newFromDate);

    // Ensure toDate respects minimum of fromDate + 1 day
    if (searchInventorySdController.toDate.value.isBefore(newFromDate.add(const Duration(days: 1)))) {
      searchInventorySdController.toDate.value = newFromDate.add(const Duration(days: 1));
      searchInventorySdController.toTime.value = TimeOfDay(hour: 0, minute: 0);
    }
  }

  void _updateToDate(DateTime newToDate) {
    searchInventorySdController.toDate.value = newToDate;
    searchInventorySdController.toTime.value = TimeOfDay.fromDateTime(newToDate);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: FromDateTimePicker(onDateChanged: _updateFromDate),
        ),
        widget.isMonthlyRental
            ? const MonthSelector()
            : Expanded(
          child: ToDateTimePicker(
            fromDate: searchInventorySdController.fromDate.value,
            onDateChanged: _updateToDate,
          ),
        ),
      ],
    );
  }
}


class MonthSelector extends StatefulWidget {
  const MonthSelector({Key? key}) : super(key: key);

  @override
  State<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  final SearchInventorySdController searchInventorySdController = Get.find<SearchInventorySdController>();

  void _openMonthPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Month",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        int month = index + 1;
                        return Obx(() {
                          return RadioListTile<int>(
                            value: month,
                            groupValue: searchInventorySdController.selectedMonth.value,
                            onChanged: (val) {
                              if (val != null) {
                                searchInventorySdController.selectedMonth.value = val;
                                setSheetState(() {}); // update sheet UI
                                Navigator.pop(context);
                              }
                            },
                            title: Text("$month Month${month > 1 ? 's' : ''}"),
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: _openMonthPicker,
        child: Obx(() {
          final selectedMonth = searchInventorySdController.selectedMonth.value;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "For Month",
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$selectedMonth Month${selectedMonth > 1 ? 's' : ''}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          );
        }),
      ),
    );
  }
}
