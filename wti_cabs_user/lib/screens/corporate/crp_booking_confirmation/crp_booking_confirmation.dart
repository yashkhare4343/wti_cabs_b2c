import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/api/corporate/cpr_api_services.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_services_controller/crp_sevices_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/cpr_profile_controller/cpr_profile_controller.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_booking_data/crp_booking_data.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_car_models/crp_car_models_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/route_management/corporate_page_transitions.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';
import 'package:wti_cabs_user/common_widget/loader/shimmer/corporate_shimmer.dart';
import 'package:wti_cabs_user/common_widget/snackbar/custom_snackbar.dart';
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
  bool _showShimmer = true;
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
    // Show shimmer for 0.5 seconds
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showShimmer = false;
        });
      }
    });
    super.initState();
    _loadInitialData();
  }

  /// Shorten address-like text to keep UI clean.
  /// Adds ".." when truncated.
  String _shortenAddress(String text, {int maxChars = 40}) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars - 2)}..';
  }

  Future<void> _loadInitialData() async {
    if (widget.bookingData != null) {
      final pickupText = widget.bookingData!.pickupPlace?.primaryText ?? '';
      final dropText = widget.bookingData!.dropPlace?.primaryText ?? '';

      // Apply character limit so fields don't overflow UI
      sourceController.text = _shortenAddress(pickupText, maxChars: 40);
      destinationController.text = _shortenAddress(dropText, maxChars: 40);
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
    if (_showShimmer) {
      return const CorporateShimmer();
    }

    return PopScope(
      canPop: false,
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
                top: 12.0, left: 20.0, right: 20.0, bottom: 70),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                      child: RouteCard(bookingData: widget.bookingData)),
                  const SizedBox(height: 16),
                  _CarDetailsCard(
                    carModel: widget.selectedCar,
                  ),
                  // const SizedBox(height: 16),
                  // _InclusionsExclusionsCard(),
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
              CorporatePageTransitions.pushRoute(
                context,
                CrpInventory(
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

  const _CarDetailsCard({super.key, this.carModel});

  /// Extracts category from carType string like "Hyundai Accent[Intermediate]" -> "Intermediate"
  String? _extractCategory(String? carType) {
    if (carType == null || carType.isEmpty) return null;
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(carType);
    return match?.group(1);
  }

  /// Extracts car name from carType string like "Hyundai Accent[Intermediate]" -> "Hyundai Accent"
  String _extractCarName(String? carType) {
    if (carType == null || carType.isEmpty) return '';
    final bracketIndex = carType.indexOf('[');
    if (bracketIndex == -1) return carType;
    return carType.substring(0, bracketIndex).trim();
  }

  @override
  Widget build(BuildContext context) {
    final carName = _extractCarName(carModel?.carType);
    final category = _extractCategory(carModel?.carType);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x402B64E5), // #2B64E540
            offset: Offset(0, 1), // 0px 1px
            blurRadius: 3, // 3px blur
            spreadRadius: 0, // 0px spread
          ),
        ],
      ),
      child: Row(
        children: [
          // Car image
          SizedBox(
            width: 71,
            height: 51,
            child: Image.network(
              carModel?.carImageUrl ?? '',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Text details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car name and category in a row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        carName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF373737),
                        ),
                      ),
                    ),
                    if (category != null && category.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B64E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/passenger.svg',
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (carModel?.seats ?? '').toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFF949494),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.ac_unit, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('AC', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _IconText extends StatelessWidget {
  final IconData icon;
  final String value;

  const _IconText({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: const Color(0xFF1E88E5),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5568),
          ),
        ),
      ],
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
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());
  final CprProfileController cprProfileController = Get.put(CprProfileController());

  @override
  void initState() {
    super.initState();
    _loadPrefilledData();
  }

  Future<void> _loadPrefilledData() async {
    // Load booking data
    if (widget.bookingData != null) {
      widget.sourceController.text =
          widget.bookingData!.pickupPlace?.primaryText ?? '';
      widget.destinationController.text =
          widget.bookingData!.dropPlace?.primaryText ?? '';
    }

    // Fetch profile data if not already loaded
    final profile = cprProfileController.crpProfileInfo.value;
    if (profile == null) {
      // Fetch profile data
      final email = await StorageServices.instance.read('email') ?? '';
      final token = loginInfoController.crpLoginInfo.value?.key ?? '';
      final guestID = loginInfoController.crpLoginInfo.value?.guestID ?? 0;
      
      if (email.isNotEmpty && token.isNotEmpty) {
        final params = {
          'email': email,
          'GuestID': guestID.toString(),
          'token': token,
          'user': email,
        };
        await cprProfileController.fetchProfileInfo(params, context);
      }
    }

    // Get updated profile after fetch
    final updatedProfile = cprProfileController.crpProfileInfo.value;

    // Load name - priority: profile > login info
    String? guestName;
    if (updatedProfile?.guestName != null && updatedProfile!.guestName!.isNotEmpty) {
      guestName = updatedProfile.guestName;
    } else {
      guestName = loginInfoController.crpLoginInfo.value?.guestName ?? '';
    }
    if (guestName != null && guestName.isNotEmpty) {
      widget.firstNameController.text = guestName;
    }

    // Load email - priority: profile > storage
    String? email;
    if (updatedProfile?.emailID != null && updatedProfile!.emailID!.isNotEmpty) {
      email = updatedProfile.emailID;
    } else {
      email = await StorageServices.instance.read('email') ?? '';
    }
    if (email != null && email.isNotEmpty) {
      widget.emailController.text = email;
    }

    // Load contact - priority: profile > storage
    String? mobile;
    if (updatedProfile?.mobile != null && updatedProfile!.mobile!.isNotEmpty) {
      mobile = updatedProfile.mobile;
    } else {
      mobile = await StorageServices.instance.read('contact') ?? '';
    }
    if (mobile != null && mobile.isNotEmpty) {
      // Remove any non-digit characters and ensure it's 10 digits
      final cleanedMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanedMobile.length == 10) {
        widget.contactController.text = cleanedMobile;
      } else if (cleanedMobile.length > 10) {
        // Take last 10 digits if longer
        widget.contactController.text = cleanedMobile.substring(cleanedMobile.length - 10);
      } else {
        widget.contactController.text = mobile;
      }
    }

    // Update title based on gender from profile
    if (updatedProfile?.gender != null) {
      // Gender: 1 = Male (Mr.), 2 = Female (Ms./Mrs.), 3 = Other (Mr.)
      if (updatedProfile!.gender == 2) {
        // Female - default to Ms.
        widget.onTitleChanged('Ms.');
      } else {
        // Male or Other - default to Mr.
        widget.onTitleChanged('Mr.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        children: [
          Row(
            children: [
              Text('Travelers Details', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black
              ),)
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF4082F1).withOpacity(0.18),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4082F1).withOpacity(0.17),
                  spreadRadius: 0,
                  blurRadius: 5,
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Chips (Read-only)
                  Row(
                    children: widget.titles.asMap().entries.map((entry) {
                      final int i = entry.key;
                      final String title = entry.value;
                      final bool isSelected = widget.selectedTitle == title;
                      return Padding(
                        padding: EdgeInsets.only(right: i < widget.titles.length - 1 ? 4.0 : 0),
                        child: ChoiceChip(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          label: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF64A4F6),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.transparent,
                            ),
                          ),
                          showCheckmark: false,
                          onSelected: null, // Disabled - read-only
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _customTextField(
                    label: 'Full Name',
                    hint: 'Enter full name',
                    controller: widget.firstNameController,
                    isReadOnly: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Full name is required";
                      }
                      return null;
                    },
                  ),
                  _customTextField(
                    label: 'Email',
                    hint: 'Enter email id',
                    controller: widget.emailController,
                    isReadOnly: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Email is required";
                      }
                      final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      return !regex.hasMatch(v.trim()) ? "Enter a valid email" : null;
                    },
                  ),
                  // Phone Field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF535353),
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  '+91',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 31,
                          child: TextFormField(
                            controller: widget.contactController,
                            keyboardType: TextInputType.number,
                            readOnly: true,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLength: 10,
                            decoration: InputDecoration(
                              hintText: 'Enter  mobile number',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w400,
                              ),
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 0,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Mobile number is required";
                              }
                              if (value.length != 10 ||
                                  !RegExp(r'^[0-9]+$').hasMatch(value)) {
                                return "Enter valid 10-digit mobile number";
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      height: 1,
                      color: Color(0xFFE8E8E8),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 20),
                    child: _customTextField(
                      label: 'Pickup',
                      hint: 'Enter Pickup Address',
                      controller: widget.sourceController,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Pickup address is required";
                        }
                        return null;
                      },
                      showBottom: false,
                      isReadOnly: true,
                    ),
                  ),
                  // if (widget.sourceController.text.isNotEmpty)
                  //   _addressTag(widget.sourceController.text),
                  _customTextField(
                    label: 'Dropping Address',
                    hint: 'Enter Dropping Address',
                    controller: widget.destinationController,
                    validator: null,
                    showBottom: false,
                    isReadOnly: true,
                  ),
                  // if (widget.destinationController.text.isNotEmpty)
                  //   _addressTag(widget.destinationController.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool? isReadOnly,
    bool showBottom = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: showBottom ? 20 : 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF535353),
            ),
          ),
          TextFormField(
            controller: controller,
            readOnly: isReadOnly ?? false,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade400,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 0,
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE1E8ED),
                  width: 1,
                ),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE1E8ED),
                  width: 1,
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF4082F1),
                  width: 1.2,
                ),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _addressTag(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18, top: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF535353),
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

  /// Shorten strings sent to API for addresses / notes
  /// to avoid excessively long values.
  String _shortenForApi(String text, {int maxChars = 80}) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars - 2)}..';
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

  /// Extracts URL from HTML anchor tag in the message
  /// Example: "Please <a href='https://example.com'> Click Here </a> to clear payments."
  /// Returns the URL or null if not found
  String? _extractPaymentUrl(String message) {
    final regex = RegExp("<a\\s+href=[\"']([^\"']+)[\"']", caseSensitive: false);
    final match = regex.firstMatch(message);
    return match?.group(1);
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

    // Extract payment URL from message if response is 0 (failure due to pending payment)
    String? paymentUrl;
    if (!isSuccess && (codeStr == '0' || codeStr == '00')) {
      paymentUrl = _extractPaymentUrl(message);
    }

    if (isSuccess) {
      CustomSuccessSnackbar.show(context, message);
    } else {
      CustomFailureSnackbar.show(context, message);
    }
    Navigator.of(context).push(
      CorporatePageTransitions.pushRoute(
        context,
        CrpBookingResultPage(
          isSuccess: isSuccess,
          message: message,
          bookingData: widget.bookingData,
          selectedCar: widget.selectedCar,
          paymentUrl: paymentUrl,
        ),
        transitionType: TransitionType.scaleFade,
      ),
    );
  }

  Future<void> _makeBooking() async {
    FocusScope.of(context).unfocus();
    final CprProfileController cprProfileController = Get.put(CprProfileController());
    final CrpBranchListController crpBranchListController = Get.put(CrpBranchListController());

    if (widget.formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      try {
        // Get data from storage
        final corporateID = await StorageServices.instance.read('crpId') ?? cprProfileController.crpProfileInfo.value?.corporateID.toString();
        final branchID = crpBranchListController.selectedBranchId.value ?? cprProfileController.crpProfileInfo.value?.branchID.toString();
        final token = await StorageServices.instance.read('crpKey') ?? '';
        final user = await StorageServices.instance.read('email') ?? cprProfileController.crpProfileInfo.value?.emailID;
        final uID = await StorageServices.instance.read('guestId') ?? cprProfileController.crpProfileInfo.value?.guestID.toString();

        final contactCode = await StorageServices.instance.read('contactCode') ?? cprProfileController.crpProfileInfo.value?.mobile.toString();
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
        
        // Addresses (character-limited)
        final rawPickupAddress = bookingData?.pickupPlace?.primaryText ?? '';
        final rawDropAddress = bookingData?.dropPlace?.primaryText ?? '';
        final pickupAddress = _shortenForApi(rawPickupAddress, maxChars: 80);
        
        // If drop address is empty, set drop address and coordinates to empty strings
        final bool hasDropAddress = rawDropAddress.isNotEmpty;
        final dropAddress = hasDropAddress ? _shortenForApi(rawDropAddress, maxChars: 80) : '';
        
        // Coordinates
        final frmlat = bookingData?.pickupPlace?.latitude?.toString() ?? '';
        final frmlng = bookingData?.pickupPlace?.longitude?.toString() ?? '';
        final tolat = hasDropAddress ? (bookingData?.dropPlace?.latitude?.toString() ?? '') : '';
        final tolng = hasDropAddress ? (bookingData?.dropPlace?.longitude?.toString() ?? '') : '';
        
        // Optional fields
        final arrivalDetails = bookingData?.flightDetails ?? '';
        final specialInstructionsRaw =
            widget.bookingData?.specialInstruction ?? '';
        final specialInstructions =
            _shortenForApi(specialInstructionsRaw, maxChars: 120);
        final costCode = widget.bookingData?.costCode ?? '';
        final remarks = widget.bookingData?.referenceNumber ?? '';
        final transNo = "";

        // Decide which corporate ID to send: entityId (from booking) or fallback corporateID from storage
        final bookingEntityId = bookingData?.entityId;
        final corporateIdForApi = bookingEntityId != null && bookingEntityId != 0
            ? bookingEntityId.toString()
            : corporateID;

        // Build params
        final params = <String, dynamic>{
          'corporateID': corporateIdForApi,
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
          'costCode': '1',
          'packageID': "",
          'transNo': transNo,
          'providerID': providerID.toString(),
          'BookingType': bookingType,
          'frmlat': frmlat,
          'frmlng': frmlng,
          'tolat': tolat,
          'tolng': tolng,
          'token': token,
          'user': await StorageServices.instance.read('email'),
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
          CustomFailureSnackbar.show(context, 'Booking failed: ${e.toString()}');
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
            : Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _makeBooking();
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
                  'Book Cab',
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
        ),
      ),
    );
  }
}

