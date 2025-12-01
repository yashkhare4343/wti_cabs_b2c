import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/api/corporate/cpr_api_services.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_services_controller/crp_sevices_controller.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_booking_data/crp_booking_data.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_car_models/crp_car_models_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';
import 'package:wti_cabs_user/screens/corporate/crp_inventory/crp_inventory.dart';
import 'package:wti_cabs_user/screens/corporate/crp_booking_confirmation/crp_booking_result.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

class CrpBookingConfirmation extends StatefulWidget {
  final CrpCarModel? selectedCar;
  final CrpBookingData? bookingData;

  const CrpBookingConfirmation({
    super.key,
    this.selectedCar,
    this.bookingData,
  });

  @override
  State<CrpBookingConfirmation> createState() => _CrpBookingConfirmationState();
}

class _CrpBookingConfirmationState extends State<CrpBookingConfirmation> {
  String selectedTitle = 'Mr.';
  final List<String> titles = ['Mr.', 'Ms.', 'Mrs.'];
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController sourceController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  PhoneNumber number = PhoneNumber(isoCode: 'IN');
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.bookingData != null) {
      sourceController.text = widget.bookingData!.pickupPlace?.primaryText ?? '';
      destinationController.text = widget.bookingData!.dropPlace?.primaryText ?? '';
    }
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

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthName(dateTime.month);
    final year = dateTime.year;

    int hour = dateTime.hour % 12;
    hour = hour == 0 ? 12 : hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$day $month, $year, $hour:$minute $period';
  }

  String trimAfterTwoSpaces(String input) {
    final parts = input.split(' ');
    if (parts.length <= 2) return input;
    return parts.take(3).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.push(
            context,
            Platform.isIOS
                ? CupertinoPageRoute(
                    builder: (context) => CrpInventory(
                      bookingData: widget.bookingData?.toJson(),
                    ),
                  )
                : MaterialPageRoute(
                    builder: (context) => CrpInventory(
                      bookingData: widget.bookingData?.toJson(),
                    ),
                  ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBgPrimary1,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
                top: 12.0, left: 12.0, right: 12.0, bottom: 70),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _BookingTopBar(
                    bookingData: widget.bookingData,
                  ),
                  const SizedBox(height: 16),
                  _CarDetailsCard(
                    carModel: widget.selectedCar,
                  ),
                  const SizedBox(height: 16),
                  _InclusionsExclusionsCard(),
                  const SizedBox(height: 16),
                  _TravelerDetailsForm(
                    formKey: formKey,
                    selectedTitle: selectedTitle,
                    titles: titles,
                    onTitleChanged: (title) {
                      setState(() {
                        selectedTitle = title;
                      });
                    },
                    firstNameController: firstNameController,
                    emailController: emailController,
                    contactController: contactController,
                    sourceController: sourceController,
                    destinationController: destinationController,
                    number: number,
                    bookingData: widget.bookingData,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomSheet: _BottomBookNowBar(
          formKey: formKey,
          selectedCar: widget.selectedCar,
          bookingData: widget.bookingData,
          firstNameController: firstNameController,
          emailController: emailController,
          contactController: contactController,
          selectedTitle: selectedTitle,
        ),
      ),
    );
  }
}

class _BookingTopBar extends StatelessWidget {
  final CrpBookingData? bookingData;

  const _BookingTopBar({this.bookingData});

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

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthName(dateTime.month);
    final year = dateTime.year;

