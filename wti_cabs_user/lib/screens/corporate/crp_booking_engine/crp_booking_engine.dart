import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart' as location;
import 'package:http/http.dart' as http;
import 'package:wti_cabs_user/common_widget/dropdown/cpr_select_box.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_select_drop_controller/crp_select_drop_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_select_pickup_controller/crp_select_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/verify_corporate/verify_corporate_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/select_location/select_drop.dart';
import '../../../../common_widget/textformfield/booking_textformfield.dart';
import '../../../../utility/constants/colors/app_colors.dart';
import '../../../../utility/constants/fonts/common_fonts.dart';
import '../../../core/controller/corporate/crp_gender/crp_gender_controller.dart';
import '../../../core/controller/corporate/crp_car_provider/crp_car_provider_controller.dart';
import '../../../core/controller/corporate/crp_get_entity_all/crp_get_entity_list_controller.dart';
import '../../../core/controller/corporate/crp_payment_mode_controller/crp_payment_mode_controller.dart';
import '../../../core/controller/corporate/crp_services_controller/crp_sevices_controller.dart';
import '../../../core/model/corporate/crp_login_response/crp_login_response.dart';
import '../../../core/model/corporate/get_entity_list/get_entity_list_response.dart';
import '../../../core/model/corporate/crp_gender_response/crp_gender_response.dart';
import '../../../core/model/corporate/crp_car_provider_response/crp_car_provider_response.dart';
import '../../../core/model/corporate/crp_payment_method/crp_payment_mode.dart';
import '../../../core/model/corporate/crp_services/crp_services_response.dart';
import '../../../core/model/corporate/crp_booking_data/crp_booking_data.dart';
import '../../../core/model/booking_engine/suggestions_places_response.dart';
import '../../../core/services/storage_services.dart';
import '../../../core/controller/corporate/crp_login_controller/crp_login_controller.dart';

class CprBookingEngine extends StatefulWidget {
  final String? selectedPickupType;
  final SuggestionPlacesResponse? selectedPickupPlace;
  final SuggestionPlacesResponse? selectedDropPlace;

  const CprBookingEngine({
    super.key,
    this.selectedPickupType,
    this.selectedPickupPlace,
    this.selectedDropPlace,
  });

  @override
  State<CprBookingEngine> createState() => _CprBookingEngineState();
}

class _CprBookingEngineState extends State<CprBookingEngine> {
  final GenderController controller = Get.put(GenderController());
  final CarProviderController carProviderController =
      Get.put(CarProviderController());
  final LoginInfoController loginInfoController =
      Get.put(LoginInfoController());
  final CrpGetEntityListController crpGetEntityListController =
      Get.put(CrpGetEntityListController());

  final VerifyCorporateController verifyCorporateController =
      Get.put(VerifyCorporateController());

  String? guestId, token, user;
  int? _preselectedRunTypeId;
  bool _hasAppliedPreselection = false;
  bool _hasAppliedPrefilledData = false;
  Entity? selectedCorporate;
  Entity? selectedEntity;
  bool _isLoadingPickupLocation =
      true; // Track loading state for pickup location
  final ScrollController _scrollController = ScrollController();

  Future<void> fetchParameter() async {
    final storage = StorageServices.instance;
    // GuestID should be read from its own key, not from branchId
    guestId = await storage.read('guestId');
    token = loginInfoController.crpLoginInfo.value?.key ??
        await storage.read('crpKey');
    user = await storage.read('email');
  }

  Future<void> _loadCorporateEntities() async {
    try {
      // Check if entities are already loaded
      final entities =
          crpGetEntityListController.getAllEntityList.value?.getEntityList ??
              [];
      if (entities.isNotEmpty) {
        debugPrint('✅ Corporate entities already loaded, skipping API call');
        return;
      }

      final email = await StorageServices.instance.read('email');
      if (email != null && email.isNotEmpty) {
        await crpGetEntityListController.fetchAllEntities(email, '');
      }
    } catch (_) {
      // Silently ignore – dropdown will just be empty on failure.
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // PRIORITY: Prefill current location immediately when screen appears (like Uber)
    // This happens first to ensure location is visible immediately
    // Skip if selectedPickupType is passed (will be handled in _initializeData after clearing)
    if (widget.selectedPickupType == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillPickupFromCurrentLocation();
      });
    }

    // Initialize async operations
    _initializeData();

