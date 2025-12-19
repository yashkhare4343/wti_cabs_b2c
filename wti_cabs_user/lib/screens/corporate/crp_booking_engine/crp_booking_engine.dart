import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());
  final CrpGetEntityListController crpGetEntityListController =
  Get.put(CrpGetEntityListController());

  final VerifyCorporateController verifyCorporateController = Get.put(VerifyCorporateController());

  String? guestId, token, user;
  int? _preselectedRunTypeId;
  bool _hasAppliedPreselection = false;
  Entity? selectedCorporate;
  Entity? selectedEntity;


  Future<void> fetchParameter() async {
    final storage = StorageServices.instance;
    guestId = await storage.read('branchId');
    token = loginInfoController.crpLoginInfo.value?.key ?? await storage.read('crpKey');
    user = await storage.read('email');
  }

  Future<void> _loadCorporateEntities() async {
    try {
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
    // Initialize async operations
    _initializeData();
    
    // Listen to entity list changes and retry prefilling
    ever(crpGetEntityListController.getAllEntityList, (_) {
      if (mounted && selectedCorporate == null) {
        final entities = crpGetEntityListController.getAllEntityList.value?.getEntityList ?? [];
        if (entities.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tryPrefillCorporateEntity(entities);
          });
        }
      }
    });
    
    // Listen to gender list changes and retry prefilling
    ever(controller.genderList, (_) {
      if (mounted && controller.selectedGender.value == null && controller.genderList.isNotEmpty) {
        debugPrint('🔄 Gender list updated, retrying prefilling. List size: ${controller.genderList.length}');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Get gender ID and try to prefill
          final int targetGenderId = await _getPrefillGenderId();
          if (targetGenderId != 0 && mounted) {
            GenderModel? matchedGender;
            for (final gender in controller.genderList) {
              if (gender.genderID != null && gender.genderID == targetGenderId) {
                matchedGender = gender;
                break;
              }
            }
            if (matchedGender != null && mounted) {
              setState(() {
                controller.selectGender(matchedGender);
                debugPrint('✅ Prefilled Gender from listener: ${matchedGender?.gender}');
              });
            }
          }
        });
      }
    });
    
    // Listen to car provider list changes and retry prefilling
    ever(carProviderController.carProviderList, (_) {
      if (mounted && carProviderController.selectedCarProvider.value == null && carProviderController.carProviderList.isNotEmpty) {
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
      if (widget.selectedPickupPlace == null && widget.selectedDropPlace == null) {
        // Defer clearing until after build to avoid setState during build error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _clearPickupAndDropLocations();
        });
      }
    }

    // 4. If selected place is passed from location selection, set it in the controller
    if (widget.selectedPickupPlace != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        crpSelectPickupController.selectedPlace.value = widget.selectedPickupPlace;
        if (widget.selectedPickupPlace!.primaryText.isNotEmpty) {
          crpSelectPickupController.searchController.text = widget.selectedPickupPlace!.primaryText;
        }
      });
    }

    // 5. If selected drop place is passed from location selection, set it in the controller
    if (widget.selectedDropPlace != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        crpSelectDropController.selectedPlace.value = widget.selectedDropPlace;
        if (widget.selectedDropPlace!.primaryText.isNotEmpty) {
          crpSelectDropController.searchController.text = widget.selectedDropPlace!.primaryText;
        }
      });
    }

    // 6. Load other data (these don't need to wait)
    _loadPreselectedRunType();
    _prefillPickupFromCurrentLocation();
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
      // 1. Login info should already be loaded from main.dart
      // This is a safety check in case it wasn't loaded yet
      if (loginInfoController.crpLoginInfo.value == null) {
        debugPrint('⚠️ Login info not available, loading from storage...');
        // Wait a bit more to ensure it's fully loaded
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 2. Fetch Run Types (doesn't depend on token)
      runTypeController.fetchRunTypes(params, context);

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
        while ((resolvedToken == null || resolvedToken.isEmpty) && retryCount < 10) {
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

      // 7. Fetch all data in parallel (fire-and-forget, but with error handling in controllers)
      // Only fetch if we have a valid token
      if (resolvedToken != null && resolvedToken.isNotEmpty) {
        paymentModeController.fetchPaymentModes(paymentParams, context);
        controller.fetchGender(context);
        carProviderController.fetchCarProviders(context);

      } else {
        debugPrint('❌ Cannot fetch data: Token not available');
        // Retry after a delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            runTypesAndPaymentModes();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error in runTypesAndPaymentModes: $e');
      // Retry after a delay if there was an error
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          runTypesAndPaymentModes();
        }
      });
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
    final hasPickupLocation = crpSelectPickupController.selectedPlace.value != null;
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
    final loginGenderId =
        loginInfoController.crpLoginInfo.value?.genderId ?? 0;
    if (loginGenderId != 0) {
      debugPrint('✅ Using GenderId from login info: $loginGenderId');
      return loginGenderId;
    }

    // Try to get from storage
    final storedGenderIdStr = await StorageServices.instance.read('crpGenderId');
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
    debugPrint('🔄 Starting _applyPrefilledDataFromLogin()');
    
    // Ensure login info is available (loaded either from API or storage)
    if (loginInfoController.crpLoginInfo.value == null) {
      debugPrint('⚠️ Login info is null, waiting...');
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final loginInfo = loginInfoController.crpLoginInfo.value;
    debugPrint('📋 Login info available: ${loginInfo != null}');
    if (loginInfo != null) {
      debugPrint('📋 EntityId from login: ${loginInfo.entityId}, GenderId from login: ${loginInfo.genderId}');
    }

    // Always set pickup datetime using advancedHourToConfirm from login info
    final int hoursOffset = _getAdvancedHourToConfirm();
    if (selectedPickupDateTime == null) {
      setState(() {
        selectedPickupDateTime = DateTime.now().add(Duration(minutes: hoursOffset*60));
      });
    } else {
      // Ensure existing selection is at least advancedHourToConfirm hours from now
      final DateTime now = DateTime.now();
      final DateTime minDateTime = now.add(Duration(minutes: hoursOffset*60));
      if (selectedPickupDateTime!.isBefore(minDateTime)) {
        setState(() {
          selectedPickupDateTime = minDateTime;
        });
      }
    }

    // Don't return early - we can still use stored values even if loginInfo is null

    // Wait briefly for dependent API lists to load so we can match IDs safely.
    // We poll a few times instead of blocking indefinitely.
    const int maxAttempts = 50; // ~5 seconds at 100ms interval (increased for app restart scenario)
    for (int i = 0; i < maxAttempts; i++) {
      final bool gendersReady = controller.genderList.isNotEmpty;
      final bool paymentModesReady = paymentModeController.modes.isNotEmpty;
      final bool entitiesReady = (crpGetEntityListController
          .getAllEntityList.value
          ?.getEntityList ??
          [])
          .isNotEmpty;
      final bool carProvidersReady =
          carProviderController.carProviderList.isNotEmpty ||
              !carProviderController.isLoading.value;

      debugPrint('📊 Lists status - Genders: $gendersReady (${controller.genderList.length}), '
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
      final storedEntityIdStr = await StorageServices.instance.read('crpEntityId');
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

    setState(() {
      // Booking Type – default to "Corporate" if nothing is selected (first element)
      if (selectedBookingFor == null && bookingForList.isNotEmpty) {
        selectedBookingFor = bookingForList.first;
        debugPrint('✅ Prefilled Booking Type: $selectedBookingFor');
      }

      // Gender – match using GenderID from login info or storage (prefill from storage/API)
      if (controller.selectedGender.value == null &&
          controller.genderList.isNotEmpty) {
        debugPrint('🔍 Attempting to prefill Gender. Target ID: $targetGenderId, List size: ${controller.genderList.length}');
        debugPrint('🔍 Gender list IDs: ${controller.genderList.map((g) => g.genderID).toList()}');
        if (targetGenderId != 0) {
          GenderModel? matchedGender;
          for (final gender in controller.genderList) {
            final genderId = gender.genderID;
            debugPrint('  - Checking gender ID: $genderId (type: ${genderId.runtimeType}) vs target: $targetGenderId (type: ${targetGenderId.runtimeType})');
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
            debugPrint('❌ Available gender IDs: ${controller.genderList.map((g) => g.genderID).toList()}');
          }
        } else {
          debugPrint('⚠️ Target GenderId is 0, skipping prefilling');
        }
      } else {
        debugPrint('⚠️ Gender already selected or list empty. Selected: ${controller.selectedGender.value?.gender}, List empty: ${controller.genderList.isEmpty}');
      }

      // Corporate Entity – match using EntityId from login info or storage, else fallback to first
      if (selectedCorporate == null) {
        final entities = crpGetEntityListController
            .getAllEntityList.value
            ?.getEntityList ??
            [];
        debugPrint('🔍 Attempting to prefill Corporate Entity. Target ID: $targetEntityId, List size: ${entities.length}');
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
          debugPrint('✅ Prefilled Corporate Entity: ${selectedCorporate?.entityName} (matched: ${matched != null})');
        } else {
          debugPrint('⚠️ Entities list is empty');
        }
      } else {
        debugPrint('⚠️ Corporate Entity already selected: ${selectedCorporate?.entityName}');
      }

      // Payment Mode – match using PayModeID from login info
      if (paymentModeController.modes.isNotEmpty) {
        final String payModeIdStr = loginInfo?.payModeID??'';
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
      }

      // Car Provider – use first element from the list (as per requirement)
      if (carProviderController.carProviderList.isNotEmpty &&
          carProviderController.selectedCarProvider.value == null) {
        // Use first element from the list
        carProviderController.selectCarProvider(carProviderController.carProviderList.first);
        debugPrint('✅ Prefilled Car Provider: ${carProviderController.carProviderList.first.providerName}');
      } else {
        debugPrint('⚠️ Car Provider already selected or list empty. Selected: ${carProviderController.selectedCarProvider.value?.providerName}, List empty: ${carProviderController.carProviderList.isEmpty}');
      }

      // Pickup DateTime is already set above (before checking loginInfo)
      // This ensures it's always at least advancedHourToConfirm hours from now
    });
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
                  debugPrint('✅ Prefilled Corporate Entity from storage: ${entity.entityName}');
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
            debugPrint('✅ Prefilled Corporate Entity from login: ${entity.entityName}');
            return;
          }
        }
      });
    }
  }

  /// Prefill pickup with current location (name + lat/lng) if available.
  /// Uses the same stored values as the personal cab flow (`sourceTitle`, `sourceLat`, `sourceLng`).
  /// Skips prefilling when navigating from corporate bottom nav (when selectedPickupType is passed).
  Future<void> _prefillPickupFromCurrentLocation() async {
    try {
      // If selectedPickupType is passed, we're coming from corporate bottom nav, so don't prefill
      if (widget.selectedPickupType != null) return;

      // If user has already selected a pickup in corporate flow, don't override it.
      if (crpSelectPickupController.selectedPlace.value != null) return;

      final storage = StorageServices.instance;
      final sourceTitle = await storage.read('sourceTitle');
      final sourceLatStr = await storage.read('sourceLat');
      final sourceLngStr = await storage.read('sourceLng');
      final sourcePlaceId = await storage.read('sourcePlaceId') ?? '';

      if (sourceTitle == null || sourceLatStr == null || sourceLngStr == null) {
        return;
      }

      final lat = double.tryParse(sourceLatStr);
      final lng = double.tryParse(sourceLngStr);
      if (lat == null || lng == null) {
        return;
      }

      final prefilledPlace = SuggestionPlacesResponse(
        primaryText: sourceTitle,
        secondaryText: '',
        placeId: sourcePlaceId,
        types: const [],
        terms: const [],
        city: '',
        state: '',
        country: '',
        isAirport: false,
        latitude: lat,
        longitude: lng,
        placeName: sourceTitle,
      );

      crpSelectPickupController.selectedPlace.value = prefilledPlace;
      crpSelectPickupController.searchController.text = sourceTitle;
    } catch (_) {
      // Silently ignore any errors – prefill is best-effort only.
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

  /// Get the minimum hours offset for pickup datetime from login info
  /// Falls back to 4 hours if not available or if value is 0
  int _getAdvancedHourToConfirm() {
    final loginInfo = loginInfoController.crpLoginInfo.value;
    final hours = loginInfo?.advancedHourToConfirm ?? 0;
    // Use the value from API if it's greater than 0, otherwise default to 4 hours
    return hours > 0 ? hours : 0;
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
    referenceNumberController.dispose();
    specialInstructionController.dispose();
    costCodeController.dispose();
    flightDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.only(left: 20, right: 20, top: 14, bottom: 20),
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
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => bookingTypeError = null);
                      _showBookingTypeBottomSheet();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(37),
                        border: Border.all(
                          color: bookingTypeError != null
                              ? Colors.red.shade400
                              : const Color(0xFFE2E2E2),
                          width: bookingTypeError != null ? 1.5 : 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: Row(
                          children: [
                            Container(
                              height: 24,
                              width: 24,
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                              ),
                              child: SvgPicture.asset(
                                'assets/images/booking_type.svg',
                                width: 20,
                                height: 20,
                                color: const Color(0xFF52A6F9),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedBookingFor ?? 'Select Booking Type',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF333333),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
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
                              size: 16, color: Colors.red.shade600),
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
                      .getAllEntityList.value?.getEntityList ??
                      [];

                  // Try to prefill from storage if not already set (only in build, don't modify state here)
                  // The actual prefilling is handled in _applyPrefilledDataFromLogin()
                  if (selectedCorporate == null &&
                      entities.isNotEmpty) {
                    // Schedule prefilling outside build method
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _tryPrefillCorporateEntity(entities);
                    });
                  }



                  if (entities.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final hasError =
                      corporateError != null && corporateError!.isNotEmpty;



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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 16),
                                      child: Text(
                                        selectedCorporate?.entityName??'Choose Corporate',
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
                                        itemCount: entities.length,
                                        itemBuilder: (context, index) {
                                          final item = entities[index];
                                          final isSelected =
                                              selectedCorporate?.entityId ==
                                                  item.entityId;
                                          return ListTile(
                                            title: Text(item.entityName ?? ''),
                                            trailing: isSelected
                                                ? const Icon(Icons.check,
                                                color:
                                                AppColors.mainButtonBg)
                                                : null,
                                            onTap: () {
                                              setState(() {
                                                corporateError = null;
                                                selectedCorporate = item;
                                              });
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
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(37),
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
                                padding: const EdgeInsets.all(1.5),
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
                                  size: 16, color: Colors.red.shade600),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
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

                  final hasError =
                      paymentModeError != null && paymentModeError!.isNotEmpty;
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
                            borderRadius: BorderRadius.circular(37),
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
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                ),
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
                                      .selectedMode.value?.mode ??
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
                                  size: 16, color: Colors.red.shade600),
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
                      final hasError =
                          genderError != null && genderError!.isNotEmpty;
                      return GestureDetector(
                        onTap: () {
                          setState(() => genderError = null);
                          _showGenderBottomSheet();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
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
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                ),
                                child: Icon(Icons.person_outline_outlined, size: 20, color: Color(0xFF96C4FA),),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  controller.selectedGender.value?.gender ??
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
                                size: 16, color: Colors.red.shade600),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.mainButtonBg),
                        ),
                      ),
                    );
                  }

                  final list = carProviderController.carProviderList;

                  if (list.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final hasError =
                      carProviderError != null && carProviderError!.isNotEmpty;
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
                            borderRadius: BorderRadius.circular(30),
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
                                decoration: BoxDecoration(
                                ),
                                child: Icon(
                                  Icons.directions_car_filled_outlined,
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
                                      .selectedCarProvider.value
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
                                  size: 16, color: Colors.red.shade600),
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
                Divider(height: 1,color: Color(0xFFE6E6E6),),
                const SizedBox(height: 20),


                // Additional Options
                _buildAdditionalOptionsAccordion(),
                const SizedBox(height: 40),

                // View Cabs Button
                _buildViewCabsButton(),
              ],
            ),
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
        color: const Color(0xFFEFF6FF), // Background light blue as image
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pickupLocationError != null || dropLocationError != null
              ? Colors.red.shade300
              : const Color(0xFFD3E3FD),
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
                      color: Color(0xFF2563EB),
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
                  Container(
                    width: 3,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  // Square end (drop icon)
                  Container(
                    width: 15,
                    height: 15,
                    padding: EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
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
                      AppRoutes.cprSelectPickup,
                      extra: selectedPickupType,
                    );
                  },
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Obx(() {
                      final pickupPlace = crpSelectPickupController.selectedPlace.value;
                      String displayText;
                      bool hasText;

                      if (pickupPlace != null && pickupPlace.primaryText != null && pickupPlace.primaryText!.isNotEmpty) {
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
                          fontWeight: hasText ? FontWeight.w600 : FontWeight.w500,
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
                      AppRoutes.cprSelectDrop,
                      extra: selectedPickupType,
                    );
                  },
                  child: Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 2),
                    child: Obx(() {
                      final dropPlace = crpSelectDropController.selectedPlace.value;
                      String displayText;
                      bool hasText;

                      if (dropPlace != null && dropPlace.primaryText != null && dropPlace.primaryText!.isNotEmpty) {
                        final secondaryText = dropPlace.secondaryText ?? '';
                        displayText = secondaryText.isNotEmpty
                            ? '${dropPlace.primaryText}, $secondaryText'
                            : dropPlace.primaryText!;
                        hasText = true;
                      } else {
                        displayText = 'Enter drop location';
                        hasText = false;
                      }

                      return Text(
                        displayText,
                        style: TextStyle(
                          fontWeight: hasText ? FontWeight.w600 : FontWeight.w500,
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
        Row(
          children: [
            // Pick Up Date Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    pickupDateError = null;
                  });
                  _showCupertinoDateTimePicker(context, isPickup: true);
                },
                child: Container(
                  // height: 38,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: pickupDateError != null
                          ? Colors.red.shade400
                          : const Color(0xFF000000),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.schedule_rounded,
                            color: Color(0xFF000000), size: 20),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          selectedPickupDateTime != null
                              ? _formatDateTime(selectedPickupDateTime!)
                              : 'Pick Up Date *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: pickupDateError != null
                                ? Colors.red.shade600
                                : const Color(0xFF333333),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF222222), size: 22)
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Drop Date Button (optional)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    dropDateError = null;
                  });
                  _showCupertinoDateTimePicker(context, isPickup: false);
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: dropDateError != null
                          ? Colors.red.shade400
                          : const Color(0xFF000000),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.schedule_rounded,
                            color: Color(0xFF000000), size: 20),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          selectedDropDateTime != null
                              ? _formatDateTime(selectedDropDateTime!)
                              : 'Drop Date',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: dropDateError != null
                                ? Colors.red.shade600
                                : const Color(0xFF333333),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF222222), size: 22)
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                    final isSelected =
                        controller.selectedGender.value == item;
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
                        carProviderController.selectedCarProvider.value ==
                            item;
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
    final int hoursOffset = _getAdvancedHourToConfirm();
    final DateTime minimumDate = isPickup
        ? now.add(Duration(hours: 0))
        : (selectedPickupDateTime ?? now);

    // Use selected date if it exists and is valid, otherwise use minimum date
    DateTime? currentSelectedDateTime =
    isPickup ? selectedPickupDateTime : selectedDropDateTime;
    DateTime tempDateTime = currentSelectedDateTime != null &&
        currentSelectedDateTime.isAfter(minimumDate) &&
        (!isPickup || currentSelectedDateTime.isAfter(now.add(Duration(minutes: hoursOffset*60))))
        ? currentSelectedDateTime
        : minimumDate;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
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
                                ? 'Select Pickup Date & Time'
                                : 'Select Drop Date & Time',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDateTime = newDateTime;
                  },
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          if (isPickup) {
                            final DateTime now = DateTime.now();
                            final int hoursOffset = _getAdvancedHourToConfirm();
                            final DateTime minPickupDateTime = now.add(Duration(minutes: hoursOffset*60));

                            // Validate pickup date is at least advancedHourToConfirm hours from now
                            if (tempDateTime.isBefore(minPickupDateTime)) {
                              setState(() {
                                pickupDateError = 'Pickup date and time must be at least $hoursOffset hours from now';
                              });
                              // Show error snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Pickup date and time must be at least $hoursOffset hours from now'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              return; // Don't close the picker
                            }
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
  }

  String _formatDateTime(DateTime dateTime) {
    // Format: 2016-05-16 15:39:05.277
    // return DateFormat('yyyy MM dd HH:mm:ss.SSS').format(dateTime);
    return DateFormat('dd MMM yyyy, hh:mm a zz').format(dateTime);
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
                        borderSide:
                        const BorderSide(color: Color(0xFFE2E2E2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide:
                        const BorderSide(color: Color(0xFFE2E2E2), width: 1),
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
                        borderSide:
                        const BorderSide(color: Color(0xFFE2E2E2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide:
                        const BorderSide(color: Color(0xFFE2E2E2), width: 1),
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
                        borderSide:
                        const BorderSide(color: Color(0xFFE2E2E2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide:
                        const BorderSide(color: Color(0xFFE2E2E2), width: 1),
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
          padding: const EdgeInsets.only(top: 14, right: 16, bottom: 14, left: 16),
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

    // 2. Validate Drop Location (Required)
    final dropPlace = crpSelectDropController.selectedPlace.value;
    final dropText = crpSelectDropController.searchController.text.trim();
    if (dropPlace == null ||
        dropPlace.primaryText == null ||
        dropPlace.primaryText?.isEmpty == true ||
        dropText.isEmpty) {
      dropLocationError = 'Please select a drop location';
      errors.add(dropLocationError!);
      hasValidationError = true;
    }

    // 3. Validate Pickup and Drop are not the same (Required)
    if (pickupPlace != null && dropPlace != null) {
      if (pickupPlace.placeId == dropPlace.placeId) {
        pickupLocationError = 'Pickup and drop locations cannot be the same';
        dropLocationError = 'Pickup and drop locations cannot be the same';
        errors.add(pickupLocationError!);
        hasValidationError = true;
      }
    }

    // 4. Validate Pickup Date (Required)
    if (selectedPickupDateTime == null) {
      pickupDateError = 'Please select a pickup date and time';
      errors.add(pickupDateError!);
      hasValidationError = true;
    } else {
      final DateTime now = DateTime.now();
      final int hoursOffset = _getAdvancedHourToConfirm();
      final DateTime minPickupDateTime = now.add(Duration(minutes: hoursOffset*60));

      // Validate pickup date is at least advancedHourToConfirm hours from now
      if (selectedPickupDateTime!.isBefore(minPickupDateTime)) {
        pickupDateError = 'Pickup date and time must be at least $hoursOffset hours from now';
        errors.add(pickupDateError!);
        hasValidationError = true;
      }
    }

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
      // Show first error in a snackbar as well
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors.first),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // All validations passed, proceed with view cabs
      _handleViewCabs();
    }
  }

  void _handleViewCabs() {
    // Get the selected pickup type
    final List<RunTypeItem> allRunTypes =
        runTypeController.runTypes.value?.runTypes ?? [];
    String? finalPickupType = selectedPickupType;

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
    );

    // Navigate to inventory screen with booking data
    GoRouter.of(context).push(
      AppRoutes.cprInventory,
      extra: bookingData.toJson(),
    );
    print('All validations passed. Proceeding to view cabs...');
  }
}
