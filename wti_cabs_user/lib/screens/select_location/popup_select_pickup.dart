import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/controller/popup_location/popup_pickup_search_controller.dart';
import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

class PopupSelectPickup extends StatefulWidget {
  final String controllerTag;
  final String initialText;

  const PopupSelectPickup({
    super.key,
    required this.controllerTag,
    this.initialText = '',
  });

  @override
  State<PopupSelectPickup> createState() => _PopupSelectPickupState();
}

class _PopupSelectPickupState extends State<PopupSelectPickup> {
  late final PopupPickupSearchController popupPickupController;
  final TextEditingController pickupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    popupPickupController =
        Get.find<PopupPickupSearchController>(tag: widget.controllerTag);
    popupPickupController.suggestions.clear();
    popupPickupController.errorMessage.value = '';
    pickupController.text = widget.initialText;
  }

  @override
  void dispose() {
    pickupController.dispose();
    super.dispose();
  }

  Future<void> _onSelect(SuggestionPlacesResponse place) async {
    pickupController.text = place.primaryText;
    await popupPickupController.getLatLngDetails(place.placeId, context);
    if (!mounted) return;
    Navigator.of(context).pop(place);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.scaffoldBgPrimary1,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.scaffoldBgPrimary1,
        iconTheme: const IconThemeData(color: AppColors.blue4),
        title: Text('Choose Pickup', style: CommonFonts.appBarText),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                autofocus: true,
                controller: pickupController,
                decoration: InputDecoration(
                  hintText: 'Enter pickup location',
                  suffixIcon: pickupController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            pickupController.clear();
                            popupPickupController.suggestions.clear();
                            setState(() {});
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
                  setState(() {});
                  popupPickupController.searchPlaces(value, context);
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.bgGrey1,
              child: const Row(
                children: [
                  Icon(Icons.history_outlined, size: 18, color: Colors.black),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pickup places Suggestions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              final suggestions = popupPickupController.suggestions;
              final loading = popupPickupController.isLoading.value;

              if (loading && suggestions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (suggestions.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: AppColors.bgGrey2),
                  ),
                  itemBuilder: (context, index) {
                    final place = suggestions[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      leading: const Icon(Icons.location_on, size: 20),
                      title: Text(
                        place.primaryText.split(',').first.trim(),
                        style: CommonFonts.bodyText1Black,
                      ),
                      subtitle: Text(
                        place.secondaryText,
                        style: CommonFonts.bodyText6Black,
                      ),
                      onTap: () => _onSelect(place),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
