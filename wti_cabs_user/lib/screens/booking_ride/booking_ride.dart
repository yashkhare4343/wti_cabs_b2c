
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/common_widget/buttons/primary_button.dart';
import 'package:wti_cabs_user/common_widget/datepicker/date_picker_tile.dart';
import 'package:wti_cabs_user/common_widget/datepicker/date_time_picker.dart';
import 'package:wti_cabs_user/common_widget/dropdown/common_dropdown.dart';
import 'package:wti_cabs_user/common_widget/loader/full_screen_gif/full_screen_gif.dart';
import 'package:wti_cabs_user/common_widget/loader/popup_loader.dart';
import 'package:wti_cabs_user/common_widget/loader/shimmer/shimmer.dart';
import 'package:wti_cabs_user/common_widget/textformfield/booking_textformfield.dart';
import 'package:wti_cabs_user/common_widget/time_picker/time_picker_tile.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/button_state_controller/button_state_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/inventory/search_cab_inventory_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/map_picker/map_picker.dart';
import '../../common_widget/datepicker/drop_date_picker.dart';
import '../../common_widget/time_picker/drop_time_picker.dart';
import '../../core/controller/choose_drop/choose_drop_controller.dart';
import '../../core/controller/rental_controller/fetch_package_controller.dart';
import '../../core/services/storage_services.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class BookingRide extends StatefulWidget {
  final String? initialTab;
  const BookingRide({super.key, this.initialTab});

  @override
  State<BookingRide> createState() => _BookingRideState();
}

class _BookingRideState extends State<BookingRide> {
  final FetchPackageController fetchPackageController =
  Get.put(FetchPackageController());
  final BookingRideController bookingRideController =
  Get.put(BookingRideController());
  final PlaceSearchController placeSearchController =
  Get.put(PlaceSearchController());

  @override
  void initState() {
    super.initState();
    // Initialize controllers to avoid LateInitializationError

    Get.put(BookingRideController());
    Get.put(PlaceSearchController());
    fetchPackageController.fetchPackages();
    if (placeSearchController.suggestions.isNotEmpty) {
      bookingRideController.prefilled.value =
          placeSearchController.suggestions.first.primaryText ?? '';
    }
    loadSeletedPackage();
  }

