import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/corporate/cpr_profile_controller/cpr_profile_controller.dart';
import '../../../common_widget/loader/shimmer/corporate_shimmer.dart';
import '../../../common_widget/snackbar/custom_snackbar.dart';
import '../../../core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import '../../../core/services/storage_services.dart';
import '../../../core/route_management/app_routes.dart';

class CrpEditProfile extends StatefulWidget {
  const CrpEditProfile({super.key});

  @override
  State<CrpEditProfile> createState() => _CrpEditProfileState();
}

class _CrpEditProfileState extends State<CrpEditProfile> {
  final CprProfileController cprProfileController = Get.put(CprProfileController());
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());
  bool _showShimmer = true;

  String? selectedGender;
  bool isCardValidated = false;
  
  @override
  void initState() {
    super.initState();
    // Show shimmer for 0.5 seconds
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showShimmer = false;
        });
      }
    });
    _loadProfileData();
  }
  
  void _loadProfileData() async {
    // Try to get GuestID and token from controller first, fallback to storage
    final guestIDFromController = loginInfoController.crpLoginInfo.value?.guestID?.toString();
    final tokenFromController = loginInfoController.crpLoginInfo.value?.key;
    final guestIDFromStorage = await StorageServices.instance.read('guestId');
    final tokenFromStorage = await StorageServices.instance.read('crpKey');
    final email = await StorageServices.instance.read('email');
    
    final Map<String, dynamic> params = {
      'email': email ?? '',
      'GuestID': guestIDFromController ?? guestIDFromStorage ?? '',
      'token': tokenFromController ?? tokenFromStorage ?? '',
      'user': email ?? '',
    };
    
    // Only proceed if we have a valid token
    if (params['token'] != null && params['token']!.toString().isNotEmpty) {
      cprProfileController.fetchProfileInfo(params, context);
    } else {
      debugPrint('⚠️ Cannot load profile: token is missing');
    }
    
    setState(() {});
  }
  
  @override
  void dispose() {

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showShimmer) {
      return const CorporateShimmer();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
      ),
      body: Obx(() => Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            // Profile Picture and Name Section
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 24),
              child: Column(
                children: [
                  // Light gray circular profile picture placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8E8E8), // Light gray color matching image
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFFB0B0B0), // Lighter gray for icon
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Obx(() {
                    final profile = cprProfileController.crpProfileInfo.value;
                    return Text(
                      profile?.guestName ?? 'Guest',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Montserrat',
                      ),
                    );
                  }),
                ],
              ),
            ),
            
            // Divider line
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                height: 1,
                color: Colors.black,
                margin: const EdgeInsets.symmetric(horizontal: 0),
              ),
            ),
            
            // Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Obx(() {
                  final profile = cprProfileController.crpProfileInfo.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileField(
                        label: 'Name',
                        detail: profile?.guestName ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Email',
                        detail: profile?.emailID ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Guest ID',
                        detail: profile?.guestID?.toString() ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Corporate Name',
                        detail: profile?.corporateName ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Corporate ID',
                        detail: profile?.corporateID ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Employee ID',
                        detail: profile?.employeeID ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Mobile',
                        detail: profile?.mobile ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Designation',
                        detail: profile?.designation ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Cost Code',
                        detail: profile?.costCode ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Branch Name',
                        detail: profile?.branchName ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Branch ID',
                        detail: profile?.branchID ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Card ID',
                        detail: profile?.cardID?.toString() ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Card Number',
                        detail: profile?.cardNo ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Card Expiry',
                        detail: profile?.ccExpiry ?? '',
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Card Validated',
                        detail: _formatYesNo(profile?.isCardValidated),
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Active',
                        detail: _formatYesNo(profile?.isActive),
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        label: 'Gender',
                        detail: _formatGender(profile?.gender),
                      ),
                    ],
                  );
                }),
              ),
            ),
            // Sticky bottom action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _navigateToEditForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052D4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        GoRouter.of(context).push(AppRoutes.cprChangePassword);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF666666),
                        side: const BorderSide(
                          color: Color(0xFFCCCCCC),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montserrat',
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
          // Loader overlay
          if (cprProfileController.isLoading.value)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052D4)),
                ),
              ),
            ),
        ],
      )),
    );
  }

  String _formatYesNo(int? value) {
    if (value == null) return '';
    return value == 1 ? 'Yes' : 'No';
  }

  String _formatGender(int? value) {
    if (value == null) return '';
    switch (value) {
      case 1:
        return 'Male';
      case 2:
        return 'Female';
      case 3:
        return 'Other';
      default:
        return '';
    }
  }
  
  Widget _buildProfileField({
    required String label,
    required String detail,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              detail, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF939393)),
            ),
          ],
        )
        // TextFormField(
        //   controller: controller,
        //   keyboardType: keyboardType,
        //   style: const TextStyle(
        //     fontSize: 14,
        //     fontWeight: FontWeight.w400,
        //     color: Color(0xFF666666), // Lighter gray for value
        //     fontFamily: 'Montserrat',
        //   ),
        //   decoration: InputDecoration(
        //     filled: true,
        //     fillColor: Colors.white,
        //     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(8),
        //       borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        //     ),
        //     enabledBorder: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(8),
        //       borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        //     ),
        //     focusedBorder: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(8),
        //       borderSide: const BorderSide(color: Color(0xFF0052D4), width: 1.5),
        //     ),
        //   ),
        // ),
      ],
    );
  }
  
  // Widget _buildCardValidatedField() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Is Card Validated',
  //         style: TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black,
  //           fontFamily: 'Montserrat',
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       InkWell(
  //         onTap: () {
  //           setState(() {
  //             isCardValidated = !isCardValidated;
  //           });
  //         },
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: const Color(0xFFE0E0E0)),
  //           ),
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: Text(
  //                   isCardValidated ? 'Yes' : 'No',
  //                   style: const TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w400,
  //                     color: Color(0xFF666666),
  //                     fontFamily: 'Montserrat',
  //                   ),
  //                 ),
  //               ),
  //               Switch(
  //                 value: isCardValidated,
  //                 onChanged: (value) {
  //                   setState(() {
  //                     isCardValidated = value;
  //                   });
  //                 },
  //                 activeColor: const Color(0xFF0052D4),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget _buildGenderField() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Gender',
  //         style: TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black,
  //           fontFamily: 'Montserrat',
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 12),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: const Color(0xFFE0E0E0)),
  //         ),
  //         child: DropdownButtonFormField<String>(
  //           value: selectedGender?.isEmpty ?? true ? null : selectedGender,
  //           decoration: const InputDecoration(
  //             border: InputBorder.none,
  //             contentPadding: EdgeInsets.symmetric(vertical: 14),
  //           ),
  //           hint: const Text(
  //             'Select Gender',
  //             style: TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w400,
  //               color: Color(0xFF999999),
  //               fontFamily: 'Montserrat',
  //             ),
  //           ),
  //           style: const TextStyle(
  //             fontSize: 14,
  //             fontWeight: FontWeight.w400,
  //             color: Color(0xFF666666),
  //             fontFamily: 'Montserrat',
  //           ),
  //           items: ['Male', 'Female', 'Other'].map((String value) {
  //             return DropdownMenuItem<String>(
  //               value: value,
  //               child: Text(value),
  //             );
  //           }).toList(),
  //           onChanged: (String? newValue) {
  //             setState(() {
  //               selectedGender = newValue;
  //             });
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }
  
  void _navigateToEditForm() async {
    final profile = cprProfileController.crpProfileInfo.value;
    if (profile != null) {
      final email = await StorageServices.instance.read('email') ?? '';
      final token = loginInfoController.crpLoginInfo.value?.key ?? '';
      final guestID = loginInfoController.crpLoginInfo.value?.guestID ?? profile.guestID ?? 0;
      
      final extraData = {
        'profile': profile,
        'email': email,
        'token': token,
        'guestID': guestID,
      };
      
      context.push(AppRoutes.cprEditProfileForm, extra: extraData);
      return;
    }

    CustomFailureSnackbar.show(context, 'Profile details not loaded yet');
  }
}

