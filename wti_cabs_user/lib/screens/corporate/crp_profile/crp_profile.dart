import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wti_cabs_user/common_widget/loader/popup_loader.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';
import 'package:get/get.dart';
import '../../../common_widget/loader/shimmer/corporate_shimmer.dart';
import '../../../core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import '../../../core/controller/corporate/cpr_profile_controller/cpr_profile_controller.dart';
import '../../../core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart';
import '../../../core/controller/corporate/crp_gender/crp_gender_controller.dart';
import '../../../core/controller/corporate/crp_car_provider/crp_car_provider_controller.dart';
import '../../../core/controller/corporate/crp_get_entity_all/crp_get_entity_list_controller.dart';
import '../../../core/controller/corporate/crp_payment_mode_controller/crp_payment_mode_controller.dart';
import '../../../core/controller/corporate/crp_services_controller/crp_sevices_controller.dart';
import '../../../core/services/storage_services.dart';
import '../../../main.dart';
import '../corporate_bottom_nav/corporate_bottom_nav.dart';

class CrpProfile extends StatefulWidget {
  const CrpProfile({super.key});

  @override
  State<CrpProfile> createState() => _CrpProfileState();
}

class _CrpProfileState extends State<CrpProfile> {
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());
  final CprProfileController cprProfileController = Get.put(CprProfileController());
  bool _showShimmer = true;
  String _storedGuestName = 'Guest';

  @override
  void initState() {
    super.initState();
    // Load guestName from storage as fallback
    _loadGuestNameFromStorage();
    // Fetch profile data to get gender and other info
    _loadProfileData();
    // Show shimmer for 0.5 seconds
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showShimmer = false;
        });
      }
    });
  }

  Future<void> _loadGuestNameFromStorage() async {
    final nameFromStorage = await StorageServices.instance.read('guestName');
    if (nameFromStorage != null && nameFromStorage.isNotEmpty && mounted) {
      setState(() {
        _storedGuestName = nameFromStorage;
      });
    }
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
  }

  void showLogOutSkeletonLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // disables tapping outside to dismiss
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // disables back button
          child: Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Logging Out...',
                      style: CommonFonts.bodyText3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  /// Perform logout: clear corporate data and navigate to bottom nav
  Future<void> _performLogout(BuildContext context) async {
    const keysToDelete = [
      'crpKey',
      'crpId',
      'branchId',
      'guestId',
      'guestName',
      'email',
      'selectedBranchName',
      'selectedBranchId',
      // Corporate prefill / cached metadata used in booking engine
      'crpGenderId',
      'crpEntityId',
      'cprSelectedRunTypeId',
    ];

    // Clear stored session data
    await Future.wait(
      keysToDelete.map(
            (k) => StorageServices.instance.delete(k).catchError((_) {}),
      ),
    );

    // Reset LoginInfoController
    loginInfoController.crpLoginInfo.value = null;

    // Reset CprProfileController to clear old profile data
    try {
      final profileController = Get.find<CprProfileController>();
      profileController.crpProfileInfo.value = null;
      profileController.isLoading.value = false;
    } catch (e) {
      debugPrint('⚠️ CprProfileController not found during logout: $e');
    }

    // Reset CrpBranchListController to clear old branch data
    try {
      final branchController = Get.find<CrpBranchListController>();
      branchController.selectedBranchId.value = null;
      branchController.selectedBranchName.value = null;
      branchController.branches.clear();
      branchController.branchNames.clear();
      branchController.isLoading.value = false;
    } catch (e) {
      debugPrint('⚠️ CrpBranchListController not found during logout: $e');
    }

    // Reset GenderController so gender list & selection are not reused
    try {
      final genderController = Get.find<GenderController>();
      genderController.genderList.clear();
      genderController.selectedGender.value = null;
    } catch (e) {
      debugPrint('⚠️ GenderController not found during logout: $e');
    }

    // Reset CarProviderController so provider list & selection are not reused
    try {
      final carProviderController = Get.find<CarProviderController>();
      carProviderController.carProviderList.clear();
      carProviderController.selectedCarProvider.value = null;
      carProviderController.isLoading.value = false;
    } catch (e) {
      debugPrint('⚠️ CarProviderController not found during logout: $e');
    }

    // Reset corporate entity list controller so entities are refetched for next login
    try {
      final entityListController = Get.find<CrpGetEntityListController>();
      entityListController.getAllEntityList.value = null;
      entityListController.isLoading.value = false;
    } catch (e) {
      debugPrint('⚠️ CrpGetEntityListController not found during logout: $e');
    }

    // Reset payment mode controller so modes & selection are refetched
    try {
      final paymentModeController = Get.find<PaymentModeController>();
      paymentModeController.modes.clear();
      paymentModeController.selectedMode.value = null;
      paymentModeController.isLoading.value = false;
    } catch (e) {
      debugPrint('⚠️ PaymentModeController not found during logout: $e');
    }

    // Reset services controller so run types are refetched
    try {
      final servicesController = Get.find<CrpServicesController>();
      servicesController.runTypes.value = null;
      servicesController.isLoading.value = false;
    } catch (e) {
      debugPrint('⚠️ CrpServicesController not found during logout: $e');
    }

    /// 🔑 Store logout flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('force_logout', true);

    /// Optional loader
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      showLogOutSkeletonLoader(ctx);
    }

    /// Warm navigation (cold start handled by redirect)
    if (ctx != null) {
      GoRouter.of(ctx).push(AppRoutes.cprLandingPage);
    }
  }

  /// Navigate to bottom nav with retry mechanism
  void _navigateToBottomNav({int retryCount = 0}) {
    const maxRetries = 5;
    const retryDelay = Duration(milliseconds: 200);

    if (navigatorKey.currentContext != null) {
      try {
        GoRouter.of(navigatorKey.currentContext!).go(AppRoutes.cprLandingPage);
        debugPrint('✅ Navigated to ${AppRoutes.cprLandingPage}');
      } catch (e) {
        debugPrint('❌ Navigation error: $e');
        // Retry if context is available but navigation failed
        if (retryCount < maxRetries) {
          Future.delayed(retryDelay, () {
            _navigateToBottomNav(retryCount: retryCount + 1);
          });
        }
      }
    } else {
      // Retry if context is not yet available
      if (retryCount < maxRetries) {
        debugPrint('⏳ Context not available, retrying... (${retryCount + 1}/$maxRetries)');
        Future.delayed(retryDelay, () {
          _navigateToBottomNav(retryCount: retryCount + 1);
        });
      } else {
        debugPrint('❌ Failed to navigate: context not available after $maxRetries retries');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_showShimmer) {
      return const CorporateShimmer();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Profile Picture and Name Section
            Padding(
              padding: const EdgeInsets.only(top: 32, bottom: 24),
              child: Column(
                children: [
                  // Light blue circular profile picture placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFB3D9F2), // Light blue color matching image
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF7BB3E8), // Slightly darker blue for icon
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Obx(() => Text(
                    loginInfoController.crpLoginInfo.value?.guestName ?? _storedGuestName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                    ),
                  )),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account & Profile Section
                    const Text(
                      'Account & Profile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Personal Details
                          InkWell(
                            onTap: () {
                              // Navigate to edit profile
                              GoRouter.of(context).push(AppRoutes.cprEditProfile);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  // Person icon with gear icon overlay (matching image)
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Icon(
                                            Icons.person_outline,
                                            size: 20,
                                            color: Color(0xFF404040),
                                          ),
                                        ),
                                        Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.settings,
                                              size: 10,
                                              color: Color(0xFF404040),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Personal Details',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF333333),
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Booking & Activity Section
                    const Text(
                      'Booking & Activity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Divider
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          // Manage Booking
                          InkWell(
                            onTap: () {
                              // Navigate to manage booking
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CorporateBottomNavScreen(initialIndex: 1),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 20,
                                    color: Color(0xFF404040),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Manage Booking',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF333333),
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Contact Us
                    InkWell(
                      onTap: () {
                        // Navigate to contact us
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CorporateBottomNavScreen(initialIndex: 2),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.headset_mic_outlined,
                              size: 20,
                              color: Color(0xFF1C1B1F),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Contact Us',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF000000),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Log Out
                    InkWell(
                      onTap: () {
                        // _showLogoutDialog(context);
                        _performLogout(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout,
                              size: 20,
                              color: Color(0xFF1C1B1F),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF000000),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // About Us
                    // InkWell(
                    //   onTap: () {
                    //     // Navigate to about us
                    //   },
                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 0,
                    //       vertical: 12,
                    //     ),
                    //     child: Row(
                    //       children: [
                    //         const Icon(
                    //           Icons.info_outline,
                    //           size: 20,
                    //           color: Color(0xFF1C1B1F),
                    //         ),
                    //         const SizedBox(width: 12),
                    //         const Text(
                    //           'About Us',
                    //           style: TextStyle(
                    //             fontSize: 14,
                    //             fontWeight: FontWeight.w400,
                    //             color: Color(0xFF000000),
                    //             fontFamily: 'Montserrat',
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
