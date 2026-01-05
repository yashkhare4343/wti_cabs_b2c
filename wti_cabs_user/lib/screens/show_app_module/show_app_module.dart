import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wti_cabs_user/core/controller/fetch_country/fetch_country_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:get/get.dart';

class ShowAppModule extends StatefulWidget {
  const ShowAppModule({super.key});

  @override
  State<ShowAppModule> createState() => _ShowAppModuleState();
}

class _ShowAppModuleState extends State<ShowAppModule> {
  final FetchCountryController fetchCountryController = Get.put(FetchCountryController());

  @override
  void initState() {
    super.initState();
  }

  Future<void> _navigateToPersonal() async {
    // Mark that user has seen this screen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("hasSeenAppModule", true);

    // Navigate based on country
    if (fetchCountryController.currentCountry.value == 'United Arab Emirates') {
      GoRouter.of(context).go(AppRoutes.selfDriveBottomSheet);
    } else {
      GoRouter.of(context).go(AppRoutes.bottomNav);
    }
  }

  Future<void> _navigateToBusiness() async {
    // Mark that user has seen this screen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("hasSeenAppModule", true);

    // Navigate to corporate landing page or login
    GoRouter.of(context).go(AppRoutes.cprLandingPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                const Text(
                  'Choose Your Module',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select how you want to use the app',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.greyText3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Personal Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _navigateToPersonal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainButtonBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: const Text(
                      'Personal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Business Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _navigateToBusiness,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: const Text(
                      'Business',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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

