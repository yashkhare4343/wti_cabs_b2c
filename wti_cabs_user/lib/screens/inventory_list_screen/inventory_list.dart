import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/common_widget/loader/shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/controller/analytics_tracking/analytics_tracking.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/drop_location_controller/drop_location_controller.dart';
import 'package:wti_cabs_user/core/controller/inventory/search_cab_inventory_controller.dart';
import 'package:wti_cabs_user/core/controller/source_controller/source_controller.dart';
import 'package:wti_cabs_user/core/model/inventory/global_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/main.dart' show navigatorKey;
import 'package:wti_cabs_user/screens/booking_details_final/booking_details_final.dart';
import 'package:wti_cabs_user/screens/map_picker/map_picker.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

import '../../common_widget/dropdown/common_dropdown.dart';
import '../../core/controller/cab_booking/cab_booking_controller.dart';
import '../../core/controller/choose_drop/choose_drop_controller.dart';
import '../../core/controller/currency_controller/currency_controller.dart';
import '../../core/controller/inventory_dialog_controller/inventory_dialog_controller.dart';
import '../../core/controller/popup_location/popup_drop_search_controller.dart';
import '../../core/controller/popup_location/popup_pickup_search_controller.dart';
import '../../core/model/booking_engine/get_lat_lng_response.dart';
import '../../core/controller/rental_controller/fetch_package_controller.dart';
import '../../core/model/booking_engine/suggestions_places_response.dart';
import '../../core/model/inventory/india_response.dart';
import '../../core/services/storage_services.dart';
import 'package:timezone/timezone.dart' as tz;

import '../bottom_nav/bottom_nav.dart';
import '../popup/popup_booking_ride.dart';
import '../select_location/popup_select_drop.dart';
import '../select_location/popup_select_pickup.dart';

