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
import '../../../core/controller/corporate/crp_payment_mode_controller/crp_payment_mode_controller.dart';
import '../../../core/controller/corporate/crp_services_controller/crp_sevices_controller.dart';
import '../../../core/model/corporate/crp_payment_method/crp_payment_mode.dart';
import '../../../core/model/corporate/crp_services/crp_services_response.dart';
import '../../../core/services/storage_services.dart';

class CprBookingEngine extends StatefulWidget {
  const CprBookingEngine({super.key});

  @override
  State<CprBookingEngine> createState() => _CprBookingEngineState();
}

class _CprBookingEngineState extends State<CprBookingEngine> {
  String? guestId, token, user;
  Future<void> fetchParameter() async {
    guestId = await StorageServices.instance.read('branchId');
    token = await StorageServices.instance.read('crpKey');
    user = await StorageServices.instance.read('email');
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    runTypesAndPaymentModes();
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
  }

  final CrpServicesController runTypeController = Get.put(CrpServicesController());
  final CrpSelectPickupController crpSelectPickupController = Get.put(CrpSelectPickupController());
  final CrpSelectDropController crpSelectDropController = Get.put(CrpSelectDropController());
  final paymentModeController = Get.put(PaymentModeController());


  int selectedTabIndex = 0;
  String? selectedPickupType;
  String? selectedBookingFor;
  String? selectedPaymentMethod;

  final params = {
    'CorpID' : StorageServices.instance.read('crpId'),
    'BranchID' : StorageServices.instance.read('branchId')
  };

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

  final TextEditingController referenceNumberController = TextEditingController();
  final TextEditingController specialInstructionController = TextEditingController();

  final List<String> bookingForList = ['Myself', 'Corporate'];
  // final TextEditingController pickupController = TextEditingController();
  // final TextEditingController dropController = TextEditingController();



