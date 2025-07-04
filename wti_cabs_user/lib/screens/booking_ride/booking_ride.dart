import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/common_widget/buttons/primary_button.dart';
import 'package:wti_cabs_user/common_widget/datepicker/date_picker_tile.dart';
import 'package:wti_cabs_user/common_widget/datepicker/date_time_picker.dart';
import 'package:wti_cabs_user/common_widget/dropdown/common_dropdown.dart';
import 'package:wti_cabs_user/common_widget/loader/popup_loader.dart';
import 'package:wti_cabs_user/common_widget/textformfield/booking_textformfield.dart';
import 'package:wti_cabs_user/common_widget/time_picker/time_picker_tile.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/inventory/search_cab_inventory_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import '../../common_widget/datepicker/drop_date_picker.dart';
import '../../common_widget/time_picker/drop_time_picker.dart';
import '../../core/controller/choose_drop/choose_drop_controller.dart';
import '../../core/controller/rental_controller/fetch_package_controller.dart';
import '../../core/services/storage_services.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class BookingRide extends StatefulWidget {
  const BookingRide({super.key});

  @override
  State<BookingRide> createState() => _BookingRideState();
}

class _BookingRideState extends State<BookingRide> {
  final FetchPackageController fetchPackageController =
      Get.put(FetchPackageController());
  @override
  void initState() {
    super.initState();
    // Initialize controllers to avoid LateInitializationError
    Get.put(BookingRideController());
    Get.put(PlaceSearchController());
    fetchPackageController.fetchPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      GoRouter.of(context).pop();
                    },
                    child: const Icon(Icons.arrow_back, color: AppColors.blue4),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Book a Ride",
                    style: CommonFonts.appBarText,
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              height: 8,
            ),
            Flexible(
              child: Container(
                  color: Colors.white, child: const CustomTabBarDemo()),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTabBarDemo extends StatefulWidget {
  const CustomTabBarDemo({Key? key}) : super(key: key);

  @override
  State<CustomTabBarDemo> createState() => _CustomTabBarDemoState();
}

class _CustomTabBarDemoState extends State<CustomTabBarDemo> {
  int selectedIndex = 1;
  final tabs = ["Airport", "Outstation", "Rentals"];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0x40747474),
                offset: const Offset(0, 2),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(tabs.length, (index) {
              final isSelected = selectedIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2C2C6F)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: const Color(0x1F002CC0),
                        offset: const Offset(8, 4),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                        : [],
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.blue4,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Expanded( // ✅ This makes IndexedStack content scrollable & flexible
          child: IndexedStack(
            index: selectedIndex,
            children: const [
              Rides(),
              OutStation(),
              Rental(),
            ],
          ),
        ),
      ],
    );

  }
}

// OutStation cabs
class OutStation extends StatefulWidget {
  const OutStation({super.key});

  @override
  State<OutStation> createState() => _OutStationState();
}

class _OutStationState extends State<OutStation> {
  String selectedTrip = 'oneWay';

  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  final PlaceSearchController placeSearchController =
      Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController =
      Get.put(DropPlaceSearchController());
  final SearchCabInventoryController searchCabInventoryController =
      Get.put(SearchCabInventoryController());
  final RxString selectedField = ''.obs;

  late final TextEditingController pickupController;
  late final TextEditingController dropController;
  late Worker _pickupWorker;
  late Worker _dropWorker;

  @override
  void dispose() {
    // TODO: implement dispose
    _pickupWorker.dispose();
    _dropWorker.dispose();
    pickupController.dispose();
    dropController.dispose();
    super.dispose();
  }

  void switchPickupAndDrop({
    required BuildContext context,
    required TextEditingController pickupController,
    required TextEditingController dropController,
  }) async {
    print('switch button hit ho gya hai');
    // Step 1: Swap place IDs
    final oldPickupId = placeSearchController.placeId.value;
    final oldDropId = dropPlaceSearchController.dropPlaceId.value;
    placeSearchController.placeId.value = oldDropId;
    dropPlaceSearchController.dropPlaceId.value = oldPickupId;

    // Step 2: Swap prefilled values (shown in UI + used in controllers)
    final oldPickupText = bookingRideController.prefilled.value;
    final oldDropText = bookingRideController.prefilledDrop.value;
    bookingRideController.prefilled.value = oldDropText;
    bookingRideController.prefilledDrop.value = oldPickupText;

    // Step 3: Update text controllers (if used in text fields)
    pickupController.text = bookingRideController.prefilled.value;
    dropController.text = bookingRideController.prefilledDrop.value;

    // Step 4: Re-fetch lat/lng details based on new placeIds
    if (placeSearchController.placeId.value.isNotEmpty) {
      placeSearchController.getLatLngDetails(placeSearchController.placeId.value, context);
    }
    if (dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
      dropPlaceSearchController.getLatLngForDrop(dropPlaceSearchController.dropPlaceId.value, context);
    }

    // Swap stored values (local storage)
    final sourceKeys = [
      'sourcePlaceId', 'sourceTitle', 'sourceCity', 'sourceState', 'sourceCountry', 'sourceTypes', 'sourceTerms'
    ];
    final destinationKeys = [
      'destinationPlaceId', 'destinationTitle', 'destinationCity', 'destinationState', 'destinationCountry', 'destinationTypes', 'destinationTerms'
    ];

    for (int i = 0; i < sourceKeys.length; i++) {
      final srcKey = sourceKeys[i];
      final destKey = destinationKeys[i];

      final srcVal = await StorageServices.instance.read(srcKey);
      final destVal = await StorageServices.instance.read(destKey);

      await StorageServices.instance.save(srcKey, destVal ?? '');
      await StorageServices.instance.save(destKey, srcVal ?? '');
    }
  }

  @override
  void initState() {
    super.initState();

    pickupController =
        TextEditingController(text: bookingRideController.prefilled.value);
    dropController =
        TextEditingController(text: bookingRideController.prefilledDrop.value);


    _pickupWorker = ever<String>(bookingRideController.prefilled, (value) {
      if (pickupController.text != value) {
        pickupController.text = value;
      }
    });

    _dropWorker = ever<String>(bookingRideController.prefilledDrop, (value) {
      if (dropController.text != value) {
        dropController.text = value;
      }
    });
  }


  DateTime getLocalDateTime() {
    final userDateTimeStr = placeSearchController
        .findCntryDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final offset = placeSearchController
        .findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (userDateTimeStr != null) {
      try {
        final utc = DateTime.parse(userDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0));
      } catch (e) {
        print("Error parsing userDateTime: $e");
      }
    }

