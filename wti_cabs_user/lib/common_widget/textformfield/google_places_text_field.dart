import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';

import '../../core/controller/choose_pickup/choose_pickup_controller.dart';
class GooglePlacesTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final Function(SuggestionPlacesResponse)? onPlaceSelected;

  GooglePlacesTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.onPlaceSelected,
  });

  @override
  State<GooglePlacesTextField> createState() => _GooglePlacesTextFieldState();
}

class _GooglePlacesTextFieldState extends State<GooglePlacesTextField> {
  final PlaceSearchController searchController = Get.put(PlaceSearchController());
  final BookingRideController bookingRideController = Get.put(BookingRideController());


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          autofocus: true,
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: widget.controller.text.isNotEmpty
                ? GestureDetector(
              onTap: () {
                widget.controller.clear();
                searchController.suggestions.value = [];
                // bookingRideController.prefilled.value = '';
              },
              child: const Icon(Icons.cancel, color: Colors.grey),
            )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
          onChanged: (value) {
            searchController.searchPlaces(value, context);
          },
        ),
      ],
    );
  }
}