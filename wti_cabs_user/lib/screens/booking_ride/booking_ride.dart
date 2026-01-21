import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wti_cabs_user/common_widget/buttons/primary_button.dart';
import 'package:wti_cabs_user/common_widget/datepicker/date_picker_tile.dart';
import 'package:wti_cabs_user/common_widget/datepicker/date_time_picker.dart';
import 'package:wti_cabs_user/common_widget/textformfield/booking_textformfield.dart';
import 'package:wti_cabs_user/common_widget/time_picker/time_picker_tile.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/button_state_controller/button_state_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/inventory/search_cab_inventory_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/select_location/select_pickup.dart';
import '../../core/controller/choose_drop/choose_drop_controller.dart';
import '../../core/controller/drop_location_controller/drop_location_controller.dart';
import '../../core/controller/rental_controller/fetch_package_controller.dart';
import '../../core/controller/source_controller/source_controller.dart';
import '../../core/services/storage_services.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import 'package:wti_cabs_user/main.dart' show navigatorKey;
import '../inventory_list_screen/inventory_list.dart';
import '../select_location/select_drop.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;

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
  final PlaceSearchController searchController =
      Get.put(PlaceSearchController());
  final SourceLocationController sourceController =
      Get.put(SourceLocationController());
  final DestinationLocationController destinationLocationController =
      Get.put(DestinationLocationController());

  String address = '';

  @override
  void initState() {
    super.initState();
    // Ensure controllers are registered and apply any requested initial tab.
    // This is critical when navigating back from location selection screens.
    Get.put(BookingRideController());
    Get.put(PlaceSearchController());
    if (widget.initialTab != null && widget.initialTab!.trim().isNotEmpty) {
      bookingRideController.setTabByName(widget.initialTab!.trim());
    }
    setPickup();
    fetchPackageController.fetchPackages();

    // Defer observable updates to after build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (placeSearchController.suggestions.isNotEmpty) {
        bookingRideController.prefilled.value =
            placeSearchController.suggestions.first.primaryText ?? '';
      }
    });

    loadSeletedPackage();
  }

  Future<void> fetchCurrentLocationAndAddress() async {
    final loc = location.Location();

    //  Ensure service is enabled0
    if (!(await loc.serviceEnabled()) && !(await loc.requestService())) return;

    //  Ensure permission
    var permission = await loc.hasPermission();
    if (permission == location.PermissionStatus.denied) {
      permission = await loc.requestPermission();
      if (permission != location.PermissionStatus.granted) return;
    }

    //  Fetch current location
    final locData = await loc.getLocation();
    if (locData.latitude == null || locData.longitude == null) return;

    await _getAddressAndPrefillFromLatLng(
      LatLng(locData.latitude!, locData.longitude!),
    );
  }

  Future<void> _getAddressAndPrefillFromLatLng(LatLng latLng) async {
    try {
      // 1. Reverse geocode to get human-readable address
      final placemarks = await geocoding.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      debugPrint(
          'yash current lat/lng is ${latLng.latitude},${latLng.longitude}');

      if (placemarks.isEmpty) {
        setState(() => address = 'Address not found');
        return;
      }

      final place = placemarks.first;
      final components = <String>[
        place.name ?? '',
        place.street ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.administrativeArea ?? '',
        place.postalCode ?? '',
        place.country ?? '',
      ];
      final fullAddress =
          components.where((s) => s.trim().isNotEmpty).join(', ');

      // 2. Show address on UI immediately
      setState(() => address = fullAddress);

      // 3. Try searching the place (may fail or return empty)
      await placeSearchController.searchPlaces(fullAddress, context);

      if (placeSearchController.suggestions.isEmpty) {
        debugPrint("No search suggestions found for $fullAddress");
        setState(() => address = 'Address not found');
        return; // stop here – do not prefill controllers/storage
      }

      final suggestion = placeSearchController.suggestions.first;

      // 4. Update booking controller ONLY if valid suggestion exists
      bookingRideController.prefilled.value = fullAddress;
      placeSearchController.placeId.value = suggestion.placeId;

      // 5. Get lat/lng details - MUST be awaited
      await placeSearchController.getLatLngDetails(suggestion.placeId, context);

      // 6. Save all data to storage - MUST be awaited
      await StorageServices.instance.save('sourcePlaceId', suggestion.placeId);
      await StorageServices.instance
          .save('sourceTitle', suggestion.primaryText);
      await StorageServices.instance.save('sourceCity', suggestion.city);
      await StorageServices.instance.save('sourceState', suggestion.state);
      await StorageServices.instance.save('sourceCountry', suggestion.country);

      if (suggestion.types.isNotEmpty) {
        await StorageServices.instance.save(
          'sourceTypes',
          jsonEncode(suggestion.types),
        );
      }

      if (suggestion.terms.isNotEmpty) {
        await StorageServices.instance.save(
          'sourceTerms',
          jsonEncode(suggestion.terms),
        );
      }

      // 7. Update source controller - MUST be done after all data is ready
      sourceController.setPlace(
        placeId: suggestion.placeId,
        title: suggestion.primaryText,
        city: suggestion.city,
        state: suggestion.state,
        country: suggestion.country,
        types: suggestion.types,
        terms: suggestion.terms,
      );

      debugPrint('akash country: ${suggestion.country}');
      debugPrint('Current location address saved: $fullAddress');
    } catch (e) {
      debugPrint('Error fetching location/address: $e');
      setState(() => address = 'Error fetching address');
      rethrow; // Re-throw to let caller handle the error
    }
  }

  void setPickup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool("isFirstTime") ?? true;
      if (isFirstTime) {
        await fetchCurrentLocationAndAddress();
      }
    } catch (e) {
      debugPrint('Error in setPickup: $e');
      // Don't set address to error state here as it might not be the first time
    }
  }

  void loadSeletedPackage() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bookingRideController.selectedPackage.value =
          await StorageServices.instance.read('selectedPackage') ?? '';
    });
  }

  void _pushToBottomNav() {
    final rootCtx = navigatorKey.currentContext;
    if (rootCtx != null) {
      GoRouter.of(rootCtx).push(AppRoutes.bottomNav);
      return;
    }
    if (!mounted) return;
    GoRouter.of(context).push(AppRoutes.bottomNav);
  }

  void _pushToBookingRideSelf() {
    // Preserve the current tab, if any.
    final tab = bookingRideController.currentTabName.trim();
    final route = tab.isNotEmpty ? '${AppRoutes.bookingRide}?tab=$tab' : AppRoutes.bookingRide;

    final rootCtx = navigatorKey.currentContext;
    if (rootCtx != null) {
      GoRouter.of(rootCtx).push(route);
      return;
    }
    if (!mounted) return;
    GoRouter.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Disable iOS interactive swipe-back gesture.
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Always push BottomNav (no pop, no iOS swipe-back).
        _pushToBottomNav();
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
                        // Always use push (matches existing Android behavior).
                        _pushToBottomNav();
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
      Get.find<BookingRideController>();
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
                OutStation(
                  selectedTrip: 'oneWay',
                ),
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
  late final String? selectedTrip;

  OutStation({super.key, required this.selectedTrip});

  @override
  State<OutStation> createState() => _OutStationState();
}

class _OutStationState extends State<OutStation> {
  final BookingRideController bookingRideController =
      Get.find<BookingRideController>();
  final PlaceSearchController placeSearchController =
      Get.find<PlaceSearchController>();
  final DropPlaceSearchController dropPlaceSearchController =
      Get.find<DropPlaceSearchController>();
  final SearchCabInventoryController searchCabInventoryController =
      Get.find<SearchCabInventoryController>();
  final RxString selectedField = ''.obs;

  late final TextEditingController pickupController;
  late final TextEditingController dropController;
  late Worker _pickupWorker;
  late Worker _dropWorker;

  late String? _selectedTrip;
  final RxBool isSwitching = false.obs;
  final Duration defaultTripDuration = const Duration(hours: 4);
  final _debounceDuration = const Duration(milliseconds: 300);
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    _selectedTrip = widget.selectedTrip;

    pickupController =
        TextEditingController(text: bookingRideController.prefilled.value);
    dropController =
        TextEditingController(text: bookingRideController.prefilledDrop.value);

    _pickupWorker = debounce<String>(bookingRideController.prefilled, (value) {
      if (mounted && pickupController.text != value) {
        pickupController.text = value;
      }
    }, time: _debounceDuration);

    _dropWorker =
        debounce<String>(bookingRideController.prefilledDrop, (value) {
      if (mounted && dropController.text != value) {
        dropController.text = value;
      }
    }, time: _debounceDuration);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pickupWorker.dispose();
    _dropWorker.dispose();
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
    FocusScope.of(context).unfocus();