    return bookingRideController.localStartTime.value;
  }

  DateTime getInitialDateTime() {
    final actualDateTimeStr = placeSearchController
        .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime;
    final offset = placeSearchController
        .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet;

    if (actualDateTimeStr != null) {
      try {
        final utc = DateTime.parse(actualDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0));
      } catch (e) {
        print("Error parsing actualDateTime: $e");
      }
    }

    return getLocalDateTime();
  }

  DateTime getDropLocalDateTime() {
    final dropDateTimeStr = dropPlaceSearchController
        .dropDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final dropOffset = dropPlaceSearchController
        .dropDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (dropDateTimeStr != null) {
      try {
        final utc = DateTime.parse(dropDateTimeStr).toUtc();
        return utc.add(Duration(minutes: dropOffset ?? 0));
      } catch (_) {}
    }

    return bookingRideController.localStartTime.value
        .add(const Duration(hours: 4));
  }

  void updateLocalStartTime(DateTime newDateTime) {
    final timezone =
        placeSearchController.findCntryDateTimeResponse.value?.timeZone ??
            placeSearchController.getCurrentTimeZoneName();
    final offset = placeSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localStartTime.value = newDateTime;
    bookingRideController.utcStartTime.value =
        newDateTime.subtract(Duration(minutes: offset));

    // 🟢 Automatically update drop if it's on the same day and less than +4hrs
    final existingDrop = bookingRideController.localEndTime.value;
    final proposedDrop = newDateTime.add(const Duration(hours: 4));

    final isSameDay = DateUtils.isSameDay(newDateTime, existingDrop);
    final isBeforeMin = existingDrop.isBefore(proposedDrop);

    if (isSameDay && isBeforeMin) {
      updateLocalEndTime(proposedDrop);
    }
  }

  void updateLocalEndTime(DateTime newDateTime) {
    final timezone =
        dropPlaceSearchController.dropDateTimeResponse.value?.timeZone ??
            dropPlaceSearchController.getCurrentTimeZoneName();
    final offset = dropPlaceSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localEndTime.value = newDateTime;
    bookingRideController.utcEndTime.value =
        newDateTime.subtract(Duration(minutes: offset));
  }

  Rx<DateTime?> dropDateTime = Rx<DateTime?>(null);


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTripTypeSelector(context),
            const SizedBox(height: 24),
            if (selectedTrip == 'oneWay') _buildOneWayUI(),
            if (selectedTrip == 'roundTrip') _buildRoundTripUI(),
          ],
        ),
      ),
    );

  }

  Widget _buildTripTypeSelector(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          color: AppColors.lightBlue1,
          border: Border.all(color: AppColors.lightBlue2),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _buildOption('One Way', 'oneWay', selectedTrip == 'oneWay'),
                SizedBox(
                  width: 16,
                )
              ],
            ),
            _verticalDivider(),
            Row(
              children: [
                _buildOption(
                    'Round Trip', 'roundTrip', selectedTrip == 'roundTrip'),
                SizedBox(
                  width: 16,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneWayUI() {
    return _buildPickupDropUI(showDropDateTime: false);
  }

  Widget _buildRoundTripUI() {
    return _buildPickupDropUI(showDropDateTime: true);
  }

  Widget _buildPickupDropUI({required bool showDropDateTime}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Image.asset('assets/images/circle.png', width: 40, height: 120),
                Expanded(
                  child: Obx(() => Column(
                        children: [
                          BookingTextFormField(
                            hintText: 'Enter Pickup Location',
                            controller: pickupController,
                            errorText: (() {
                              final pickupId =
                                  placeSearchController.placeId.value;
                              final dropId =
                                  dropPlaceSearchController.dropPlaceId.value;
            
                              if (pickupId.isNotEmpty &&
                                  dropId.isNotEmpty &&
                                  pickupId == dropId) {
                                return "Pickup and Drop cannot be the same";
                              }
            
                              if (placeSearchController
                                          .findCntryDateTimeResponse
                                          .value
                                          ?.sourceInput ==
                                      true ||
                                  dropPlaceSearchController.dropDateTimeResponse
                                          .value?.sourceInput ==
                                      true) {
                                return "We don't offer services from this region";
                              }
            
                              return null;
                            })(),
                            onTap: () => GoRouter.of(context)
                                .push(AppRoutes.choosePickup),
                          ),
                          const SizedBox(height: 12),
                          BookingTextFormField(
                            hintText: 'Enter Drop Location',
                            controller: dropController,
                            errorText: (() {
                              final pickupId =
                                  placeSearchController.placeId.value;
                              final dropId =
                                  dropPlaceSearchController.dropPlaceId.value;
            
                              if (pickupId.isNotEmpty &&
                                  dropId.isNotEmpty &&
                                  pickupId == dropId) {
                                return "Pickup and Drop cannot be the same";
                              }
            
                              if (placeSearchController
                                          .findCntryDateTimeResponse
                                          .value
                                          ?.destinationInputFalse ==
                                      true ||
                                  dropPlaceSearchController.dropDateTimeResponse
                                          .value?.destinationInputFalse ==
                                      true) {
                                return "We don't offer services from this region";
                              }
            
                              return null;
                            })(),
                            onTap: () =>
                                GoRouter.of(context).push(AppRoutes.chooseDrop),
                          ),
                        ],
                      )),
                ),
                Column(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.blue5),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: (){
                        switchPickupAndDrop(context: context, pickupController: pickupController, dropController: dropController);
                      },
                      child: Transform.translate(
                        offset: const Offset(0, 0),
                        child: Image.asset('assets/images/interchange.png',
                            width: 30, height: 30),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(Icons.add_circle_outline, color: AppColors.blue5),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() {
                final localStart = bookingRideController.localStartTime.value;
                final localEnd = bookingRideController.localEndTime.value;
            
                return Column(
                  children: [
                    DatePickerTile(
                      label: 'Pickup Date',
                      initialDate: localStart,
                      onDateSelected: (pickedDate) {
                        final updated = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          localStart.hour,
                          localStart.minute,
                        );
                        updateLocalStartTime(updated);
            
                        // If drop is same day and violates 4hr rule, auto adjust
                        final minDrop = updated.add(const Duration(hours: 4));
                        final drop = bookingRideController.localEndTime.value;
                        if (DateUtils.isSameDay(drop, updated) &&
                            drop.isBefore(minDrop)) {
                          updateLocalEndTime(minDrop);
                          bookingRideController.localEndTime.refresh();
                        }
            
                        bookingRideController.localStartTime.refresh();
                      },
                      controller: placeSearchController,
                    ),
                    const SizedBox(height: 16),
                    TimePickerTile(
                      label: 'Pickup Time',
                      initialTime: localStart,
                      onTimeSelected: (pickedTime) {
                        final updatedPickup = DateTime(
                          localStart.year,
                          localStart.month,
                          localStart.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
            
                        updateLocalStartTime(updatedPickup);
                        bookingRideController.localStartTime.refresh();
            
                        final minAllowedDrop =
                            updatedPickup.add(const Duration(hours: 4));
                        final existingDrop =
                            bookingRideController.localEndTime.value;
            
                        final isSameDay =
                            DateUtils.isSameDay(updatedPickup, existingDrop);
                        final isDropBeforeMin =
                            existingDrop.isBefore(minAllowedDrop);
            
                        if (isSameDay && isDropBeforeMin) {
                          updateLocalEndTime(minAllowedDrop);
                          bookingRideController.localEndTime.refresh();
                        }
                      },
                      controller: placeSearchController,
                    ),
                    if (showDropDateTime) ...[
                      const SizedBox(height: 16),
                      DateTimePickerTile(
                        label: 'Drop Date',
                        initialDateTime: localEnd.isBefore(
                                localStart.add(const Duration(hours: 4)))
                            ? localStart.add(const Duration(hours: 4))
                            : localEnd,
                        minimumDate: localStart.add(const Duration(hours: 4)),
                        onDateTimeSelected: (picked) {
                          final minDrop = bookingRideController
                              .localStartTime.value
                              .add(const Duration(hours: 4));

                          final updated =
                              picked.isBefore(minDrop) ? minDrop : picked;

                          updateLocalEndTime(updated);
                          bookingRideController.localEndTime.refresh();
                        },
                      ),
                    ]
                  ],
                );
              }),
            ),
            SizedBox(height: 28,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Obx(() {
                    final pickupId = placeSearchController.placeId.value;
                    final dropId = dropPlaceSearchController.dropPlaceId.value;
            
                    final samePlace = pickupId.isNotEmpty &&
                        dropId.isNotEmpty &&
                        pickupId == dropId;
            
                    final hasSourceError = placeSearchController
                        .findCntryDateTimeResponse.value?.sourceInput ==
                        true ||
                        dropPlaceSearchController
                            .dropDateTimeResponse.value?.sourceInput ==
                            true;
            
                    final hasDestinationError = placeSearchController
                        .findCntryDateTimeResponse
                        .value
                        ?.destinationInputFalse ==
                        true ||
                        dropPlaceSearchController.dropDateTimeResponse.value
                            ?.destinationInputFalse ==
                            true;
            
                    final isPlaceMissing = pickupId.isEmpty || dropId.isEmpty;
            
                    final canProceed =
                        !samePlace &&
                            !hasSourceError &&
                            !hasDestinationError &&
                            !isPlaceMissing &&
                            (placeSearchController.findCntryDateTimeResponse
                                .value?.goToNextPage ==
                                true ||
                                placeSearchController.findCntryDateTimeResponse
                                    .value?.sameCountry ==
                                    true ||
                                dropPlaceSearchController.dropDateTimeResponse
                                    .value?.sameCountry ==
                                    true ||
                                dropPlaceSearchController.dropDateTimeResponse
                                    .value?.goToNextPage ==
                                    true);
            
                    final forceDisable =
                        samePlace || hasSourceError || hasDestinationError;
            
                    return Opacity(
                      opacity: forceDisable
                          ? 0.6
                          : canProceed
                          ? 1.0
                          : 0.6,
                      child:  PrimaryButton(
                        text: 'Search Now',
                        onPressed: forceDisable || !canProceed
                            ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text(
                                  "Selected drop location is not available for this pickup."),
                            ),
                          );
                        } // 🔒 do nothing
                            : () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const PopupLoader(),
                          );
                          // final typesJson = await StorageServices.instance.read('sourceTypes');
                          // final List<String> types = typesJson != null && typesJson.isNotEmpty
                          //     ? List<String>.from(jsonDecode(typesJson))
                          //     : [];
                          //
                          // final termsJson = await StorageServices.instance.read('sourceTerms');
                          // final List<Map<String, dynamic>> terms = termsJson != null && termsJson.isNotEmpty
                          //     ? List<Map<String, dynamic>>.from(jsonDecode(termsJson))
                          //     : [];
            
                          // current date, time and offset
                          final now = DateTime.now();
            //
            // // ✅ Format date and time
                          final String searchDate = now
                              .toIso8601String()
                              .split('T')
                              .first; // "YYYY-MM-DD"
                          final String searchTime =
                              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
            
            // ✅ Get timezone offset in minutes (e.g., 330 for +05:30)
                          final int offset = now.timeZoneOffset.inMinutes;
            //
            //                         final int tripCode = (selectedTrip == 'oneWay') ? 0 : 1;
            //                         print('storage trip code : $tripCode');
            //
            // // ✅ Save all
            //                        print('storage $searchDate, $searchTime, $offset');
            //
            //                        // print('✅ Stored Source Data:');
            //                        // print('📌 types     : $types');
            //                        // print('📌 terms     : $terms');
            //                        // for (var term in terms) {
            //                        //   print('🔸 term => offset: ${term['offset']}, value: ${term['value']}');
            //                        // }
            //
            
                          final country = await StorageServices.instance
                              .read('country');
                          final userOffset = await StorageServices
                              .instance
                              .read('userOffset');
                          final userDateTime = await StorageServices
                              .instance
                              .read('userDateTime');
                          final userTimeWithOffset = await StorageServices
                              .instance
                              .read('userTimeWithOffset');
                          final actualTimeWithOffset =
                          await StorageServices.instance
                              .read('actualTimeWithOffset');
                          final actualOffset = await StorageServices
                              .instance
                              .read('actualOffset');
                          final timeZone = await StorageServices.instance
                              .read('timeZone');
                          final sourceTitle = await StorageServices
                              .instance
                              .read('sourceTitle');
                          final sourcePlaceId = await StorageServices
                              .instance
                              .read('sourcePlaceId');
                          final sourceCity = await StorageServices
                              .instance
                              .read('sourceCity');
                          final sourceState = await StorageServices
                              .instance
                              .read('sourceState');
                          final sourceCountry = await StorageServices
                              .instance
                              .read('country');
                          final sourceLat = await StorageServices.instance
                              .read('sourceLat');
                          final sourceLng = await StorageServices.instance
                              .read('sourceLng');
                          // source type and terms
                          final typesJson = await StorageServices.instance
                              .read('sourceTypes');
                          final List<String> sourceTypes = typesJson !=
                              null &&
                              typesJson.isNotEmpty
                              ? List<String>.from(jsonDecode(typesJson))
                              : [];
            
                          final termsJson = await StorageServices.instance
                              .read('sourceTerms');
                          final List<Map<String, dynamic>> sourceTerms =
                          termsJson != null && termsJson.isNotEmpty
                              ? List<Map<String, dynamic>>.from(
                              jsonDecode(termsJson))
                              : [];
            
                          //destination type and terms
                          final destinationPlaceId = await StorageServices
                              .instance
                              .read('destinationPlaceId');
                          final destinationTitle = await StorageServices
                              .instance
                              .read('destinationTitle');
                          final destinationCity = await StorageServices
                              .instance
                              .read('destinationCity');
                          final destinationState = await StorageServices
                              .instance
                              .read('destinationState');
                          final destinationCountry = await StorageServices
                              .instance
                              .read('destinationCountry');
            
                          final destinationTypesJson =
                          await StorageServices.instance
                              .read('destinationTypes');
                          final destinationTermsJson =
                          await StorageServices.instance
                              .read('destinationTerms');
            
            // Decode JSON strings to actual List or Map types (if applicable)
                          final List<String> destinationType =
                          destinationTypesJson != null &&
                              destinationTypesJson.isNotEmpty
                              ? List<String>.from(
                              jsonDecode(destinationTypesJson))
                              : [];
                          final List<Map<String, dynamic>>
                          destinationTerms =
                          destinationTermsJson != null &&
                              destinationTermsJson.isNotEmpty
                              ? List<Map<String, dynamic>>.from(
                              jsonDecode(destinationTermsJson))
                              : [];
                          final destinationLat = await StorageServices
                              .instance
                              .read('destinationLat');
                          final destinationLng = await StorageServices
                              .instance
                              .read('destinationLng');

                        final returnDateTimeISO =  await StorageServices.instance.read('drop_round_trip_iso');
                          final returnDateTimeUTC = await StorageServices.instance.read('drop_round_trip_utc');
            
                          final Map<String, dynamic> requestData = (selectedTrip == 'oneWay') ? {
                            "timeOffSet": -offset,
                            "countryName": country,
                            "searchDate": searchDate,
                            "searchTime": searchTime,
                            "offset": int.parse(userOffset ?? ''),
                            "pickupDateAndTime": userDateTime,
                            "returnDateAndTime": "",
                            "tripCode": "0",
                            "source": {
                              "sourceTitle": sourceTitle,
                              "sourcePlaceId": sourcePlaceId,
                              "sourceCity": sourceCity,
                              "sourceState": sourceState,
                              "sourceCountry": sourceCountry,
                              "sourceType": sourceTypes,
                              "sourceLat": sourceLat,
                              "sourceLng": sourceLng,
                              "terms": sourceTerms
                            },
                            "destination": {
                              "destinationTitle": destinationTitle,
                              "destinationPlaceId": destinationPlaceId,
                              "destinationCity": destinationCity,
                              "destinationState": destinationState,
                              "destinationCountry": destinationCountry,
                              "destinationType": destinationType,
                              "destinationLat": destinationLat,
                              "destinationLng": destinationLng,
                              "terms": destinationTerms
                            },
                            "packageSelected": {"km": "", "hours": ""},
                            "stopsArray": [],
                            "pickUpTime": {
                              "time": actualTimeWithOffset,
                              "offset": actualOffset,
                              "timeZone": timeZone
                            },
                            "dropTime": {},
                            "mindate": {
                              "date": userTimeWithOffset,
                              "time": userTimeWithOffset,
                              "offset": userOffset,
                              "timeZone": timeZone
                            },
                            "isGlobal":
                            (country?.toLowerCase() == 'india')
                                ? false
                                : true
                          } : {
                            "timeOffSet": -offset,
                            "countryName": country,
                            "searchDate": searchDate,
                            "searchTime": searchTime,
                            "offset": int.parse(userOffset ?? ''),
                            "pickupDateAndTime": userDateTime,
                            "returnDateAndTime": returnDateTimeUTC,
                            "tripCode": "1",
                            "source": {
                              "sourceTitle": sourceTitle,
                              "sourcePlaceId": sourcePlaceId,
                              "sourceCity": sourceCity,
                              "sourceState": sourceState,
                              "sourceCountry": sourceCountry,
                              "sourceType": sourceTypes,
                              "sourceLat": sourceLat,
                              "sourceLng": sourceLng,
                              "terms": sourceTerms
                            },
                            "destination": {
                              "destinationTitle": destinationTitle,
                              "destinationPlaceId": destinationPlaceId,
                              "destinationCity": destinationCity,
                              "destinationState": destinationState,
                              "destinationCountry": destinationCountry,
                              "destinationType": destinationType,
                              "destinationLat": destinationLat,
                              "destinationLng": destinationLng,
                              "terms": destinationTerms
                            },
                            "packageSelected": {"km": "", "hours": ""},
                            "stopsArray": [],
                            "pickUpTime": {
                              "time": actualTimeWithOffset,
                              "offset": actualOffset,
                              "timeZone": timeZone
                            },
                            "dropTime": {
                              "time": returnDateTimeISO,
                              "offset": actualOffset,
                              "timeZone": timeZone
                            },
                            "mindate": {
                              "date": userTimeWithOffset,
                              "time": userTimeWithOffset,
                              "offset": userOffset,
                              "timeZone": timeZone
                            },
                            "isGlobal":
                            (country?.toLowerCase() == 'india')
                                ? false
                                : true
                          };
            
                          searchCabInventoryController.fetchBookingData(
                              country: country!,
                              requestData: requestData,
                              context: context, isSecondPage: false);
                          // ✅ Proceed with booking
                          if (Navigator.of(context, rootNavigator: true).canPop()) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                      ),
                    );
                  })),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String title, String value, bool isSelected) {
    return InkWell(
      onTap: () async {
        setState(() => selectedTrip = value);
      },
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Radio<String>(
              value: value,
              groupValue: selectedTrip,
              onChanged: (val) => setState(() => selectedTrip = val!),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.lightGrey1,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
        height: 32,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.grey.withOpacity(0.3),
      );
}

// airport cabs
class Rides extends StatefulWidget {
  const Rides({super.key});

  @override
  State<Rides> createState() => _RidesState();
}

class _RidesState extends State<Rides> {
  final BookingRideController bookingRideController =
  Get.put(BookingRideController());
  final PlaceSearchController placeSearchController =
  Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController =
  Get.put(DropPlaceSearchController());
  final SearchCabInventoryController searchCabInventoryController =
  Get.put(SearchCabInventoryController());
  final RxString selectedField = ''.obs;

  // Declare TextEditingControllers as class-level variables
  late TextEditingController ridePickupController;
  late TextEditingController rideDropController;
  late Worker _ridePickupWorker;
  late Worker _rideDropWorker;

  void switchPickupAndDrop({
    required BuildContext context,
    required TextEditingController pickupController,
    required TextEditingController dropController,
  }) async {
    print('switch button hit ho gya hai');
    // Step 1: Swap place IDs
    final oldPickupId = placeSearchController.placeId.value;
    final oldDropId = dropPlaceSearchController.dropPlaceId.value;
    placeSearchController.placeId.value = oldDropId;
    dropPlaceSearchController.dropPlaceId.value = oldPickupId;

    // Step 2: Swap prefilled values (shown in UI + used in controllers)
    final oldPickupText = bookingRideController.prefilled.value;
    final oldDropText = bookingRideController.prefilledDrop.value;
    bookingRideController.prefilled.value = oldDropText;
    bookingRideController.prefilledDrop.value = oldPickupText;

    // Step 3: Update text controllers (if used in text fields)
    pickupController.text = bookingRideController.prefilled.value;
    dropController.text = bookingRideController.prefilledDrop.value;

    // Step 4: Re-fetch lat/lng details based on new placeIds
    if (placeSearchController.placeId.value.isNotEmpty) {
      placeSearchController.getLatLngDetails(placeSearchController.placeId.value, context);
    }
    if (dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
      dropPlaceSearchController.getLatLngForDrop(dropPlaceSearchController.dropPlaceId.value, context);
    }

    // Swap stored values (local storage)
    final sourceKeys = [
      'sourcePlaceId', 'sourceTitle', 'sourceCity', 'sourceState', 'sourceCountry', 'sourceTypes', 'sourceTerms'
    ];
    final destinationKeys = [
      'destinationPlaceId', 'destinationTitle', 'destinationCity', 'destinationState', 'destinationCountry', 'destinationTypes', 'destinationTerms'
    ];

    for (int i = 0; i < sourceKeys.length; i++) {
      final srcKey = sourceKeys[i];
      final destKey = destinationKeys[i];

      final srcVal = await StorageServices.instance.read(srcKey);
      final destVal = await StorageServices.instance.read(destKey);

      await StorageServices.instance.save(srcKey, destVal ?? '');
      await StorageServices.instance.save(destKey, srcVal ?? '');
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    ridePickupController =
        TextEditingController(text: bookingRideController.prefilled.value);
    rideDropController =
        TextEditingController(text: bookingRideController.prefilledDrop.value);


    // Listen to changes in prefilled and prefilledDrop to update controllers
    _ridePickupWorker = ever(bookingRideController.prefilled, (String value) {
      if (ridePickupController.text != value) {
        ridePickupController.text = value;
      }
    });
    _rideDropWorker = ever(bookingRideController.prefilledDrop, (String value) {
      if (rideDropController.text != value) {
        rideDropController.text = value;
      }
    });
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _ridePickupWorker.dispose();
    _rideDropWorker.dispose();
    ridePickupController.dispose();
    rideDropController.dispose();
    super.dispose();
  }

  DateTime getLocalDateTime() {
    final userDateTimeStr = placeSearchController
        .findCntryDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final offset = placeSearchController
        .findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (userDateTimeStr != null) {
      try {
        final utc = DateTime.parse(userDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0));
      } catch (e) {
        print("Error parsing userDateTime: $e");
      }
    }
    return bookingRideController.localStartTime.value;
  }

  DateTime getInitialDateTime() {
    final actualDateTimeStr = placeSearchController
        .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime;
    final offset = placeSearchController
        .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet;

    if (actualDateTimeStr != null) {
      try {
        final utc = DateTime.parse(actualDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0));
      } catch (e) {
        print("Error parsing actualDateTime: $e");
      }
    }
    return getLocalDateTime();
  }

  DateTime getDropLocalDateTime() {
    final dropDateTimeStr = dropPlaceSearchController
        .dropDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final dropOffset = dropPlaceSearchController
        .dropDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (dropDateTimeStr != null) {
      try {
        final utc = DateTime.parse(dropDateTimeStr).toUtc();
        return utc.add(Duration(minutes: dropOffset ?? 0));
      } catch (_) {}
    }
    return bookingRideController.localStartTime.value
        .add(const Duration(hours: 4));
  }

  void updateLocalStartTime(DateTime newDateTime) {
    final timezone =
        placeSearchController.findCntryDateTimeResponse.value?.timeZone ??
            placeSearchController.getCurrentTimeZoneName();
    final offset = placeSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localStartTime.value = newDateTime;
    bookingRideController.utcStartTime.value =
        newDateTime.subtract(Duration(minutes: offset));
  }

  void updateLocalEndTime(DateTime newDateTime) {
    final timezone =
        dropPlaceSearchController.dropDateTimeResponse.value?.timeZone ??
            dropPlaceSearchController.getCurrentTimeZoneName();
    final offset = dropPlaceSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localEndTime.value = newDateTime;
    bookingRideController.utcEndTime.value =
        newDateTime.subtract(Duration(minutes: offset));
  }

  @override
  Widget build(BuildContext context) {
    return _buildOneWayUI();
  }

  Widget _buildOneWayUI() {
    return _buildPickupDropUI(showDropDateTime: false);
  }

  Widget _buildPickupDropUI({required bool showDropDateTime}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset('assets/images/circle.png', width: 40, height: 120),
                Expanded(
                  child: Obx(() => Column(
                    children: [
                      BookingTextFormField(
                        hintText: 'Enter Pickup Location',
                        controller: ridePickupController,
                        errorText: (() {
                          final placeId =
                              placeSearchController.placeId.value;
                          final dropId =
                              dropPlaceSearchController.dropPlaceId.value;

                          if (placeId.isNotEmpty &&
                              dropId.isNotEmpty &&
                              placeId == dropId) {
                            return "Pickup and Drop cannot be the same";
                          }

                          if (placeSearchController
                              .findCntryDateTimeResponse
                              .value
                              ?.sourceInput ==
                              true ||
                              dropPlaceSearchController.dropDateTimeResponse
                                  .value?.sourceInput ==
                                  true) {
                            return "We don't offer services from this region";
                          }

                          return null;
                        })(),
                        onTap: () async {
                          await GoRouter.of(context)
                              .push(AppRoutes.choosePickup);
                        },
                      ),
                      const SizedBox(height: 12),
                      BookingTextFormField(
                        hintText: 'Enter Drop Location',
                        controller: rideDropController,
                        errorText: (() {
                          final pickupId =
                              placeSearchController.placeId.value;
                          final dropId =
                              dropPlaceSearchController.dropPlaceId.value;

                          if (pickupId.isNotEmpty &&
                              dropId.isNotEmpty &&
                              pickupId == dropId) {
                            return "Pickup and Drop cannot be the same";
                          }

                          if (placeSearchController
                              .findCntryDateTimeResponse
                              .value
                              ?.destinationInputFalse ==
                              true ||
                              dropPlaceSearchController.dropDateTimeResponse
                                  .value?.destinationInputFalse ==
                                  true) {
                            return "We don't offer services from this region";
                          }

                          return null;
                        })(),
                        onTap: () =>
                            GoRouter.of(context).push(AppRoutes.chooseDrop),
                      ),
                    ],
                  )),
                ),
                Column(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.blue5),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: (){
                        switchPickupAndDrop(context: context, pickupController: ridePickupController, dropController: rideDropController);
                      },
                      child: Transform.translate(
                        offset: const Offset(0, 0),
                        child: Image.asset('assets/images/interchange.png',
                            width: 30, height: 30),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(Icons.add_circle_outline, color: AppColors.blue5),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() {
                final localStartTime =
                    bookingRideController.localStartTime.value;
                final dropoffDateTime = getDropLocalDateTime();

                final dynamic activeController = selectedField.value == 'drop'
                    ? dropPlaceSearchController
                    : placeSearchController;

                return Column(
                  children: [
                    DatePickerTile(
                      label: 'Pickup Date',
                      initialDate: localStartTime,
                      onDateSelected: (newDate) {
                        final actualDateTimeStr = placeSearchController
                            .findCntryDateTimeResponse
                            .value
                            ?.actualDateTimeObject
                            ?.actualDateTime;

                        if (actualDateTimeStr != null) {
                          final actualMinDateTime =
                          DateTime.parse(actualDateTimeStr).toLocal();

                          if (DateUtils.isSameDay(newDate, actualMinDateTime)) {
                            final updatedTime = DateTime(
                              newDate.year,
                              newDate.month,
                              newDate.day,
                              actualMinDateTime.hour,
                              actualMinDateTime.minute,
                            );

                            if (!updatedTime.isAtSameMomentAs(
                                bookingRideController.localStartTime.value)) {
                              updateLocalStartTime(updatedTime);
                            } else {
                              bookingRideController.localStartTime.refresh();
                            }
                          } else {
                            final newDateTime = DateTime(
                              newDate.year,
                              newDate.month,
                              newDate.day,
                              localStartTime.hour,
                              localStartTime.minute,
                            );
                            updateLocalStartTime(newDateTime);
                          }
                        } else {
                          final newDateTime = DateTime(
                            newDate.year,
                            newDate.month,
                            newDate.day,
                            localStartTime.hour,
                            localStartTime.minute,
                          );
                          updateLocalStartTime(newDateTime);
                        }
                      },
                      controller: placeSearchController,
                    ),
                    const SizedBox(height: 16),
                    TimePickerTile(
                      label: 'Pickup Time',
                      initialTime: localStartTime,
                      onTimeSelected: (newTime) {
                        final updatedTime = DateTime(
                          localStartTime.year,
                          localStartTime.month,
                          localStartTime.day,
                          newTime.hour,
                          newTime.minute,
                        );

                        if (!updatedTime.isAtSameMomentAs(
                            bookingRideController.localStartTime.value)) {
                          updateLocalStartTime(updatedTime);
                          bookingRideController.localStartTime
                              .refresh(); // 🔁 Force rebuild on same value
                        } else {
                          bookingRideController.localStartTime
                              .refresh(); // 🔁 Force rebuild on same value
                        }
                      },
                      controller: placeSearchController,
                    ),
                    if (showDropDateTime) ...[
                      const SizedBox(height: 16),
                      DateTimePickerTile(
                        label: 'Dropoff Date & Time',
                        initialDateTime: dropoffDateTime,
                        onDateTimeSelected: (pickedDateTime) {
                          if (pickedDateTime.isBefore(
                              localStartTime.add(const Duration(hours: 4)))) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text(
                                  'Dropoff time must be at least 4 hours after pickup time.'),
                            ));
                            return;
                          }
                          updateLocalEndTime(pickedDateTime);
                        },
                      ),
                    ],
                  ],
                );
              }),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final pickupId = placeSearchController.placeId.value;
                  final dropId = dropPlaceSearchController.dropPlaceId.value;

                  final samePlace = pickupId.isNotEmpty &&
                      dropId.isNotEmpty &&
                      pickupId == dropId;

                  final hasSourceError = placeSearchController
                      .findCntryDateTimeResponse.value?.sourceInput ==
                      true ||
                      dropPlaceSearchController
                          .dropDateTimeResponse.value?.sourceInput ==
                          true;

                  final hasDestinationError = placeSearchController
                      .findCntryDateTimeResponse
                      .value
                      ?.destinationInputFalse ==
                      true ||
                      dropPlaceSearchController.dropDateTimeResponse.value
                          ?.destinationInputFalse ==
                          true;

                  final isPlaceMissing = pickupId.isEmpty || dropId.isEmpty;

                  final canProceed = !samePlace &&
                      !hasSourceError &&
                      !hasDestinationError &&
                      !isPlaceMissing &&
                      (placeSearchController
                          .findCntryDateTimeResponse.value?.goToNextPage ==
                          true ||
                          placeSearchController.findCntryDateTimeResponse.value
                              ?.sameCountry ==
                              true ||
                          dropPlaceSearchController
                              .dropDateTimeResponse.value?.sameCountry ==
                              true ||
                          dropPlaceSearchController
                              .dropDateTimeResponse.value?.goToNextPage ==
                              true);

                  final forceDisable =
                      samePlace || hasSourceError || hasDestinationError;

                  return Opacity(
                    opacity: forceDisable
                        ? 0.6
                        : canProceed
                        ? 1.0
                        : 0.6,
                    child: PrimaryButton(
                      text: 'Search Now',
                      onPressed: forceDisable || !canProceed
                          ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text(
                                "Selected drop location is not available for this pickup."),
                          ),
                        );
                      }
                          : () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const PopupLoader(),
                        );
                        // final typesJson = await StorageServices.instance.read('sourceTypes');
                        // final List<String> types = typesJson != null && typesJson.isNotEmpty
                        //     ? List<String>.from(jsonDecode(typesJson))
                        //     : [];
                        //
                        // final termsJson = await StorageServices.instance.read('sourceTerms');
                        // final List<Map<String, dynamic>> terms = termsJson != null && termsJson.isNotEmpty
                        //     ? List<Map<String, dynamic>>.from(jsonDecode(termsJson))
                        //     : [];

                        // current date, time and offset
                        final now = DateTime.now();
