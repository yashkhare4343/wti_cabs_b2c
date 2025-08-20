import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/controller/fetch_reservation_booking_data/fetch_reservation_booking_data.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

class PaymentFailurePage extends StatefulWidget {
  @override
  State<PaymentFailurePage> createState() => _PaymentFailurePageState();
}

class _PaymentFailurePageState extends State<PaymentFailurePage> {
  final FetchReservationBookingData fetchReservationBookingData =
  Get.put(FetchReservationBookingData());

  @override
  void initState() {
    super.initState();
    fetchReservationBookingData.fetchReservationData();
  }

  String convertUtcToLocal(String utcTimeString, String timezoneString) {
    DateTime utcTime = DateTime.parse(utcTimeString);
    final location = tz.getLocation(timezoneString);
    final localTime = tz.TZDateTime.from(utcTime, location);
    return DateFormat("d MMM yyyy, hh:mm a").format(localTime);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 🚀 Stops the default "pop and close app"
      onPopInvoked: (didPop) {
        // This will be called for hardware back and gesture
        GoRouter.of(context).go(AppRoutes.bookingDetailsFinal);
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Obx(() {
                    final response =
                        fetchReservationBookingData.chaufferReservationResponse.value;

                    if (response == null ||
                        response.result == null ||
                        response.result!.isEmpty) {
                      return const CircularProgressIndicator();
                    }

                    final booking = response.result!.first;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 50),
                        const SizedBox(height: 12),
                        const Text(
                          'Booking Failed',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Something went wrong, please try again!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 18),

                        // 🚗 Show car network image
                        if (booking.carImageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              booking.carImageUrl!,
                              height: 120,
                              width: 180,
                              fit: BoxFit.cover,
                            ),
                          ),

                        const SizedBox(height: 16),

                        // 🔹 Booking Details Card
                        _buildDetailCard(
                          title: "Booking Details",
                          icon: Icons.assignment,
                          details: [
                            _detailItem("Booking Id", booking.id ?? ''),
                            _detailItem("Booking Type",
                                booking.tripTypeDetails?.tripType ?? ''),
                            _detailItem("Cab Category",
                                booking.vehicleDetails?.model ?? ''),
                            _detailItem(
                                "Booking Date",
                                convertUtcToLocal(
                                    booking.startTime ?? '', booking.timezone ?? '')),
                            _detailItem("Pickup", booking.source?.address ?? ''),
                            _detailItem("Drop", booking.destination?.address ?? ''),
                            _detailItem(
                                "Pickup Date",
                                convertUtcToLocal(
                                    booking.startTime ?? '', booking.timezone ?? '')),
                            if (booking.tripTypeDetails?.basicTripType != 'LOCAL')
                              _detailItem(
                                  "Drop Date",
                                  convertUtcToLocal(
                                      booking.endTime ?? '', booking.timezone ?? '')),
                          ],
                        ),



                        const SizedBox(height: 20),

                        // 👉 Two buttons side by side (Retry + See Bookings)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: AppColors.mainButtonBg, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () {
                                    GoRouter.of(context).go(AppRoutes.bookingDetailsFinal);
                                  },
                                  child: Text(
                                    'Retry Payment',
                                    style: TextStyle(
                                      color: AppColors.mainButtonBg,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Detail Card Widget
  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> details,
  }) {
    return Card(
      elevation: 0.2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...details,
          ],
        ),
      ),
    );
  }

  /// ✅ Single Detail Item
  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ),
          Expanded(
            flex: 7,
            child: Text(
              value,
              textAlign: TextAlign.start,
              maxLines: 2,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