class RouteCard extends StatefulWidget {
  final CrpBookingData? bookingData;

  const RouteCard({this.bookingData});

  @override
  State<RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  final GlobalKey pickupLocationKey = GlobalKey();
  final GlobalKey dropLocationKey = GlobalKey();

  CrpBookingData? get bookingData => widget.bookingData;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 0, right: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC1C1C1),
          width: 0.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000), // ultra subtle, barely perceptible
            offset: Offset(0, 0.5),
            blurRadius: 1,
            spreadRadius: 0,
          ),
        ],
      ),
      // Ensures all child corners are clipped properly
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            /// TOP CARD
            Container(
              padding: const EdgeInsets.only(top: 14, right: 14, left: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x05000000), // ultra subtle, barely perceptible
                    offset: Offset(0, 0.5),
                    blurRadius: 1,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      InkWell(
                        onTap: () {
                          context.push(AppRoutes.cprBookingEngine);
                        },
                        child: SvgPicture.asset(
                          'assets/images/back.svg',
                          width: 18,
                          height: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Left: vertical icon line (pickup and drop icons)
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
                              // Vertical line (only show if drop exists)
                              if (_hasDropLocation())
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
                              // Square end (drop icon) - only show if drop exists
                              if (_hasDropLocation())
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
                            // Pickup location
                            InkWell(
                              onTap: () {
                                _showTooltipOnTap(
                                  context,
                                  _getFullPickupRouteText(),
                                  pickupLocationKey,
                                );
                              },
                              child: Text(
                                _getPickupRouteText(),
                                key: pickupLocationKey,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F4F4F),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Drop location (only show if drop exists)
                            if (_hasDropLocation()) ...[
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () {
                                  _showTooltipOnTap(
                                    context,
                                    _getFullDropRouteText(),
                                    dropLocationKey,
                                  );
                                },
                                child: Text(
                                  _getDropRouteText(),
                                  key: dropLocationKey,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4F4F4F),
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// WHITE SPACER
            Container(height: 10, color: Colors.white),

            /// BOTTOM SECTION
            Container(
              padding: const EdgeInsets.only(
                  left: 16, top: 10, bottom: 10, right: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(bookingData?.pickupDateTime),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF717171),
                    ),
                  ),
                  if (_getPickupTypeText().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      _getPickupTypeText(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4082F1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('dd MMM, yyyy, hh:mm a zz').format(dateTime);
  }

  /// Safely shortens a text to a maximum number of characters.
  /// Adds ".." suffix if truncated.
  /// This uses character length only (not widget width) to keep
  /// strings compact inside the RouteCard.
  String _shorten(String text, {int maxChars = 25}) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars - 2)}..';
  }

  String _getPickupRouteText() {
    if (bookingData == null) {
      return 'Please select pickup locations';
    }

    final pickupPlace = bookingData!.pickupPlace;
    final pickupPrimary = pickupPlace?.primaryText ?? 'Pickup location';
    final pickupSecondary = pickupPlace?.secondaryText ?? '';
    final pickupFull = pickupSecondary.isNotEmpty
        ? '$pickupPrimary, $pickupSecondary'
        : pickupPrimary;

    // Enforce a strict character length for the pickup text
    return _shorten(pickupFull, maxChars: 25);
  }

  String _getDropRouteText() {
    if (bookingData == null) {
      return 'Please select drop locations';
    }

    final dropPlace = bookingData!.dropPlace;
    final dropPrimary = dropPlace?.primaryText ?? 'drop location';
    final dropSecondary = dropPlace?.secondaryText ?? '';
    final dropFull = dropSecondary.isNotEmpty
        ? '$dropPrimary, $dropSecondary'
        : dropPrimary;

    // Enforce a strict character length for the drop text
    return _shorten(dropFull, maxChars: 25);
  }

  String _getFullPickupRouteText() {
    if (bookingData == null) {
      return 'Please select pickup locations';
    }

    final pickupPlace = bookingData!.pickupPlace;
    final pickupPrimary = pickupPlace?.primaryText ?? 'Pickup location';
    final pickupSecondary = pickupPlace?.secondaryText ?? '';
    final pickupFull = pickupSecondary.isNotEmpty
        ? '$pickupPrimary, $pickupSecondary'
        : pickupPrimary;

    return pickupFull;
  }

  String _getFullDropRouteText() {
    if (bookingData == null) {
      return 'Please select drop locations';
    }

    final dropPlace = bookingData!.dropPlace;
    final dropPrimary = dropPlace?.primaryText ?? 'drop location';
    final dropSecondary = dropPlace?.secondaryText ?? '';
    final dropFull = dropSecondary.isNotEmpty
        ? '$dropPrimary, $dropSecondary'
        : dropPrimary;

    return dropFull;
  }

  String _getPickupTypeText() {
    if (bookingData == null || bookingData!.pickupType == null) {
      return '';
    }
    return bookingData!.pickupType ?? '';
  }

  void _showTooltipOnTap(BuildContext context, String message, GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // Calculate tooltip position - center it horizontally above the text
    final double tooltipWidth = (message.length * 7.0).clamp(100.0, MediaQuery.of(context).size.width - 32);
    final double leftPosition = (position.dx + (size.width / 2) - (tooltipWidth / 2)).clamp(8.0, MediaQuery.of(context).size.width - tooltipWidth - 8);
    final double topPosition = position.dy - 45;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => overlayEntry.remove(),
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          Positioned(
            left: leftPosition,
            top: topPosition,
            child: Material(
              elevation: 2,
              color: const Color(0xFF616161),
              borderRadius: BorderRadius.circular(4),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 16,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Remove tooltip after 3 seconds or on tap outside
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  bool _hasDropLocation() {
    if (bookingData == null) {
      return false;
    }
    final dropPlace = bookingData!.dropPlace;
    if (dropPlace == null) {
      return false;
    }
    final primaryText = dropPlace.primaryText;
    return primaryText != null && primaryText.isNotEmpty;
  }
}