  @override
  void dispose() {
    // Note: crpSelectPickupController.searchController and crpSelectDropController.searchController
    // are managed by their respective GetX controllers and will be disposed in onClose()
    referenceNumberController.dispose();
    specialInstructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    crpSelectPickupController.searchController.text = crpSelectPickupController.selectedPlace.value?.primaryText ?? 'Please Select Pickup';
    crpSelectDropController.searchController.text = crpSelectDropController.selectedPlace.value?.primaryText ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Book a Cab',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs Section
              Obx(() => _buildTabsSection()),
              const SizedBox(height: 24),
              // Location Input Section
              _buildLocationSection(),
              const SizedBox(height: 24),
              // Pick Up Date and Drop Date Buttons
              _buildDateButtons(),
              // Pick Up Type Button (only if runTypeList > 3)
              Obx(() => _buildConditionalPickUpTypeButton()),
              // Booking For
              Row(
                children: [
                  Text('Booking Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),),
                ],
              ),
              SizedBox(height: 8,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: bookingTypeError != null ? Colors.red : const Color(0xFFE0E0E0),
                        width: bookingTypeError != null ? 1.5 : 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBookingFor,
                        isExpanded: true,
                        hint: Row(
                          children: [
                            Icon(
                              Icons.person_outline_outlined,
                              color: bookingTypeError != null ? Colors.red : AppColors.greyText3,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Booking Type',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: bookingTypeError != null ? Colors.red : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        selectedItemBuilder: (BuildContext context) {
                          return bookingForList.map((bookingFor) {
                            return Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  color: bookingTypeError != null ? Colors.red : AppColors.greyText3,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    bookingFor,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: bookingTypeError != null ? Colors.red : Colors.black87,
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
                          Icons.keyboard_arrow_down,
                          color: bookingTypeError != null ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        dropdownColor: Colors.white,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: bookingTypeError != null ? Colors.red : Colors.black87,
                        ),
                        items: bookingForList.map((bookingFor) {
                          return DropdownMenuItem<String>(
                            value: bookingFor,
                            child: Text(
                              bookingFor,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        bookingTypeError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Payment Controller
              Obx(() {
                if (paymentModeController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = paymentModeController.modes;

                if (list.isEmpty) {
                  return const Text("No Payment Modes Found");
                }

                final hasError = paymentModeError != null && paymentModeError!.isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Payment Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),),
                      ],
                    ),
                    SizedBox(height: 8,),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasError ? Colors.red : Colors.grey.shade400,
                          width: hasError ? 1.5 : 1,
                        ),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentModeItem>(
                          value: paymentModeController.selectedMode.value,
                          isExpanded: true,
                          style: TextStyle(
                            color: hasError ? Colors.red : Colors.black87,
                          ),
                          items: list.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item.mode ?? ""),
                            );
                          }).toList(),
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
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          paymentModeError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
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
    
    // Show loading or empty state if no tabs
    if (runTypeController.isLoading.value) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (allTabs.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // All tabs
              ...List.generate(allTabs.length > 3 ? 3 : allTabs.length, (index) {
                final isSelected = selectedTabIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTabIndex = index;
                        pickupTypeError = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.mainButtonBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        allTabs[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical line with icons
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.mainButtonBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                Container(
                  width: 3,
                  height: 60,
                  color: AppColors.mainButtonBg,
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.mainButtonBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.place,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Text fields
          Expanded(
            child: Column(
              children: [
                 BookingTextFormField(
                  hintText: '',
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
        Row(
          children: [
            Text('Pickup Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),),
          ],
        ),
        SizedBox(height: 8,),
        _buildActionButton(
          icon: Icons.access_time,
          label: selectedPickupDateTime != null
              ? _formatDateTime(selectedPickupDateTime!)
              : 'Pick Up Date',
          errorText: pickupDateError,
          onTap: () {
            setState(() {
              pickupDateError = null;
            });
            _showCupertinoDateTimePicker(context, isPickup: true);
          },
        ),
        if (pickupDateError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              pickupDateError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Drop Date Section
        Row(
          children: [
            Text('Drop Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),),
          ],
        ),
        SizedBox(height: 8,),
        _buildActionButton(
          icon: Icons.access_time,
          label: selectedDropDateTime != null
              ? _formatDateTime(selectedDropDateTime!)
              : 'Drop Date',
          errorText: dropDateError,
          onTap: () {
            setState(() {
              dropDateError = null;
            });
            _showCupertinoDateTimePicker(context, isPickup: false);
          },
        ),
        if (dropDateError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              dropDateError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConditionalPickUpTypeButton() {
    final List<RunTypeItem> allRunTypes = runTypeController.runTypes.value?.runTypes ?? [];
    
    // Only show if runTypeList > 3
    if (allRunTypes.length <= 3) {
      return const SizedBox.shrink();
    }
    
    return _buildPickUpTypeButton();
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red : const Color(0xFFE0E0E0),
              width: hasError ? 1.5 : 1,
            ),
          ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPickupType,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: hasError ? Colors.red : AppColors.greyText3,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Pick Up Type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: hasError ? Colors.red : Colors.black87,
                ),
              ),
            ],
          ),
          selectedItemBuilder: (BuildContext context) {
            return allPickupTypes.map((pickupType) {
              return Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: hasError ? Colors.red : AppColors.greyText3,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pickupType,
                      style: TextStyle(
                        fontSize: pickupType.length > 15 ? 10 : 12,
                        fontWeight: FontWeight.w500,
                        color: hasError ? Colors.red : Colors.black87,
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
            Icons.keyboard_arrow_down,
            color: hasError ? Colors.red : Colors.grey,
            size: 20,
          ),
          dropdownColor: Colors.white,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: hasError ? Colors.red : Colors.black87,
          ),
          items: allPickupTypes.map((pickupType) {
            return DropdownMenuItem<String>(
              value: pickupType,
              child: Text(
                pickupType,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
        )),
        if (pickupTypeError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              pickupTypeError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
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
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Done'),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError ? Colors.red : const Color(0xFFE0E0E0),
            width: hasError ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasError ? Colors.red : AppColors.greyText3, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: hasError ? Colors.red : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: hasError ? Colors.red : Colors.grey,
              size: 20,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: AppColors.greyText3, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Additional Options',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    isAdditionalOptionsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Expanded Content
          if (isAdditionalOptionsExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Reference Number Field
                  TextFormField(
                    controller: referenceNumberController,
                    decoration: InputDecoration(
                      hintText: 'Reference Number',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.greyText3,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Special Instruction Field
                  TextFormField(
                    controller: specialInstructionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Special Instruction',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.greyText3,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                      ),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _validateAndProceed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainButtonBg,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'View Cabs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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

    // 5. Validate Drop Date (Required)
    if (selectedDropDateTime == null) {
      dropDateError = 'Please select a drop date and time';
      errors.add(dropDateError!);
      hasValidationError = true;
    }

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
      if (selectedTabIndex < 0 || selectedTabIndex >= allRunTypes.length) {
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

    // Note: Reference Number and Special Instruction are optional fields
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
    // TODO: Implement the actual view cabs functionality
    // This is where you would navigate to the next screen or make API calls
    // with the validated data
    GoRouter.of(context).push(AppRoutes.cprInventory);
    print('All validations passed. Proceeding to view cabs...');
    // Example: GoRouter.of(context).push(AppRoutes.viewCabs);
  }
}