  void loadSeletedPackage() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bookingRideController.selectedPackage.value =
          await StorageServices.instance.read('selectedPackage') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 🚀 Stops the default "pop and close app"
      onPopInvoked: (didPop) {
        // This will be called for hardware back and gesture
        GoRouter.of(context).go(AppRoutes.bottomNav);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 56,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        GoRouter.of(context).go(AppRoutes.bottomNav);
                      },
                      child:
                      const Icon(Icons.arrow_back, color: AppColors.blue4),
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
                child:
                Container(color: Colors.white, child: CustomTabBarDemo()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTabBarDemo extends StatefulWidget {
  CustomTabBarDemo({Key? key}) : super(key: key);

  @override
  State<CustomTabBarDemo> createState() => _CustomTabBarDemoState();
}

class _CustomTabBarDemoState extends State<CustomTabBarDemo> {
  final BookingRideController bookingRideController =
  Get.put(BookingRideController());
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
              ),
            ],
          ),
          child: Obx(() {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(tabs.length, (index) {
                final isSelected =
                    bookingRideController.selectedIndex.value == index;
                return GestureDetector(
                  onTap: () => bookingRideController.changeTab(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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
            );
          }),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Obx(() {
            return IndexedStack(
              index: bookingRideController.selectedIndex.value,
              children: [
                Rides(),
                OutStation(),
                Rental(),
              ],
            );
          }),
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

  final BookingRideController bookingRideController = Get.put(BookingRideController());
  final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController = Get.put(DropPlaceSearchController());
  final SearchCabInventoryController searchCabInventoryController = Get.put(SearchCabInventoryController());
  final ButtonStateController buttonStateController = Get.put(
    ButtonStateController(
      placeSearchController: Get.find<PlaceSearchController>(),
      dropPlaceSearchController: Get.find<DropPlaceSearchController>(),
      bookingRideController: Get.find<BookingRideController>(),
    ),
  );
  final RxString selectedField = ''.obs;

  late final TextEditingController pickupController;
  late final TextEditingController dropController;
  late Worker _pickupWorker;
  late Worker _dropWorker;
  late Worker _placeIdWorker;
  late Worker _dropPlaceIdWorker;

  @override
  void initState() {
    super.initState();

    pickupController = TextEditingController(text: bookingRideController.prefilled.value);
    dropController = TextEditingController(text: bookingRideController.prefilledDrop.value);

    _pickupWorker = ever<String>(bookingRideController.prefilled, (value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && pickupController.text != value) {
          setState(() {
            pickupController.text = value;
            pickupController.selection = TextSelection.collapsed(offset: value.length);
          });
        }
      });
    });

    _dropWorker = ever<String>(bookingRideController.prefilledDrop, (value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && dropController.text != value) {
          setState(() {
            dropController.text = value;
            dropController.selection = TextSelection.collapsed(offset: value.length);
          });
        }
      });
    });

    // Validate prefilled placeId and dropPlaceId after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (placeSearchController.placeId.value.isNotEmpty || dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
        buttonStateController.isEnabled.value = false; // Disable button initially
        buttonStateController.isButtonLoading.value = true; // Show loader
        Future(() async {
          try {
            final futures = <Future>[];
            if (placeSearchController.placeId.value.isNotEmpty) {
              futures.add(placeSearchController.getLatLngDetails(placeSearchController.placeId.value, context));
            }
            if (dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
              futures.add(dropPlaceSearchController.getLatLngForDrop(dropPlaceSearchController.dropPlaceId.value, context));
            }
            await Future.wait(futures);
          } catch (e, st) {
            debugPrint('Prefilled validation error: $e\n$st');
          } finally {
            buttonStateController.isButtonLoading.value = false; // Hide loader
            buttonStateController.validateButtonState();
          }
        });
      }
    });

    // Monitor placeId changes
    _placeIdWorker = ever(placeSearchController.placeId, (String placeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        buttonStateController.isEnabled.value = false; // Disable immediately
        buttonStateController.isButtonLoading.value = true; // Show loader
        Future(() async {
          if (placeId.isNotEmpty) {
            try {
              await placeSearchController.getLatLngDetails(placeId, context);
            } catch (e, st) {
              debugPrint('PlaceId validation error: $e\n$st');
            }
          }
          buttonStateController.isButtonLoading.value = false; // Hide loader
          buttonStateController.validateButtonState();
        });
      });
    });

    // Monitor dropPlaceId changes
    _dropPlaceIdWorker = ever(dropPlaceSearchController.dropPlaceId, (String dropId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        buttonStateController.isEnabled.value = false; // Disable immediately
        buttonStateController.isButtonLoading.value = true; // Show loader
        Future(() async {
          if (dropId.isNotEmpty) {
            try {
              await dropPlaceSearchController.getLatLngForDrop(dropId, context);
            } catch (e, st) {
              debugPrint('DropPlaceId validation error: $e\n$st');
            }
          }
          buttonStateController.isButtonLoading.value = false; // Hide loader
          buttonStateController.validateButtonState();
        });
      });
    });
  }

  @override
  void dispose() {
    _pickupWorker.dispose();
    _dropWorker.dispose();
    _placeIdWorker.dispose();
    _dropPlaceIdWorker.dispose();
    pickupController.dispose();
    dropController.dispose();
    super.dispose();
  }

  Future<void> switchPickupAndDrop({
    required BuildContext context,
    required TextEditingController pickupController,
    required TextEditingController dropController,
  }) async {
    if (bookingRideController.isSwitching.value) return;

    bookingRideController.isSwitching.value = true;
    buttonStateController.isButtonLoading.value = true; // Show loader during swap
    FocusScope.of(context).unfocus();

    try {
      final oldPickupId = placeSearchController.placeId.value.trim();
      final oldDropId = dropPlaceSearchController.dropPlaceId.value.trim();
      final oldPickupText = bookingRideController.prefilled.value;
      final oldDropText = bookingRideController.prefilledDrop.value;

      final idsSame = oldPickupId == oldDropId;
      final textsSame = oldPickupText == oldDropText;
      if (idsSame && textsSame) {
        bookingRideController.isSwitching.value = false;
        buttonStateController.isButtonLoading.value = false;
        return;
      }

      placeSearchController.placeId.value = oldDropId;
      dropPlaceSearchController.dropPlaceId.value = oldPickupId;
      bookingRideController.prefilled.value = oldDropText;
      bookingRideController.prefilledDrop.value = oldPickupText;

      pickupController.value = TextEditingValue(
        text: bookingRideController.prefilled.value,
        selection: TextSelection.collapsed(offset: bookingRideController.prefilled.value.length),
      );
      dropController.value = TextEditingValue(
        text: bookingRideController.prefilledDrop.value,
        selection: TextSelection.collapsed(offset: bookingRideController.prefilledDrop.value.length),
      );

      final futures = <Future>[];
      final newPickupId = placeSearchController.placeId.value;
      final newDropId = dropPlaceSearchController.dropPlaceId.value;

      if (newPickupId.isNotEmpty) {
        futures.add(placeSearchController.getLatLngDetails(newPickupId, context));
      }
      if (newDropId.isNotEmpty) {
        futures.add(dropPlaceSearchController.getLatLngForDrop(newDropId, context));
      }
      await Future.wait(futures);

      const sourceKeys = [
        'sourcePlaceId',
        'sourceTitle',
        'sourceCity',
        'sourceState',
        'sourceCountry',
        'sourceTypes',
        'sourceTerms',
      ];
      const destinationKeys = [
        'destinationPlaceId',
        'destinationTitle',
        'destinationCity',
        'destinationState',
        'destinationCountry',
        'destinationTypes',
        'destinationTerms',
      ];

      final srcVals = await Future.wait(sourceKeys.map(StorageServices.instance.read));
      final destVals = await Future.wait(destinationKeys.map(StorageServices.instance.read));
      await Future.wait([
        ...List.generate(sourceKeys.length, (i) => StorageServices.instance.save(sourceKeys[i], (destVals[i] ?? '').toString())),
        ...List.generate(destinationKeys.length, (i) => StorageServices.instance.save(destinationKeys[i], (srcVals[i] ?? '').toString())),
      ]);

      buttonStateController.validateButtonState();
    } catch (e, st) {
      debugPrint('switchPickupAndDrop error: $e\n$st');
    } finally {
      bookingRideController.isSwitching.value = false;
      buttonStateController.isButtonLoading.value = false; // Hide loader
    }
  }

  DateTime getLocalDateTime() {
    final userDateTimeStr = placeSearchController.findCntryDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final offset = placeSearchController.findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (userDateTimeStr != null) {
      try {
        final utc = DateTime.parse(userDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0));
      } catch (e) {
        debugPrint("Error parsing userDateTime: $e");
      }
    }

    return bookingRideController.localStartTime.value;
  }

  DateTime getInitialDateTime() {
    final actualDateTimeStr = placeSearchController.findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime;
    final offset = placeSearchController.findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet;

    if (actualDateTimeStr != null) {
      try {
        final utc = DateTime.parse(actualDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0));
      } catch (e) {
        debugPrint("Error parsing actualDateTime: $e");
      }
    }

    return getLocalDateTime();
  }

  DateTime getDropLocalDateTime() {
    final dropDateTimeStr = dropPlaceSearchController.dropDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final dropOffset = dropPlaceSearchController.dropDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (dropDateTimeStr != null) {
      try {
        final utc = DateTime.parse(dropDateTimeStr).toUtc();
        return utc.add(Duration(minutes: dropOffset ?? 0));
      } catch (_) {}
    }

    return bookingRideController.localStartTime.value.add(const Duration(hours: 4));
  }

  void updateLocalStartTime(DateTime newDateTime) {
    final timezone = placeSearchController.findCntryDateTimeResponse.value?.timeZone ?? placeSearchController.getCurrentTimeZoneName();
    final offset = placeSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localStartTime.value = newDateTime;
    bookingRideController.utcStartTime.value = newDateTime.subtract(Duration(minutes: offset));

    final existingDrop = bookingRideController.localEndTime.value;
    final proposedDrop = newDateTime.add(const Duration(hours: 4));

    final isSameDay = DateUtils.isSameDay(newDateTime, existingDrop);
    final isBeforeMin = existingDrop.isBefore(proposedDrop);

    if (isSameDay && isBeforeMin) {
      updateLocalEndTime(proposedDrop);
    }

    buttonStateController.validateButtonState(); // Re-validate after time change
  }

  void updateLocalEndTime(DateTime newDateTime) {
    final timezone = dropPlaceSearchController.dropDateTimeResponse.value?.timeZone ?? dropPlaceSearchController.getCurrentTimeZoneName();
    final offset = dropPlaceSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localEndTime.value = newDateTime;
    bookingRideController.utcEndTime.value = newDateTime.subtract(Duration(minutes: offset));
    buttonStateController.validateButtonState(); // Re-validate after time change
  }

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
                const SizedBox(width: 16),
              ],
            ),
            _verticalDivider(),
            Row(
              children: [
                _buildOption('Round Trip', 'roundTrip', selectedTrip == 'roundTrip'),
                const SizedBox(width: 16),
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
                        errorText: () {
                          if (buttonStateController.isButtonLoading.value) return null; // Suppress errors during loading
                          final pickupId = placeSearchController.placeId.value;
                          final dropId = dropPlaceSearchController.dropPlaceId.value;
                          if (pickupId.isNotEmpty && dropId.isNotEmpty && pickupId == dropId) {
                            return "Pickup and Drop cannot be the same";
                          }
                          if (placeSearchController.findCntryDateTimeResponse.value?.sourceInput == true ||
                              dropPlaceSearchController.dropDateTimeResponse.value?.sourceInput == true) {
                            return "We don't offer services from this region";
                          }
                          return null;
                        }(),
                        onTap: () => GoRouter.of(context).push(AppRoutes.choosePickup),
                      ),
                      const SizedBox(height: 12),
                      BookingTextFormField(
                        hintText: 'Enter Drop Location',
                        controller: dropController,
                        errorText: () {
                          if (buttonStateController.isButtonLoading.value) return null; // Suppress errors during loading
                          final pickupId = placeSearchController.placeId.value;
                          final dropId = dropPlaceSearchController.dropPlaceId.value;
                          if (pickupId.isNotEmpty && dropId.isNotEmpty && pickupId == dropId) {
                            return "Pickup and Drop cannot be the same";
                          }
                          if (placeSearchController.findCntryDateTimeResponse.value?.destinationInputFalse == true ||
                              dropPlaceSearchController.dropDateTimeResponse.value?.destinationInputFalse == true) {
                            return "We don't offer services from this region";
                          }
                          return null;
                        }(),
                        onTap: () => GoRouter.of(context).push(AppRoutes.chooseDrop),
                      ),
                    ],
                  )),
                ),
                Column(
                  children: [
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        switchPickupAndDrop(
                          context: context,
                          pickupController: pickupController,
                          dropController: dropController,
                        );
                      },
                      child: Transform.translate(
                        offset: const Offset(0, 0),
                        child: Image.asset('assets/images/interchange.png', width: 30, height: 30),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                    Row(
                      children: [
                        Expanded(
                          child: DatePickerTile(
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

                              final minDrop = updated.add(const Duration(hours: 4));
                              final drop = bookingRideController.localEndTime.value;
                              if (DateUtils.isSameDay(drop, updated) && drop.isBefore(minDrop)) {
                                updateLocalEndTime(minDrop);
                                bookingRideController.localEndTime.refresh();
                              }

                              bookingRideController.localStartTime.refresh();
                            },
                            controller: placeSearchController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TimePickerTile(
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

                              final minAllowedDrop = updatedPickup.add(const Duration(hours: 4));
                              final existingDrop = bookingRideController.localEndTime.value;

                              final isSameDay = DateUtils.isSameDay(updatedPickup, existingDrop);
                              final isDropBeforeMin = existingDrop.isBefore(minAllowedDrop);

                              if (isSameDay && isDropBeforeMin) {
                                updateLocalEndTime(minAllowedDrop);
                                bookingRideController.localEndTime.refresh();
                              }
                            },
                            controller: placeSearchController,
                          ),
                        ),
                      ],
                    ),
                    if (showDropDateTime) ...[
                      const SizedBox(height: 16),
                      DateTimePickerTile(
                        label: 'Drop Date',
                        initialDateTime: localEnd.isBefore(localStart.add(const Duration(hours: 4)))
                            ? localStart.add(const Duration(hours: 4))
                            : localEnd,
                        minimumDate: localStart.add(const Duration(hours: 4)),
                        onDateTimeSelected: (picked) {
                          final minDrop = bookingRideController.localStartTime.value.add(const Duration(hours: 4));
                          final updated = picked.isBefore(minDrop) ? minDrop : picked;
                          updateLocalEndTime(updated);
                          bookingRideController.localEndTime.refresh();
                        },
                      ),
                    ],
                  ],
                );
              }),
            ),
            const SizedBox(height: 12),
            Obx(() {
              return bookingRideController.isInvalidTime.value && !buttonStateController.isButtonLoading.value
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: const Text(
                  "Invalid selection: You cannot choose a past time. Select a valid time to continue.",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                  maxLines: 2,
                ),
              )
                  : const SizedBox();
            }),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                final pickupId = placeSearchController.placeId.value;
                final dropId = dropPlaceSearchController.dropPlaceId.value;

                final samePlace = pickupId.isNotEmpty && dropId.isNotEmpty && pickupId == dropId;

                final hasSourceError = placeSearchController.findCntryDateTimeResponse.value?.sourceInput == true ||
                    dropPlaceSearchController.dropDateTimeResponse.value?.sourceInput == true;

                final hasDestinationError = placeSearchController.findCntryDateTimeResponse.value?.destinationInputFalse == true ||
                    dropPlaceSearchController.dropDateTimeResponse.value?.destinationInputFalse == true;

                final isPlaceMissing = pickupId.isEmpty || dropId.isEmpty;

                final canProceed = !samePlace &&
                    !hasSourceError &&
                    !hasDestinationError &&
                    !isPlaceMissing &&
                    (placeSearchController.findCntryDateTimeResponse.value?.goToNextPage == true ||
                        placeSearchController.findCntryDateTimeResponse.value?.sameCountry == true ||
                        dropPlaceSearchController.dropDateTimeResponse.value?.sameCountry == true ||
                        dropPlaceSearchController.dropDateTimeResponse.value?.goToNextPage == true);

                final isEnabled = canProceed && !bookingRideController.isInvalidTime.value;

                return Opacity(
                  opacity: isEnabled && !buttonStateController.isButtonLoading.value ? 1.0 : 0.6,
                  child: SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'Search Now',
                      isLoading: buttonStateController.isButtonLoading.value,
                      isEnabled: isEnabled,
                      onPressed: isEnabled && !buttonStateController.isButtonLoading.value
                          ? () async {
                        final requestData = await _buildOutstationRequestData(context);
                        await searchCabInventoryController.fetchBookingData(
                          country: requestData['countryName'],
                          requestData: requestData,
                          context: context,
                          isSecondPage: true,
                        );
                        GoRouter.of(context).push(AppRoutes.inventoryList, extra: requestData);
                      }
                          : () {},
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _buildOutstationRequestData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FullScreenGifLoader(),
    );
    final now = DateTime.now();
    final searchDate = now.toIso8601String().split('T').first;
    final searchTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final offset = now.timeZoneOffset.inMinutes;

    final keys = [
      'country',
      'userOffset',
      'userDateTime',
      'userTimeWithOffset',
      'actualTimeWithOffset',
      'actualOffset',
      'timeZone',
      'sourceTitle',
      'sourcePlaceId',
      'sourceCity',
      'sourceState',
      'sourceCountry',
      'sourceLat',
      'sourceLng',
      'sourceTypes',
      'sourceTerms',
      'destinationPlaceId',
      'destinationTitle',
      'destinationCity',
      'destinationState',
      'destinationCountry',
      'destinationTypes',
      'destinationTerms',
      'destinationLat',
      'destinationLng',
    ];

    final values = await Future.wait(keys.map(StorageServices.instance.read));
    final Map<String, dynamic> data = Map.fromIterables(keys, values);
    final isRoundTrip = selectedTrip != 'oneWay';

    GoRouter.of(context).pop();

    return {
      "timeOffSet": -offset,
      "countryName": data['country'],
      "searchDate": searchDate,
      "searchTime": searchTime,
      "offset": int.parse(data['userOffset'] ?? '0'),
      "pickupDateAndTime": bookingRideController.convertLocalToUtc(),
      "returnDateAndTime": isRoundTrip ? bookingRideController.convertLocalToUtc() : "",
      "tripCode": isRoundTrip ? "1" : "0",
      "source": {
        "sourceTitle": data['sourceTitle'],
        "sourcePlaceId": data['sourcePlaceId'],
        "sourceCity": placeSearchController.getPlacesLatLng.value?.city.toString() ?? '',
        "sourceState": placeSearchController.getPlacesLatLng.value?.state.toString() ?? '',
        "sourceCountry": placeSearchController.getPlacesLatLng.value?.country.toString() ?? '',
        "sourceType": _parseList<String>(data['sourceTypes']),
        "sourceLat": placeSearchController.getPlacesLatLng.value?.latLong.lat.toString() ?? '',
        "sourceLng": placeSearchController.getPlacesLatLng.value?.latLong.lng.toString() ?? '',
        "terms": _parseList<Map<String, dynamic>>(data['sourceTerms']),
      },
      "destination": {
        "destinationTitle": data['destinationTitle'],
        "destinationPlaceId": data['destinationPlaceId'],
        "destinationCity": dropPlaceSearchController.dropLatLng.value?.city.toString() ?? '',
        "destinationState": dropPlaceSearchController.dropLatLng.value?.state.toString() ?? '',
        "destinationCountry": dropPlaceSearchController.dropLatLng.value?.country.toString() ?? '',
        "destinationType": _parseList<String>(data['destinationTypes']),
        "destinationLat": dropPlaceSearchController.dropLatLng.value?.latLong.lat.toString() ?? '',
        "destinationLng": dropPlaceSearchController.dropLatLng.value?.latLong.lng.toString() ?? '',
        "terms": _parseList<Map<String, dynamic>>(data['destinationTerms']),
      },
      "packageSelected": {"km": "", "hours": ""},
      "stopsArray": [],
      "pickUpTime": {
        "time": data['actualTimeWithOffset'],
        "offset": data['actualOffset'],
        "timeZone": data['timeZone'],
      },
      "dropTime": isRoundTrip
          ? {
        "time": bookingRideController.localEndTime.value.toIso8601String(),
        "offset": dropPlaceSearchController.getOffsetFromTimeZone(
            dropPlaceSearchController.dropDateTimeResponse.value?.timeZone ?? dropPlaceSearchController.getCurrentTimeZoneName()),
        "timeZone": dropPlaceSearchController.dropDateTimeResponse.value?.timeZone ?? dropPlaceSearchController.getCurrentTimeZoneName(),
      }
          : {},
      "mindate": {
        "date": data['userTimeWithOffset'],
        "time": data['userTimeWithOffset'],
        "offset": data['userOffset'],
        "timeZone": data['timeZone'],
      },
      "isGlobal": (data['country']?.toLowerCase() == 'india') ? false : true,
    };
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