    // Listen to entity list changes and retry prefilling
    ever(crpGetEntityListController.getAllEntityList, (_) {
      if (mounted && selectedCorporate == null) {
        final entities =
            crpGetEntityListController.getAllEntityList.value?.getEntityList ??
                [];
        if (entities.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tryPrefillCorporateEntity(entities);
          });
        }
      }
    });

    // Listen to gender list changes and retry prefilling
    ever(controller.genderList, (_) {
      if (mounted &&
          controller.selectedGender.value == null &&
          controller.genderList.isNotEmpty) {
        debugPrint(
            '🔄 Gender list updated, retrying prefilling. List size: ${controller.genderList.length}');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Get gender ID and try to prefill
          final int targetGenderId = await _getPrefillGenderId();
          if (targetGenderId != 0 && mounted) {
            GenderModel? matchedGender;
            for (final gender in controller.genderList) {
              if (gender.genderID != null &&
                  gender.genderID == targetGenderId) {
                matchedGender = gender;
                break;
              }
            }
            if (matchedGender != null && mounted) {
              setState(() {
                controller.selectGender(matchedGender);
                debugPrint(
                    '✅ Prefilled Gender from listener: ${matchedGender?.gender}');
              });
            }
          }
        });
      }
    });

    // Listen to car provider list changes and retry prefilling
    ever(carProviderController.carProviderList, (_) {
      if (mounted &&
          carProviderController.selectedCarProvider.value == null &&
          carProviderController.carProviderList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyPrefilledDataFromLogin();
        });
      }
    });
  }

  /// Initialize all data sources - ensures proper order and waiting
  Future<void> _initializeData() async {
    // 1. Login info should already be loaded from main.dart, but ensure it's available
    // This is a safety check in case main.dart didn't load it yet
    // Force reload to ensure fresh data after app kill

    // 3. If selectedPickupType is passed from navigation, use it
    if (widget.selectedPickupType != null) {
      selectedPickupType = widget.selectedPickupType;
      // Only clear pickup and drop locations when navigating from corporate bottom nav (home screen)
      // Don't clear if we're coming back from location selection (selectedPickupPlace or selectedDropPlace is passed)
      if (widget.selectedPickupPlace == null &&
          widget.selectedDropPlace == null) {
        // Ensure loading state is true when coming from home screen (will show loading indicator)
        if (mounted) {
          setState(() {
            _isLoadingPickupLocation = true;
          });
        }
        // Defer clearing until after build to avoid setState during build error
        // After clearing, immediately prefill with current location from storage
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _clearPickupAndDropLocations();
          // Prefill current location after clearing (to show current location when coming from home screen)
          // Loading will stop when prefilling completes in _prefillPickupFromCurrentLocation()
          _prefillPickupFromCurrentLocation();
        });
      }
    }

    // 4. If selected place is passed from location selection, set it in the controller
    if (widget.selectedPickupPlace != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        crpSelectPickupController.selectedPlace.value =
            widget.selectedPickupPlace;
        if (widget.selectedPickupPlace!.primaryText.isNotEmpty) {
          crpSelectPickupController.searchController.text =
              widget.selectedPickupPlace!.primaryText;
        }
        // Stop loading since pickup is already provided
        if (mounted) {
          setState(() {
            _isLoadingPickupLocation = false;
          });
        }
      });
    }

    // 5. If selected drop place is passed from location selection, set it in the controller
    if (widget.selectedDropPlace != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        crpSelectDropController.selectedPlace.value = widget.selectedDropPlace;
        if (widget.selectedDropPlace!.primaryText.isNotEmpty) {
          crpSelectDropController.searchController.text =
              widget.selectedDropPlace!.primaryText;
        }
      });
    }

    // 6. Load other data (these don't need to wait)
    _loadPreselectedRunType();
    // Note: Location prefilling is now handled in initState() for immediate display
    _loadCorporateEntities();

    // 7. Fetch fresh data from APIs (will use cached data if API fails)
    // Don't await - let it run in background while UI shows cached data
    runTypesAndPaymentModes();

    // 8. Apply all other prefilled data once APIs & lists are ready
    // Use a post-frame callback with a small delay to ensure everything is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Small delay to ensure storage-loaded lists are available
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _applyPrefilledDataFromLogin();
      }

      // Retry prefilling after a longer delay to catch late-loading data
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _applyPrefilledDataFromLogin();
        }
      });
    });
  }

  void runTypesAndPaymentModes() async {
    try {
      // Check if data is already loaded - skip API calls if already fetched
      final runTypesAlreadyLoaded = runTypeController.runTypes.value != null &&
          (runTypeController.runTypes.value?.runTypes?.isNotEmpty ?? false);
      final paymentModesAlreadyLoaded = paymentModeController.modes.isNotEmpty;
      final genderAlreadyLoaded = controller.genderList.isNotEmpty;
      final carProvidersAlreadyLoaded =
          carProviderController.carProviderList.isNotEmpty;

      // If all data is already loaded, skip API calls
      if (runTypesAlreadyLoaded &&
          paymentModesAlreadyLoaded &&
          genderAlreadyLoaded &&
          carProvidersAlreadyLoaded) {
        debugPrint('✅ All data already loaded, skipping API calls');
        return;
      }

      // 1. Login info should already be loaded from main.dart
      // This is a safety check in case it wasn't loaded yet
      if (loginInfoController.crpLoginInfo.value == null) {
        debugPrint('⚠️ Login info not available, loading from storage...');
        // Wait a bit more to ensure it's fully loaded
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 2. Fetch Run Types only if not already loaded (doesn't depend on token)
      if (!runTypesAlreadyLoaded) {
        runTypeController.fetchRunTypes(params, context);
      }

      // 4. Wait for guestId, token, user
      await fetchParameter();
      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      // 5. Get token - prioritize login info, then storage, then fallback
      String? resolvedToken = loginInfoController.crpLoginInfo.value?.key;
      if (resolvedToken == null || resolvedToken.isEmpty) {
        resolvedToken = token ?? await StorageServices.instance.read('crpKey');
      }

      // 6. Wait a bit more if token is still not available (give storage time to load)
      if (resolvedToken == null || resolvedToken.isEmpty) {
        debugPrint('⚠️ Token not available yet, waiting...');
        int retryCount = 0;
        while ((resolvedToken == null || resolvedToken.isEmpty) &&
            retryCount < 10) {
          await Future.delayed(const Duration(milliseconds: 200));
          resolvedToken = loginInfoController.crpLoginInfo.value?.key ??
              token ??
              await StorageServices.instance.read('crpKey');
          retryCount++;
        }
      }

      final Map<String, dynamic> paymentParams = {
        'GuestID': int.tryParse(guestId ?? '') ?? 0,
        'token': resolvedToken ?? '',
        'user': user ?? email ?? ''
      };

      // 7. Fetch only missing data in parallel (fire-and-forget, but with error handling in controllers)
      // Only fetch if we have a valid token
      if (resolvedToken != null && resolvedToken.isNotEmpty) {
        if (!paymentModesAlreadyLoaded) {
          paymentModeController.fetchPaymentModes(paymentParams, context);
        }
        if (!genderAlreadyLoaded) {
          controller.fetchGender(context);
        }
        if (!carProvidersAlreadyLoaded) {
          carProviderController.fetchCarProviders(context);
        }
      } else {
        debugPrint('❌ Cannot fetch data: Token not available');
        // Retry after a delay only if we need to fetch data
        if (!runTypesAlreadyLoaded ||
            !paymentModesAlreadyLoaded ||
            !genderAlreadyLoaded ||
            !carProvidersAlreadyLoaded) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              runTypesAndPaymentModes();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error in runTypesAndPaymentModes: $e');
      // Retry after a delay if there was an error and we still need data
      final runTypesAlreadyLoaded = runTypeController.runTypes.value != null &&
          (runTypeController.runTypes.value?.runTypes?.isNotEmpty ?? false);
      final paymentModesAlreadyLoaded = paymentModeController.modes.isNotEmpty;
      final genderAlreadyLoaded = controller.genderList.isNotEmpty;
      final carProvidersAlreadyLoaded =
          carProviderController.carProviderList.isNotEmpty;

      if (!runTypesAlreadyLoaded ||
          !paymentModesAlreadyLoaded ||
          !genderAlreadyLoaded ||
          !carProvidersAlreadyLoaded) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            runTypesAndPaymentModes();
          }
        });
      }
    }
  }

  /// Clear pickup and drop locations when navigating from corporate bottom nav
  void _clearPickupAndDropLocations() {
    crpSelectPickupController.clearSelection();
    crpSelectDropController.clearSelection();
  }

  Future<void> _loadPreselectedRunType() async {
    // Skip if pickup type is already passed from navigation
    if (widget.selectedPickupType != null) {
      return;
    }

    // Only load preselected run type if we're not coming back from location selection screens
    // If locations are already selected, we're likely coming back from location screens, so skip preselection
    final hasPickupLocation =
        crpSelectPickupController.selectedPlace.value != null;
    final hasDropLocation = crpSelectDropController.selectedPlace.value != null;

    if (hasPickupLocation || hasDropLocation) {
      // User has already selected locations, likely coming back from location screens
      // Clear any stored preselected run type to prevent applying it
      await StorageServices.instance.delete('cprSelectedRunTypeId');
      return;
    }

    final idStr = await StorageServices.instance.read('cprSelectedRunTypeId');
    if (idStr != null) {
      final parsed = int.tryParse(idStr);
      if (parsed != null) {
        setState(() {
          _preselectedRunTypeId = parsed;
        });
      }
      // Clear it so it doesn't affect future navigations without selection
      await StorageServices.instance.delete('cprSelectedRunTypeId');
    }
  }

  final CrpServicesController runTypeController =
      Get.put(CrpServicesController());
  final CrpSelectPickupController crpSelectPickupController =
      Get.put(CrpSelectPickupController());
  final CrpSelectDropController crpSelectDropController =
      Get.put(CrpSelectDropController());
  final paymentModeController = Get.put(PaymentModeController());

  // Google API Key for reverse geocoding current location
  final String googleApiKey = "AIzaSyCWbmCiquOta1iF6um7_5_NFh6YM5wPL30";

  String? selectedPickupType;
  String? selectedBookingFor;
  String? selectedPaymentMethod;

  final params = {
    'CorpID': StorageServices.instance.read('crpId'),
    'BranchID': StorageServices.instance.read('branchId')
  };

  /// Get the gender ID to use for prefilling:
  /// 1. Prefer value from corporate login (CrpLoginResponse.genderId)
  /// 2. Fallback to stored value from storage
  Future<int> _getPrefillGenderId() async {
    final loginGenderId = loginInfoController.crpLoginInfo.value?.genderId ?? 0;
    if (loginGenderId != 0) {
      debugPrint('✅ Using GenderId from login info: $loginGenderId');
      return loginGenderId;
    }

    // Try to get from storage
    final storedGenderIdStr =
        await StorageServices.instance.read('crpGenderId');
    debugPrint('💾 Stored GenderId from storage: $storedGenderIdStr');
    if (storedGenderIdStr != null && storedGenderIdStr.isNotEmpty) {
      final storedGenderId = int.tryParse(storedGenderIdStr);
      if (storedGenderId != null && storedGenderId != 0) {
        debugPrint('✅ Using stored GenderId: $storedGenderId');
        return storedGenderId;
      }
    }

    debugPrint('⚠️ No GenderId found, returning 0');
    return 0;
  }

  bool get _isAirportRunType {
    final type = selectedPickupType ?? widget.selectedPickupType;
    if (type == null) return false;
    return type.toLowerCase().contains('airport');
  }

  /// Apply all possible prefilled data using values returned by the corporate
  /// login API (`CrpLoginResponse`) once the respective lists are loaded.
  ///
  /// This covers:
  /// - Booking Type (always "Corporate")
  /// - Gender (using `genderId`)
  /// - Corporate Entity (using `entityId`)
  /// - Payment Mode (using `payModeID`)
  /// - Car Provider (using first element from list)
  /// - Pickup DateTime (using `advancedHourToConfirm` as an offset from now)
  Future<void> _applyPrefilledDataFromLogin() async {
    // Check if prefilling has already been completed
    if (_hasAppliedPrefilledData) {
      // Check if all data is already prefilled - if so, skip
      final hasBookingType = selectedBookingFor != null;
      final hasGender = controller.selectedGender.value != null;
      final hasCorporate = selectedCorporate != null;
      final hasPaymentMode = paymentModeController.selectedMode.value != null;
      final hasCarProvider =
          carProviderController.selectedCarProvider.value != null;
      final hasDateTime = selectedPickupDateTime != null;

      if (hasBookingType &&
          hasGender &&
          hasCorporate &&
          hasPaymentMode &&
          hasCarProvider &&
          hasDateTime) {
        debugPrint(
            '✅ All data already prefilled, skipping _applyPrefilledDataFromLogin()');
        return;
      }
    }

    debugPrint('🔄 Starting _applyPrefilledDataFromLogin()');

    // Ensure login info is available (loaded either from API or storage)
    if (loginInfoController.crpLoginInfo.value == null) {
      debugPrint('⚠️ Login info is null, waiting...');
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final loginInfo = loginInfoController.crpLoginInfo.value;
    debugPrint('📋 Login info available: ${loginInfo != null}');
    if (loginInfo != null) {
      debugPrint(
          '📋 EntityId from login: ${loginInfo.entityId}, GenderId from login: ${loginInfo.genderId}');
    }

    // Always set pickup datetime using advancedHourToConfirm from login info
    final int minutesOffset = _getAdvancedHourToConfirm();
    if (selectedPickupDateTime == null) {
      setState(() {
        selectedPickupDateTime =
            DateTime.now().add(Duration(minutes: minutesOffset));
      });
    } else {
      // Ensure existing selection is at least advancedHourToConfirm hours from now
      final DateTime now = DateTime.now();
      final DateTime minDateTime = now.add(Duration(minutes: minutesOffset));
      if (selectedPickupDateTime!.isBefore(minDateTime)) {
        setState(() {
          selectedPickupDateTime = minDateTime;
        });
      }
    }

    // Don't return early - we can still use stored values even if loginInfo is null

    // Wait briefly for dependent API lists to load so we can match IDs safely.
    // We poll a few times instead of blocking indefinitely.
    const int maxAttempts =
        50; // ~5 seconds at 100ms interval (increased for app restart scenario)
    for (int i = 0; i < maxAttempts; i++) {
      final bool gendersReady = controller.genderList.isNotEmpty;
      final bool paymentModesReady = paymentModeController.modes.isNotEmpty;
      final bool entitiesReady =
          (crpGetEntityListController.getAllEntityList.value?.getEntityList ??
                  [])
              .isNotEmpty;
      final bool carProvidersReady =
          carProviderController.carProviderList.isNotEmpty ||
              !carProviderController.isLoading.value;

      debugPrint(
          '📊 Lists status - Genders: $gendersReady (${controller.genderList.length}), '
          'PaymentModes: $paymentModesReady (${paymentModeController.modes.length}), '
          'Entities: $entitiesReady, CarProviders: $carProvidersReady (${carProviderController.carProviderList.length})');

      if (gendersReady &&
          paymentModesReady &&
          entitiesReady &&
          carProvidersReady) {
        debugPrint('✅ All lists are ready!');
        break;
      }

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!mounted) return;

    // Handle corporate entity prefilling with storage fallback (before setState)
    int targetEntityId = loginInfo?.entityId ?? 0;
    debugPrint('🔍 Initial targetEntityId: $targetEntityId');
    if (targetEntityId == 0) {
      final storedEntityIdStr =
          await StorageServices.instance.read('crpEntityId');
      debugPrint('💾 Stored EntityId from storage: $storedEntityIdStr');
      if (storedEntityIdStr != null && storedEntityIdStr.isNotEmpty) {
        targetEntityId = int.tryParse(storedEntityIdStr) ?? 0;
        debugPrint('✅ Using stored EntityId: $targetEntityId');
      }
    }

    // Get gender ID for prefilling
    final int targetGenderId = await _getPrefillGenderId();
    debugPrint('🔍 Target GenderId: $targetGenderId');

    if (!mounted) return;

    // Fetch payment modes if null and list is empty
    if (paymentModeController.selectedMode.value == null &&
        paymentModeController.modes.isEmpty &&
        !paymentModeController.isLoading.value) {
      debugPrint(
          '🔄 Payment mode is null and list is empty, fetching payment modes...');

      // Get required parameters for fetching payment modes
      await fetchParameter();
      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      // Get token - prioritize login info, then storage, then fallback
      String? resolvedToken = loginInfoController.crpLoginInfo.value?.key;
      if (resolvedToken == null || resolvedToken.isEmpty) {
        resolvedToken = token ?? await StorageServices.instance.read('crpKey');
      }

      if (resolvedToken != null && resolvedToken.isNotEmpty) {
        final Map<String, dynamic> paymentParams = {
          'GuestID': int.tryParse(guestId ?? '') ?? 0,
          'token': resolvedToken ?? '',
          'user': user ?? email ?? ''
        };

        // Fetch payment modes and wait for completion
        await paymentModeController.fetchPaymentModes(paymentParams, context);

        // Wait a bit for the list to populate
        int retryCount = 0;
        while (paymentModeController.modes.isEmpty && retryCount < 20) {
          await Future.delayed(const Duration(milliseconds: 100));
          retryCount++;
        }

        debugPrint(
            '✅ Payment modes fetched. List size: ${paymentModeController.modes.length}');
      } else {
        debugPrint('⚠️ Cannot fetch payment modes: Token not available');
      }
    }

    setState(() {
      // Booking Type – default to "Corporate" if nothing is selected (first element)
      if (selectedBookingFor == null && bookingForList.isNotEmpty) {
        selectedBookingFor = bookingForList.first;
        debugPrint('✅ Prefilled Booking Type: $selectedBookingFor');
      }

      // Gender – match using GenderID from login info or storage (prefill from storage/API)
      if (controller.selectedGender.value == null &&
          controller.genderList.isNotEmpty) {
        debugPrint(
            '🔍 Attempting to prefill Gender. Target ID: $targetGenderId, List size: ${controller.genderList.length}');
        debugPrint(
            '🔍 Gender list IDs: ${controller.genderList.map((g) => g.genderID).toList()}');
        if (targetGenderId != 0) {
          GenderModel? matchedGender;
          for (final gender in controller.genderList) {
            final genderId = gender.genderID;
            debugPrint(
                '  - Checking gender ID: $genderId (type: ${genderId.runtimeType}) vs target: $targetGenderId (type: ${targetGenderId.runtimeType})');
            if (genderId != null && genderId == targetGenderId) {
              matchedGender = gender;
              debugPrint('✅ Found matching gender: ${gender.gender}');
              break;
            }
          }
          if (matchedGender != null) {
            controller.selectGender(matchedGender);
            debugPrint('✅ Prefilled Gender: ${matchedGender.gender}');
            // Force UI update by accessing the value
            final _ = controller.selectedGender.value;
          } else {
            debugPrint('❌ No matching gender found for ID: $targetGenderId');
            debugPrint(
                '❌ Available gender IDs: ${controller.genderList.map((g) => g.genderID).toList()}');
          }
        } else {
          debugPrint('⚠️ Target GenderId is 0, skipping prefilling');
        }
      } else {
        debugPrint(
            '⚠️ Gender already selected or list empty. Selected: ${controller.selectedGender.value?.gender}, List empty: ${controller.genderList.isEmpty}');
      }

      // Corporate Entity – match using EntityId from login info or storage, else fallback to first
      if (selectedCorporate == null) {
        final entities =
            crpGetEntityListController.getAllEntityList.value?.getEntityList ??
                [];
        debugPrint(
            '🔍 Attempting to prefill Corporate Entity. Target ID: $targetEntityId, List size: ${entities.length}');
        if (entities.isNotEmpty) {
          Entity? matched;
          if (targetEntityId != 0) {
            for (final entity in entities) {
              debugPrint('  - Checking entity ID: ${entity.entityId}');
              if (entity.entityId == targetEntityId) {
                matched = entity;
                debugPrint('✅ Found matching entity: ${entity.entityName}');
                break;
              }
            }
          }
          selectedCorporate = matched ?? entities.first;
          debugPrint(
              '✅ Prefilled Corporate Entity: ${selectedCorporate?.entityName} (matched: ${matched != null})');
        } else {
          debugPrint('⚠️ Entities list is empty');
        }
      } else {
        debugPrint(
            '⚠️ Corporate Entity already selected: ${selectedCorporate?.entityName}');
      }

      // Payment Mode – match using PayModeID from login info, or prefill first if null
      if (paymentModeController.modes.isNotEmpty) {
        final String payModeIdStr = loginInfo?.payModeID ?? '';
        final int? payModeId = int.tryParse(payModeIdStr);

        PaymentModeItem? matchedMode;
        if (payModeId != null) {
          for (final mode in paymentModeController.modes) {
            if (mode.id == payModeId) {
              matchedMode = mode;
              break;
            }
          }
        }

        // If nothing matched, keep current selection or fall back to first item
        paymentModeController.updateSelected(
          matchedMode ??
              paymentModeController.selectedMode.value ??
              (paymentModeController.modes.isNotEmpty
                  ? paymentModeController.modes.first
                  : null),
        );

        if (paymentModeController.selectedMode.value != null) {
          debugPrint(
              '✅ Prefilled Payment Mode: ${paymentModeController.selectedMode.value?.mode}');
        }
      } else if (paymentModeController.selectedMode.value == null) {
        debugPrint('⚠️ Payment modes list is empty and no selection available');
      }

      // Car Provider – use first element from the list (as per requirement)
      if (carProviderController.carProviderList.isNotEmpty &&
          carProviderController.selectedCarProvider.value == null) {
        // Use first element from the list
        carProviderController
            .selectCarProvider(carProviderController.carProviderList.first);
        debugPrint(
            '✅ Prefilled Car Provider: ${carProviderController.carProviderList.first.providerName}');
      } else {
        debugPrint(
            '⚠️ Car Provider already selected or list empty. Selected: ${carProviderController.selectedCarProvider.value?.providerName}, List empty: ${carProviderController.carProviderList.isEmpty}');
      }

      // Pickup DateTime is already set above (before checking loginInfo)
      // This ensures it's always at least advancedHourToConfirm hours from now
    });

    // Mark prefilling as completed
    _hasAppliedPrefilledData = true;
    debugPrint('✅ Finished _applyPrefilledDataFromLogin()');
  }

  /// Try to prefill corporate entity from login info or storage
  void _tryPrefillCorporateEntity(List<Entity> entities) {
    if (selectedCorporate != null || entities.isEmpty) return;

    int targetEntityId = 0;

    // Try login info first
    if (loginInfoController.crpLoginInfo.value != null) {
      targetEntityId = loginInfoController.crpLoginInfo.value!.entityId;
    }

    // Fallback to storage
    if (targetEntityId == 0) {
      StorageServices.instance.read('crpEntityId').then((storedEntityIdStr) {
        if (storedEntityIdStr != null && storedEntityIdStr.isNotEmpty) {
          final storedEntityId = int.tryParse(storedEntityIdStr);
          if (storedEntityId != null && storedEntityId != 0 && mounted) {
            setState(() {
              for (final entity in entities) {
                if (entity.entityId == storedEntityId) {
                  selectedCorporate = entity;
                  debugPrint(
                      '✅ Prefilled Corporate Entity from storage: ${entity.entityName}');
                  return;
                }
              }
            });
          }
        }
      });
      return;
    }

    // Match from login info
    if (targetEntityId != 0 && mounted) {
      setState(() {
        for (final entity in entities) {
          if (entity.entityId == targetEntityId) {
            selectedCorporate = entity;
            debugPrint(
                '✅ Prefilled Corporate Entity from login: ${entity.entityName}');
            return;
          }
        }
      });
    }
  }

  /// Load current location from storage (saved at app start in main.dart).
  /// Optimized for speed - reads all data in parallel and validates quickly.
  /// Returns a SuggestionPlacesResponse if all required data is available, null otherwise.
  Future<SuggestionPlacesResponse?> _loadCurrentLocationFromStorage() async {
    try {
      final storage = StorageServices.instance;

      // Read all stored location data in parallel for maximum speed
      final results = await Future.wait([
        storage.read('sourceTitle'),
        storage.read('sourceLat'),
        storage.read('sourceLng'),
        storage.read('sourcePlaceId'),
        storage.read('sourceCity'),
        storage.read('sourceState'),
        storage.read('sourceCountry'),
        storage.read('sourceTypes'),
        storage.read('sourceTerms'),
      ]);

      final sourceTitle = results[0] as String?;
      final sourceLatStr = results[1] as String?;
      final sourceLngStr = results[2] as String?;
      final sourcePlaceId = (results[3] as String?) ?? '';
      final sourceCity = (results[4] as String?) ?? '';
      final sourceState = (results[5] as String?) ?? '';
      final sourceCountry = (results[6] as String?) ?? '';
      final sourceTypesStr = results[7] as String?;
      final sourceTermsStr = results[8] as String?;

      // Quick validation of essential fields (title, lat, lng are required)
      if (sourceTitle == null ||
          sourceTitle.isEmpty ||
          sourceLatStr == null ||
          sourceLatStr.isEmpty ||
          sourceLngStr == null ||
          sourceLngStr.isEmpty) {
        return null; // Don't log in normal case - storage might not be ready yet
      }

      final lat = double.tryParse(sourceLatStr);
      final lng = double.tryParse(sourceLngStr);

      if (lat == null || lng == null) {
        return null;
      }

      // Parse types from JSON string (optional field, don't block on errors)
      List<String> types = [];
      if (sourceTypesStr != null && sourceTypesStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(sourceTypesStr) as List;
          types = decoded.map((e) => e.toString()).toList();
        } catch (_) {
          // Ignore parse errors for optional fields
        }
      }

      // Parse terms from JSON string (optional field, don't block on errors)
      List<Term> terms = [];
      if (sourceTermsStr != null && sourceTermsStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(sourceTermsStr) as List;
          terms = decoded
              .map((e) => Term.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          // Ignore parse errors for optional fields
        }
      }

      // Build secondary text from city, state, country if available
      String secondaryText = '';
      final locationParts = <String>[
        if (sourceCity.isNotEmpty) sourceCity,
        if (sourceState.isNotEmpty) sourceState,
        if (sourceCountry.isNotEmpty) sourceCountry,
      ];
      if (locationParts.isNotEmpty) {
        secondaryText = locationParts.join(', ');
      }

      // Build place name (use full address if available, otherwise use title)
      String placeName = sourceTitle;
      if (secondaryText.isNotEmpty) {
        placeName = '$sourceTitle, $secondaryText';
      }

      final storedPlace = SuggestionPlacesResponse(
        primaryText: sourceTitle,
        secondaryText: secondaryText,
        placeId: sourcePlaceId,
        types: types,
        terms: terms,
        city: sourceCity,
        state: sourceState,
        country: sourceCountry,
        isAirport: false,
        latitude: lat,
        longitude: lng,
        placeName: placeName,
      );

      return storedPlace;
    } catch (e) {
      // Silently fail - storage might not be ready or location not saved yet
      return null;
    }
  }

  /// Prefill pickup with current location (name + lat/lng) if available.
  /// Uses the same stored values as the personal cab flow (saved at app start in main.dart).
  /// Optimized for immediate display - only uses storage (no GPS fetch to avoid delay).
  Future<void> _prefillPickupFromCurrentLocation() async {
    try {
      // Don't override if user has already selected a pickup location
      if (crpSelectPickupController.selectedPlace.value != null) {
        debugPrint('📍 Pickup location already selected, skipping prefilling');
        if (mounted) {
          setState(() {
            _isLoadingPickupLocation = false;
          });
        }
        return;
      }

      // Don't override if pickup place was passed from navigation
      if (widget.selectedPickupPlace != null) {
        debugPrint(
            '📍 Pickup place passed from navigation, skipping prefilling');
        if (mounted) {
          setState(() {
            _isLoadingPickupLocation = false;
          });
        }
        return;
      }

      // Try to load from storage first (fast, no GPS fetch needed)
      // This is the main path - should be instant since data is already in storage
      final storedPlace = await _loadCurrentLocationFromStorage();

      if (storedPlace != null && mounted) {
        // Use stored location data - this should be instant
        crpSelectPickupController.selectedPlace.value = storedPlace;
        crpSelectPickupController.searchController.text =
            storedPlace.primaryText;
        debugPrint(
            '✅ Prefilled pickup from stored location: ${storedPlace.primaryText}');

        // Stop loading and trigger UI update
        if (mounted) {
          setState(() {
            _isLoadingPickupLocation = false;
          });
        }
        return;
      }

      // Only fetch GPS in background if absolutely necessary (should rarely happen)
      // Don't await this - let it happen in background so UI doesn't wait
      debugPrint('⚠️ No stored location found, will fetch GPS in background');
      _setPickupFromCurrentGps().then((_) {
        if (mounted) {
          setState(() {
            _isLoadingPickupLocation = false;
          });
        }
      }).catchError((e) {
        debugPrint('❌ GPS fetch failed: $e');
        if (mounted) {
          setState(() {
            _isLoadingPickupLocation = false;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Error in _prefillPickupFromCurrentLocation: $e');
      // Stop loading even on error
      if (mounted) {
        setState(() {
          _isLoadingPickupLocation = false;
        });
      }
    }
  }

  /// Fallback: fetch device's current GPS location, reverse geocode it,
  /// and use that address as pickup. Saves to storage so other screens
  /// (map, search) also see the same current-location address.
  Future<void> _setPickupFromCurrentGps() async {
    try {
      final loc = location.Location();

      if (!(await loc.serviceEnabled()) && !(await loc.requestService())) {
        return;
      }

      var permission = await loc.hasPermission();
      if (permission == location.PermissionStatus.denied) {
        permission = await loc.requestPermission();
        if (permission != location.PermissionStatus.granted) {
          return;
        }
      }

      final locData = await loc.getLocation();
      if (locData.latitude == null || locData.longitude == null) {
        return;
      }

      final lat = locData.latitude!;
      final lng = locData.longitude!;

      // Reverse geocode to get a human-readable address
      String addressTitle = 'Current location';
      String fullAddress = '';
      try {
        final url =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final results = jsonData["results"] as List;
          if (results.isNotEmpty) {
            fullAddress = results[0]["formatted_address"] ?? '';
            if (fullAddress.isNotEmpty) {
              addressTitle = fullAddress.split(',').first.trim();
            }
          }
        }
      } catch (_) {
        // If reverse geocoding fails, we still fall back to generic "Current location"
      }

      final place = SuggestionPlacesResponse(
        primaryText: addressTitle,
        secondaryText: fullAddress,
        placeId: '',
        types: const [],
        terms: const [],
        city: '',
        state: '',
        country: '',
        isAirport: false,
        latitude: lat,
        longitude: lng,
        placeName: fullAddress.isNotEmpty ? fullAddress : addressTitle,
      );

      crpSelectPickupController.selectedPlace.value = place;
      crpSelectPickupController.searchController.text = addressTitle;

      final storage = StorageServices.instance;
      await Future.wait([
        storage.save('sourceTitle', addressTitle),
        storage.save('sourceLat', lat.toString()),
        storage.save('sourceLng', lng.toString()),
      ]);

      // Stop loading when GPS fetch completes
      if (mounted) {
        setState(() {
          _isLoadingPickupLocation = false;
        });
      }
    } catch (_) {
      // Stop loading even on error
      if (mounted) {
        setState(() {
          _isLoadingPickupLocation = false;
        });
      }
    }
  }

  DateTime? selectedPickupDateTime;
  DateTime? selectedDropDateTime;

  bool isBookingForExpanded = false;
  bool isPaymentMethodsExpanded = false;
  bool isAdditionalOptionsExpanded = false;

  // Error states for validation
  String? pickupLocationError;
  String? dropLocationError;
  String? pickupDateError;
  String? dropDateError;
  String? pickupTypeError;
  String? bookingTypeError;
  String? paymentModeError;
  String? genderError;
  String? carProviderError;
  String? corporateError;

  final TextEditingController referenceNumberController =
      TextEditingController();
  final TextEditingController specialInstructionController =
      TextEditingController();
  final TextEditingController costCodeController = TextEditingController();
  final TextEditingController flightDetailsController = TextEditingController();

  final List<String> bookingForList = ['Corporate'];
  // final TextEditingController pickupController = TextEditingController();
  // final TextEditingController dropController = TextEditingController();

  /// Get the minimum minutes offset for pickup datetime from login info
  /// Falls back to 0 if not available or if value is 0
  /// Adds 15 minutes to the configured hours
  int _getAdvancedHourToConfirm() {
    final loginInfo = loginInfoController.crpLoginInfo.value;
    final hours = loginInfo?.advancedHourToConfirm ?? 0;
    // Convert hours to minutes and add 15 minutes
    return (hours > 0 ? hours : 0) * 60 + 15;
  }

  /// Safely check if pickup and drop refer to the same location.
  /// Handles cases where placeId may be empty (typed or map-selected locations).
  bool _arePickupAndDropSame(
      SuggestionPlacesResponse pickup, SuggestionPlacesResponse drop) {
    // If both have coordinates, compare lat/lng
    if (pickup.latitude != null &&
        pickup.longitude != null &&
        drop.latitude != null &&
        drop.longitude != null) {
      final latDiff = (pickup.latitude! - drop.latitude!).abs();
      final lngDiff = (pickup.longitude! - drop.longitude!).abs();
      // Treat as same if extremely close (within ~1e-4 degrees)
      if (latDiff < 0.0001 && lngDiff < 0.0001) {
        return true;
      }
    }

    // If both have non-empty placeId, fall back to ID comparison
    if ((pickup.placeId ?? '').isNotEmpty &&
        (drop.placeId ?? '').isNotEmpty &&
        pickup.placeId == drop.placeId) {
      return true;
    }

    // As a last resort, compare normalized primaryText
    final pickupText = (pickup.primaryText ?? '').trim().toLowerCase();
    final dropText = (drop.primaryText ?? '').trim().toLowerCase();

    if (pickupText.isNotEmpty &&
        dropText.isNotEmpty &&
        pickupText == dropText) {
      return true;
    }

    return false;
  }

  CarProviderModel? _getValidCarProviderValue(
    CarProviderModel? selectedValue,
    List<CarProviderModel> list,
  ) {
    if (selectedValue == null) return null;

    // Check if the selected value exists in the list
    final exists = list.any((item) => item == selectedValue);
    return exists ? selectedValue : null;
  }

  GenderModel? _getValidGenderValue(
    GenderModel? selectedValue,
    List<GenderModel> list,
  ) {
    if (selectedValue == null) return null;

    // Check if the selected value exists in the list
    final exists = list.any((item) => item == selectedValue);
    return exists ? selectedValue : null;
  }

  @override
  void dispose() {
    // Note: crpSelectPickupController.searchController and crpSelectDropController.searchController
    // are managed by their respective GetX controllers and will be disposed in onClose()
    _scrollController.dispose();
    referenceNumberController.dispose();
    specialInstructionController.dispose();
    costCodeController.dispose();
    flightDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When coming from home screen (selectedPickupType is passed), always show loading
    // until location is prefilled. Don't check for existing location in this case.
    // Only check for existing location if NOT coming from home screen.
    if (_isLoadingPickupLocation && widget.selectedPickupType == null) {
      // Not coming from home screen - check if location is already available
      if (crpSelectPickupController.selectedPlace.value != null ||
          widget.selectedPickupPlace != null) {
        // Location is already available, stop loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isLoadingPickupLocation = false;
            });
          }
        });
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          context.push(AppRoutes.cprBottomNav);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.05),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => context.push(AppRoutes.cprBottomNav),
          ),
          title: const Text(
            'Booking',
            style: TextStyle(
              color: Color(0xFF000000),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              // letterSpacing: -0.5,
            ),
          ),
          centerTitle: false,
        ),
        body: _isLoadingPickupLocation
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.mainButtonBg),
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                    // Scrollable content
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        thickness: 8,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 14, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Location Input Section
                              Obx(() => _buildPickUpTypeSection()),
                              const SizedBox(height: 20),

                              _buildLocationSection(),
                              const SizedBox(height: 24),
                              // Pick Up Date and Drop Date Buttons
                              _buildDateButtons(),
                              // Pick Up Type Button (always shown, replaces tabs)
                              const SizedBox(height: 20),
                              // Booking For
                              _buildSectionLabel('Booking Type *'),
                              const SizedBox(height: 10),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => bookingTypeError = null);
                                        _showBookingTypeBottomSheet();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(37),
                                          border: Border.all(
                                            color: bookingTypeError != null
                                                ? Colors.red.shade400
                                                : const Color(0xFFE2E2E2),
                                            width: bookingTypeError != null
                                                ? 1.5
                                                : 1,
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 24,
                                                width: 24,
                                                padding:
                                                    const EdgeInsets.all(1.5),
                                                decoration: BoxDecoration(),
                                                child: SvgPicture.asset(
                                                  'assets/images/booking_type.svg',
                                                  width: 20,
                                                  height: 20,
                                                  color:
                                                      const Color(0xFF52A6F9),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  selectedBookingFor ??
                                                      'Select Booking Type',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xFF333333),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              const Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color: Color(0xFF111111),
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (bookingTypeError != null) ...[
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                size: 16,
                                                color: Colors.red.shade600),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                bookingTypeError!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]
                                  ]),

                              const SizedBox(height: 12),
                              // Choose Corporate (mandatory)
                              Obx(() {
                                final entities = crpGetEntityListController
                                        .getAllEntityList
                                        .value
                                        ?.getEntityList ??
                                    [];

                                // Try to prefill from storage if not already set (only in build, don't modify state here)
                                // The actual prefilling is handled in _applyPrefilledDataFromLogin()
                                if (selectedCorporate == null &&
                                    entities.isNotEmpty) {
                                  // Schedule prefilling outside build method
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _tryPrefillCorporateEntity(entities);
                                  });
                                }

                                if (entities.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final hasError = corporateError != null &&
                                    corporateError!.isNotEmpty;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionLabel('Choose Corporate *'),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => corporateError = null);
                                        showModalBottomSheet<Entity>(
                                          context: context,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(20)),
                                          ),
                                          builder: (ctx) {
                                            return SafeArea(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 16),
                                                    child: Text(
                                                      selectedCorporate
                                                              ?.entityName ??
                                                          'Choose Corporate',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(height: 1),
                                                  Flexible(
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      itemCount:
                                                          entities.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        final item =
                                                            entities[index];
                                                        final isSelected =
                                                            selectedCorporate
                                                                    ?.entityId ==
                                                                item.entityId;
                                                        return ListTile(
                                                          title: Text(
                                                              item.entityName ??
                                                                  ''),
                                                          trailing: isSelected
                                                              ? const Icon(
                                                                  Icons.check,
                                                                  color: AppColors
                                                                      .mainButtonBg)
                                                              : null,
                                                          onTap: () {
                                                            setState(() {
                                                              corporateError =
                                                                  null;
                                                              selectedCorporate =
                                                                  item;
                                                            });
                                                            Navigator.of(ctx)
                                                                .pop();
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(37),
                                          border: Border.all(
                                            color: hasError
                                                ? Colors.red.shade400
                                                : const Color(0xFFE2E2E2),
                                            width: hasError ? 1.5 : 1,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 24,
                                              width: 24,
                                              padding:
                                                  const EdgeInsets.all(1.5),
                                              decoration: const BoxDecoration(),
                                              child: SvgPicture.asset(
                                                'assets/images/booking_type.svg',
                                                width: 20,
                                                height: 20,
                                                color: const Color(0xFF52A6F9),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                selectedCorporate?.entityName ??
                                                    'Select Corporate',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: hasError
                                                      ? Colors.red.shade700
                                                      : const Color(0xFF333333),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: hasError
                                                  ? Colors.red.shade400
                                                  : const Color(0xFF6B7280),
                                              size: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (corporateError != null) ...[
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                size: 16,
                                                color: Colors.red.shade600),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                corporateError!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              }),
                              const SizedBox(height: 12),
                              // Payment Controller
                              Obx(() {
                                if (paymentModeController.isLoading.value) {
                                  return Container(
                                    padding: const EdgeInsets.all(24),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.mainButtonBg),
                                      ),
                                    ),
                                  );
                                }

                                final list = paymentModeController.modes;

                                // if (list.isEmpty) {
                                //   return Container(
                                //     padding: const EdgeInsets.all(16),
                                //     decoration: BoxDecoration(
                                //       color: Colors.orange.shade50,
                                //       borderRadius: BorderRadius.circular(12),
                                //       border: Border.all(color: Colors.orange.shade200),
                                //     ),
                                //     child: Row(
                                //       children: [
                                //         Icon(Icons.info_outline,
                                //             color: Colors.orange.shade700, size: 20),
                                //         const SizedBox(width: 12),
                                //         Expanded(
                                //           child: Text(
                                //             "No Payment Modes Found",
                                //             style: TextStyle(
                                //               fontSize: 14,
                                //               color: Colors.orange.shade700,
                                //               fontWeight: FontWeight.w500,
                                //             ),
                                //           ),
                                //         ),
                                //       ],
                                //     ),
                                //   );
                                // }
                                if (list.isEmpty) {
                                  return SizedBox();
                                }

                                final hasError = paymentModeError != null &&
                                    paymentModeError!.isNotEmpty;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionLabel('Payment Mode *'),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => paymentModeError = null);
                                        _showPaymentModeBottomSheet();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(37),
                                          border: Border.all(
                                            color: hasError
                                                ? Colors.red.shade400
                                                : const Color(0xFFE2E2E2),
                                            width: hasError ? 1.5 : 1,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 24,
                                              width: 24,
                                              padding:
                                                  const EdgeInsets.all(1.5),
                                              decoration: BoxDecoration(),
                                              child: SvgPicture.asset(
                                                'assets/images/payment_mode.svg',
                                                width: 20,
                                                height: 20,
                                                // color: const Color(0xFF52A6F9),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                paymentModeController
                                                        .selectedMode
                                                        .value
                                                        ?.mode ??
                                                    'Select Payment Mode',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: hasError
                                                      ? Colors.red.shade700
                                                      : const Color(0xFF333333),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: hasError
                                                  ? Colors.red.shade400
                                                  : const Color(0xFF6B7280),
                                              size: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (paymentModeError != null) ...[
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                size: 16,
                                                color: Colors.red.shade600),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                paymentModeError!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              }),
                              const SizedBox(height: 12),

                              // Gender
                              // Gender
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionLabel('Gender *'),
                                  const SizedBox(height: 10),
                                  Obx(() {
                                    final hasError = genderError != null &&
                                        genderError!.isNotEmpty;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() => genderError = null);
                                        _showGenderBottomSheet();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color: hasError
                                                ? Colors.red.shade400
                                                : const Color(0xFFE2E2E2),
                                            width: hasError ? 1.5 : 1,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 24,
                                              width: 24,
                                              padding:
                                                  const EdgeInsets.all(1.5),
                                              decoration: BoxDecoration(),
                                              child: Icon(
                                                Icons.person_outline_outlined,
                                                size: 20,
                                                color: Color(0xFF96C4FA),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                controller.selectedGender.value
                                                        ?.gender ??
                                                    'Select Gender',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: hasError
                                                      ? Colors.red.shade700
                                                      : const Color(0xFF333333),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: hasError
                                                  ? Colors.red.shade400
                                                  : const Color(0xFF6B7280),
                                              size: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  if (genderError != null) ...[
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              size: 16,
                                              color: Colors.red.shade600),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              genderError!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Car Provider
                              Obx(() {
                                if (carProviderController.isLoading.value) {
                                  return Container(
                                    padding: const EdgeInsets.all(24),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.mainButtonBg),
                                      ),
                                    ),
                                  );
                                }

                                final list =
                                    carProviderController.carProviderList;

                                if (list.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final hasError = carProviderError != null &&
                                    carProviderError!.isNotEmpty;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionLabel('Car Provider *'),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => carProviderError = null);
                                        _showCarProviderBottomSheet();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color: hasError
                                                ? Colors.red.shade400
                                                : const Color(0xFFE2E2E2),
                                            width: hasError ? 1.5 : 1,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(),
                                              child: Icon(
                                                Icons
                                                    .directions_car_filled_outlined,
                                                color: hasError
                                                    ? Colors.red.shade600
                                                    : Color(0xFF96C4FA),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                carProviderController
                                                        .selectedCarProvider
                                                        .value
                                                        ?.providerName ??
                                                    'Select Car Provider',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: hasError
                                                      ? Colors.red.shade700
                                                      : const Color(0xFF333333),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: hasError
                                                  ? Colors.red.shade400
                                                  : const Color(0xFF6B7280),
                                              size: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (carProviderError != null) ...[
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                size: 16,
                                                color: Colors.red.shade600),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                carProviderError!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              }),

                              const SizedBox(height: 20),
                              Divider(
                                height: 1,
                                color: Color(0xFFE6E6E6),
                              ),
                              const SizedBox(height: 20),

                              // Additional Options
                              _buildAdditionalOptionsAccordion(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Fixed bottom button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: _buildViewCabsButton(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPickUpTypeSection() {
    final List<RunTypeItem> allRunTypes =
        runTypeController.runTypes.value?.runTypes ?? [];

    // Apply preselected run type (from home screen tap) once when data is available
    // Only apply if:
    // 1. We haven't applied it yet
    // 2. There's a preselected ID
    // 3. Run types are loaded
    // 4. User hasn't already selected a pickup type (to avoid overriding when coming back from location screens)
    if (!_hasAppliedPreselection &&
        _preselectedRunTypeId != null &&
        allRunTypes.isNotEmpty &&
        selectedPickupType == null) {
      final index =
          allRunTypes.indexWhere((rt) => rt.runTypeID == _preselectedRunTypeId);
      if (index != -1) {
        selectedPickupType = allRunTypes[index].run;
      }
      _hasAppliedPreselection = true;
    }

    // Show loading or empty state if no run types
    if (runTypeController.isLoading.value) {
      return Container(
        // padding: const EdgeInsets.symmetric(vertical: 20),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainButtonBg),
          ),
        ),
      );
    }

    if (allRunTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    // If no pickup type is selected yet, default to the first run type.
    // This applies only after run types are loaded and no preselection was applied.
    if (selectedPickupType == null) {
      selectedPickupType = allRunTypes.first.run;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const SizedBox(height: 20),
        // _buildSectionLabel('Pick Up Type'),
        // const SizedBox(height: 10),
        _buildPickUpTypeButton(),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF), // Background light blue as image
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 1), // x: 0px, y: 1px
            blurRadius: 3, // blur: 3px
            spreadRadius: 0, // spread: 0px
            color: Color(0x40000000), // #00000040 → 25% opacity black
          ),
        ],
        border: Border.all(
          color: pickupLocationError != null || dropLocationError != null
              ? Colors.red.shade300
              : const Color(0xFFFFFFFF),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: vertical blue icon line
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 28,
              child: Column(
                children: [
                  // Circle with dot (pickup icon)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA4FF59),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  // Vertical line
                  SizedBox(
                    width: 2,
                    height: 24,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (_) => Container(
                          width: 2,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7B7B7B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Square end (drop icon)
                  Container(
                    width: 15,
                    height: 15,
                    padding: EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB179),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Center: locations fields/text, expanded
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup location (filled text style)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pickupLocationError = null;
                    });
                    GoRouter.of(context).push(
                      AppRoutes.cprPickupSearch,
                      extra: {
                        'selectedPickupType': selectedPickupType,
                      },
                    );
                  },
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Obx(() {
                      final pickupPlace =
                          crpSelectPickupController.selectedPlace.value;
                      String displayText;
                      bool hasText;

                      if (pickupPlace != null &&
                          pickupPlace.primaryText != null &&
                          pickupPlace.primaryText!.isNotEmpty) {
                        final secondaryText = pickupPlace.secondaryText ?? '';
                        displayText = secondaryText.isNotEmpty
                            ? '${pickupPlace.primaryText}, $secondaryText'
                            : pickupPlace.primaryText!;
                        hasText = true;
                      } else {
                        displayText = 'Enter Pickup Location';
                        hasText = false;
                      }

                      return Text(
                        displayText,
                        style: TextStyle(
                          fontWeight:
                              hasText ? FontWeight.w600 : FontWeight.w500,
                          color: hasText
                              ? const Color(0xFF4F4F4F)
                              : Color(0xFFB2B2B2),
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      );
                    }),
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                // Drop location (placeholder style unless selected)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      dropLocationError = null;
                    });
                    GoRouter.of(context).push(
                      AppRoutes.cprDropSearch,
                      extra: {
                        'fromCrpHomeScreen': false,
                      },
                    );
                  },
                  child: Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 2),
                    child: Obx(() {
                      final dropPlace =
                          crpSelectDropController.selectedPlace.value;
                      String displayText;
                      bool hasText;

                      if (dropPlace != null &&
                          dropPlace.primaryText != null &&
                          dropPlace.primaryText!.isNotEmpty) {
                        final secondaryText = dropPlace.secondaryText ?? '';
                        displayText = secondaryText.isNotEmpty
                            ? '${dropPlace.primaryText}, $secondaryText'
                            : dropPlace.primaryText!;
                        hasText = true;
                      } else {
                        displayText = 'Enter drop location (optional)';
                        hasText = false;
                      }

                      return Text(
                        displayText,
                        style: TextStyle(
                          fontWeight:
                              hasText ? FontWeight.w600 : FontWeight.w500,
                          color: hasText
                              ? const Color(0xFF4F4F4F)
                              : Color(0xFFB2B2B2),
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: pickupDateError != null || dropDateError != null
                  ? Colors.red.shade400
                  : Color(0xFFE2E2E2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Pick Up Date Section
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      pickupDateError = null;
                    });
                    _showCupertinoDateTimePicker(context, isPickup: true);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Light blue header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Choose Pickup Date',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: pickupDateError != null
                                ? Colors.red.shade600
                                : const Color(0xFF585858),
                          ),
                        ),
                      ),
                      // White body with date and time
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Calendar icon with clock overlay
                            Stack(
                              children: [
                                Image.asset(
                                  'assets/images/datetimeIcon.png',
                                  height: 24,
                                  width: 24,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.grey.shade600,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Date and time text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedPickupDateTime != null
                                        ? _formatDate(selectedPickupDateTime!)
                                        : 'Select Date',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: pickupDateError != null
                                          ? Colors.red.shade600
                                          : const Color(0xFF585858),
                                    ),
                                  ),
                                  Text(
                                    selectedPickupDateTime != null
                                        ? _formatTime(selectedPickupDateTime!)
                                        : 'Select Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: pickupDateError != null
                                          ? Colors.red.shade400
                                          : Color(0xFFA5A5A5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Vertical divider
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey.shade300,
                ),
              ),
              // Drop Date Section
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      dropDateError = null;
                    });
                    _showCupertinoDateTimePicker(context, isPickup: false);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Light blue header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Choose Drop Date',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: pickupDateError != null
                                ? Colors.red.shade600
                                : const Color(0xFF585858),
                          ),
                        ),
                      ),
                      // White body with date and time
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Calendar icon with clock overlay
                            Stack(
                              children: [
                                Image.asset(
                                  'assets/images/datetimeIcon.png',
                                  height: 24,
                                  width: 24,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.grey.shade600,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Date and time text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedDropDateTime != null
                                        ? _formatDate(selectedDropDateTime!)
                                        : 'Select Date',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: dropDateError != null
                                          ? Colors.red.shade600
                                          : const Color(0xFF585858),
                                    ),
                                  ),
                                  Text(
                                    selectedDropDateTime != null
                                        ? _formatTime(selectedDropDateTime!)
                                        : 'Select Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: dropDateError != null
                                          ? Colors.red.shade400
                                          : Color(0xFFA5A5A5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Pickup error message
        if (pickupDateError != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pickupDateError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Drop error message
        if (dropDateError != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dropDateError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.3,
      ),
    );
  }

  void _showBookingTypeBottomSheet() {
    showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  'Select Booking Type',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...bookingForList.map(
                (bookingFor) => ListTile(
                  title: Text(bookingFor),
                  trailing: selectedBookingFor == bookingFor
                      ? const Icon(Icons.check, color: AppColors.mainButtonBg)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedBookingFor = bookingFor;
                      bookingTypeError = null;
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentModeBottomSheet() {
    final list = paymentModeController.modes;
    showModalBottomSheet<PaymentModeItem>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  'Select Payment Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isSelected =
                        paymentModeController.selectedMode.value == item;
                    return ListTile(
                      title: Text(item.mode ?? ''),
                      trailing: isSelected
                          ? const Icon(Icons.check,
                              color: AppColors.mainButtonBg)
                          : null,
                      onTap: () {
                        setState(() {
                          paymentModeError = null;
                        });
                        paymentModeController.updateSelected(item);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showGenderBottomSheet() {
    final list = controller.genderList;
    showModalBottomSheet<GenderModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  'Select Gender',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isSelected = controller.selectedGender.value == item;
                    return ListTile(
                      title: Text(item.gender ?? ''),
                      trailing: isSelected
                          ? const Icon(Icons.check,
                              color: AppColors.mainButtonBg)
                          : null,
                      onTap: () {
                        setState(() {
                          genderError = null;
                        });
                        controller.selectGender(item);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCarProviderBottomSheet() {
    final list = carProviderController.carProviderList;
    showModalBottomSheet<CarProviderModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  'Select Car Provider',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isSelected =
                        carProviderController.selectedCarProvider.value == item;
                    return ListTile(
                      title: Text(item.providerName ?? ''),
                      trailing: isSelected
                          ? const Icon(Icons.check,
                              color: AppColors.mainButtonBg)
                          : null,
                      onTap: () {
                        setState(() {
                          carProviderError = null;
                        });
                        carProviderController.selectCarProvider(item);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickUpTypeButton() {
    final List<RunTypeItem> allRunTypes =
        runTypeController.runTypes.value?.runTypes ?? [];
    final List<String> allPickupTypes =
        allRunTypes.map((val) => val.run ?? '').toList();
    final hasError = pickupTypeError != null && pickupTypeError!.isNotEmpty;
    final isExpanded = _isPickupTypeExpanded;

    if (allPickupTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              pickupTypeError = null;
              _isPickupTypeExpanded = !_isPickupTypeExpanded;
            });
            if (_isPickupTypeExpanded) {
              _showPickupTypeBottomSheet(allPickupTypes);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Light blue background
              borderRadius: BorderRadius.circular(30),
              border: hasError
                  ? Border.all(
                      color: Colors.red.shade400,
                      width: 2,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Building icon with location pin overlay
                Image.asset(
                  'assets/images/city.png',
                  height: 30,
                  width: 30,
                ),
                const SizedBox(width: 12),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   'Pick Up Type',
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     fontWeight: FontWeight.w400,
                      //     color: hasError
                      //         ? Colors.red.shade400
                      //         : const Color(0xFF7B7B7B), // Lighter gray
                      //   ),
                      // ),
                      // const SizedBox(height: 2),
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pick Up Type *',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7B7B7B)),
                              ),
                            ],
                          ),
                          // SizedBox(height: 4,),
                          Row(
                            children: [
                              Text(
                                selectedPickupType ?? 'Select Pick Up Type',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: hasError
                                      ? Colors.red.shade700
                                      : const Color(
                                          0xFF585858), // Dark gray, bold
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Chevron icon
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: hasError
                      ? Colors.red.shade400
                      : const Color(0xFF333333), // Dark gray
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (pickupTypeError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pickupTypeError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool _isPickupTypeExpanded = false;

  void _showPickupTypeBottomSheet(List<String> pickupTypes) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Pick Up Type",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1), // Slide from top
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          )),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.only(top: 40),
                // constraints: BoxConstraints(
                //   maxHeight: MediaQuery.of(context).size.height * 0.6,
                //   maxWidth: MediaQuery.of(context).size.width - 40,
                // ),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header section (same as button design)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF), // Light blue background
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          // Building icon with location pin overlay
                          Image.asset(
                            'assets/images/city.png',
                            height: 30,
                            width: 30,
                          ),
                          const SizedBox(width: 12),
                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text(
                                //   'Pick Up Type',
                                //   style: TextStyle(
                                //     fontSize: 12,
                                //     fontWeight: FontWeight.w400,
                                //     color: hasError
                                //         ? Colors.red.shade400
                                //         : const Color(0xFF7B7B7B), // Lighter gray
                                //   ),
                                // ),
                                // const SizedBox(height: 2),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Pick Up Type',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF7B7B7B)),
                                        ),
                                      ],
                                    ),
                                    // SizedBox(height: 4,),
                                    Row(
                                      children: [
                                        Text(
                                          selectedPickupType ??
                                              'Select Pick Up Type',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(
                                                0xFF585858), // Dark gray, bold
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Chevron icon
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: const Color(0xFF333333), // Dark gray
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    // Radio button list
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        itemCount: pickupTypes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final pickupType = pickupTypes[index];
                          final isSelected = selectedPickupType == pickupType;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              splashColor: Colors.transparent,
                              onTap: () {
                                setState(() {
                                  selectedPickupType = pickupType;
                                  pickupTypeError = null;
                                  _isPickupTypeExpanded = false;
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                child: Row(
                                  children: [
                                    // Radio button
                                    Radio<String>(
                                      value: pickupType,
                                      groupValue: selectedPickupType,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedPickupType = value;
                                          pickupTypeError = null;
                                          _isPickupTypeExpanded = false;
                                        });
                                        Navigator.pop(context);
                                      },
                                      activeColor: const Color(0xFF1C1B1F),
                                      fillColor: WidgetStateProperty
                                          .resolveWith<Color>((states) {
                                        if (states
                                            .contains(WidgetState.selected)) {
                                          return const Color(0xFF1C1B1F);
                                        }
                                        return Colors.grey.shade400;
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    // Text
                                    Expanded(
                                      child: Text(
                                        pickupType,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF333333), // Dark gray
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isPickupTypeExpanded = false;
      });
    });
  }

  void _showCupertinoDateTimePicker(BuildContext context,
      {required bool isPickup}) {
    final DateTime now = DateTime.now();
    // For pickup, minimum date uses advancedHourToConfirm from login info
    final int minutesOffset = _getAdvancedHourToConfirm();
    // Calculate minimum date properly - for pickup, it's now + minutesOffset
    // The picker will automatically disable dates/times before this minimum
    final DateTime minimumDate = isPickup
        ? now.add(Duration(minutes: minutesOffset))
        : (selectedPickupDateTime ?? now);

    // Use selected date if it exists and is valid (after minimum), otherwise use minimum date
    DateTime? currentSelectedDateTime =
        isPickup ? selectedPickupDateTime : selectedDropDateTime;
    DateTime tempDateTime = currentSelectedDateTime != null &&
            currentSelectedDateTime.isAfter(minimumDate)
        ? currentSelectedDateTime
        : minimumDate;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            return Container(
              height: 350,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Text(
                                isPickup
                                    ? 'Choose Pickup Time'
                                    : 'Choose Drop Time',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF333333),
                                    ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: Colors.grey.shade600),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Divider(
                            height: 1,
                            color: Color(0xFF939393),
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.dateAndTime,
                      initialDateTime: tempDateTime,
                      minimumDate: minimumDate,
                      // The picker automatically prevents selecting dates before minimumDate
                      // Invalid dates/times will appear disabled (grayed out) by default
                      onDateTimeChanged: (DateTime newDateTime) {
                        // Ensure the selected date is always >= minimumDate
                        // This prevents any edge cases where user might scroll to invalid date
                        if (newDateTime.isAfter(minimumDate) ||
                            newDateTime.isAtSameMomentAs(minimumDate)) {
                          setPickerState(() {
                            tempDateTime = newDateTime;
                          });
                        } else {
                          setPickerState(() {
                            tempDateTime = minimumDate;
                          });
                        }
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A1A1A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                    color: Colors.grey.shade300, width: 1.5),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // No need to validate here - the picker's minimumDate
                              // ensures only valid dates can be selected
                              // The tempDateTime is guaranteed to be >= minimumDate
                              if (isPickup) {
                                setState(() {
                                  selectedPickupDateTime = tempDateTime;
                                  pickupDateError = null;
                                });
                              } else {
                                setState(() {
                                  selectedDropDateTime = tempDateTime;
                                  dropDateError = null;
                                });
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainButtonBg,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    // Format: 2016-05-16 15:39:05.277
    // return DateFormat('yyyy MM dd HH:mm:ss.SSS').format(dateTime);
    return DateFormat('dd MMM yyyy, hh:mm a zz').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasError ? Colors.red.shade400 : Colors.grey.shade300,
            width: hasError ? 2 : 1.5,
          ),
          boxShadow: hasError
              ? [
                  BoxShadow(
                    color: Colors.red.shade50,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasError
                    ? Colors.red.shade50
                    : AppColors.mainButtonBg.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: hasError ? Colors.red.shade600 : AppColors.mainButtonBg,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color:
                      hasError ? Colors.red.shade700 : const Color(0xFF1A1A1A),
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: hasError ? Colors.red.shade400 : Colors.grey.shade600,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalOptionsAccordion() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () {
              setState(() {
                isAdditionalOptionsExpanded = !isAdditionalOptionsExpanded;
              });
            },
            child: Container(
              child: Row(
                children: [
                  Container(
                    child: Icon(
                      Icons.add,
                      color: Color(0xFFC1C1C1),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      'Additional Options',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF696972),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isAdditionalOptionsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade600,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded Content
          if (isAdditionalOptionsExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Reference Number Field
                  TextFormField(
                    controller: referenceNumberController,
                    decoration: InputDecoration(
                      hintText: 'Reference Number',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF333333),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 17),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide:
                            BorderSide(color: Color(0xFFE2E2E2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide:
                            BorderSide(color: Color(0xFFE2E2E2), width: 1),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Cost Code Field (same UI as Reference Number)
                  TextFormField(
                    controller: costCodeController,
                    decoration: InputDecoration(
                      hintText: 'Cost Code',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF333333),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 17),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: const BorderSide(
                            color: Color(0xFFE2E2E2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: const BorderSide(
                            color: Color(0xFFE2E2E2), width: 1),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Flight Details Field (same UI as Reference Number)
                  TextFormField(
                    controller: flightDetailsController,
                    decoration: InputDecoration(
                      hintText: 'Flight Details',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF333333),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 17),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: const BorderSide(
                            color: Color(0xFFE2E2E2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: const BorderSide(
                            color: Color(0xFFE2E2E2), width: 1),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Special Instruction Field (same UI as Reference Number, multi-line)
                  TextFormField(
                    controller: specialInstructionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Special Instruction',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF333333),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 17),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: const BorderSide(
                            color: Color(0xFFE2E2E2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: const BorderSide(
                            color: Color(0xFFE2E2E2), width: 1),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewCabsButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _validateAndProceed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4082F1),
          padding:
              const EdgeInsets.only(top: 14, right: 16, bottom: 14, left: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(39),
            side: const BorderSide(color: Color(0xFFD9D9D9), width: 1),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'View Cabs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllErrors() {
    setState(() {
      pickupLocationError = null;
      dropLocationError = null;
      pickupDateError = null;
      dropDateError = null;
      pickupTypeError = null;
      bookingTypeError = null;
      paymentModeError = null;
      genderError = null;
      carProviderError = null;
      corporateError = null;
    });
  }

  void _validateAndProceed() {
    // Clear previous errors
    setState(() {
      pickupLocationError = null;
      dropLocationError = null;
      pickupDateError = null;
      dropDateError = null;
      pickupTypeError = null;
      bookingTypeError = null;
      paymentModeError = null;
      genderError = null;
      carProviderError = null;
      corporateError = null;
    });

    // Collect all validation errors
    List<String> errors = [];
    bool hasValidationError = false;

    // 1. Validate Pickup Location (Required)
    final pickupPlace = crpSelectPickupController.selectedPlace.value;
    final pickupText = crpSelectPickupController.searchController.text.trim();
    if (pickupPlace == null ||
        pickupPlace.primaryText == null ||
        pickupPlace.primaryText?.isEmpty == true ||
        pickupText.isEmpty ||
        pickupText == 'Please Select Pickup') {
      pickupLocationError = 'Please select a pickup location';
      errors.add(pickupLocationError!);
      hasValidationError = true;
    }

    // 2. Validate Drop Location (Optional - no validation needed)

    // 3. Validate Pickup and Drop are not the same (only if both are provided)
    final dropPlace = crpSelectDropController.selectedPlace.value;
    if (pickupPlace != null && dropPlace != null) {
      if (_arePickupAndDropSame(pickupPlace, dropPlace)) {
        pickupLocationError = 'Pickup and drop locations cannot be the same';
        dropLocationError = 'Pickup and drop locations cannot be the same';
        errors.add(pickupLocationError!);
        hasValidationError = true;
      }
    }

    // 4. Validate Pickup Date (Required)
    // Note: Minimum date validation is handled by the date picker itself
    // The picker's minimumDate ensures only valid dates (>= now + advancedHourToConfirm) can be selected
    if (selectedPickupDateTime == null) {
      pickupDateError = 'Please select a pickup date and time';
      errors.add(pickupDateError!);
      hasValidationError = true;
    }
    // No need to validate minimum date here - the picker prevents invalid selections

    // // 5. Validate Drop Date (Required)
    // if (selectedDropDateTime == null) {
    //   dropDateError = 'Please select a drop date and time';
    //   errors.add(dropDateError!);
    //   hasValidationError = true;
    // }

    // 6. Drop Date is optional – no validation needed

    // 7. Validate Pickup Type (Required)
    final List<RunTypeItem> allRunTypes =
        runTypeController.runTypes.value?.runTypes ?? [];
    if (selectedPickupType == null || selectedPickupType!.isEmpty) {
      pickupTypeError = 'Please select a pickup type';
      errors.add(pickupTypeError!);
      hasValidationError = true;
    } else {
      // Validate that selected pickup type exists in the run types list
      final pickupTypeExists =
          allRunTypes.any((runType) => runType.run == selectedPickupType);
      if (!pickupTypeExists) {
        pickupTypeError = 'Selected pickup type is invalid';
        errors.add(pickupTypeError!);
        hasValidationError = true;
      }
    }

    // 8. Validate Booking Type (Required)
    if (selectedBookingFor == null || selectedBookingFor!.isEmpty) {
      bookingTypeError = 'Please select a booking type';
      errors.add(bookingTypeError!);
      hasValidationError = true;
    } else {
      // Validate that selected booking type is in the allowed list
      if (!bookingForList.contains(selectedBookingFor)) {
        bookingTypeError = 'Selected booking type is invalid';
        errors.add(bookingTypeError!);
        hasValidationError = true;
      }
    }

    // 9. Validate Corporate (Required)
    if (selectedCorporate == null) {
      corporateError = 'Please select a corporate';
      errors.add(corporateError!);
      hasValidationError = true;
    }

    // 10. Validate Payment Mode (Required)
    if (paymentModeController.selectedMode.value == null) {
      paymentModeError = 'Please select a payment mode';
      errors.add(paymentModeError!);
      hasValidationError = true;
    }

    // 11. Validate Gender (Required)
    if (controller.selectedGender.value == null) {
      genderError = 'Please select a gender';
      errors.add(genderError!);
      hasValidationError = true;
    }

    // 12. Validate Car Provider (Required)
    if (carProviderController.carProviderList.isNotEmpty) {
      if (carProviderController.selectedCarProvider.value == null) {
        carProviderError = 'Please select a car provider';
        errors.add(carProviderError!);
        hasValidationError = true;
      }
    }

    // Note: Reference Number, Cost Code, Flight Details, and Special Instruction are optional fields
    // No validation needed for them

    // Show errors or proceed
    if (hasValidationError) {
      // Scroll to first error field
      // Show first error in a smooth, professional snackbar as well
      _showErrorSnackBar(errors.first);
    } else {
      // All validations passed, proceed with view cabs
      _handleViewCabs();
    }
  }

  /// Show a smooth, Swiggy-style floating error snackbar
  void _showErrorSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        backgroundColor: const Color(0xFF0B1120), // Deep navy / near-black
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: const Color(0xFF4B5563).withOpacity(0.5), // Subtle border
          ),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C).withOpacity(0.15), // Soft red bg
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFF87171), // Muted red accent
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleViewCabs() {
    // Get the selected pickup type
    final List<RunTypeItem> allRunTypes =
        runTypeController.runTypes.value?.runTypes ?? [];
    String? finalPickupType = selectedPickupType;

    // Find the runTypeID from the selected pickup type
    int? selectedRunTypeId;
    if (finalPickupType != null && allRunTypes.isNotEmpty) {
      final matchedRunType = allRunTypes.firstWhere(
        (rt) => rt.run == finalPickupType,
        orElse: () => allRunTypes.first,
      );
      selectedRunTypeId = matchedRunType.runTypeID;
    }

    // Create booking data object
    final bookingData = CrpBookingData(
      pickupPlace: crpSelectPickupController.selectedPlace.value,
      dropPlace: crpSelectDropController.selectedPlace.value,
      pickupDateTime: selectedPickupDateTime,
      dropDateTime: selectedDropDateTime,
      pickupType: finalPickupType,
      bookingType: selectedBookingFor,
      paymentMode: paymentModeController.selectedMode.value,
      referenceNumber: referenceNumberController.text.trim().isEmpty
          ? null
          : referenceNumberController.text.trim(),
      specialInstruction: specialInstructionController.text.trim().isEmpty
          ? null
          : specialInstructionController.text.trim(),
      costCode: costCodeController.text.trim().isEmpty
          ? null
          : costCodeController.text.trim(),
      flightDetails: flightDetailsController.text.trim().isEmpty
          ? null
          : flightDetailsController.text.trim(),
      gender: controller.selectedGender.value,
      carProvider: carProviderController.selectedCarProvider.value,
      selectedTabIndex: null, // No longer using tabs, always use dropdown
      entityId: selectedCorporate?.entityId,
      runTypeId: selectedRunTypeId,
    );

    // Navigate to inventory screen with booking data
    GoRouter.of(context).push(
      AppRoutes.cprInventory,
      extra: bookingData.toJson(),
    );
    print('All validations passed. Proceeding to view cabs...');
  }
}
