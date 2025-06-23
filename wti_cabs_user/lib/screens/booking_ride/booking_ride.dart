import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/common_widget/buttons/primary_button.dart';
import 'package:wti_cabs_user/common_widget/datepicker/date_picker_tile.dart';
import 'package:wti_cabs_user/common_widget/datepicker/date_time_picker.dart';
import 'package:wti_cabs_user/common_widget/textformfield/booking_textformfield.dart';
import 'package:wti_cabs_user/common_widget/time_picker/time_picker_tile.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import '../../core/controller/choose_drop/choose_drop_controller.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class BookingRide extends StatefulWidget {
  const BookingRide({super.key});

  @override
  State<BookingRide> createState() => _BookingRideState();
}

class _BookingRideState extends State<BookingRide> {
  @override
  void initState() {
    super.initState();
    // Initialize controllers to avoid LateInitializationError
    Get.put(BookingRideController());
    Get.put(PlaceSearchController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      GoRouter.of(context).pop();
                    },
                    child: const Icon(Icons.arrow_back, color: AppColors.blue4),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Book a Ride",
                    style: CommonFonts.appBarText,
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              height: 8,
            ),
            Flexible(
              child: Container(color: Colors.white, child: const CustomTabBarDemo()),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTabBarDemo extends StatefulWidget {
  const CustomTabBarDemo({Key? key}) : super(key: key);

  @override
  State<CustomTabBarDemo> createState() => _CustomTabBarDemoState();
}

class _CustomTabBarDemoState extends State<CustomTabBarDemo> {
  int selectedIndex = 1;
  final tabs = ["Rides", "Outstation", "Rentals"];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0x40747474),
                offset: const Offset(0, 2),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(tabs.length, (index) {
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2C2C6F)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: const Color(0x1F002CC0),
                            offset: const Offset(8, 4),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ]
                            : [],
                      ),
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.blue4,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        IndexedStack(
          index: selectedIndex,
          children: [
            Center(child: Text("Rides", style: TextStyle(fontSize: 18))),
            OutStation(),
            Center(child: Text("Rentals View", style: TextStyle(fontSize: 18))),
          ],
        ),
      ],
    );
  }
}

class OutStation extends StatefulWidget {
  const OutStation({Key? key}) : super(key: key);

  @override
  State<OutStation> createState() => _OutStationState();
}

class _OutStationState extends State<OutStation> {
  String selectedTrip = 'oneWay';

  final BookingRideController bookingRideController = Get.put(BookingRideController());
  final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController = Get.put(DropPlaceSearchController());
  final RxString selectedField = ''.obs;

  @override
  void initState() {
    super.initState();
  }

  DateTime getDropLocalDateTime() {
    final dropDateTimeStr = dropPlaceSearchController.dropDateTimeResponse.value
        ?.userDateTimeObject?.userDateTime;
    final dropOffset = dropPlaceSearchController.dropDateTimeResponse.value
        ?.userDateTimeObject?.userOffSet;

    if (dropDateTimeStr != null) {
      try {
        final utc = DateTime.parse(dropDateTimeStr).toUtc();
        return utc.add(Duration(minutes: dropOffset ?? 0));
      } catch (_) {}
    }

    return bookingRideController.localStartTime.value.add(const Duration(hours: 4));
  }

  void updateLocalStartTime(DateTime newDateTime) {
    final timezone = placeSearchController.findCntryDateTimeResponse.value?.timeZone ??
        placeSearchController.getCurrentTimeZoneName();
    final offset = placeSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localStartTime.value = newDateTime;
    bookingRideController.utcStartTime.value = newDateTime.subtract(Duration(minutes: offset));
  }