class ButtonStateController extends GetxController {
  final PlaceSearchController placeSearchController;
  final DropPlaceSearchController dropPlaceSearchController;
  final BookingRideController bookingRideController;
  final RxBool isEnabled = false.obs;
  final RxBool isButtonLoading = false.obs;

  ButtonStateController({
    required this.placeSearchController,
    required this.dropPlaceSearchController,
    required this.bookingRideController,
  }) {
    ever(bookingRideController.isInvalidTime, (_) => WidgetsBinding.instance.addPostFrameCallback((_) => validateButtonState()));
    ever(placeSearchController.findCntryDateTimeResponse, (_) => WidgetsBinding.instance.addPostFrameCallback((_) => validateButtonState()));
    ever(dropPlaceSearchController.dropDateTimeResponse, (_) => WidgetsBinding.instance.addPostFrameCallback((_) => validateButtonState()));
    WidgetsBinding.instance.addPostFrameCallback((_) => validateButtonState());
  }

  void validateButtonState() {
    isEnabled.value = false;

    final placeId = placeSearchController.placeId.value;
    final dropId = dropPlaceSearchController.dropPlaceId.value;
    if (placeId.isEmpty || dropId.isEmpty) return;

    if (placeId == dropId) return;

    if (placeSearchController.findCntryDateTimeResponse.value?.sourceInput == true ||
        dropPlaceSearchController.dropDateTimeResponse.value?.sourceInput == true ||
        placeSearchController.findCntryDateTimeResponse.value?.destinationInputFalse == true ||
        dropPlaceSearchController.dropDateTimeResponse.value?.destinationInputFalse == true) {
      return;
    }

    if (bookingRideController.isInvalidTime.value) return;

    final canProceed = (placeSearchController.findCntryDateTimeResponse.value?.goToNextPage == true ||
        placeSearchController.findCntryDateTimeResponse.value?.sameCountry == true ||
        dropPlaceSearchController.dropDateTimeResponse.value?.sameCountry == true ||
        dropPlaceSearchController.dropDateTimeResponse.value?.goToNextPage == true);

    if (canProceed) {
      isEnabled.value = true;
    }
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (isEnabled && !isLoading) ? onPressed : null,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (isLoading) return AppColors.mainButtonBg; // Blue when loading
          if (states.contains(WidgetState.disabled)) return AppColors.mainButtonBg.withOpacity(0.8); // Reduced opacity when disabled
          return AppColors.mainButtonBg; // Default background
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white), // Always white for text/loader
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: isLoading
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // White loader
        ),
      )
          : Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white, // Always white text
        ),
      ),
    );
  }
}

