import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:wti_cabs_user/core/controller/self_drive/fetch_most_popular_location/fetch_most_popular_location_controller.dart';
import 'package:wti_cabs_user/core/controller/self_drive/sd_google_suggestions/sd_google_suggestions_controller.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_pickup_map/self_drive_pickup_map.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

import '../../../core/controller/self_drive/google_lat_lng_controller/google_lat_lng_controller.dart';

class SelfDriveMostPopularLocation extends StatefulWidget {
  final String vehicleId;
  final bool isHomePage;
  const SelfDriveMostPopularLocation(
      {super.key, required this.vehicleId, required this.isHomePage});

  @override
  State<SelfDriveMostPopularLocation> createState() =>
      _SelfDriveMostPopularLocationState();
}

class _SelfDriveMostPopularLocationState
    extends State<SelfDriveMostPopularLocation> {
  final FetchMostPopularLocationController fetchMostPopularLocationController =
      Get.put(FetchMostPopularLocationController());
  final SdGoogleSuggestionsController sdGoogleSuggestionsController =
      Get.put(SdGoogleSuggestionsController());

  final TextEditingController searchController = TextEditingController();
  final GoogleLatLngController googleLatLngController =
      Get.put(GoogleLatLngController());

  @override
  void initState() {
    super.initState();
    fetchMostPopularLocationController.fetchMostPopularLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.white,
        elevation: 0,
        title: SizedBox(
            height: 40,
            child: TextFormField(
              controller: sdGoogleSuggestionsController
                  .searchController, // normal controller
              decoration: InputDecoration(
                hintText: "Search address",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                sdGoogleSuggestionsController.fetchSuggestions(val);
              },
            )),
      ),
      body: Obx(() {
        if (sdGoogleSuggestionsController.searchText.value.isNotEmpty) {
          /// Show Google suggestions
          return Column(
            children: [
              Container(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.0),
                margin: EdgeInsets.symmetric(horizontal: 16.0),
                color: Colors.grey.shade200,
                child: Text(
                  'Address Suggestions',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.bodyTextPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: sdGoogleSuggestionsController
                          .sdGoogleSuggestionsResponse.value?.result?.length ??
                      0,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final suggestion = sdGoogleSuggestionsController
                        .sdGoogleSuggestionsResponse.value?.result?[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(suggestion?.primaryText ?? "",
                          style: TextStyle(fontSize: 13)),
                      subtitle: Text(suggestion?.secondaryText ?? "",
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      onTap: () async {
                        await googleLatLngController
                            .fetchLatLng(suggestion?.placeId ?? '', context)
                            .then((val) {
                          Navigator.of(context).push(
                            Platform.isIOS
                                ? CupertinoPageRoute(
                                    builder: (_) => SelfDrivePlaceMap(
                                      vehicleId: widget.vehicleId,
                                      isHomePage: false,
                                    ),
                                  )
                                : MaterialPageRoute(
                                    builder: (_) => SelfDrivePlaceMap(
                                      vehicleId: widget.vehicleId,
                                      isHomePage: false,
                                    ),
                                  ),
                          );
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        } else {
          /// Show default popular sections
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              SectionAirportWidget(
                title: "Airports",
                icon: Icons.flight_takeoff,
                vehicleId: widget.vehicleId,
                isHomePage: false,
              ),
              SizedBox(height: 10),
              SectionResidentialWidget(
                title: "Residential",
                icon: Icons.location_on_outlined,
                vehicleId: widget.vehicleId,
                isHomePage: false,
              ),
              SizedBox(height: 10),
              SectionHotelsWidget(
                title: "Hotels",
                icon: Icons.location_on_outlined,
                vehicleId: widget.vehicleId,
                isHomePage: false,
              ),
            ],
          );
        }
      }),
    );
  }
}

// Airport
class SectionAirportWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final String vehicleId;
  final bool isHomePage;

  const SectionAirportWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.vehicleId,
    required this.isHomePage,
  });

  @override
  State<SectionAirportWidget> createState() => _SectionAirportWidgetState();
}

class _SectionAirportWidgetState extends State<SectionAirportWidget> {
  final FetchMostPopularLocationController fetchMostPopularLocationController =
      Get.put(FetchMostPopularLocationController());
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchMostPopularLocationController.fetchMostPopularLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8.0),
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          color: Colors.grey.shade200,
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.bodyTextPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        // Card with items
        Obx(() => Card(
              color: Colors.white,
              elevation: 0.3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fetchMostPopularLocationController
                        .mostPopularLocationResponse
                        .value
                        ?.result
                        ?.data
                        ?.airport
                        ?.length ??
                    0,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      widget.icon,
                      color: Colors.black87,
                      size: 20,
                    ),
                    title: Text(
                      fetchMostPopularLocationController
                              .mostPopularLocationResponse
                              .value
                              ?.result
                              ?.data
                              ?.airport?[index]
                              .address ??
                          '',
                      style: TextStyle(fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        Platform.isIOS
                            ? CupertinoPageRoute(
                                builder: (_) => SelfDrivePlaceMap(
                                  fromMostPopularPlace: true,
                                  placeName: fetchMostPopularLocationController
                                      .mostPopularLocationResponse
                                      .value
                                      ?.result
                                      ?.data
                                      ?.airport?[index]
                                      .address,
                                  lat: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.airport?[index]
                                          .latlng
                                          ?.lat
                                          ?.toDouble() ??
                                      0.0,
                                  lng: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.airport?[index]
                                          .latlng
                                          ?.lng
                                          ?.toDouble() ??
                                      0.0,
                                  rate: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.airport?[index]
                                          .rate
                                          ?.toDouble() ??
                                      0.0,
                                  vehicleId: widget.vehicleId,
                                  isHomePage: false,
                                ),
                              )
                            : MaterialPageRoute(
                                builder: (_) => SelfDrivePlaceMap(
                                  fromMostPopularPlace: true,
                                  placeName: fetchMostPopularLocationController
                                      .mostPopularLocationResponse
                                      .value
                                      ?.result
                                      ?.data
                                      ?.airport?[index]
                                      .address,
                                  lat: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.airport?[index]
                                          .latlng
                                          ?.lat
                                          ?.toDouble() ??
                                      0.0,
                                  lng: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.airport?[index]
                                          .latlng
                                          ?.lng
                                          ?.toDouble() ??
                                      0.0,
                                  rate: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.airport?[index]
                                          .rate
                                          ?.toDouble() ??
                                      0.0,
                                  vehicleId: widget.vehicleId,
                                  isHomePage: false,
                                ),
                              ),
                      );
                      // handle tap here if needed
                    },
                  );
                },
              ),
            )),
      ],
    );
  }
}

