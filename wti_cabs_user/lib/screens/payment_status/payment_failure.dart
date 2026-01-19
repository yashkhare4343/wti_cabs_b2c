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

  bool _isTripCodeRental(dynamic tripCode) {
    if (tripCode == null) return false;
    if (tripCode is num) return tripCode.toInt() == 3;
    final s = tripCode.toString().trim();
    return s == '3';
  }

  Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  String _stringOrDash(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? '-' : s;
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  String _formatAmount(dynamic amount) {
    final a = _asDouble(amount);
    if (a == null) return '-';
    return a.toStringAsFixed(2);
  }

  /// Backward compatible getter for both old and new provisional payload shapes.
  dynamic _getNested(Map<String, dynamic>? map, List<String> path) {
    dynamic cur = map;
    for (final key in path) {
      final m = _asMap(cur);
      if (m == null) return null;
      cur = m[key];
    }
    return cur;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Ensure timezone database is initialized before calling tz.getLocation(...)
    try {
      tz.initializeTimeZones();
    } catch (_) {
      // If already initialized or fails for some reason, we fall back safely in convertUtcToLocal().
    }
    // fetchReservationBookingData.fetchReservationData();
  }


  String convertUtcToLocal(String utcTimeString, String timezoneString) {
    // Guard against empty/invalid timestamps coming from provisionalData.
    final raw = utcTimeString.trim();
    if (raw.isEmpty) return '-';

    DateTime? utcTime = DateTime.tryParse(raw);

    // Also support epoch timestamps (seconds or milliseconds) if API sends numeric strings.
    if (utcTime == null) {
      final epoch = int.tryParse(raw);
      if (epoch != null) {
        // Heuristic: 13 digits => milliseconds; otherwise seconds.
        final millis = raw.length >= 13 ? epoch : epoch * 1000;
        utcTime = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
      }
    }

    if (utcTime == null) return '-';
    final utc = utcTime.isUtc ? utcTime : utcTime.toUtc();

    // Convert UTC to local time in given timezone, but fall back to UTC on any issues.
    try {
      final tzName = timezoneString.trim().isEmpty ? 'UTC' : timezoneString.trim();
      final location = tz.getLocation(tzName);
      final localTime = tz.TZDateTime.from(utc, location);
      return DateFormat("d MMMM, yyyy, hh:mm a").format(localTime);
    } catch (_) {
      return DateFormat("d MMMM, yyyy, hh:mm a").format(utc);
    }
  }
  @override
  Widget build(BuildContext context) {
    final provisional = widget.provisionalData ?? const <String, dynamic>{};
    final reservation = _asMap(provisional['reservation']) ?? const <String, dynamic>{};
    final order = _asMap(provisional['order']) ?? const <String, dynamic>{};
    final receipt = _asMap(provisional['receiptData']) ?? const <String, dynamic>{};
    final ui = _asMap(provisional['ui']) ?? const <String, dynamic>{};

    final currencyCode = _stringOrDash(order['currency']);
    final amountStr = _formatAmount(order['amount']);
    final paymentType = _stringOrDash(receipt['paymentType']);

    // Old payload fallbacks (if present)
    final oldPickup = _stringOrDash(_getNested(provisional, ['reservation', 'source', 'address']));
    final oldDrop = _stringOrDash(_getNested(provisional, ['reservation', 'destination', 'address']));
    final oldStartTime = _stringOrDash(_getNested(provisional, ['reservation', 'start_time']));
    final oldEndTime = _stringOrDash(_getNested(provisional, ['reservation', 'end_time']));
    final oldTimezone = _stringOrDash(_getNested(provisional, ['reservation', 'timezone']));

    final tripCode = ui['tripCode'];
    final isRentalTrip = _isTripCodeRental(tripCode);

    final pickupAddress = _stringOrDash(ui['pickup'] ?? oldPickup);
    // For rental trips, never show drop/drop time (even if old fallback contains values).
    final dropAddress =
        isRentalTrip ? '-' : _stringOrDash(ui['drop'] ?? oldDrop);

    final pickupTimeRaw = _stringOrDash(ui['pickup_time'] ?? oldStartTime);
    final dropTimeRaw =
        isRentalTrip ? '-' : _stringOrDash(ui['drop_time'] ?? oldEndTime);

    final timezone = _stringOrDash(ui['timezone'] ?? oldTimezone);
    final hasDrop = dropAddress != '-' && dropAddress.trim().isNotEmpty;
    final hasDropTime = dropTimeRaw != '-' && dropTimeRaw.trim().isNotEmpty;

    CurrencyController? currencyController;
    try {
      currencyController = Get.isRegistered<CurrencyController>()
          ? Get.find<CurrencyController>()
          : null;
    } catch (_) {
      currencyController = null;
    }
    final currencySymbol = currencyController?.selectedCurrency.value.symbol ?? '';

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

                    // Payment summary
                    bookingDetailRow('Payment Type', paymentType),
                    bookingDetailRow('Currency', currencyCode),
                    bookingDetailRow('Amount', '$currencySymbol $amountStr'),

                    // Booking details (from BookingDetailsFinal -> provisionalData['ui'])
                    bookingDetailRow('Pickup', pickupAddress),
                    if (!isRentalTrip && hasDrop)
                      bookingDetailRow('Drop', dropAddress),
                    if (pickupTimeRaw != '-' && timezone != '-')
                      bookingDetailRow(
                        'Pickup Time',
                        convertUtcToLocal(
                            pickupTimeRaw, timezone == '-' ? 'UTC' : timezone),
                      ),
                    if (!isRentalTrip && hasDropTime && timezone != '-')
                      bookingDetailRow(
                        'Drop Time',
                        convertUtcToLocal(
                            dropTimeRaw, timezone == '-' ? 'UTC' : timezone),
                      ),

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
                              builder: (context) => BookingDetailsFinal(
                                fromPaymentFailure: true,
                              ), // replace with your screen
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