//

class Rides extends StatefulWidget {
  const Rides({super.key});

  @override
  State<Rides> createState() => _RidesState();
}

class _RidesState extends State<Rides> {
  final BookingRideController bookingRideController = Get.put(BookingRideController());
  final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController = Get.put(DropPlaceSearchController());
  final SearchCabInventoryController searchCabInventoryController = Get.put(SearchCabInventoryController());
  final ButtonStateController buttonStateController = Get.put(
    ButtonStateController(
      placeSearchController: Get.find<PlaceSearchController>(),
      dropPlaceSearchController: Get.find<DropPlaceSearchController>(),
      bookingRideController: Get.find<BookingRideController>(),
    ),
  );
  final RxString selectedField = ''.obs;

  late TextEditingController ridePickupController;
  late TextEditingController rideDropController;
  late Worker _ridePickupWorker;
  late Worker _rideDropWorker;
  late Worker _placeIdWorker;
  late Worker _dropPlaceIdWorker;
  final RxBool _isLoading = false.obs;

  Future<void> switchPickupAndDrop({
    required BuildContext context,
    required TextEditingController pickupController,
    required TextEditingController dropController,
  }) async {
    if (bookingRideController.isSwitching.value) return;

    bookingRideController.isSwitching.value = true;
    buttonStateController.isButtonLoading.value = true; // Show loader during swap
    FocusScope.of(context).unfocus();

    try {
      final oldPickupId = placeSearchController.placeId.value;
      final oldDropId = dropPlaceSearchController.dropPlaceId.value;
      final oldPickupText = bookingRideController.prefilled.value;
      final oldDropText = bookingRideController.prefilledDrop.value;

      if (oldPickupId == oldDropId && oldPickupText == oldDropText) {
        bookingRideController.isSwitching.value = false;
        buttonStateController.isButtonLoading.value = false;
        return;
      }

      placeSearchController.placeId.value = oldDropId;
      dropPlaceSearchController.dropPlaceId.value = oldPickupId;
      bookingRideController.prefilled.value = oldDropText;
      bookingRideController.prefilledDrop.value = oldPickupText;

      pickupController.text = oldDropText;
      dropController.text = oldPickupText;
      pickupController.selection = TextSelection.collapsed(offset: oldDropText.length);
      dropController.selection = TextSelection.collapsed(offset: oldPickupText.length);

      final futures = <Future>[];
      if (placeSearchController.placeId.isNotEmpty) {
        futures.add(placeSearchController.getLatLngDetails(placeSearchController.placeId.value, context));
      }
      if (dropPlaceSearchController.dropPlaceId.isNotEmpty) {
        futures.add(dropPlaceSearchController.getLatLngForDrop(dropPlaceSearchController.dropPlaceId.value, context));
      }
      await Future.wait(futures);

      const sourceKeys = ['sourcePlaceId', 'sourceTitle', 'sourceCity', 'sourceState', 'sourceCountry', 'sourceTypes', 'sourceTerms'];
      const destinationKeys = ['destinationPlaceId', 'destinationTitle', 'destinationCity', 'destinationState', 'destinationCountry', 'destinationTypes', 'destinationTerms'];
      final srcVals = await Future.wait(sourceKeys.map(StorageServices.instance.read));
      final destVals = await Future.wait(destinationKeys.map(StorageServices.instance.read));
      await Future.wait([
        for (int i = 0; i < sourceKeys.length; i++) StorageServices.instance.save(sourceKeys[i], destVals[i] ?? ''),
        for (int i = 0; i < destinationKeys.length; i++) StorageServices.instance.save(destinationKeys[i], srcVals[i] ?? ''),
      ]);

      buttonStateController.validateButtonState();
    } catch (e, st) {
      debugPrint('switchPickupAndDrop error: $e\n$st');
    } finally {
      bookingRideController.isSwitching.value = false;
      buttonStateController.isButtonLoading.value = false; // Hide loader
    }
  }

