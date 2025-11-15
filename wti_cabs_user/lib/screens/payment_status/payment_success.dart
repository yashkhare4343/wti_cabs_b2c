import 'package:firebase_analytics/firebase_analytics.dart';
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
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

import '../../core/controller/analytics_tracking/analytics_tracking.dart';
import '../../core/controller/currency_controller/currency_controller.dart';
import '../booking_details_final/booking_details_final.dart';
import '../bottom_nav/bottom_nav.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/controller/fetch_reservation_booking_data/fetch_reservation_booking_data.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

import '../bottom_nav/bottom_nav.dart';

class PaymentSuccessPage extends StatefulWidget {
  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final FetchReservationBookingData fetchReservationBookingData =
  Get.put(FetchReservationBookingData());

  @override
  void initState() {
    super.initState();
    fetchReservationBookingData.fetchReservationData();
    tz.initializeTimeZones(); // ✅ add this
    WidgetsBinding.instance.addPostFrameCallback((_) async{
      await logPurchase();
    });
  }

  String convertUtcToLocal(String utcTimeString, String? timezoneString) {
    try {
      if (utcTimeString.isEmpty) return '';

      DateTime utcTime = DateTime.parse(utcTimeString);

      // ✅ Default to UTC if timezone is null or invalid
      tz.Location location;
      try {
        if (timezoneString == null || timezoneString.trim().isEmpty) {
          location = tz.getLocation('UTC');
        } else {
          location = tz.getLocation(timezoneString);
        }
      } catch (e) {
        // fallback again in case the timezone string is invalid
        location = tz.getLocation('UTC');
      }

      final localTime = tz.TZDateTime.from(utcTime, location);
      return DateFormat("d MMM yyyy, hh:mm a").format(localTime);
    } catch (e) {
      debugPrint('Error in convertUtcToLocal: $e');
      return utcTimeString; // fallback: show original time
    }
  }

  Future<void> logPurchase() async {
    final selectedTripController = Get.find<SelectedTripController>();
    final currencyController = Get.find<CurrencyController>();
    final convertedPartialAmount = await currencyController.convertPrice(cabBookingController.partFare.toDouble());
    final convertFullAmount = await currencyController.convertPrice(cabBookingController.totalFare.toDouble());
    // 🧩 Add or merge custom keys (including converted amount)
    // 🧾 Get stored values
    final storedItem = selectedTripController.selectedItem.value;
    final storedParams = selectedTripController.parameters;

    if (storedItem == null || storedParams.isEmpty) {
      print('⚠️ No trip data found in controller, skipping log.');
      return;
    }

    // 🧩 You can modify or add new keys if needed
    selectedTripController.addCustomParameters({
      'event': 'purchase',
      'screen_name': 'Payment Success',
      'partial_amount':convertedPartialAmount,
      'payment_option': cabBookingController.selectedOption.value == 1 ? "FULL" : "PART",
      'total_amount' : convertFullAmount,
      'value': convertFullAmount,
      'transaction_id': fetchReservationBookingData.chaufferReservationResponse.value?.result?.first.orderReferenceNumber??''
    });

    // ✅ Prepare final parameters to send
    final updatedParams = Map<String, Object>.from(selectedTripController.parameters);

    // ✅ Log to Firebase Analytics
    await FirebaseAnalytics.instance.logPurchase(
      items: [storedItem],
      parameters: updatedParams,
    );

    print('✅ Logged purchase for ${storedItem.itemName}');
    print('📦 Parameters sent: $updatedParams');
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        GoRouter.of(context).go(AppRoutes.bottomNav);
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
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 50),
                        const SizedBox(height: 12),
                        const Text(
                          'Booking Confirmed',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Thank you for booking with WTI!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 18),

                        // 🚗 Car image
                        if (booking.carImageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              booking.carImageUrl!,
                              height: 100,
                              width: 160,
                              fit: BoxFit.cover,
                            ),
                          ),

                        const SizedBox(height: 16),

                        // 🔹 Booking Details Card (same as failure UI)
                        _buildDetailCard(
                          title: "Booking Details",
                          icon: Icons.assignment,
                          details: [
                           _detailItem("Booking Id", fetchReservationBookingData.reservationId.value),
                            _detailItem("Booking Type",
                                booking.tripTypeDetails?.tripType ?? ''),
                            _detailItem("Cab Category",
                                booking.vehicleDetails?.model ?? ''),
                            _detailItem(
                                "Booking Date",
                                convertUtcToLocal(
                                    booking.startTime ?? '', booking.timezone ?? '')),
                            _detailItem("Pickup", booking.source?.address ?? ''),
                            if (booking.tripTypeDetails?.basicTripType != 'LOCAL') _detailItem("Drop", booking.destination?.address ?? ''),
                            booking.startTime !=null ? _detailItem(
                                "Pickup Date",
                                convertUtcToLocal(
                                    booking.startTime ?? '', booking.timezone ?? '')) : SizedBox(),
                            if (booking.tripTypeDetails?.basicTripType != 'LOCAL')
                              booking.endTime!=null ? _detailItem(
                                  "Drop Date",
                                  convertUtcToLocal(
                                      booking.endTime ?? '', booking.timezone ?? '')) : SizedBox(),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 👉 Two buttons side by side (Home + Bookings)
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
                                    GoRouter.of(context).go(AppRoutes.bottomNav);
                                  },
                                  child: Text(
                                    'Go to Home',
                                    style: TextStyle(
                                      color: AppColors.mainButtonBg,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: MainButton(
                                  text: 'See My Bookings',
                                  onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => BottomNavScreen(initialIndex: 1,)),
                                      );
                                  },

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
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 16),
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
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                style:
                const TextStyle(fontSize: 14, color: Colors.black54)),
          ),
          Expanded(
            flex: 7,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
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
