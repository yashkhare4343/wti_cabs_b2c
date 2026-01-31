import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/api/corporate/cpr_api_services.dart';
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
  final VoidCallback? onRefreshParent;
  final Future<CrpBookingHistoryItem?> Function()? getUpdatedBooking;

  const CrpBookingDetails({
    super.key,
    required this.booking,
    this.onRefreshParent,
    this.getUpdatedBooking,
  });

  @override
  State<CrpBookingDetails> createState() => _CrpBookingDetailsState();
}

class _CrpBookingDetailsState extends State<CrpBookingDetails> {
  final CrpBookingDetailsController crpBookingDetailsController = Get.put(CrpBookingDetailsController());
  bool _showShimmer = true;
  
  // Local state to hold current booking (can be updated after refresh)
  late CrpBookingHistoryItem _currentBooking;
  
  // Access currentDispatchStatusId from current booking
  int? get currentDispatchStatusId => _currentBooking.currentDispatchStatusId;

  // Draggable SOS floating button (shown only when dispatched / status==2)
  static const double _sosButtonSize = 72;
  static const double _sosMargin = 8;
  Offset? _sosOffset;
  bool _isSendingSos = false;

  /// Get effective status for a booking
  /// If status is "Dispatched" and currentDispatchStatusId is 6 (Close), return "Completed"
  String _getEffectiveStatus() {
    return _getEffectiveStatusFrom(
      status: _currentBooking.status,
      currentDispatchStatusId: _currentBooking.currentDispatchStatusId,
    );
  }

  String _getEffectiveStatusFrom({
    required String? status,
    required int? currentDispatchStatusId,
  }) {
    if (status == null || status.isEmpty) return status ?? 'Pending';
    
    final normalizedStatus = status.trim().toLowerCase();
    // If status is "Dispatched" and currentDispatchStatusId is 6 (Close), treat as "Completed"
    if ((normalizedStatus == 'dispatched' || normalizedStatus == '2') &&
        currentDispatchStatusId == 6) {
      return 'Completed';
    }
    
    return status;
  }