  @override
  void initState() {
    super.initState();
    ridePickupController = TextEditingController(text: bookingRideController.prefilled.value);
    rideDropController = TextEditingController(text: bookingRideController.prefilledDrop.value);

    _ridePickupWorker = debounce(bookingRideController.prefilled, (String val) {
      if (mounted) {
        ridePickupController.text = val;
        ridePickupController.selection = TextSelection.collapsed(offset: val.length);
      }
    }, time: const Duration(milliseconds: 100));

    _rideDropWorker = debounce(bookingRideController.prefilledDrop, (String val) {
      if (mounted) {
        rideDropController.text = val;
        rideDropController.selection = TextSelection.collapsed(offset: val.length);
      }
    }, time: const Duration(milliseconds: 100));

    // Validate prefilled placeId and dropPlaceId
    if (placeSearchController.placeId.value.isNotEmpty || dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
      buttonStateController.isEnabled.value = false; // Disable button initially
      buttonStateController.isButtonLoading.value = true; // Show loader for prefilled validation
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final futures = <Future>[];
          if (placeSearchController.placeId.value.isNotEmpty) {
            futures.add(placeSearchController.getLatLngDetails(placeSearchController.placeId.value, context));
          }
          if (dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
            futures.add(dropPlaceSearchController.getLatLngForDrop(dropPlaceSearchController.dropPlaceId.value, context));
          }
          await Future.wait(futures);
        } catch (e, st) {
          debugPrint('Prefilled validation error: $e\n$st');
        } finally {
          buttonStateController.isButtonLoading.value = false; // Hide loader
          buttonStateController.validateButtonState();
        }
      });
    }

    // Monitor placeId and dropPlaceId changes, show loader and disable button
    _placeIdWorker = ever(placeSearchController.placeId, (String placeId) async {
      buttonStateController.isEnabled.value = false; // Disable immediately
      buttonStateController.isButtonLoading.value = true; // Show loader
      if (placeId.isNotEmpty) {
        await placeSearchController.getLatLngDetails(placeId, context);
      }
      buttonStateController.isButtonLoading.value = false; // Hide loader
      buttonStateController.validateButtonState();
    });

    _dropPlaceIdWorker = ever(dropPlaceSearchController.dropPlaceId, (String dropId) async {
      buttonStateController.isEnabled.value = false; // Disable immediately
      buttonStateController.isButtonLoading.value = true; // Show loader
      if (dropId.isNotEmpty) {
        await dropPlaceSearchController.getLatLngForDrop(dropId, context);
      }
      buttonStateController.isButtonLoading.value = false; // Hide loader
      buttonStateController.validateButtonState();
    });
  }

  @override
  void dispose() {
    _ridePickupWorker.dispose();
    _rideDropWorker.dispose();
    _placeIdWorker.dispose();
    _dropPlaceIdWorker.dispose();
    ridePickupController.dispose();
    rideDropController.dispose();
    super.dispose();
  }

  DateTime getLocalDateTime() {
    final userDateTimeStr = placeSearchController.findCntryDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final offset = placeSearchController.findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet ?? 0;
    try {
      return userDateTimeStr != null ? DateTime.parse(userDateTimeStr).toUtc().add(Duration(minutes: offset)) : bookingRideController.localStartTime.value;
    } catch (e) {
      debugPrint('Error parsing userDateTime: $e');
      return bookingRideController.localStartTime.value;
    }
  }

  DateTime getInitialDateTime() {
    final actualDateTimeStr = placeSearchController.findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime;
    final offset = placeSearchController.findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet ?? 0;
    try {
      return actualDateTimeStr != null ? DateTime.parse(actualDateTimeStr).toUtc().add(Duration(minutes: offset)) : getLocalDateTime();
    } catch (e) {
      debugPrint('Error parsing actualDateTime: $e');
      return getLocalDateTime();
    }
  }

  DateTime getDropLocalDateTime() {
    final dropDateTimeStr = dropPlaceSearchController.dropDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final dropOffset = dropPlaceSearchController.dropDateTimeResponse.value?.userDateTimeObject?.userOffSet ?? 0;
    try {
      return dropDateTimeStr != null ? DateTime.parse(dropDateTimeStr).toUtc().add(Duration(minutes: dropOffset)) : bookingRideController.localStartTime.value.add(const Duration(hours: 4));
    } catch (_) {
      return bookingRideController.localStartTime.value.add(const Duration(hours: 4));
    }
  }

  void updateLocalStartTime(DateTime newDateTime) {
    final timezone = placeSearchController.findCntryDateTimeResponse.value?.timeZone ?? placeSearchController.getCurrentTimeZoneName();
    final offset = placeSearchController.getOffsetFromTimeZone(timezone);
    bookingRideController.localStartTime.value = newDateTime;
    bookingRideController.utcStartTime.value = newDateTime.subtract(Duration(minutes: offset));
    buttonStateController.validateButtonState(); // Re-validate after time change
  }

  void updateLocalEndTime(DateTime newDateTime) {
    final timezone = dropPlaceSearchController.dropDateTimeResponse.value?.timeZone ?? dropPlaceSearchController.getCurrentTimeZoneName();
    final offset = dropPlaceSearchController.getOffsetFromTimeZone(timezone);
    bookingRideController.localEndTime.value = newDateTime;
    bookingRideController.utcEndTime.value = newDateTime.subtract(Duration(minutes: offset));
    buttonStateController.validateButtonState(); // Re-validate after time change
  }

  @override
  Widget build(BuildContext context) {
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
                        errorText: _getPickupErrorText(),
                        onTap: () => GoRouter.of(context).push(AppRoutes.choosePickup),
                      ),
                      const SizedBox(height: 12),
                      BookingTextFormField(
                        hintText: 'Enter Drop Location',
                        controller: rideDropController,
                        errorText: _getDropErrorText(),
                        onTap: () => GoRouter.of(context).push(AppRoutes.chooseDrop),
                      ),
                    ],
                  )),
                ),
                Column(
                  children: [
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => switchPickupAndDrop(
                        context: context,
                        pickupController: ridePickupController,
                        dropController: rideDropController,
                      ),
                      child: Image.asset('assets/images/interchange.png', width: 30, height: 30),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() => Row(
                children: [
                  Expanded(
                    child: DatePickerTile(
                      label: 'Pickup Date',
                      initialDate: bookingRideController.localStartTime.value,
                      onDateSelected: (newDate) {
                        final actualDateTimeStr = placeSearchController.findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime;
                        if (actualDateTimeStr != null) {
                          final actualMinDateTime = DateTime.parse(actualDateTimeStr).toLocal();
                          final updatedTime = DateTime(
                            newDate.year,
                            newDate.month,
                            newDate.day,
                            DateUtils.isSameDay(newDate, actualMinDateTime) ? actualMinDateTime.hour : bookingRideController.localStartTime.value.hour,
                            DateUtils.isSameDay(newDate, actualMinDateTime) ? actualMinDateTime.minute : bookingRideController.localStartTime.value.minute,
                          );
                          updateLocalStartTime(updatedTime);
                        } else {
                          updateLocalStartTime(DateTime(
                            newDate.year,
                            newDate.month,
                            newDate.day,
                            bookingRideController.localStartTime.value.hour,
                            bookingRideController.localStartTime.value.minute,
                          ));
                        }
                      },
                      controller: placeSearchController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TimePickerTile(
                      label: 'Pickup Time',
                      initialTime: bookingRideController.localStartTime.value,
                      onTimeSelected: (newTime) {
                        updateLocalStartTime(DateTime(
                          bookingRideController.localStartTime.value.year,
                          bookingRideController.localStartTime.value.month,
                          bookingRideController.localStartTime.value.day,
                          newTime.hour,
                          newTime.minute,
                        ));
                      },
                      controller: placeSearchController,
                    ),
                  ),
                ],
              )),
            ),
            Obx(() => bookingRideController.isInvalidTime.value
                ? Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text(
                "Invalid selection: You cannot choose a past time. Select a valid time to continue.",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent),
                maxLines: 2,
              ),
            )
                : const SizedBox()),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() => Opacity(
                opacity: buttonStateController.isEnabled.value && !buttonStateController.isButtonLoading.value ? 1.0 : 0.6,
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Search Now',
                    isLoading: buttonStateController.isButtonLoading.value,
                    onPressed: buttonStateController.isEnabled.value && !buttonStateController.isButtonLoading.value
                        ? () async => GoRouter.of(context).push(AppRoutes.inventoryList, extra: await _buildRequestData(context))
                        : () {},
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  String? _getPickupErrorText() {
    // Suppress error text while loading
    if (buttonStateController.isButtonLoading.value) return null;

    final placeId = placeSearchController.placeId.value;
    final dropId = dropPlaceSearchController.dropPlaceId.value;
    if (placeId.isNotEmpty && dropId.isNotEmpty && placeId == dropId) {
      return "Pickup and Drop cannot be the same";
    }
    if (placeSearchController.findCntryDateTimeResponse.value?.sourceInput == true ||
        dropPlaceSearchController.dropDateTimeResponse.value?.sourceInput == true) {
      return "We don't offer services from this region";
    }
    return null;
  }

  String? _getDropErrorText() {
    // Suppress error text while loading
    if (buttonStateController.isButtonLoading.value) return null;

    final pickupId = placeSearchController.placeId.value;
    final dropId = dropPlaceSearchController.dropPlaceId.value;
    if (pickupId.isNotEmpty && dropId.isNotEmpty && pickupId == dropId) {
      return "Pickup and Drop cannot be the same";
    }
    if (placeSearchController.findCntryDateTimeResponse.value?.destinationInputFalse == true ||
        dropPlaceSearchController.dropDateTimeResponse.value?.destinationInputFalse == true) {
      return "We don't offer services from this region";
    }
    return null;
  }

  Future<Map<String, dynamic>> _buildRequestData(BuildContext context) async {
    final now = DateTime.now();
    final searchDate = now.toIso8601String().split('T').first;
    final searchTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final offset = now.timeZoneOffset.inMinutes;

    showDialog(context: context, barrierDismissible: false, builder: (_) => FullScreenGifLoader());

    const keys = [
      'country', 'userOffset', 'userDateTime', 'userTimeWithOffset', 'actualTimeWithOffset', 'actualOffset', 'timeZone',
      'sourceTitle', 'sourcePlaceId', 'sourceCity', 'sourceState', 'sourceCountry', 'sourceLat', 'sourceLng', 'sourceTypes', 'sourceTerms',
      'destinationPlaceId', 'destinationTitle', 'destinationCity', 'destinationState', 'destinationCountry', 'destinationTypes', 'destinationTerms', 'destinationLat', 'destinationLng'
    ];
    final values = await Future.wait(keys.map(StorageServices.instance.read));
    final data = Map<String, dynamic>.fromIterables(keys, values);

    GoRouter.of(context).pop();

    return {
      "timeOffSet": -offset,
      "countryName": data['country'],
      "searchDate": searchDate,
      "searchTime": searchTime,
      "offset": int.parse(data['userOffset'] ?? '0'),
      "pickupDateAndTime": bookingRideController.convertLocalToUtc(),
      "returnDateAndTime": "",
      "tripCode": "2",
      "source": {
        "sourceTitle": data['sourceTitle'],
        "sourcePlaceId": data['sourcePlaceId'],
        "sourceCity": placeSearchController.getPlacesLatLng.value?.city?.toString() ?? '',
        "sourceState": placeSearchController.getPlacesLatLng.value?.state?.toString() ?? '',
        "sourceCountry": placeSearchController.getPlacesLatLng.value?.country?.toString() ?? '',
        "sourceType": _parseList<String>(data['sourceTypes']),
        "sourceLat": placeSearchController.getPlacesLatLng.value?.latLong.lat.toString() ?? '',
        "sourceLng": placeSearchController.getPlacesLatLng.value?.latLong.lng.toString() ?? '',
        "terms": _parseList<Map<String, dynamic>>(data['sourceTerms']),
      },
      "destination": {
        "destinationTitle": data['destinationTitle'],
        "destinationPlaceId": data['destinationPlaceId'],
        "destinationCity": dropPlaceSearchController.dropLatLng.value?.city?.toString() ?? '',
        "destinationState": dropPlaceSearchController.dropLatLng.value?.state?.toString() ?? '',
        "destinationCountry": dropPlaceSearchController.dropLatLng.value?.country?.toString() ?? '',
        "destinationType": _parseList<String>(data['destinationTypes']),
        "destinationLat": dropPlaceSearchController.dropLatLng.value?.latLong.lat.toString() ?? '',
        "destinationLng": dropPlaceSearchController.dropLatLng.value?.latLong.lng.toString() ?? '',
        "terms": _parseList<Map<String, dynamic>>(data['destinationTerms']),
      },
      "packageSelected": {"km": "", "hours": ""},
      "stopsArray": [],
      "pickUpTime": {
        "time": data['actualTimeWithOffset'],
        "offset": data['actualOffset'],
        "timeZone": data['timeZone']
      },
      "dropTime": {},
      "mindate": {
        "date": data['userTimeWithOffset'],
        "time": data['userTimeWithOffset'],
        "offset": data['userOffset'],
        "timeZone": data['timeZone']
      },
      "isGlobal": (data['country']?.toLowerCase() == 'india') ? false : true,
    };
  }
}


