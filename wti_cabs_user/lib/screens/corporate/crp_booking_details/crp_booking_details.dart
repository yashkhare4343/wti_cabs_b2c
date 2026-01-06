import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_booking_detail/crp_booking_detail_controller.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_booking_history/crp_booking_history_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../common_widget/loader/shimmer/corporate_shimmer.dart';
import '../../../common_widget/loader/popup_loader.dart';
import '../../../common_widget/snackbar/custom_snackbar.dart';
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
  Future<void> fetchBookingDetails() async{
    final token = await StorageServices.instance.read('crpKey');
    final userEmail = await StorageServices.instance.read('email');
    final orderId = widget.booking.bookingId.toString();
    await crpBookingDetailsController.fetchBookingData(orderId, token??'', userEmail??'');
    await crpBookingDetailsController.fetchDriverDetails(orderId, token??'', userEmail??'');
  }

  /// Refresh booking details when returning from modify screen
  Future<void> _refreshBookingDetails() async {
    await fetchBookingDetails();
    if (mounted) {
      setState(() {});
    }
  }

  // Helper method to check if status is dispatched
  bool _isDispatched(String? status) {
    if (status == null) return false;
    final statusLower = status.toLowerCase().trim();
    return statusLower == '2' || statusLower == 'dispatched';
  }

  /// Extract numeric booking ID from booking number
  /// Example: "WTI-DEL20260102-3518818" -> "3518818"
  String? _extractNumericBookingId(CrpBookingHistoryItem booking) {
    // Try bookingNo first (e.g., "WTI-DEL20260102-3518818")
    if (booking.bookingNo != null && booking.bookingNo!.isNotEmpty) {
      final parts = booking.bookingNo!.split('-');
      if (parts.isNotEmpty) {
        // Get the last part after the last hyphen
        final lastPart = parts.last;
        // Check if it's numeric
        if (RegExp(r'^\d+$').hasMatch(lastPart)) {
          return lastPart;
        }
      }
    }
    
    // Fallback to bookingId or id if available
    if (booking.bookingId != null) {
      return booking.bookingId.toString();
    }
    if (booking.id != null) {
      return booking.id.toString();
    }
    
    return null;
  }

  Future<void> _downloadInvoice(CrpBookingHistoryItem booking) async {
    try {
      // Extract numeric booking ID from booking number
      final numericBookingId = _extractNumericBookingId(booking);
      
      if (numericBookingId == null || numericBookingId.isEmpty) {
        if (mounted) {
          CustomFailureSnackbar.show(context, 'Booking ID not found');
        }
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopupLoader(message: 'Downloading Invoice...'),
      );

      // Construct invoice URL with extracted numeric booking ID
      final invoiceUrl = 'http://office.aaveg.co.in/Mt/PrintFullDS_Digital?BookingID=$numericBookingId';

      // Request storage permissions (for Android)
      if (Platform.isAndroid) {
        // Android 13+ → use these new permissions
        if (await Permission.photos.isDenied) {
          await Permission.photos.request();
        }
        if (await Permission.videos.isDenied) {
          await Permission.videos.request();
        }
        // Older Android (for writing to /storage/emulated/0/Download)
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
      }

      // Determine download directory
      Directory? dir;
      if (Platform.isAndroid) {
        if (await Directory("/storage/emulated/0/Download").exists()) {
          dir = Directory("/storage/emulated/0/Download");
        } else {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        if (mounted) {
          GoRouter.of(context).pop(); // Close loader
          CustomFailureSnackbar.show(context, 'Could not access download directory');
        }
        return;
      }

      // Download the PDF
      final uri = Uri.parse(invoiceUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Save the PDF file
        final fileName = 'invoice_$numericBookingId.pdf';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);

        // Ensure directory exists
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }

        await file.writeAsBytes(response.bodyBytes);

        // Close loader dialog
        if (mounted) {
          GoRouter.of(context).pop();
        }

        // Open the PDF file directly in PDF viewer
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done && mounted) {
          CustomSuccessSnackbar.show(context, 'PDF saved to ${dir.path}. Opening...');
        }
      } else if (response.statusCode == 500) {
        if (mounted) {
          GoRouter.of(context).pop(); // Close loader
          CustomFailureSnackbar.show(context, 'The booking is still in progress. The invoice will be available once the trip is completed.');
        }
      } else {
        if (mounted) {
          GoRouter.of(context).pop(); // Close loader
          CustomFailureSnackbar.show(context, 'Failed to download invoice. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        GoRouter.of(context).pop(); // Close loader
        CustomFailureSnackbar.show(context, 'Error downloading invoice: ${e.toString()}');
      }
    }
  }


  /// Build status badge with pill design and different colors/icons for each status
  Widget _buildStatusBadge(String? status) {
    // Normalize status to handle case variations
    final normalizedStatus = (status ?? 'Pending').trim().toLowerCase();

    // Define colors and icons for each status
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    IconData icon;
    String statusText;

    if (normalizedStatus == 'confirmed' || normalizedStatus == '1') {
      backgroundColor = const Color(0xFFECFDD7); // Light green
      textColor = const Color(0xFF7CC521); // Dark green
      iconColor = const Color(0xFF7CC521);
      icon = Icons.check_circle_outline;
      statusText = 'Confirmed';
    } else if (normalizedStatus == 'allocated' ||
        normalizedStatus == 'completed' || normalizedStatus == '6') {
      backgroundColor = const Color(0xFFE3F2FD); // Light blue
      textColor = const Color(0xFF2196F3); // Dark blue
      iconColor = const Color(0xFF2196F3);
      icon = Icons.check_circle;
      statusText = normalizedStatus == '6' ? 'Allocated' : 'Allocated';
    } else if (normalizedStatus == 'cancelled' ||
        normalizedStatus == 'canceled' || normalizedStatus == '4') {
      backgroundColor = const Color(0xFFFFEBEE); // Light red/pink
      textColor = const Color(0xFFE91E63); // Dark pink/red
      iconColor = const Color(0xFFE91E63);
      icon = Icons.cancel;
      statusText = 'Cancelled';
    } else if (normalizedStatus == 'pending' || normalizedStatus == '0') {
      backgroundColor = const Color(0xFFFFF3E0); // Light orange
      textColor = const Color(0xFFFF9800); // Dark orange
      iconColor = const Color(0xFFFF9800);
      icon = Icons.access_time;
      statusText = 'Pending';
    } else if (normalizedStatus == 'dispatched' || normalizedStatus == '2') {
      backgroundColor = const Color(0xFFF3E5F5); // Light purple
      textColor = const Color(0xFF9C27B0); // Dark purple
      iconColor = const Color(0xFF9C27B0);
      icon = Icons.check_circle;
      statusText = 'Dispatched';
    } else if (normalizedStatus == 'missed' || normalizedStatus == '3') {
      backgroundColor = const Color(0xFFE0E0E0); // Light grey
      textColor = const Color(0xFF757575); // Dark grey
      iconColor = const Color(0xFF757575);
      icon = Icons.warning;
      statusText = 'Missed';
    } else if (normalizedStatus == 'void' || normalizedStatus == '5') {
      backgroundColor = const Color(0xFFE0E0E0); // Light grey
      textColor = const Color(0xFF757575); // Dark grey
      iconColor = const Color(0xFF757575);
      icon = Icons.block;
      statusText = 'Void';
    } else {
      // Default for unknown statuses
      backgroundColor = const Color(0xFFF5F5F5); // Light grey
      textColor = const Color(0xFF757575); // Dark grey
      iconColor = const Color(0xFF757575);
      icon = Icons.help_outline;
      statusText = status ?? 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20), // Pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(width: 6),
          Center(
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
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
                      // Status Badge
                      _buildStatusBadge(widget.booking.status),
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
                  Obx(() {
                    final dropAddress = crpBookingDetailsController.crpBookingDetailResponse.value?.dropAddress;
                    // Only show drop if it's not null, not empty (trimmed), and not the string "null"
                    final hasDropAddress = dropAddress != null && 
                        dropAddress.trim().isNotEmpty && 
                        dropAddress.trim().toLowerCase() != 'null';
                    
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vertical Line with Circle and Square
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: SizedBox(
                              width: 28,
                              child: Column(
                                children: [
                                  // Circle with dot (pickup icon)
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFA4FF59),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Vertical line (only show if drop exists and is not null)
                                  if (hasDropAddress)
                                    SizedBox(
                                      width: 2,
                                      height: 24,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: List.generate(
                                          6,
                                          (_) => Container(
                                            width: 2,
                                            height: 3,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF7B7B7B),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Square end (drop icon) - only show if drop exists and is not null
                                  if (hasDropAddress)
                                    Container(
                                      width: 15,
                                      height: 15,
                                      padding: EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFB179),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFFFF),
                                          borderRadius: BorderRadius.circular(0.5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
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
                                // Drop Location - only show if drop exists and is not null or "null"
                                if (hasDropAddress && dropAddress != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    dropAddress.trim(),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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

                  final formattedDate = DateFormat('dd MMM yyyy, hh:mm a')
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
                  // Edit Booking, Track Cab, and Download Invoice Buttons
                  Builder(
                    builder: (context) {
                      final bookingStatus = (widget.booking.status ?? '').toLowerCase().trim();
                      return Row(
                        children: [
                          // Only show Edit Booking button if status is not dispatched or cancelled
                          if (bookingStatus != 'dispatched' && bookingStatus != '2' && 
                              bookingStatus != 'cancelled' && bookingStatus != 'canceled' && bookingStatus != '4') ...[
                        Expanded(
                          child: _buildActionButton(
                            'Edit Booking',
                            () async {
                              // Navigate to modify booking screen with booking ID and car model
                              final orderId = widget.booking.bookingId?.toString() ??
                                  widget.booking.bookingNo ??
                                  '';
                              if (orderId.isNotEmpty) {
                                final result = await GoRouter.of(context).push<bool>(
                                  AppRoutes.cprModifyBooking,
                                  extra: {
                                    'orderId': orderId,
                                    'carModelName': widget.booking.model,
                                  },
                                );
                                // If modification/cancellation was successful, refresh booking details
                                if (result == true && mounted) {
                                  await _refreshBookingDetails();
                                  // Pop with result true to refresh booking list in parent screen
                                  GoRouter.of(context).pop(true);
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if(bookingStatus == 'dispatched' || bookingStatus == '2')...[
                        Expanded(
                          child: _buildActionButton(
                            'Track Cab',
                            () {
                              // Navigate to tracking screen with booking ID and details
                              final bookingId = widget.booking.bookingId?.toString() ??
                                  widget.booking.bookingNo ??
                                  '';
                              if (bookingId.isNotEmpty) {
                                // Get driver details from controller
                                final driverDetails = crpBookingDetailsController.driverDetailsResponse.value;
                                final bookingDetails = crpBookingDetailsController.crpBookingDetailResponse.value;
                                
                                GoRouter.of(context).push(
                                  AppRoutes.cprCabTracking,
                                  extra: {
                                    'bookingId': bookingId,
                                    'carModel': widget.booking.model ?? '',
                                    'carNo': driverDetails?.carNo ?? '',
                                    'driverName': driverDetails?.chauffeur ?? '',
                                    'driverMobile': driverDetails?.mobile ?? '',
                                    'bookingNo': widget.booking.bookingNo ?? widget.booking.bookingId?.toString() ?? '',
                                    'cabRequiredOn': widget.booking.cabRequiredOn ?? bookingDetails?.cabRequiredOn ?? '',
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ],
                      // Show Download Invoice button for completed statuses (Dispatched and Allocated)
                      if ((widget.booking.status?.toLowerCase().trim() == 'allocated') || 
                          (widget.booking.status?.toLowerCase().trim() == 'dispatched')) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            'Download Invoice',
                            () => _downloadInvoice(widget.booking),
                          ),
                        ),
                      ],
                    ],
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
                      );
                    },
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

