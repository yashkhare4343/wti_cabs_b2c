import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_inventory_list_controller/crp_inventory_list_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_select_drop_controller/crp_select_drop_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_select_pickup_controller/crp_select_pickup_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/select_location/select_drop.dart';
import '../../../../common_widget/loader/shimmer/corporate_shimmer.dart';
import '../../../../common_widget/textformfield/booking_textformfield.dart';
import '../../../../common_widget/snackbar/custom_snackbar.dart';
import '../../../../utility/constants/colors/app_colors.dart';
import '../../../../utility/constants/fonts/common_fonts.dart';
import '../../../core/controller/corporate/crp_booking_history_controller/crp_booking_history_controller.dart';
import '../../../core/controller/corporate/crp_gender/crp_gender_controller.dart';
import '../../../core/controller/corporate/crp_booking_detail/crp_booking_detail_controller.dart';
import '../../../core/controller/corporate/crp_car_provider/crp_car_provider_controller.dart';
import '../../../core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import '../../../core/controller/corporate/crp_payment_mode_controller/crp_payment_mode_controller.dart';
import '../../../core/controller/corporate/crp_services_controller/crp_sevices_controller.dart';
import '../../../core/model/corporate/crp_car_models/crp_car_models_response.dart';
import '../../../core/model/corporate/crp_gender_response/crp_gender_response.dart';
import '../../../core/model/corporate/crp_car_provider_response/crp_car_provider_response.dart';
import '../../../core/model/corporate/crp_payment_method/crp_payment_mode.dart';
import '../../../core/model/corporate/crp_services/crp_services_response.dart';
import '../../../core/model/corporate/crp_booking_data/crp_booking_data.dart';
import '../../../core/model/booking_engine/suggestions_places_response.dart';
import '../../../core/services/storage_services.dart';
import '../../../core/api/corporate/cpr_api_services.dart';

class CprModifyBooking extends StatefulWidget {
  const CprModifyBooking({
    super.key,
    required this.orderId,
    required this.branchId,
    this.initialCarModelName,
  });

  final String orderId;
  final String branchId;
  final String? initialCarModelName;

  @override
  State<CprModifyBooking> createState() => _CprModifyBookingState();
}