Future<Map<String, dynamic>> _buildRequestData(BuildContext context) async {
  final now = DateTime.now();
  final searchDate = now.toIso8601String().split('T').first;
  final searchTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  final offset = now.timeZoneOffset.inMinutes;
  final BookingRideController bookingRideController = Get.put(BookingRideController());
  final PlaceSearchController placeSearchController =
  Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController =
  Get.put(DropPlaceSearchController());

  // Show loader
  showDialog(context: context, barrierDismissible: false, builder: (_) => FullScreenGifLoader());

  // Fetch storage values in a single batch
  const keys = [
    'country', 'userOffset', 'userDateTime', 'userTimeWithOffset', 'actualTimeWithOffset', 'actualOffset', 'timeZone',
    'sourceTitle', 'sourcePlaceId', 'sourceCity', 'sourceState', 'sourceCountry', 'sourceLat', 'sourceLng', 'sourceTypes', 'sourceTerms',
    'destinationPlaceId', 'destinationTitle', 'destinationCity', 'destinationState', 'destinationCountry', 'destinationTypes', 'destinationTerms', 'destinationLat', 'destinationLng'
  ];
  final values = await Future.wait(keys.map(StorageServices.instance.read));
  final data = Map<String, dynamic>.fromIterables(keys, values);

  GoRouter.of(context).pop();

  return {
    "timeOffSet": -offset,
    "countryName": data['country'],
    "searchDate": searchDate,
    "searchTime": searchTime,
    "offset": int.parse(data['userOffset'] ?? '0'),
    "pickupDateAndTime": bookingRideController.convertLocalToUtc(),
    "returnDateAndTime": "",
    "tripCode": "2",
    "source": {
      "sourceTitle": data['sourceTitle'],
      "sourcePlaceId": data['sourcePlaceId'],
      "sourceCity": placeSearchController.getPlacesLatLng.value?.city?.toString() ?? '',
      "sourceState": placeSearchController.getPlacesLatLng.value?.state?.toString() ?? '',
      "sourceCountry": placeSearchController.getPlacesLatLng.value?.country?.toString() ?? '',
      "sourceType": _parseList<String>(data['sourceTypes']),
      "sourceLat": placeSearchController.getPlacesLatLng.value?.latLong.lat.toString() ?? '',
      "sourceLng": placeSearchController.getPlacesLatLng.value?.latLong.lng.toString() ?? '',
      "terms": _parseList<Map<String, dynamic>>(data['sourceTerms']),
    },
    "destination": {
      "destinationTitle": data['destinationTitle'],
      "destinationPlaceId": data['destinationPlaceId'],
      "destinationCity": dropPlaceSearchController.dropLatLng.value?.city?.toString() ?? '',
      "destinationState": dropPlaceSearchController.dropLatLng.value?.state?.toString() ?? '',
      "destinationCountry": dropPlaceSearchController.dropLatLng.value?.country?.toString() ?? '',
      "destinationType": _parseList<String>(data['destinationTypes']),
      "destinationLat": dropPlaceSearchController.dropLatLng.value?.latLong.lat.toString() ?? '',
      "destinationLng": dropPlaceSearchController.dropLatLng.value?.latLong.lng.toString() ?? '',
      "terms": _parseList<Map<String, dynamic>>(data['destinationTerms']),
    },
    "packageSelected": {"km": "", "hours": ""},
    "stopsArray": [],
    "pickUpTime": {
      "time": data['actualTimeWithOffset'],
      "offset": data['actualOffset'],
      "timeZone": data['timeZone']
    },
    "dropTime": {},
    "mindate": {
      "date": data['userTimeWithOffset'],
      "time": data['userTimeWithOffset'],
      "offset": data['userOffset'],
      "timeZone": data['timeZone']
    },
    "isGlobal": (data['country']?.toLowerCase() == 'india') ? false : true,
  };
}

List<T> _parseList<T>(dynamic json) => json != null && json.isNotEmpty ? List<T>.from(jsonDecode(json)) : [];

// hourly rental



class Rental extends StatefulWidget {
  const Rental({super.key});

  @override
  State<Rental> createState() => _RentalState();
}

class _RentalState extends State<Rental> {
  final BookingRideController bookingRideController = Get.find<BookingRideController>();
  final PlaceSearchController placeSearchController = Get.find<PlaceSearchController>();
  final DropPlaceSearchController dropPlaceSearchController = Get.find<DropPlaceSearchController>();
  final SearchCabInventoryController searchCabInventoryController = Get.find<SearchCabInventoryController>();
  final FetchPackageController fetchPackageController = Get.find<FetchPackageController>();
  final ButtonRentalStateController buttonRentalStateController = Get.put(
    ButtonRentalStateController(
      placeSearchController: Get.find<PlaceSearchController>(),
      bookingRideController: Get.find<BookingRideController>(),
      fetchPackageController: Get.find<FetchPackageController>(),
    ),
  );

