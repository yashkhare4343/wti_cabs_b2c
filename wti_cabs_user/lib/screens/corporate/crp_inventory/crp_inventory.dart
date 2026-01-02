import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:wti_cabs_user/core/api/corporate/cpr_api_services.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_inventory_list_controller/crp_inventory_list_controller.dart';

import '../../../common_widget/loader/shimmer/corporate_shimmer.dart';
import '../../../core/model/corporate/crp_car_models/crp_car_models_response.dart';
import '../../../core/model/corporate/crp_booking_data/crp_booking_data.dart';
import '../../../core/services/storage_services.dart';

class CrpInventory extends StatefulWidget {
  final Map<String, dynamic>? bookingData;

  const CrpInventory({super.key, this.bookingData});

  @override
  State<CrpInventory> createState() => _CrpInventoryState();
}

class _CrpInventoryState extends State<CrpInventory> {
  final controller = Get.put(CrpInventoryListController());
  bool _isInitialLoad = true;

  String? guestId, token, user, corpId, branchId;

  @override
  void initState() {
    super.initState();
    // Start fetching data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        fetchCardModel(); // TODO: Initialize inventory data
      }
    });
  }

  Future<void> fetchParameter() async {
    guestId = await StorageServices.instance.read('branchId');
    token = await StorageServices.instance.read('crpKey');
    user = await StorageServices.instance.read('email');
    corpId = await StorageServices.instance.read('crpId');
    branchId = await StorageServices.instance.read('branchId');
  }

  void fetchCardModel() async {
    await fetchParameter();
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    // Get runTypeId from booking data if available, otherwise default to 1
    int runTypeId = 1;
    if (widget.bookingData != null) {
      try {
        final parsedBookingData = CrpBookingData.fromJson(widget.bookingData!);
        if (parsedBookingData.runTypeId != null &&
            parsedBookingData.runTypeId! > 0) {
          runTypeId = parsedBookingData.runTypeId!;
        }
      } catch (e) {
        print('Error parsing booking data for runTypeId: $e');
      }
    }

    final Map<String, dynamic> params = {
      'token': token,
      'user': user ?? email,
      'CorpID': corpId,
      'BranchID': branchId,
      'RunTypeID': runTypeId
    };

    // Mark initial load as complete - fetchCarModels will set isLoading = true
    if (_isInitialLoad && mounted) {
      setState(() {
        _isInitialLoad = false;
      });
    }

    await controller.fetchCarModels(params, context);
  }

  @override
  Widget build(BuildContext context) {
    // Parse booking data if provided
    CrpBookingData? parsedBookingData;
    if (widget.bookingData != null) {
      try {
        parsedBookingData = CrpBookingData.fromJson(widget.bookingData!);
      } catch (e) {
        print('Error parsing booking data: $e');
      }
    }

    return Obx(() {
      // Show full-screen circular progress indicator while loading or during initial load
      final bool showLoader = controller.isLoading.value || _isInitialLoad;

      if (showLoader) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) {
              context.push(AppRoutes.cprBookingEngine);
            }
          },
          child: const CorporateShimmer(),
        );
      }

      // Show actual content when loading is complete
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) {
            context.push(AppRoutes.cprBookingEngine);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBgPrimary1,
          body: SafeArea(
            child: _BookingBody(bookingData: parsedBookingData),
          ),
        ),
      );
    });
  }
}

class _BookingBody extends StatefulWidget {
  final CrpBookingData? bookingData;

  const _BookingBody({super.key, this.bookingData});

  @override
  State<_BookingBody> createState() => _BookingBodyState();
}

