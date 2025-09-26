import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wti_cabs_user/core/controller/self_drive/google_lat_lng_controller/google_lat_lng_controller.dart';
import 'package:wti_cabs_user/core/controller/self_drive/self_drive_booking_details/self_drive_booking_details_controller.dart';
import '../../../core/controller/self_drive/fetch_most_popular_location/fetch_most_popular_location_controller.dart';
import '../self_drive_final_page_st1/self_drive_final_page_s1.dart';

class SelfDriveReturnPlaceMap extends StatefulWidget {
  final bool? fromMostPopularPlace;
  final String? placeName;
  final double? lat;
  final double? lng; // <-- fixed type to double for consistency
  final double? rate;
  final String vehicleId;
  final bool isHomePage; // <-- fixed type to double for consistency

  const SelfDriveReturnPlaceMap({
    super.key,
    this.fromMostPopularPlace,
    this.placeName,
    this.lat,
    this.lng,
    this.rate,
    required this.vehicleId,
    required this.isHomePage,
  });

  @override
  State<SelfDriveReturnPlaceMap> createState() => _SelfDriveReturnPlaceMapState();
}

class _SelfDriveReturnPlaceMapState extends State<SelfDriveReturnPlaceMap> {
  final GoogleLatLngController googleLatLngController =
      Get.put(GoogleLatLngController());
  final FetchMostPopularLocationController fetchMostPopularLocationController =
      Get.put(FetchMostPopularLocationController());
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
      Get.put(FetchSdBookingDetailsController());
  GoogleMapController? mapController;
  final Set<Marker> markers = {};

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Obx(() {
        final result =
            googleLatLngController.googleLatLngResponse.value?.result;

        /// LatLng based on MostPopularPlace or API response
        final LatLng initialLatLng = widget.fromMostPopularPlace == true
            ? LatLng(widget.lat ?? 25.2048, widget.lng ?? 55.2708)
            : LatLng(
                result?.latlng?.lat ?? 25.2048, result?.latlng?.lng ?? 55.2708);

        markers.clear();
        markers.add(
          Marker(
            markerId: const MarkerId("custom_marker"),
            position: initialLatLng,
            infoWindow: InfoWindow(
              title: widget.fromMostPopularPlace == true
                  ? widget.placeName ?? "Selected Location"
                  : result?.city ?? "Selected Location",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );

        final searchController = TextEditingController(
          text: widget.fromMostPopularPlace == true
              ? widget.placeName ?? ""
              : result?.address ?? "",
        );

        final address = widget.fromMostPopularPlace == true
            ? widget.placeName ?? ""
            : result?.address ?? "";

        final rate = widget.fromMostPopularPlace == true
            ? widget.rate.toString()
            : "${result?.rate ?? 0}";

        return Stack(
          children: [
            /// Google Map
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: initialLatLng, zoom: 14),
              onMapCreated: _onMapCreated,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),

            /// Top search bar
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: TextFormField(
                readOnly: true,
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search address",
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  // Hook for suggestions API
                },
              ),
            ),

            /// Bottom sheet
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Address + Rate Card
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0.3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "AED $rate",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    /// Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Get.back(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                fetchSdBookingDetailsController
                                    .isFreeDrop.value = false;
                                fetchSdBookingDetailsController.isSameLocation.value = false; // important
                                fetchSdBookingDetailsController
                                    .collection_charges.value = double.parse(rate);
                                fetchSdBookingDetailsController
                                    .fetchBookingDetails(
                                        widget.vehicleId, false)
                                    .then((val) {
                                  Navigator.of(context).push(
                                    Platform.isIOS
                                        ? CupertinoPageRoute(
                                            builder: (_) =>
                                                SelfDriveFinalPageS1(
                                                    vehicleId: widget.vehicleId,
                                                    isHomePage: false),
                                          )
                                        : MaterialPageRoute(
                                            builder: (_) =>
                                                SelfDriveFinalPageS1(
                                                    vehicleId: widget.vehicleId,
                                                    isHomePage: false),
                                          ),
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Save",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