//
// // ✅ Format date and time
                        final String searchDate = now
                            .toIso8601String()
                            .split('T')
                            .first; // "YYYY-MM-DD"
                        final String searchTime =
                            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

// ✅ Get timezone offset in minutes (e.g., 330 for +05:30)
                        final int offset = now.timeZoneOffset.inMinutes;
//
//                         final int tripCode = (selectedTrip == 'oneWay') ? 0 : 1;
//                         print('storage trip code : $tripCode');
//
// // ✅ Save all
//                        print('storage $searchDate, $searchTime, $offset');
//
//                        // print('✅ Stored Source Data:');
//                        // print('📌 types     : $types');
//                        // print('📌 terms     : $terms');
//                        // for (var term in terms) {
//                        //   print('🔸 term => offset: ${term['offset']}, value: ${term['value']}');
//                        // }
//

                        final country = await StorageServices.instance
                            .read('country');
                        final userOffset = await StorageServices.instance
                            .read('userOffset');
                        final userDateTime = await StorageServices
                            .instance
                            .read('userDateTime');
                        final userTimeWithOffset = await StorageServices
                            .instance
                            .read('userTimeWithOffset');
                        final actualTimeWithOffset = await StorageServices
                            .instance
                            .read('actualTimeWithOffset');
                        final actualOffset = await StorageServices
                            .instance
                            .read('actualOffset');
                        final timeZone = await StorageServices.instance
                            .read('timeZone');
                        final sourceTitle = await StorageServices.instance
                            .read('sourceTitle');
                        final sourcePlaceId = await StorageServices
                            .instance
                            .read('sourcePlaceId');
                        final sourceCity = await StorageServices.instance
                            .read('sourceCity');
                        final sourceState = await StorageServices.instance
                            .read('sourceState');
                        final sourceCountry = await StorageServices
                            .instance
                            .read('country');
                        final sourceLat = await StorageServices.instance
                            .read('sourceLat');
                        final sourceLng = await StorageServices.instance
                            .read('sourceLng');
                        // source type and terms
                        final typesJson = await StorageServices.instance
                            .read('sourceTypes');
                        final List<String> sourceTypes =
                        typesJson != null && typesJson.isNotEmpty
                            ? List<String>.from(jsonDecode(typesJson))
                            : [];

                        final termsJson = await StorageServices.instance
                            .read('sourceTerms');
                        final List<Map<String, dynamic>> sourceTerms =
                        termsJson != null && termsJson.isNotEmpty
                            ? List<Map<String, dynamic>>.from(
                            jsonDecode(termsJson))
                            : [];

                        //destination type and terms
                        final destinationPlaceId = await StorageServices
                            .instance
                            .read('destinationPlaceId');
                        final destinationTitle = await StorageServices
                            .instance
                            .read('destinationTitle');
                        final destinationCity = await StorageServices
                            .instance
                            .read('destinationCity');
                        final destinationState = await StorageServices
                            .instance
                            .read('destinationState');
                        final destinationCountry = await StorageServices
                            .instance
                            .read('destinationCountry');

                        final destinationTypesJson = await StorageServices
                            .instance
                            .read('destinationTypes');
                        final destinationTermsJson = await StorageServices
                            .instance
                            .read('destinationTerms');