// Residential
class SectionResidentialWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final String vehicleId;
  final bool isHomePage;

  const SectionResidentialWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.vehicleId,
    required this.isHomePage,
  });

  @override
  State<SectionResidentialWidget> createState() =>
      _SectionResidentialWidgetState();
}

class _SectionResidentialWidgetState extends State<SectionResidentialWidget> {
  final FetchMostPopularLocationController fetchMostPopularLocationController =
      Get.put(FetchMostPopularLocationController());
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchMostPopularLocationController.fetchMostPopularLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8.0),
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          color: Colors.grey.shade200,
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.bodyTextPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        // Card with items
        Obx(() => Card(
              color: Colors.white,
              elevation: 0.3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fetchMostPopularLocationController
                        .mostPopularLocationResponse
                        .value
                        ?.result
                        ?.data
                        ?.residential
                        ?.length ??
                    0,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      widget.icon,
                      color: Colors.black87,
                      size: 20,
                    ),
                    title: Text(
                      fetchMostPopularLocationController
                              .mostPopularLocationResponse
                              .value
                              ?.result
                              ?.data
                              ?.residential?[index]
                              .address ??
                          '',
                      style: TextStyle(fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        Platform.isIOS
                            ? CupertinoPageRoute(
                                builder: (_) => SelfDrivePlaceMap(
                                  fromMostPopularPlace: true,
                                  placeName: fetchMostPopularLocationController
                                      .mostPopularLocationResponse
                                      .value
                                      ?.result
                                      ?.data
                                      ?.residential?[index]
                                      .address,
                                  lat: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.residential?[index]
                                          .latlng
                                          ?.lat
                                          ?.toDouble() ??
                                      0.0,
                                  lng: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.residential?[index]
                                          .latlng
                                          ?.lng
                                          ?.toDouble() ??
                                      0.0,
                                  rate: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.residential?[index]
                                          .rate
                                          ?.toDouble() ??
                                      0.0,
                                  vehicleId: widget.vehicleId,
                                  isHomePage: false,
                                ),
                              )
                            : MaterialPageRoute(
                                builder: (_) => SelfDrivePlaceMap(
                                  fromMostPopularPlace: true,
                                  placeName: fetchMostPopularLocationController
                                      .mostPopularLocationResponse
                                      .value
                                      ?.result
                                      ?.data
                                      ?.residential?[index]
                                      .address,
                                  lat: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.residential?[index]
                                          .latlng
                                          ?.lat
                                          ?.toDouble() ??
                                      0.0,
                                  lng: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.residential?[index]
                                          .latlng
                                          ?.lng
                                          ?.toDouble() ??
                                      0.0,
                                  rate: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.residential?[index]
                                          .rate
                                          ?.toDouble() ??
                                      0.0,
                                  vehicleId: widget.vehicleId,
                                  isHomePage: false,
                                ),
                              ),
                      );
                    },
                  );
                },
              ),
            )),
      ],
    );
  }
}