class InventoryList extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final bool? fromFinalBookingPage;
  final bool? fromRecentSearch;

  const InventoryList(
      {super.key,
        required this.requestData,
        this.fromFinalBookingPage,
        this.fromRecentSearch});

  @override
  State<InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends State<InventoryList> with WidgetsBindingObserver {
  final SearchCabInventoryController searchCabInventoryController =
  Get.put(SearchCabInventoryController());
  final TripController tripController = Get.put(TripController());
  final FetchPackageController fetchPackageController =
  Get.put(FetchPackageController());
  final BookingRideController bookingRideController =
  Get.put(BookingRideController());
  final PlaceSearchController placeSearchController = Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController = Get.put(DropPlaceSearchController());

  static const Map<String, String> tripMessages = {
    '0': 'Your selected trip type has changed to Outstation One Way Trip.',
    '1': 'Your selected trip type has changed to Outstation Round Way Trip.',
    '2': 'Your selected trip type has changed to Airport Trip.',
    '3': 'Your selected trip type has changed to Local.',
  };

  String? _country;
  bool isLoading = true;
  bool _isInitialLoad = true;
  String? _previousPickupPlaceId;
  String? _previousDropPlaceId;

  final _analytics = FirebaseAnalytics.instance;

  // 🔹 Call your test analytics function here

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _previousPickupPlaceId = placeSearchController.placeId.value;
    _previousDropPlaceId = dropPlaceSearchController.dropPlaceId.value;
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchData();
      await loadInitialData();
      bookingRideController.requestData.value = widget.requestData;
      _isInitialLoad = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final data = searchCabInventoryController.indiaData.value;
        if (data != null) {
          logCabViewItemList(data);
        }
      });
    });

    // Show error message when navigated here due to inventory fetch failure
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msg = widget.requestData['noInventoryMessage'];
      if (msg is String && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isInitialLoad) {
      _checkAndRefreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLoad && mounted) {
      // Check if locations have changed when screen becomes visible again
      // Use a small delay to ensure navigation is complete
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkAndRefreshData();
        }
      });
    }
  }

  /// Check if location data has changed and refresh if needed
  Future<void> _checkAndRefreshData() async {
    if (!mounted || _isInitialLoad) return;
    
    final currentPickupId = placeSearchController.placeId.value;
    final currentDropId = dropPlaceSearchController.dropPlaceId.value;
    
    // Check if locations have changed
    if (currentPickupId != _previousPickupPlaceId || 
        currentDropId != _previousDropPlaceId) {
      _previousPickupPlaceId = currentPickupId;
      _previousDropPlaceId = currentDropId;
      
      // Small delay to ensure location updates are complete
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Refresh data if locations changed
      if (mounted) {
        await _refreshData();
      }
    }
  }

  /// Refresh inventory data
  Future<void> _refreshData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      // Rebuild request data with updated locations
      final updatedRequestData = Map<String, dynamic>.from(widget.requestData);
      
      await searchCabInventoryController.fetchBookingData(
        country: updatedRequestData['countryName'] ?? _country ?? '',
        requestData: updatedRequestData,
        context: context,
        isSecondPage: true,
      );
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> logCabViewItemList(IndiaResponse indiaResponse) async {
    final result = indiaResponse.result;
    if (result == null ||
        result.inventory?.carTypes == null ||
        result.inventory!.carTypes!.isEmpty) {
      debugPrint('⚠️ No car inventory data found, skipping analytics event.');
      return;
    }

    final currencyController = Get.put(CurrencyController());
    final tripType = result.tripType;
    final carTypes = result.inventory!.carTypes!;
    final tripCategory = tripType?.tripTypeDetails?.airportType ??
        tripType?.tripTypeDetails?.basicTripType ??
        '';
    final tripTypeDetail = tripType?.tripType ?? ''; // ONE-WAY, ROUND TRIP
    final tripMode = tripType?.tripTypeDetails?.basicTripType ?? 'Unknown'; // OUTSTATION, AIRPORT, RENTAL
    final sourceCity = tripType?.source?.city ?? '';
    final destCity = tripType?.destination?.city ?? '';
    final sourceName = tripType?.source?.address ?? '';
    final destName = tripType?.destination?.address ?? '';

    final dateFormat = DateFormat('EEEE, dd MMM, yyyy h:mm a');
    final pickupDateTime = tripType?.startTime != null
        ? dateFormat.format(tripType!.startTime!.toLocal())
        : '';
    final returnDateTime = tripType?.endTime != null
        ? dateFormat.format(tripType!.endTime!.toLocal())
        : '';

    // ✅ Prepare list
    final List<AnalyticsEventItem> items = [];

    for (int index = 0; index < carTypes.length; index++) {
      final car = carTypes[index];
      final carType = car.type ?? 'Unknown';
      final uniqueItemId =
          '${carType}-${car.combustionType ?? ''}-${car.skuId ?? index}';
      final baseFare = (car.fareDetails?.baseFare ?? 0).toDouble();

      debugPrint('base fare view_item_list: $baseFare');

      // 🔹 Await converted price (async)
      final convertedPrice = await currencyController.convertPrice(baseFare);

      items.add(
        AnalyticsEventItem(
          currency: currencyController.selectedCurrency.value.code,
          itemId: uniqueItemId,
          itemName: carType.toUpperCase(),
          itemBrand: getTripTypeString(tripType?.currentTripCode),
          itemCategory: getTripCategoryString(
            tripType?.currentTripCode,
            tripType?.tripTypeDetails?.airportType,
            tripType?.packageId,
          ),
          itemCategory2: pickupDateTime,
          itemCategory3: returnDateTime,
          itemCategory4: sourceCity,
          itemCategory5: destCity,
          itemVariant: Platform.isIOS?"Ios" : "Android",
          price: baseFare, // ✅ now a double, not a Future<double>
          quantity: 1,
          coupon: '',
          discount: (car.fakePercentageOff ?? 0).toDouble(),
          index: index + 1,
        ),
      );
    }

    // ✅ Event-level metadata
    final parameters = <String, Object>{
      'event': 'view_item_list',
      'user_id': '', // replace dynamically if logged in
      'user_status': 'logged_out',
      'currency': currencyController.selectedCurrency.value.code,
      'trip_type': getTripTypeString(tripType?.currentTripCode),
      'pickup_datetime': pickupDateTime,
      'return_datetime': returnDateTime,
      'origin_id': '',
      'origin_name': sourceName,
      'destination_id': '',
      'destination_name': destName,
    };

    // ✅ Send to Firebase Analytics
    await _analytics.logViewItemList(
      itemListId: 'Cab_Booking',
      itemListName: 'Cab_Booking',
      items: items,
      parameters: parameters,
    );

    debugPrint('✅ Logged view_item_list with ${items.length} items.');
  }

  Future<void> _logViewItemList() async {
    await _analytics.logViewItemList(
      itemListId: 'L001',                     // unique ID for the list
      itemListName: 'Related products',       // human-readable name
      items: [
        AnalyticsEventItem(
          itemId: 'SKU_123',
          itemName: 'Stan Tee',
          price: 9.99,
          itemCategory: 'Apparel',
          index: 3,                           // 0-based position in the list
        ),
        // Add as many items as you want (GA4 caps at 100 per event)
        AnalyticsEventItem(
          itemId: 'SKU_456',
          itemName: 'Blue Hoodie',
          price: 29.99,
          itemCategory: 'Apparel/Hoodies',
          index: 4,
        ),
      ],
    );

    // Optional: also set a screen name for better context
    await _analytics.setCurrentScreen(screenName: 'ProductListScreen');
  }
  // Future<void> logViewItemListEvent({
  //   required IndiaResponse indiaResponse,
  //   required String userId,
  //   required String clientId,
  //   required bool isLoggedIn,
  // }) async {
  //   final analytics = FirebaseAnalytics.instance;
  //
  //   final carTypes = indiaResponse.result?.inventory?.carTypes ?? [];
  //
  //   // Convert car list to Firebase item format
  //   final List<Map<String, dynamic>> items = carTypes.map((car) {
  //     return {
  //       'item_id': car.skuId ?? '',
  //       'item_name': car.model ?? car.type ?? '',
  //       'item_brand': car.makeYearType ?? '',
  //       'item_category': car.subcategory ?? '',
  //       'price': car.fareDetails?.baseFare ?? 0,
  //       'currency': 'INR',
  //       'route_id': car.routeId ?? '',
  //       'seats': car.seats ?? 0,
  //       'trip_type': car.tripType ?? '',
  //       'rating': car.rating?.ratePoints ?? 0,
  //     };
  //   }).toList();
  //
  //   await analytics.logEvent(
  //     name: 'view_item_list',
  //     parameters: {
  //       'item_list_id': 'Cab_Listing',
  //       'item_list_name': 'Available Cabs',
  //       'currency': 'INR',
  //       'user_id': userId,
  //       'client_id_hit': clientId,
  //       'user_status': isLoggedIn ? 'logged_in' : 'logged_out',
  //       'screen_name': 'PLP_Screen',
  //       'items': jsonEncode(items),
  //       // Optional contextual data
  //       'trip_type': indiaResponse.result?.tripType?.tripType ?? '',
  //       'distance_booked': indiaResponse.result?.inventory?.distanceBooked ?? 0,
  //       'start_time': '',
  //     },
  //   );
  //
  //   debugPrint('✅ Firebase Analytics: view_item_list logged with ${items.length} items');
  // }



  /// Load the country and check trip code change dialog after UI is rendered
  Future<void> loadInitialData() async {
    // ✅ Rental can have no destination; prefer requestData/pickup as fallback.
    final fromRequest = widget.requestData['countryName'] ?? widget.requestData['country'];
    _country = (fromRequest is String && fromRequest.isNotEmpty)
        ? fromRequest.toLowerCase()
        : (dropPlaceSearchController.dropLatLng.value?.country ??
                placeSearchController.getPlacesLatLng.value?.country)
            ?.toLowerCase();
    setState(() {
      isLoading = false;
    });
    // Show this dialog ONLY when InventoryList is opened from BookingRide.
    if (mounted && _shouldShowTripUpdatedDialog) {
      await loadTripCode(context);
    }
  }

  bool get _shouldShowTripUpdatedDialog {
    final v = widget.requestData['inventoryEntryPoint'];
    return v == 'booking_ride';
  }

  /// When InventoryList is reached from payment flow screens, the previous route
  /// in the stack is often `PaymentFailurePage` or `BookingDetailsFinal`.
  /// Allowing an iOS interactive pop would land back on those pages, which is
  /// not desired. In that case we intercept back/swipe and push to BookingRide.
  bool get _isFromPaymentFlow {
    final v = widget.requestData['inventoryEntryPoint'];
    return v == 'payment_failure' || v == 'booking_details_final';
  }

  bool get _allowIosInteractivePop => Platform.isIOS && !_isFromPaymentFlow;

  /// Check for trip code changes and show dialog if needed
  Future<void> loadTripCode(BuildContext context) async {
    final current =
        await StorageServices.instance.read('currentTripCode') ?? '';
    final previous =
        await StorageServices.instance.read('previousTripCode') ?? '';

    if (mounted && current.isNotEmpty && current != previous) {
      final message =
          tripMessages[current] ?? 'Your selected trip type has changed.';
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            elevation: 10,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: const [
                Icon(Icons.update_outlined, color: Colors.blueAccent, size: 20),
                SizedBox(width: 10),
                Text('Trip Updated',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.mainButtonBg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  /// Fetches booking data and handles loading/error state
  Future<void> _fetchData() async {
    try {
      await searchCabInventoryController.fetchBookingData(
        country: widget.requestData['countryName'],
        requestData: widget.requestData,
        context: context,
        isSecondPage: true,
      );
    } catch (e) {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        // If inventory fetch fails, route back to BookingRide without popping, preserve last selected tab.
        final lastTab = bookingRideController.tabNames[bookingRideController.selectedIndex.value];
        _pushToBookingRide(null, lastTab);
      }
    }
  }

  num getFakePriceWithPercent(num baseFare, num percent) =>
      (baseFare * 100) / (100 - percent);
  num getFivePercentOfBaseFare(num baseFare) => baseFare * 0.05;

  final CurrencyController currencyController = Get.find<CurrencyController>();

  void _pushToBookingRide([String? route, String? tab]) {
    final baseRoute = route ?? AppRoutes.bookingRide;
    final target = (tab != null && tab.isNotEmpty)
        ? '$baseRoute?tab=$tab'
        : baseRoute;

    // Prefer pushing via the app's root navigator key, to avoid nested navigator
    // contexts where `GoRouter.of(context)` may not target the root stack.
    final rootCtx = navigatorKey.currentContext;
    if (rootCtx != null) {
      GoRouter.of(rootCtx).push(target);
      return;
    }

    if (!mounted) return;
    GoRouter.of(context).push(target);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return PopScope(
        // Always intercept back and route to BookingRide (no .pop()).
        // Enable iOS interactive swipe-back.
        canPop: _allowIosInteractivePop,
        onPopInvoked: (didPop) {
          if (didPop) return; // Already popped, nothing to do
          if (Platform.isIOS && _allowIosInteractivePop) return;

          bookingRideController.isInventoryPage.value = false;
          final lastTab = bookingRideController.tabNames[bookingRideController.selectedIndex.value];
          // Navigate back - use microtask for immediate execution
          Future.microtask(() {
            if (!mounted) return;
            // InventoryList >>> back to >>> BookingRide (always push), preserve last selected tab
            _pushToBookingRide(null, lastTab);
          });
        },
        child: Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          body: FullPageShimmer(),
        ),
      );
    }

    final isIndia = _country?.toLowerCase() == 'india';
    final indiaData = searchCabInventoryController.indiaData.value;
    final globalData = searchCabInventoryController.globalData.value;

    if (_country == null ||
        (isIndia && indiaData == null) ||
        (!isIndia && globalData == null)) {
      return PopScope(
        // Always intercept back and route to BookingRide (no .pop()).
        // Enable iOS interactive swipe-back.
        canPop: _allowIosInteractivePop,
        onPopInvoked: (didPop) {
          if (didPop) return; // Already popped, nothing to do
          if (Platform.isIOS && _allowIosInteractivePop) return;

          bookingRideController.isInventoryPage.value = false;
          final lastTab = bookingRideController.tabNames[bookingRideController.selectedIndex.value];
          // Navigate back - use microtask for immediate execution
          Future.microtask(() {
            if (!mounted) return;
            
            Get.delete<PlaceSearchController>(force: true);
            Get.delete<DropPlaceSearchController>(force: true);
            Get.delete<SourceLocationController>(force: true);
            Get.delete<DestinationLocationController>(force: true);
            Get.delete<SearchCabInventoryController>(force: true);
            Get.delete<BookingRideController>(force: true);
            Get.put(PlaceSearchController());
            Get.put(DropPlaceSearchController());
            Get.put(SourceLocationController());
            Get.put(DestinationLocationController());
            Get.put(SearchCabInventoryController());
            Get.put(BookingRideController());
            if (isIndia && indiaData == null) {
              bookingRideController.prefilled.value =
                  indiaData?.result?.tripType?.source?.address ?? '';
              bookingRideController.prefilledDrop.value =
                  indiaData?.result?.tripType?.destination?.address ?? '';
            } else if (!isIndia && globalData == null) {
              bookingRideController.prefilled.value = globalData
                  ?.result.first.iterator.current.tripDetails?.source.title ??
                  '';
              bookingRideController.prefilledDrop.value = globalData?.result.first
                  .iterator.current.tripDetails?.destination.title ??
                  '';
            }

            // InventoryList >>> back to >>> BookingRide (always push), preserve last selected tab
            _pushToBookingRide(null, lastTab);
          });
        },
        child: Scaffold(
          body: Center(child: FullPageShimmer()),
        ),
      );
    }

    final indiaCarTypes = indiaData?.result?.inventory?.carTypes ?? [];
    final globalList = globalData?.result ?? [];

    return PopScope(
      // Always intercept back and route to BookingRide (no .pop()).
      // Enable iOS interactive swipe-back.
      canPop: _allowIosInteractivePop,
      onPopInvoked: (didPop) {
        if (didPop) return; // Already popped, nothing to do
        if (Platform.isIOS && _allowIosInteractivePop) return;

        bookingRideController.isInventoryPage.value = false;
        final lastTab = bookingRideController.tabNames[bookingRideController.selectedIndex.value];
        // Navigate back - use microtask for immediate execution
        Future.microtask(() {
          if (!mounted) return;
          // InventoryList >>> back to >>> BookingRide (always push), preserve last selected tab
          _pushToBookingRide(null, lastTab);
        });
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookingTopBar(),
                // Column(
                //   children: [
                //     SelectedPackageCard(controller: fetchPackageController),
                //   ],
                // ),
                Expanded(
                  child: Obx(() {
                    final isIndia =
                        searchCabInventoryController.indiaData.value != null;
                    final indiaCarTypes = searchCabInventoryController
                        .indiaData.value?.result?.inventory?.carTypes ??
                        [];
                    final globalList =
                        searchCabInventoryController.globalData.value?.result ??
                            [];
                    final isEmptyList = (isIndia && indiaCarTypes.isEmpty) ||
                        (!isIndia && globalList.isEmpty);
                    final isPopupOpen = bookingRideController.isPopupOpen.value;

                    if (isEmptyList && !isPopupOpen) {
                      return const Center(
                        child: Text(
                          "No cabs available on this route",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      );
                    }

                    if ((placeSearchController.getPlacesLatLng.value?.country !=
                        dropPlaceSearchController
                            .dropLatLng.value?.country) &&
                        (indiaCarTypes.isNotEmpty &&
                            indiaCarTypes.first.tripType != 'LOCAL_RENTAL')) {
                      return const Center(
                        child: Text(
                          "No cabs available on this route, Please search on same country for pickup and drop",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        SizedBox(
                          height: 12,
                        ),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                            children: [
                              const TextSpan(text: 'Rates for '),
                              _country?.toLowerCase() == 'india'
                                  ? TextSpan(
                                text:
                                '${searchCabInventoryController.indiaData.value?.result?.tripType?.distanceBooked ?? int.parse(searchCabInventoryController.indiaData.value?.result?.tripType?.packageId?.split("_")[1] ?? '0')} Kms',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )
                                  : TextSpan(
                                  text:
                                  '${searchCabInventoryController.globalData.value?.result.first.first.tripDetails?.totalDistance} kms'),
                              const TextSpan(text: ' approx distance | '),
                              _country?.toLowerCase() == 'india'
                                  ? TextSpan(
                                text:
                                '${(DateTime.parse(searchCabInventoryController.indiaData.value?.result?.tripType?.endTime.toString() ?? '').difference(DateTime.parse(searchCabInventoryController.indiaData.value?.result?.tripType?.startTime.toString() ?? '')).inMinutes / 60).toStringAsFixed(2)} hrs',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              )
                                  : TextSpan(
                                text:
                                '${(DateTime.parse(searchCabInventoryController.globalData.value?.result.first.first.tripDetails?.dropDateTime ?? '').difference(DateTime.parse(searchCabInventoryController.globalData.value?.result.first.first.tripDetails?.pickupDateTime ?? '')).inMinutes / 60).toStringAsFixed(2)} hrs',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' approx time'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: isIndia
                                ? indiaCarTypes.length
                                : globalList.length,
                            itemBuilder: (context, index) {
                              if (isIndia) {
                                final carType = indiaCarTypes[index];
                                return _buildIndiaCard(carType);
                              } else {
                                final globalListItem = globalList[index];
                                final tripDetails = globalListItem
                                    .firstWhereOrNull(
                                        (e) => e.tripDetails != null)
                                    ?.tripDetails;
                                final fareDetails = globalListItem
                                    .firstWhereOrNull(
                                        (e) => e.fareDetails != null)
                                    ?.fareDetails;
                                final vehicleDetails = globalListItem
                                    .firstWhereOrNull(
                                        (e) => e.vehicleDetails != null)
                                    ?.vehicleDetails;

                                if (tripDetails == null ||
                                    fareDetails == null ||
                                    vehicleDetails == null) {
                                  return const SizedBox();
                                }

                                return _buildGlobalCard(
                                    tripDetails, fareDetails, vehicleDetails);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndiaCard(CarType carType) {
    final tripCode = searchCabInventoryController
        .indiaData.value?.result?.tripType?.currentTripCode;
    final CabBookingController cabBookingController =
    Get.put(CabBookingController());
    final CurrencyController currencyController = Get.put(CurrencyController());
    final tripTypeDetails =
        searchCabInventoryController.indiaData.value?.result?.tripType;

    final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

    num calculateOriginalPrice(num baseFare, num discountPercent) {
      return baseFare + (baseFare * discountPercent / 100);
    }

    num originalPrice = calculateOriginalPrice(
        carType.fareDetails?.baseFare ?? 0, carType.fakePercentageOff ?? 0);

    return InkWell(
      splashColor: Colors.transparent,
      onTap: () async {

        final SelectedTripController selectedTripController = Get.put(SelectedTripController());

        final country = dropPlaceSearchController.dropLatLng.value?.country.toLowerCase() ?? placeSearchController.getPlacesLatLng.value?.country.toLowerCase();
        final Map<String, dynamic> requestData = {
          "isGlobal": false,
          "country": country,
          "routeInventoryId": carType.routeId,
          "vehicleId": null,
          "trip_type": carType.tripType,
          "pickUpDateTime": tripTypeDetails?.startTime?.toIso8601String() ?? '',
          "dropDateTime": tripTypeDetails?.endTime?.toIso8601String() ?? '',
          "totalKilometers": tripTypeDetails?.distanceBooked ??
              int.parse(searchCabInventoryController
                  .indiaData.value?.result?.tripType?.packageId
                  ?.split("_")[1] ??
                  '0'),
          "package_id": tripTypeDetails?.packageId ?? '',
          "source": {
            "address": tripTypeDetails?.source?.address ?? '',
            "latitude": tripTypeDetails?.source?.latitude,
            "longitude": tripTypeDetails?.source?.longitude,
            "city": tripTypeDetails?.source?.city
          },
          "destination": {
            "address": tripTypeDetails?.destination?.address ?? '',
            "latitude": tripTypeDetails?.destination?.latitude,
            "longitude": tripTypeDetails?.destination?.longitude,
            "city": tripTypeDetails?.destination?.city
          },
          "tripCode": tripCode,
          "role":"CUSTOMER",
          "trip_type_details": {
            "basic_trip_type":
            tripTypeDetails?.tripTypeDetails?.basicTripType ?? '',
            "airport_type": tripTypeDetails?.tripTypeDetails?.airportType ?? ''
          },
        };


        final currencyController = Get.put(CurrencyController());
        final tripType = carType.tripType;
        final carTypes = carType;
        final tripCategory = tripTypeDetails?.tripTypeDetails?.basicTripType ??
            '';
        final tripTypeDetail = tripType ?? ''; // ONE-WAY, ROUND TRIP
        final tripMode = tripTypeDetails?.tripTypeDetails?.basicTripType  ?? 'Unknown'; // OUTSTATION, AIRPORT, RENTAL
        final sourceCity = tripTypeDetails?.source?.city ?? '';
        final destCity = tripTypeDetails?.destination?.city ?? '';
        final sourceName = tripTypeDetails?.source?.address ?? '';
        final destName = tripTypeDetails?.destination?.address ?? '';

        final dateFormat = DateFormat('EEEE, dd MMM, yyyy h:mm a');
        final pickupDateTime = tripTypeDetails?.startTime?.toIso8601String() != null
            ? dateFormat.format(tripTypeDetails?.startTime?.toLocal()??DateTime.now())
            : '';
        final returnDateTime = tripTypeDetails?.endTime?.toIso8601String() != null
            ? dateFormat.format(tripTypeDetails?.endTime?.toLocal()??DateTime.now())
            : '';

        // ✅ Prepare list
        final List<AnalyticsEventItem> items = [];

        for (int index = 0; index <1; index++) {
          final carType = carTypes ?? 'Unknown';
          final uniqueItemId =
              '${searchCabInventoryController.indiaData.value?.result?.inventory?.carTypes?[index].type}-${searchCabInventoryController.indiaData.value?.result?.inventory?.carTypes?[index].combustionType}-${searchCabInventoryController.indiaData.value?.result?.inventory?.carTypes?[index].skuId ?? index}';
          final baseFare = (searchCabInventoryController.indiaData.value?.result?.inventory?.carTypes?[index].fareDetails?.baseFare ?? 0).toDouble();

          debugPrint('base fare view_item_list: $baseFare');

          // 🔹 Await converted price (async)
          final convertedPrice = await currencyController.convertPrice(baseFare);

          items.add(
            AnalyticsEventItem(
              currency: currencyController.selectedCurrency.value.code,
              itemId: uniqueItemId,
              itemName: searchCabInventoryController.indiaData.value?.result?.inventory?.carTypes?[index].type?.toUpperCase(),
              itemBrand: getTripTypeString(searchCabInventoryController.indiaData.value?.result?.tripType?.currentTripCode),
              itemCategory: getTripCategoryString(
                searchCabInventoryController.indiaData.value?.result?.tripType?.currentTripCode,
                searchCabInventoryController.indiaData.value?.result?.tripType?.tripTypeDetails?.airportType,
                searchCabInventoryController.indiaData.value?.result?.tripType?.packageId,
              ),
              itemCategory2: pickupDateTime,
              itemCategory3: returnDateTime,
              itemCategory4: sourceCity,
              itemCategory5: destCity,
              itemVariant: Platform.isIOS?"Ios" : "Android",
              price: baseFare, // ✅ now a double, not a Future<double>
              quantity: 1,
              coupon: '',
              discount: (searchCabInventoryController.indiaData.value?.result?.inventory?.carTypes?[index].fakePercentageOff ?? 0).toDouble(),
              index: index + 1,
            ),
          );
        }

        // ✅ Event-level metadata
        final parameters = <String, Object>{
          'event': 'select_item',
          'user_id': '', // replace dynamically if logged in
          'user_status': 'logged_out',
          'currency': currencyController.selectedCurrency.value.code,
          'trip_type': getTripTypeString(searchCabInventoryController.indiaData.value?.result?.tripType?.currentTripCode),
          'pickup_datetime': pickupDateTime,
          'return_datetime': returnDateTime,
          'origin_id': '',
          'origin_name': sourceName,
          'destination_id': '',
          'destination_name': destName,
        };

        // ✅ Send to Firebase Analytics
        await _analytics.logSelectItem(
          itemListId: 'Cab_Booking',
          itemListName: 'Cab_Booking',
          items: items,
          parameters: parameters,
        );

        selectedTripController.setTripData(
          item: items.first,   // or any selected item
          params: parameters,  // your analytics or trip parameters
        );

        debugPrint('✅ Logged select with ${items.length} items.');

        // Pass recommended coupon (if any) to Booking Details for auto-selection.
        cabBookingController.setPreselectedCoupon(
          couponId: carType.coupon?.id,
          couponCode: carType.coupon?.codeName,
          discountedCoupon: carType.discountedCoupon,
        );

        cabBookingController.fetchBookingData(
            country: country ?? '', requestData: requestData, context: context);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Builder(builder: (context) {
          final String title =
              (carType.carTagLine?.trim().isNotEmpty ?? false)
                  ? carType.carTagLine!.trim()
                  : (carType.model?.trim().isNotEmpty ?? false)
                      ? carType.model!.trim()
                      : (carType.type ?? '');

          final int seats = (carType.seats ?? 0).toInt();
          final String category = (carType.type ?? '').trim();
          final String fuel = (carType.combustionType ?? '').trim();

          final bool hasCoupon = carType.coupon != null;


          final String categoryLower = category.toLowerCase();
          final String defaultSubtitle = categoryLower == 'sedan'
              ? 'Compact Car'
              : categoryLower == 'suv'
                  ? 'Spacious Car'
                  : 'Spacious Car';

          final String subtitle =
              (carType.subcategory?.trim().isNotEmpty ?? false)
                  ? carType.subcategory!.trim()
                  : defaultSubtitle;

          num finalInventoryPrice(num baseFare, num discountCouponPrice){
            return baseFare - discountCouponPrice;
          }

          Widget compactConvertedPrice(
            num value, {
            TextStyle? style,
            bool strikeThrough = false,
          }) {
            final double v = value.toDouble();
            return FutureBuilder<double>(
              future: currencyController.convertPrice(v),
              builder: (context, snapshot) {
                final converted = snapshot.data ?? v;
                final formatted = NumberFormat.decimalPattern('en_IN')
                    .format(converted.round());
                return Text(
                  '${currencyController.selectedCurrency.value.symbol}$formatted',
                  style: (style ?? const TextStyle()).copyWith(
                    decoration: strikeThrough
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                );
              },
            );
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFFC1C1C1),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              carType.carImageUrl ?? '',
                              width: 76,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 72,
                                  height: 52,
                                  color: const Color(0xFFF3F4F6),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          height: 1.1,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF585858),
                                        ),
                                      ),
                                    ),
                                    // const SizedBox(width: 10),
                                    // const Icon(
                                    //   Icons.info_outline_rounded,
                                    //   size: 18,
                                    //   color: Color(0xFF2B64E5),
                                    // ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Or Similar',
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64A4F6),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  [
                                    if (category.isNotEmpty) category,
                                    if (seats > 0) '$seats Seats',
                                    if (fuel.isNotEmpty) fuel,
                                  ].join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    height: 1.15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (hasCoupon) SizedBox(
                        height: 1,
                        child: Row(
                          children: List.generate(
                            40,
                                (_) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                color: const Color(0xFF7B7B7B).withOpacity(0.48),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (hasCoupon) const SizedBox(height: 6),
                      if (hasCoupon)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                   Flexible(
                                    child: Text(
                                      carType.coupon?.codeDescription ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF373737),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10,)
                                  // compactConvertedPrice(
                                  //   (carType.discountedCoupon ?? 0),
                                  //   style: const TextStyle(
                                  //     fontSize: 10,
                                  //     fontWeight: FontWeight.w600,
                                  //     color: Color(0xFF373737),
                                  //   ),
                                  // ),
                                  // const Text(
                                  //   ' OFF',
                                  //   style: TextStyle(
                                  //     fontSize: 10,
                                  //     fontWeight: FontWeight.w600,
                                  //     color: Color(0xFF373737),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            CouponAppliedUI(text: carType.coupon?.codeName??'')
                          ],
                        ),
                      if (hasCoupon) const SizedBox(height: 6),
                   SizedBox(
                        height: 1,
                        child: Row(
                          children: List.generate(
                            40,
                                (_) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                color: const Color(0xFF7B7B7B).withOpacity(0.48),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    stops: [0.2376, 1.1101],
                                    colors: [
                                      Color(0xFF64A4F6),
                                      Color(0xFF3B6090),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "New",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                defaultSubtitle,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF484848),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (hasCoupon)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if ((carType.fakePercentageOff ?? 0) > 0)
                                      Text(
                                        '${(carType.coupon?.codePercentage ?? 0).toInt()}% Off',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    compactConvertedPrice(
                                      carType.fareDetails?.baseFare ?? 0,
                                      strikeThrough: true,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 2),
                              compactConvertedPrice(
                                (finalInventoryPrice(carType.fareDetails?.baseFare??0, carType.discountedCoupon??0) ?? 0),
                                style: const TextStyle(
                                  fontSize: 20,
                                  height: 1.05,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF585858),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC1DBFC),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 🔥 key
                      children: const [
                        Text(
                          'Verified Driver',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF585858),
                          ),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          height: 12,
                          child: VerticalDivider(
                            thickness: 1,
                            color: Color(0xFF585858),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pay 20% and rest to driver',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF585858),
                          ),
                        ),
                      ],
                    ),
                  ),
                )

              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGlobalCard(GlobalTripDetails tripDetails,
      GlobalFareDetails fareDetails, GlobalVehicleDetails vehicleDetails) {
    final CurrencyController currencyController = Get.put(CurrencyController());
    final List<IconData> amenityIcons = [
      Icons.cleaning_services, // Tissue
      Icons.sanitizer, // Sanitizer
    ];
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () async {
        final country = dropPlaceSearchController.dropLatLng.value?.country.toLowerCase();
        final CabBookingController cabBookingController =
        Get.put(CabBookingController());
        final Map<String, dynamic> requestData = {
          "isGlobal": false,
          "country": country,
          "routeInventoryId": fareDetails.id,
          "vehicleId": vehicleDetails.id,
          "trip_type": fareDetails.tripType,
          "pickUpDateTime": tripDetails?.pickupDateTime ?? '',
          "dropDateTime": tripDetails.dropDateTime ?? '',
          "totalKilometers": tripDetails.totalDistance ?? 0,
          "package_id": null,
          "source": {},
          "destination": {},
          "tripCode": tripDetails.currentTripCode,
          "trip_type_details": {
            "basic_trip_type": searchCabInventoryController
                .globalData.value?.tripTypeDetails?.basicTripType ??
                '',
            "airport_type": searchCabInventoryController
                .globalData.value?.tripTypeDetails?.airportType ??
                ''
          },
        };
        // Global flow doesn't carry an inventory-provided coupon; ensure we don't reuse a stale one.
        cabBookingController.clearPreselectedCoupon();
        // `fetchBookingData` handles navigation to BookingDetailsFinal via GoRouter.push().
        cabBookingController.fetchBookingData(
          country: country ?? '',
          requestData: requestData,
          context: context,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              elevation: 0.3,
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            Image.network(
                              vehicleDetails.vehicleImageLink ?? '',
                              width: 65,
                              height: 50,
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3F2FD),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                side: const BorderSide(
                                    color: Colors.transparent, width: 1),
                                foregroundColor: const Color(0xFF1565C0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {},
                              child: Text(
                                vehicleDetails.filterCategory ?? '',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      vehicleDetails.title ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16),
                                      overflow: TextOverflow.clip,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.mainButtonBg,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  side: const BorderSide(
                                      color: AppColors.mainButtonBg, width: 1),
                                  foregroundColor: Colors.white,
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () {},
                                child: Text(
                                  vehicleDetails.fuelType ?? '',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                      "${vehicleDetails.passengerCapacity} Seater",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 10,
                                          color: Colors.grey[700])),
                                  const SizedBox(width: 8),
                                  Text(
                                      "• ${vehicleDetails.checkinLuggageCapacity.toString()} bags",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 10,
                                          color: Colors.grey[700])),
                                ],
                              )
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text("20%",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 6),
                                FutureBuilder<double>(
                                  future: currencyController.convertPrice(
                                    getFakePriceWithPercent(
                                        tripDetails.totalFare, 20)
                                        .toDouble(),
                                  ),
                                  builder: (context, snapshot) {
                                    final convertedValue = snapshot.data ??
                                        getFakePriceWithPercent(
                                            tripDetails.totalFare, 20)
                                            .toDouble();

                                    return Text(
                                      '${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Colors
                                            .grey, // lighter color for cut-off price
                                        decoration: TextDecoration
                                            .lineThrough, // 👈 adds cutoff
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                FutureBuilder<double>(
                                  future: currencyController.convertPrice(
                                      tripDetails.totalFare?.toDouble() ?? 0),
                                  builder: (context, snapshot) {
                                    final convertedValue =
                                        snapshot.data ?? tripDetails.totalFare;
                                    return Text(
                                      '${currencyController.selectedCurrency.value.symbol}${convertedValue?.toDouble().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                    );
                                  },
                                ),
                              ],
                            ),
                            // Text(
                            //   'All Inclusions',
                            //   style: const TextStyle(
                            //     fontWeight: FontWeight.w600,
                            //     fontSize: 10,
                            //     color: Colors.grey, // lighter color for cut-off price
                            //   ),
                            // ),
                            // ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50, // light background
                                borderRadius: BorderRadius.circular(4),
                                border:
                                Border.all(color: Colors.green, width: 1),
                              ),
                              child: const Text(
                                "Free Cancellation",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // const SizedBox(height: 4),
                            // FutureBuilder<double>(
                            //   future: currencyController.convertPrice(
                            //       getFivePercentOfBaseFare(
                            //               fareDetails.baseFare ?? 0)
                            //           .toDouble()),
                            //   builder: (context, snapshot) {
                            //     final convertedTaxes = snapshot.data ??
                            //         getFivePercentOfBaseFare(
                            //                 fareDetails.baseFare ?? 0)
                            //             .toDouble();
                            //     return Text(
                            //       '+ ${currencyController.selectedCurrency.value.symbol}${convertedTaxes.toStringAsFixed(2)} (taxes & charges)',
                            //       style: TextStyle(
                            //           color: Colors.grey[600], fontSize: 10),
                            //     );
                            //   },
                            // ),
                          ],
                        )
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    SizedBox(
                      height: 20,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vehicleDetails.extras?.length ?? 0,
                        itemBuilder: (context, index) {
                          final iconUrl = amenityIcons[index] ?? '';
                          final label = vehicleDetails.extras?[index] ?? '';

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.grey.shade400, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // load icon from API (SVG or PNG)
                                Icon(
                                  amenityIcons[index],
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildConvertedPrice(double value,
      {TextStyle? style, bool strikeThrough = false, String prefix = "₹"}) {
    final CurrencyController currencyController = Get.put(CurrencyController());
    return FutureBuilder<double>(
      future: currencyController.convertPrice(value),
      builder: (context, snapshot) {
        final converted = snapshot.data ?? value;
        return Text(
          "$prefix${converted.toStringAsFixed(2)}",
          style: style?.copyWith(
              decoration: strikeThrough
                  ? TextDecoration.lineThrough
                  : TextDecoration.none) ??
              TextStyle(
                  decoration: strikeThrough
                      ? TextDecoration.lineThrough
                      : TextDecoration.none),
        );
      },
    );
  }
}

class CouponAppliedUI extends StatefulWidget {
  final String text;
  
  const CouponAppliedUI({super.key, required this.text});

  @override
  State<CouponAppliedUI> createState() => _CouponAppliedUIState();
}

class _CouponAppliedUIState extends State<CouponAppliedUI> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:  [
        Text(
          "Applied",
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF585858),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 8),
        DottedBorderChip(text: widget.text??''),
      ],
    );
  }
}

class DottedBorderChip extends StatelessWidget {
  final String text;

  const DottedBorderChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedRoundedBorderPainter(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF8E8), // light green background
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF7CC521), // green text
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
class _DottedRoundedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7CC521)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 3;
    const dashSpace = 3;
    const radius = 20.0;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}



class BookingTopBar extends StatefulWidget {
  final bool? fromRecentSearch;

  const BookingTopBar({super.key, this.fromRecentSearch});
  @override
  State<BookingTopBar> createState() => _BookingTopBarState();
}

class _BookingTopBarState extends State<BookingTopBar> {
  final SearchCabInventoryController searchCabInventoryController =
  Get.put(SearchCabInventoryController());
  final BookingRideController bookingRideController =
  Get.put(BookingRideController());
  final PlaceSearchController placeSearchController =
  Get.put(PlaceSearchController());
  final FetchPackageController fetchPackageController =
  Get.put(FetchPackageController());

  String? tripCode;
  String? previousCode;

  @override
  void initState() {
    super.initState();
    getCurrentTripCode();
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  String formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthName(dateTime.month);
    final year = dateTime.year;

    int hour = dateTime.hour % 12;
    hour = hour == 0 ? 12 : hour; // handle midnight & noon
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$day $month, $hour:$minute $period';
  }

  void getCurrentTripCode() async {
    tripCode = await StorageServices.instance.read('currentTripCode') ??
        await StorageServices.instance.read('previousTripCode');
    previousCode =
        await StorageServices.instance.read('previousTripCode') ?? '';
    if (mounted) {
      setState(() {});
    }
  }

  String trimAfterTwoSpaces(String input) {
    final parts = input.split(' ');
    if (parts.length <= 2) return input;
    return parts.take(2).join(' ');
  }

  Widget _buildTripTypeTag(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.mainButtonBg.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.mainButtonBg),
      ),
    );
  }

  String convertUtcToLocal(String utcTimeString, String timezoneString) {
    // Parse UTC time
    DateTime utcTime = DateTime.parse(utcTimeString);

    // Get the location based on timezone string like "Asia/Kolkata"
    final location = tz.getLocation(timezoneString);

    // Convert UTC to local time in given timezone
    final localTime = tz.TZDateTime.from(utcTime, location);

    // Format as "3 Sep, 07:30 AM"
    final formatted = DateFormat("d MMM, hh:mm a").format(localTime);

    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pickupDateTime = bookingRideController.localStartTime.value;
      final formattedPickup = formatDateTime(pickupDateTime);
      DateTime localEndUtc = bookingRideController.localEndTime.value.toUtc();
      DateTime? backendEndUtc =
          searchCabInventoryController.indiaData.value?.result?.tripType?.endTime;
      final activeTripCode = searchCabInventoryController.newCurrent.value
              .toString()
              .trim()
              .isNotEmpty
          ? searchCabInventoryController.newCurrent.value.toString()
          : searchCabInventoryController.tripCode.value.toString();

      DateTime finalDropUtc =
          (backendEndUtc != null && backendEndUtc.isAfter(localEndUtc))
              ? backendEndUtc
              : localEndUtc;

      final formattedDrop = convertUtcToLocal(
        finalDropUtc.toIso8601String(),
        placeSearchController.findCntryDateTimeResponse.value?.timeZone ?? '',
      );

      return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: GestureDetector(
          onTap: () {
            final tabName = bookingRideController.currentTabName;
            final route = tabName == 'rental'
                ? '${AppRoutes.bookingRide}?tab=airport'
                : '${AppRoutes.bookingRide}?tab=airport';

            if (widget.fromRecentSearch == true) {
              GoRouter.of(context).push(route,
                  extra: (context) => Platform.isIOS
                      ? CupertinoPage(child: const BottomNavScreen())
                      : MaterialPage(child: const BottomNavScreen()));
            } else {
              GoRouter.of(context).push(AppRoutes.bookingRide);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back,
                size: 16, color: AppColors.mainButtonBg),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                activeTripCode == '3'
                    ? bookingRideController.prefilled.value
                    : '${trimAfterTwoSpaces(bookingRideController.prefilled.value)} to ${trimAfterTwoSpaces(bookingRideController.prefilledDrop.value)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (activeTripCode.isNotEmpty)
              GestureDetector(
                  onTap: () {
                    bookingRideController.isInventoryPage.value = true;
                    bookingRideController.isPopupOpen.value = true;
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => TopBookingDialogWrapper(),
                    ).whenComplete(() {
                      bookingRideController.isPopupOpen.value = false;
                    });
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    decoration: BoxDecoration(
                      color: AppColors.mainButtonBg.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit,
                            size: 14, color: AppColors.mainButtonBg),
                        SizedBox(width: 4),
                        Text(
                          "Edit",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mainButtonBg,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (activeTripCode == '1')
                  ? '$formattedPickup - $formattedDrop'
                  : '$formattedPickup',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greyText5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (activeTripCode == '3')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectedPackageCard(controller: fetchPackageController),
              ),
            // if (tripCode == '0') _buildTripTypeTag('Outstation One Way Trip'),
            // if (tripCode == '1') _buildTripTypeTag('Outstation Round Way Trip'),
            // if (tripCode == '2') _buildTripTypeTag('Airport Trip'),
            // if (tripCode == '3') _buildTripTypeTag('Rental Trip'),
          ],
        ),
      ),
    );
    });
  }
}

Widget _buildTripTypeTag(String text) {
  return Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.mainButtonBg.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.mainButtonBg,
      ),
    ),
  );
}

class TopBookingDialogWrapper extends StatefulWidget {
  const TopBookingDialogWrapper({super.key});

  @override
  State<TopBookingDialogWrapper> createState() =>
      _TopBookingDialogWrapperState();
}

class _TopBookingDialogWrapperState extends State<TopBookingDialogWrapper> {
  final SearchCabInventoryController searchCabInventoryController = Get.find();
  final BookingRideController bookingRideController = Get.find();
  final PlaceSearchController placeSearchController = Get.find();
  final DropPlaceSearchController dropPlaceSearchController = Get.find();
  final String _popupPickupTag = 'popup_pickup_dialog_controller';
  final String _popupDropTag = 'popup_drop_dialog_controller';
  late final PopupPickupSearchController popupPickupSearchController;
  late final PopupDropSearchController popupDropSearchController;
  Worker? _tripCodeWorker;
  int _selectedTabIndex = 0;
  String _selectedOutstationTrip = 'oneWay';
  DateTime? _pickupDateTime;
  DateTime? _dropDateTime;
  bool _isSearching = false;
  String _editedPickup = '';
  String _editedDrop = '';
  String _editedPickupPlaceId = '';
  String _editedDropPlaceId = '';
  GetLatLngResponse? _editedPickupLatLng;
  GetLatLngResponse? _editedDropLatLng;
  SuggestionPlacesResponse? _editedPickupSuggestion;
  SuggestionPlacesResponse? _editedDropSuggestion;

  int _tripCodeToTabIndex(String tripCode) {
    if (tripCode == '2') return 1;
    if (tripCode == '3') return 2;
    return 0;
  }

  String _tripCodeToOutstationTrip(String tripCode) {
    return tripCode == '1' ? 'roundTrip' : 'oneWay';
  }

  String _resolvedTripCodeForSelection() {
    if (_selectedTabIndex == 1) return '2';
    if (_selectedTabIndex == 2) return '3';
    return _selectedOutstationTrip == 'roundTrip' ? '1' : '0';
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd MMM, yyyy hh:mm a').format(value);
  }

  Future<DateTime?> _showCupertinoDateTimePicker({
    required DateTime initialDateTime,
  }) async {
    DateTime tempPicked = initialDateTime;

    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E5EA)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(tempPicked),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: initialDateTime,
                  minimumDate: DateTime.now().subtract(const Duration(days: 365)),
                  maximumDate: DateTime.now().add(const Duration(days: 3650)),
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempPicked = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDateTime({required bool isPickup}) async {
    final currentValue = isPickup
        ? (_pickupDateTime ?? bookingRideController.localStartTime.value)
        : (_dropDateTime ?? bookingRideController.localEndTime.value);
    final selected = await _showCupertinoDateTimePicker(
      initialDateTime: currentValue,
    );
    if (selected == null || !mounted) return;

    setState(() {
      if (isPickup) {
        _pickupDateTime = selected;
        if (_dropDateTime != null && _dropDateTime!.isBefore(selected)) {
          _dropDateTime = selected.add(const Duration(hours: 1));
        }
      } else {
        _dropDateTime = selected;
      }
    });
  }

  Widget _buildTripTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mainButtonBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.greyText5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutstationTripSelector() {
    Widget buildOption(String title, String value) {
      final isSelected = _selectedOutstationTrip == value;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedOutstationTrip = value;
            });
            searchCabInventoryController.newCurrent.value =
                _resolvedTripCodeForSelection();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.mainButtonBg.withOpacity(0.12) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off_outlined,
                  size: 16,
                  color: isSelected ? AppColors.mainButtonBg : AppColors.greyText5,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? AppColors.mainButtonBg : AppColors.greyText5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        border: Border.all(color: const Color(0xFFE1E5EE)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          buildOption('One Way', 'oneWay'),
          const SizedBox(width: 8),
          buildOption('Round Trip', 'roundTrip'),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.greyText5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          readOnly: true,
          initialValue: value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 18, color: AppColors.mainButtonBg),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE1E5EE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE1E5EE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.mainButtonBg),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLocationTap({required bool isPickup}) async {
    if (isPickup) {
      final result = await Navigator.push<SuggestionPlacesResponse>(
        context,
        Platform.isIOS
            ? CupertinoPageRoute(
                builder: (context) => PopupSelectPickup(
                  controllerTag: _popupPickupTag,
                  initialText: _editedPickup,
                ),
              )
            : MaterialPageRoute(
                builder: (context) => PopupSelectPickup(
                  controllerTag: _popupPickupTag,
                  initialText: _editedPickup,
                ),
              ),
      );
      if (result == null || !mounted) return;

      setState(() {
        _editedPickup = result.primaryText;
        _editedPickupPlaceId = result.placeId;
        _editedPickupLatLng = popupPickupSearchController.getPlacesLatLng.value;
      _editedPickupSuggestion = result;
      });
      return;
    }

    final result = await Navigator.push<SuggestionPlacesResponse>(
      context,
      Platform.isIOS
          ? CupertinoPageRoute(
              builder: (context) => PopupSelectDrop(
                controllerTag: _popupDropTag,
                initialText: _editedDrop,
              ),
            )
          : MaterialPageRoute(
              builder: (context) => PopupSelectDrop(
                controllerTag: _popupDropTag,
                initialText: _editedDrop,
              ),
            ),
    );
    if (result == null || !mounted) return;

    if (_editedPickupPlaceId.isNotEmpty && _editedPickupPlaceId == result.placeId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and drop cannot be same.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _editedDrop = result.primaryText;
      _editedDropPlaceId = result.placeId;
      _editedDropLatLng = popupDropSearchController.dropLatLng.value;
      _editedDropSuggestion = result;
    });
  }

  Map<String, dynamic> _buildUpdatedRequestData({
    required DateTime selectedPickup,
    required DateTime selectedDrop,
    required String tripCode,
  }) {
    final baseData = bookingRideController.requestData.isNotEmpty
        ? Map<String, dynamic>.from(bookingRideController.requestData)
        : <String, dynamic>{};

    final source = Map<String, dynamic>.from(
      (baseData['source'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    final destination = Map<String, dynamic>.from(
      (baseData['destination'] as Map?)?.cast<String, dynamic>() ?? {},
    );

    final pickupCountry =
        _editedPickupLatLng?.country.isNotEmpty == true
            ? _editedPickupLatLng!.country
            : (_editedDropLatLng?.country ?? baseData['countryName'] ?? 'India');
    final sourceCountry = _editedPickupLatLng?.country ?? pickupCountry;
    final destinationCountry = _editedDropLatLng?.country ?? pickupCountry;

    List<String> _toStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return <String>[];
    }

    List<Map<String, dynamic>> _toTermList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      return <Map<String, dynamic>>[];
    }

    final sourceTypes = _editedPickupSuggestion != null
        ? List<String>.from(_editedPickupSuggestion!.types)
        : _toStringList(source['sourceType']);
    final sourceTerms = _editedPickupSuggestion != null
        ? _editedPickupSuggestion!.terms
            .map((t) => {'offset': t.offset, 'value': t.value})
            .toList()
        : _toTermList(source['terms']);

    final destinationTypes = _editedDropSuggestion != null
        ? List<String>.from(_editedDropSuggestion!.types)
        : _toStringList(destination['destinationType']);
    final destinationTerms = _editedDropSuggestion != null
        ? _editedDropSuggestion!.terms
            .map((t) => {'offset': t.offset, 'value': t.value})
            .toList()
        : _toTermList(destination['terms']);

    source['sourceTitle'] = _editedPickup;
    source['sourcePlaceId'] = _editedPickupPlaceId;
    source['sourceCity'] = _editedPickupLatLng?.city ?? source['sourceCity'] ?? '';
    source['sourceState'] =
        _editedPickupLatLng?.state ?? source['sourceState'] ?? '';
    source['sourceCountry'] = sourceCountry;
    source['sourceLat'] =
        _editedPickupLatLng?.latLong.lat.toString() ?? source['sourceLat'] ?? '';
    source['sourceLng'] =
        _editedPickupLatLng?.latLong.lng.toString() ?? source['sourceLng'] ?? '';
    source['sourceType'] = sourceTypes;
    source['terms'] = sourceTerms;

    destination['destinationTitle'] = _editedDrop;
    destination['destinationPlaceId'] = _editedDropPlaceId;
    destination['destinationCity'] =
        _editedDropLatLng?.city ?? destination['destinationCity'] ?? '';
    destination['destinationState'] =
        _editedDropLatLng?.state ?? destination['destinationState'] ?? '';
    destination['destinationCountry'] = destinationCountry;
    destination['destinationLat'] = _editedDropLatLng?.latLong.lat.toString() ??
        destination['destinationLat'] ??
        '';
    destination['destinationLng'] = _editedDropLatLng?.latLong.lng.toString() ??
        destination['destinationLng'] ??
        '';
    destination['destinationType'] = destinationTypes;
    destination['terms'] = destinationTerms;

    baseData['applicationType'] = baseData['applicationType'] ?? 'APP';
    baseData['comingFrom'] = baseData['comingFrom'] ?? 'searchInventory api 2nd page -APP';
    baseData['tripCode'] = tripCode;
    baseData['countryName'] = pickupCountry;
    baseData['country'] = pickupCountry;
    baseData['pickupDateAndTime'] = selectedPickup.toUtc().toIso8601String();
    baseData['pickUpDateTime'] = selectedPickup.toUtc().toIso8601String();
    baseData['returnDateAndTime'] =
        tripCode == '1' ? selectedDrop.toUtc().toIso8601String() : '';
    baseData['dropDateTime'] = selectedDrop.toUtc().toIso8601String();
    baseData['source'] = source;
    baseData['destination'] = destination;

    return baseData;
  }

  Future<void> _submitPopupSearch() async {
    if (_isSearching) return;
    final selectedPickup =
        _pickupDateTime ?? bookingRideController.localStartTime.value;
    DateTime selectedDrop = _dropDateTime ?? bookingRideController.localEndTime.value;

    if (selectedDrop.isBefore(selectedPickup)) {
      selectedDrop = selectedPickup.add(const Duration(hours: 1));
    }

    if (_editedPickupPlaceId.isNotEmpty && _editedPickupPlaceId == _editedDropPlaceId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and drop cannot be same.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_editedPickupPlaceId.isEmpty ||
        (_selectedTabIndex != 2 && _editedDropPlaceId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and drop locations.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tripCode = _resolvedTripCodeForSelection();

    final updatedRequestData = _buildUpdatedRequestData(
      selectedPickup: selectedPickup,
      selectedDrop: selectedDrop,
      tripCode: tripCode,
    );

    setState(() => _isSearching = true);
    try {
      bookingRideController.prefilled.value = _editedPickup;
      bookingRideController.prefilledDrop.value = _editedDrop;
      placeSearchController.placeId.value = _editedPickupPlaceId;
      dropPlaceSearchController.dropPlaceId.value = _editedDropPlaceId;
      placeSearchController.getPlacesLatLng.value = _editedPickupLatLng;
      dropPlaceSearchController.dropLatLng.value = _editedDropLatLng;
      bookingRideController.localStartTime.value = selectedPickup;
      bookingRideController.localEndTime.value = selectedDrop;
      bookingRideController.requestData.value = updatedRequestData;
      await Future.wait([
        StorageServices.instance.save('sourceTitle', _editedPickup),
        StorageServices.instance.save('sourcePlaceId', _editedPickupPlaceId),
        StorageServices.instance.save(
            'sourceTypes',
            jsonEncode((updatedRequestData['source'] as Map)['sourceType'] ?? [])),
        StorageServices.instance.save(
            'sourceTerms',
            jsonEncode((updatedRequestData['source'] as Map)['terms'] ?? [])),
        StorageServices.instance.save('destinationTitle', _editedDrop),
        StorageServices.instance.save(
            'destinationPlaceId', _editedDropPlaceId),
        StorageServices.instance.save(
            'destinationTypes',
            jsonEncode((updatedRequestData['destination'] as Map)['destinationType'] ??
                [])),
        StorageServices.instance.save(
            'destinationTerms',
            jsonEncode((updatedRequestData['destination'] as Map)['terms'] ?? [])),
      ]);

      await searchCabInventoryController.fetchBookingData(
        country: (updatedRequestData['countryName'] ??
                updatedRequestData['country'] ??
                '')
            .toString(),
        requestData: updatedRequestData,
        context: context,
        isSecondPage: true,
      );

      if (!mounted) return;
      bookingRideController.isPopupOpen.value = false;
      GoRouter.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Widget _buildEditableDateField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.greyText5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onTap,
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mainButtonBg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: Icon(icon, size: 18, color: AppColors.mainButtonBg),
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE1E5EE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE1E5EE)),
              ),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    popupPickupSearchController = Get.put(
      PopupPickupSearchController(),
      tag: _popupPickupTag,
    );
    popupDropSearchController = Get.put(
      PopupDropSearchController(),
      tag: _popupDropTag,
    );
    final initialTripCode =
        searchCabInventoryController.newCurrent.value.toString();
    _selectedTabIndex = _tripCodeToTabIndex(
      initialTripCode,
    );
    _selectedOutstationTrip = _tripCodeToOutstationTrip(initialTripCode);
    _pickupDateTime = bookingRideController.localStartTime.value;
    _dropDateTime = bookingRideController.localEndTime.value;
    _editedPickup = bookingRideController.prefilled.value;
    _editedDrop = bookingRideController.prefilledDrop.value;
    _editedPickupPlaceId = placeSearchController.placeId.value;
    _editedDropPlaceId = dropPlaceSearchController.dropPlaceId.value;
    _editedPickupLatLng = placeSearchController.getPlacesLatLng.value;
    _editedDropLatLng = dropPlaceSearchController.dropLatLng.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchCabInventoryController.loadTripCode();
    });

    _tripCodeWorker = ever(searchCabInventoryController.newCurrent, (value) {
      final tripCode = value.toString();
      final nextTab = _tripCodeToTabIndex(tripCode);
      final nextOutstation = _tripCodeToOutstationTrip(tripCode);
      if (mounted &&
          (nextTab != _selectedTabIndex ||
              nextOutstation != _selectedOutstationTrip)) {
        setState(() {
          _selectedTabIndex = nextTab;
          _selectedOutstationTrip = nextOutstation;
        });
      }
    });
  }

  @override
  void dispose() {
    _tripCodeWorker?.dispose();
    if (Get.isRegistered<PopupPickupSearchController>(tag: _popupPickupTag)) {
      Get.delete<PopupPickupSearchController>(tag: _popupPickupTag);
    }
    if (Get.isRegistered<PopupDropSearchController>(tag: _popupDropTag)) {
      Get.delete<PopupDropSearchController>(tag: _popupDropTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(builder: (_) {
          final pickup = _editedPickup.trim();
          final drop = _editedDrop.trim();
          final pickupDateTime =
              _pickupDateTime ?? bookingRideController.localStartTime.value;
          final dropDateTime =
              _dropDateTime ?? bookingRideController.localEndTime.value;
          final pickupDate = _formatDateTime(pickupDateTime);
          final dropDate = _formatDateTime(dropDateTime);

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Edit Trip Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        bookingRideController.isPopupOpen.value = false;
                        GoRouter.of(context).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildTripTab(
                        title: 'Outstation',
                        isSelected: _selectedTabIndex == 0,
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 0;
                          });
                          searchCabInventoryController.newCurrent.value =
                              _resolvedTripCodeForSelection();
                        },
                      ),
                      _buildTripTab(
                        title: 'Airport',
                        isSelected: _selectedTabIndex == 1,
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 1;
                          });
                          searchCabInventoryController.newCurrent.value =
                              _resolvedTripCodeForSelection();
                        },
                      ),
                      _buildTripTab(
                        title: 'Rental',
                        isSelected: _selectedTabIndex == 2,
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 2;
                          });
                          searchCabInventoryController.newCurrent.value =
                              _resolvedTripCodeForSelection();
                        },
                      ),
                    ],
                  ),
                ),
                if (_selectedTabIndex == 0) ...[
                  const SizedBox(height: 10),
                  _buildOutstationTripSelector(),
                ],
                const SizedBox(height: 16),
                _buildEditableDateField(
                  label: 'Pickup',
                  value: pickup.isEmpty ? 'Select pickup location' : pickup,
                  icon: Icons.my_location,
                  onTap: () => _handleLocationTap(isPickup: true),
                ),
                const SizedBox(height: 12),
                _buildEditableDateField(
                  label: 'Drop',
                  value: drop.isEmpty ? 'Select drop location' : drop,
                  icon: Icons.location_on_outlined,
                  onTap: () => _handleLocationTap(isPickup: false),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildEditableDateField(
                        label: 'Pickup DateTime',
                        value: pickupDate,
                        icon: Icons.calendar_today_outlined,
                        onTap: () => _pickDateTime(isPickup: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildEditableDateField(
                        label: 'Drop DateTime',
                        value: dropDate,
                        icon: Icons.calendar_month_outlined,
                        onTap: () => _pickDateTime(isPickup: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: MainButton(
                    text: 'Search Now',
                    isLoading: _isSearching,
                    onPressed: _submitPopupSearch,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class BookNowChipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const BookNowChipButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: const Text(
        'Book Now',
        style: TextStyle(
            fontSize: 8, color: Colors.white, fontWeight: FontWeight.w500),
      ),
      backgroundColor: AppColors.mainButtonBg,
      onPressed: onPressed,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

Widget _buildShimmer() {
  return Column(
    children: [
      const SizedBox(height: 40),
      Padding(
        padding: const EdgeInsets.all(8),
        child: ShimmerWidget.rectangular(height: 50, width: double.infinity),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.all(8),
            child:
            ShimmerWidget.rectangular(height: 50, width: double.infinity),
          ),
        ),
      ),
    ],
  );
}

class ShimmerWidget extends StatelessWidget {
  final double height;
  final double width;

  const ShimmerWidget.rectangular(
      {super.key, required this.height, this.width = double.infinity});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class StaticBookingTopBar extends StatelessWidget {
  const StaticBookingTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pickup",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                const Text("Connaught Place, Delhi",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                const Text("Sat, 10 Aug · 09:00 AM",
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.swap_vert, size: 20, color: Colors.black54),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Drop",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                const Text("Jaipur, Rajasthan",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                const Text("Sat, 10 Aug · 02:00 PM",
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedPackageCard extends StatelessWidget {
  final FetchPackageController controller;
  final SearchCabInventoryController searchCabInventoryController =
  Get.put(SearchCabInventoryController());

  SelectedPackageCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedPackage.value.isEmpty ||
          searchCabInventoryController.tripCode.value.toString() != '3') {
        return const SizedBox();
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selected Package -",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600)),
                const SizedBox(width: 8),
                Text(controller.selectedPackage.value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainButtonBg)),
              ],
            ),
          ),
        ],
      );
    });
  }
}