// Decode JSON strings to actual List or Map types (if applicable)
                        final List<String> destinationType =
                        destinationTypesJson != null &&
                            destinationTypesJson.isNotEmpty
                            ? List<String>.from(
                            jsonDecode(destinationTypesJson))
                            : [];
                        final List<Map<String, dynamic>>
                        destinationTerms =
                        destinationTermsJson != null &&
                            destinationTermsJson.isNotEmpty
                            ? List<Map<String, dynamic>>.from(
                            jsonDecode(destinationTermsJson))
                            : [];
                        final destinationLat = await StorageServices
                            .instance
                            .read('destinationLat');
                        final destinationLng = await StorageServices
                            .instance
                            .read('destinationLng');

                        final Map<String, dynamic> requestData = {
                          "timeOffSet": -offset,
                          "countryName": country,
                          "searchDate": searchDate,
                          "searchTime": searchTime,
                          "offset": int.parse(userOffset ?? ''),
                          "pickupDateAndTime": userDateTime,
                          "returnDateAndTime": "",
                          "tripCode": "2",
                          "source": {
                            "sourceTitle": sourceTitle,
                            "sourcePlaceId": sourcePlaceId,
                            "sourceCity": sourceCity,
                            "sourceState": sourceState,
                            "sourceCountry": sourceCountry,
                            "sourceType": sourceTypes,
                            "sourceLat": sourceLat,
                            "sourceLng": sourceLng,
                            "terms": sourceTerms
                          },
                          "destination": {
                            "destinationTitle": destinationTitle,
                            "destinationPlaceId": destinationPlaceId,
                            "destinationCity": destinationCity,
                            "destinationState": destinationState,
                            "destinationCountry": destinationCountry,
                            "destinationType": destinationType,
                            "destinationLat": destinationLat,
                            "destinationLng": destinationLng,
                            "terms": destinationTerms
                          },
                          "packageSelected": {"km": "", "hours": ""},
                          "stopsArray": [],
                          "pickUpTime": {
                            "time": actualTimeWithOffset,
                            "offset": actualOffset,
                            "timeZone": timeZone
                          },
                          "dropTime": {},
                          "mindate": {
                            "date": userTimeWithOffset,
                            "time": userTimeWithOffset,
                            "offset": userOffset,
                            "timeZone": timeZone
                          },
                          "isGlobal": (country?.toLowerCase() == 'india')
                              ? false
                              : true
                        };

                        searchCabInventoryController.fetchBookingData(
                            country: country!,
                            requestData: requestData,
                            context: context, isSecondPage: false);
                        // ✅ Proceed with booking
                        if (Navigator.of(context, rootNavigator: true).canPop()) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// hourly rental
