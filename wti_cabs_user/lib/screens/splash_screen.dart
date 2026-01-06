import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wti_cabs_user/core/model/version_check/version_check_response.dart';

import '../core/controller/version_check/version_check_controller.dart';
import '../core/controller/fetch_country/fetch_country_controller.dart';
import '../core/route_management/app_routes.dart';
import '../core/services/storage_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final VersionCheckController versionCheckController = Get.put(VersionCheckController());
  final FetchCountryController fetchCountryController = Get.put(FetchCountryController());
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    fetchVersion();
    _waitAndRedirect();
  }

  void fetchVersion() async {
    await versionCheckController.verifyAppCompatibity(context: context);
  }

  Future<void> _waitAndRedirect() async {
    // Ensure minimum 2-second delay
    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    if (elapsed < 2) {
      await Future.delayed(Duration(seconds: 2 - elapsed));
    }

    if (!mounted) return;

    // Check first launch
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool("isFirstTime") ?? true;

    if (versionCheckController.versionCheckResponse.value?.isCompatible == true) {
      if (isFirstTime) {
        // Don't set isFirstTime to false here - let walkthrough handle it.
        // First-time users go to walkthrough, which will now route directly
        // into the personal module instead of showing the app module screen.
        GoRouter.of(context).go(AppRoutes.walkthrough);
      } else {
        // Not first time - we no longer route to ShowAppModule.
        // Ensure legacy flag is marked as seen so we don't depend on it anymore.
        final hasSeenAppModule = prefs.getBool("hasSeenAppModule") ?? false;
        if (!hasSeenAppModule) {
          await prefs.setBool("hasSeenAppModule", true);
        }

        // Check last selected module preference (defaults to personal).
        final lastSelectedModule = prefs.getString("lastSelectedModule");

        if (lastSelectedModule == "corporate") {
          // User last opened corporate module - check if logged in
          final existingKey = await StorageServices.instance.read('crpKey');
          if (existingKey != null && existingKey.isNotEmpty) {
            // User is logged in to corporate - navigate to corporate home
            GoRouter.of(context).go(AppRoutes.cprBottomNav);
          } else {
            // User is not logged in - navigate to corporate landing page
            GoRouter.of(context).go(AppRoutes.cprLandingPage);
          }
        } else {
          // User last opened personal/retail module or no preference - navigate to personal
          if (fetchCountryController.currentCountry.value == 'United Arab Emirates') {
            GoRouter.of(context).go(AppRoutes.selfDriveBottomSheet);
          } else {
            GoRouter.of(context).go(AppRoutes.bottomNav);
          }
        }
      }
    } else {
      final Uri uri = Uri.parse(Platform.isAndroid ? 'https://play.google.com/store/apps/details?id=com.wti.cabbooking&pcampaignid=web_share':'https://apps.apple.com/in/app/wti-cabs/id1634737888');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> redirectToWeb(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(
          image: AssetImage('assets/images/wti_logo.png'),
          width: 50,
          height: 50,
        ),
      ),
    );
  }
}