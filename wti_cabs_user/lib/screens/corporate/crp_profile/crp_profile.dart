import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';
import 'package:get/get.dart';
import '../../../common_widget/loader/shimmer/corporate_shimmer.dart';
import '../../../core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import '../../../core/services/storage_services.dart';
import '../corporate_bottom_nav/corporate_bottom_nav.dart';
import '../corporate_landing_page/corporate_landing_page.dart';

class CrpProfile extends StatefulWidget {
  const CrpProfile({super.key});

  @override
  State<CrpProfile> createState() => _CrpProfileState();
}

class _CrpProfileState extends State<CrpProfile> {
  final CurrencyController currencyController = Get.find<CurrencyController>();
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());
  bool _showShimmer = true;

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
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Montserrat',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.mainButtonBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _performLogout(context);
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Perform logout: clear corporate data and navigate to landing page
  Future<void> _performLogout(BuildContext context) async {
    // Store context reference before async operations
    final navigatorContext = context;

    final keysToDelete = [
      'crpKey',
      'crpId',
      'branchId',
      'guestId',
      'guestName',
      'email',
    ];

    // Delete keys in parallel with error handling
    await Future.wait(
      keysToDelete.map((key) async {
        try {
          await StorageServices.instance.delete(key);
          debugPrint('✅ Deleted $key');
        } catch (e) {
          // Ignore errors if key doesn't exist - this is expected
          debugPrint('Key $key not found or already deleted: $e');
        }
      }),
      eagerError: false, // Continue even if one fails
    );

    // Reset LoginInfoController
    loginInfoController.crpLoginInfo.value = null;

    debugPrint('✅ Corporate logout data cleared');

    // Navigate to corporate landing page (or redirect) and clear navigation stack
    context.go(AppRoutes.cprLandingPage);
  }

  @override
  Widget build(BuildContext context) {
    if (_showShimmer) {
      return const CorporateShimmer();
    }

    return PopScope(
      canPop: true, // allow router to change route
      onPopInvoked: (didPop) {
        // block only system back
      },
      child: Scaffold(
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
                    Obx(()=>Text(
                      loginInfoController.crpLoginInfo.value?.guestName??'Guest',
                      style: TextStyle(
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
                          _showLogoutDialog(context);
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
                      InkWell(
                        onTap: () {
                          // Navigate to about us
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Color(0xFF1C1B1F),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'About Us',
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

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