// Hotels
class SectionHotelsWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final String vehicleId;
  final bool isHomePage;

  const SectionHotelsWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.vehicleId,
    required this.isHomePage,
  });

  @override
  State<SectionHotelsWidget> createState() => _SectionHotelsWidgetState();
}

class _SectionHotelsWidgetState extends State<SectionHotelsWidget> {
  final FetchMostPopularLocationController fetchMostPopularLocationController =
      Get.put(FetchMostPopularLocationController());
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchMostPopularLocationController.fetchMostPopularLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8.0),
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          color: Colors.grey.shade200,
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.bodyTextPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        // Card with items
        Obx(() => Card(
              color: Colors.white,
              elevation: 0.3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fetchMostPopularLocationController
                        .mostPopularLocationResponse
                        .value
                        ?.result
                        ?.data
                        ?.hotel
                        ?.length ??
                    0,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      widget.icon,
                      color: Colors.black87,
                      size: 20,
                    ),
                    title: Text(
                      fetchMostPopularLocationController
                              .mostPopularLocationResponse
                              .value
                              ?.result
                              ?.data
                              ?.hotel?[index]
                              .address ??
                          '',
                      style: TextStyle(fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        Platform.isIOS
                            ? CupertinoPageRoute(
                                builder: (_) => SelfDrivePlaceMap(
                                  fromMostPopularPlace: true,
                                  placeName: fetchMostPopularLocationController
                                      .mostPopularLocationResponse
                                      .value
                                      ?.result
                                      ?.data
                                      ?.hotel?[index]
                                      .address,
                                  lat: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.hotel?[index]
                                          .latlng
                                          ?.lat
                                          ?.toDouble() ??
                                      0.0,
                                  lng: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.hotel?[index]
                                          .latlng
                                          ?.lng
                                          ?.toDouble() ??
                                      0.0,
                                  rate: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.hotel?[index]
                                          .rate
                                          ?.toDouble() ??
                                      0.0,
                                  vehicleId: widget.vehicleId,
                                  isHomePage: false,
                                ),
                              )
                            : MaterialPageRoute(
                                builder: (_) => SelfDrivePlaceMap(
                                  fromMostPopularPlace: true,
                                  placeName: fetchMostPopularLocationController
                                      .mostPopularLocationResponse
                                      .value
                                      ?.result
                                      ?.data
                                      ?.hotel?[index]
                                      .address,
                                  lat: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.hotel?[index]
                                          .latlng
                                          ?.lat
                                          ?.toDouble() ??
                                      0.0,
                                  lng: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.hotel?[index]
                                          .latlng
                                          ?.lng
                                          ?.toDouble() ??
                                      0.0,
                                  rate: fetchMostPopularLocationController
                                          .mostPopularLocationResponse
                                          .value
                                          ?.result
                                          ?.data
                                          ?.hotel?[index]
                                          .rate
                                          ?.toDouble() ??
                                      0.0,
                                  vehicleId: widget.vehicleId,
                                  isHomePage: false,
                                ),
                              ),
                      );
                    },
                  );
                },
              ),
            )),
      ],
    );
  }
}
