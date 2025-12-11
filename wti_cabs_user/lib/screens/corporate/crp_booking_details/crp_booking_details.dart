import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_booking_detail/crp_booking_detail_controller.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_booking_history/crp_booking_history_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';

import '../../../core/services/storage_services.dart';

class CrpBookingDetails extends StatefulWidget {
  final CrpBookingHistoryItem booking;

  const CrpBookingDetails({
    super.key,
    required this.booking,
  });

  @override
  State<CrpBookingDetails> createState() => _CrpBookingDetailsState();
}

class _CrpBookingDetailsState extends State<CrpBookingDetails> {
  final CrpBookingDetailsController crpBookingDetailsController = Get.put(CrpBookingDetailsController());
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchBookingDetails();
  }
  void fetchBookingDetails() async{
    final token = await StorageServices.instance.read('crpKey');
    final userEmail = await StorageServices.instance.read('email');
    await crpBookingDetailsController.fetchBookingData(widget.booking.bookingId.toString(), token??'', userEmail??'');
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.booking.status?.toLowerCase() == 'completed';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF000000),
          ),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text(
          'Details',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Booking Card
          Obx(() {
            if(crpBookingDetailsController.isLoading.value){
              return CircularProgressIndicator();
            }
            return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Type, Car Model, Car Details Link, and Status Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Booking Type
                            Text(
                              widget.booking.run ?? 'Airport Drop',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF002CC0),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Car Model
                            Text(
                              widget.booking.model ?? 'Swift Dzire',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Car Details Link
                            GestureDetector(
                              onTap: () {
                                // Handle car details navigation
                              },
                              child: Text(
                                'Car Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey.shade500,
                                  fontFamily: 'Montserrat',
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Car Icon and Status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // White 3D Car Icon (using a container with icon as placeholder)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.directions_car,
                              size: 20,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status with Checkmark
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color: isCompleted ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.booking.status ?? 'Completed',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isCompleted ? Colors.green : Colors.red,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Route Visualization
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vertical Line with Circle and Square
                      Column(
                        children: [
                          // Circle at top (Pickup)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFF002CC0),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Vertical Line
                          Container(
                            width: 2,
                            height: 50,
                            color: const Color(0xFF002CC0),
                          ),
                          // Square at bottom (Drop)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFF002CC0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Pickup and Drop Locations
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pickup Location
                            Text(
                              crpBookingDetailsController.crpBookingDetailResponse.value?.pickupAddress??'',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF000000),
                                fontFamily: 'Montserrat',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            // Drop Location
                            Text(
                              crpBookingDetailsController.crpBookingDetailResponse.value?.dropAddress??'',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF000000),
                                fontFamily: 'Montserrat',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Duration and Distance
                            Text(
                              '2 Hours 35 mins • 3 kms',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Dotted Divider
                  CustomPaint(
                    painter: DottedLinePainter(),
                    child: const SizedBox(
                      width: double.infinity,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Booking ID and Date
                  Text(
                    'Booking ID ${widget.booking.bookingNo ?? widget.booking.bookingId ?? '432411'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Booked on 23 Nov 2025',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Edit Booking and Feedback Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Edit Booking',
                              () {
                            // Navigate to modify booking screen with booking ID
                            final orderId = widget.booking.bookingId?.toString() ?? widget.booking.bookingNo ?? '';
                            if (orderId.isNotEmpty) {
                              GoRouter.of(context).push(
                                AppRoutes.cprModifyBooking,
                                extra: orderId,
                              );
                            }
                          },
                        ),
                      ),
                      // Vertical Divider
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildActionButton(
                          'Feedback',
                              () {
                            // Handle feedback
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
          }),
            const SizedBox(height: 16),
            // Need Help? Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Handle need help navigation
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.headset_mic,
                          color: const Color(0xFF002CC0),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Need Help?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF002CC0),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF002CC0),
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Dotted Line
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

