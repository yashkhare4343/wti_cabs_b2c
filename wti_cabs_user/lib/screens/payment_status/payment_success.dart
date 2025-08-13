import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/controller/fetch_reservation_booking_data/fetch_reservation_booking_data.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';

import '../bottom_nav/bottom_nav.dart';

class PaymentSuccessPage extends StatefulWidget {
  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final FetchReservationBookingData fetchReservationBookingData = Get.put(FetchReservationBookingData());


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchReservationBookingData.fetchReservationData();
  }


  String convertUtcToLocal(String utcTimeString, String timezoneString) {
    // Parse UTC time
    DateTime utcTime = DateTime.parse(utcTimeString);

    // Get the location based on timezone string like "Asia/Kolkata"
    final location = tz.getLocation(timezoneString);

    // Convert UTC to local time in given timezone
    final localTime = tz.TZDateTime.from(utcTime, location);

    // Format the local time as "28 July, 2025"
    final formatted = DateFormat("d MMMM, yyyy, hh:mm a").format(localTime);

    return formatted;
  }
  @override
  Widget build(BuildContext context) {
    fetchReservationBookingData.fetchReservationData();
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Obx(() {
                  final response = fetchReservationBookingData.chaufferReservationResponse.value;

                  if (response == null || response.result == null || response.result!.isEmpty) {
                    return CircularProgressIndicator(); // ⏳ Show loading until data is ready
                  }

                  final booking = response.result!.first;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 60),
                      SizedBox(height: 16),
                      Text('Booking confirmed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Thank you for booking with WTI!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                      SizedBox(height: 24),

                      bookingDetailRow('Booking Id', booking.id ?? ''),
                      bookingDetailRow('Booking Type', booking.tripTypeDetails?.tripType ?? ''),
                      bookingDetailRow('Cab Category', booking.vehicleDetails?.model ?? ''),
                      bookingDetailRow('Booking Date', convertUtcToLocal(fetchReservationBookingData.chaufferReservationResponse.value?.result?.first.startTime??'', fetchReservationBookingData.chaufferReservationResponse.value?.result?.first.timezone??'')),
                      bookingDetailRow('Pickup', booking.source?.address ?? ''),
                      bookingDetailRow('Drop', booking.destination?.address ?? ''),
                      bookingDetailRow('Pickup Date', convertUtcToLocal(fetchReservationBookingData.chaufferReservationResponse.value?.result?.first.startTime??'', fetchReservationBookingData.chaufferReservationResponse.value?.result?.first.timezone??'')),
                    (booking.tripTypeDetails?.basicTripType == 'LOCAL') ? SizedBox() : bookingDetailRow('Drop Date', convertUtcToLocal(fetchReservationBookingData.chaufferReservationResponse.value?.result?.first.endTime??'', fetchReservationBookingData.chaufferReservationResponse.value?.result?.first.timezone??'')),

                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: MainButton(text: 'See My Bookings', onPressed: () {
                          // Navigate or do something
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BottomNavScreen(initialIndex: 2)), // Bookings
                          );
                        }),
                      )
                    ],
                  );
                }),

              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bookingDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(title, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget attendeeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Attendees', style: TextStyle(color: Colors.grey.shade600))),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                CircleAvatar(radius: 12, backgroundImage: AssetImage('assets/avatar1.png')),
                SizedBox(width: 4),
                CircleAvatar(radius: 12, backgroundImage: AssetImage('assets/avatar2.png')),
                SizedBox(width: 4),
                CircleAvatar(radius: 12, backgroundImage: AssetImage('assets/avatar3.png')),
                SizedBox(width: 4),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    '+1',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget calendarButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        calendarIcon('assets/google_calendar.png'),
        SizedBox(width: 12),
        calendarIcon('assets/outlook.png'),
        SizedBox(width: 12),
        calendarIcon('assets/apple_calendar.png'),
      ],
    );
  }

  Widget calendarIcon(String assetPath) {
    return InkWell(
      onTap: () {},
      child: Image.asset(assetPath, width: 36, height: 36),
    );
  }
}

Widget buildShimmer() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 96,
                height: 104,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(height: 12, width: 40, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 40, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 60, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 16, height: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    ),
  );
}