class _BookingBodyState extends State<_BookingBody> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;

  // Google API Key (same as used in controllers)
  final String googleApiKey = "AIzaSyCWbmCiquOta1iF6um7_5_NFh6YM5wPL30";

  final CrpInventoryListController _inventoryController =
  Get.put(CrpInventoryListController());

  /// Creates pickup pin icon from asset image
  Future<BitmapDescriptor> _createPickupPinIcon() async {
    return BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(90, 90)),
      'assets/images/pickup.png',
    );
  }

  /// Creates drop pin icon from asset image
  Future<BitmapDescriptor> _createDropPinIcon() async {
    return BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(90, 90)),
      'assets/images/drop.png',
    );
  }

  /// Checks if drop location exists and has valid data
  bool _hasDropLocation() {
    if (widget.bookingData == null) {
      return false;
    }
    final dropPlace = widget.bookingData!.dropPlace;
    if (dropPlace == null) {
      return false;
    }
    final primaryText = dropPlace.primaryText;
    return primaryText != null && primaryText.isNotEmpty;
  }

  CameraPosition get _initialCameraPosition {
    // If we have booking data with coordinates, center between pickup and drop
    if (widget.bookingData != null) {
      final pickupLat = widget.bookingData!.pickupPlace?.latitude;
      final pickupLng = widget.bookingData!.pickupPlace?.longitude;
      final dropLat = widget.bookingData!.dropPlace?.latitude;
      final dropLng = widget.bookingData!.dropPlace?.longitude;

      if (pickupLat != null &&
          pickupLng != null &&
          dropLat != null &&
          dropLng != null) {
        // Calculate center point
        final centerLat = (pickupLat + dropLat) / 2;
        final centerLng = (pickupLng + dropLng) / 2;

        // Calculate zoom level based on distance
        final distance =
            _calculateDistance(pickupLat, pickupLng, dropLat, dropLng);
        double zoom = 6.0;
        if (distance > 100) {
          zoom = 6.0;
        } else if (distance > 50) {
          zoom = 6.0;
        } else if (distance > 20) {
          zoom = 6.0;
        }

        return CameraPosition(
          target: LatLng(centerLat, centerLng),
          zoom: zoom,
        );
      }
    }

    // Default position
    return const CameraPosition(
      target: LatLng(28.5562, 77.1000), // IGI example
      zoom: 8,
    );
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  /// Generates curved points between two LatLng coordinates using quadratic bezier curve
  List<LatLng> _generateCurvedPoints(LatLng start, LatLng end) {
    // Calculate midpoint
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;

    // Calculate distance to determine curve height
    final distance = _calculateDistance(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    // Create a control point offset perpendicular to the line
    // This creates an arc above the straight line
    final bearing = _calculateBearing(
        start.latitude, start.longitude, end.latitude, end.longitude);
    final perpendicularBearing = bearing + 90; // 90 degrees perpendicular

    // Calculate offset distance (curve height) - adjust based on total distance
    final offsetDistance = distance * 0.1; // 10% of distance as curve height

    // Calculate control point using bearing and offset
    final controlPoint = _destinationPoint(
      midLat,
      midLng,
      perpendicularBearing,
      offsetDistance,
    );

    // Generate points along the quadratic bezier curve
    final points = <LatLng>[];
    const numPoints = 50; // Number of points for smooth curve

    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      final point = _quadraticBezier(start, controlPoint, end, t);
      points.add(point);
    }

    return points;
  }

  /// Calculate bearing between two points
  double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = _toRadians(lng2 - lng1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final y = math.sin(dLng) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLng);

    final bearing = math.atan2(y, x);
    return _toDegrees(bearing);
  }

  double _toDegrees(double radians) => radians * (180.0 / math.pi);

  /// Calculate destination point given start point, bearing, and distance
  LatLng _destinationPoint(
      double lat, double lng, double bearing, double distance) {
    const earthRadius = 6371.0; // km
    final latRad = _toRadians(lat);
    final lngRad = _toRadians(lng);
    final bearingRad = _toRadians(bearing);
    final angularDistance = distance / earthRadius;

    final newLat = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
          math.cos(latRad) * math.sin(angularDistance) * math.cos(bearingRad),
    );

    final newLng = lngRad +
        math.atan2(
          math.sin(bearingRad) * math.sin(angularDistance) * math.cos(latRad),
          math.cos(angularDistance) - math.sin(latRad) * math.sin(newLat),
        );

    return LatLng(_toDegrees(newLat), _toDegrees(newLng));
  }

  /// Quadratic bezier curve calculation
  LatLng _quadraticBezier(LatLng p0, LatLng p1, LatLng p2, double t) {
    final oneMinusT = 1 - t;
    final lat = oneMinusT * oneMinusT * p0.latitude +
        2 * oneMinusT * t * p1.latitude +
        t * t * p2.latitude;
    final lng = oneMinusT * oneMinusT * p0.longitude +
        2 * oneMinusT * t * p1.longitude +
        t * t * p2.longitude;
    return LatLng(lat, lng);
  }

  /// Fetches route from Google Directions API
  Future<List<LatLng>?> _fetchDirections(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      setState(() {
        _isLoadingRoute = true;
      });

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&key=$googleApiKey',
      );

      final response =
          await CprApiService().sendRequestWithRetry(() => http.get(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final overviewPolyline = route['overview_polyline'];
          final encodedPolyline = overviewPolyline['points'] as String;

          // Decode the polyline
          final decodedPoints = _decodePolyline(encodedPolyline);
          return decodedPoints;
        } else {
          print('Directions API error: ${data['status']}');
          return null;
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching directions: $e');
      return null;
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  /// Decodes Google's encoded polyline string into a list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      // Decode latitude
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;

      // Decode longitude
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  Future<void> _updateMapMarkersAndPolyline() async {
    if (widget.bookingData == null) {
      print('⚠️ Booking data is null, cannot update map');
      return;
    }

    final pickupPlace = widget.bookingData!.pickupPlace;
    final dropPlace = widget.bookingData!.dropPlace;

    // Validate that we have valid coordinates
    final hasPickupCoords =
        pickupPlace?.latitude != null && pickupPlace?.longitude != null;
    final hasDropCoords =
        dropPlace?.latitude != null && dropPlace?.longitude != null;

    if (!hasPickupCoords) {
      print(
          '⚠️ Pickup place missing coordinates: lat=${pickupPlace?.latitude}, lng=${pickupPlace?.longitude}');
    }
    if (!hasDropCoords) {
      print(
          '⚠️ Drop place missing coordinates: lat=${dropPlace?.latitude}, lng=${dropPlace?.longitude}');
    }

    if (!hasPickupCoords || !hasDropCoords) {
      print('⚠️ Cannot update map markers/polylines without valid coordinates');
      return;
    }

    // Create custom pin icons
    final pickupIcon = await _createPickupPinIcon();
    final dropIcon = await _createDropPinIcon();

    // First, update markers synchronously
    setState(() {
      _markers.clear();
      _polylines.clear();

      // Add pickup marker with custom icon
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupPlace!.latitude!, pickupPlace.longitude!),
          icon: pickupIcon,
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: pickupPlace.primaryText ?? 'Pickup Location',
          ),
        ),
      );

      // Add drop marker with custom icon
      _markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(dropPlace!.latitude!, dropPlace.longitude!),
          icon: dropIcon,
          infoWindow: InfoWindow(
            title: 'Drop',
            snippet: dropPlace.primaryText ?? 'Drop Location',
          ),
        ),
      );

      print('✅ Added ${_markers.length} markers to map');
    });

    // Wait a frame to ensure markers are rendered
    await Future.delayed(const Duration(milliseconds: 100));

    // Update camera to show both markers
    if (_markers.length >= 2 && _mapController != null) {
      _fitBounds();
    }

    // Then, fetch route from Google Directions API and add polyline asynchronously
    // Fetch directions from Google Directions API
    final routePoints = await _fetchDirections(
      pickupPlace!.latitude!,
      pickupPlace.longitude!,
      dropPlace!.latitude!,
      dropPlace.longitude!,
    );

    // If we got route points from Directions API, use them
    // Otherwise, fall back to straight line
    final pointsToUse = routePoints ??
        [
          LatLng(pickupPlace.latitude!, pickupPlace.longitude!),
          LatLng(dropPlace.latitude!, dropPlace.longitude!),
        ];

    // Update polyline with the route points
    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: pointsToUse,
          color: const Color(0xFF213B87), // Bright blue color for visibility
          width: 5, // Increased width for better visibility
          geodesic: routePoints !=
              null, // Use geodesic for actual route, false for straight line
        ),
      );
      print('✅ Added polyline with ${pointsToUse.length} points');
    });

    // Fit bounds again after polyline is added to ensure everything is visible
    if (_markers.length >= 2 && _mapController != null) {
      await Future.delayed(const Duration(milliseconds: 100));
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_markers.isEmpty || _mapController == null) return;

    // Collect all positions from markers
    final positions = _markers.map((m) => m.position).toList();

    // Also include polyline points if available
    for (var polyline in _polylines) {
      positions.addAll(polyline.points);
    }

    if (positions.isEmpty) return;

    // Calculate bounds
    double minLat = positions[0].latitude;
    double maxLat = positions[0].latitude;
    double minLng = positions[0].longitude;
    double maxLng = positions[0].longitude;

    for (var pos in positions) {
      minLat = minLat < pos.latitude ? minLat : pos.latitude;
      maxLat = maxLat > pos.latitude ? maxLat : pos.latitude;
      minLng = minLng < pos.longitude ? minLng : pos.longitude;
      maxLng = maxLng > pos.longitude ? maxLng : pos.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding in pixels
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only update map if drop location exists
      if (_hasDropLocation()) {
        _updateMapMarkersAndPolyline();
      }
    });
  }

  @override
  void didUpdateWidget(_BookingBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookingData != widget.bookingData) {
      // Only update map if drop location exists
      if (_hasDropLocation()) {
        _updateMapMarkersAndPolyline();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDrop = _hasDropLocation();

    return Stack(
      children: [
        // Full-screen Google Map (only show if drop exists)
        Column(
          children: [
            if (hasDrop)
              SizedBox(
                height: 400,
                child: GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
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
                  onMapCreated: (c) {
                    _mapController = c;
                    // Update markers and polyline after map is created (only if drop exists)
                    if (_hasDropLocation()) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _updateMapMarkersAndPolyline();
                      });
                    }
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                ),
              ),
            if (!hasDrop)
              SizedBox(
                height: 116,
              ),
            Expanded(
                child: Padding(
              padding: !hasDrop
                  ? const EdgeInsets.symmetric(horizontal: 16.0)
                  : EdgeInsets.symmetric(horizontal: 0.0),
              child: _VehicleSection(bookingData: widget.bookingData),
            ))
          ],
        ),
        SizedBox(
            height: 146, child: _RouteCard(bookingData: widget.bookingData)),
        // SizedBox(
        //   height: 192,
        //     child: TripContainer()),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final CrpBookingData? bookingData;

  const _RouteCard({this.bookingData});

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('dd MMM, yyyy, hh:mm a zz').format(dateTime);
  }

  /// Safely shortens a text to a maximum number of characters.
  /// Adds ".." suffix if truncated.
  /// This uses character length only (not widget width) to keep
  /// strings compact inside the RouteCard.
  String _shorten(String text, {int maxChars = 25}) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars - 2)}..';
  }

  String _getRouteText() {
    if (bookingData == null) {
      return 'Please select pickup and drop locations';
    }

    final pickupPlace = bookingData!.pickupPlace;
    final dropPlace = bookingData!.dropPlace;

    // Build full text using primary + secondary, similar to booking screen
    final pickupPrimary = pickupPlace?.primaryText ?? 'Pickup location';
    final pickupSecondary = pickupPlace?.secondaryText ?? '';
    final pickupFull = pickupSecondary.isNotEmpty
        ? '$pickupPrimary, $pickupSecondary'
        : pickupPrimary;

    final dropPrimary = dropPlace?.primaryText ?? 'Drop location';
    final dropSecondary = dropPlace?.secondaryText ?? '';
    final dropFull =
        dropSecondary.isNotEmpty ? '$dropPrimary, $dropSecondary' : dropPrimary;

    final combined = '$pickupFull to $dropFull';
    // Slightly higher limit for the combined route line
    return _shorten(combined, maxChars: 40);
  }

  String _getPickupRouteText() {
    if (bookingData == null) {
      return 'Please select pickup locations';
    }

    final pickupPlace = bookingData!.pickupPlace;
    final pickupPrimary = pickupPlace?.primaryText ?? 'Pickup location';
    final pickupSecondary = pickupPlace?.secondaryText ?? '';
    final pickupFull = pickupSecondary.isNotEmpty
        ? '$pickupPrimary, $pickupSecondary'
        : pickupPrimary;

    // Enforce a strict character length for the pickup text
    return _shorten(pickupFull, maxChars: 25);
  }

  String _getDropRouteText() {
    if (bookingData == null) {
      return 'Please select drop locations';
    }

    final dropPlace = bookingData!.dropPlace;
    final dropPrimary = dropPlace?.primaryText ?? 'drop location';
    final dropSecondary = dropPlace?.secondaryText ?? '';
    final dropFull =
        dropSecondary.isNotEmpty ? '$dropPrimary, $dropSecondary' : dropPrimary;

    // Enforce a strict character length for the drop text
    return _shorten(dropFull, maxChars: 25);
  }

  String _getPickupTypeText() {
    if (bookingData == null || bookingData!.pickupType == null) {
      return '';
    }
    return bookingData!.pickupType ?? '';
  }

  bool _hasDropLocation() {
    if (bookingData == null) {
      return false;
    }
    final dropPlace = bookingData!.dropPlace;
    if (dropPlace == null) {
      return false;
    }
    final primaryText = dropPlace.primaryText;
    return primaryText != null && primaryText.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 14, right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000), // More visible shadow for map separation
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x0D000000), // Softer outer shadow
            offset: Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),

      // Ensures all child corners are clipped properly
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            /// TOP CARD
            Container(
              padding: const EdgeInsets.only(top: 14, right: 14, left: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      InkWell(
                        onTap: () {
                          context.push(AppRoutes.cprBookingEngine);
                        },
                        child: SvgPicture.asset(
                          'assets/images/back.svg',
                          width: 18,
                          height: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Left: vertical icon line (pickup and drop icons)
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
                              // Vertical line (only show if drop exists)
                              if (_hasDropLocation())
                                SizedBox(
                                  width: 2,
                                  height: 24,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                              // Square end (drop icon) - only show if drop exists
                              if (_hasDropLocation())
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
                      const SizedBox(width: 16),
                      // Center: locations fields/text, expanded
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pickup location
                            Text(
                              _getPickupRouteText(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F4F4F),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Drop location (only show if drop exists)
                            if (_hasDropLocation()) ...[
                              const SizedBox(height: 16),
                              Text(
                                _getDropRouteText(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F4F4F),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// WHITE SPACER
            Container(height: 10, color: Colors.white),

            /// BOTTOM SECTION
            Container(
              padding: const EdgeInsets.only(
                  left: 16, top: 10, bottom: 10, right: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(bookingData?.pickupDateTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF717171),
                    ),
                  ),
                  if (_getPickupTypeText().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      child: Text(
                        _getPickupTypeText(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4082F1),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleSection extends StatefulWidget {
  final CrpBookingData? bookingData;

  const _VehicleSection({this.bookingData});

  @override
  State<_VehicleSection> createState() => _VehicleSectionState();
}

class _VehicleSectionState extends State<_VehicleSection> {
  final controller = Get.put(CrpInventoryListController());
  String? selectedCategory;

  /// Extracts category from carType string like "Tata Indiaca[Economy]" -> "Economy"
  String? _extractCategory(String? carType) {
    if (carType == null || carType.isEmpty) return null;
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(carType);
    return match?.group(1);
  }

  /// Gets unique categories from all models
  List<String> _getCategories() {
    final categories = <String>{};
    for (var model in controller.models) {
      final category = _extractCategory(model.carType);
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }
    final sortedCategories = categories.toList()..sort();
    return ['All', ...sortedCategories];
  }

  /// Filters models based on selected category
  List<CrpCarModel> _getFilteredModels() {
    if (selectedCategory == null || selectedCategory == 'All') {
      return controller.models;
    }
    return controller.models.where((model) {
      final category = _extractCategory(model.carType);
      return category == selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Don't render anything while loading - parent handles the loader
      if (controller.isLoading.value) {
        return const SizedBox.shrink();
      }

      final categories = _getCategories();

      // Initialize selected category to 'All' on first load
      if (selectedCategory == null && categories.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              selectedCategory = 'All';
            });
          }
        });
      }

      final filteredModels = _getFilteredModels();

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x402B64E5),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 14),
            _VehicleFilterTabs(
              categories: categories,
              selectedCategory: selectedCategory ?? 'All',
              onCategorySelected: (category) {
                setState(() {
                  selectedCategory = category;
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredModels.isEmpty
                  ? const Center(
                      child: Text(
                        'No vehicles available',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: filteredModels.length,
                      itemBuilder: (_, index) => _VehicleCard(
                        model: filteredModels[index],
                        bookingData: widget.bookingData,
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _VehicleFilterTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const _VehicleFilterTabs({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final category = categories[i];
          final isSelected = category == selectedCategory;
          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2B64E5) : Color(0xFFE2E2E2),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VehicleCard extends StatefulWidget {
  final CrpCarModel model;
  final CrpBookingData? bookingData;

  const _VehicleCard({required this.model, this.bookingData});

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard> {
  /// Extracts category from carType string like "Hyundai Accent[Intermediate]" -> "Intermediate"
  String? _extractCategory(String? carType) {
    if (carType == null || carType.isEmpty) return null;
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(carType);
    return match?.group(1);
  }

  /// Extracts car name from carType string like "Hyundai Accent[Intermediate]" -> "Hyundai Accent"
  String _extractCarName(String? carType) {
    if (carType == null || carType.isEmpty) return '';
    final bracketIndex = carType.indexOf('[');
    if (bracketIndex == -1) return carType;
    return carType.substring(0, bracketIndex).trim();
  }

  @override
  Widget build(BuildContext context) {
    final carName = _extractCarName(widget.model.carType);
    final category = _extractCategory(widget.model.carType);

    return GestureDetector(
        onTap: () {
          GoRouter.of(context).push(
            AppRoutes.cprBookingConfirmation,
            extra: {
              'carModel': widget.model.toJson(),
              'bookingData': widget.bookingData?.toJson(),
            },
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0x402B64E5), // #2B64E540
                offset: const Offset(0, 1), // 0px 1px
                blurRadius: 3, // 3px blur
                spreadRadius: 0, // 0px spread
              ),
            ],
          ),
          child: Row(
            children: [
              // Car image
              Container(
                width: 71,
                height: 51,
                child: Image.network(
                  widget.model.carImageUrl ?? '',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Text details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car name and category in a row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            carName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF373737)),
                          ),
                        ),
                        if (category != null && category.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B64E5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/passenger.svg',
                          width: 12,
                          height: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(widget.model.seats.toString() ?? '',
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                        Container(
                          width: 9,
                          height: 9,
                          decoration:
                              const BoxDecoration(color: Color(0xFF949494)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.ac_unit, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text('AC', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class _InventoryShimmer extends StatelessWidget {
  const _InventoryShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Fake filter tabs row
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: 4,
                itemBuilder: (_, __) => Container(
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: 5,
                itemBuilder: (_, __) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TripContainer extends StatelessWidget {
  final CrpBookingData? bookingData;
  const TripContainer({super.key, this.bookingData});

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('dd MMM, yyyy, hh:mm a zz').format(dateTime);
  }

  String _getPickupRouteText() {
    if (bookingData == null) {
      return 'Please select pickup locations';
    }

    final pickupPlace = bookingData!.pickupPlace;
    final pickupPrimary = pickupPlace?.primaryText ?? 'Pickup location';
    final pickupSecondary = pickupPlace?.secondaryText ?? '';
    final pickup = pickupSecondary.isNotEmpty
        ? '$pickupPrimary, $pickupSecondary'
        : pickupPrimary;

    // Let the Text widget handle truncation
    return pickup;
  }

  String _getDropRouteText() {
    if (bookingData == null) {
      return 'Please select drop locations';
    }

    final dropPlace = bookingData!.dropPlace;
    final dropPrimary = dropPlace?.primaryText ?? 'drop location';
    final dropSecondary = dropPlace?.secondaryText ?? '';
    final drop =
        dropSecondary.isNotEmpty ? '$dropPrimary, $dropSecondary' : dropPrimary;

    // Let the Text widget handle truncation
    return drop;
  }

  String _getPickupTypeText() {
    if (bookingData == null || bookingData!.pickupType == null) {
      return '';
    }
    return bookingData!.pickupType ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ), // rounded + elevation-like shadow [web:12][web:13]
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              const Icon(Icons.radio_button_checked,
                  color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getPickupRouteText(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(width: 40),
              Icon(Icons.location_on, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getDropRouteText(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(bookingData?.pickupDateTime),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    foregroundColor: Colors.blue,
                  ), // rounded pill button [web:5][web:26]
                  onPressed: () {},
                  child: Text(
                    _getPickupTypeText(),
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