  /// Sync local `_currentBooking.status` from latest booking-detail API.
  /// This ensures the status badge (which reads `_currentBooking.status`) updates after refresh.
  void _syncCurrentBookingStatusFromDetailsResponse() {
    final details = crpBookingDetailsController.crpBookingDetailResponse.value;
    final bookingStatus = details?.bookingStatus;
    if (bookingStatus == null) return;

    final nextStatus = bookingStatus.toString();
    if ((_currentBooking.status ?? '').trim() == nextStatus) return;
    if (!mounted) return;

    setState(() {
      _currentBooking = CrpBookingHistoryItem(
        bookingId: _currentBooking.bookingId,
        uid: _currentBooking.uid,
        id: _currentBooking.id,
        bookingNo: _currentBooking.bookingNo,
        passenger: _currentBooking.passenger,
        cabRequiredOn: _currentBooking.cabRequiredOn,
        pickupDateTime: _currentBooking.pickupDateTime,
        completedDateTime: _currentBooking.completedDateTime,
        cancelledDateTime: _currentBooking.cancelledDateTime,
        status: nextStatus,
        model: _currentBooking.model,
        run: _currentBooking.run,
        isReviewed: _currentBooking.isReviewed,
        pickupAddress: _currentBooking.pickupAddress,
        dropAddress: _currentBooking.dropAddress,
        currentDispatchStatusId: _currentBooking.currentDispatchStatusId,
        extraPaxCount: _currentBooking.extraPaxCount,
        multipax: _currentBooking.multipax,
      );
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Initialize current booking with widget booking
    _currentBooking = widget.booking;
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
    final orderId = _currentBooking.bookingId.toString();
    await crpBookingDetailsController.fetchBookingData(orderId, token??'', userEmail??'');
    _syncCurrentBookingStatusFromDetailsResponse();
    await crpBookingDetailsController.fetchDriverDetails(orderId, token??'', userEmail??'');
  }

  /// Refresh booking details when returning from modify screen
  Future<void> _refreshBookingDetails() async {
    await fetchBookingDetails();
    // Also refresh the parent booking list if callback is provided
    if (widget.onRefreshParent != null) {
      widget.onRefreshParent!();
    }
    // Get updated booking from parent if callback is provided
    if (widget.getUpdatedBooking != null) {
      final updatedBooking = await widget.getUpdatedBooking!();
      if (updatedBooking != null && mounted) {
        setState(() {
          _currentBooking = updatedBooking;
        });
      }
    }
    // Ensure badge reflects latest status even if parent did not provide updated booking.
    _syncCurrentBookingStatusFromDetailsResponse();
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

  void _ensureInitialSosOffset(BoxConstraints constraints) {
    if (_sosOffset != null) return;

    // Defer setState so we don't update during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _sosOffset != null) return;
      final initial = Offset(
        constraints.maxWidth - _sosButtonSize - _sosMargin,
        constraints.maxHeight - _sosButtonSize - _sosMargin,
      );
      setState(() {
        _sosOffset = _clampSosOffset(initial, constraints);
      });
    });
  }

  Offset _clampSosOffset(Offset proposed, BoxConstraints constraints) {
    final minX = _sosMargin;
    final minY = _sosMargin;
    final rawMaxX = constraints.maxWidth - _sosButtonSize - _sosMargin;
    final rawMaxY = constraints.maxHeight - _sosButtonSize - _sosMargin;
    final maxX = (rawMaxX < minX) ? minX : rawMaxX;
    final maxY = (rawMaxY < minY) ? minY : rawMaxY;

    return Offset(
      proposed.dx.clamp(minX, maxX).toDouble(),
      proposed.dy.clamp(minY, maxY).toDouble(),
    );
  }

  Future<void> _confirmAndSendSosAlert() async {
    if (_isSendingSos || !mounted) return;

    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Send Emergency Alert', style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F), // Near-black for seriousness
                ),),
                content: const Text(
                  'This action will notify our emergency support team for immediate attention.\n',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4F4F4F), // Calm dark grey
                    height: 1.4,
                  ),
                ),
                actionsPadding: EdgeInsets.zero,
                actions: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel', style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF757575), // Grey
                              ),),
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (_isSendingSos) return;
                                  setDialogState(() => isSubmitting = true);
                                  Navigator.of(dialogContext).pop();
                                  await Future<void>.delayed(Duration.zero);
                                  if (!mounted) return;
                                  await _sendSosAlert();
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            foregroundColor:
                                Theme.of(context).colorScheme.onError,
                          ),
                          child: const Text('Send Alert', style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSosButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.transparent,
        onTap: _isSendingSos ? null : _confirmAndSendSosAlert,
        child: SizedBox(
          width: _sosButtonSize,
          height: _sosButtonSize,
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/sos_floating.png',
                    fit: BoxFit.contain,
                  ),
                ),
                if (_isSendingSos)
                  Container(
                    color: Colors.white.withOpacity(0.45),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendSosAlert() async {
    if (_isSendingSos) return;
    setState(() {
      _isSendingSos = true;
    });

    try {
      final token = await StorageServices.instance.read('crpKey');
      final user = await StorageServices.instance.read('email');
      final guestIdStr = await StorageServices.instance.read('guestId');
      final bookingIdStr = _extractNumericBookingId(_currentBooking);

      if (token == null || token.isEmpty || token == 'null') {
        CustomFailureSnackbar.show(context, 'Token missing. Please login again.');
        return;
      }
      if (user == null || user.isEmpty || user == 'null') {
        CustomFailureSnackbar.show(context, 'User missing. Please login again.');
        return;
      }
      final bookingId = int.tryParse((bookingIdStr ?? '').trim());
      if (bookingId == null) {
        CustomFailureSnackbar.show(context, 'Booking ID not found');
        return;
      }
      final guestId = int.tryParse((guestIdStr ?? '').trim());
      if (guestId == null) {
        CustomFailureSnackbar.show(context, 'Guest ID not found');
        return;
      }

      // Try to get current location; fallback to sample coordinates if unavailable.
      double lat = 0.0;
      double lng = 0.0;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (_) {
        // keep fallback
      }

      final payload = {
        "Lat": lat,
        "lng": lng,
        "BookingID": bookingId,
        "GuestID": guestId,
      };

      final uri = Uri.parse('${CprApiService().baseUrl}/SOSAlert').replace(
        queryParameters: {
          'user': user,
          'token': token,
        },
      );

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Basic $token',
      };

      final response = await CprApiService().sendRequestWithRetry(() {
        return http.post(uri, headers: headers, body: jsonEncode(payload));
      });

      dynamic decoded = response.body;
      try {
        // Some APIs wrap JSON in quotes; decode until it's no longer wrapped.
        while (decoded is String &&
            decoded.startsWith('"') &&
            decoded.endsWith('"')) {
          decoded = jsonDecode(decoded);
        }
        if (decoded is String) {
          decoded = jsonDecode(decoded);
        }
      } catch (_) {
        // leave as-is
      }

      final map = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
      final bStatus = map['bStatus'] == true;
      final message = (map['sMessage'] ?? map['message'] ?? 'SOS request completed').toString();

      if (!mounted) return;
      if (bStatus) {
        CustomSuccessSnackbar.show(context, message);
      } else {
        CustomFailureSnackbar.show(context, message);
      }
    } catch (e) {
      if (!mounted) return;
      CustomFailureSnackbar.show(context, 'Failed to send SOS alert');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingSos = false;
        });
      }
    }
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

  /// Download DutySlip PDF and open it directly in PDF viewer
  Future<void> _downloadDutySlip(CrpBookingHistoryItem booking) async {
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
        builder: (_) => const PopupLoader(message: 'Downloading DutySlip...'),
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
      // Use app's external storage directory (works on all Android versions including 13+)
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
        if (dir != null) {
          // Create Downloads subfolder in app's external storage for better organization
          dir = Directory('${dir.path}/Download');
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
        // Ensure directory exists before saving
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        // Save the PDF file
        final fileName = 'dutyslip_$numericBookingId.pdf';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);

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
          CustomFailureSnackbar.show(context, 'The booking is still in progress. The DutySlip will be available once the trip is completed.');
        }
      } else {
        if (mounted) {
          GoRouter.of(context).pop(); // Close loader
          CustomFailureSnackbar.show(context, 'Failed to download DutySlip. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        GoRouter.of(context).pop(); // Close loader
        CustomFailureSnackbar.show(context, 'Error downloading DutySlip: ${e.toString()}');
      }
    }
  }

  /// Download Invoice PDF and open it directly in PDF viewer
  /// Uses: http://office.aaveg.co.in/Mt/PrintAsPDF_F7?bid=$bookingId
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

      final invoiceUrl =
          'http://office.aaveg.co.in/Mt/PrintAsPDF_F7?bid=$numericBookingId';

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
      // Use app's external storage directory (works on all Android versions including 13+)
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
        if (dir != null) {
          // Create Downloads subfolder in app's external storage for better organization
          dir = Directory('${dir.path}/Download');
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
        // Ensure directory exists before saving
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        // Save the PDF file
        final fileName = 'invoice_$numericBookingId.pdf';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);

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

  /// Matches the exact download button UI used in `crp_booking.dart`
  Widget _buildDownloadPillButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 24,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDCEAFD), // bg color
          elevation: 0,
          padding: const EdgeInsets.all(5), // padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // border-radius
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/bookmark.png',
              width: 12,
              height: 12,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: Color(0xFF7B7B7B),
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// Build status badge with pill design and different colors/icons for each status
  Widget _buildStatusBadge(String? status) {
    // Use effective status (handles Dispatched + currentDispatchStatusId == 6 -> Completed)
    final effectiveStatus = _getEffectiveStatusFrom(
      status: status,
      currentDispatchStatusId: _currentBooking.currentDispatchStatusId,
    );
    // Normalize status to handle case variations
    final normalizedStatus = effectiveStatus.trim().toLowerCase();

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
    } else if (normalizedStatus == 'allocated' || normalizedStatus == '6') {
      backgroundColor = const Color(0xFFE3F2FD); // Light blue
      textColor = const Color(0xFF2196F3); // Dark blue
      iconColor = const Color(0xFF2196F3);
      icon = Icons.check_circle;
      statusText = 'Allocated';
    } else if (normalizedStatus == 'completed') {
      backgroundColor = const Color(0xFFE3F2FD); // Light blue
      textColor = const Color(0xFF2196F3); // Dark blue
      iconColor = const Color(0xFF2196F3);
      icon = Icons.check_circle;
      statusText = 'Completed';
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

    final bookingStatus = (_currentBooking.status ?? '').toLowerCase().trim();
    final shouldShowSos =
        bookingStatus == 'dispatched' || bookingStatus == '2';

    return PopScope(
      canPop: true,
      child: Scaffold(
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF000000),
            ),
            onPressed: () async {
              await _refreshBookingDetails();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (shouldShowSos) {
            _ensureInitialSosOffset(constraints);
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refreshBookingDetails,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Booking Card
                      Obx(() {
                        if (crpBookingDetailsController.isLoading.value) {
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
                              _currentBooking.run ?? 'Airport Drop',
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
                              _currentBooking.model?.replaceAll(RegExp(r'\s*\[.*?\]'), '') ?? '',
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
                      _buildStatusBadge(_currentBooking.status),
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
                                  _currentBooking.passenger ?? 
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
                  const SizedBox(height: 4),
                  // OTP Display Section
                  Obx(() {
                    final bookingDetails = crpBookingDetailsController.crpBookingDetailResponse.value;
                    final effectiveStatus = _getEffectiveStatus().toLowerCase().trim();

                    // Do not show OTP section once booking is completed
                    if (effectiveStatus == 'completed') {
                      return const SizedBox.shrink();
                    }

                    // Get OTP values, handling null cases
                    final pickupOtpRaw = bookingDetails?.pickupOtp;
                    final dropOtpRaw = bookingDetails?.dropOtp;

                    // Convert to string and handle null/empty cases
                    final pickupOtpStr = pickupOtpRaw?.toString().trim() ?? "0";
                    final dropOtpStr = dropOtpRaw?.toString().trim() ?? "0";

                    // Debug: Print OTP values
                    print('🔍 OTP Debug - PickupOtp: "$pickupOtpStr", DropOtp: "$dropOtpStr"');
                    print('🔍 OTP Raw - PickupOtpRaw: $pickupOtpRaw, DropOtpRaw: $dropOtpRaw');

                    // Parse OTPs to check if they're greater than 0
                    // Handle both string "0" and numeric 0 cases
                    final pickupOtpInt = int.tryParse(pickupOtpStr) ?? 0;
                    final dropOtpInt = int.tryParse(dropOtpStr) ?? 0;

                    print('🔍 OTP Parsed - PickupOtpInt: $pickupOtpInt, DropOtpInt: $dropOtpInt');
                    print('🔍 OTP Condition - Both > 0: ${pickupOtpInt > 0 && dropOtpInt > 0}');

                    // Only show if at least one OTP is greater than 0
                    if (pickupOtpInt > 0 || dropOtpInt > 0) {
                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Start OTP Section
                                  pickupOtpInt > 0 ?  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Start OTP',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF7B7B7B), // Light gray
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                        Text(
                                          pickupOtpInt > 0 ? pickupOtpStr : '---',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: pickupOtpInt > 0
                                                ? const Color(0xFF7CC521) // Vibrant lime green
                                                : Colors.grey.shade600,
                                            fontFamily: 'Montserrat',
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ) : SizedBox.shrink(),
                                  // Horizontal Line
                                  dropOtpInt > 0 ?  Container(
                                    width: MediaQuery.of(context).size.width*0.2,
                                    height: 1,
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    color: Color(0xFFC1C1C1), // Light gray line
                                  ) : SizedBox.shrink(),
                                  // End OTP Section
                                  dropOtpInt > 0 ?   Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'End OTP',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF7B7B7B), // Light gray
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                        Text(
                                          dropOtpInt > 0 ? dropOtpStr : '---',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: dropOtpInt > 0
                                                ? const Color(0xFFFF8935) // Bright orange
                                                : Colors.grey.shade600,
                                            fontFamily: 'Montserrat',
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ) : SizedBox.shrink(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 12),

                  // Booking Status Timeline
                  _buildStatusTimeline(),

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
                    'Booking ID:- ${_currentBooking.bookingNo ?? _currentBooking.bookingId ?? '432411'}',
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
                  // Edit Booking, Track Cab, and Download buttons
                  Builder(
                    builder: (context) {
                      final bookingStatus = (_currentBooking.status ?? '').toLowerCase().trim();
                      final effectiveStatus = _getEffectiveStatus().toLowerCase().trim();
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
                              final orderId = _currentBooking.bookingId?.toString() ??
                                  _currentBooking.bookingNo ??
                                  '';
                              if (orderId.isNotEmpty) {
                                final result = await GoRouter.of(context).push<bool>(
                                  AppRoutes.cprModifyBooking,
                                  extra: {
                                    'orderId': orderId,
                                    'branchId': crpBookingDetailsController.crpBookingDetailResponse.value?.branchID.toString(),
                                    'carModelName': _currentBooking.model,
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
                      // Show Track Cab button only for dispatched status (not for completed)
                      if((bookingStatus == 'dispatched' || bookingStatus == '2') && effectiveStatus != 'completed')...[
                        Expanded(
                          child: _buildActionButton(
                            'Track Cab',
                            () {
                              // Navigate to tracking screen with booking ID and details
                              final bookingId = _currentBooking.bookingId?.toString() ??
                                  _currentBooking.bookingNo ??
                                  '';
                              if (bookingId.isNotEmpty) {
                                // Get driver details from controller
                                final driverDetails = crpBookingDetailsController.driverDetailsResponse.value;
                                final bookingDetails = crpBookingDetailsController.crpBookingDetailResponse.value;
                                
                                // Get OTP values
                                final pickupOtpRaw = bookingDetails?.pickupOtp;
                                final dropOtpRaw = bookingDetails?.dropOtp;
                                final pickupOtpStr = pickupOtpRaw?.toString().trim() ?? "0";
                                final dropOtpStr = dropOtpRaw?.toString().trim() ?? "0";
                                
                                GoRouter.of(context).push(
                                  AppRoutes.cprCabTracking,
                                  extra: {
                                    'bookingId': bookingId,
                                    'carModel': _currentBooking.model ?? '',
                                    'carNo': driverDetails?.carNo ?? '',
                                    'driverName': driverDetails?.chauffeur ?? '',
                                    'driverMobile': driverDetails?.mobile ?? '',
                                    'bookingNo': _currentBooking.bookingNo ?? _currentBooking.bookingId?.toString() ?? '',
                                    'cabRequiredOn': _currentBooking.cabRequiredOn ?? bookingDetails?.cabRequiredOn ?? '',
                                    'pickupOtp': pickupOtpStr,
                                    'dropOtp': dropOtpStr,
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ],
                      // Show Download DutySlip + Download Invoice + Track Cab buttons in column for completed status
                      if (effectiveStatus == 'completed') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDownloadPillButton(
                                label: 'Download DutySlip',
                                onPressed: () => _downloadDutySlip(_currentBooking),
                              ),
                              const SizedBox(height: 8),
                              _buildDownloadPillButton(
                                label: 'Download Invoice',
                                onPressed: () => _downloadInvoice(_currentBooking),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: _buildActionButton(
                                  'Track Cab',
                                  () {
                                    // Navigate to tracking screen with booking ID and details
                                    final bookingId = _currentBooking.bookingId?.toString() ??
                                        _currentBooking.bookingNo ??
                                        '';
                                    if (bookingId.isNotEmpty) {
                                      // Get driver details from controller
                                      final driverDetails = crpBookingDetailsController.driverDetailsResponse.value;
                                      final bookingDetails = crpBookingDetailsController.crpBookingDetailResponse.value;
                                      
                                      // Get OTP values
                                      final pickupOtpRaw = bookingDetails?.pickupOtp;
                                      final dropOtpRaw = bookingDetails?.dropOtp;
                                      final pickupOtpStr = pickupOtpRaw?.toString().trim() ?? "0";
                                      final dropOtpStr = dropOtpRaw?.toString().trim() ?? "0";
                                      
                                      GoRouter.of(context).push(
                                        AppRoutes.cprCabTracking,
                                        extra: {
                                          'bookingId': bookingId,
                                          'carModel': _currentBooking.model ?? '',
                                          'carNo': driverDetails?.carNo ?? '',
                                          'driverName': driverDetails?.chauffeur ?? '',
                                          'driverMobile': driverDetails?.mobile ?? '',
                                          'bookingNo': _currentBooking.bookingNo ?? _currentBooking.bookingId?.toString() ?? '',
                                          'cabRequiredOn': _currentBooking.cabRequiredOn ?? bookingDetails?.cabRequiredOn ?? '',
                                          'pickupOtp': pickupOtpStr,
                                          'dropOtp': dropOtpStr,
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
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
                        final driverDetails = crpBookingDetailsController
                            .driverDetailsResponse.value;
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
                        _currentBooking.model ?? 'N/A',
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
              ),

              // Draggable SOS button (only when dispatched / "2")
              if (shouldShowSos && _sosOffset != null)
                Positioned(
                  left: _sosOffset!.dx,
                  top: _sosOffset!.dy,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      final next =
                          (_sosOffset ?? Offset.zero) + details.delta;
                      setState(() {
                        _sosOffset = _clampSosOffset(next, constraints);
                      });
                    },
                    child: _buildSosButton(),
                  ),
                ),
            ],
          );
        },
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

  /// Build horizontal status timeline
  Widget _buildStatusTimeline() {
    final effectiveStatus = _getEffectiveStatus().toLowerCase().trim();
    final status = (_currentBooking.status ?? 'Pending').toLowerCase().trim();
    
    // Determine which stages are completed based on status
    // Pending is always completed
    final isPendingCompleted = true;
    
    // Confirmed is completed if status is Confirmed or beyond
    final isConfirmedCompleted = status == 'confirmed' || status == '1' || 
                                 status == 'dispatched' || status == '2' ||
                                 status == 'allocated' || status == '6' ||
                                 effectiveStatus == 'completed' ||
                                 status == 'missed' || status == '3' ||
                                 status == 'cancelled' || status == 'canceled' || status == '4';
    
    // On Going is completed if status is Dispatched or beyond (but not Cancelled)
    final isCancelled = status == 'cancelled' || status == 'canceled' || status == '4';
    final isOnGoingCompleted = !isCancelled && (status == 'dispatched' || status == '2' ||
                                                status == 'allocated' || status == '6' ||
                                                effectiveStatus == 'completed' ||
                                                status == 'missed' || status == '3');
    
    // Determine final stage type
    final isMissed = status == 'missed' || status == '3';
    final isAllocated = status == 'allocated' || status == '6';
    final isCompleted = effectiveStatus == 'completed';
    
    // Always show all 4 stages
    final stages = <_TimelineStage>[];
    
    // Stage 1: Pending (always completed/blue)
    stages.add(_TimelineStage(
      label: 'Pending',
      icon: Icons.access_time,
      isCompleted: isPendingCompleted,
    ));
    
    // Stage 2: Confirmed
    stages.add(_TimelineStage(
      label: 'Confirmed',
      icon: Icons.directions_car,
      isCompleted: isConfirmedCompleted,
    ));
    
    // Stage 3: On Going
    // For cancelled status, we SKIP \"On Going\" so the flow is:
    // Pending → Confirmed → Cancelled
    if (!isCancelled) {
      stages.add(_TimelineStage(
        label: 'On Going',
        icon: Icons.directions_car,
        isCompleted: isOnGoingCompleted,
      ));
    }
    
    // Stage 3 or 4: Final stage (Completed, Allocated, Cancelled, or Missed)
    if (isCancelled) {
      stages.add(_TimelineStage(
        label: 'Cancelled',
        icon: Icons.cancel,
        isError: true,
      ));
    } else if (isMissed) {
      stages.add(_TimelineStage(
        label: 'Missed',
        icon: Icons.error_outline,
        isError: true,
      ));
    } else if (isAllocated) {
      stages.add(_TimelineStage(
        label: 'Allocated',
        icon: Icons.check_circle,
        isCompleted: true,
      ));
    } else {
      // Default to Completed
      stages.add(_TimelineStage(
        label: 'Completed',
        icon: Icons.check_circle,
        isCompleted: isCompleted,
      ));
    }

    return Container(
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(12),
      //   border: Border.all(
      //     color: Colors.grey.shade300,
      //     width: 1,
      //   ),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.grey.shade200,
      //       blurRadius: 4,
      //       offset: const Offset(0, 2),
      //     ),
      //   ],
      // ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (index) {
            final stage = stages[index];
            final isLast = index == stages.length - 1;
            
            return Expanded(
              child: Row(
                children: [
                  // Stage Circle
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: stage.isError
                              ? const Color(0xFFE91E63)
                              : (stage.isCompleted || stage.isActive
                                  ? const Color(0xFF4082F1)
                                  : const Color(0xFFE0E0E0)),
                          shape: BoxShape.circle,
                        ),
                        child: stage.label == 'Confirmed'
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ],
                              )
                            : Icon(
                                stage.icon,
                                color: Colors.white,
                                size: 16,
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stage.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: stage.isError
                              ? const Color(0xFFE91E63)
                              : (stage.isCompleted || stage.isActive
                                  ? const Color(0xFF4082F1)
                                  : const Color(0xFF939393)),
                          fontFamily: 'Montserrat',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  // Connecting Line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: stage.isCompleted && !stage.isError
                                ? [
                                    const Color(0xFF4082F1),
                                    stages[index + 1].isCompleted || stages[index + 1].isActive
                                        ? const Color(0xFF4082F1)
                                        : const Color(0xFFE0E0E0),
                                  ]
                                : [
                                    const Color(0xFFE0E0E0),
                                    const Color(0xFFE0E0E0),
                                  ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Timeline stage model
class _TimelineStage {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;
  final bool isError;

  _TimelineStage({
    required this.label,
    required this.icon,
    this.isActive = false,
    this.isCompleted = false,
    this.isError = false,
  });
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

