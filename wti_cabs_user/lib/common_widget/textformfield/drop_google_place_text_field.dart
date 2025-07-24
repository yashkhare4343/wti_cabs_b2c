import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_drop/choose_drop_controller.dart';
import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';

class DropGooglePlacesTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final Function(SuggestionPlacesResponse)? onPlaceSelected;

  const DropGooglePlacesTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.onPlaceSelected,
  });

  @override
  State<DropGooglePlacesTextField> createState() => _DropGooglePlacesTextFieldState();
}

class _DropGooglePlacesTextFieldState extends State<DropGooglePlacesTextField> {
  final DropPlaceSearchController dropSearchController = Get.put(DropPlaceSearchController());
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
                dropSearchController.dropSuggestions.value = [];
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
            dropSearchController.searchDropPlaces(value, context);
          },
        ),
      ],
    );
  }
}