class Rental extends StatefulWidget {
  const Rental({super.key});

  @override
  State<Rental> createState() => _RentalState();
}

class _RentalState extends State<Rental> {
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  final PlaceSearchController placeSearchController =
      Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController =
      Get.put(DropPlaceSearchController());
  final SearchCabInventoryController searchCabInventoryController =
      Get.put(SearchCabInventoryController());
  final FetchPackageController fetchPackageController =
      Get.put(FetchPackageController());

  final RxString selectedField = ''.obs;

  // Declare TextEditingControllers as class-level variables
  late TextEditingController ridePickupController;
  late TextEditingController rideDropController;

  void switchPickupAndDrop({
    required BuildContext context,
    required TextEditingController pickupController,
    required TextEditingController dropController,
  }) async {
    print('switch button hit ho gya hai');
    // Step 1: Swap place IDs
    final oldPickupId = placeSearchController.placeId.value;
    final oldDropId = dropPlaceSearchController.dropPlaceId.value;
    placeSearchController.placeId.value = oldDropId;
    dropPlaceSearchController.dropPlaceId.value = oldPickupId;

    // Step 2: Swap prefilled values (shown in UI + used in controllers)
    final oldPickupText = bookingRideController.prefilled.value;
    final oldDropText = bookingRideController.prefilledDrop.value;
    bookingRideController.prefilled.value = oldDropText;
    bookingRideController.prefilledDrop.value = oldPickupText;

    // Step 3: Update text controllers (if used in text fields)
    pickupController.text = bookingRideController.prefilled.value;
    dropController.text = bookingRideController.prefilledDrop.value;

    // Step 4: Re-fetch lat/lng details based on new placeIds
    if (placeSearchController.placeId.value.isNotEmpty) {
      placeSearchController.getLatLngDetails(placeSearchController.placeId.value, context);
    }
    if (dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
      dropPlaceSearchController.getLatLngForDrop(dropPlaceSearchController.dropPlaceId.value, context);
    }

    // Swap stored values (local storage)
    final sourceKeys = [
      'sourcePlaceId', 'sourceTitle', 'sourceCity', 'sourceState', 'sourceCountry', 'sourceTypes', 'sourceTerms'
    ];
    final destinationKeys = [
      'destinationPlaceId', 'destinationTitle', 'destinationCity', 'destinationState', 'destinationCountry', 'destinationTypes', 'destinationTerms'
    ];

    for (int i = 0; i < sourceKeys.length; i++) {
      final srcKey = sourceKeys[i];
      final destKey = destinationKeys[i];

      final srcVal = await StorageServices.instance.read(srcKey);
      final destVal = await StorageServices.instance.read(destKey);

      await StorageServices.instance.save(srcKey, destVal ?? '');
      await StorageServices.instance.save(destKey, srcVal ?? '');
    }
  }