    try {
      final oldPickupId = placeSearchController.placeId.value;
      final oldDropId = dropPlaceSearchController.dropPlaceId.value;
      final oldPickupText = bookingRideController.prefilled.value;
      final oldDropText = bookingRideController.prefilledDrop.value;

      if (oldPickupId == oldDropId && oldPickupText == oldDropText) return;

      placeSearchController.placeId.value = oldDropId;
      dropPlaceSearchController.dropPlaceId.value = oldPickupId;
      bookingRideController.prefilled.value = oldDropText;
      bookingRideController.prefilledDrop.value = oldPickupText;

      pickupController.text = oldDropText;
      dropController.text = oldDropText;

      final futures = <Future>[];
      if (oldDropId.isNotEmpty) {
        futures.add(placeSearchController.getLatLngDetails(oldDropId, context));
      }
      if (oldPickupId.isNotEmpty) {
        futures.add(
            dropPlaceSearchController.getLatLngForDrop(oldPickupId, context));
      }
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

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

      final srcVals =
          await Future.wait(sourceKeys.map(StorageServices.instance.read));
      final destVals =
          await Future.wait(destinationKeys.map(StorageServices.instance.read));

      await Future.wait([
        ...List.generate(
            sourceKeys.length,
            (i) => StorageServices.instance
                .save(sourceKeys[i], destVals[i] ?? '')),
        ...List.generate(
            destinationKeys.length,
            (i) => StorageServices.instance
                .save(destinationKeys[i], srcVals[i] ?? '')),
      ]);
    } catch (e, st) {
      debugPrint('switchPickupAndDrop error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      bookingRideController.isSwitching.value = false;
    }
  }

  DateTime? _cachedLocalDateTime;
  DateTime? _cachedInitialDateTime;
  DateTime? _cachedDropLocalDateTime;

  DateTime getLocalDateTime() {
    if (_cachedLocalDateTime != null) return _cachedLocalDateTime!;

    final userDateTimeStr = placeSearchController
        .findCntryDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final offset = placeSearchController
        .findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (userDateTimeStr != null) {
      try {
        final utc = DateTime.parse(userDateTimeStr).toUtc();
        _cachedLocalDateTime = utc.add(Duration(minutes: offset ?? 0));
        debugPrint(
            '[getLocalDateTime] Parsed: ${_cachedLocalDateTime?.toString()}');
        return _cachedLocalDateTime!;
      } catch (e) {
        debugPrint('[getLocalDateTime] Error: $e');
      }
    }

    _cachedLocalDateTime = bookingRideController.localStartTime.value;
    return _cachedLocalDateTime!;
  }

  DateTime getInitialDateTime() {
    if (_cachedInitialDateTime != null) return _cachedInitialDateTime!;

    final actualDateTimeStr = placeSearchController
        .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualDateTime;
    final offset = placeSearchController
        .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet;

    if (actualDateTimeStr != null) {
      try {
        final utc = DateTime.parse(actualDateTimeStr).toUtc();
        _cachedInitialDateTime = utc.add(Duration(minutes: offset ?? 0));
        debugPrint(
            '[getInitialDateTime] Parsed: ${_cachedInitialDateTime?.toString()}');
        return _cachedInitialDateTime!;
      } catch (e) {
        debugPrint('[getInitialDateTime] Error: $e');
      }
    }

    _cachedInitialDateTime = getLocalDateTime();
    return _cachedInitialDateTime!;
  }

  DateTime getDropLocalDateTime() {
    if (_cachedDropLocalDateTime != null) return _cachedDropLocalDateTime!;

    final dropDateTimeStr = dropPlaceSearchController
        .dropDateTimeResponse.value?.userDateTimeObject?.userDateTime;
    final dropOffset = dropPlaceSearchController
        .dropDateTimeResponse.value?.userDateTimeObject?.userOffSet;

    if (dropDateTimeStr != null) {
      try {
        final utc = DateTime.parse(dropDateTimeStr).toUtc();
        _cachedDropLocalDateTime = utc.add(Duration(minutes: dropOffset ?? 0));
        debugPrint(
            '[getDropLocalDateTime] Parsed: ${_cachedDropLocalDateTime?.toString()}');
        return _cachedDropLocalDateTime!;
      } catch (e) {
        debugPrint('[getDropLocalDateTime] Error: $e');
      }
    }

    _cachedDropLocalDateTime =
        bookingRideController.localStartTime.value.add(defaultTripDuration);
    return _cachedDropLocalDateTime!;
  }

  void updateLocalStartTime(DateTime newDateTime) {
    final timezone =
        placeSearchController.findCntryDateTimeResponse.value?.timeZone ??
            placeSearchController.getCurrentTimeZoneName();
    final offset = placeSearchController.getOffsetFromTimeZone(timezone);

    bookingRideController.localStartTime.value = newDateTime;
    bookingRideController.utcStartTime.value =
        newDateTime.subtract(Duration(minutes: offset));

    final existingDrop = bookingRideController.localEndTime.value;
    final proposedDrop = newDateTime.add(defaultTripDuration);

    if (DateUtils.isSameDay(newDateTime, existingDrop) &&
        existingDrop.isBefore(proposedDrop)) {
      updateLocalEndTime(proposedDrop);
    }
  }

  void updateLocalEndTime(DateTime newDateTime) {
    final timezone =
        dropPlaceSearchController.dropDateTimeResponse.value?.timeZone ??
            dropPlaceSearchController.getCurrentTimeZoneName();
    final offset = dropPlaceSearchController.getOffsetFromTimeZone(timezone);

    if (newDateTime.isAfter(bookingRideController.localEndTime.value) ||
        newDateTime
            .isAtSameMomentAs(bookingRideController.localEndTime.value)) {
      bookingRideController.localEndTime.value = newDateTime;
      bookingRideController.utcEndTime.value =
          newDateTime.subtract(Duration(minutes: offset));
    }
  }