/// A mapping class (similar to your JS `searchEngineMap`)
class SearchEngineMap {
  static const int AIRPORT_TRANSFER = 2;
  static const int ONE_WAY = 0;
  static const int TWO_WAY = 1;
  static const int HOURLY_RENTAL = 3;
}

/// Returns the trip type label based on trip code.
String getTripTypeString(dynamic tripCode) {
  final int code = int.tryParse(tripCode.toString()) ?? -1;

  switch (code) {
    case SearchEngineMap.AIRPORT_TRANSFER:
      return 'Airport';
    case SearchEngineMap.ONE_WAY:
    case SearchEngineMap.TWO_WAY:
      return 'Outstation';
    case SearchEngineMap.HOURLY_RENTAL:
      return 'Hourly';
    default:
      return 'Unknown';
  }
}

/// Returns the trip category label (like Airport_Pickup, One Way, etc.)
String getTripCategoryString(
    dynamic tripCode,
    String? airportType,
    String? tripPackage,
    ) {
  final int code = int.tryParse(tripCode.toString()) ?? -1;

  switch (code) {
    case SearchEngineMap.AIRPORT_TRANSFER:
      return 'Airport_${airportType == 'PICKUP' ? 'Pickup' : 'Drop'}';

    case SearchEngineMap.ONE_WAY:
      return 'One Way';

    case SearchEngineMap.TWO_WAY:
      return 'Round Trip';

    case SearchEngineMap.HOURLY_RENTAL:
      if (tripPackage != null && tripPackage.contains('_')) {
        final parts = tripPackage.split('_');
        // Example: PKG_40_4 → ["PKG", "40", "4"]
        if (parts.length >= 3) {
          return '${parts[1]} KM, ${parts[2]} HRS';
        }
      }
      return 'Hourly Rental';

    default:
      return 'Outstation';
  }
}

