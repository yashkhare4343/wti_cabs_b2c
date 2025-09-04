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
import 'package:wti_cabs_user/screens/booking_details_final/booking_details_final.dart';

import '../../core/controller/currency_controller/currency_controller.dart';

class PaymentFailurePage extends StatefulWidget {
  final Map<String, dynamic>? provisionalData;

  const PaymentFailurePage({Key? key, this.provisionalData}) : super(key: key);

  @override
  State<PaymentFailurePage> createState() => _PaymentFailurePageState();
}
class _PaymentFailurePageState extends State<PaymentFailurePage> {
  // final FetchReservationBookingData fetchReservationBookingData = Get.put(FetchReservationBookingData());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // fetchReservationBookingData.fetchReservationData();
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
    final reservation = widget.provisionalData?['reservation'] ?? {};
    final order = widget.provisionalData?['order'] ?? {};

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, color: Colors.red, size: 60),
                    SizedBox(height: 16),
                    Text('Booking Failed',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      'Something went wrong, Please try again!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 24),

                    bookingDetailRow('Booking Type',
                        reservation['trip_type_details']?['trip_type'] ?? ''),
                    bookingDetailRow('Cab Category',
                        reservation['vehicle_details']?['model'] ?? ''),
                    bookingDetailRow(
                        'Pickup', reservation['source']?['address'] ?? ''),
                    bookingDetailRow(
                        'Drop', reservation['destination']?['address'] ?? ''),
                    bookingDetailRow('Pickup Date',
                        convertUtcToLocal(reservation['start_time'] ?? '', reservation['timezone'] ?? 'UTC')),
                    bookingDetailRow('Drop Date',
                        convertUtcToLocal(reservation['end_time'] ?? '', reservation['timezone'] ?? 'UTC')),
                    bookingDetailRow('Amount',
                        '${CurrencyController().selectedCurrency.value.symbol} ${order['amount']?.toString()}' ?? '0'),

                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: MainButton(
                        text: 'Retry Payment',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingDetailsFinal(fromPaymentFailure: true,), // replace with your screen
                            ),
                          );                        },
                      ),
                    )
                  ],
                ),
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
              maxLines: 3,
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