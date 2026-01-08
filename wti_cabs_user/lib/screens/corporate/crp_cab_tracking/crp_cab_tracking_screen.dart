import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_cab_tracking/crp_cab_tracking_controller.dart';

import '../../../common_widget/snackbar/custom_snackbar.dart';
import '../../../core/model/corporate/crp_cab_tracking/crp_cab_tracking_response.dart';

class CrpCabTrackingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, String>? bookingDetails;
  final bool? bStatus;
  final String? bookingStatus;
  final String? pickupOtp;
  final String? dropOtp;

  const CrpCabTrackingScreen({
    super.key,
    required this.bookingId,
    this.bookingDetails,
    this.bStatus,
    this.bookingStatus,
    this.pickupOtp,
    this.dropOtp,
  });

  @override
  State<CrpCabTrackingScreen> createState() => _CrpCabTrackingScreenState();
}

class _CrpCabTrackingScreenState extends State<CrpCabTrackingScreen> {
  late final CrpCabTrackingController _controller;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _lastCabPosition;
  BitmapDescriptor? _carIcon;
  bool _routeFetched = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(CrpCabTrackingController());
    _createCarIcon();

    // Start tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.startTracking(widget.bookingId);
      }
    });

    // Listen to tracking updates
    ever(_controller.trackingResponse, (response) {
      if (response != null && mounted) {
        _updateMapMarkers(response);
      }
    });

    // Listen to route updates
    ever(_controller.routePoints, (points) {
      if (mounted && points.isNotEmpty) {
        _updatePolyline(points);
      }
    });
  }

  /// Create custom car icon from asset
  Future<void> _createCarIcon() async {
    try {
      final ByteData data =
          await rootBundle.load('assets/images/liveCarWhite.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 180, // Resize to appropriate size for marker
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        _carIcon = BitmapDescriptor.fromBytes(pngBytes);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error creating car icon: $e');
      // Fallback to default marker
      _carIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  @override
  void dispose() {
    _controller.stopPolling();
    _mapController?.dispose();
    super.dispose();
  }

  /// Build bottom details card with car, booking, and chauffeur info
  Widget _buildBottomDetailsCard({String? message}) {
    final details = widget.bookingDetails!;
    final carModel = details['carModel'] ?? '';
    final carNo = details['carNo'] ?? '';
    final driverName = details['driverName'] ?? '';
    final driverMobile = details['driverMobile'] ?? '';
    final bookingNo = details['bookingNo'] ?? '';
    final cabRequiredOn = details['cabRequiredOn'] ?? '';

    // Format booking date
    String formattedDate = '';
    if (cabRequiredOn.isNotEmpty) {
      try {
        final date = DateTime.parse(cabRequiredOn);
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      } catch (e) {
        formattedDate = cabRequiredOn;
      }
    }

    // If message is provided, show message card instead of normal details
    if (message != null && message.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(23),
            topRight: Radius.circular(23),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF192653),
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(23),
          topRight: Radius.circular(23),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car Details and Arrival Time Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car Image and Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car Image
                      Container(
                        width: 90,
                        height: 60,
                        decoration: BoxDecoration(
                          // color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/booking_crp_car.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.directions_car,
                              size: 40,
                              color: Color(0xFF002CC0),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 25),
                      // License Plate - dark gray, bold
                      Text(
                        carNo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF192653),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Car Model - lighter gray
                      Text(
                        carModel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF939393),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Arrival Time Badge - positioned at top right
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Arriving in',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFA5A5A5),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Obx(() {
                              // Calculate arrival time from tracking response
                              final response = _controller.trackingResponse.value;
                              String arrivalText = '15 Mins';
                              
                              // Calculate estimated time based on distance if we have coordinates
                              if (response != null) {
                                final cabLat = response.cabLatitude;
                                final cabLng = response.cabLongitude;
                                final pickupLat = response.pickupLatitude;
                                final pickupLng = response.pickupLongitude;
                                
                                if (cabLat != null && cabLng != null && 
                                    pickupLat != null && pickupLng != null) {
                                  // Calculate distance in km
                                  final distance = _calculateDistance(
                                    cabLat, cabLng, 
                                    pickupLat, pickupLng
                                  );
                                  
                                  // Estimate time: assume average speed of 30 km/h
                                  // Time in minutes = (distance / 30) * 60
                                  final estimatedMinutes = (distance / 30 * 60).round();
                                  if (estimatedMinutes > 0 && estimatedMinutes < 120) {
                                    arrivalText = '$estimatedMinutes Mins';
                                  }
                                }
                              }
                              
                              return Text(
                                arrivalText,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F4F4F), // Dark gray instead of blue
                                  fontFamily: 'Montserrat',
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      // Booking Information - below arrival time badge, on the right
                      if (bookingNo.isNotEmpty || formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (bookingNo.isNotEmpty)
                              Text(
                                'Booking ID $bookingNo',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF939393),
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            if (formattedDate.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Booked on $formattedDate',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF939393),
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // OTP Display Section
              Obx(() {
                // Get current status from tracking response or use passed parameters
                final response = _controller.trackingResponse.value;
                final currentBStatus = response?.bStatus ?? widget.bStatus ?? false;
                final currentBookingStatus = (response?.bookingStatus ?? widget.bookingStatus ?? '').toLowerCase().trim();
                
                // Get OTP values
                final pickupOtpRaw = widget.pickupOtp ?? '0';
                final dropOtpRaw = widget.dropOtp ?? '0';
                final pickupOtpStr = pickupOtpRaw.trim();
                final dropOtpStr = dropOtpRaw.trim();
                
                // Parse OTPs to check if they're greater than 0
                final pickupOtpInt = int.tryParse(pickupOtpStr) ?? 0;
                final dropOtpInt = int.tryParse(dropOtpStr) ?? 0;
                
                // Show Start OTP if status is Start or Pick
                final showStartOtp = currentBStatus && 
                    (currentBookingStatus == 'start' || currentBookingStatus == 'pick') && 
                    pickupOtpInt > 0;
                
                // Show Drop OTP if status is Drop
                final showDropOtp = currentBStatus && 
                    currentBookingStatus == 'drop' && 
                    dropOtpInt > 0;
                
                if (showStartOtp || showDropOtp) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Start OTP Section
                              showStartOtp ? Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Start OTP',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF7B7B7B),
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    Text(
                                      pickupOtpStr,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF7CC521),
                                        fontFamily: 'Montserrat',
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ) : const SizedBox.shrink(),
                              // Horizontal Line
                              if (showStartOtp && showDropOtp)
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.2,
                                  height: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  color: const Color(0xFFC1C1C1),
                                ),
                              // Drop OTP Section
                              showDropOtp ? Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'End OTP',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF7B7B7B),
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    Text(
                                      dropOtpStr,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFF8935),
                                        fontFamily: 'Montserrat',
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ) : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              // Chauffeur Details Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Profile Picture Placeholder - circular light gray
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Driver Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chauffer Name',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF939393),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          Text(
                            driverName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4082F1),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Phone Icon - circular white button with light blue icon
                    if (driverMobile.isNotEmpty)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _launchPhoneCall(driverMobile);
                          },
                          icon: const Icon(
                            Icons.phone_rounded,
                            color: Color(0xFF64A4F6),
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Update map markers based on tracking response
  void _updateMapMarkers(CrpCabTrackingResponse response) {
    if (!mounted) return;

    _markers.clear();

    // Pickup marker (static)
    final pickupLat = response.pickupLatitude;
    final pickupLng = response.pickupLongitude;
    if (pickupLat != null && pickupLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupLat, pickupLng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Pickup Location',
            snippet: 'Your pickup point',
          ),
        ),
      );
    }

    // Drop marker (static)
    final dropLat = response.dropLatitude;
    final dropLng = response.dropLongitude;
    if (dropLat != null && dropLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(dropLat, dropLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Drop Location',
            snippet: 'Your destination',
          ),
        ),
      );
    }

    // Cab marker (dynamic) - use car icon if available
    final cabLat = response.cabLatitude;
    final cabLng = response.cabLongitude;
    if (cabLat != null && cabLng != null) {
      final cabPosition = LatLng(cabLat, cabLng);
      _lastCabPosition = cabPosition;

      _markers.add(
        Marker(
          markerId: const MarkerId('cab'),
          position: cabPosition,
          icon: _carIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Driver Location',
            snippet: 'Your driver is here',
          ),
          anchor: const Offset(0.5, 0.5), // Center the icon
        ),
      );

      // Animate camera to cab position smoothly
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(cabPosition),
      );
    }

    // Fetch route from Google Directions API if we have both pickup and drop (only once)
    if (!_routeFetched &&
        pickupLat != null &&
        pickupLng != null &&
        dropLat != null &&
        dropLng != null) {
      _routeFetched = true;
      _controller.fetchRoute(pickupLat, pickupLng, dropLat, dropLng);
    }

    setState(() {});
  }

  /// Update polyline with route points from Directions API
  void _updatePolyline(List<LatLng> points) {
    if (!mounted || points.isEmpty) return;

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: const Color(0xFF213B87),
        width: 4,
        patterns: [],
        geodesic: true,
      ),
    );

    setState(() {});
  }

  /// Get initial camera position
  CameraPosition _getInitialCameraPosition() {
    // Default to a central location (can be improved with actual coordinates)
    return const CameraPosition(
      target: LatLng(28.5621, 77.0675), // Default location
      zoom: 13,
    );
  }

  /// Calculate distance between two coordinates in kilometers (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Launch phone call using url_launcher
  Future<void> _launchPhoneCall(String phoneNumber) async {
    try {
      // Remove any spaces, dashes, or other formatting
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri uri = Uri(scheme: 'tel', path: cleanedNumber);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          CustomFailureSnackbar.show(context, 'Unable to make phone call');
        }
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
      if (mounted) {
        CustomFailureSnackbar.show(context, 'Error: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Track Chauffeur',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        // Get current status from tracking response or use passed parameters
        final response = _controller.trackingResponse.value;
        final currentBStatus = response?.bStatus ?? widget.bStatus ?? false;
        final currentBookingStatus = (response?.bookingStatus ?? widget.bookingStatus ?? '').toLowerCase().trim();

        // Show loader until first successful response
        if (_controller.isLoading.value &&
            _controller.trackingResponse.value == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF002CC0),
            ),
          );
        }

        // Show error if no response and not loading
        if (response == null && !_controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _controller.errorMessage.value.isNotEmpty
                      ? _controller.errorMessage.value
                      : 'Unable to fetch tracking data',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _controller.fetchTrackingData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002CC0),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Case 1: bStatus is true and BookingStatus is "Pending" -> show message
        if (currentBStatus && currentBookingStatus == 'pending') {
          return Stack(
            children: [
              // Show map in background (optional, or show empty)
              GoogleMap(
                initialCameraPosition: _getInitialCameraPosition(),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                compassEnabled: true,
              ),
              // Bottom message card
              if (widget.bookingDetails != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomDetailsCard(message: 'Booking is not starting yet.'),
                ),
            ],
          );
        }

        // Case 2: bStatus is true and BookingStatus is "Close" -> show message
        if (currentBStatus && currentBookingStatus == 'close') {
          return Stack(
            children: [
              // Show map in background (optional, or show empty)
              GoogleMap(
                initialCameraPosition: _getInitialCameraPosition(),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                compassEnabled: true,
              ),
              // Bottom message card
              if (widget.bookingDetails != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomDetailsCard(message: 'Booking has been completed'),
                ),
            ],
          );
        }

        // Case 3 & 4: bStatus is true and BookingStatus is "Start", "Pick", or "Drop" -> show tracking map
        if (currentBStatus && 
            (currentBookingStatus == 'start' || 
             currentBookingStatus == 'pick' || 
             currentBookingStatus == 'drop')) {
          // Show tracking map with bottom UI (OTP will be shown in bottom card)
          return _buildTrackingMap(response);
        }

        // Default: Show completion message if ride is not active
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/no_tracking.png', width: 248, height: 223,),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Live Cab tracking is currently \n unavailable for this booking',
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF192653),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                response?.sMessage ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Build tracking map widget
  Widget _buildTrackingMap(CrpCabTrackingResponse? response) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: _getInitialCameraPosition(),
          onMapCreated: (controller) {
            _mapController = controller;
            // Update markers after map is created
            if (response != null) {
              _updateMapMarkers(response);
            }
          },
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          zoomControlsEnabled: true,
          compassEnabled: true,
          style: '''[
    {
        "elementType": "labels.text",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "landscape.natural",
        "elementType": "geometry.fill",
        "stylers": [
            {
                "color": "#f5f5f2"
            },
            {
                "visibility": "on"
            }
        ]
    },
    {
        "featureType": "administrative",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "transit",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "poi.attraction",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "landscape.man_made",
        "elementType": "geometry.fill",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "visibility": "on"
            }
        ]
    },
    {
        "featureType": "poi.business",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "poi.medical",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "poi.place_of_worship",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "poi.school",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "poi.sports_complex",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "visibility": "simplified"
            }
        ]
    },
    {
        "featureType": "road.arterial",
        "stylers": [
            {
                "visibility": "simplified"
            },
            {
                "color": "#ffffff"
            }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "labels.icon",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "labels.icon",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "road.arterial",
        "stylers": [
            {
                "color": "#ffffff"
            }
        ]
    },
    {
        "featureType": "road.local",
        "stylers": [
            {
                "color": "#ffffff"
            }
        ]
    },
    {
        "featureType": "poi.park",
        "elementType": "labels.icon",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "poi",
        "elementType": "labels.icon",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "water",
        "stylers": [
            {
                "color": "#71c8d4"
            }
        ]
    },
    {
        "featureType": "landscape",
        "stylers": [
            {
                "color": "#e5e8e7"
            }
        ]
    },
    {
        "featureType": "poi.park",
        "stylers": [
            {
                "color": "#8ba129"
            }
        ]
    },
    {
        "featureType": "road",
        "stylers": [
            {
                "color": "#ffffff"
            }
        ]
    },
    {
        "featureType": "poi.sports_complex",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#c7c7c7"
            },
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "water",
        "stylers": [
            {
                "color": "#a0d3d3"
            }
        ]
    },
    {
        "featureType": "poi.park",
        "stylers": [
            {
                "color": "#91b65d"
            }
        ]
    },
    {
        "featureType": "poi.park",
        "stylers": [
            {
                "gamma": 1.51
            }
        ]
    },
    {
        "featureType": "road.local",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "road.local",
        "elementType": "geometry",
        "stylers": [
            {
                "visibility": "on"
            }
        ]
    },
    {
        "featureType": "poi.government",
        "elementType": "geometry",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "landscape",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "road",
        "elementType": "labels",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
            {
                "visibility": "simplified"
            }
        ]
    },
    {
        "featureType": "road.local",
        "stylers": [
            {
                "visibility": "simplified"
            }
        ]
    },
    {
        "featureType": "road"
    },
    {
        "featureType": "road"
    },
    {},
    {
        "featureType": "road.highway"
    }
]''',
            ),

            // Status banner at top
            // if (response?.isRideActive == true)
            //   Positioned(
            //     top: 16,
            //     left: 16,
            //     right: 16,
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 16,
            //         vertical: 12,
            //       ),
            //       decoration: BoxDecoration(
            //         color: const Color(0xFF002CC0),
            //         borderRadius: BorderRadius.circular(8),
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.black.withOpacity(0.1),
            //             blurRadius: 4,
            //             offset: const Offset(0, 2),
            //           ),
            //         ],
            //       ),
            //       child: Row(
            //         children: [
            //           const Icon(
            //             Icons.directions_car,
            //             color: Colors.white,
            //             size: 24,
            //           ),
            //           const SizedBox(width: 12),
            //           const Expanded(
            //             child: Text(
            //               'Driver is on the way',
            //               style: TextStyle(
            //                 fontSize: 16,
            //                 fontWeight: FontWeight.w600,
            //                 color: Colors.white,
            //                 fontFamily: 'Montserrat',
            //               ),
            //             ),
            //           ),
            //           if (_controller.isPolling.value)
            //             const SizedBox(
            //               width: 16,
            //               height: 16,
            //               child: CircularProgressIndicator(
            //                 strokeWidth: 2,
            //                 valueColor:
            //                     AlwaysStoppedAnimation<Color>(Colors.white),
            //               ),
            //             ),
            //         ],
            //       ),
            //     ),
            //   ),

            // Loading overlay (subtle)
            if (_controller.isLoading.value &&
                _controller.trackingResponse.value != null)
              Positioned(
                top: 80,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF002CC0),
                    ),
                  ),
                ),
              ),

            // Bottom section with booking and chauffeur details
            if (widget.bookingDetails != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomDetailsCard(),
              ),
          ],
        );
  }
}
