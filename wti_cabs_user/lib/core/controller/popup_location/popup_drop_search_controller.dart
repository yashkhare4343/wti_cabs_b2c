import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/api/api_services.dart';
import 'package:wti_cabs_user/core/model/booking_engine/get_lat_lng_response.dart';
import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';

class PopupDropSearchController extends GetxController {
  final apiService = ApiService();

  final RxList<SuggestionPlacesResponse> suggestions =
      <SuggestionPlacesResponse>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString dropPlaceId = ''.obs;
  final Rxn<GetLatLngResponse> dropLatLng = Rxn<GetLatLngResponse>();

  Timer? _debounce;

  Future<void> searchDropPlaces(String searchedText, BuildContext context) async {
    _debounce?.cancel();
    if (searchedText.trim().isEmpty) {
      suggestions.clear();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        isLoading.value = true;
        final responseData = await apiService.postRequest(
          'google/ind/$searchedText?isMobileApp=true',
          {},
          context,
        );

        final results = responseData['result'] as List?;
        suggestions.value = results
                ?.map((e) =>
                    SuggestionPlacesResponse.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      } catch (e) {
        errorMessage.value = e.toString();
        suggestions.clear();
      } finally {
        isLoading.value = false;
      }
    });
  }

  Future<void> getLatLngForDrop(String selectedPlaceId, BuildContext context) async {
    try {
      isLoading.value = true;
      final responseData = await apiService.postRequest(
        'google/getLatLongChauffeur?isMobileApp=true',
        {"place_id": selectedPlaceId, "isLatLngAvailable": false},
        context,
      );

      final parsed = GetLatLngResponse.fromJson(responseData);
      dropLatLng.value = parsed;
      dropPlaceId.value = selectedPlaceId;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
