import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:wti_cabs_user/core/api/corporate/cpr_api_services.dart';
import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';

class CrpSelectPickupController extends GetxController {
  final RxList<SuggestionPlacesResponse> suggestions = <SuggestionPlacesResponse>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasSearchText = false.obs;

  final TextEditingController searchController = TextEditingController();
  final Rx<SuggestionPlacesResponse?> selectedPlace = Rx<SuggestionPlacesResponse?>(null);

  Timer? _debounce;

  // Google Api Key
  final String googleApiKey = "AIzaSyCWbmCiquOta1iF6um7_5_NFh6YM5wPL30";

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      final text = searchController.text;
      hasSearchText.value = text.isNotEmpty;
      _onSearchChanged(text);
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      suggestions.clear();
      hasSearchText.value = false;
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchPlaces(value.trim());
    });
  }

  Future<void> searchPlaces(String searchedText) async {
    if (searchedText.isEmpty) {
      suggestions.clear();
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$searchedText&key=$googleApiKey&components=country:in";

    try {
      final response = await CprApiService()
          .sendRequestWithRetry(() => http.get(Uri.parse(url)));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final predictions = jsonData["predictions"] as List;

        suggestions.value = predictions
            .map((e) => SuggestionPlacesResponse(
          primaryText: e["structured_formatting"]["main_text"] ?? "",
          secondaryText: e["structured_formatting"]["secondary_text"] ?? "",
          placeId: e["place_id"] ?? "", 
          types: [], 
          terms: [], 
          city: '', 
          state: '', 
          country: '', 
          isAirport: false,
          latitude: null,
          longitude: null,
          placeName: '',
        ))
            .toList();
      } else {
        errorMessage.value = "Failed: ${response.statusCode}";
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches place details including latitude, longitude, and place name
  Future<SuggestionPlacesResponse?> getPlaceDetails(
      String placeId, SuggestionPlacesResponse? existingPlace) async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey&fields=geometry,formatted_address,name";

      final response = await CprApiService()
          .sendRequestWithRetry(() => http.get(Uri.parse(url)));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = jsonData["result"];

        if (result != null) {
          final geometry = result["geometry"];
          final location = geometry?["location"];
          
          final latitude = location?["lat"] != null 
              ? (location["lat"] as num).toDouble() 
              : null;
          final longitude = location?["lng"] != null 
              ? (location["lng"] as num).toDouble() 
              : null;
          final placeName = result["name"] ?? "";
          final formattedAddress = result["formatted_address"] ?? "";

          // Create updated place with details
          if (existingPlace != null) {
            return SuggestionPlacesResponse(
              primaryText: existingPlace.primaryText,
              secondaryText: existingPlace.secondaryText,
              placeId: existingPlace.placeId,
              types: existingPlace.types,
              terms: existingPlace.terms,
              city: existingPlace.city,
              state: existingPlace.state,
              country: existingPlace.country,
              isAirport: existingPlace.isAirport,
              latitude: latitude,
              longitude: longitude,
              placeName: placeName.isNotEmpty ? placeName : formattedAddress,
            );
          }
        }
      }
    } catch (e) {
      errorMessage.value = "Error fetching place details: ${e.toString()}";
    }
    return null;
  }

  Future<void> selectPlace(SuggestionPlacesResponse place) async {
    // Fetch place details to get lat/lng if not already available
    SuggestionPlacesResponse? updatedPlace = place;
    
    if (place.latitude == null || place.longitude == null) {
      updatedPlace = await getPlaceDetails(place.placeId, place);
      if (updatedPlace == null) {
        // If fetching details fails, use the original place
        updatedPlace = place;
      }
    }

    selectedPlace.value = updatedPlace;
    searchController.text = updatedPlace.primaryText;
    suggestions.clear();
  }

  void clearSelection() {
    selectedPlace.value = null;
    searchController.clear();
    suggestions.clear();
    hasSearchText.value = false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