  void updateLocalEndTime(DateTime newDateTime) {
    final timezone = dropPlaceSearchController.dropDateTimeResponse.value?.timeZone ??
        dropPlaceSearchController.getCurrentTimeZoneName();
    final offset = dropPlaceSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localEndTime.value = newDateTime;
    bookingRideController.utcEndTime.value = newDateTime.subtract(Duration(minutes: offset));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTripTypeSelector(context),
        const SizedBox(height: 24),
        if (selectedTrip == 'oneWay') _buildOneWayUI(),
        if (selectedTrip == 'roundTrip') _buildRoundTripUI(),
      ],
    );
  }

  Widget _buildTripTypeSelector(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        decoration: BoxDecoration(
          color: AppColors.lightBlue1,
          border: Border.all(color: AppColors.lightBlue2),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOption('One Way', 'oneWay', selectedTrip == 'oneWay'),
            _verticalDivider(),
            _buildOption('Round Trip', 'roundTrip', selectedTrip == 'roundTrip'),
          ],
        ),
      ),
    );
  }

  Widget _buildOneWayUI() => _buildPickupDropUI(showDropDateTime: false);
  Widget _buildRoundTripUI() => _buildPickupDropUI(showDropDateTime: true);

  Widget _buildPickupDropUI({required bool showDropDateTime}) {
    TextEditingController pickupController =
    TextEditingController(text: bookingRideController.prefilled.value);
    TextEditingController dropController =
    TextEditingController(text: bookingRideController.prefilledDrop.value);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset('assets/images/circle.png', width: 40, height: 120),
                Expanded(
                  child: Column(
                    children: [
                      BookingTextFormField(
                        hintText: 'Enter Pickup Location',
                        controller: pickupController,
                        onTap: () => GoRouter.of(context).push(AppRoutes.choosePickup),
                      ),
                      const SizedBox(height: 12),
                      BookingTextFormField(
                        hintText: 'Enter Drop Location',
                        controller: dropController,
                        onTap: () => GoRouter.of(context).push(AppRoutes.chooseDrop),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.blue5),
                    const SizedBox(height: 10),
                    Transform.translate(
                      offset: const Offset(-40, 0),
                      child: Image.asset('assets/images/interchange.png', width: 30, height: 30),
                    ),
                    const SizedBox(height: 10),
                    Icon(Icons.add_circle_outline, color: AppColors.blue5),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() {
                final localStartTime = bookingRideController.localStartTime.value;
                final dropoffDateTime = getDropLocalDateTime();

                final dynamic activeController = selectedField.value == 'drop'
                    ? dropPlaceSearchController
                    : placeSearchController;

                return Column(
                  children: [
                    DatePickerTile(
                      label: 'Pickup Date',
                      initialDate: localStartTime,
                      onDateSelected: updateLocalStartTime,
                      controller: activeController,
                      controllerDate: bookingRideController.localStartTime,
                    ),
                    const SizedBox(height: 16),
                    TimePickerTile(
                      label: 'Pickup Time',
                      initialTime: localStartTime,
                      onTimeSelected: updateLocalStartTime,
                      controller: activeController,
                      controllerTime: bookingRideController.localStartTime,
                    ),
                    if (showDropDateTime) ...[
                      const SizedBox(height: 16),
                      DateTimePickerTile(
                        label: 'Dropoff Date & Time',
                        initialDateTime: dropoffDateTime,
                        onDateTimeSelected: (pickedDateTime) {
                          if (pickedDateTime.isBefore(localStartTime.add(const Duration(hours: 4)))) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text('Dropoff time must be at least 4 hours after pickup time.'),
                            ));
                            return;
                          }
                          updateLocalEndTime(pickedDateTime);
                        },
                      ),
                    ],
                  ],
                );
              }),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Search Now',
                  onPressed: () {
                    // handle booking action
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String title, String value, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => selectedTrip = value),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Radio<String>(
              value: value,
              groupValue: selectedTrip,
              onChanged: (val) => setState(() => selectedTrip = val!),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.lightGrey1,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
    height: 32,
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: Colors.grey.withOpacity(0.3),
  );
}
