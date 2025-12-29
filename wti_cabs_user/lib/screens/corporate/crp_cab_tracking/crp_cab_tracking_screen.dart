import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_cab_tracking/crp_cab_tracking_controller.dart';

import '../../../core/model/corporate/crp_cab_tracking/crp_cab_tracking_response.dart';

class CrpCabTrackingScreen extends StatefulWidget {
  final String bookingId;

  const CrpCabTrackingScreen({
    super.key,
    required this.bookingId,
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
      final ByteData data = await rootBundle.load('assets/images/liveCarWhite.png');
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
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  @override
  void dispose() {
    _controller.stopPolling();
    _mapController?.dispose();
    super.dispose();
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
          icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
    if (!_routeFetched && pickupLat != null && pickupLng != null && dropLat != null && dropLng != null) {
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
          'Live Tracking',
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
        // Show loader until first successful response
        if (_controller.isLoading.value && _controller.trackingResponse.value == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF002CC0),
            ),
          );
        }

        final response = _controller.trackingResponse.value;

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

        // Show completion message if ride is completed
        if (response?.isRideCompleted == true) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ride has been completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF192653),
                    fontFamily: 'Montserrat',
                  ),
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
        }

        // Show tracking map
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
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#e9e9e9"
            },
            {
                "lightness": 17
            }
        ]
    },
    {
        "featureType": "landscape",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#f5f5f5"
            },
            {
                "lightness": 20
            }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "geometry.fill",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "lightness": 17
            }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "geometry.stroke",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "lightness": 29
            },
            {
                "weight": 0.2
            }
        ]
    },
    {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "lightness": 18
            }
        ]
    },
    {
        "featureType": "road.local",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#ffffff"
            },
            {
                "lightness": 16
            }
        ]
    },
    {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#f5f5f5"
            },
            {
                "lightness": 21
            }
        ]
    },
    {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#dedede"
            },
            {
                "lightness": 21
            }
        ]
    },
    {
        "elementType": "labels.text.stroke",
        "stylers": [
            {
                "visibility": "on"
            },
            {
                "color": "#ffffff"
            },
            {
                "lightness": 16
            }
        ]
    },
    {
        "elementType": "labels.text.fill",
        "stylers": [
            {
                "saturation": 36
            },
            {
                "color": "#333333"
            },
            {
                "lightness": 40
            }
        ]
    },
    {
        "elementType": "labels.icon",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "transit",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#f2f2f2"
            },
            {
                "lightness": 19
            }
        ]
    },
    {
        "featureType": "administrative",
        "elementType": "geometry.fill",
        "stylers": [
            {
                "color": "#fefefe"
            },
            {
                "lightness": 20
            }
        ]
    },
    {
        "featureType": "administrative",
        "elementType": "geometry.stroke",
        "stylers": [
            {
                "color": "#fefefe"
            },
            {
                "lightness": 17
            },
            {
                "weight": 1.2
            }
        ]
    }
]''',
            ),

            // Status banner at top
            if (response?.isRideActive == true)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF002CC0),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Driver is on the way',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                      if (_controller.isPolling.value)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Loading overlay (subtle)
            if (_controller.isLoading.value && _controller.trackingResponse.value != null)
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
          ],
        );
      }),
    );
  }
}

