import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/controller/country/country_controller.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/controller/reservation_cancellation_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';

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
                Text(message,
                    style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    },
  );

  // Fake delay to simulate loading
  Future.delayed(const Duration(seconds: 3), () {
    Navigator.pop(context); // Close loader
  });

}


void _successLoader(String message, BuildContext outerContext, VoidCallback onComplete) {
  showDialog(
    context: outerContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      Future.delayed(const Duration(seconds: 1), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop(); // Close dialog
        }
        onComplete(); // 🚀 Call back to navigate
      });

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
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text("Booking Canceled Successfully",
                    style: TextStyle(fontSize: 16)),
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

  void _showReasonBottomSheet(BuildContext context) {
    final reasons = [
      "Change of plans",
      "Driver issue",
      "Booked by mistake",
      "Other",
    ];

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setModalState(() {
                          selectedReason = value;
                        });
                        setState(() {}); // update main UI
                      },
                    ),
                  ),
                  const SizedBox(height: 12), // spacing before Done button
                  SizedBox(
                    width: double.infinity,
                    child: MainButton(
                        text: 'Done',
                        onPressed: () {
                          Navigator.pop(context);
                        }),
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

    return Scaffold(
      appBar: AppBar(
        title: Text("Cancel Bookings",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black)),
        centerTitle: true,
        elevation: 0.6,
        backgroundColor: Colors.white,
        leading: Icon(
          Icons.arrow_back,
          color: Colors.black,
          size: 20,
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingDetails(booking),
            const SizedBox(height: 24),
            const Text(
              "Why are you cancelling?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

// Button to open bottom sheet
            OutlinedButton(
              onPressed: () => _showReasonBottomSheet(context),
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    Colors.grey.shade100, // optional light background
                foregroundColor: Colors.black87,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Colors.grey), // border color
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(selectedReason ?? "Select a reason"),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 46,
                  child: Opacity(
                      opacity: selectedReason == null ? 0.4 : 1,
                      child: MainButton(
                          text: 'Cancel Booking',
                          onPressed: () async {
                            _showLoader('Please wait', context);
                            final Map<String, dynamic> requestData = {
                              "id": booking["id"] ?? '',
                              "cancellation_reason": selectedReason,
                              "amount": booking["amountPaid"],
                              "payment_gateway_used":
                                  (countryController.isIndia == true) ? 1 : 0,
                              if (countryController.isIndia == true)
                                "paymentId": booking["paymentId"],
                              if (countryController.isIndia == true)
                                "receiptId": booking["recieptId"],
                            };
                            debugPrint(
                                'cancellation reservation request data : $requestData');
                            await reservationCancellationController
                                .verifyCancelReservation(requestData: requestData, context: context)
                                .then((value) {
                              _successLoader(
                                'Booking Canceled Successfully',
                                context,
                                    () {
                                  // ✅ Navigate only after loader closes
                                  GoRouter.of(context).go(AppRoutes.bottomNav);
                                },
                              );
                            });
                          })),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails(Map<String, dynamic> booking) {
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
                    () => currencyController.convertPrice(booking["amountPaid"].toDouble()),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
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

                return _buildDetailRow("Trip Type",  "${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(0)}");
              },
            ),

            _buildDetailRow("Amount Paid", booking["amountPaid"]),
            _buildDetailRow("Start Time", booking["startTime"]),
            _buildDetailRow("End Time", booking["endTime"]),
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

  void _showConfirmDialog(BuildContext context, Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Are you sure?"),
        content: Text(
            "Do you really want to cancel booking ID ${booking["id"]}?\nReason: $selectedReason"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("No")),
          ElevatedButton(
            onPressed: () async {
              final Map<String, dynamic> requestData = {
                "id": booking["id"] ?? '',
                "cancellation_reason": "asdfg",
                "amount": 1000,
                "payment_gateway_used": 2
              };
              await reservationCancellationController
                  .verifyCancelReservation(requestData: requestData, context: context)
                  .then((value) {
                _successLoader(
                  'Booking Canceled Successfully',
                  context,
                      () {
                    // ✅ Navigate only after loader closes
                    GoRouter.of(context).go(AppRoutes.bottomNav);
                  },
                );
              });

            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }
}
