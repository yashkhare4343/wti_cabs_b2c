import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_select_drop_controller/crp_select_drop_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_select_pickup_controller/crp_select_pickup_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/select_location/select_drop.dart';
import '../../../../common_widget/textformfield/booking_textformfield.dart';
import '../../../../utility/constants/colors/app_colors.dart';
import '../../../../utility/constants/fonts/common_fonts.dart';
import '../../../core/controller/corporate/crp_gender/crp_gender_controller.dart';
import '../../../core/controller/corporate/crp_car_provider/crp_car_provider_controller.dart';
import '../../../core/controller/corporate/crp_payment_mode_controller/crp_payment_mode_controller.dart';
import '../../../core/controller/corporate/crp_services_controller/crp_sevices_controller.dart';
import '../../../core/model/corporate/crp_gender_response/crp_gender_response.dart';
import '../../../core/model/corporate/crp_car_provider_response/crp_car_provider_response.dart';
import '../../../core/model/corporate/crp_payment_method/crp_payment_mode.dart';
import '../../../core/model/corporate/crp_services/crp_services_response.dart';
import '../../../core/model/corporate/crp_booking_data/crp_booking_data.dart';
import '../../../core/model/booking_engine/suggestions_places_response.dart';
import '../../../core/services/storage_services.dart';

class CprBookingEngine extends StatefulWidget {
  const CprBookingEngine({super.key});

  @override
  State<CprBookingEngine> createState() => _CprBookingEngineState();
}

class _CprBookingEngineState extends State<CprBookingEngine> {
  final GenderController controller = Get.put(GenderController());
  final CarProviderController carProviderController = Get.put(CarProviderController());

  String? guestId, token, user;
  int? selectedTabIndex;
  int? _preselectedRunTypeId;
  bool _hasAppliedPreselection = false;

  Future<void> fetchParameter() async {
    guestId = await StorageServices.instance.read('branchId');
    token = await StorageServices.instance.read('crpKey');
    user = await StorageServices.instance.read('email');
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadPreselectedRunType();
    _loadSelectedTabIndex();
    runTypesAndPaymentModes();
    _prefillPickupFromCurrentLocation();
  }

  void runTypesAndPaymentModes() async {
    // 1. Fetch Run Types
    runTypeController.fetchRunTypes(params, context);

    // 2. Wait for guestId, token, user
    await fetchParameter();

    // 3. Now call payment modes safely
    final Map<String, dynamic> paymentParams = {
      'GuestID': int.parse(guestId??''),
      'token' : token,
      'user' : user
    };

    paymentModeController.fetchPaymentModes(paymentParams, context);
    controller.fetchGender(context);
    carProviderController.fetchCarProviders(context);

  }

