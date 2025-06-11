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
  const OutStation({super.key});

  @override
  State<OutStation> createState() => _OutStationState();
}

class _OutStationState extends State<OutStation> {
  String selectedTrip = 'oneWay';
  final BookingRideController bookingRideController = Get.find<BookingRideController>();
  final PlaceSearchController placeSearchController = Get.find<PlaceSearchController>();


  @override
  void initState() {
    super.initState();
  }

  // Helper to get DateTime from localStartTime
  DateTime getLocalDateTime() {
    final localTime = bookingRideController.localStartTime.value;
    print('getLocalDateTime: localTime = $localTime'); // Debug
    try {
      if (localTime != 'Loading...' && localTime.isNotEmpty) {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parse(localTime);
      }
    } catch (e) {
      print('Error parsing localStartTime: $e');
    }
    // Fallback to PlaceSearchController's currentDateTime or system time
    final fallbackTime = placeSearchController.currentDateTime.value.isAfter(DateTime.now())
        ? placeSearchController.currentDateTime.value
        : DateTime.now();
    print('getLocalDateTime: Using fallback time = $fallbackTime');
    return fallbackTime;
  }

  // Helper to update localStartTime
  void updateLocalStartTime(DateTime newDateTime) {
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(newDateTime);
    bookingRideController.localStartTime.value = formattedTime;
    print('Updated localStartTime: $formattedTime');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: AppColors.lightBlue1,
              border: Border.all(
                color: AppColors.lightBlue2,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildOption(
                      'One Way', 'oneWay', selectedTrip == 'oneWay'),
                ),
                _verticalDivider(),
                _buildOption(
                    'Round Trip', 'roundTrip', selectedTrip == 'roundTrip'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (selectedTrip == 'oneWay') _buildOneWayUI(),
        if (selectedTrip == 'roundTrip') _buildRoundTripUI(),
      ],
    );
  }

  Widget _buildOneWayUI() {
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
                Image.asset(
                  'assets/images/circle.png',
                  fit: BoxFit.contain,
                  width: 40,
                  height: 120,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookingTextFormField(
                        hintText: 'Enter Pickup Location',
                        controller: pickupController,
                        onTap: () {
                          GoRouter.of(context).push(AppRoutes.choosePickup);
                        },
                      ),
                      const SizedBox(height: 12),
                      BookingTextFormField(
                        hintText: 'Enter Drop Location',
                        controller: dropController,
                        onTap: () {
                          GoRouter.of(context).push(AppRoutes.chooseDrop);
                        },
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.blue5, size: 20),
                    SizedBox(height: 10),
                    Transform.translate(
                      offset: Offset(-40, 0),
                      child: Image.asset(
                        'assets/images/interchange.png',
                        fit: BoxFit.contain,
                        width: 30,
                        height: 30,
                      ),
                    ),
                    SizedBox(height: 10),
                    Icon(Icons.add_circle_outline,
                        color: AppColors.blue5, size: 20),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() {
                print('Obx: localStartTime = ${bookingRideController.localStartTime.value}'); // Debug
                final currentDateTime = getLocalDateTime();
                return Column(
                  children: [
                    DatePickerTile(
                      label: 'Pickup Date',
                      initialDate: currentDateTime,
                      onDateSelected: (newDate) {
                        final updatedDateTime = DateTime(
                          newDate.year,
                          newDate.month,
                          newDate.day,
                          currentDateTime.hour,
                          currentDateTime.minute,
                        );
                        updateLocalStartTime(updatedDateTime);
                      },
                    ),
                    const SizedBox(height: 16),
                    TimePickerTile(
                      label: 'Pickup Time',
                      initialTime: currentDateTime,
                      onTimeSelected: (newTime) {
                        final updatedDateTime = DateTime(
                          currentDateTime.year,
                          currentDateTime.month,
                          currentDateTime.day,
                          newTime.hour,
                          newTime.minute,
                        );
                        updateLocalStartTime(updatedDateTime);
                      },
                    ),
                    const SizedBox(height: 16),
                    DateTimePickerTile(
                      label: 'Pickup Date & Time',
                      initialDateTime: currentDateTime,
                      onDateTimeSelected: (newDateTime) {
                        updateLocalStartTime(newDateTime);
                      },
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Search Now',
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundTripUI() {
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
                Image.asset(
                  'assets/images/circle.png',
                  fit: BoxFit.contain,
                  width: 40,
                  height: 120,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookingTextFormField(
                        hintText: 'Enter Pickup Location',
                        controller: pickupController,
                        onTap: () {
                          GoRouter.of(context).push(AppRoutes.choosePickup);
                        },
                      ),
                      const SizedBox(height: 12),
                      BookingTextFormField(
                        hintText: 'Enter Drop Location',
                        controller: dropController,
                        onTap: () {
                          GoRouter.of(context).push(AppRoutes.chooseDrop);
                        },
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.blue5, size: 20),
                    SizedBox(height: 10),
                    Transform.translate(
                      offset: Offset(-40, 0),
                      child: Image.asset(
                        'assets/images/interchange.png',
                        fit: BoxFit.contain,
                        width: 30,
                        height: 30,
                      ),
                    ),
                    SizedBox(height: 10),
                    Icon(Icons.add_circle_outline,
                        color: AppColors.blue5, size: 20),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() {
                print('Obx: localStartTime = ${bookingRideController.localStartTime.value}'); // Debug
                final pickupDateTime = getLocalDateTime();
                final dropoffDateTime = pickupDateTime.add(const Duration(hours: 4));
                return Column(
                  children: [
                    DatePickerTile(
                      label: 'Pickup Date',
                      initialDate: pickupDateTime,
                      onDateSelected: (newDate) {
                        final updatedDateTime = DateTime(
                          newDate.year,
                          newDate.month,
                          newDate.day,
                          pickupDateTime.hour,
                          pickupDateTime.minute,
                        );
                        updateLocalStartTime(updatedDateTime);
                      },
                    ),
                    const SizedBox(height: 16),
                    TimePickerTile(
                      label: 'Pickup Time',
                      initialTime: pickupDateTime,
                      onTimeSelected: (newTime) {
                        final updatedDateTime = DateTime(
                          pickupDateTime.year,
                          pickupDateTime.month,
                          pickupDateTime.day,
                          newTime.hour,
                          newTime.minute,
                        );
                        updateLocalStartTime(updatedDateTime);
                      },
                    ),
                    const SizedBox(height: 16),
                    DateTimePickerTile(
                      label: 'Pickup Date & Time',
                      initialDateTime: pickupDateTime,
                      onDateTimeSelected: (newDateTime) {
                        updateLocalStartTime(newDateTime);
                      },
                    ),
                    const SizedBox(height: 16),
                    DateTimePickerTile(
                      label: 'Dropoff Date & Time',
                      initialDateTime: dropoffDateTime,
                      onDateTimeSelected: (pickedDateTime) {
                        if (pickedDateTime.isBefore(pickupDateTime.add(const Duration(hours: 4)))) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text(
                                  'Dropoff time must be at least 4 hours after pickup time.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        print('Dropoff DateTime: $pickedDateTime');
                      },
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Search Now',
                  onPressed: () {},
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
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          selectedTrip = value;
        });
      },
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: RadioTheme(
              data: RadioThemeData(
                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xFF1A1A64);
                  }
                  return const Color(0xFFBDBDBD);
                }),
              ),
              child: Radio<String>(
                value: value,
                groupValue: selectedTrip,
                onChanged: (val) {
                  setState(() {
                    selectedTrip = val!;
                  });
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color:
              isSelected ? const Color(0xFF1A1A64) : AppColors.lightGrey1,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey.withOpacity(0.3),
    );
  }
}