  final RxString selectedField = ''.obs;

  late TextEditingController ridePickupController;
  late TextEditingController rideDropController;
  late Worker rentalPickupWorker;
  late Worker rentalDropWorker;
  late Worker _placeIdWorker;

  @override
  void initState() {
    super.initState();
    ridePickupController = TextEditingController(text: bookingRideController.prefilled.value);
    rideDropController = TextEditingController(text: bookingRideController.prefilledDrop.value);

    rentalPickupWorker = ever(bookingRideController.prefilled, (String value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ridePickupController.text != value) {
          setState(() {
            ridePickupController.text = value;
            ridePickupController.selection = TextSelection.collapsed(offset: value.length);
          });
        }
      });
    });

    rentalDropWorker = ever(bookingRideController.prefilledDrop, (String value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && rideDropController.text != value) {
          setState(() {
            rideDropController.text = value;
            rideDropController.selection = TextSelection.collapsed(offset: value.length);
          });
        }
      });
    });

    // Validate prefilled placeId after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (placeSearchController.placeId.value.isNotEmpty) {
        buttonRentalStateController.isEnabled.value = false; // Disable button initially
        buttonRentalStateController.isButtonLoading.value = true; // Show loader
        Future.microtask(() async {
          try {
            await placeSearchController.getLatLngDetails(placeSearchController.placeId.value, context);
          } catch (e, st) {
            debugPrint('Prefilled validation error: $e\n$st');
          } finally {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              buttonRentalStateController.isButtonLoading.value = false; // Hide loader
              buttonRentalStateController.validateRentalButtonState();
            });
          }
        });
      }
    });

    // Monitor placeId changes
    _placeIdWorker = ever(placeSearchController.placeId, (String placeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        buttonRentalStateController.isEnabled.value = false; // Disable immediately
        buttonRentalStateController.isButtonLoading.value = true; // Show loader
        Future.microtask(() async {
          if (placeId.isNotEmpty) {
            try {
              await placeSearchController.getLatLngDetails(placeId, context);
            } catch (e, st) {
              debugPrint('PlaceId validation error: $e\n$st');
            }
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            buttonRentalStateController.isButtonLoading.value = false; // Hide loader
            buttonRentalStateController.validateRentalButtonState();
          });
        });
      });
    });
  }

  @override
  void dispose() {
    rentalPickupWorker.dispose();
    rentalDropWorker.dispose();
    _placeIdWorker.dispose();
    ridePickupController.dispose();
    rideDropController.dispose();
    super.dispose();
  }

  void switchPickupAndDrop({
    required BuildContext context,
    required TextEditingController pickupController,
    required TextEditingController dropController,
  }) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      buttonRentalStateController.isButtonLoading.value = true; // Show loader
    });
    print('switch button hit ho gya hai');

    try {
      final oldPickupId = placeSearchController.placeId.value;
      final oldDropId = dropPlaceSearchController.dropPlaceId.value;
      placeSearchController.placeId.value = oldDropId;
      dropPlaceSearchController.dropPlaceId.value = oldPickupId;

      final oldPickupText = bookingRideController.prefilled.value;
      final oldDropText = bookingRideController.prefilledDrop.value;
      bookingRideController.prefilled.value = oldDropText;
      bookingRideController.prefilledDrop.value = oldPickupText;

      pickupController.text = bookingRideController.prefilled.value;
      dropController.text = bookingRideController.prefilledDrop.value;

      final futures = <Future>[];
      if (placeSearchController.placeId.value.isNotEmpty) {
        futures.add(placeSearchController.getLatLngDetails(placeSearchController.placeId.value, context));
      }
      if (dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
        futures.add(dropPlaceSearchController.getLatLngForDrop(dropPlaceSearchController.dropPlaceId.value, context));
      }
      await Future.wait(futures);

      final sourceKeys = [
        'sourcePlaceId',
        'sourceTitle',
        'sourceCity',
        'sourceState',
        'sourceCountry',
        'sourceTypes',
        'sourceTerms',
      ];
      final destinationKeys = [
        'destinationPlaceId',
        'destinationTitle',
        'destinationCity',
        'destinationState',
        'destinationCountry',
        'destinationTypes',
        'destinationTerms',
      ];

      final srcVals = await Future.wait(sourceKeys.map(StorageServices.instance.read));
      final destVals = await Future.wait(destinationKeys.map(StorageServices.instance.read));
      await Future.wait([
        for (int i = 0; i < sourceKeys.length; i++) StorageServices.instance.save(sourceKeys[i], destVals[i] ?? ''),
        for (int i = 0; i < destinationKeys.length; i++) StorageServices.instance.save(destinationKeys[i], srcVals[i] ?? ''),
      ]);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        buttonRentalStateController.validateRentalButtonState();
      });
    } catch (e, st) {
      debugPrint('switchPickupAndDrop error: $e\n$st');
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        buttonRentalStateController.isButtonLoading.value = false; // Hide loader
      });
    }
  }

  DateTime getLocalDateTime() {
    final userDateTimeStr = placeSearchController.findCntryDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final offset = placeSearchController.findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (userDateTimeStr != null) {
      try {
        final utc = DateTime.parse(userDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0));
      } catch (e) {
        debugPrint("Error parsing userDateTime: $e");
      }
    }
    return bookingRideController.localStartTime.value;
  }

  DateTime getInitialDateTime() {
    final actualDateTimeStr = placeSearchController.findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime;
    final offset = placeSearchController.findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet;

    if (actualDateTimeStr != null) {
      try {
        final utc = DateTime.parse(actualDateTimeStr).toUtc();
        return utc.add(Duration(minutes: offset ?? 0));
      } catch (e) {
        debugPrint("Error parsing actualDateTime: $e");
      }
    }
    return getLocalDateTime();
  }

  DateTime getDropLocalDateTime() {
    final dropDateTimeStr = dropPlaceSearchController.dropDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final dropOffset = dropPlaceSearchController.dropDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (dropDateTimeStr != null) {
      try {
        final utc = DateTime.parse(dropDateTimeStr).toUtc();
        return utc.add(Duration(minutes: dropOffset ?? 0));
      } catch (_) {}
    }
    return bookingRideController.localStartTime.value.add(const Duration(hours: 4));
  }

  void updateLocalStartTime(DateTime newDateTime) {
    final timezone = placeSearchController.findCntryDateTimeResponse.value?.timeZone ?? placeSearchController.getCurrentTimeZoneName();
    final offset = placeSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localStartTime.value = newDateTime;
    bookingRideController.utcStartTime.value = newDateTime.subtract(Duration(minutes: offset));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      buttonRentalStateController.validateRentalButtonState(); // Re-validate after time change
    });
  }

  void updateLocalEndTime(DateTime newDateTime) {
    final timezone = dropPlaceSearchController.dropDateTimeResponse.value?.timeZone ?? dropPlaceSearchController.getCurrentTimeZoneName();
    final offset = dropPlaceSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localEndTime.value = newDateTime;
    bookingRideController.utcEndTime.value = newDateTime.subtract(Duration(minutes: offset));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      buttonRentalStateController.validateRentalButtonState(); // Re-validate after time change
    });
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        BookingTextFormField(
                          hintText: 'Enter Pickup Location',
                          controller: ridePickupController,
                          errorText: () {
                            if (buttonRentalStateController.isButtonLoading.value) return null; // Suppress errors during loading
                            if (placeSearchController.findCntryDateTimeResponse.value?.sourceInput == true) {
                              return "We don't offer services from this region";
                            }
                            if (placeSearchController.getPlacesLatLng.value?.country?.toLowerCase() != 'india') {
                              return "Rental services are only available in India";
                            }
                            return null;
                          }(),
                          onTap: () async {
                            await GoRouter.of(context).push(AppRoutes.choosePickup);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() {
                final localStartTime = bookingRideController.localStartTime.value;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DatePickerTile(
                        label: 'Pickup Date',
                        initialDate: localStartTime,
                        onDateSelected: (newDate) {
                          final actualDateTimeStr = placeSearchController.findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime;

                          if (actualDateTimeStr != null) {
                            final actualMinDateTime = DateTime.parse(actualDateTimeStr).toLocal();

                            if (DateUtils.isSameDay(newDate, actualMinDateTime)) {
                              final updatedTime = DateTime(
                                newDate.year,
                                newDate.month,
                                newDate.day,
                                actualMinDateTime.hour,
                                actualMinDateTime.minute,
                              );

                              if (!updatedTime.isAtSameMomentAs(bookingRideController.localStartTime.value)) {
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TimePickerTile(
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

                          if (!updatedTime.isAtSameMomentAs(bookingRideController.localStartTime.value)) {
                            updateLocalStartTime(updatedTime);
                            bookingRideController.localStartTime.refresh();
                          } else {
                            bookingRideController.localStartTime.refresh();
                          }
                        },
                        controller: placeSearchController,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final items = fetchPackageController.packageModel.value?.data
                  .map((value) => '${value.hours} hrs, ${value.kilometers} kms')
                  .toList() ??
                  [];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) {
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isSelected = fetchPackageController.selectedPackage.value == item;

                            return ListTile(
                              title: Text(
                                item,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                  : null,
                              onTap: () async {
                                fetchPackageController.updateSelectedPackage(item);
                                Navigator.pop(context);

                                print('✅ Selected package is: $item');

                                final packageRegex = RegExp(r'(\d+)\s*hrs?,\s*(\d+)\s*kms?');
                                final match = packageRegex.firstMatch(item);

                                if (match != null) {
                                  final extractedHours = int.tryParse(match.group(1)!);
                                  final extractedKms = int.tryParse(match.group(2)!);

                                  fetchPackageController.selectedHours.value = extractedHours ?? 0;
                                  fetchPackageController.selectedKms.value = extractedKms ?? 0;

                                  print('📦 Extracted Hours: $extractedHours');
                                  print('📦 Extracted Kms: $extractedKms');

                                  await StorageServices.instance.save('selectedHours', extractedHours.toString());
                                  await StorageServices.instance.save('selectedKms', extractedKms.toString());
                                }
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  buttonRentalStateController.validateRentalButtonState();
                                });
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fetchPackageController.selectedPackage.value.isNotEmpty
                              ? fetchPackageController.selectedPackage.value
                              : "Select Packages",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              return bookingRideController.isInvalidTime.value && !buttonRentalStateController.isButtonLoading.value
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Text(
                  "Invalid selection: You cannot choose a past time. Select a valid time to continue.",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent),
                  maxLines: 2,
                ),
              )
                  : const SizedBox();
            }),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: Obx(() {
                  return Opacity(
                    opacity: buttonRentalStateController.isEnabled.value && !buttonRentalStateController.isButtonLoading.value ? 1.0 : 0.6,
                    child: PrimaryRentalButton(
                      text: 'Search Now',
                      isLoading: buttonRentalStateController.isButtonLoading.value,
                      onPressed: buttonRentalStateController.isEnabled.value && !buttonRentalStateController.isButtonLoading.value
                          ? () async {
                        final requestData = await _buildRentalRequestData(context);
                        await searchCabInventoryController.fetchBookingData(
                          country: requestData['countryName'],
                          requestData: requestData,
                          context: context,
                          isSecondPage: true,
                        );
                        GoRouter.of(context).push(AppRoutes.inventoryList, extra: requestData);
                      }
                          : () {},
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

Future<Map<String, dynamic>> _buildRentalRequestData(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const FullScreenGifLoader(),
  );
  final now = DateTime.now();
  final searchDate = now.toIso8601String().split('T').first;
  final searchTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  final offset = now.timeZoneOffset.inMinutes;
  final FetchPackageController fetchPackageController = FetchPackageController();

  final keys = [
    'country',
    'userOffset',
    'userDateTime',
    'userTimeWithOffset',
    'actualTimeWithOffset',
    'actualOffset',
    'timeZone',
    'sourceTitle',
    'sourcePlaceId',
    'sourceCity',
    'sourceState',
    'sourceCountry',
    'sourceLat',
    'sourceLng',
    'sourceTypes',
    'sourceTerms',
    'selectedHours',
    'selectedKms',
  ];

  final values = await Future.wait(keys.map(StorageServices.instance.read));
  final Map<String, dynamic> data = Map.fromIterables(keys, values);

  GoRouter.of(context).pop();

  return {
    "timeOffSet": -offset,
    "countryName": data['country'],
    "searchDate": searchDate,
    "searchTime": searchTime,
    "offset": int.parse(data['userOffset'] ?? '0'),
    "pickupDateAndTime": bookingRideController.convertLocalToUtc(),
    "returnDateAndTime": "",
    "tripCode": "3",
    "source": {
      "sourceTitle": data['sourceTitle'],
      "sourcePlaceId": data['sourcePlaceId'],
      "sourceCity": placeSearchController.getPlacesLatLng.value?.city.toString() ?? '',
      "sourceState": placeSearchController.getPlacesLatLng.value?.state.toString() ?? '',
      "sourceCountry": placeSearchController.getPlacesLatLng.value?.country.toString() ?? '',
      "sourceType": _parseList<String>(data['sourceTypes']),
      "sourceLat": placeSearchController.getPlacesLatLng.value?.latLong.lat.toString() ?? '',
      "sourceLng": placeSearchController.getPlacesLatLng.value?.latLong.lng.toString() ?? '',
      "terms": _parseList<Map<String, dynamic>>(data['sourceTerms']),
    },
    "destination": {},
    "packageSelected": {
      "km": fetchPackageController.selectedKms.value.toString(),
      "hours": fetchPackageController.selectedHours.value.toString(),
    },
    "stopsArray": [],
    "pickUpTime": {
      "time": data['actualTimeWithOffset'],
      "offset": data['actualOffset'],
      "timeZone": data['timeZone'],
    },
    "dropTime": {},
    "mindate": {
      "date": data['userTimeWithOffset'],
      "time": data['userTimeWithOffset'],
      "offset": data['userOffset'],
      "timeZone": data['timeZone'],
    },
    "isGlobal": (data['country']?.toLowerCase() == 'india') ? false : true,
  };
}

class ButtonRentalStateController extends GetxController {
  final PlaceSearchController placeSearchController;
  final BookingRideController bookingRideController;
  final FetchPackageController fetchPackageController;
  final RxBool isEnabled = false.obs;
  final RxBool isButtonLoading = false.obs;

  ButtonRentalStateController({
    required this.placeSearchController,
    required this.bookingRideController,
    required this.fetchPackageController,
  }) {
    // Defer all reactive updates to after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ever(bookingRideController.isInvalidTime, (_) => WidgetsBinding.instance.addPostFrameCallback((_) => validateRentalButtonState()));
      ever(placeSearchController.findCntryDateTimeResponse, (_) => WidgetsBinding.instance.addPostFrameCallback((_) => validateRentalButtonState()));
      ever(fetchPackageController.selectedPackage, (_) => WidgetsBinding.instance.addPostFrameCallback((_) => validateRentalButtonState()));
      validateRentalButtonState();
    });
  }

  void validateRentalButtonState() {
    isEnabled.value = false;

    final placeId = placeSearchController.placeId.value;
    if (placeId.isEmpty) return;

    if (placeSearchController.findCntryDateTimeResponse.value?.sourceInput == true) return;

    if (placeSearchController.getPlacesLatLng.value?.country?.toLowerCase() != 'india') return;

    if (fetchPackageController.selectedPackage.value.isEmpty) return;

    if (bookingRideController.isInvalidTime.value) return;

    isEnabled.value = true;
  }
}

class PrimaryRentalButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  const PrimaryRentalButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isLoading ? AppColors.mainButtonBg.withOpacity(0.8) : AppColors.mainButtonBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