  String selectPackage = '';
  late Worker rentalPickupWorker;
  late Worker rentalDropWorker;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    ridePickupController =
        TextEditingController(text: bookingRideController.prefilled.value);
    rideDropController =
        TextEditingController(text: bookingRideController.prefilledDrop.value);

    // Listen to changes in prefilled and prefilledDrop to update controllers
    rentalPickupWorker =  ever(bookingRideController.prefilled, (String value) {
      if (ridePickupController.text != value) {
        ridePickupController.text = value;
      }
    });
   rentalDropWorker = ever(bookingRideController.prefilledDrop, (String value) {
      if (rideDropController.text != value) {
        rideDropController.text = value;
      }
    });
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    rentalPickupWorker.dispose();
    rentalDropWorker.dispose();
    ridePickupController.dispose();
    rideDropController.dispose();
    super.dispose();
  }

  DateTime getLocalDateTime() {
    final userDateTimeStr = placeSearchController
        .findCntryDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final offset = placeSearchController
        .findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (userDateTimeStr != null) {
      try {
        final utc = DateTime.parse(userDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0));
      } catch (e) {
        print("Error parsing userDateTime: $e");
      }
    }
    return bookingRideController.localStartTime.value;
  }

  DateTime getInitialDateTime() {
    final actualDateTimeStr = placeSearchController
        .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime;
    final offset = placeSearchController
        .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet;

    if (actualDateTimeStr != null) {
      try {
        final utc = DateTime.parse(actualDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0));
      } catch (e) {
        print("Error parsing actualDateTime: $e");
      }
    }
    return getLocalDateTime();
  }

  DateTime getDropLocalDateTime() {
    final dropDateTimeStr = dropPlaceSearchController
        .dropDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final dropOffset = dropPlaceSearchController
        .dropDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (dropDateTimeStr != null) {
      try {
        final utc = DateTime.parse(dropDateTimeStr).toUtc();
        return utc.add(Duration(minutes: dropOffset ?? 0));
      } catch (_) {}
    }
    return bookingRideController.localStartTime.value
        .add(const Duration(hours: 4));
  }

  void updateLocalStartTime(DateTime newDateTime) {
    final timezone =
        placeSearchController.findCntryDateTimeResponse.value?.timeZone ??
            placeSearchController.getCurrentTimeZoneName();
    final offset = placeSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localStartTime.value = newDateTime;
    bookingRideController.utcStartTime.value =
        newDateTime.subtract(Duration(minutes: offset));
  }

  void updateLocalEndTime(DateTime newDateTime) {
    final timezone =
        dropPlaceSearchController.dropDateTimeResponse.value?.timeZone ??
            dropPlaceSearchController.getCurrentTimeZoneName();
    final offset = dropPlaceSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localEndTime.value = newDateTime;
    bookingRideController.utcEndTime.value =
        newDateTime.subtract(Duration(minutes: offset));
  }

  @override
  Widget build(BuildContext context) {
    return _buildOneWayUI();
  }

  Widget _buildOneWayUI() {
    return _buildPickupDropUI(showDropDateTime: false);
  }

  Widget _buildPickupDropUI({required bool showDropDateTime}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() => Column(
                          children: [
                            BookingTextFormField(
                              hintText: 'Enter Pickup Location',
                              controller: ridePickupController,
                              errorText: (() {
                                final placeId =
                                    placeSearchController.placeId.value;
                                final dropId =
                                    dropPlaceSearchController.dropPlaceId.value;

                                if (placeId.isNotEmpty &&
                                    dropId.isNotEmpty &&
                                    placeId == dropId) {
                                  return "Pickup and Drop cannot be the same";
                                }

                                if (placeSearchController
                                            .findCntryDateTimeResponse
                                            .value
                                            ?.sourceInput ==
                                        true ||
                                    dropPlaceSearchController
                                            .dropDateTimeResponse
                                            .value
                                            ?.sourceInput ==
                                        true) {
                                  return "We don't offer services from this region";
                                }

                                return null;
                              })(),
                              onTap: () async {
                                await GoRouter.of(context)
                                    .push(AppRoutes.choosePickup);
                              },
                            ),
                          ],
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() {
                final localStartTime =
                    bookingRideController.localStartTime.value;
                final dropoffDateTime = getDropLocalDateTime();

                final dynamic activeController = selectedField.value == 'drop'
                    ? dropPlaceSearchController
                    : placeSearchController;

                return Column(
                  children: [
                    DatePickerTile(
                      label: 'Pickup Date',
                      initialDate: localStartTime,
                      onDateSelected: (newDate) {
                        final actualDateTimeStr = placeSearchController
                            .findCntryDateTimeResponse
                            .value
                            ?.actualDateTimeObject
                            ?.actualDateTime;

                        if (actualDateTimeStr != null) {
                          final actualMinDateTime =
                              DateTime.parse(actualDateTimeStr).toLocal();

                          if (DateUtils.isSameDay(newDate, actualMinDateTime)) {
                            final updatedTime = DateTime(
                              newDate.year,
                              newDate.month,
                              newDate.day,
                              actualMinDateTime.hour,
                              actualMinDateTime.minute,
                            );

                            if (!updatedTime.isAtSameMomentAs(
                                bookingRideController.localStartTime.value)) {
                              updateLocalStartTime(updatedTime);
                            } else {
                              bookingRideController.localStartTime.refresh();
                            }
                          } else {
                            final newDateTime = DateTime(
                              newDate.year,
                              newDate.month,
                              newDate.day,
                              localStartTime.hour,
                              localStartTime.minute,
                            );
                            updateLocalStartTime(newDateTime);
                          }
                        } else {
                          final newDateTime = DateTime(
                            newDate.year,
                            newDate.month,
                            newDate.day,
                            localStartTime.hour,
                            localStartTime.minute,
                          );
                          updateLocalStartTime(newDateTime);
                        }
                      },
                      controller: placeSearchController,
                    ),
                    const SizedBox(height: 16),
                    TimePickerTile(
                      label: 'Pickup Time',
                      initialTime: localStartTime,
                      onTimeSelected: (newTime) {
                        final updatedTime = DateTime(
                          localStartTime.year,
                          localStartTime.month,
                          localStartTime.day,
                          newTime.hour,
                          newTime.minute,
                        );

                        if (!updatedTime.isAtSameMomentAs(
                            bookingRideController.localStartTime.value)) {
                          updateLocalStartTime(updatedTime);
                          bookingRideController.localStartTime
                              .refresh(); // 🔁 Force rebuild on same value
                        } else {
                          bookingRideController.localStartTime
                              .refresh(); // 🔁 Force rebuild on same value
                        }
                      },
                      controller: placeSearchController,
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            Obx(() {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CustomDropdownField(
                  hintText: 'Select Packages',
                  items: fetchPackageController.packageModel.value?.data
                          .map((value) =>
                              '${value.hours} hrs, ${value.kilometers} kms')
                          .toList() ??
                      [],
                  onChanged: (value) async {
                    final selectedValue = value ?? '';

                    print('✅ Selected package is: $selectedValue');

                    // Extract hours and kms
                    final packageRegex =
                        RegExp(r'(\d+)\s*hrs?,\s*(\d+)\s*kms?');
                    final match = packageRegex.firstMatch(selectedValue);

                    if (match != null) {
                      final extractedHours = int.tryParse(match.group(1)!);
                      final extractedKms = int.tryParse(match.group(2)!);

                      print('📦 Extracted Hours: $extractedHours');
                      print('📦 Extracted KMs: $extractedKms');

                      // Optional: store them individually if needed
                      await StorageServices.instance
                          .save('selectedHours', extractedHours.toString());
                      await StorageServices.instance
                          .save('selectedKms', extractedKms.toString());
                    } else {
                      print(
                          '⚠️ Could not extract hrs and kms from "$selectedValue"');
                    }

                    // Update state last
                    setState(() {
                      selectPackage = selectedValue;
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final pickupId = placeSearchController.placeId.value;

                  final hasSourceError = placeSearchController
                          .findCntryDateTimeResponse.value?.sourceInput ==
                      true;

                  final isPlaceMissing = pickupId.isEmpty;

                  final canProceed = !hasSourceError &&
                      !isPlaceMissing &&
                      (placeSearchController
                                  .findCntryDateTimeResponse.value?.goToNextPage ==
                              true ||
                          placeSearchController.findCntryDateTimeResponse.value
                                  ?.sameCountry ==
                              true ||
                          dropPlaceSearchController
                                  .dropDateTimeResponse.value?.sameCountry ==
                              true ||
                          dropPlaceSearchController
                                  .dropDateTimeResponse.value?.goToNextPage ==
                              true);

                  final forceDisable = hasSourceError;

                  return Opacity(
                    opacity: forceDisable
                        ? 0.6
                        : canProceed
                            ? 1.0
                            : 0.6,
                    child: PrimaryButton(
                      text: 'Search Now',
                      onPressed: forceDisable || !canProceed
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text(
                                      "Selected drop location is not available for this pickup."),
                                ),
                              );
                            }
                          : () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const PopupLoader(),
                        );
                              // final typesJson = await StorageServices.instance.read('sourceTypes');
                              // final List<String> types = typesJson != null && typesJson.isNotEmpty
                              //     ? List<String>.from(jsonDecode(typesJson))
                              //     : [];
                              //
                              // final termsJson = await StorageServices.instance.read('sourceTerms');
                              // final List<Map<String, dynamic>> terms = termsJson != null && termsJson.isNotEmpty
                              //     ? List<Map<String, dynamic>>.from(jsonDecode(termsJson))
                              //     : [];

                              // current date, time and offset
                              final now = DateTime.now();
//
// // ✅ Format date and time
                              final String searchDate = now
                                  .toIso8601String()
                                  .split('T')
                                  .first; // "YYYY-MM-DD"
                              final String searchTime =
                                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

// ✅ Get timezone offset in minutes (e.g., 330 for +05:30)
                              final int offset = now.timeZoneOffset.inMinutes;
//
//                         final int tripCode = (selectedTrip == 'oneWay') ? 0 : 1;
//                         print('storage trip code : $tripCode');
//
// // ✅ Save all
//                        print('storage $searchDate, $searchTime, $offset');
//
//                        // print('✅ Stored Source Data:');
//                        // print('📌 types     : $types');
//                        // print('📌 terms     : $terms');
//                        // for (var term in terms) {
//                        //   print('🔸 term => offset: ${term['offset']}, value: ${term['value']}');
//                        // }
//
                              Map<String, dynamic> destinationRental = {};

                              final country = await StorageServices.instance
                                  .read('country');
                              final userOffset = await StorageServices.instance
                                  .read('userOffset');
                              final userDateTime = await StorageServices
                                  .instance
                                  .read('userDateTime');
                              final userTimeWithOffset = await StorageServices
                                  .instance
                                  .read('userTimeWithOffset');
                              final actualTimeWithOffset = await StorageServices
                                  .instance
                                  .read('actualTimeWithOffset');
                              final actualOffset = await StorageServices
                                  .instance
                                  .read('actualOffset');
                              final timeZone = await StorageServices.instance
                                  .read('timeZone');
                              final sourceTitle = await StorageServices.instance
                                  .read('sourceTitle');
                              final sourcePlaceId = await StorageServices
                                  .instance
                                  .read('sourcePlaceId');
                              final sourceCity = await StorageServices.instance
                                  .read('sourceCity');
                              final sourceState = await StorageServices.instance
                                  .read('sourceState');
                              final sourceCountry = await StorageServices
                                  .instance
                                  .read('country');
                              final sourceLat = await StorageServices.instance
                                  .read('sourceLat');
                              final sourceLng = await StorageServices.instance
                                  .read('sourceLng');
                              // source type and terms
                              final typesJson = await StorageServices.instance
                                  .read('sourceTypes');
                              final List<String> sourceTypes =
                                  typesJson != null && typesJson.isNotEmpty
                                      ? List<String>.from(jsonDecode(typesJson))
                                      : [];

                              final termsJson = await StorageServices.instance
                                  .read('sourceTerms');
                              final List<Map<String, dynamic>> sourceTerms =
                                  termsJson != null && termsJson.isNotEmpty
                                      ? List<Map<String, dynamic>>.from(
                                          jsonDecode(termsJson))
                                      : [];

                              //destination type and terms
                              final destinationPlaceId = await StorageServices
                                  .instance
                                  .read('destinationPlaceId');
                              final destinationTitle = await StorageServices
                                  .instance
                                  .read('destinationTitle');
                              final destinationCity = await StorageServices
                                  .instance
                                  .read('destinationCity');
                              final destinationState = await StorageServices
                                  .instance
                                  .read('destinationState');
                              final destinationCountry = await StorageServices
                                  .instance
                                  .read('destinationCountry');

                              final destinationTypesJson = await StorageServices
                                  .instance
                                  .read('destinationTypes');
                              final destinationTermsJson = await StorageServices
                                  .instance
                                  .read('destinationTerms');
                              final selectPackageData = await StorageServices
                                  .instance
                                  .read('selectPackageData');

// Decode JSON strings to actual List or Map types (if applicable)
                              final List<String> destinationType =
                                  destinationTypesJson != null &&
                                          destinationTypesJson.isNotEmpty
                                      ? List<String>.from(
                                          jsonDecode(destinationTypesJson))
                                      : [];
                              final List<Map<String, dynamic>>
                                  destinationTerms =
                                  destinationTermsJson != null &&
                                          destinationTermsJson.isNotEmpty
                                      ? List<Map<String, dynamic>>.from(
                                          jsonDecode(destinationTermsJson))
                                      : [];
                              final destinationLat = await StorageServices
                                  .instance
                                  .read('destinationLat');
                              final destinationLng = await StorageServices
                                  .instance
                                  .read('destinationLng');
                              final packageHrs = await StorageServices.instance
                                  .read('selectedHours');
                              final packageKms = await StorageServices.instance
                                  .read('selectedKms');

                              final Map<String, dynamic> requestData = {
                                "timeOffSet": -offset,
                                "countryName": country,
                                "searchDate": searchDate,
                                "searchTime": searchTime,
                                "offset": int.parse(userOffset ?? ''),
                                "pickupDateAndTime": userDateTime,
                                "returnDateAndTime": "",
                                "tripCode": "3",
                                "source": {
                                  "sourceTitle": sourceTitle,
                                  "sourcePlaceId": sourcePlaceId,
                                  "sourceCity": sourceCity,
                                  "sourceState": sourceState,
                                  "sourceCountry": sourceCountry,
                                  "sourceType": sourceTypes,
                                  "sourceLat": sourceLat,
                                  "sourceLng": sourceLng,
                                  "terms": sourceTerms
                                },
                                "destination": destinationRental,
                                "packageSelected": {
                                  "km": packageKms,
                                  "hours": packageHrs
                                },
                                "stopsArray": [],
                                "pickUpTime": {
                                  "time": actualTimeWithOffset,
                                  "offset": actualOffset,
                                  "timeZone": timeZone
                                },
                                "dropTime": {},
                                "mindate": {
                                  "date": userTimeWithOffset,
                                  "time": userTimeWithOffset,
                                  "offset": userOffset,
                                  "timeZone": timeZone
                                },
                                "isGlobal": (country?.toLowerCase() == 'india')
                                    ? false
                                    : true
                              };



                              searchCabInventoryController.fetchBookingData(
                                  country: country!,
                                  requestData: requestData,
                                  context: context, isSecondPage: false);
                              // ✅ Proceed with booking
                        if (Navigator.of(context, rootNavigator: true).canPop()) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                            },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
