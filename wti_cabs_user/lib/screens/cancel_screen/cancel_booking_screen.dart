import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/controller/country/country_controller.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/controller/reservation_cancellation_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:wti_cabs_user/screens/bottom_nav/bottom_nav.dart';

import '../../utility/constants/colors/app_colors.dart';

class CancelBookingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const CancelBookingScreen({super.key, required this.booking});

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

void _showLoader(String message, BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpinKitFadingCircle(
                  color: Colors.deepPurple,
                  size: 48.0,
                ),
                SizedBox(height: 16),
                Text(message, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _successLoader(
  String message,
  BuildContext outerContext,
  VoidCallback onComplete,
) {
  showDialog(
    context: outerContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      Future.delayed(const Duration(seconds: 1), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop(); // Close dialog
        }
        onComplete(); // 🚀 Call back
      });

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  message, // ✅ Use dynamic message
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "This action was completed successfully.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  final ReservationCancellationController reservationCancellationController =
      Get.put(ReservationCancellationController());
  final CountryController countryController = Get.put(CountryController());
  String? selectedReason;
  final CurrencyController currencyController = Get.put(CurrencyController());

  Future<void> _cancelBooking({
    required BuildContext context,
    required Map<String, dynamic> booking,
    required String reason,
  }) async {
    _showLoader('Please wait', context);
    final Map<String, dynamic> requestData = {
      "id": booking["id"] ?? '',
      "cancellation_reason": reason,
      "amount": booking["amountPaid"],
      "payment_gateway_used": (countryController.isIndia == true) ? 1 : 0,
      if (countryController.isIndia == true) "paymentId": booking["paymentId"],
      if (countryController.isIndia == true) "receiptId": booking["recieptId"],
    };
    debugPrint('cancellation reservation request data : $requestData');

    final bool isSuccess =
        await reservationCancellationController.verifyCancelReservation(
      requestData: requestData,
      context: context,
    );

    if (!context.mounted) return;

    // Close "Please wait" loader immediately once API finishes
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!isSuccess) return;

    _successLoader(
      'Booking Canceled Successfully',
      context,
      () {
        // ✅ Navigate only after loader closes
        Navigator.of(context).push(
          Platform.isIOS
              ? CupertinoPageRoute(
                  builder: (_) => const BottomNavScreen(initialIndex: 0),
                )
              : MaterialPageRoute(
                  builder: (_) => const BottomNavScreen(initialIndex: 0),
                ),
        );
      },
    );
  }

  Future<bool> _showCancelConfirmationDialog({
    required BuildContext context,
    required String reason,
  }) async {
    if (Platform.isIOS) {
      final res = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Cancel booking?'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Reason: $reason\n\nThis action can’t be undone.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep booking'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancel booking'),
            ),
          ],
        ),
      );
      return res ?? false;
    }

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text('Reason: $reason\n\nThis action can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep booking'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _showCancelBottomSheet(BuildContext context) {
    final reasons = [
      "Change of plans",
      "Driver issue",
      "Booked by mistake",
      "Other",
    ];

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final booking = widget.booking;
            final String? modalSelectedReason = selectedReason;
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // reduced from 12
                  const Text(
                    "Select Cancellation Reason",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8), // reduced from 12
                  ...reasons.map(
                    (reason) => RadioListTile<String>(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 0), // less space
                      dense: true, // makes tile more compact
                      title: Text(reason, style: const TextStyle(fontSize: 14)),
                      value: reason,
                      groupValue: modalSelectedReason,
                      onChanged: (value) {
                        setModalState(() {
                          selectedReason = value;
                        });
                        setState(() {}); // update main UI
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                  buildRefundPolicy(),
                  const SizedBox(height: 8), // spacing before Done button
                  SizedBox(
                    width: double.infinity,
                    child: Opacity(
                      opacity: selectedReason == null ? 0.4 : 1,
                      child: MainButton(
                        text: 'Continue',
                        onPressed: () async {
                          final reason = selectedReason;
                          if (reason == null) return;

                          Navigator.pop(context); // close bottom sheet

                          final shouldCancel =
                              await _showCancelConfirmationDialog(
                            context: context,
                            reason: reason,
                          );
                          if (!shouldCancel) return;

                          if (!context.mounted) return;
                          await _cancelBooking(
                            context: context,
                            booking: booking,
                            reason: reason,
                          );
                        },
                      ),
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
    final booking = widget.booking;

    return PopScope(
      // iOS interactive swipe-back needs a real pop. Keep Android back routing intact.
      canPop: Platform.isIOS,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Always use push (matches existing Android behavior).
        Navigator.of(context).push(
          Platform.isIOS
              ? CupertinoPageRoute(
                  builder: (_) => const BottomNavScreen(initialIndex: 1),
                )
              : MaterialPageRoute(
                  builder: (_) => const BottomNavScreen(initialIndex: 1),
                ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Bookings Details",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black)),
          centerTitle: true,
          elevation: 0.6,
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'More',
              onPressed: () => _showCancelBottomSheet(context),
              icon: const Icon(Icons.more_vert, color: Colors.black),
            ),
          ],
          leading: GestureDetector(
            onTap: () {
              // Always use push (matches existing Android behavior).
              Navigator.of(context).push(
                Platform.isIOS
                    ? CupertinoPageRoute(
                        builder: (_) => const BottomNavScreen(initialIndex: 1),
                      )
                    : MaterialPageRoute(
                        builder: (_) => const BottomNavScreen(initialIndex: 1),
                      ),
              );
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookingDetails(booking),
              // const SizedBox(height: 16),
              // Text(
              //   selectedReason == null
              //       ? "To cancel this booking, tap the 3-dot menu in the top-right."
              //       : "Selected reason: $selectedReason",
              //   style: const TextStyle(fontSize: 13, color: Colors.black54),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDetails(Map<String, dynamic> booking) {
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

    return Card(
      color: const Color(0xFFFFFFFF),
      elevation: 0.6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Booking Details",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12), // spacing between heading and details
            _buildDetailRow("Booking ID", booking["id"]),
            _buildDetailRow("Vehicle", booking["vehicleType"]),
            _buildDetailRow("Pickup", booking["pickup"]),
            _buildDetailRow("Drop", booking["drop"]),
            _buildDetailRow("Trip Type", booking["tripType"]),
            FutureBuilder<double>(
              future: Future.delayed(
                const Duration(milliseconds: 500), // 0.5s fake loader
                () => currencyController
                    .convertPrice(booking["amountPaid"].toDouble()),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 12,
                    width: 20,
                    child: Center(
                      child: SizedBox(
                        height: 10,
                        width: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey.shade400),
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Text(
                    "--",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  );
                }

                final convertedValue =
                    snapshot.data ?? booking["amountPaid"].toDouble();

                return _buildDetailRow("Amount Paid",
                    "${currencyController.selectedCurrency.value.code} ${convertedValue.toStringAsFixed(2)}");
              },
            ),

            // _buildDetailRow("Amount Paid", booking["amountPaid"]),
            _buildDetailRow(
              "Start Time",
              convertUtcToLocal(
                booking["startTime"].toString(),
                booking["timezone"].toString(),
              ),
            ),
            _buildDetailRow(
              "End Time",
              convertUtcToLocal(
                booking["endTime"].toString(),
                booking["timezone"].toString(),
              ),
            ),

            _buildDetailRow("Timezone", booking["timezone"]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value?.toString() ?? "-"),
          ),
        ],
      ),
    );
  }

  Widget _reasonChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedReason == label,
      onSelected: (val) {
        setState(() => selectedReason = val ? label : null);
      },
      selectedColor: Colors.red.shade100,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: selectedReason == label ? Colors.red : Colors.black87,
      ),
    );
  }
}

// refund info card
Widget buildRefundPolicy() {
  return Card(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.receipt_long, // You can also try Icons.policy or Icons.info
            color: Colors.blueAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Refund Policy",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "• Cancellations within 1 hour of the booking start time are not eligible for a refund.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
