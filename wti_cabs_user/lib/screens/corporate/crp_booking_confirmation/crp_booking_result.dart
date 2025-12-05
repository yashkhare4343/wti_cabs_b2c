import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_booking_data/crp_booking_data.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_car_models/crp_car_models_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

class CrpBookingResultPage extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final CrpBookingData? bookingData;
  final CrpCarModel? selectedCar;

  const CrpBookingResultPage({
    super.key,
    required this.isSuccess,
    required this.message,
    this.bookingData,
    this.selectedCar,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = bookingData?.pickupPlace?.primaryText ?? '';
    final drop = bookingData?.dropPlace?.primaryText ?? '';
    final tripType = bookingData?.pickupType ?? '';
    final carType = selectedCar?.carType ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 50,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSuccess ? 'Booking Successful' : 'Booking Failed',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Booking details card
                  _buildDetailCard(
                    title: "Booking Details",
                    icon: Icons.assignment,
                    children: [
                      _detailRow("Trip Type", tripType),
                      if (pickup.isNotEmpty) _detailRow("Pickup", pickup),
                      if (drop.isNotEmpty) _detailRow("Drop", drop),
                      if (carType.isNotEmpty) _detailRow("Car Type", carType),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.mainButtonBg,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        // Same navigation as in crp_booking_confirmation.dart (1096-1097)
                        GoRouter.of(context).go(AppRoutes.cprHomeScreen);
                      },
                      child: const Text(
                        'Go to Home',
                        style: TextStyle(
                          color: AppColors.mainButtonBg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




