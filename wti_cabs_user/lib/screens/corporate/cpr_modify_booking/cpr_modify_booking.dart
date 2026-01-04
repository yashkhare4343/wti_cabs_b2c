import 'dart:convert';
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
    this.initialCarModelName,
  });

  final String orderId;
  final String? initialCarModelName;

  @override
  State<CprModifyBooking> createState() => _CprModifyBookingState();
}

class _CprModifyBookingState extends State<CprModifyBooking> {
  final GenderController controller = Get.put(GenderController());
  final CarProviderController carProviderController =
      Get.put(CarProviderController());
  final CrpBookingDetailsController crpBookingDetailsController =
      Get.put(CrpBookingDetailsController());
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());
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
    if (guestId == null || guestId!.isEmpty || guestId == '0' || guestId == 'null') {
      if (loginGuestId != null && loginGuestId != 0) {
        guestId = loginGuestId.toString();
        await StorageServices.instance.save('guestId', guestId??'');
      }
    }
  }

  @override
  void initState() {
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

    // 3. Now call payment modes safely
    final Map<String, dynamic> paymentParams = {
      'GuestID': int.parse(guestId ?? ''),
      'token': token,
      'user': user ?? email
    };

    // Prefer the user-selected run type; fallback to booking-detail RunTypeID
    int? runTypeIdForInventory() {
      final runTypes = runTypeController.runTypes.value?.runTypes ?? [];
      final selectedId = runTypes
          .firstWhereOrNull((item) => item.run == selectedPickupType)
          ?.runTypeID;
      return selectedId ??
          _preselectedRunTypeId ??
          crpBookingDetailsController.crpBookingDetailResponse.value?.runTypeID;
    }

    final Map<String, dynamic> inventoryParams = {
      'token': token,
      'user': user??email,
      'CorpID': crpBookingDetailsController
          .crpBookingDetailResponse.value?.corporateID,
      'BranchID':
          crpBookingDetailsController.crpBookingDetailResponse.value?.branchID,
      'RunTypeID': runTypeIdForInventory()
    };

    paymentModeController.fetchPaymentModes(paymentParams, context);
    controller.fetchGender(context);
    // Skip auto-selection so we can preselect based on booking details
    crpInventoryListController.fetchCarModels(inventoryParams, context, skipAutoSelection: true);
  }

  void _initPrefillListeners() {
    ever<dynamic>(crpBookingDetailsController.crpBookingDetailResponse, (_) {
      _applyPrefilledFields();
      _applyPrefilledSelectionsIfReady();
      // Also try to apply car model prefill when booking details are loaded
      _applyCarModelPrefill();
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

  final params = {
    'CorpID': StorageServices.instance.read('crpId'),
    'BranchID': StorageServices.instance.read('branchId')
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
                          crpInventoryListController.updateSelected(item);
                          Navigator.pop(context);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.carType ?? '',
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
  }

  /// Prefill car model in dropdown using the passed car model name (if any)
  /// or makeID from booking details response
  void _applyCarModelPrefill() {
    if (_hasAppliedCarModelPrefill) return;

    final models = crpInventoryListController.models;
    if (models.isEmpty) return;

    CrpCarModel? matchedModel;

    // First, try to match by makeID from booking details response (more reliable)
    final bookingDetails = crpBookingDetailsController.crpBookingDetailResponse.value;
    if (bookingDetails?.makeID != null) {
      matchedModel = models.firstWhereOrNull(
        (m) => m.makeId == bookingDetails!.makeID,
      );
      if (matchedModel != null) {
        crpInventoryListController.updateSelected(matchedModel);
        _hasAppliedCarModelPrefill = true;
        debugPrint('✅ Car model preselected by makeID: ${matchedModel.carType}');
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
          (m) => (m.carType ?? '').trim().toLowerCase().contains(normalizedTarget) ||
                 normalizedTarget.contains((m.carType ?? '').trim().toLowerCase()),
        );
      }

      if (matchedModel != null) {
        crpInventoryListController.updateSelected(matchedModel);
        _hasAppliedCarModelPrefill = true;
        debugPrint('✅ Car model preselected by name: ${matchedModel.carType}');
      } else {
        debugPrint('⚠️ Could not find car model matching: $targetName');
        debugPrint('Available models: ${models.map((m) => m.carType).toList()}');
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

  final TextEditingController alternativeMobileNoController = TextEditingController();
  final TextEditingController cancelReasonController = TextEditingController();

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
    alternativeMobileNoController.dispose();
    cancelReasonController.dispose();
    super.dispose();
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
            padding: const EdgeInsets.only(left: 20, right: 20, top: 14, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup type skeleton
                _buildShimmerContainer(height: 50, radius: 30),
                const SizedBox(height: 20),
                // Location section skeleton
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

    crpSelectPickupController.searchController.text =
        crpSelectPickupController.selectedPlace.value?.primaryText ?? '';
    crpSelectDropController.searchController.text =
        crpSelectDropController.selectedPlace.value?.primaryText ?? '';
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
                              child: Text(
                                crpInventoryListController
                                        .selectedModel.value?.carType ??
                                    'Select Car Model',
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

                    /// ====== ERROR MESSAGE =========
                  ],
                );
              }),
              SizedBox(
                height: 16,
              ),
              _buildSectionLabel('Alternate Number '),
              const SizedBox(height: 10),
              TextFormField(
                controller: alternativeMobileNoController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF333333),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Text('+91', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF585858)),),
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
              const SizedBox(height: 20),
              Divider(
                height: 1,
                color: Color(0xFFE6E6E6),
              ),

              const SizedBox(height: 40),

              // View Cabs Button
              _buildModifyBookButton(),
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
            offset: Offset(0, 1),     // x: 0px, y: 1px
            blurRadius: 3,            // blur: 3px
            spreadRadius: 0,          // spread: 0px
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
                        displayText = 'Enter drop location (optional)';
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
                                selectedPickupType ??
                                    crpBookingDetailsController
                                        .crpBookingDetailResponse
                                        .value
                                        ?.runTypeID
                                        .toString() ??
                                    '',
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
    final selectedId = runTypes
        .firstWhereOrNull((item) => item.run == selectedPickupType)
        ?.runTypeID;
    return selectedId ??
        _preselectedRunTypeId ??
        crpBookingDetailsController.crpBookingDetailResponse.value?.runTypeID;
  }

  void _showPickupTypeBottomSheet(List<String> pickupTypes) async{
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



                                          final Map<String, dynamic>
                                              inventoryParams = {
                                            'token': token,
                                            'user': user??email,
                                            'CorpID':
                                                crpBookingDetailsController
                                                    .crpBookingDetailResponse
                                                    .value
                                                    ?.corporateID,
                                            'BranchID':
                                                crpBookingDetailsController
                                                    .crpBookingDetailResponse
                                                    .value
                                                    ?.branchID,
                                            'RunTypeID': runTypeIdForInventory()
                                          };

                                          crpInventoryListController
                                              .fetchCarModels(
                                                  inventoryParams, context, skipAutoSelection: true);
                                          // Reset prefill flag so it can reapply after models reload
                                          _hasAppliedCarModelPrefill = false;
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
                        isPickup
                            ? 'Choose Pickup time'
                            : 'Choose Drop Time',
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
                            if (isPickup) {
                              selectedPickupDateTime = tempDateTime;
                              pickupDateError = null;
                            } else {
                              selectedDropDateTime = tempDateTime;
                              dropDateError = null;
                            }
                          });
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

  Widget _buildModifyBookButton() {
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
              'Cancel',
              style: TextStyle(
                color: Color(0xFF4082F1),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Confirm Booking Button
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _handleModifyBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4082F1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(39),
                side: const BorderSide(color: Color(0xFFD9D9D9), width: 1),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Confirm Booking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleModifyBooking() async {
    final bookingData = crpBookingDetailsController.crpBookingDetailResponse.value;
    if (bookingData == null) {
      CustomFailureSnackbar.show(context, 'Booking details not available');
      return;
    }

    await fetchParameter();
    if (token == null || user == null) {
      CustomFailureSnackbar.show(context, 'Session expired. Please login again');
      return;
    }

    final pickupAddress =
        crpSelectPickupController.selectedPlace.value?.primaryText ??
            crpSelectPickupController.searchController.text.trim();

    final dropAddress =
        crpSelectDropController.selectedPlace.value?.primaryText ??
            crpSelectDropController.searchController.text.trim();

    final carTypeID =
        crpInventoryListController.selectedModel.value?.makeId ??
            bookingData.makeID;

    final selectedRunTypeID =
        runTypeIdForInventory() ?? bookingData.runTypeID;

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
        /// ✅ NAVIGATE AFTER FRAME (SAFE WITH GOROUTER)
        /// Pop with result true to trigger refresh in parent screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            GoRouter.of(context).pop(true);
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
    final bookingData = crpBookingDetailsController.crpBookingDetailResponse.value;
    if (bookingData == null) {
      CustomFailureSnackbar.show(context, 'Booking details not available');
      return;
    }

    // Ensure we have token and user
    await fetchParameter();
    if (token == null || user == null) {
      CustomFailureSnackbar.show(context, 'Session expired. Please login again');
      return;
    }

    // Get cancel reason
    final cancelReason = cancelReasonController.text.trim();
    if (cancelReason.isEmpty) {
      CustomFailureSnackbar.show(context, 'Please enter a reason for cancellation');
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
      final response = await CprApiService().postRequestParamsNew<Map<String, dynamic>>(
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
                      (bStatus == true ? 'Successfully Cancelled.' : 'Failed to cancel booking');

      if (context.mounted) {
        if (bStatus == true) {
          // Show success message
          CustomSuccessSnackbar.show(context, sMessage, duration: const Duration(seconds: 2));

          
          // Clear cancel reason controller
          cancelReasonController.clear();
          
          // Navigate back after success - use microtask to ensure dialog is fully closed
          // Pop with result true to trigger refresh in parent screen
          Future.microtask(() {
            if (context.mounted) {
              // Pop modify screen with result true to trigger refresh
              GoRouter.of(context).pop(true);
            }
          });
        } else {
          // Show error message
          CustomFailureSnackbar.show(context, sMessage, duration: const Duration(seconds: 3));
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
        CustomFailureSnackbar.show(context, 'Error: ${e.toString()}', duration: const Duration(seconds: 3));
      }

      debugPrint('❌ Error canceling booking: $e');
    }
  }

  void _showCancelBookingDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Cancel This Booking?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 20),
                // Text input field
                TextField(
                  controller: cancelReasonController,
                  decoration: InputDecoration(
                    hintText: 'Tell us why you’re cancelling',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF000000),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    // Cancel button (left, outlined style like Cancel button at bottom)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
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
                          'Back',
                          style: TextStyle(
                            color: Color(0xFF4082F1),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cancel Booking button (right, filled style like Confirm Booking button)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate cancel reason
                          if (cancelReasonController.text.trim().isEmpty) {
                            CustomFailureSnackbar.show(context, 'Please enter a reason for cancellation', duration: const Duration(seconds: 2));
                            return;
                          }
                          // Close dialog first
                          Navigator.of(context).pop();
                          // Call cancel booking API
                          _handleCancelBooking();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4082F1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(39),
                            side: const BorderSide(color: Color(0xFFD9D9D9), width: 1),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
