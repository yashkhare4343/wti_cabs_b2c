import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// import '../bottom_nav/bottom_nav.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/controller/self_drive/self_drive_payment_status/self_drive_payment_booking_controller.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_home/self_drive_home_screen.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

import '../../../core/route_management/app_routes.dart';
// import '../route_management/app_routes.dart';

class SelfDrivePaymentSuccessPage extends StatefulWidget {
  const SelfDrivePaymentSuccessPage({super.key});

  @override
  State<SelfDrivePaymentSuccessPage> createState() => _SelfDrivePaymentSuccessPageState();
}

class _SelfDrivePaymentSuccessPageState extends State<SelfDrivePaymentSuccessPage> {
  final SelfDrivePaymentBookingController selfDrivePaymentBookingController =
  Get.put(SelfDrivePaymentBookingController());

  @override
  void initState() {
    super.initState();
    // ✅ Pass orderReferenceNumber
    selfDrivePaymentBookingController.fetchPaymentBookingDetails();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        GoRouter.of(context).go(AppRoutes.bottomNav);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Obx(() {
            if (selfDrivePaymentBookingController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final bookingResponse = selfDrivePaymentBookingController.sdPaymentBookingResponse.value;
            if (bookingResponse == null) {
              return const Center(child: Text("No booking details available"));
            }

            final result = bookingResponse.result;

            return SingleChildScrollView(
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 50),
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
                        if (result?.vehicleImg != null && result!.vehicleImg!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              result.vehicleImg!,
                              height: 130,
                              width: 160,
                              fit: BoxFit.fill,
                            ),
                          ),
                        const SizedBox(height: 16),

                        // 🔹 Booking Details Card
                        _buildDetailCard(
                          title: "Booking Details",
                          icon: Icons.assignment,
                          details: [
                            _detailItem("Booking Id", result?.bookingSummary?.first.value ?? ''),
                            _detailItem("User Name", result?.bookingSummary?[1].value ?? ''),
                            _detailItem("User Contact", result?.bookingSummary?[2].value.toString() ?? ''),
                            _detailItem("User Email", result?.bookingSummary?[3].value ?? ''),
                            _detailItem("Rental Type", result?.bookingSummary?[4].value ?? ''),
                            _detailItem("Vehicle", result?.bookingSummary?[5].value ?? ''),
                            _detailItem("Booked On", result?.bookingSummary?[6].value ?? ''),
                            _detailItem("Pickup", result?.pickup?.address ?? ''),
                            _detailItem("Pickup Date", result?.pickup?.date ?? ''),
                            _detailItem("Pickup Time", result?.pickup?.time ?? ''),
                            _detailItem("Drop Off", result?.drop?.address ?? ''),
                            _detailItem("Drop Off Date", result?.drop?.date ?? ''),
                            _detailItem("Drop Off Time", result?.drop?.time ?? ''),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 👉 Two buttons side by side
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
                                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              SelfDriveHomeScreen()),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
  Widget _buildDetailCard({ required String title, required IconData icon, required List<Widget> details, }) { return Card( elevation: 0.2, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.all(14), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Row( children: [ Icon(icon, color: Colors.green), const SizedBox(width: 8), Text( title, style: const TextStyle( fontSize: 14, fontWeight: FontWeight.w600), ), ], ), const Divider(height: 16), ...details, ], ), ), ); } Widget _detailItem(String label, String value) { return Padding( padding: const EdgeInsets.symmetric(vertical: 6), child: Row( children: [ Expanded( flex: 5, child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)), ), Expanded( flex: 7, child: Text( value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), ), ), ], ), ); }
}
