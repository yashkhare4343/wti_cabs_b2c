import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/controller/popup_location/popup_drop_search_controller.dart';
import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

class PopupSelectDrop extends StatefulWidget {
  final String controllerTag;
  final String initialText;

  const PopupSelectDrop({
    super.key,
    required this.controllerTag,
    this.initialText = '',
  });

  @override
  State<PopupSelectDrop> createState() => _PopupSelectDropState();
}

class _PopupSelectDropState extends State<PopupSelectDrop> {
  late final PopupDropSearchController popupDropController;
  final TextEditingController dropController = TextEditingController();

  @override
  void initState() {
    super.initState();
    popupDropController =
        Get.find<PopupDropSearchController>(tag: widget.controllerTag);
    popupDropController.suggestions.clear();
    popupDropController.errorMessage.value = '';
    dropController.text = widget.initialText;
  }

  @override
  void dispose() {
    dropController.dispose();
    super.dispose();
  }

  Future<void> _onSelect(SuggestionPlacesResponse place) async {
    dropController.text = place.primaryText;
    await popupDropController.getLatLngForDrop(place.placeId, context);
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
        title: Text('Choose Drop', style: CommonFonts.appBarText),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                autofocus: true,
                controller: dropController,
                decoration: InputDecoration(
                  hintText: 'Enter drop location',
                  suffixIcon: dropController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            dropController.clear();
                            popupDropController.suggestions.clear();
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
                  popupDropController.searchDropPlaces(value, context);
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
                      'Drop Places Suggestions',
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
              final suggestions = popupDropController.suggestions;
              final loading = popupDropController.isLoading.value;

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
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.bgGrey2,
                  ),
                  itemBuilder: (context, index) {
                    final place = suggestions[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
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
