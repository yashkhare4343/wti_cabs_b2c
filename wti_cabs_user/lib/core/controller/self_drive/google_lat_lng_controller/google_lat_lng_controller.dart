import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/model/booking_reservation/booking_reservation_response.dart';
import 'package:wti_cabs_user/core/model/self_drive/google_suggestions/sd_google_suggestions_response.dart';
import 'package:wti_cabs_user/core/model/self_drive/self_drive_lat_lng_response/self_drive_lat_lng_response.dart';
import 'package:wti_cabs_user/core/model/self_drive/service_hub_response/service_hub_response.dart';

import '../../../../screens/self_drive/self_drive_pickup_map/self_drive_pickup_map.dart';
import '../../../api/api_services.dart';
import '../../../model/self_drive/get_all_cities/get_all_cities_response.dart';
import '../../../model/self_drive/self_drive_most_popular_location/self_drive_most_popular_location.dart';
import '../search_inventory_sd_controller/search_inventory_sd_controller.dart';


class GoogleLatLngController extends GetxController {
  Rx<GoogleLatLngResponse?> googleLatLngResponse = Rx<GoogleLatLngResponse?>(null);
  final searchController = TextEditingController();
  final searchText = "".obs;



  RxBool isLoading = false.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    // whenever text changes, update the reactive string
    searchController.addListener(() {
      searchText.value = searchController.text.trim();
    });
  }

  Future<void> fetchLatLng(String placeId, BuildContext context) async {
    isLoading.value = true;
    try {
      final result = await SelfDriveApiService().getRequestNew<GoogleLatLngResponse>(
        'google/getLatLong/$placeId/ae',
        GoogleLatLngResponse.fromJson,
      );
      googleLatLngResponse.value = result;

    } catch (e) {
      print("Failed to fetch Suggestions: $e");
    } finally {
      isLoading.value = false;
    }
  }
}