    int hour = dateTime.hour % 12;
    hour = hour == 0 ? 12 : hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$day $month, $year, $hour:$minute $period';
  }

  String trimAfterTwoSpaces(String input) {
    final parts = input.split(' ');
    if (parts.length <= 2) return input;
    return parts.take(3).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final pickupText = bookingData?.pickupPlace?.primaryText ?? '';
    final dropText = bookingData?.dropPlace?.primaryText ?? '';
    final routeText = dropText.isNotEmpty
        ? '${trimAfterTwoSpaces(pickupText)} to ${trimAfterTwoSpaces(dropText)}'
        : pickupText;
    final dateTimeText = formatDateTime(bookingData?.pickupDateTime);
    final tripType = bookingData?.pickupType ?? 'Outstation Round Trip';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrpInventory(
                  bookingData: bookingData?.toJson(),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 16, color: AppColors.mainButtonBg),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                routeText,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateTimeText,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.greyText5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tripType,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mainButtonBg),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CarDetailsCard extends StatelessWidget {
  final CrpCarModel? carModel;

  const _CarDetailsCard({this.carModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.greyBorder1, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car image
            Transform.translate(
              offset: const Offset(0, -5),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/inventory_car.png',
                      width: 70,
                      height: 45,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3F2FD),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      minimumSize: Size.zero,
                      side: const BorderSide(color: Colors.transparent, width: 1),
                      foregroundColor: const Color(0xFF1565C0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      carModel?.carType ?? 'Sedan',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    carModel?.carType ?? 'Suzuki Dzire',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text(
                        '4',
                        style: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.luggage_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text(
                        '2',
                        style: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text(
                        '2 hrs',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InclusionsExclusionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.greyBorder1, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inclusions Section
            Text(
              "Inclusions & Exclusions",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildInclusionItem(
              icon: Icons.check_circle,
              title: "Toll Charges, Parking Charges, State Tax & Driver Allowance includ",
            ),
            _buildInclusionItem(
              icon: Icons.check_circle,
              title: "Only One Pickup and Drop",
            ),
            _buildInclusionItem(
              icon: Icons.check_circle,
              title: "460 Kms included. ₹14.5/Km will be charged beyond that",
            ),
            _buildInclusionItem(
              icon: Icons.check_circle,
              title: "Waiting time upto 45 mins included. ₹100.00/30 mins after that",
            ),
            _buildInclusionItem(
              icon: Icons.check_circle,
              title: "Free cancellation till 1 hr before ride",
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // Navigate to policies
              },
              child: Row(
                children: [
                  Text(
                    "Policies",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainButtonBg,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.mainButtonBg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInclusionItem({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelerDetailsForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String selectedTitle;
  final List<String> titles;
  final Function(String) onTitleChanged;
  final TextEditingController firstNameController;
  final TextEditingController emailController;
  final TextEditingController contactController;
  final TextEditingController sourceController;
  final TextEditingController destinationController;
  final PhoneNumber number;
  final CrpBookingData? bookingData;

  const _TravelerDetailsForm({
    required this.formKey,
    required this.selectedTitle,
    required this.titles,
    required this.onTitleChanged,
    required this.firstNameController,
    required this.emailController,
    required this.contactController,
    required this.sourceController,
    required this.destinationController,
    required this.number,
    this.bookingData,
  });

  @override
  State<_TravelerDetailsForm> createState() => _TravelerDetailsFormState();
}

class _TravelerDetailsFormState extends State<_TravelerDetailsForm> {
  String? contact;
  String? contactCode;

  @override
  void initState() {
    super.initState();
    if (widget.bookingData != null) {
      widget.sourceController.text =
          widget.bookingData!.pickupPlace?.primaryText ?? '';
      widget.destinationController.text =
          widget.bookingData!.dropPlace?.primaryText ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.greyBorder1, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Travelers Details",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              /// Title Chips
              Row(
                children: widget.titles.map((title) {
                  final isSelected = widget.selectedTitle == title;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(title),
                      selected: isSelected,
                      selectedColor: AppColors.mainButtonBg,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: AppColors.mainButtonBg),
                      ),
                      showCheckmark: false,
                      onSelected: (_) => widget.onTitleChanged(title),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              /// Full Name
              _buildTextField(
                label: 'Full Name',
                hint: "Enter full name",
                controller: widget.firstNameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Full name is required";
                  }
                  return null;
                },
              ),

              /// Email
              _buildTextField(
                label: 'Email',
                hint: "Enter email id",
                controller: widget.emailController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Email is required";
                  }
                  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  return !regex.hasMatch(v.trim()) ? "Enter a valid email" : null;
                },
              ),

              /// Phone
              Text(
                'Phone',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: Row(
                  children: [
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: InternationalPhoneNumberInput(
                          selectorConfig: const SelectorConfig(
                            selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                            useBottomSheetSafeArea: true,
                            showFlags: true,
                          ),
                          selectorTextStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          initialValue: widget.number,
                          textFieldController: widget.contactController,
                          textStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          maxLength: 10,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Mobile number is required";
                            }
                            if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return "Enter valid 10-digit mobile number";
                            }
                            return null;
                          },
                          inputDecoration: const InputDecoration(
                            hintText: "Enter mobile number",
                            hintStyle: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                            counterText: "",
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          formatInput: false,
                          onInputChanged: (PhoneNumber value) async {
                            contact = (value.phoneNumber
                                    ?.replaceAll(' ', '')
                                    .replaceFirst(value.dialCode ?? '', '')) ??
                                '';
                            contactCode = value.dialCode?.replaceAll('+', '');
                            await StorageServices.instance.save('contactCode', contactCode ?? '');
                            await StorageServices.instance.save('contact', contact ?? '');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              /// Pickup Address
              _buildTextField(
                label: 'Pickup',
                hint: "Enter Pickup Address",
                controller: widget.sourceController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Pickup address is required";
                  }
                  return null;
                },
                isReadOnly: true,
              ),
              if (widget.sourceController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.yellow.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.yellow.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.sourceController.text,
                          style: TextStyle(fontSize: 10, color: Colors.yellow.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

              /// Dropping Address
              _buildTextField(
                label: 'Dropping Address',
                hint: "Enter Dropping Address",
                controller: widget.destinationController,
                validator: null,
                isReadOnly: true,
              ),
              if (widget.destinationController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.yellow.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.yellow.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.destinationController.text,
                          style: TextStyle(fontSize: 10, color: Colors.yellow.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool? isReadOnly,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black38),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            readOnly: isReadOnly ?? false,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint.toUpperCase(),
              hintStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.black54, width: 1.2),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}

class _BottomBookNowBar extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final CrpCarModel? selectedCar;
  final CrpBookingData? bookingData;
  final TextEditingController firstNameController;
  final TextEditingController emailController;
  final TextEditingController contactController;
  final String selectedTitle;

  const _BottomBookNowBar({
    required this.formKey,
    this.selectedCar,
    this.bookingData,
    required this.firstNameController,
    required this.emailController,
    required this.contactController,
    required this.selectedTitle,
  });

  @override
  State<_BottomBookNowBar> createState() => _BottomBookNowBarState();
}

class _BottomBookNowBarState extends State<_BottomBookNowBar> {
  bool isLoading = false;

  String _generateTransactionNumber() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'TXN$timestamp$randomNum';
  }

  String _formatDateTimeForAPI(DateTime? dateTime) {
    if (dateTime == null) return '';
    // Format: 2025-11-30T22:30:00
    return DateFormat('yyyy-MM-ddTHH:mm:ss').format(dateTime);
  }

  int? _getRunTypeID(String? pickupType) {
    if (pickupType == null) return null;
    
    try {
      final runTypeController = Get.find<CrpServicesController>();
      final runTypes = runTypeController.runTypes.value?.runTypes ?? [];
      
      for (final rt in runTypes) {
        if (rt.run?.toLowerCase() == pickupType.toLowerCase()) {
          return rt.runTypeID;
        }
      }
    } catch (e) {
      debugPrint('Error getting runTypeID: $e');
    }
    
    return null;
  }
  // show snackbar based on success / failure
  void showApiSnackBar(BuildContext context, dynamic response) {
    debugPrint("Parsed Response: $response");

    String codeStr = '';
    String message = '';

    // Case 1: API returned a single string like: "1, Your Booking has been successfully created..."
    if (response is String) {
      final cleaned = response.replaceAll('"', '').trim();
      final parts = cleaned.split(',');
      if (parts.isNotEmpty) {
        codeStr = parts.first.trim();
        if (parts.length > 1) {
          message = parts.sublist(1).join(',').trim();
        }
      }
    }

    // Case 2: Map response (existing behavior + support for "1, message" in a field)
    if (response is Map && (codeStr.isEmpty && message.isEmpty)) {
      final codeRaw = response['response'];
      codeStr = codeRaw?.toString().trim() ?? "";

      // If 'response' itself is a "1, message" style string, parse it
      if (codeRaw is String && codeRaw.contains(',')) {
        final cleaned = codeRaw.replaceAll('"', '').trim();
        final parts = cleaned.split(',');
        if (parts.isNotEmpty) {
          codeStr = parts.first.trim();
          if (parts.length > 1) {
            message = parts.sublist(1).join(',').trim();
          }
        }
      }

      // If message still empty, try common message keys
      if (message.isEmpty) {
        for (final key in ['message', 'Message', 'msg', 'Msg']) {
          if (response.containsKey(key) && response[key] != null) {
            final val = response[key].toString().trim();
            if (val.isNotEmpty) {
              message = val;
              break;
            }
          }
        }
      }

      // If still empty, try to infer from structure shown earlier:
      // {response: 1, Your Booking has been successfully created ...: ""}
      if (message.isEmpty) {
        for (final key in response.keys) {
          if (key is String &&
              key.trim().isNotEmpty &&
              key.toLowerCase() != 'response') {
            message = key.trim();
            break;
          }
        }
      }
    }

    // Final fallbacks
    message = message.isNotEmpty
        ? message
        : "Booking completed successfully";

    // Determine success:
    //  - response code is 1 or 2 (string or int), OR
    //  - message text clearly indicates success
    final lowerMsg = message.toLowerCase();
    final bool isSuccessByCode =
        (codeStr == '1' || codeStr == '2' || codeStr == '01' || codeStr == '02');
    final bool isSuccessByMessage =
        lowerMsg.contains('successfully') || lowerMsg.contains('success');

    final bool isSuccess = isSuccessByCode || isSuccessByMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrpBookingResultPage(
          isSuccess: isSuccess,
          message: message,
          bookingData: widget.bookingData,
          selectedCar: widget.selectedCar,
        ),
      ),
    );
  }


  Future<void> _makeBooking() async {
    if (widget.formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      try {
        // Get data from storage
        final corporateID = await StorageServices.instance.read('crpId') ?? '1';
        final branchID = await StorageServices.instance.read('branchId') ?? '1';
        final token = await StorageServices.instance.read('crpKey') ?? '';
        final user = await StorageServices.instance.read('email') ?? '';
        final uID = await StorageServices.instance.read('guestID') ?? '26142';
        final contactCode = await StorageServices.instance.read('contactCode') ?? '';
        final contact = await StorageServices.instance.read('contact') ?? widget.contactController.text.trim();

        // Get booking data
        final bookingData = widget.bookingData;
        final passengerName = '${widget.selectedTitle} ${widget.firstNameController.text.trim()}';
        final email = widget.emailController.text.trim();
        final mobile = contact.length == 10 ? contact : widget.contactController.text.trim();
        
        // Get runTypeID
        final runTypeID = _getRunTypeID(bookingData?.pickupType);
        
        // Format dates
        final cabRequiredOn = _formatDateTimeForAPI(bookingData?.pickupDateTime);
        final dropoffDatetime = _formatDateTimeForAPI(bookingData?.dropDateTime);
        
        // Get other data
        final genderID = bookingData?.gender?.genderID ?? 1;
        final carTypeID = widget.selectedCar?.makeId ?? 1;
        final providerID = bookingData?.carProvider?.providerID ?? 1;
        final payMode = bookingData?.paymentMode?.id ?? 1;
        final bookingType = bookingData?.bookingType == 'Corporate' ? '1' : '0';
        
        // Addresses
        final pickupAddress = bookingData?.pickupPlace?.primaryText ?? '';
        final dropAddress = bookingData?.dropPlace?.primaryText ?? '';
        
        // Coordinates
        final frmlat = bookingData?.pickupPlace?.latitude?.toString() ?? '0';
        final frmlng = bookingData?.pickupPlace?.longitude?.toString() ?? '0';
        final tolat = bookingData?.dropPlace?.latitude?.toString() ?? '0';
        final tolng = bookingData?.dropPlace?.longitude?.toString() ?? '0';
        
        // Optional fields
        final arrivalDetails = bookingData?.flightDetails ?? '';
        final specialInstructions = bookingData?.specialInstruction ?? '';
        final costCode = bookingData?.costCode ?? '';
        final remarks = bookingData?.referenceNumber ?? '';
        final transNo = '';
        
        // Build params
        final params = <String, dynamic>{
          'corporateID': corporateID,
          'passenger': passengerName,
          'email': email,
          'mobile': mobile,
          'gender': genderID.toString(),
          'cabRequiredOn': cabRequiredOn,
          'pickupCityID': branchID, // Default or get from place
          'carTypeID': carTypeID.toString(),
          'arrivalDetails': arrivalDetails,
          'pickupAddress': pickupAddress,
          'pickupContact': mobile,
          'dropoffDatetime': dropoffDatetime,
          'dropAddress': dropAddress,
          'specialInstructions': specialInstructions,
          'payMode': payMode.toString(),
          'bookingPassedBy': "",
          'branchID': branchID,
          'remarks': remarks,
          'uID': uID,
          'runTypeID': runTypeID?.toString() ?? '2',
          // 'costCode': costCode,
          'costCode': null,
          'packageID': "",
          'transNo': transNo,
          'providerID': providerID.toString(),
          'BookingType': bookingType,
          'frmlat': frmlat,
          'frmlng': frmlng,
          'tolat': tolat,
          'tolng': tolng,
          'token': token,
          'user': user,
        };

        debugPrint('📤 Making booking with params: $params');

        // Call API
        final apiService = CprApiService();
        final response = await apiService.postMakeBooking(params, context);

        debugPrint('✅ Booking response: $response');

        if (mounted) {
          // Show snackbar
          showApiSnackBar(context, response);
        }
      } catch (e) {
        debugPrint('❌ Booking error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Platform.isIOS
          ? const EdgeInsets.only(top: 8, bottom: 24, left: 12, right: 12)
          : const EdgeInsets.only(top: 8, bottom: 8, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : MainButton(
                text: 'BOOK NOW',
                onPressed: _makeBooking,
              ),
      ),
    );
  }
}


