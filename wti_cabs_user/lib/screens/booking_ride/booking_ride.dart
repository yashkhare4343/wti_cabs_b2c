import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

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

  // Helper to get DateTime from localStartTime or response
  DateTime getLocalDateTime() {
    final userDateTimeStr = placeSearchController.findCntryDateTimeResponse.value
        ?.userDateTimeObject
        ?.userDateTime;

    final offset = placeSearchController.findCntryDateTimeResponse.value
        ?.userDateTimeObject
        ?.userOffSet;

    if (userDateTimeStr != null) {
      try {
        final utc = DateTime.parse(userDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0)); // Convert to local
      } catch (e) {
        print("Error parsing userDateTime: $e");
      }
    }

    // fallback to localStartTime
    return bookingRideController.localStartTime.value;
  }

  // Helper to get initial DateTime from response's actualDateTime
  DateTime getInitialDateTime() {
    final actualDateTimeStr = placeSearchController.findCntryDateTimeResponse.value
        ?.actualDateTimeObject
        ?.actualDateTime;

    final offset = placeSearchController.findCntryDateTimeResponse.value
        ?.actualDateTimeObject
        ?.actualOffSet;

    if (actualDateTimeStr != null) {
      try {
        final utc = DateTime.parse(actualDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0)); // Convert to local
      } catch (e) {
        print("Error parsing actualDateTime: $e");
      }
    }

    return getLocalDateTime(); // fallback
  }

  // // Helper to update localStartTime with timezone consideration
  // void updateLocalStartTime(DateTime newDateTime) {
  //   final placeSearchController = Get.find<PlaceSearchController>();
  //   bookingRideController.localStartTime.value = newDateTime; // Store as local time
  //   print('Updated localStartTime: $newDateTime');
  //
  //   // Update UTC in controller for API usage
  //   final timezone = placeSearchController.findCntryDateTimeResponse.value?.timeZone ??
  //       placeSearchController.getCurrentTimeZoneName();
  //   final offset = placeSearchController.getOffsetFromTimeZone(timezone);
  //   final utcDateTime = newDateTime.subtract(Duration(minutes: offset));
  //   bookingRideController.localStartTime.value = utcDateTime;
  //   print('Updated utcStartTime: $utcDateTime');
  // }

  void updateLocalStartTime(DateTime newDateTime) {
    final placeSearchController = Get.find<PlaceSearchController>();
    bookingRideController.localStartTime.value = newDateTime; // Store as local time
    print('Updated localStartTime: $newDateTime');

    // Update UTC in controller for API usage
    final timezone = placeSearchController.findCntryDateTimeResponse.value?.timeZone ??
        placeSearchController.getCurrentTimeZoneName();
    final offset = placeSearchController.getOffsetFromTimeZone(timezone);
    final utcDateTime = newDateTime.subtract(Duration(minutes: offset));
    bookingRideController.utcStartTime.value = utcDateTime; // Use utcStartTime instead
    print('Updated utcStartTime: $utcDateTime');
  }

  DateTime convertUtcToLocal(String utcIsoString, int offsetMinutes) {
    // Parse the ISO 8601 UTC string
    DateTime utcTime = DateTime.parse(utcIsoString).toUtc();

    // Create Duration based on offsetMinutes
    Duration offset = Duration(minutes: offsetMinutes);

    // Add the offset to UTC time
    DateTime localTime = utcTime.add(offset);

    return localTime;
  }

  DateTime getLocalTimeFromUtc() {
    final utcIsoString = placeSearchController.findCntryDateTimeResponse.value
        ?.actualDateTimeObject
        ?.actualDateTime;

    final offsetMinutes = placeSearchController.findCntryDateTimeResponse.value
        ?.userDateTimeObject
        ?.userOffSet;

    if (utcIsoString == null || utcIsoString.isEmpty) return DateTime.now();

    try {
      final utcTime = DateTime.parse(utcIsoString).toUtc();
      return utcTime.add(Duration(minutes: offsetMinutes ?? 0));
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    getLocalTimeFromUtc();
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
    final placeSearchController = Get.find<PlaceSearchController>();
    
    // redirect to rohit screen 
    Future<void> launchCallbackUrl(String jwtToken) async {
      final url = Uri.parse(
        'https://aceuat.acumengroup.in/callback?id=A1RM001&token=$jwtToken&sso=true',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Or LaunchMode.inAppWebView
        );
      } else {
        throw 'Could not launch $url';
      }
    }

    Future<void> rohitPostData() async {
      final url = Uri.parse('https://aceuat.acumengroup.in:3002/backend/generate-token-via-app');

      // Headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization':
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJnZW5lcmljSWQiOiJob3h4IiwidXNlclR5cGUiOiJhZG1pbiIsImZvclJvdXRlcyI6ImFsbCIsImlhdCI6MTc1MDIzNzk3MCwiZXhwIjo0OTAzODM3OTcwfQ.fWCjl54ULGPs159pZKRGms_5g_5FglsvS4U-FPb_mtM'
      };

      // Body
      final body = jsonEncode({
        "genericId": "A1RM001",
        "userType": "client"
      });

      // Custom HttpClient that ignores SSL errors (ONLY FOR DEV)
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final ioClient = IOClient(httpClient);

      try {
        final response = await ioClient.post(url, headers: headers, body: body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);

          final accessToken = data['token'];
          print('Rohit API Success: ${response.body}');

          launchCallbackUrl(accessToken);
        } else {
          print('Failed: ${response.statusCode}');
          print('Body: ${response.body}');
        }
      } catch (e) {
        print('Error: $e');
      } finally {
        ioClient.close();
      }
    }

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
                  child: Obx((){
                    return  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookingTextFormField(
                          hintText: 'Enter Pickup Location',
                          controller: pickupController,
                          onTap: () {
                            GoRouter.of(context).push(AppRoutes.choosePickup);
                          },
                          isError: placeSearchController.findCntryDateTimeResponse.value?.sourceInput??false,
                          errorText: 'We do not offer service in this region',
                        ),
                        const SizedBox(height: 12),
                        BookingTextFormField(
                          hintText: 'Enter Drop Location',
                          controller: dropController,
                          onTap: () {
                            GoRouter.of(context).push(AppRoutes.chooseDrop);
                          },
                        isError: placeSearchController.findCntryDateTimeResponse.value?.destinationInputFalse??false,
                          errorText: 'We do not offer service in this region',
                        ),
                      ],
                    );
                  })
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
                final placeSearchController = Get.find<PlaceSearchController>();
                final bookingRideController = Get.find<BookingRideController>();

                // Always use current value from controller
                final localStartTime = bookingRideController.localStartTime.value;

                // Used for limiting min selectable date/time (e.g., for Cupertino pickers)
                DateTime getActualLocalDateTime() {
                  final actualTimeStr = placeSearchController.findCntryDateTimeResponse.value
                      ?.actualDateTimeObject
                      ?.actualDateTime;
                  final actualOffset = placeSearchController.findCntryDateTimeResponse.value
                      ?.actualDateTimeObject
                      ?.actualOffSet;

                  if (actualTimeStr != null && actualOffset != null) {
                    try {
                      final utcTime = DateTime.parse(actualTimeStr).toUtc();
                      return utcTime.add(Duration(minutes: actualOffset));
                    } catch (_) {}
                  }

                  return DateTime.now(); // fallback
                }

                final actualDateTime = getActualLocalDateTime();

                return Column(
                  children: [
                    DatePickerTile(
                      label: 'Pickup Date',
                      initialDate: localStartTime,
                      onDateSelected: (newDate) {
                        final updatedDateTime = DateTime(
                          newDate.year,
                          newDate.month,
                          newDate.day,
                          localStartTime.hour,
                          localStartTime.minute,
                        );
                        updateLocalStartTime(updatedDateTime);
                      },
                    ),
                    const SizedBox(height: 16),
                    TimePickerTile(
                      label: 'Pickup Time',
                      initialTime: localStartTime,
                      onTimeSelected: (newTime) {
                        final updatedDateTime = DateTime(
                          localStartTime.year,
                          localStartTime.month,
                          localStartTime.day,
                          newTime.hour,
                          newTime.minute,
                        );
                        updateLocalStartTime(updatedDateTime);
                      },
                    ),
                    const SizedBox(height: 16),
                    DateTimePickerTile(
                      label: 'Pickup Date & Time',
                      initialDateTime: localStartTime,
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
                  onPressed: () {
                    rohitPostData();
                  },
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
                final initialDateTime = getInitialDateTime();
                final pickupDateTime = getLocalDateTime();
                final dropoffDateTime = pickupDateTime.add(const Duration(hours: 4));
                return Column(
                  children: [
                    DatePickerTile(
                      label: 'Pickup Date',
                      initialDate: initialDateTime,
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
                      initialTime: initialDateTime,
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
                      initialDateTime: initialDateTime,
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