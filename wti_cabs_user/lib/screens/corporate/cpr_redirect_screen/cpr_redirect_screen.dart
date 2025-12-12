import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';
import '../../../core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import '../corporate_bottom_nav/corporate_bottom_nav.dart';
import '../corporate_landing_page/corporate_landing_page.dart';

class CprRedirectScreen extends StatefulWidget {
  const CprRedirectScreen({super.key});

  @override
  State<CprRedirectScreen> createState() => _CprRedirectScreenState();
}

class _CprRedirectScreenState extends State<CprRedirectScreen> {
  bool _isChecking = true;
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());


  @override
  void initState() {
    super.initState();
    _checkCrpKeyAndRedirect();
  }

  /// Check for crpKey token and redirect accordingly
  Future<void> _checkCrpKeyAndRedirect() async {
    try {
      // Load corporate login info from storage
      await loginInfoController.loadFromStorage();

      // Wait for the next frame to ensure context is available
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));

      // Get crpKey from storage directly (with proper null handling)
      final String? crpKeyNullable = await StorageServices.instance.read('crpKey');
      
      // Also check the controller's loaded value as fallback
      final String? crpKeyFromController = loginInfoController.crpLoginInfo.value?.key;
      
      // Use controller value if available, otherwise use direct storage read
      final String? crpKey = crpKeyFromController ?? crpKeyNullable;
      
      debugPrint('🔍 crpKey from storage: $crpKeyNullable');
      debugPrint('🔍 crpKey from controller: $crpKeyFromController');
      debugPrint('🔍 Final crpKey: $crpKey');

      // Check if crpKey exists and is not empty
      if (crpKey != null && crpKey.isNotEmpty) {
        // User is logged in - redirect to corporate bottom nav
        debugPrint('✅ crpKey found, redirecting to Corporate Bottom Nav');
        if (mounted) {
          // Use pushReplacement to avoid any routing mismatch
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const CorporateBottomNavScreen(),
            ),
          );
        }
      } else {
        // User is not logged in - redirect to corporate landing page
        debugPrint('crpKey not found, redirecting to Corporate Landing Page');
        if (mounted) {
          // Navigate to landing page - using push since there's no route defined for it
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CorporateLandingPage(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking crpKey: $e');
      // On error, redirect to landing page as fallback
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CorporateLandingPage(),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: _isChecking
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