  Future<void> _loadPreselectedRunType() async {
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

  final CrpServicesController runTypeController = Get.put(CrpServicesController());
  final CrpSelectPickupController crpSelectPickupController = Get.put(CrpSelectPickupController());
  final CrpSelectDropController crpSelectDropController = Get.put(CrpSelectDropController());
  final paymentModeController = Get.put(PaymentModeController());


  String? selectedPickupType;
  String? selectedBookingFor;
  String? selectedPaymentMethod;

  final params = {
    'CorpID' : StorageServices.instance.read('crpId'),
    'BranchID' : StorageServices.instance.read('branchId')
  };

  /// Prefill pickup with current location (name + lat/lng) if available.
  /// Uses the same stored values as the personal cab flow (`sourceTitle`, `sourceLat`, `sourceLng`).
  Future<void> _prefillPickupFromCurrentLocation() async {
    try {
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

  Future<void> _loadSelectedTabIndex() async {
    final tabIndexStr = await StorageServices.instance.read('tabIndex');
    if (tabIndexStr == null) return;

    final idx = int.tryParse(tabIndexStr);
    if (idx == null) return;

    if (!mounted) return;

    setState(() {
      selectedTabIndex = idx;
    });
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

  final TextEditingController referenceNumberController = TextEditingController();
  final TextEditingController specialInstructionController = TextEditingController();
  final TextEditingController costCodeController = TextEditingController();
  final TextEditingController flightDetailsController = TextEditingController();

  final List<String> bookingForList = ['Myself', 'Corporate'];
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
    referenceNumberController.dispose();
    specialInstructionController.dispose();
    costCodeController.dispose();
    flightDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    crpSelectPickupController.searchController.text = crpSelectPickupController.selectedPlace.value?.primaryText ?? '';
    crpSelectDropController.searchController.text = crpSelectDropController.selectedPlace.value?.primaryText ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Book a Cab',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs Section
              Obx(() => _buildTabsSection()),
              const SizedBox(height: 28),
              // Location Input Section
              _buildLocationSection(),
              const SizedBox(height: 24),
              // Pick Up Date and Drop Date Buttons
              _buildDateButtons(),
              // Pick Up Type Button (only if runTypeList > 3)
              Obx(() => _buildConditionalPickUpTypeButton()),
              const SizedBox(height: 20),
              // Booking For
              _buildSectionLabel('Booking Type'),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: bookingTypeError != null
                            ? Colors.red.shade400
                            : Colors.grey.shade300,
                        width: bookingTypeError != null ? 2 : 1.5,
                      ),
                      boxShadow: bookingTypeError != null
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBookingFor,
                        isExpanded: true,
                        hint: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.mainButtonBg.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: bookingTypeError != null
                                    ? Colors.red.shade600
                                    : AppColors.mainButtonBg,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Select Booking Type',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: bookingTypeError != null
                                    ? Colors.red.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        selectedItemBuilder: (BuildContext context) {
                          return bookingForList.map((bookingFor) {
                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.mainButtonBg.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: bookingTypeError != null
                                        ? Colors.red.shade600
                                        : AppColors.mainButtonBg,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    bookingFor,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: bookingTypeError != null
                                          ? Colors.red.shade700
                                          : const Color(0xFF1A1A1A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: bookingTypeError != null
                              ? Colors.red.shade400
                              : Colors.grey.shade600,
                          size: 24,
                        ),
                        dropdownColor: Colors.white,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: bookingTypeError != null
                              ? Colors.red.shade700
                              : const Color(0xFF1A1A1A),
                        ),
                        items: bookingForList.map((bookingFor) {
                          return DropdownMenuItem<String>(
                            value: bookingFor,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                bookingFor,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedBookingFor = value;
                            bookingTypeError = null;
                          });
                        },
                      ),
                    ),
                  ),
                  if (bookingTypeError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
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
                  ],
                ],
              ),
              const SizedBox(height: 20),
              // Payment Controller
              Obx(() {
                if (paymentModeController.isLoading.value) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainButtonBg),
                      ),
                    ),
                  );
                }

                final list = paymentModeController.modes;

                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "No Payment Modes Found",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final hasError = paymentModeError != null && paymentModeError!.isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Payment Mode'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasError ? Colors.red.shade400 : Colors.grey.shade300,
                          width: hasError ? 2 : 1.5,
                        ),
                        color: Colors.white,
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
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentModeItem>(
                          value: paymentModeController.selectedMode.value,
                          isExpanded: true,
                          style: TextStyle(
                            color: hasError ? Colors.red.shade700 : const Color(0xFF1A1A1A),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          hint: Text(
                            'Select Payment Mode',
                            style: TextStyle(
                              fontSize: 15,
                              color: hasError ? Colors.red.shade400 : Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          items: list.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(
                                item.mode ?? "",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            );
                          }).toList(),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: hasError ? Colors.red.shade400 : Colors.grey.shade600,
                            size: 24,
                          ),
                          onChanged: (value) {
                            setState(() {
                              paymentModeError = null;
                            });
                            paymentModeController.updateSelected(value);
                          },
                        ),
                      ),
                    ),
                    if (paymentModeError != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
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
              const SizedBox(height: 20),

              // Gender
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Gender'),
                  const SizedBox(height: 10),
                  Obx(() {
                    final hasError = genderError != null && genderError!.isNotEmpty;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasError ? Colors.red.shade400 : Colors.grey.shade300,
                          width: hasError ? 2 : 1.5,
                        ),
                        color: Colors.white,
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
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<GenderModel>(
                          value: _getValidGenderValue(
                            controller.selectedGender.value,
                            controller.genderList,
                          ),
                          isExpanded: true,
                          style: TextStyle(
                            color: hasError ? Colors.red.shade700 : const Color(0xFF1A1A1A),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          hint: Text(
                            'Select Gender',
                            style: TextStyle(
                              fontSize: 15,
                              color: hasError ? Colors.red.shade400 : Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          items: controller.genderList.map((item) {
                            return DropdownMenuItem<GenderModel>(
                              value: item,
                              child: Text(
                                item.gender ?? "",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            );
                          }).toList(),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: hasError ? Colors.red.shade400 : Colors.grey.shade600,
                            size: 24,
                          ),
                          onChanged: (value) {
                            setState(() {
                              genderError = null;
                            });
                            controller.selectGender(value);
                          },
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
                          Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
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

              const SizedBox(height: 20),

              // Car Provider
              Obx(() {
                if (carProviderController.isLoading.value) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainButtonBg),
                      ),
                    ),
                  );
                }

                final list = carProviderController.carProviderList;

                if (list.isEmpty) {
                  return const SizedBox.shrink();
                }

                final hasError = carProviderError != null && carProviderError!.isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Car Provider'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasError ? Colors.red.shade400 : Colors.grey.shade300,
                          width: hasError ? 2 : 1.5,
                        ),
                        color: Colors.white,
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
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CarProviderModel>(
                          value: _getValidCarProviderValue(
                            carProviderController.selectedCarProvider.value,
                            list,
                          ),
                          isExpanded: true,
                          style: TextStyle(
                            color: hasError ? Colors.red.shade700 : const Color(0xFF1A1A1A),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          hint: Text(
                            'Select Car Provider',
                            style: TextStyle(
                              fontSize: 15,
                              color: hasError ? Colors.red.shade400 : Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          items: list.map((item) {
                            return DropdownMenuItem<CarProviderModel>(
                              value: item,
                              child: Text(
                                item.providerName ?? "",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            );
                          }).toList(),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: hasError ? Colors.red.shade400 : Colors.grey.shade600,
                            size: 24,
                          ),
                          onChanged: (value) {
                            setState(() {
                              carProviderError = null;
                            });
                            carProviderController.selectCarProvider(value);
                          },
                        ),
                      ),
                    ),
                    if (carProviderError != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
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

              const SizedBox(height: 12),

              // Additional Options
              _buildAdditionalOptionsAccordion(),
              const SizedBox(height: 32),

              // View Cabs Button
              _buildViewCabsButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabsSection() {
    final List<RunTypeItem> allRunTypes = runTypeController.runTypes.value?.runTypes ?? [];
    final List<String> allTabs = allRunTypes.map((val) => val.run ?? '').toList();
    // Apply preselected run type (from home screen tap) once when data is available
    if (!_hasAppliedPreselection &&
        _preselectedRunTypeId != null &&
        allRunTypes.isNotEmpty) {
      final index = allRunTypes.indexWhere((rt) => rt.runTypeID == _preselectedRunTypeId);
      if (index != -1 && allTabs.isNotEmpty) {
        // If 3 or fewer run types, we highlight the corresponding tab by index
        if (allRunTypes.length <= 3) {
          selectedTabIndex = index.clamp(0, allTabs.length - 1);
        } else {
          // For more than 3, we will highlight via pickup type dropdown instead
          selectedPickupType = allRunTypes[index].run;
        }
      }
      _hasAppliedPreselection = true;
    }
    
    // Show loading or empty state if no tabs
    if (runTypeController.isLoading.value) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainButtonBg),
          ),
        ),
      );
    }
    
    if (allTabs.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // All tabs
          ...List.generate(allTabs.length > 3 ? 3 : allTabs.length, (index) {
            final isSelected = selectedTabIndex == index;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTabIndex = index;
                      pickupTypeError = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.mainButtonBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.mainButtonBg.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      allTabs[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pickupLocationError != null || dropLocationError != null
              ? Colors.red.shade300
              : Colors.grey.shade200,
          width: pickupLocationError != null || dropLocationError != null ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical line with icons
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.mainButtonBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mainButtonBg.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.mainButtonBg.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.mainButtonBg,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mainButtonBg.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Text fields
          Expanded(
            child: Column(
              children: [
                 BookingTextFormField(
                  hintText: 'Enter Pickup Location',
                  controller: crpSelectPickupController.searchController,
                  errorText: pickupLocationError,
                  onTap: () {
                    setState(() {
                      pickupLocationError = null;
                    });
                    GoRouter.of(context).push(AppRoutes.cprSelectPickup);
                  },
                ),
                const SizedBox(height: 12),
                BookingTextFormField(
                  hintText: 'Enter drop location',
                  controller: crpSelectDropController.searchController,
                  errorText: dropLocationError,
                  onTap: () {
                    setState(() {
                      dropLocationError = null;
                    });
                    GoRouter.of(context).push(AppRoutes.cprSelectDrop);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Plus icon button
          // Padding(
          //   padding: const EdgeInsets.only(top: 4),
          //   child: GestureDetector(
          //     onTap: () {
          //       // Handle add location
          //     },
          //     child: Container(
          //       width: 36,
          //       height: 36,
          //       decoration: BoxDecoration(
          //         color: AppColors.mainButtonBg,
          //         shape: BoxShape.circle,
          //       ),
          //       child: const Icon(
          //         Icons.add,
          //         color: Colors.white,
          //         size: 20,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildDateButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pickup Date Section
        _buildSectionLabel('Pickup Date'),
        const SizedBox(height: 10),
        _buildActionButton(
          icon: Icons.calendar_today_rounded,
          label: selectedPickupDateTime != null
              ? _formatDateTime(selectedPickupDateTime!)
              : 'Select Pickup Date & Time',
          errorText: pickupDateError,
          onTap: () {
            setState(() {
              pickupDateError = null;
            });
            _showCupertinoDateTimePicker(context, isPickup: true);
          },
        ),
        if (pickupDateError != null) ...[
          const SizedBox(height: 6),
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

  Widget _buildConditionalPickUpTypeButton() {
    final List<RunTypeItem> allRunTypes = runTypeController.runTypes.value?.runTypes ?? [];
    
    // Only show if runTypeList > 3
    if (allRunTypes.length <= 3) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionLabel('Pick Up Type'),
        const SizedBox(height: 10),
        _buildPickUpTypeButton(),
      ],
    );
  }

  Widget _buildPickUpTypeButton() {
    final List<RunTypeItem> allRunTypes = runTypeController.runTypes.value?.runTypes ?? [];
    final List<String> allPickupTypes = allRunTypes.map((val) => val.run ?? '').toList();
    final hasError = pickupTypeError != null && pickupTypeError!.isNotEmpty;
    
    if (allPickupTypes.isEmpty) {
      return _buildActionButton(
        icon: Icons.description_outlined,
        label: 'Pick Up Type',
        errorText: pickupTypeError,
        onTap: () {},
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPickupType,
              isExpanded: true,
              hint: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.mainButtonBg.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: hasError ? Colors.red.shade600 : AppColors.mainButtonBg,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select Pick Up Type',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: hasError ? Colors.red.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              selectedItemBuilder: (BuildContext context) {
                return allPickupTypes.map((pickupType) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.mainButtonBg.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          color: hasError ? Colors.red.shade600 : AppColors.mainButtonBg,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pickupType,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: hasError ? Colors.red.shade700 : const Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: hasError ? Colors.red.shade400 : Colors.grey.shade600,
                size: 24,
              ),
              dropdownColor: Colors.white,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: hasError ? Colors.red.shade700 : const Color(0xFF1A1A1A),
              ),
              items: allPickupTypes.map((pickupType) {
                return DropdownMenuItem<String>(
                  value: pickupType,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      pickupType,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedPickupType = value;
                  pickupTypeError = null;
                });
              },
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

  void _showCupertinoDateTimePicker(BuildContext context, {required bool isPickup}) {
    final DateTime now = DateTime.now();
    final DateTime minimumDate = isPickup ? now : (selectedPickupDateTime ?? now);
    
    // Use selected date if it exists and is not in the past, otherwise use minimum date
    DateTime? currentSelectedDateTime = isPickup ? selectedPickupDateTime : selectedDropDateTime;
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
                        isPickup ? 'Select Pickup Date & Time' : 'Select Drop Date & Time',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
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
                  color: hasError ? Colors.red.shade700 : const Color(0xFF1A1A1A),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mainButtonBg.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.mainButtonBg,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Additional Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.3,
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
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.mainButtonBg, width: 2),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Cost Code Field
                  TextFormField(
                    controller: costCodeController,
                    decoration: InputDecoration(
                      hintText: 'Cost Code',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.mainButtonBg, width: 2),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Flight Details Field
                  TextFormField(
                    controller: flightDetailsController,
                    decoration: InputDecoration(
                      hintText: 'Flight Details',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.mainButtonBg, width: 2),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Special Instruction Field
                  TextFormField(
                    controller: specialInstructionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Special Instruction',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.mainButtonBg, width: 2),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainButtonBg.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _validateAndProceed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainButtonBg,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
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
      // Validate pickup date is not in the past
      if (selectedPickupDateTime!.isBefore(DateTime.now())) {
        pickupDateError = 'Pickup date and time cannot be in the past';
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

    // 6. Validate Drop Date is after Pickup Date (Required)
    if (selectedPickupDateTime != null && selectedDropDateTime != null) {
      if (selectedDropDateTime!.isBefore(selectedPickupDateTime!) ||
          selectedDropDateTime!.isAtSameMomentAs(selectedPickupDateTime!)) {
        dropDateError = 'Drop date and time must be after pickup date and time';
        errors.add(dropDateError!);
        hasValidationError = true;
      }
    }

    // 7. Validate Pickup Type (Required - conditional based on run types count)
    final List<RunTypeItem> allRunTypes = runTypeController.runTypes.value?.runTypes ?? [];
    if (allRunTypes.length > 3) {
      // If more than 3 run types, pickup type dropdown is shown and required
      if (selectedPickupType == null || selectedPickupType!.isEmpty) {
        pickupTypeError = 'Please select a pickup type';
        errors.add(pickupTypeError!);
        hasValidationError = true;
      } else {
        // Validate that selected pickup type exists in the run types list
        final pickupTypeExists = allRunTypes.any((runType) => runType.run == selectedPickupType);
        if (!pickupTypeExists) {
          pickupTypeError = 'Selected pickup type is invalid';
          errors.add(pickupTypeError!);
          hasValidationError = true;
        }
      }
    } else {
      // If 3 or fewer run types, validate that selectedTabIndex is valid
      if (selectedTabIndex! < 0 || selectedTabIndex! >= allRunTypes.length) {
        pickupTypeError = 'Please select a valid run type';
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

    // 9. Validate Payment Mode (Required)
    if (paymentModeController.selectedMode.value == null) {
      paymentModeError = 'Please select a payment mode';
      errors.add(paymentModeError!);
      hasValidationError = true;
    }

    // 10. Validate Gender (Required)
    if (controller.selectedGender.value == null) {
      genderError = 'Please select a gender';
      errors.add(genderError!);
      hasValidationError = true;
    }

    // 11. Validate Car Provider (Required)
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
    // Get the selected pickup type based on whether it's from dropdown or tabs
    final List<RunTypeItem> allRunTypes = runTypeController.runTypes.value?.runTypes ?? [];
    String? finalPickupType;
    
    if (allRunTypes.length > 3) {
      // If more than 3 run types, use selectedPickupType from dropdown
      finalPickupType = selectedPickupType;
    } else {
      // If 3 or fewer, use the selected tab index
      if (selectedTabIndex! >= 0 && selectedTabIndex! < allRunTypes.length) {
        finalPickupType = allRunTypes[selectedTabIndex??0].run;
      }
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
      selectedTabIndex: allRunTypes.length <= 3 ? selectedTabIndex : null,
    );

    // Navigate to inventory screen with booking data
    GoRouter.of(context).push(
      AppRoutes.cprInventory,
      extra: bookingData.toJson(),
    );
    print('All validations passed. Proceeding to view cabs...');
  }
}


