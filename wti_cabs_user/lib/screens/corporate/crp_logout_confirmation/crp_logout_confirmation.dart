import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../../core/route_management/app_routes.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../../../core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import '../../../core/services/storage_services.dart';
import '../corporate_landing_page/corporate_landing_page.dart';
import '../../../main.dart';

class CrpLogoutConfirmation extends StatefulWidget {
  const CrpLogoutConfirmation({super.key});

  @override
  State<CrpLogoutConfirmation> createState() => _CrpLogoutConfirmationState();
}

class _CrpLogoutConfirmationState extends State<CrpLogoutConfirmation> {
  final LoginInfoController loginInfoController = Get.find<LoginInfoController>();
  bool _isLoggingOut = false;

  
  
  
  /// Perform logout: clear corporate data and navigate to landing page
  Future<void> _performLogout() async {
    if (_isLoggingOut) return; // Prevent multiple calls
    
    setState(() {
      _isLoggingOut = true;
    });

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

    // Navigate using retry mechanism that works after app kill
    // await _navigateToLandingPage();
    await Future.delayed(const Duration(milliseconds: 500));

    GoRouter.of(context).go(AppRoutes.cprBottomNav);
  }

  /// Navigate to landing page with retry mechanism for app kill scenarios
  // Future<void> _navigateToLandingPage() async {
  //   const maxRetries = 10;
  //   const retryDelay = Duration(milliseconds: 200);
  //
  //   for (int attempt = 0; attempt < maxRetries; attempt++) {
  //     // Wait a bit before each attempt (except the first)
  //     if (attempt > 0) {
  //       await Future.delayed(retryDelay);
  //     }
  //
  //     // Try to get context from navigatorKey first (works after app kill)
  //     final navigationContext = navigatorKey.currentContext ?? context;
  //
  //     if (navigationContext != null) {
  //       try {
  //         // Check if GoRouter is available in the context
  //         final router = GoRouter.maybeOf(navigationContext);
  //         if (router != null) {
  //           router.go(AppRoutes.cprLandingPage);
  //           debugPrint('✅ Navigation successful on attempt ${attempt + 1}');
  //           return; // Success, exit the function
  //         } else {
  //           debugPrint('⚠️ GoRouter not available in context on attempt ${attempt + 1}');
  //         }
  //       } catch (e) {
  //         debugPrint('⚠️ Navigation attempt ${attempt + 1} failed: $e');
  //         // Continue to next retry
  //       }
  //     } else {
  //       debugPrint('⚠️ Navigation context not available on attempt ${attempt + 1}');
  //     }
  //   }
  //
  //   // If all retries failed, try one more time with a longer delay
  //   await Future.delayed(Duration(milliseconds: 500));
  //   final finalContext = navigatorKey.currentContext ?? context;
  //   if (finalContext != null) {
  //     try {
  //       final router = GoRouter.maybeOf(finalContext);
  //       if (router != null) {
  //         router.go(AppRoutes.cprLandingPage);
  //         debugPrint('✅ Navigation successful on final attempt');
  //         return;
  //       } else {
  //         debugPrint('❌ GoRouter not available in final context');
  //       }
  //     } catch (e) {
  //       debugPrint('❌ Final navigation attempt failed: $e');
  //     }
  //   }
  //
  //   // Last resort: use Navigator as fallback
  //   try {
  //     final fallbackContext = navigatorKey.currentContext ?? context;
  //     if (fallbackContext != null && fallbackContext.mounted) {
  //       Navigator.of(fallbackContext).pushAndRemoveUntil(
  //         MaterialPageRoute(builder: (_) => const CorporateLandingPage()),
  //         (route) => false,
  //       );
  //       debugPrint('✅ Navigation successful using Navigator fallback');
  //     }
  //   } catch (e) {
  //     debugPrint('❌ All navigation attempts failed: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.logout,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Title
              const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Message
              const Text(
                'Are you sure you want to log out? You will need to log in again to access your corporate account.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Montserrat',
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoggingOut
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Logout button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoggingOut ? null : _performLogout,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.mainButtonBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoggingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