  Rx<DateTime?> dropDateTime = Rx<DateTime?>(null);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTripTypeSelector(context),
          const SizedBox(height: 24),
          if (_selectedTrip == 'oneWay') _buildOneWayUI(),
          if (_selectedTrip == 'roundTrip') _buildRoundTripUI(),
        ],
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
            _buildOption('One Way', 'oneWay', _selectedTrip == 'oneWay'),
            const SizedBox(width: 16),
            _verticalDivider(),
            _buildOption(
                'Round Trip', 'roundTrip', _selectedTrip == 'roundTrip'),
          ],
        ),
      ),
    );
  }

  Widget _buildOneWayUI() => _buildPickupDropUI(showDropDateTime: false);

  Widget _buildRoundTripUI() => _buildPickupDropUI(showDropDateTime: true);

  Widget _buildPickupDropUI({required bool showDropDateTime}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset('assets/images/circle.png', width: 40, height: 120),
              Expanded(
                child: Column(
                  children: [
                    BookingTextFormField(
                      hintText: 'Enter Pickup Location',
                      controller: pickupController,
                      errorText: _getPickupErrorText(),
                      onTap: () => _handleLocationTap(context, isPickup: true),
                    ),
                    const SizedBox(height: 12),
                    BookingTextFormField(
                      hintText: 'Enter Drop Location',
                      controller: dropController,
                      errorText: _getDropErrorText(),
                      onTap: () => _handleLocationTap(context, isPickup: false),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => switchPickupAndDrop(
                      context: context,
                      pickupController: pickupController,
                      dropController: dropController,
                    ),
                    child: Image.asset('assets/images/interchange.png',
                        width: 30, height: 30),
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
              Duration tripDuration = defaultTripDuration;

              try {
                final startTimeStr = searchCabInventoryController
                    .indiaData.value?.result?.tripType?.startTime
                    ?.toString();
                final endTimeStr = searchCabInventoryController
                    .indiaData.value?.result?.tripType?.endTime
                    ?.toString();
                if (startTimeStr != null && endTimeStr != null) {
                  tripDuration = DateTime.parse(endTimeStr)
                      .difference(DateTime.parse(startTimeStr));
                }
              } catch (e) {
                debugPrint(
                    '[buildPickupDropUI] Error calculating trip duration: $e');
              }

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
                                localStart.minute);
                            updateLocalStartTime(updated);
                            final minDrop = updated.add(tripDuration);
                            if (DateUtils.isSameDay(
                                    bookingRideController.localEndTime.value,
                                    updated) &&
                                bookingRideController.localEndTime.value
                                    .isBefore(minDrop)) {
                              updateLocalEndTime(minDrop);
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
                                pickedTime.minute);
                            updateLocalStartTime(updatedPickup);
                            final minAllowedDrop =
                                updatedPickup.add(tripDuration);
                            if (DateUtils.isSameDay(updatedPickup,
                                    bookingRideController.localEndTime.value) &&
                                bookingRideController.localEndTime.value
                                    .isBefore(minAllowedDrop)) {
                              updateLocalEndTime(minAllowedDrop);
                            }
                            bookingRideController.localStartTime.refresh();
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
                      initialDateTime: localStart.add(tripDuration),
                      minimumDate: localStart.add(tripDuration),
                      onDateTimeSelected: (picked) {
                        final minDrop = bookingRideController
                            .localStartTime.value
                            .add(tripDuration);
                        updateLocalEndTime(
                            picked.isBefore(minDrop) ? minDrop : picked);
                        bookingRideController.localEndTime.refresh();
                      },
                    ),
                  ],
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Obx(() => bookingRideController.isInvalidTime.value
              ? Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    border: Border.all(color: Colors.redAccent, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "The earliest booking slot available at ${bookingRideController.selectedLocalDate.value}, ${bookingRideController.selectedLocalTime.value}.",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink()),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: Obx(() {
                final sourceValue =
                    bookingRideController.prefilled.value.trim();
                final dropValue =
                    bookingRideController.prefilledDrop.value.trim();
                final sourcePlaceId = placeSearchController.placeId.value;
                final dropPlaceId = dropPlaceSearchController.dropPlaceId.value;

                final isSourceEmpty =
                    sourceValue.isEmpty && sourcePlaceId.isEmpty;
                final isDropEmpty = dropValue.isEmpty && dropPlaceId.isEmpty;
                final isDisabled = isSourceEmpty || isDropEmpty;

                return PrimaryButton(
                  text: 'Search Now',
                  isLoading: _isSearching,
                  onPressed: isDisabled
                      ? null
                      : () {
                          // Haptic feedback for smooth tap response
                          HapticFeedback.lightImpact();

                          if (_isSearching) return;
                          setState(() => _isSearching = true);

                          // Defer heavy operations to allow button animation to complete smoothly
                          SchedulerBinding.instance
                              .addPostFrameCallback((_) async {
                            try {
                              // ✅ FAST PATH: Check countries immediately if already available
                              var sourceCountry = placeSearchController
                                      .getPlacesLatLng.value?.country
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              var destinationCountry = dropPlaceSearchController
                                      .dropLatLng.value?.country
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';

                              // If countries are available, check immediately (fast path)
                              if (sourceCountry.isNotEmpty &&
                                  destinationCountry.isNotEmpty) {
                                if (sourceCountry != destinationCountry) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Pickup and drop countries must be the same.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return; // ✅ Fast return if countries don't match
                                }
                              }

                              // ✅ Fetch lat/lng APIs in parallel only if needed
                              final futures = <Future>[];
                              if (placeSearchController
                                      .placeId.value.isNotEmpty &&
                                  placeSearchController.getPlacesLatLng.value ==
                                      null) {
                                futures.add(placeSearchController
                                    .getLatLngDetails(
                                        placeSearchController.placeId.value,
                                        context)
                                    .catchError((e) => debugPrint(
                                        'Error fetching source lat/lng: $e')));
                              }
                              if (dropPlaceSearchController
                                      .dropPlaceId.value.isNotEmpty &&
                                  dropPlaceSearchController.dropLatLng.value ==
                                      null) {
                                futures.add(dropPlaceSearchController
                                    .getLatLngForDrop(
                                        dropPlaceSearchController
                                            .dropPlaceId.value,
                                        context)
                                    .catchError((e) => debugPrint(
                                        'Error fetching destination lat/lng: $e')));
                              }

                              // Wait for APIs in parallel if needed
                              if (futures.isNotEmpty) {
                                await Future.wait(futures);
                                // Re-check countries after APIs complete
                                sourceCountry = placeSearchController
                                        .getPlacesLatLng.value?.country
                                        ?.toString()
                                        .toLowerCase() ??
                                    '';
                                destinationCountry = dropPlaceSearchController
                                        .dropLatLng.value?.country
                                        ?.toString()
                                        .toLowerCase() ??
                                    '';
                              }

                              // ✅ Final country validation
                              if (sourceCountry.isEmpty ||
                                  destinationCountry.isEmpty) {
                                return;
                              }

                              if (sourceCountry != destinationCountry) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Pickup and drop countries must be the same.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return; // ✅ CRITICAL: Return early, do NOT build request data or call API
                              }

                              // Only build request data if countries match
                              final requestData =
                                  await _buildOutstationRequestData(context);

                              // Only call API if countries match
                              await searchCabInventoryController
                                  .fetchBookingData(
                                country: placeSearchController
                                        .getPlacesLatLng.value?.country ??
                                    '',
                                requestData: requestData,
                                context: context,
                              );

                              Duration tripDuration = defaultTripDuration;
                              DateTime? backendEndTime;
                              try {
                                final startTimeStr =
                                    searchCabInventoryController.indiaData.value
                                        ?.result?.tripType?.startTime
                                        ?.toString();
                                final endTimeStr = searchCabInventoryController
                                    .indiaData.value?.result?.tripType?.endTime
                                    ?.toString();
                                if (startTimeStr != null &&
                                    endTimeStr != null) {
                                  final startTime =
                                      DateTime.parse(startTimeStr);
                                  backendEndTime = DateTime.parse(endTimeStr);
                                  tripDuration =
                                      backendEndTime.difference(startTime);
                                }
                              } catch (e) {
                                debugPrint(
                                    '[SearchNow] Error calculating trip duration: $e');
                              }

                              final startTime =
                                  bookingRideController.localStartTime.value;
                              final currentEndTime =
                                  bookingRideController.localEndTime.value;
                              final defaultEndTime =
                                  startTime.add(tripDuration);

                              if (backendEndTime != null &&
                                  backendEndTime
                                      .toLocal()
                                      .isAfter(currentEndTime)) {
                                updateLocalEndTime(backendEndTime.toLocal());
                              } else if (currentEndTime
                                  .isBefore(defaultEndTime)) {
                                updateLocalEndTime(defaultEndTime);
                              }

                              bookingRideController.localEndTime.refresh();

                              Navigator.push(
                                context,
                                Platform.isIOS
                                    ? CupertinoPageRoute(
                                        builder: (context) => InventoryList(
                                            requestData: requestData),
                                      )
                                    : MaterialPageRoute(
                                        builder: (context) => InventoryList(
                                            requestData: requestData),
                                      ),
                              );
                              // Navigator.of(context).pop();
                            } catch (e) {
                              debugPrint('[SearchNow] Error: $e');
                              if (mounted) {
                                // Navigate to inventory list with error message
                                Navigator.push(
                                  context,
                                  Platform.isIOS
                                      ? CupertinoPageRoute(
                                          builder: (context) => InventoryList(
                                                requestData: const {
                                                  'noInventoryMessage':
                                                      'No Inventory Found, Please try again!',
                                                },
                                              ))
                                      : MaterialPageRoute(
                                          builder: (context) => InventoryList(
                                                requestData: const {
                                                  'noInventoryMessage':
                                                      'No Inventory Found, Please try again!',
                                                },
                                              )),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isSearching = false);
                            }
                          });
                        },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String? _getPickupErrorText() {
    final pickupId = placeSearchController.placeId.value.trim();
    final dropId = dropPlaceSearchController.dropPlaceId.value.trim();

    //  Fix: Only show error if both text and placeId are empty
    if (pickupController.text.trim().isEmpty && pickupId.isEmpty) {
      return "Please enter pickup location";
    }

    if (pickupId.isNotEmpty && dropId.isNotEmpty && pickupId == dropId) {
      return "Pickup and Drop cannot be the same";
    }

    if (placeSearchController.findCntryDateTimeResponse.value?.sourceInput ==
            true ||
        dropPlaceSearchController.dropDateTimeResponse.value?.sourceInput ==
            true) {
      return "We don't offer services from this region";
    }

    return null;
  }

  String? _getDropErrorText() {
    final pickupId = placeSearchController.placeId.value;
    final dropId = dropPlaceSearchController.dropPlaceId.value;

    if (dropId.isEmpty) return "Please enter drop location";
    if (pickupId.isNotEmpty && dropId.isNotEmpty && pickupId == dropId)
      return "Pickup and Drop cannot be the same";
    if (placeSearchController
                .findCntryDateTimeResponse.value?.destinationInputFalse ==
            true ||
        dropPlaceSearchController
                .dropDateTimeResponse.value?.destinationInputFalse ==
            true) {
      return "We don't offer services from this region";
    }
    return null;
  }

  void _handleLocationTap(BuildContext context,
      {required bool isPickup}) async {
    final startTime = bookingRideController.localStartTime.value;
    if (startTime.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
      final resetEndTime = startTime.add(defaultTripDuration);
      updateLocalEndTime(resetEndTime);
      bookingRideController.localEndTime.refresh();
      bookingRideController.isInvalidTime.value = false;
      searchCabInventoryController.indiaData.value = null;
    }

    if (isPickup) {
      final result = await Navigator.push(
        context,
        Platform.isIOS
            ? CupertinoPageRoute(
                builder: (context) => const SelectPickup(),
              )
            : MaterialPageRoute(
                builder: (context) => const SelectPickup(),
              ),
      );

      // Ensure all three APIs are called after returning from SelectPickup
      if (placeSearchController.placeId.value.isNotEmpty) {
        try {
          await placeSearchController.getLatLngDetails(
              placeSearchController.placeId.value, context);
        } catch (e) {
          debugPrint('Error fetching source details after navigation: $e');
          // Continue even if API fails
        }
      }
    } else {
      final result = await Navigator.push(
        context,
        Platform.isIOS
            ? CupertinoPageRoute(
                builder: (context) => const SelectDrop(
                    fromInventoryScreen: false, fromHomeScreen: false),
              )
            : MaterialPageRoute(
                builder: (context) => const SelectDrop(
                    fromInventoryScreen: false, fromHomeScreen: false),
              ),
      );

      // Ensure all three APIs are called after returning from SelectDrop
      if (dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
        try {
          await dropPlaceSearchController.getLatLngForDrop(
              dropPlaceSearchController.dropPlaceId.value, context);
        } catch (e) {
          debugPrint('Error fetching destination details after navigation: $e');
          // Continue even if API fails
        }
      }
    }
  }

  String getDurationInHours(DateTime start, DateTime end) {
    return (end.difference(start).inMinutes / 60).toStringAsFixed(2);
  }

  Future<Map<String, dynamic>> _buildOutstationRequestData(
      BuildContext context) async {
    // Loader is already shown on button tap, no need to show again

    final now = DateTime.now();
    final searchDate = now.toIso8601String().split('T').first;
    final searchTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
      'sourceTypes',
      'sourceTerms',
      'destinationPlaceId',
      'destinationTitle',
      'destinationTypes',
      'destinationTerms',
    ];

    final values = await Future.wait(keys.map(StorageServices.instance.read));
    final data = Map<String, dynamic>.fromIterables(keys, values);
    final isRoundTrip = _selectedTrip != 'oneWay';

    final dateFormat = DateFormat('EEEE, dd MMM, yyyy h:mm a');
    final pickupDateTime =
        bookingRideController.localStartTime.value.toUtc() != null
            ? dateFormat.format(
                bookingRideController.localStartTime.value.toUtc() ??
                    DateTime.now())
            : '';
    final returnDateTime = bookingRideController.localEndTime.value
                .toUtc()
                .toIso8601String() !=
            null
        ? dateFormat.format(
            bookingRideController.localEndTime.value.toUtc() ?? DateTime.now())
        : '';

    // search Analytics GA4 event tracking
    final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
    //  Send to Firebase Analytics
    await _analytics.logSearch(
      searchTerm: '${data['sourceTitle']} to ${data['destinationTitle']}',
      numberOfPassengers: 1,
      origin: placeSearchController.getPlacesLatLng.value?.city.toString(),
      destination: dropPlaceSearchController.dropLatLng.value!.city.toString(),
      startDate: pickupDateTime,
      endDate: returnDateTime,
      parameters: {
        'event': 'search',
        'trip_type': isRoundTrip ? 'One_way' : 'Round_way',
        'user_status': 'logged_out',
        'search_source': 'home_screen',
      },
    );
    // ========================================

    // Get fallback values from controllers if storage is null
    final sourceTitle = data['sourceTitle'] ??
        bookingRideController.prefilled.value ??
        placeSearchController.suggestions.firstOrNull?.primaryText ??
        '';
    final actualOffset = data['actualOffset'] ??
        placeSearchController
            .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet
            ?.toString() ??
        offset.toString();
    final timeZone = data['timeZone'] ??
        placeSearchController.findCntryDateTimeResponse.value?.timeZone ??
        placeSearchController.getCurrentTimeZoneName();
    final actualTimeWithOffset = data['actualTimeWithOffset'] ??
        (placeSearchController.findCntryDateTimeResponse.value
                    ?.actualDateTimeObject?.actualDateTime !=
                null
            ? placeSearchController.convertToIsoWithOffset(
                placeSearchController.findCntryDateTimeResponse.value!
                    .actualDateTimeObject!.actualDateTime!,
                -(placeSearchController.findCntryDateTimeResponse.value!
                        .actualDateTimeObject!.actualOffSet ??
                    0))
            : DateTime.now().toIso8601String());
    final userTimeWithOffset = data['userTimeWithOffset'] ??
        (placeSearchController.findCntryDateTimeResponse.value
                    ?.userDateTimeObject?.userDateTime !=
                null
            ? placeSearchController.convertToIsoWithOffset(
                placeSearchController.findCntryDateTimeResponse.value!
                    .userDateTimeObject!.userDateTime!,
                -(placeSearchController.findCntryDateTimeResponse.value!
                        .userDateTimeObject!.userOffSet ??
                    0))
            : DateTime.now().toIso8601String());
    final userOffset = data['userOffset'] ??
        placeSearchController
            .findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet
            ?.toString() ??
        offset.toString();

    // Get source terms from suggestion if available
    List<Map<String, dynamic>> sourceTerms =
        _parseList<Map<String, dynamic>>(data['sourceTerms']);
    if (sourceTerms.isEmpty && placeSearchController.suggestions.isNotEmpty) {
      final suggestion = placeSearchController.suggestions.first;
      if (suggestion.terms.isNotEmpty) {
        sourceTerms = suggestion.terms
            .map((term) => {
                  'offset': term.offset,
                  'value': term.value,
                })
            .toList();
      }
    }

    return {
      // Used by InventoryList to decide whether to show the Trip Updated dialog.
      "applicationType": "APP",
      "comingFrom": "searchInventory api 2nd page -APP",
      "inventoryEntryPoint": "booking_ride",
      "timeOffSet": -offset,
      "countryName": data['country'] ?? 'India',
      "searchDate": searchDate,
      "searchTime": searchTime,
      "offset": int.parse(userOffset),
      "pickupDateAndTime": bookingRideController.convertLocalToUtc(),
      "returnDateAndTime": isRoundTrip
          ? bookingRideController.localEndTime.value.toUtc().toIso8601String()
          : "",
      "tripCode": isRoundTrip ? "1" : "0",
      "source": {
        "sourceTitle": sourceTitle,
        "sourcePlaceId":
            data['sourcePlaceId'] ?? placeSearchController.placeId.value,
        "sourceCity":
            placeSearchController.getPlacesLatLng.value?.city.toString() ?? '',
        "sourceState":
            placeSearchController.getPlacesLatLng.value?.state.toString() ?? '',
        "sourceCountry":
            placeSearchController.getPlacesLatLng.value?.country.toString() ??
                'India',
        "sourceType": _parseList<String>(data['sourceTypes']),
        "sourceLat": placeSearchController.getPlacesLatLng.value?.latLong.lat
                .toString() ??
            '',
        "sourceLng": placeSearchController.getPlacesLatLng.value?.latLong.lng
                .toString() ??
            '',
        "terms": sourceTerms,
      },
      "destination": {
        "destinationTitle": data['destinationTitle'] ??
            bookingRideController.prefilledDrop.value ??
            '',
        "destinationPlaceId": data['destinationPlaceId'] ??
            dropPlaceSearchController.dropPlaceId.value,
        "destinationCity":
            dropPlaceSearchController.dropLatLng.value?.city.toString() ?? '',
        "destinationState":
            dropPlaceSearchController.dropLatLng.value?.state.toString() ?? '',
        "destinationCountry":
            dropPlaceSearchController.dropLatLng.value?.country.toString() ??
                'India',
        "destinationType": _parseList<String>(data['destinationTypes']),
        "destinationLat": dropPlaceSearchController
                .dropLatLng.value?.latLong.lat
                .toString() ??
            '',
        "destinationLng": dropPlaceSearchController
                .dropLatLng.value?.latLong.lng
                .toString() ??
            '',
        "terms": _parseList<Map<String, dynamic>>(data['destinationTerms']),
      },
      "packageSelected": {"km": "", "hours": ""},
      "stopsArray": [],
      "pickUpTime": {
        "time": actualTimeWithOffset,
        "offset": actualOffset,
        "timeZone": timeZone
      },
      "dropTime": isRoundTrip
          ? {
              "time": bookingRideController.localEndTime.value
                  .toUtc()
                  .toIso8601String(),
              "offset": actualOffset,
              "timeZone": timeZone
            }
          : {},
      "mindate": {
        "date": userTimeWithOffset,
        "time": userTimeWithOffset,
        "offset": userOffset,
        "timeZone": timeZone
      },
      "isGlobal":
          (data['country']?.toLowerCase() ?? 'india') == 'india' ? false : true,
    };
  }

  Widget _buildOption(String title, String value, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedTrip = value),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Radio<String>(
              value: value,
              groupValue: _selectedTrip,
              onChanged: (val) => setState(() => _selectedTrip = val!),
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
  final ButtonStateController buttonStateController = Get.put(
    ButtonStateController(
      placeSearchController: Get.find<PlaceSearchController>(),
      dropPlaceSearchController: Get.find<DropPlaceSearchController>(),
      bookingRideController: Get.find<BookingRideController>(),
    ),
  );
  final RxString selectedField = ''.obs;

  // Declare TextEditingControllers as class-level variables
  late TextEditingController ridePickupController;
  late TextEditingController rideDropController;
  late Worker _ridePickupWorker;
  late Worker _rideDropWorker;
  bool _isLoading = false;
  final RxBool isSwitching = false.obs;

  Future<void> switchPickupAndDrop({
    required BuildContext context,
    required TextEditingController pickupController,
    required TextEditingController dropController,
  }) async {
    //  Debounce: ignore if already switching
    if (bookingRideController.isSwitching.value) return;

    bookingRideController.isSwitching.value = true;
    FocusScope.of(context)
        .unfocus(); // avoid onChanged side-effects during swap

    try {
      // Snapshot current values
      final oldPickupId = placeSearchController.placeId.value.trim();
      final oldDropId = dropPlaceSearchController.dropPlaceId.value.trim();
      final oldPickupText = bookingRideController.prefilled.value;
      final oldDropText = bookingRideController.prefilledDrop.value;

      // Nothing to do?
      final idsSame = oldPickupId == oldDropId;
      final textsSame = oldPickupText == oldDropText;
      if (idsSame && textsSame) return;

      // ---------- 1) Swap observables (single source of truth) ----------
      placeSearchController.placeId.value = oldDropId;
      dropPlaceSearchController.dropPlaceId.value = oldPickupId;

      bookingRideController.prefilled.value = oldDropText;
      bookingRideController.prefilledDrop.value = oldPickupText;

      // ---------- 2) Update text fields (cursor at end, minimal noise) ----------
      pickupController.value = TextEditingValue(
        text: bookingRideController.prefilled.value,
        selection: TextSelection.collapsed(
            offset: bookingRideController.prefilled.value.length),
      );
      dropController.value = TextEditingValue(
        text: bookingRideController.prefilledDrop.value,
        selection: TextSelection.collapsed(
            offset: bookingRideController.prefilledDrop.value.length),
      );

      // ---------- 3) Refresh geocode/latlng IN PARALLEL ----------
      final futures = <Future>[];
      final newPickupId = placeSearchController.placeId.value;
      final newDropId = dropPlaceSearchController.dropPlaceId.value;

      if (newPickupId.isNotEmpty) {
        futures
            .add(placeSearchController.getLatLngDetails(newPickupId, context));
      }
      if (newDropId.isNotEmpty) {
        futures.add(
            dropPlaceSearchController.getLatLngForDrop(newDropId, context));
      }
      await Future.wait(futures); // ensures consistent state before moving on

      // ---------- 4) Swap cached/local storage IN PARALLEL ----------
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

      // Read both sets concurrently
      final srcVals =
          await Future.wait(sourceKeys.map(StorageServices.instance.read));
      final destVals =
          await Future.wait(destinationKeys.map(StorageServices.instance.read));

      // Write both directions concurrently
      await Future.wait([
        ...List.generate(
            sourceKeys.length,
            (i) => StorageServices.instance
                .save(sourceKeys[i], (destVals[i] ?? '').toString())),
        ...List.generate(
            destinationKeys.length,
            (i) => StorageServices.instance
                .save(destinationKeys[i], (srcVals[i] ?? '').toString())),
      ]);
    } catch (e, st) {
      // Optional: log your error handler
      debugPrint('switchPickupAndDrop error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      bookingRideController.isSwitching.value = false;
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

    // setLocation();

    // Listen to changes in prefilled and prefilledDrop to update controllers
    _ridePickupWorker = ever<String>(bookingRideController.prefilled, (val) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            ridePickupController.text = val;
          });
        }
      });
    });

    _rideDropWorker = ever<String>(bookingRideController.prefilledDrop, (val) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            rideDropController.text = val;
          });
        }
      });
    });
  }

  void setLocation() {
    setState(() {
      ridePickupController.text = bookingRideController.prefilled.value;
      rideDropController.text = bookingRideController.prefilledDrop.value;
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
        debugPrint("Error parsing userDateTime: $e");
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
        debugPrint("Error parsing actualDateTime: $e");
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
                              final pickupId =
                                  placeSearchController.placeId.value.trim();
                              final dropId = dropPlaceSearchController
                                  .dropPlaceId.value
                                  .trim();

                              //  Fix: only show error if controller text is empty AND placeId is empty
                              if (ridePickupController.text.trim().isEmpty &&
                                  pickupId.isEmpty) {
                                return "Please enter pickup location";
                              }

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
                            onTap: () async {
                              setState(() {
                                ridePickupController.text =
                                    bookingRideController.prefilled.value;
                                rideDropController.text =
                                    bookingRideController.prefilledDrop.value;
                              });
                              bookingRideController.isInvalidTime.value = false;
                              final result = await Navigator.push(
                                context,
                                Platform.isIOS
                                    ? CupertinoPageRoute(
                                        builder: (context) =>
                                            const SelectPickup(),
                                      )
                                    : MaterialPageRoute(
                                        builder: (context) =>
                                            const SelectPickup(),
                                      ),
                              );

                              // Ensure all three APIs are called after returning from SelectPickup
                              if (placeSearchController
                                  .placeId.value.isNotEmpty) {
                                await placeSearchController.getLatLngDetails(
                                    placeSearchController.placeId.value,
                                    context);
                              }
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

                                if (dropId.isEmpty) {
                                  return "Please enter drop location";
                                }

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
                                    dropPlaceSearchController
                                            .dropDateTimeResponse
                                            .value
                                            ?.destinationInputFalse ==
                                        true) {
                                  return "We don't offer services from this region";
                                }

                                return null;
                              })(),
                              onTap: () async {
                                bookingRideController.isInvalidTime.value =
                                    false;
                                final result = await Navigator.push(
                                  context,
                                  Platform.isIOS
                                      ? CupertinoPageRoute(
                                          builder: (context) =>
                                              const SelectDrop(
                                            fromInventoryScreen: false,
                                            fromHomeScreen: false,
                                          ),
                                        )
                                      : MaterialPageRoute(
                                          builder: (context) =>
                                              const SelectDrop(
                                            fromInventoryScreen: false,
                                            fromHomeScreen: false,
                                          ),
                                        ),
                                );

                                // Ensure all three APIs are called after returning from SelectDrop
                                if (dropPlaceSearchController
                                    .dropPlaceId.value.isNotEmpty) {
                                  await dropPlaceSearchController
                                      .getLatLngForDrop(
                                          dropPlaceSearchController
                                              .dropPlaceId.value,
                                          context);
                                }
                              }),
                        ],
                      )),
                ),
                Column(
                  children: [
                    // Icon(Icons.info_outline, color: AppColors.blue5),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        switchPickupAndDrop(
                            context: context,
                            pickupController: ridePickupController,
                            dropController: rideDropController);
                      },
                      child: Transform.translate(
                        offset: const Offset(0, 0),
                        child: Image.asset('assets/images/interchange.png',
                            width: 30, height: 30),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Icon(Icons.add_circle_outline, color: AppColors.blue5),
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

                return Row(
                  children: [
                    Expanded(
                      child: DatePickerTile(
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

                            if (DateUtils.isSameDay(
                                newDate, actualMinDateTime)) {
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
                    ),
                    SizedBox(width: 16),
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

                          if (!updatedTime.isAtSameMomentAs(
                              bookingRideController.localStartTime.value)) {
                            debugPrint(
                                'yash 22 local start time : ${bookingRideController.localStartTime.value}');
                            updateLocalStartTime(updatedTime);
                            bookingRideController.localStartTime
                                .refresh(); // 🔁 Force rebuild on same value
                          } else {
                            debugPrint(
                                'yash 22 local start time : ${bookingRideController.localStartTime.value}');
                            bookingRideController.localStartTime
                                .refresh(); // 🔁 Force rebuild on same value
                          }
                        },
                        controller: placeSearchController,
                      ),
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
            Obx(() {
              return bookingRideController.isInvalidTime.value
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        border: Border.all(color: Colors.redAccent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "The earliest booking slot available at ${bookingRideController.selectedLocalDate.value}, ${bookingRideController.selectedLocalTime.value}.",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox();
            }),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final sourceValue =
                      bookingRideController.prefilled.value.trim();
                  final sourcePlaceId = placeSearchController.placeId.value;

                  final isSourceEmpty =
                      sourceValue.isEmpty && sourcePlaceId.isEmpty;
                  // ✅ Rental: destination is optional; enable button if pickup exists.
                  final isDisabled = isSourceEmpty;

                  return PrimaryButton(
                    text: 'Search Now',
                    isLoading: _isLoading,
                    onPressed: isDisabled
                        ? null
                        : () {
                            // Haptic feedback for smooth tap response
                            HapticFeedback.lightImpact();

                            if (_isLoading) return;
                            setState(() => _isLoading = true);

                            // Defer heavy operations to allow button animation to complete smoothly
                            SchedulerBinding.instance
                                .addPostFrameCallback((_) async {
                              // ✅ FAST PATH: Check countries immediately if already available
                              var sourceCountry = placeSearchController
                                      .getPlacesLatLng.value?.country
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              var destinationCountry = dropPlaceSearchController
                                      .dropLatLng.value?.country
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';

                              // If countries are available, check immediately (fast path)
                              if (sourceCountry.isNotEmpty &&
                                  destinationCountry.isNotEmpty) {
                                if (sourceCountry != destinationCountry) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Pickup and drop countries must be the same.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return; // ✅ Fast return if countries don't match
                                }
                              }

                              // ✅ Fetch lat/lng APIs in parallel only if needed
                              final futures = <Future>[];
                              if (placeSearchController
                                      .placeId.value.isNotEmpty &&
                                  placeSearchController.getPlacesLatLng.value ==
                                      null) {
                                futures.add(placeSearchController
                                    .getLatLngDetails(
                                        placeSearchController.placeId.value,
                                        context)
                                    .catchError((e) => debugPrint(
                                        'Error fetching source lat/lng: $e')));
                              }
                              if (dropPlaceSearchController
                                      .dropPlaceId.value.isNotEmpty &&
                                  dropPlaceSearchController.dropLatLng.value ==
                                      null) {
                                futures.add(dropPlaceSearchController
                                    .getLatLngForDrop(
                                        dropPlaceSearchController
                                            .dropPlaceId.value,
                                        context)
                                    .catchError((e) => debugPrint(
                                        'Error fetching destination lat/lng: $e')));
                              }

                              // Wait for APIs in parallel if needed
                              if (futures.isNotEmpty) {
                                await Future.wait(futures);
                                // Re-check countries after APIs complete
                                sourceCountry = placeSearchController
                                        .getPlacesLatLng.value?.country
                                        ?.toString()
                                        .toLowerCase() ??
                                    '';
                                destinationCountry = dropPlaceSearchController
                                        .dropLatLng.value?.country
                                        ?.toString()
                                        .toLowerCase() ??
                                    '';
                              }

                              // ✅ Final country validation
                              if (sourceCountry.isEmpty ||
                                  destinationCountry.isEmpty) {
                                return;
                              }

                              if (sourceCountry != destinationCountry) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Pickup and drop countries must be the same.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return; // ✅ CRITICAL: Return early, do NOT call _buildRequestData which has GoRouter.pop()
                              }

                              // Only build request data if countries match
                              try {
                                final requestData =
                                    await _buildRequestData(context);

                                // Only navigate if countries match (API will be called from inventory list screen)
                                GoRouter.of(context).push(
                                  AppRoutes.inventoryList,
                                  extra: requestData,
                                );
                              } catch (e) {
                                debugPrint('[SearchNow] Error: $e');
                                if (mounted) {
                                  // Navigate to inventory list with error message
                                  GoRouter.of(context).push(
                                    AppRoutes.inventoryList,
                                    extra: const {
                                      'noInventoryMessage':
                                          'No Inventory Found, Please try again!',
                                    },
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            });
                          },
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

Future<Map<String, dynamic>> _buildRequestData(BuildContext context) async {
  final DropPlaceSearchController dropPlaceSearchController =
      Get.put(DropPlaceSearchController());
  final PlaceSearchController placeSearchController =
      Get.put(PlaceSearchController());
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  // Loader is already shown on button tap, no need to show again
  final now = DateTime.now();
  final searchDate = now.toIso8601String().split('T').first;
  final searchTime =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

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
    'sourceTypes',
    'sourceTerms',
    'destinationPlaceId',
    'destinationTitle',
    'destinationTypes',
    'destinationTerms',
  ];

  final values = await Future.wait(keys.map(StorageServices.instance.read));
  final Map<String, dynamic> data = Map.fromIterables(keys, values);
  final dateFormat = DateFormat('EEEE, dd MMM, yyyy h:mm a');
  final pickupDateTime = bookingRideController.localStartTime.value.toUtc() !=
          null
      ? dateFormat.format(
          bookingRideController.localStartTime.value.toUtc() ?? DateTime.now())
      : '';
  final returnDateTime = bookingRideController.localEndTime.value
              .toUtc()
              .toIso8601String() !=
          null
      ? dateFormat.format(
          bookingRideController.localEndTime.value.toUtc() ?? DateTime.now())
      : '';
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  await _analytics.logSearch(
    searchTerm: '${data['sourceTitle']} to ${data['destinationTitle']}',
    numberOfPassengers: 1,
    origin: placeSearchController.getPlacesLatLng.value?.city.toString(),
    destination: dropPlaceSearchController.dropLatLng.value!.city.toString(),
    startDate: pickupDateTime,
    endDate: returnDateTime,
    parameters: {
      'event': 'search',
      'trip_type': 'Airport',
      'user_status': 'logged_out',
      'search_source': 'home_screen',
    },
  );

  debugPrint('yash pickup utc time : ${data['userDateTime']}');
  debugPrint(
      'yash 22aug local start time : ${bookingRideController.localStartTime.value}');
  debugPrint(
      'yash 22aug local selected time : ${bookingRideController.selectedDateTime.value}');
  // Get fallback values from controllers if storage is null
  final sourceTitle = data['sourceTitle'] ??
      bookingRideController.prefilled.value ??
      (placeSearchController.suggestions.isNotEmpty
          ? placeSearchController.suggestions.first.primaryText
          : '');
  final actualOffset = data['actualOffset'] ??
      placeSearchController
          .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet
          ?.toString() ??
      offset.toString();
  final timeZone = data['timeZone'] ??
      placeSearchController.findCntryDateTimeResponse.value?.timeZone ??
      placeSearchController.getCurrentTimeZoneName();
  final actualTimeWithOffset = data['actualTimeWithOffset'] ??
      (placeSearchController.findCntryDateTimeResponse.value
                  ?.actualDateTimeObject?.actualDateTime !=
              null
          ? placeSearchController.convertToIsoWithOffset(
              placeSearchController.findCntryDateTimeResponse.value!
                  .actualDateTimeObject!.actualDateTime!,
              -(placeSearchController.findCntryDateTimeResponse.value!
                      .actualDateTimeObject!.actualOffSet ??
                  0))
          : DateTime.now().toIso8601String());
  final userTimeWithOffset =
      data['userTimeWithOffset'] ??
          (placeSearchController.findCntryDateTimeResponse.value
                      ?.userDateTimeObject?.userDateTime !=
                  null
              ? placeSearchController.convertToIsoWithOffset(
                  placeSearchController.findCntryDateTimeResponse.value!
                      .userDateTimeObject!.userDateTime!,
                  -(placeSearchController.findCntryDateTimeResponse.value!
                          .userDateTimeObject!.userOffSet ??
                      0))
              : DateTime.now().toIso8601String());
  final userOffset = data['userOffset'] ??
      placeSearchController
          .findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet
          ?.toString() ??
      offset.toString();

  // Get source terms from suggestion if available
  List<Map<String, dynamic>> sourceTerms =
      _parseList<Map<String, dynamic>>(data['sourceTerms']);
  if (sourceTerms.isEmpty && placeSearchController.suggestions.isNotEmpty) {
    final suggestion = placeSearchController.suggestions.first;
    if (suggestion.terms.isNotEmpty) {
      sourceTerms = suggestion.terms.map((term) => term.toJson()).toList();
    }
  }

  return {
    // Used by InventoryList to decide whether to show the Trip Updated dialog.
    "applicationType": "APP",
    "comingFrom": "searchInventory api 2nd page -APP",
    "inventoryEntryPoint": "booking_ride",
    "timeOffSet": -offset,
    "countryName": data['country'] ?? 'India',
    "searchDate": searchDate,
    "searchTime": searchTime,
    "offset": int.parse(userOffset),
    // "pickupDateAndTime": data['userDateTime'],
    "pickupDateAndTime": bookingRideController.convertLocalToUtc(),
    "returnDateAndTime": "",
    "tripCode": "2",
    "source": {
      "sourceTitle": sourceTitle,
      "sourcePlaceId":
          data['sourcePlaceId'] ?? placeSearchController.placeId.value,
      "sourceCity":
          placeSearchController.getPlacesLatLng.value?.city.toString() ?? '',
      "sourceState":
          placeSearchController.getPlacesLatLng.value?.state.toString() ?? '',
      "sourceCountry":
          placeSearchController.getPlacesLatLng.value?.country.toString() ??
              'India',
      "sourceType": _parseList<String>(data['sourceTypes']),
      "sourceLat":
          placeSearchController.getPlacesLatLng.value?.latLong.lat.toString() ??
              '',
      "sourceLng":
          placeSearchController.getPlacesLatLng.value?.latLong.lng.toString() ??
              '',
      "terms": sourceTerms,
    },
    "destination": {
      "destinationTitle": data['destinationTitle'] ??
          bookingRideController.prefilledDrop.value ??
          '',
      "destinationPlaceId": data['destinationPlaceId'] ??
          dropPlaceSearchController.dropPlaceId.value,
      "destinationCity":
          dropPlaceSearchController.dropLatLng.value?.city.toString() ?? '',
      "destinationState":
          dropPlaceSearchController.dropLatLng.value?.state.toString() ?? '',
      "destinationCountry":
          dropPlaceSearchController.dropLatLng.value?.country.toString() ??
              'India',
      "destinationType": _parseList<String>(data['destinationTypes']),
      "destinationLat":
          dropPlaceSearchController.dropLatLng.value?.latLong.lat.toString() ??
              '',
      "destinationLng":
          dropPlaceSearchController.dropLatLng.value?.latLong.lng.toString() ??
              '',
      "terms": _parseList<Map<String, dynamic>>(data['destinationTerms']),
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
        (data['country']?.toLowerCase() ?? 'india') == 'india' ? false : true,
  };
}

List<T> _parseList<T>(dynamic json) {
  if (json != null && json.isNotEmpty) {
    return List<T>.from(jsonDecode(json));
  }
  return [];
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
    debugPrint('switch button hit ho gya hai');
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
      placeSearchController.getLatLngDetails(
          placeSearchController.placeId.value, context);
    }
    if (dropPlaceSearchController.dropPlaceId.value.isNotEmpty) {
      dropPlaceSearchController.getLatLngForDrop(
          dropPlaceSearchController.dropPlaceId.value, context);
    }

    // Swap stored values (local storage)
    final sourceKeys = [
      'sourcePlaceId',
      'sourceTitle',
      'sourceCity',
      'sourceState',
      'sourceCountry',
      'sourceTypes',
      'sourceTerms'
    ];
    final destinationKeys = [
      'destinationPlaceId',
      'destinationTitle',
      'destinationCity',
      'destinationState',
      'destinationCountry',
      'destinationTypes',
      'destinationTerms'
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    ridePickupController =
        TextEditingController(text: bookingRideController.prefilled.value);
    rideDropController =
        TextEditingController(text: bookingRideController.prefilledDrop.value);

    // Listen to changes in prefilled and prefilledDrop to update controllers
    rentalPickupWorker = ever(bookingRideController.prefilled, (String value) {
      if (ridePickupController.text != value) {
        ridePickupController.text = value;
      }
    });
    rentalDropWorker =
        ever(bookingRideController.prefilledDrop, (String value) {
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
        debugPrint("Error parsing userDateTime: $e");
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
        debugPrint("Error parsing actualDateTime: $e");
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
                    child: Column(
                      children: [
                        BookingTextFormField(
                          hintText: 'Enter Pickup Location',
                          controller: ridePickupController,
                          onTap: () async {
                            bookingRideController.isInvalidTime.value = false;
                            await GoRouter.of(context)
                                .push(AppRoutes.choosePickup);

                            // Ensure all three APIs are called after returning from choosePickup
                            if (placeSearchController
                                .placeId.value.isNotEmpty) {
                              await placeSearchController.getLatLngDetails(
                                  placeSearchController.placeId.value, context);
                            }
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
                final localStartTime =
                    bookingRideController.localStartTime.value;
                final dropoffDateTime = getDropLocalDateTime();

                final dynamic activeController = selectedField.value == 'drop'
                    ? dropPlaceSearchController
                    : placeSearchController;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DatePickerTile(
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

                            if (DateUtils.isSameDay(
                                newDate, actualMinDateTime)) {
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
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final items = fetchPackageController.packageModel.value?.data
                      .map((value) =>
                          '${value.hours} hrs, ${value.kilometers} kms')
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
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      builder: (context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey, width: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Select Package',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox.shrink(),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final isSelected = fetchPackageController
                                          .selectedPackage.value ==
                                      item;

                                  return RadioListTile(
                                    value: item,
                                    groupValue: fetchPackageController
                                        .selectedPackage.value,
                                    title: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                    activeColor: AppColors.mainButtonBg,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    onChanged: (value) async {
                                      fetchPackageController
                                          .updateSelectedPackage(item);
                                      Navigator.pop(context);

                                      debugPrint(' Selected package is: $item');

                                      // Extract hours & kms
                                      final packageRegex = RegExp(
                                          r'(\d+)\s*hrs?,\s*(\d+)\s*kms?');
                                      final match =
                                          packageRegex.firstMatch(item);

                                      if (match != null) {
                                        final extractedHours =
                                            int.tryParse(match.group(1)!);
                                        final extractedKms =
                                            int.tryParse(match.group(2)!);

                                        fetchPackageController.selectedHours
                                            .value = extractedHours ?? 0;
                                        fetchPackageController.selectedKms
                                            .value = extractedKms ?? 0;

                                        debugPrint(
                                            '📦 Extracted Hours: $extractedHours');
                                        debugPrint(
                                            '📦 Extracted KMs: $extractedKms');

                                        await StorageServices.instance.save(
                                            'selectedHours',
                                            extractedHours.toString());
                                        await StorageServices.instance.save(
                                            'selectedKms',
                                            extractedKms.toString());
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fetchPackageController
                                  .selectedPackage.value.isNotEmpty
                              ? fetchPackageController.selectedPackage.value
                              : "Select Packages",
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              return bookingRideController.isInvalidTime.value
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        border: Border.all(color: Colors.redAccent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "The earliest booking slot available at ${bookingRideController.selectedLocalDate.value}, ${bookingRideController.selectedLocalTime.value}.",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox();
            }),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: ridePickupController,
                  builder: (context, _) {
                    return Obx(() {
                      // Keep this reference so widget rebuilds when the shared state updates
                      // (e.g. after selecting pickup from the picker screen).
                      bookingRideController.prefilled.value;

                      final pickupText = ridePickupController.text.trim();
                      final sourcePlaceId =
                          placeSearchController.placeId.value.trim();

                      // ✅ Rental: destination is optional; enable button if pickup exists.
                      final isDisabled =
                          pickupText.isEmpty && sourcePlaceId.isEmpty;

                      return PrimaryButton(
                        text: 'Search Now',
                        isLoading: _isLoading,
                        onPressed: isDisabled
                            ? null
                            : () {
                                // Haptic feedback for smooth tap response
                                HapticFeedback.lightImpact();

                                if (_isLoading) return;
                                setState(() => _isLoading = true);

                                // Defer heavy operations to allow button animation to complete smoothly
                                SchedulerBinding.instance
                                    .addPostFrameCallback((_) async {
                                  // ✅ FAST PATH: Check countries immediately if already available
                                  var sourceCountry = placeSearchController
                                          .getPlacesLatLng.value?.country
                                          ?.toString()
                                          .toLowerCase() ??
                                      '';
                                  var destinationCountry =
                                      dropPlaceSearchController
                                              .dropLatLng.value?.country
                                              ?.toString()
                                              .toLowerCase() ??
                                          '';

                                  // For rental, if destination exists, check immediately (fast path)
                                  if (destinationCountry.isNotEmpty &&
                                      sourceCountry.isNotEmpty) {
                                    if (sourceCountry != destinationCountry) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Pickup and drop countries must be the same.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return; // ✅ Fast return if countries don't match
                                    }
                                  }

                                  // ✅ Fetch lat/lng APIs in parallel only if needed
                                  final futures = <Future>[];
                                  if (placeSearchController
                                          .placeId.value.isNotEmpty &&
                                      placeSearchController
                                              .getPlacesLatLng.value ==
                                          null) {
                                    futures.add(placeSearchController
                                        .getLatLngDetails(
                                            placeSearchController.placeId.value,
                                            context)
                                        .catchError((e) => debugPrint(
                                            'Error fetching source lat/lng: $e')));
                                  }
                                  if (dropPlaceSearchController
                                          .dropPlaceId.value.isNotEmpty &&
                                      dropPlaceSearchController
                                              .dropLatLng.value ==
                                          null) {
                                    futures.add(dropPlaceSearchController
                                        .getLatLngForDrop(
                                            dropPlaceSearchController
                                                .dropPlaceId.value,
                                            context)
                                        .catchError((e) => debugPrint(
                                            'Error fetching destination lat/lng: $e')));
                                  }

                                  // Wait for APIs in parallel if needed
                                  if (futures.isNotEmpty) {
                                    await Future.wait(futures);
                                    // Re-check countries after APIs complete
                                    sourceCountry = placeSearchController
                                            .getPlacesLatLng.value?.country
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    destinationCountry =
                                        dropPlaceSearchController
                                                .dropLatLng.value?.country
                                                ?.toString()
                                                .toLowerCase() ??
                                            '';
                                  }

                                  // ✅ Final country validation for rental
                                  // For rental, if destination exists, both must match
                                  if (destinationCountry.isNotEmpty) {
                                    if (sourceCountry.isEmpty ||
                                        sourceCountry != destinationCountry) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Pickup and drop countries must be the same.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return; // ✅ CRITICAL: Return early, do NOT build request data or call API
                                    }
                                  }

                                  // Only build request data if countries match (or destination is empty for rental)
                                  try {
                                    final requestData =
                                        await _buildRentalRequestData(context);

                                    // ✅ If destination is not selected for Rental, close the popup and let
                                    // the InventoryList screen handle fetching (prevents loader sticking).
                                    final hasDestination =
                                        dropPlaceSearchController
                                            .dropPlaceId.value
                                            .trim()
                                            .isNotEmpty;
                                    if (!hasDestination) {
                                      bookingRideController
                                          .isInventoryPage.value = false;
                                      GoRouter.of(context).push(
                                        AppRoutes.inventoryList,
                                        extra: requestData,
                                      );
                                      return;
                                    }

                                    // Only call API if countries match (or destination is empty for rental)
                                    try {
                                      await searchCabInventoryController
                                          .fetchBookingData(
                                        country: requestData['countryName'],
                                        requestData: requestData,
                                        context: context,
                                        isSecondPage: true,
                                      );

                                      bookingRideController
                                          .isInventoryPage.value = false;
                                      GoRouter.of(context).push(
                                        AppRoutes.inventoryList,
                                        extra: requestData,
                                      );
                                    } catch (e) {
                                      debugPrint(
                                          'Error fetching booking data: $e');
                                      // Show error to user but don't block
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Network error. Please try again.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    debugPrint('[SearchNow] Error: $e');
                                    if (mounted) {
                                      // Navigate to inventory list with error message
                                      GoRouter.of(context).push(
                                        AppRoutes.inventoryList,
                                        extra: const {
                                          'noInventoryMessage':
                                              'No Inventory Found, Please try again!',
                                        },
                                      );
                                    }
                                  } finally {
                                    if (mounted)
                                      setState(() => _isLoading = false);
                                  }
                                });
                              },
                      );
                    });
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> _buildRentalRequestData(
    BuildContext context) async {
  final PlaceSearchController placeSearchController =
      Get.put(PlaceSearchController());
  final FetchPackageController fetchPackageController =
      Get.put(FetchPackageController());
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());

  // Loader is already shown on button tap, no need to show again
  final now = DateTime.now();
  final searchDate = now.toIso8601String().split('T').first;
  final searchTime =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
    'sourceTypes',
    'sourceTerms',
    'destinationPlaceId',
    'destinationTitle',
    'destinationTypes',
    'destinationTerms',
  ];

  final values = await Future.wait(keys.map(StorageServices.instance.read));
  final data = Map.fromIterables(keys, values);

  final dateFormat = DateFormat('EEEE, dd MMM, yyyy h:mm a');
  final pickupDateTime = bookingRideController.localStartTime.value.toUtc() !=
          null
      ? dateFormat.format(
          bookingRideController.localStartTime.value.toUtc() ?? DateTime.now())
      : '';
  final returnDateTime = bookingRideController.localEndTime.value
              .toUtc()
              .toIso8601String() !=
          null
      ? dateFormat.format(
          bookingRideController.localEndTime.value.toUtc() ?? DateTime.now())
      : '';
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  await _analytics.logSearch(
    searchTerm: '${data['sourceTitle']} to ${data['destinationTitle']}',
    numberOfPassengers: 1,
    origin: placeSearchController.getPlacesLatLng.value?.city.toString(),
    destination: placeSearchController.getPlacesLatLng.value?.city.toString(),
    startDate: pickupDateTime,
    endDate: returnDateTime,
    parameters: {
      'event': 'search',
      'trip_type': 'Local',
      'user_status': 'logged_out',
      'search_source': 'home_screen',
    },
  );

  // Get fallback values from controllers if storage is null
  final sourceTitle = data['sourceTitle'] ??
      bookingRideController.prefilled.value ??
      (placeSearchController.suggestions.isNotEmpty
          ? placeSearchController.suggestions.first.primaryText
          : '');
  final actualOffset = data['actualOffset'] ??
      placeSearchController
          .findCntryDateTimeResponse.value?.actualDateTimeObject?.actualOffSet
          ?.toString() ??
      offset.toString();
  final timeZone = data['timeZone'] ??
      placeSearchController.findCntryDateTimeResponse.value?.timeZone ??
      placeSearchController.getCurrentTimeZoneName();
  final actualTimeWithOffset = data['actualTimeWithOffset'] ??
      (placeSearchController.findCntryDateTimeResponse.value
                  ?.actualDateTimeObject?.actualDateTime !=
              null
          ? placeSearchController.convertToIsoWithOffset(
              placeSearchController.findCntryDateTimeResponse.value!
                  .actualDateTimeObject!.actualDateTime!,
              -(placeSearchController.findCntryDateTimeResponse.value!
                      .actualDateTimeObject!.actualOffSet ??
                  0))
          : DateTime.now().toIso8601String());
  final userTimeWithOffset =
      data['userTimeWithOffset'] ??
          (placeSearchController.findCntryDateTimeResponse.value
                      ?.userDateTimeObject?.userDateTime !=
                  null
              ? placeSearchController.convertToIsoWithOffset(
                  placeSearchController.findCntryDateTimeResponse.value!
                      .userDateTimeObject!.userDateTime!,
                  -(placeSearchController.findCntryDateTimeResponse.value!
                          .userDateTimeObject!.userOffSet ??
                      0))
              : DateTime.now().toIso8601String());
  final userOffset = data['userOffset'] ??
      placeSearchController
          .findCntryDateTimeResponse.value?.userDateTimeObject?.userOffSet
          ?.toString() ??
      offset.toString();

  // Get source terms from suggestion if available
  List<Map<String, dynamic>> sourceTerms =
      _parseList<Map<String, dynamic>>(data['sourceTerms']);
  if (sourceTerms.isEmpty && placeSearchController.suggestions.isNotEmpty) {
    final suggestion = placeSearchController.suggestions.first;
    if (suggestion.terms.isNotEmpty) {
      sourceTerms = suggestion.terms.map((term) => term.toJson()).toList();
    }
  }

  return {
    // Used by InventoryList to decide whether to show the Trip Updated dialog.
    "applicationType": "APP",
    "comingFrom": "searchInventory api 2nd page -APP",
    "inventoryEntryPoint": "booking_ride",
    "timeOffSet": -offset,
    "countryName": data['country'] ?? 'India',
    "searchDate": searchDate,
    "searchTime": searchTime,
    "offset": int.parse(userOffset),
    "pickupDateAndTime": bookingRideController.convertLocalToUtc(),
    "returnDateAndTime": "",
    "tripCode": "3",
    "source": {
      "sourceTitle": sourceTitle,
      "sourcePlaceId":
          data['sourcePlaceId'] ?? placeSearchController.placeId.value,
      "sourceCity":
          placeSearchController.getPlacesLatLng.value?.city.toString() ?? '',
      "sourceState":
          placeSearchController.getPlacesLatLng.value?.state.toString() ?? '',
      "sourceCountry":
          placeSearchController.getPlacesLatLng.value?.country.toString() ??
              'India',
      "sourceType": _parseList<String>(data['sourceTypes']),
      "sourceLat":
          placeSearchController.getPlacesLatLng.value?.latLong.lat.toString() ??
              '',
      "sourceLng":
          placeSearchController.getPlacesLatLng.value?.latLong.lng.toString() ??
              '',
      "terms": sourceTerms,
    },
    "destination": {},
    // "packageSelected": {
    //   "km": data['selectedKms'],
    //   "hours": data['selectedHours']
    // },
    "packageSelected": {
      "km": fetchPackageController.selectedKms.value,
      "hours": fetchPackageController.selectedHours.value
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
    "isGlobal":
        (data['country']?.toLowerCase() ?? 'india') == 'india' ? false : true,
  };
}
