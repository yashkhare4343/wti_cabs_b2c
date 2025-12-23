import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controller/corporate/crp_select_drop_controller/crp_select_drop_controller.dart';
import '../../../core/model/booking_engine/suggestions_places_response.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../../../utility/constants/fonts/common_fonts.dart';

class CrpDropSearchScreen extends StatefulWidget {
  const CrpDropSearchScreen({super.key});

  @override
  State<CrpDropSearchScreen> createState() => _CrpDropSearchScreenState();
}

class _CrpDropSearchScreenState extends State<CrpDropSearchScreen> {
  final CrpSelectDropController crpSelectDropController =
      Get.put(CrpSelectDropController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.8,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.polylineGrey),
        title: Text(
          'Search drop location',
          style: CommonFonts.appBarText,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => TextField(
                controller: crpSelectDropController.searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter drop location',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      crpSelectDropController.hasSearchText.value &&
                              crpSelectDropController
                                  .searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: AppColors.greyText2,
                              ),
                              onPressed: () {
                                crpSelectDropController.clearSelection();
                              },
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (crpSelectDropController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final suggestions =
                    crpSelectDropController.suggestions.toList();

                if (suggestions.isEmpty) {
                  if (crpSelectDropController.hasSearchText.value) {
                    return const Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.greyText2,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                return ListView.separated(
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.bgGrey2,
                  ),
                  itemBuilder: (context, index) {
                    final SuggestionPlacesResponse place = suggestions[index];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        place.primaryText.split(',').first.trim(),
                        style: CommonFonts.bodyText1Black,
                      ),
                      subtitle: Text(
                        place.secondaryText,
                        style: CommonFonts.bodyText6Black,
                      ),
                      onTap: () async {
                        await crpSelectDropController.selectPlace(place);
                        final selected =
                            crpSelectDropController.selectedPlace.value;
                        Navigator.of(context).pop(selected);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