class _CprModifyBookingState extends State<CprModifyBooking> {
  // #region agent log
  void _agentLog({
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, dynamic>? data,
    String runId = 'run1',
  }) {
    try {
      final payload = <String, dynamic>{
        'sessionId': 'debug-session',
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data ?? <String, dynamic>{},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      // 1) Best-effort local file write (works on macOS/desktop runs)
      try {
        File('/Users/asndtechnologies/Documents/yash/wti_cabs_b2c/wti_cabs_user/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(payload)}\n',
                mode: FileMode.append, flush: true);
      } catch (_) {}

      // 2) Best-effort HTTP ingest (works when app can't write to host FS)
      try {
        final baseUri = Uri.parse(
            'http://127.0.0.1:7242/ingest/7d4e7254-f04b-431d-ae17-5bdc7357e72b');
        final effectiveUri =
            Platform.isAndroid ? baseUri.replace(host: '10.0.2.2') : baseUri;
        http
            .post(
              effectiveUri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .catchError((_) {});
      } catch (_) {}
    } catch (_) {}
  }
  // #endregion
  final GenderController controller = Get.put(GenderController());
  final CarProviderController carProviderController =
      Get.put(CarProviderController());
  final CrpBookingDetailsController crpBookingDetailsController =
      Get.put(CrpBookingDetailsController());
  final LoginInfoController loginInfoController =
      Get.put(LoginInfoController());
  bool _showShimmer = true;

  String? guestId, token, user;
  int? _preselectedRunTypeId;
  bool _hasAppliedPreselection = false;
  int? _prefillPaymentModeId;
  int? _prefillGenderId;
  int? _prefillProviderId;
  bool _hasAppliedFieldPrefill = false;
  bool _hasAppliedSelectionPrefill = false;
  bool _showSkeletonLoader = true;
  bool _hasAppliedCarModelPrefill = false;
  int? _lastFetchedInventoryRunTypeId;

  /// Modify button enablement
  /// - Disabled (with 0.4 opacity) until user changes something
  /// - Disabled again if user reverts to original values
  bool _userHasInteracted = false;
  bool _hasChanges = false;
  bool _hasCapturedBaseline = false;

  int? _baselineRunTypeId;
  int? _baselineMakeId;
  DateTime? _baselinePickupDateTime;
  String _baselinePickupAddress = '';
  String _baselineDropAddress = '';

  Future<void> fetchParameter() async {
    // Resolve identifiers from storage; fallback to in-memory login info when returning from other screens
    guestId = await StorageServices.instance.read('guestId');
    token = await StorageServices.instance.read('crpKey');
    user = await StorageServices.instance.read('email');

    // Fallback to login info controller if storage values are missing/invalid
    if (token == null || token!.isEmpty || token == 'null') {
      final loginToken = loginInfoController.crpLoginInfo.value?.key;
      if (loginToken != null && loginToken.isNotEmpty) {
        token = loginToken;
        await StorageServices.instance.save('crpKey', loginToken);
      }
    }

    final loginGuestId = loginInfoController.crpLoginInfo.value?.guestID;
    if (guestId == null ||
        guestId!.isEmpty ||
        guestId == '0' ||
        guestId == 'null') {
      if (loginGuestId != null && loginGuestId != 0) {
        guestId = loginGuestId.toString();
        await StorageServices.instance.save('guestId', guestId ?? '');
      }
    }
  }

  @override
  void initState() {
    // #region agent log
    _agentLog(
      hypothesisId: 'E',
      location: 'cpr_modify_booking.dart:initState',
      message: 'CprModifyBooking opened',
      data: {'hasInitialCarModelName': widget.initialCarModelName != null},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _agentLog(
        hypothesisId: 'E',
        location: 'cpr_modify_booking.dart:initState',
        message: 'CprModifyBooking first frame',
        data: {'mounted': mounted},
      );
    });
    // #endregion

    // Show shimmer for 0.5 seconds
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showShimmer = false;
        });
      }
    });
    super.initState();
    _initPrefillListeners();
    // Recompute change state when text changes (incl. after returning from search screens)
    alternativeMobileNoController.addListener(_recomputeHasChanges);
    crpSelectPickupController.searchController.addListener(_recomputeHasChanges);
    crpSelectDropController.searchController.addListener(_recomputeHasChanges);
    runTypesAndPaymentModes();
    _loadBookingDetails();
    // Show skeleton loader for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSkeletonLoader = false;
        });
      }
    });
  }

  void runTypesAndPaymentModes() async {
    // 1. Fetch Run Types
    runTypeController.fetchRunTypes(params, context);

    // 2. Wait for guestId, token, user
    await fetchParameter();

    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    final storedCorpId = await StorageServices.instance.read('crpId');
    // final storedBranchId = await StorageServices.instance.read('branchId');

    // 3. Now call payment modes safely
    final Map<String, dynamic> paymentParams = {
      'GuestID': int.parse(guestId ?? ''),
      'token': token,
      'user': user ?? email
    };

    // Inventory (car models) depends on an exact RunTypeID.
    // On this screen, booking details + run types can arrive later, so only fetch
    // when we can resolve a non-null RunTypeID.
    final resolvedRunTypeId = runTypeIdForInventory();
    if (resolvedRunTypeId != null) {
      // Prefer stored corp/branch (authoritative for corporate session)
      // Booking-details IDs can be different fields (e.g. provider/company ids) and break inventory filtering.
      final corpIdForInventory = storedCorpId ??
          crpBookingDetailsController
              .crpBookingDetailResponse.value?.corporateID
              ?.toString();
      final branchIdForInventory = widget.branchId;

      final Map<String, dynamic> inventoryParams = {
        'token': token,
        'user': user ?? email,
        'CorpID': corpIdForInventory,
        'BranchID': widget.branchId,
        'RunTypeID': resolvedRunTypeId,
      };

      // #region agent log
      // _agentLog(
      //   hypothesisId: 'B',
      //   location: 'cpr_modify_booking.dart:runTypesAndPaymentModes',
      //   message: 'Initial inventory fetch params (corp/branch source)',
      //   data: {
      //     'corpIdForInventory': corpIdForInventory,
      //     'branchIdForInventory': branchIdForInventory,
      //     'storedCorpId': storedCorpId,
      //     'storedBranchId': storedBranchId,
      //   },
      // );
      // #endregion

      _lastFetchedInventoryRunTypeId = resolvedRunTypeId;
      // Skip auto-selection so we can preselect based on booking details
      crpInventoryListController.fetchCarModels(inventoryParams, context,
          skipAutoSelection: true);
    }

    paymentModeController.fetchPaymentModes(paymentParams, context);
    controller.fetchGender(context);
  }

  void _initPrefillListeners() {
    ever<dynamic>(crpBookingDetailsController.crpBookingDetailResponse, (_) {
      _applyPrefilledFields();
      _applyPrefilledSelectionsIfReady();
      // Also try to apply car model prefill when booking details are loaded
      _applyCarModelPrefill();
      _captureBaselineIfNeeded();
      _recomputeHasChanges();
    });
    ever(runTypeController.runTypes, (_) => _applyPrefilledSelectionsIfReady());
    ever(
        paymentModeController.modes, (_) => _applyPrefilledSelectionsIfReady());
    ever(controller.genderList, (_) => _applyPrefilledSelectionsIfReady());
    ever(carProviderController.carProviderList,
        (_) => _applyPrefilledSelectionsIfReady());
    // Apply car model prefill once inventory models are loaded
    ever(crpInventoryListController.models, (_) => _applyCarModelPrefill());
    // Also trigger when loading finishes to ensure prefill happens
    ever(crpInventoryListController.isLoading, (isLoading) {
      if (!isLoading && crpInventoryListController.models.isNotEmpty) {
        _applyCarModelPrefill();
      }
    });

    // Change tracking hooks
    ever(crpSelectPickupController.selectedPlace, (_) => _recomputeHasChanges());
    ever(crpSelectDropController.selectedPlace, (_) => _recomputeHasChanges());
    ever(crpInventoryListController.selectedModel, (_) => _recomputeHasChanges());
  }

  Future<void> _loadBookingDetails() async {
    await fetchParameter();
    final currentToken = token ?? '';
    final currentUser = user ?? '';

    if (widget.orderId.isEmpty || currentToken.isEmpty || currentUser.isEmpty) {
      return;
    }

    await crpBookingDetailsController.fetchBookingData(
        widget.orderId, currentToken, currentUser);
  }

  final CrpServicesController runTypeController =
      Get.put(CrpServicesController());
  final CrpSelectPickupController crpSelectPickupController =
      Get.put(CrpSelectPickupController());
  final CrpSelectDropController crpSelectDropController =
      Get.put(CrpSelectDropController());
  final CrpInventoryListController crpInventoryListController =
      Get.put(CrpInventoryListController());
  final paymentModeController = Get.put(PaymentModeController());

  String? selectedPickupType;
  String? selectedBookingFor;

  Map<String, dynamic> get params => {
        'CorpID': StorageServices.instance.read('crpId'),
        'BranchID': widget.branchId,
      };

  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  /// Get the minimum minutes offset for pickup datetime from login info
  /// Falls back to 0 if not available or if value is 0
  /// Adds 15 minutes to the configured hours
  int _getAdvancedHourToConfirm() {
    final loginInfo = loginInfoController.crpLoginInfo.value;
    final hours = loginInfo?.advancedHourToConfirm ?? 0;
    // Convert hours to minutes and add 15 minutes
    return (hours > 0 ? hours : 0) * 60 + 15;
  }

  SuggestionPlacesResponse? _buildPlaceFromAddress(String? address) {
    if (address == null || address.isEmpty) return null;
    return SuggestionPlacesResponse(
      primaryText: address,
      secondaryText: '',
      placeId: '',
      types: const [],
      terms: const [],
      city: '',
      state: '',
      country: '',
      isAirport: false,
      latitude: null,
      longitude: null,
      placeName: address,
    );
  }

  void _showCarModelBottomSheet() {
    // #region agent log
    _agentLog(
      hypothesisId: 'E',
      location: 'cpr_modify_booking.dart:_showCarModelBottomSheet',
      message: 'Open car model bottom sheet',
      data: {
        'modelsCount': crpInventoryListController.models.length,
        'selectedMakeId': crpInventoryListController.selectedModel.value?.makeId,
      },
    );
    // #endregion

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        final list = crpInventoryListController.models;
        final height = MediaQuery.of(context).size.height * 0.5;

        return SizedBox(
          height: height,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),

                /// Title
                Container(
                  height: 5,
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Select Car Model",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),

                /// LIST
                Flexible(
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey.shade300),
                    itemBuilder: (_, index) {
                      final item = list[index];
                      final isSelected = crpInventoryListController
                              .selectedModel.value?.makeId ==
                          item.makeId;

                      return GestureDetector(
                        onTap: () {
                          _userHasInteracted = true;
                          crpInventoryListController.updateSelected(item);
                          _recomputeHasChanges();
                          Navigator.pop(context);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _removeBracketText(item.carType),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.mainButtonBg
                                      : const Color(0xFF333333),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                size: 20,
                                color: AppColors.mainButtonBg,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applyPrefilledFields() {
    if (_hasAppliedFieldPrefill) return;
    final data = crpBookingDetailsController.crpBookingDetailResponse.value;
    if (data == null) return;

    // Use RunTypeID from booking details response to prefill the run type selection
    _preselectedRunTypeId = data.runTypeID;
    _prefillPaymentModeId = data.payMode;
    _prefillGenderId = data.gender;
    _prefillProviderId = data.providerID;

    selectedBookingFor ??= 'Corporate';
    alternativeMobileNoController.text = data.alternateMobile ?? '';

    final pickupPlace = _buildPlaceFromAddress(data.pickupAddress);
    if (pickupPlace != null) {
      crpSelectPickupController.selectedPlace.value = pickupPlace;
      crpSelectPickupController.searchController.text = pickupPlace.primaryText;
    }

    // Handle drop address - clear if null, empty, or "null" string
    final dropAddress = data.dropAddress;
    final hasValidDropAddress = dropAddress != null &&
        dropAddress.trim().isNotEmpty &&
        dropAddress.trim().toLowerCase() != 'null';

    if (hasValidDropAddress) {
      final dropPlace = _buildPlaceFromAddress(dropAddress);
      if (dropPlace != null) {
        crpSelectDropController.selectedPlace.value = dropPlace;
        crpSelectDropController.searchController.text = dropPlace.primaryText;
      }
    } else {
      // Clear drop selection if address is null, empty, or "null"
      crpSelectDropController.selectedPlace.value = null;
      crpSelectDropController.searchController.text = '';
    }

    // Prefill pickup date/time from booking details
    final parsedDateTime = _parseDateTime(data.cabRequiredOn);
    if (parsedDateTime != null) {
      setState(() {
        selectedPickupDateTime = parsedDateTime;
      });
    }
    _hasAppliedFieldPrefill = true;
  }

  void _applyPrefilledSelectionsIfReady() {
    if (_hasAppliedSelectionPrefill) return;
    final data = crpBookingDetailsController.crpBookingDetailResponse.value;
    if (data == null) return;

    bool runTypeApplied = false;
    bool paymentApplied = false;
    bool genderApplied = false;
    bool providerApplied = false;

    final runTypes = runTypeController.runTypes.value?.runTypes ?? [];
    if (_preselectedRunTypeId != null && runTypes.isNotEmpty) {
      final match = runTypes
          .firstWhereOrNull((item) => item.runTypeID == _preselectedRunTypeId);
      if (match != null) {
        selectedPickupType = match.run;
        _hasAppliedPreselection = true;
        runTypeApplied = true;
      }
    }

    if (_prefillPaymentModeId != null &&
        paymentModeController.modes.isNotEmpty) {
      final payment = paymentModeController.modes
          .firstWhereOrNull((item) => item.id == _prefillPaymentModeId);
      if (payment != null) {
        paymentModeController.updateSelected(payment);
        paymentApplied = true;
      }
    }

    if (_prefillGenderId != null && controller.genderList.isNotEmpty) {
      final gender = controller.genderList
          .firstWhereOrNull((item) => item.genderID == _prefillGenderId);
      if (gender != null) {
        controller.selectGender(gender);
        genderApplied = true;
      }
    }

    if (_prefillProviderId != null &&
        carProviderController.carProviderList.isNotEmpty) {
      final provider = carProviderController.carProviderList
          .firstWhereOrNull((item) => item.providerID == _prefillProviderId);
      if (provider != null) {
        carProviderController.selectCarProvider(provider);
        providerApplied = true;
      }
    }

    final runTypeReady =
        _preselectedRunTypeId == null || runTypeController.isLoading.isFalse;
    final paymentReady = _prefillPaymentModeId == null ||
        paymentModeController.isLoading.isFalse;
    final genderReady =
        _prefillGenderId == null || controller.genderList.isNotEmpty;
    final providerReady = _prefillProviderId == null ||
        carProviderController.carProviderList.isNotEmpty;

    if (runTypeReady && paymentReady && genderReady && providerReady) {
      _hasAppliedSelectionPrefill =
          runTypeApplied || paymentApplied || genderApplied || providerApplied;
    }

    // Ensure inventory models are fetched for the exact (prefilled) RunTypeID.
    // This fixes cases where initial inventory fetch happened before booking/run types were ready.
    if (runTypeApplied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadCarModelsOnRunTypeChange();
      });
    }
  }

  /// Prefill car model in dropdown using the passed car model name (if any)
  /// or makeID from booking details response
  void _applyCarModelPrefill() {
    if (_hasAppliedCarModelPrefill) return;

    final models = crpInventoryListController.models;
    if (models.isEmpty) return;

    CrpCarModel? matchedModel;

    // First, try to match by makeID from booking details response (more reliable)
    final bookingDetails =
        crpBookingDetailsController.crpBookingDetailResponse.value;
    if (bookingDetails?.makeID != null) {
      matchedModel = models.firstWhereOrNull(
        (m) => m.makeId == bookingDetails!.makeID,
      );
      if (matchedModel != null) {
        crpInventoryListController.updateSelected(matchedModel);
        _hasAppliedCarModelPrefill = true;
        debugPrint(
            '✅ Car model preselected by makeID: ${matchedModel.carType}');
        return;
      }
    }

    // Fallback to matching by car model name from initialCarModelName
    final targetName = widget.initialCarModelName;
    if (targetName != null && targetName.trim().isNotEmpty) {
      final normalizedTarget = targetName.trim().toLowerCase();

      // Try exact match first
      matchedModel = models.firstWhereOrNull(
        (m) => (m.carType ?? '').trim().toLowerCase() == normalizedTarget,
      );

      // If no exact match, try partial match (contains)
      if (matchedModel == null) {
        matchedModel = models.firstWhereOrNull(
          (m) =>
              (m.carType ?? '')
                  .trim()
                  .toLowerCase()
                  .contains(normalizedTarget) ||
              normalizedTarget.contains((m.carType ?? '').trim().toLowerCase()),
        );
      }

      if (matchedModel != null) {
        crpInventoryListController.updateSelected(matchedModel);
        _hasAppliedCarModelPrefill = true;
        debugPrint('✅ Car model preselected by name: ${matchedModel.carType}');
      } else {
        debugPrint('⚠️ Could not find car model matching: $targetName');
        debugPrint(
            'Available models: ${models.map((m) => m.carType).toList()}');
        // If no match found, select first model as fallback
        if (models.isNotEmpty) {
          crpInventoryListController.updateSelected(models.first);
          _hasAppliedCarModelPrefill = true;
        }
      }
    } else {
      // If no target name provided, select first model as fallback
      if (models.isNotEmpty) {
        crpInventoryListController.updateSelected(models.first);
        _hasAppliedCarModelPrefill = true;
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
  String? carModelError;

  final TextEditingController alternativeMobileNoController =
      TextEditingController();
  final TextEditingController cancelReasonController = TextEditingController();
  String? selectedCancelReason; // Track selected radio option

  // final TextEditingController pickupController = TextEditingController();
  // final TextEditingController dropController = TextEditingController();

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
    alternativeMobileNoController.removeListener(_recomputeHasChanges);
    crpSelectPickupController.searchController
        .removeListener(_recomputeHasChanges);
    crpSelectDropController.searchController.removeListener(_recomputeHasChanges);
    alternativeMobileNoController.dispose();
    cancelReasonController.dispose();
    super.dispose();
  }

  void _captureBaselineIfNeeded() {
    if (_hasCapturedBaseline) return;
    final data = crpBookingDetailsController.crpBookingDetailResponse.value;
    if (data == null) return;

    _baselineRunTypeId = data.runTypeID;
    _baselineMakeId = data.makeID;
    _baselinePickupDateTime = _parseDateTime(data.cabRequiredOn);
    _baselinePickupAddress = (data.pickupAddress ?? '').trim();

    final drop = data.dropAddress;
    final dropClean = (drop == null ||
            drop.trim().isEmpty ||
            drop.trim().toLowerCase() == 'null')
        ? ''
        : drop.trim();
    _baselineDropAddress = dropClean;

    _hasCapturedBaseline = true;
  }

  bool _isSameMoment(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.toUtc().millisecondsSinceEpoch == b.toUtc().millisecondsSinceEpoch;
  }

  bool _computeHasChangesCore() {
    if (!_hasCapturedBaseline) return false;

    final pickupRaw =
        (crpSelectPickupController.selectedPlace.value?.primaryText ??
                crpSelectPickupController.searchController.text)
            .trim();
    final dropRaw = (crpSelectDropController.selectedPlace.value?.primaryText ??
            crpSelectDropController.searchController.text)
        .trim();

    // Match API fallback behavior: if empty, treat as "unchanged"
    final pickup = pickupRaw.isNotEmpty ? pickupRaw : _baselinePickupAddress;
    final drop = dropRaw.isNotEmpty ? dropRaw : _baselineDropAddress;

    final currentRunTypeId = runTypeIdForInventory() ?? _baselineRunTypeId;
    final currentMakeId =
        crpInventoryListController.selectedModel.value?.makeId ?? _baselineMakeId;
    final currentPickupDateTime =
        selectedPickupDateTime ?? _baselinePickupDateTime;

    if (pickup.trim() != _baselinePickupAddress.trim()) return true;
    if (drop.trim() != _baselineDropAddress.trim()) return true;
    if (currentRunTypeId != _baselineRunTypeId) return true;
    if (currentMakeId != _baselineMakeId) return true;
    if (!_isSameMoment(currentPickupDateTime, _baselinePickupDateTime)) return true;

    return false;
  }

  void _recomputeHasChanges() {
    if (!mounted) return;
    final next = _userHasInteracted && _computeHasChangesCore();
    if (next == _hasChanges) return;
    setState(() => _hasChanges = next);
  }

  Widget _buildSkeletonLoader() {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    Widget _buildShimmerContainer({
      double? height,
      double? width,
      double radius = 8.0,
    }) {
      return Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: _buildShimmerContainer(height: 20, width: 150),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1400),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 14, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup type skeleton
                _buildShimmerContainer(height: 50, radius: 30),
                const SizedBox(height: 20),
                // Location section skeleton
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildShimmerContainer(height: 40, radius: 8),
                      const SizedBox(height: 12),
                      _buildShimmerContainer(height: 40, radius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Date buttons skeleton
                Row(
                  children: [
                    Expanded(
                      child: _buildShimmerContainer(height: 40, radius: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Car model skeleton
                _buildShimmerContainer(height: 20, width: 100),
                const SizedBox(height: 10),
                _buildShimmerContainer(height: 50, radius: 30),
                const SizedBox(height: 16),
                // Alternate number skeleton
                _buildShimmerContainer(height: 20, width: 120),
                const SizedBox(height: 10),
                _buildShimmerContainer(height: 50, radius: 35),
                const SizedBox(height: 20),
                // Divider
                _buildShimmerContainer(height: 1),
                const SizedBox(height: 40),
                // View Cabs button skeleton
                _buildShimmerContainer(height: 50, radius: 39),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showShimmer) {
      return const CorporateShimmer();
    }
    // Show skeleton loader for 2 seconds
    if (_showSkeletonLoader) {
      return _buildSkeletonLoader();
    }

    // Defer TextEditingController updates to avoid setState during build
    // Only update if we have a selected place (don't clear user input when selectedPlace is null)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final selectedPickupPlace = crpSelectPickupController.selectedPlace.value;
      if (selectedPickupPlace != null) {
        final pickupText = selectedPickupPlace.primaryText;
        if (crpSelectPickupController.searchController.text != pickupText) {
          crpSelectPickupController.searchController.text = pickupText;
        }
      }
      
      final selectedDropPlace = crpSelectDropController.selectedPlace.value;
      if (selectedDropPlace != null) {
        final dropText = selectedDropPlace.primaryText;
        if (crpSelectDropController.searchController.text != dropText) {
          crpSelectDropController.searchController.text = dropText;
        }
      }
    });
    
    return PopScope(
      canPop: true,
      child: Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Modify Booking',
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
              SizedBox(
                height: 16,
              ),

              // Car model
              Obx(() {
                if (crpInventoryListController.isLoading.value) {
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

                final list = crpInventoryListController.models;

                if (list.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Explicitly access selectedModel to ensure Obx tracks it
                final selectedModel = crpInventoryListController.selectedModel.value;
                final hasError =
                    carModelError != null && carModelError!.isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Car Model'),
                    const SizedBox(height: 10),

                    /// =========== DROPDOWN ================
                    GestureDetector(
                      onTap: () {
                        setState(() => carModelError = null);
                        _showCarModelBottomSheet();
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
                            Icon(
                              Icons.car_rental,
                              color: hasError
                                  ? Colors.red.shade600
                                  : const Color(0xFF96C4FA),
                              size: 20,
                            ),
                            const SizedBox(width: 12),

                            /// Selected Value
                            Expanded(
                              child: Obx(() {
                                // Nested Obx to ensure selectedModel changes trigger rebuild
                                final currentModel = crpInventoryListController.selectedModel.value;
                                final carTypeText = _removeBracketText(currentModel?.carType);
                                return Text(
                                  carTypeText.isNotEmpty
                                      ? carTypeText
                                      : 'Select Car Model',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: hasError
                                        ? Colors.red.shade700
                                        : const Color(0xFF333333),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              }),
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

                    /// ====== ERROR MESSAGE =========
                  ],
                );
              }),
              // SizedBox(
              //   height: 16,
              // ),
              // _buildSectionLabel('Alternate Number '),
              // const SizedBox(height: 10),
              // TextFormField(
              //   controller: alternativeMobileNoController,
              //   keyboardType: TextInputType.phone,
              //   maxLength: 10,
              //   decoration: InputDecoration(
              //     hintText: '',
              //     hintStyle: const TextStyle(
              //       fontSize: 14,
              //       fontWeight: FontWeight.w400,
              //       color: Color(0xFF333333),
              //     ),
              //     prefixIcon: Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              //       child: Text('+91', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF585858)),),
              //     ),
              //     contentPadding: const EdgeInsets.symmetric(
              //         horizontal: 20, vertical: 17),
              //     enabledBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(35),
              //       borderSide:
              //       const BorderSide(color: Color(0xFFE2E2E2), width: 1),
              //     ),
              //     focusedBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(35),
              //       borderSide:
              //       const BorderSide(color: Color(0xFFE2E2E2), width: 1),
              //     ),
              //   ),
              //   style: const TextStyle(
              //     fontSize: 14,
              //     fontWeight: FontWeight.w400,
              //     color: Color(0xFF333333),
              //   ),
              // ),
              // const SizedBox(height: 20),
              // Divider(
              //   height: 1,
              //   color: Color(0xFFE6E6E6),
              // ),

              const SizedBox(height: 40),

              // View Cabs Button
              _buildModifyBookButton(),
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
    if (!_hasAppliedPreselection &&
        _preselectedRunTypeId != null &&
        allRunTypes.isNotEmpty) {
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
                  onTap: () async {
                    setState(() {
                      pickupLocationError = null;
                      _userHasInteracted = true;
                    });
                    await GoRouter.of(context).push(
                      AppRoutes.cprPickupSearch,
                      extra: {
                        'selectedPickupType': selectedPickupType,
                      },
                    );
                    // Ensure UI updates after returning from search screen
                    // Use post-frame callback to ensure reactive updates are processed
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    }
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
                  onTap: () async {
                    setState(() {
                      dropLocationError = null;
                      _userHasInteracted = true;
                    });
                    await GoRouter.of(context).push(
                      AppRoutes.cprDropSearch,
                      extra: {
                        'fromCrpHomeScreen': false,
                      },
                    );
                    // Ensure UI updates after returning from search screen
                    // Use post-frame callback to ensure reactive updates are processed
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    }
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
                              : 'Pick Up Date',
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
          const SizedBox(height: 20),
          // Drop Date Section
          _buildSectionLabel('Drop Date'),
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.calendar_today_rounded,
            label: selectedDropDateTime != null
                ? _formatDateTime(selectedDropDateTime!)
                : 'Select Drop Date & Time',
            errorText: dropDateError,
            onTap: () {
              setState(() {
                dropDateError = null;
              });
              _showCupertinoDateTimePicker(context, isPickup: false);
            },
          ),
          if (dropDateError != null) ...[
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

  int? runTypeIdForInventory() {
    final runTypes = runTypeController.runTypes.value?.runTypes ?? [];
    final selectedLabel = selectedPickupType?.trim();
    int? selectedId;
    if (selectedLabel != null && selectedLabel.isNotEmpty) {
      // Try exact (trimmed) match first
      selectedId = runTypes
          .firstWhereOrNull((item) => (item.run ?? '').trim() == selectedLabel)
          ?.runTypeID;
      // Fallback to case-insensitive match (guards against inconsistent API casing)
      selectedId ??= runTypes
          .firstWhereOrNull(
              (item) => (item.run ?? '').trim().toLowerCase() ==
                  selectedLabel.toLowerCase())
          ?.runTypeID;
    }
    final bookingId =
        crpBookingDetailsController.crpBookingDetailResponse.value?.runTypeID;
    final resolved = selectedId ?? _preselectedRunTypeId ?? bookingId;
    // #region agent log
    _agentLog(
      hypothesisId: 'A',
      location: 'cpr_modify_booking.dart:runTypeIdForInventory',
      message: 'Resolved RunTypeID for inventory',
      data: {
        'selectedPickupType': selectedPickupType,
        'runTypesCount': runTypes.length,
        'selectedId': selectedId,
        'preselectedRunTypeId': _preselectedRunTypeId,
        'bookingRunTypeId': bookingId,
        'resolvedRunTypeId': resolved,
      },
    );
    // #endregion
    return resolved;
  }

  /// Reloads car models when run type changes
  /// [explicitRunTypeId] - Optional explicit runTypeId to use (prevents timing issues)
  Future<void> _reloadCarModelsOnRunTypeChange({int? explicitRunTypeId}) async {
    // Ensure auth params are available (can be called from UI interactions)
    if (token == null || token!.isEmpty || user == null || user!.isEmpty) {
      await fetchParameter();
    }

    // Use explicit runTypeId if provided, otherwise resolve from current state
    final resolvedRunTypeId = explicitRunTypeId ?? runTypeIdForInventory();
    final earlyReturnReason = <String>[
      if (resolvedRunTypeId == null) 'resolvedRunTypeId_null',
      if (_lastFetchedInventoryRunTypeId == resolvedRunTypeId)
        'already_fetched_same_runTypeId',
    ];
    // #region agent log
    _agentLog(
      hypothesisId: 'B',
      location: 'cpr_modify_booking.dart:_reloadCarModelsOnRunTypeChange',
      message: 'Attempt reload car models',
      data: {
        'resolvedRunTypeId': resolvedRunTypeId,
        'explicitRunTypeId': explicitRunTypeId,
        'lastFetchedInventoryRunTypeId': _lastFetchedInventoryRunTypeId,
        'hasToken': (token != null && token!.isNotEmpty),
        'hasUser': (user != null && user!.isNotEmpty),
        'earlyReturnReason': earlyReturnReason,
      },
    );
    // #endregion
    if (resolvedRunTypeId == null) return;
    if (_lastFetchedInventoryRunTypeId == resolvedRunTypeId) return;

    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    final storedCorpId = await StorageServices.instance.read('crpId');

    // Prefer stored corp id (authoritative); branch id from widget (passed to screen)
    final corpId = storedCorpId ??
        crpBookingDetailsController
            .crpBookingDetailResponse.value?.corporateID
            ?.toString();

    if (corpId == null ||
        corpId.toString().isEmpty ||
        widget.branchId.isEmpty) {
      // #region agent log
      _agentLog(
        hypothesisId: 'B',
        location: 'cpr_modify_booking.dart:_reloadCarModelsOnRunTypeChange',
        message: 'Skipped reload due to missing corp/branch',
        data: {
          'corpIdNull': corpId == null,
          'branchIdEmpty': widget.branchId.isEmpty,
          'storedCorpId': storedCorpId,
        },
      );
      // #endregion
      return;
    }

    final Map<String, dynamic> inventoryParams = {
      'token': token,
      'user': user ?? email,
      'CorpID': corpId,
      'BranchID': widget.branchId,
      'RunTypeID': resolvedRunTypeId,
    };

    // #region agent log
    _agentLog(
      hypothesisId: 'B',
      location: 'cpr_modify_booking.dart:_reloadCarModelsOnRunTypeChange',
      message: 'Reload inventory params (corp/branch source)',
      data: {
        'corpIdForInventory': corpId,
        'branchIdForInventory': widget.branchId,
        'storedCorpId': storedCorpId,
      },
    );
    // #endregion

    // Clear selected model when changing runTypeId (old selection may not be valid)
    crpInventoryListController.selectedModel.value = null;
    
    try {
      await crpInventoryListController.fetchCarModels(inventoryParams, context,
          skipAutoSelection: true);
      
      // Only update last fetched ID AFTER successful fetch
      _lastFetchedInventoryRunTypeId = resolvedRunTypeId;
      
      // Reset prefill flag so it can reapply after models reload
      _hasAppliedCarModelPrefill = false;
      
      // #region agent log
      _agentLog(
        hypothesisId: 'B',
        location: 'cpr_modify_booking.dart:_reloadCarModelsOnRunTypeChange',
        message: 'Successfully reloaded car models',
        data: {
          'resolvedRunTypeId': resolvedRunTypeId,
          'modelsCount': crpInventoryListController.models.length,
          'lastFetchedInventoryRunTypeId': _lastFetchedInventoryRunTypeId,
        },
      );
      // #endregion
    } catch (e) {
      // If fetch fails, don't update last fetched ID so it can retry
      // #region agent log
      _agentLog(
        hypothesisId: 'B',
        location: 'cpr_modify_booking.dart:_reloadCarModelsOnRunTypeChange',
        message: 'Failed to reload car models',
        data: {
          'resolvedRunTypeId': resolvedRunTypeId,
          'lastFetchedInventoryRunTypeId': _lastFetchedInventoryRunTypeId,
          'error': e.toString(),
        },
      );
      // #endregion
      rethrow;
    }
  }

  void _showPickupTypeBottomSheet(List<String> pickupTypes) async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
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

                          print('pickup type : ${selectedPickupType}');
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              splashColor: Colors.transparent,
                              onTap: () async {
                                // Find the runTypeID for the selected pickup type BEFORE updating state
                                final runTypes = runTypeController.runTypes.value?.runTypes ?? [];
                                final normalizedPickupType = pickupType.trim();
                                int? selectedRunTypeId;
                                
                                // Try exact match first
                                selectedRunTypeId = runTypes
                                    .firstWhereOrNull((item) => (item.run ?? '').trim() == normalizedPickupType)
                                    ?.runTypeID;
                                
                                // Fallback to case-insensitive match
                                selectedRunTypeId ??= runTypes
                                    .firstWhereOrNull((item) => 
                                        (item.run ?? '').trim().toLowerCase() == normalizedPickupType.toLowerCase())
                                    ?.runTypeID;

                                // #region agent log
                                _agentLog(
                                  hypothesisId: 'F',
                                  location: 'cpr_modify_booking.dart:pickupType_onTap',
                                  message: 'User selected pickup type',
                                  data: {
                                    'pickupType': pickupType,
                                    'normalizedPickupType': normalizedPickupType,
                                    'selectedRunTypeId': selectedRunTypeId,
                                    'currentLastFetched': _lastFetchedInventoryRunTypeId,
                                    'allRunTypes': runTypes.map((rt) => {'run': rt.run, 'runTypeID': rt.runTypeID}).toList(),
                                  },
                                );
                                // #endregion

                                setState(() {
                                  _userHasInteracted = true;
                                  selectedPickupType = pickupType;
                                  pickupTypeError = null;
                                  _isPickupTypeExpanded = false;
                                });

                                // Reload car models when run type changes - pass explicit runTypeId
                                if (selectedRunTypeId != null) {
                                  await _reloadCarModelsOnRunTypeChange(explicitRunTypeId: selectedRunTypeId);
                                } else {
                                  // #region agent log
                                  _agentLog(
                                    hypothesisId: 'F',
                                    location: 'cpr_modify_booking.dart:pickupType_onTap',
                                    message: 'Warning: Could not resolve runTypeId, using fallback',
                                    data: {
                                      'pickupType': pickupType,
                                    },
                                  );
                                  // #endregion
                                  await _reloadCarModelsOnRunTypeChange();
                                }
                                _recomputeHasChanges();

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
                                      onChanged: (value) async {
                                        if (value == null) return;
                                        
                                        // Find the runTypeID for the selected pickup type BEFORE updating state
                                        final runTypes = runTypeController.runTypes.value?.runTypes ?? [];
                                        final normalizedValue = value.trim();
                                        int? selectedRunTypeId;
                                        
                                        // Try exact match first
                                        selectedRunTypeId = runTypes
                                            .firstWhereOrNull((item) => (item.run ?? '').trim() == normalizedValue)
                                            ?.runTypeID;
                                        
                                        // Fallback to case-insensitive match
                                        selectedRunTypeId ??= runTypes
                                            .firstWhereOrNull((item) => 
                                                (item.run ?? '').trim().toLowerCase() == normalizedValue.toLowerCase())
                                            ?.runTypeID;

                                        // #region agent log
                                        _agentLog(
                                          hypothesisId: 'F',
                                          location: 'cpr_modify_booking.dart:pickupType_Radio_onChanged',
                                          message: 'User selected pickup type via Radio',
                                          data: {
                                            'value': value,
                                            'normalizedValue': normalizedValue,
                                            'selectedRunTypeId': selectedRunTypeId,
                                            'currentLastFetched': _lastFetchedInventoryRunTypeId,
                                            'allRunTypes': runTypes.map((rt) => {'run': rt.run, 'runTypeID': rt.runTypeID}).toList(),
                                          },
                                        );
                                        // #endregion

                                        setState(() {
                                          _userHasInteracted = true;
                                          selectedPickupType = value;
                                          pickupTypeError = null;
                                          _isPickupTypeExpanded = false;
                                        });

                                        // Reload car models when run type changes - pass explicit runTypeId
                                        if (selectedRunTypeId != null) {
                                          await _reloadCarModelsOnRunTypeChange(explicitRunTypeId: selectedRunTypeId);
                                        } else {
                                          // #region agent log
                                          _agentLog(
                                            hypothesisId: 'F',
                                            location: 'cpr_modify_booking.dart:pickupType_Radio_onChanged',
                                            message: 'Warning: Could not resolve runTypeId, using fallback',
                                            data: {
                                              'value': value,
                                            },
                                          );
                                          // #endregion
                                          await _reloadCarModelsOnRunTypeChange();
                                        }
                                        _recomputeHasChanges();

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

    // Use selected date if it exists and is not in the past, otherwise use minimum date
    DateTime? currentSelectedDateTime =
        isPickup ? selectedPickupDateTime : selectedDropDateTime;
    DateTime tempDateTime = currentSelectedDateTime != null &&
            currentSelectedDateTime.isAfter(minimumDate) &&
            (!isPickup || currentSelectedDateTime.isAfter(now))
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
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        isPickup ? 'Choose Pickup time' : 'Choose Drop Time',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
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
                          'Cancel Booking',
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
                          setState(() {
                            _userHasInteracted = true;
                            if (isPickup) {
                              selectedPickupDateTime = tempDateTime;
                              pickupDateError = null;
                            } else {
                              selectedDropDateTime = tempDateTime;
                              dropDateError = null;
                            }
                          });
                          _recomputeHasChanges();
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

  /// Removes bracket text from car type (e.g., "Hyundai Accent[Intermediate]" -> "Hyundai Accent")
  String _removeBracketText(String? carType) {
    if (carType == null || carType.isEmpty) return '';
    final bracketIndex = carType.indexOf('[');
    if (bracketIndex == -1) return carType;
    return carType.substring(0, bracketIndex).trim();
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

  Widget _buildModifyBookButton() {
    return Obx(() {
      // Check if a car model is selected
      final hasCarModelSelected = crpInventoryListController.selectedModel.value != null;
      // Button is enabled only if there are changes AND a car model is selected
      final isEnabled = _hasChanges && hasCarModelSelected;
      
      return Row(
        children: [
          // Cancel Button
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _showCancelBookingDialog();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4082F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(39),
                  side: const BorderSide(color: Color(0xFF4082F1), width: 1.5),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Cancel Booking',
                style: TextStyle(
                  color: Color(0xFF4082F1),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Confirm Booking Button
          Expanded(
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.4,
              child: ElevatedButton(
                onPressed: isEnabled ? _handleModifyBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4082F1),
                  disabledBackgroundColor: const Color(0xFF4082F1),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(39),
                    side: const BorderSide(color: Color(0xFFD9D9D9), width: 1),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Modify Booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _handleModifyBooking() async {
    final CrpBookingHistoryController crpBookingHistoryController =
        Get.put(CrpBookingHistoryController());
    final bookingData =
        crpBookingDetailsController.crpBookingDetailResponse.value;
    if (bookingData == null) {
      CustomFailureSnackbar.show(context, 'Booking details not available');
      return;
    }

    await fetchParameter();
    if (token == null || user == null) {
      CustomFailureSnackbar.show(
          context, 'Session expired. Please login again');
      return;
    }

    final pickupAddress =
        crpSelectPickupController.selectedPlace.value?.primaryText ??
            crpSelectPickupController.searchController.text.trim();

    final dropAddress =
        crpSelectDropController.selectedPlace.value?.primaryText ??
            crpSelectDropController.searchController.text.trim();

    final carTypeID = crpInventoryListController.selectedModel.value?.makeId ??
        bookingData.makeID;

    final selectedRunTypeID = runTypeIdForInventory() ?? bookingData.runTypeID;

    final cabRequiredOn =
        selectedPickupDateTime ?? _parseDateTime(bookingData.cabRequiredOn);

    final formattedDateTime = cabRequiredOn != null
        ? DateFormat('yyyy-MM-ddTHH:mm:ss').format(cabRequiredOn)
        : '';

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    final Map<String, dynamic> params = {
      'OrderID': widget.orderId,
      'costCode': bookingData.costCode ?? '',
      'CabRequiredOn': formattedDateTime,
      'carTypeID': carTypeID?.toString() ?? '',
      'PickUpAddress':
          pickupAddress.isNotEmpty ? pickupAddress : bookingData.pickupAddress,
      'transNo': bookingData.transNo ?? '',
      'mobile': bookingData.mobile ?? '',
      'runTypeID': selectedRunTypeID?.toString() ?? '',
      'arrivalDetails': bookingData.arrivalDetails ?? '',
      'dropAddress':
          dropAddress.isNotEmpty ? dropAddress : bookingData.dropAddress,
      'specialInstructions': bookingData.specialInstructions ?? '',
      'uID': bookingData.uid?.toString() ?? '',
      'token': token!,
      'user': user ?? email,
    };

    if (!context.mounted) return;

    /// ✅ SHOW DIALOG ON ROOT NAVIGATOR
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response =
          await CprApiService().postRequestParamsNew<Map<String, dynamic>>(
        'PostEditBooking',
        params,
        (body) {
          if (body is String) {
            try {
              return Map<String, dynamic>.from(jsonDecode(body));
            } catch (_) {}
          }
          return Map<String, dynamic>.from(body as Map);
        },
        context,
      );

      /// ✅ CLOSE ONLY THE DIALOG (ROOT)
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final bStatus = response['bStatus'] as bool? ?? false;
      final sMessage = response['sMessage'] as String? ??
          (bStatus ? 'Successfully Modified' : 'Failed to modify booking');

      if (!context.mounted) return;

      if (bStatus) {
        CustomSuccessSnackbar.show(context, sMessage);
      } else {
        CustomFailureSnackbar.show(context, sMessage);
      }

      if (bStatus) {
        /// ✅ NAVIGATE BACK TO BOOKING SCREEN AND REFRESH DATA
        /// Navigate to bottom nav with booking tab (index 1) selected
        /// This ensures we're on the booking screen and data will be refreshed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            // Navigate to bottom nav with booking tab selected (index 1)
            GoRouter.of(context).push(
              AppRoutes.cprBottomNav,
              extra: {
                'initialIndex': 1, // Booking tab index
              },
            );
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        CustomFailureSnackbar.show(context, 'Error: $e');
      }
    }
  }

  Future<void> _handleCancelBooking() async {
    // Get booking details
    final bookingData =
        crpBookingDetailsController.crpBookingDetailResponse.value;
    if (bookingData == null) {
      CustomFailureSnackbar.show(context, 'Booking details not available');
      return;
    }

    // Ensure we have token and user
    await fetchParameter();
    if (token == null || user == null) {
      CustomFailureSnackbar.show(
          context, 'Session expired. Please login again');
      return;
    }

    // Get cancel reason - use selected reason or custom text for "others"
    String cancelReason;
    if (selectedCancelReason == 'others') {
      cancelReason = cancelReasonController.text.trim();
      if (cancelReason.isEmpty) {
        CustomFailureSnackbar.show(
            context, 'Please enter a reason for cancellation');
        return;
      }
    } else if (selectedCancelReason != null) {
      cancelReason = selectedCancelReason!;
    } else {
      CustomFailureSnackbar.show(
          context, 'Please select a reason for cancellation');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    // Build request parameters
    final Map<String, dynamic> params = {
      'OrderID': widget.orderId,
      'CancelReason': cancelReason,
      'CancelledBy': '0',
      'UID': bookingData.uid?.toString() ?? '',
      'token': token ?? '',
      'user': user ?? email,
    };

    debugPrint('📤 Cancel Booking Params: $params');

    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response =
          await CprApiService().postRequestParamsNew<Map<String, dynamic>>(
        'PostCancelBooking',
        params,
        (body) {
          // Handle string response that might be JSON
          if (body is String) {
            try {
              final decoded = jsonDecode(body);
              if (decoded is Map) {
                return Map<String, dynamic>.from(decoded);
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing string response: $e');
            }
          }

          if (body is Map) {
            return Map<String, dynamic>.from(body);
          }

          return {"response": body};
        },
        context,
      );

      // Close loading dialog - use rootNavigator: false to ensure we only close the dialog
      if (context.mounted) {
        final navigator = Navigator.of(context, rootNavigator: false);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }

      debugPrint('✅ Cancel Booking Response: $response');

      // Parse response to check bStatus
      final bStatus = response['bStatus'] as bool?;
      final sMessage = response['sMessage'] as String? ??
          (bStatus == true
              ? 'Successfully Cancelled.'
              : 'Failed to cancel booking');

      if (context.mounted) {
        if (bStatus == true) {
          // Show success message
          CustomSuccessSnackbar.show(context, sMessage,
              duration: const Duration(seconds: 2));

          // Clear cancel reason controller
          cancelReasonController.clear();

          // Navigate back to booking screen and refresh data after success
          // Navigate to bottom nav with booking tab (index 1) selected
          // This ensures we're on the booking screen and data will be refreshed
          Future.microtask(() {
            if (context.mounted) {
              // Navigate to bottom nav with booking tab selected (index 1)
              GoRouter.of(context).push(
                AppRoutes.cprBottomNav,
                extra: {
                  'initialIndex': 1, // Booking tab index
                },
              );
            }
          });
        } else {
          // Show error message
          CustomFailureSnackbar.show(context, sMessage,
              duration: const Duration(seconds: 3));
        }
      }
    } catch (e) {
      // Close loading dialog - use rootNavigator: false to ensure we only close the dialog
      if (context.mounted) {
        final navigator = Navigator.of(context, rootNavigator: false);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }

      // Show error message
      if (context.mounted) {
        CustomFailureSnackbar.show(context, 'Error: ${e.toString()}',
            duration: const Duration(seconds: 3));
      }

      debugPrint('❌ Error canceling booking: $e');
    }
  }

  Widget _buildRadioOption({
    required BuildContext context,
    required String title,
    required String value,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = selectedValue == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4082F1).withOpacity(0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4082F1) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Custom Radio Button
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4082F1)
                      : Colors.grey.shade400,
                  width: isSelected ? 2 : 1.5,
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4082F1),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelBookingDialog() {
    // Use local variables for dialog state
    String? localSelectedReason;
    final TextEditingController localCancelReasonController =
        TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async {
            // Dispose controller after frame to ensure widget tree is cleaned up
            WidgetsBinding.instance.addPostFrameCallback((_) {
              localCancelReasonController.dispose();
            });
            return true;
          },
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cancel Booking',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Please select a reason for cancellation',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  color: Colors.grey.shade600, size: 22),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      // Content Section - Scrollable
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 20,
                            bottom: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Custom Radio Options
                              _buildRadioOption(
                                context: context,
                                title: 'Driver is taking too long to arrive',
                                value: 'Driver is taking too long to arrive',
                                selectedValue: localSelectedReason,
                                onChanged: (value) {
                                  setDialogState(() {
                                    localSelectedReason = value;
                                    if (value != 'others') {
                                      localCancelReasonController.clear();
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildRadioOption(
                                context: context,
                                title: 'Change of travel plans',
                                value: 'Change of travel plans',
                                selectedValue: localSelectedReason,
                                onChanged: (value) {
                                  setDialogState(() {
                                    localSelectedReason = value;
                                    if (value != 'others') {
                                      localCancelReasonController.clear();
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildRadioOption(
                                context: context,
                                title: 'Booked by mistake',
                                value: 'Booked by mistake',
                                selectedValue: localSelectedReason,
                                onChanged: (value) {
                                  setDialogState(() {
                                    localSelectedReason = value;
                                    if (value != 'others') {
                                      localCancelReasonController.clear();
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildRadioOption(
                                context: context,
                                title: 'Others',
                                value: 'others',
                                selectedValue: localSelectedReason,
                                onChanged: (value) {
                                  setDialogState(() {
                                    localSelectedReason = value;
                                  });
                                },
                              ),
                              // Text input field - only show when "others" is selected
                              if (localSelectedReason == 'others') ...[
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: localCancelReasonController,
                                    autofocus: true,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: "Please specify your reason...",
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Footer Section with Buttons
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF4082F1),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                        color: Color(0xFF4082F1), width: 1.5),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Back',
                                  style: TextStyle(
                                    color: Color(0xFF4082F1),
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
                                  // Validate cancel reason
                                  if (localSelectedReason == null) {
                                    CustomFailureSnackbar.show(context,
                                        'Please select a reason for cancellation',
                                        duration: const Duration(seconds: 2));
                                    return;
                                  }
                                  if (localSelectedReason == 'others' &&
                                      localCancelReasonController.text
                                          .trim()
                                          .isEmpty) {
                                    CustomFailureSnackbar.show(context,
                                        'Please enter a reason for cancellation',
                                        duration: const Duration(seconds: 2));
                                    return;
                                  }
                                  // Save the values before closing
                                  final savedReason = localSelectedReason;
                                  final savedCustomText =
                                      localSelectedReason == 'others'
                                          ? localCancelReasonController.text
                                          : '';
                                  // Close dialog first
                                  Navigator.of(dialogContext).pop();
                                  // Update parent state after dialog closes using microtask
                                  Future.microtask(() {
                                    if (mounted) {
                                      setState(() {
                                        selectedCancelReason = savedReason;
                                        if (savedReason == 'others') {
                                          cancelReasonController.text =
                                              savedCustomText;
                                        } else {
                                          cancelReasonController.clear();
                                        }
                                      });
                                      // Call cancel booking API
                                      _handleCancelBooking();
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4082F1),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Confirm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
