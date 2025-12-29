import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_booking_detail/crp_booking_detail_controller.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_booking_history/crp_booking_history_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';

import '../../../common_widget/loader/shimmer/corporate_shimmer.dart';
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
  bool _showShimmer = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchBookingDetails();
    // Show shimmer for 0.5 seconds
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showShimmer = false;
        });
      }
    });
  }
  void fetchBookingDetails() async{
    final token = await StorageServices.instance.read('crpKey');
    final userEmail = await StorageServices.instance.read('email');
    final orderId = widget.booking.bookingId.toString();
    await crpBookingDetailsController.fetchBookingData(orderId, token??'', userEmail??'');
    await crpBookingDetailsController.fetchDriverDetails(orderId, token??'', userEmail??'');
  }

  // Helper method to get status icon and color based on status
  Map<String, dynamic> _getStatusIconAndColor(String? status) {
    if (status == null) {
      return {
        'icon': Icons.pending,
        'color': Colors.orange,
        'text': 'Pending',
      };
    }

    final statusLower = status.toLowerCase().trim();
    
    // Handle numeric status codes
    switch (statusLower) {
      case '0':
      case 'pending':
        return {
          'icon': Icons.pending,
          'color': Colors.orange,
          'text': 'Pending',
        };
      case '1':
      case 'confirmed':
        return {
          'icon': Icons.check_circle,
          'color': Colors.green,
          'text': 'Confirmed',
        };
      case '2':
      case 'dispatched':
        return {
          'icon': Icons.local_shipping,
          'color': Colors.blue,
          'text': 'Dispatched',
        };
      case '3':
      case 'missed':
        return {
          'icon': Icons.error_outline,
          'color': Colors.orange,
          'text': 'Missed',
        };
      case '4':
      case 'cancelled':
        return {
          'icon': Icons.cancel,
          'color': Colors.red,
          'text': 'Cancelled',
        };
      case '5':
      case 'void':
        return {
          'icon': Icons.block,
          'color': Colors.grey,
          'text': 'Void',
        };
      case '6':
      case 'allocated':
        return {
          'icon': Icons.assignment,
          'color': Colors.blue.shade700,
          'text': 'Allocated',
        };
      default:
        // Default case for unknown statuses
        return {
          'icon': Icons.help_outline,
          'color': Colors.grey,
          'text': status,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showShimmer) {
      return CorporateShimmer(
        showAppBar: true,
        isDetailsPage: true,
        customAppBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          leading: Icon(
            Icons.arrow_back,
            color: Color(0xFF000000),
          ),
          title: Text(
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
      );
    }

    final statusInfo = _getStatusIconAndColor(widget.booking.status);

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
                      // White 3D Car Icon (using a container with icon as placeholder)
                      Container(
                        width: 63,
                        height: 47,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/booking_crp_car.png',
                          width: 60,
                          height: 47,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Booking Type
                            Text(
                              widget.booking.run ?? 'Airport Drop',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF192653),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Car Model
                            Text(
                              widget.booking.model ?? 'Swift Dzire',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF939393),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            // Car Details Link
                            // GestureDetector(
                            //   onTap: () {
                            //     // Handle car details navigation
                            //   },
                            //   child: Text(
                            //     'Car Details',
                            //     style: TextStyle(
                            //       fontSize: 14,
                            //       fontWeight: FontWeight.w400,
                            //       color: Colors.grey.shade500,
                            //       fontFamily: 'Montserrat',
                            //       decoration: TextDecoration.underline,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      // Car Icon and Status
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status with Icon
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusInfo['icon'] as IconData,
                                size: 16,
                                color: statusInfo['color'] as Color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusInfo['text'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: statusInfo['color'] as Color,
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
                  CustomPaint(
                    painter: DottedLinePainter(),
                    child: const SizedBox(
                      width: double.infinity,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 16,),
                  // Route Visualization
                  IntrinsicHeight(
                    child: Row(
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
                            // Vertical Line - expands to fill available space
                            Expanded(
                              child: Container(
                                width: 2,
                                color: const Color(0xFF002CC0),
                              ),
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
                                crpBookingDetailsController.crpBookingDetailResponse.value?.pickupAddress ?? 
                                widget.booking.passenger ?? 
                                'Pickup location',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F4F4F),
                                  fontFamily: 'Montserrat',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              // Drop Location
                              Text(
                                crpBookingDetailsController.crpBookingDetailResponse.value?.dropAddress ?? 
                                'Drop location',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F4F4F),
                                  fontFamily: 'Montserrat',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                    'Booking ID:- ${widget.booking.bookingNo ?? widget.booking.bookingId ?? '432411'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                Obx(() {
                  final raw = crpBookingDetailsController
                      .crpBookingDetailResponse.value?.cabRequiredOn;

                  if (raw == null || raw.isEmpty) {
                    return const SizedBox();
                  }

                  final formattedDate = DateFormat('dd MMM yyyy')
                      .format(DateTime.parse(raw));

                  return Text(
                    'Pickup Time:- $formattedDate',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                      fontFamily: 'Montserrat',
                    ),
                  );
                }),
                  const SizedBox(height: 20),
                  // Edit Booking and Track Cab Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Edit Booking',
                          () {
                            // Navigate to modify booking screen with booking ID and car model
                            final orderId = widget.booking.bookingId?.toString() ??
                                widget.booking.bookingNo ??
                                '';
                            if (orderId.isNotEmpty) {
                              GoRouter.of(context).push(
                                AppRoutes.cprModifyBooking,
                                extra: {
                                  'orderId': orderId,
                                  'carModelName': widget.booking.model,
                                },
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          'Track Cab',
                          () {
                            // Navigate to tracking screen with booking ID
                            final bookingId = widget.booking.bookingId?.toString() ??
                                widget.booking.bookingNo ??
                                '';
                            if (bookingId.isNotEmpty) {
                              GoRouter.of(context).push(
                                AppRoutes.cprCabTracking,
                                extra: bookingId,
                              );
                            }
                          },
                        ),
                      ),
                      // Vertical Divider
                      // Container(
                      //   width: 8,
                      //   height: 36,
                      //   color: Colors.transparent,
                      // ),
                      // Expanded(
                      //   child: _buildActionButton(
                      //     'Feedback',
                      //         () {
                      //       // Handle feedback
                      //     },
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          );
          }),
            const SizedBox(height: 16),
            // Chauffeur Details Card
            Obx(() {
              final driverDetails = crpBookingDetailsController.driverDetailsResponse.value;
              // Only show card if bStatus is true
              if (driverDetails?.bStatus != true) {
                return const SizedBox.shrink();
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
                      // Title
                      const Text(
                        'Chauffeur Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF192653),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Driver Name
                      _buildDetailRow(
                        'Driver Name',
                        driverDetails?.chauffeur ?? 'N/A',
                        Icons.person,
                      ),
                      const SizedBox(height: 12),
                      // Driver No
                      _buildDetailRow(
                        'Driver No',
                        driverDetails?.mobile ?? 'N/A',
                        Icons.phone,
                      ),
                      const SizedBox(height: 12),
                      // Car Model
                      _buildDetailRow(
                        'Car Model',
                        widget.booking.model ?? 'N/A',
                        Icons.directions_car,
                      ),
                      const SizedBox(height: 12),
                      // Car No
                      _buildDetailRow(
                        'Car No',
                        driverDetails?.carNo ?? 'N/A',
                        Icons.confirmation_number,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            // Need Help? Section
            // Container(
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     color: const Color(0xFFE8F0FE),
            //     borderRadius: BorderRadius.circular(12),
            //     border: Border.all(
            //       color: Colors.grey.shade200,
            //       width: 1,
            //     ),
            //   ),
            //   child: Material(
            //     color: Colors.transparent,
            //     child: InkWell(
            //       onTap: () {
            //         // Handle need help navigation
            //       },
            //       borderRadius: BorderRadius.circular(12),
            //       child: Padding(
            //         padding: const EdgeInsets.symmetric(
            //           horizontal: 16.0,
            //           vertical: 14.0,
            //         ),
            //         child: Row(
            //           children: [
            //             Icon(
            //               Icons.headset_mic,
            //               color: const Color(0xFF002CC0),
            //               size: 24,
            //             ),
            //             const SizedBox(width: 12),
            //             const Text(
            //               'Need Help?',
            //               style: TextStyle(
            //                 fontSize: 16,
            //                 fontWeight: FontWeight.w500,
            //                 color: Color(0xFF002CC0),
            //                 fontFamily: 'Montserrat',
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF002CC0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F4F4F),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      ],
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

