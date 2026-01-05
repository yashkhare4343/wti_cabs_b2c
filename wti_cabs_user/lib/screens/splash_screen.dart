import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:wti_cabs_user/core/model/version_check/version_check_response.dart';

import '../core/controller/version_check/version_check_controller.dart';
import '../core/controller/fetch_country/fetch_country_controller.dart';
import '../core/route_management/app_routes.dart';

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
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    // Record start time for minimum delay
    fetchVersion();
    _startTime = DateTime.now();
    // Initialize the video player with a network video URL
    _controller = VideoPlayerController.asset(
        'assets/images/splash.mp4'
    );
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // Auto-play the video once initialized
      _controller.play();
    });
    // Disable looping to allow video completion
    _controller.setLooping(false);
    // Add listener to detect video completion
    _controller.addListener(_videoListener);
  }

  void fetchVersion() async{
    await versionCheckController.verifyAppCompatibity(context: context);
  }

  Future<void> redirectToWeb(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // 🔥 opens in browser, not in-app
    )) {
      throw Exception("Could not launch $url");
    }
  }

  void _videoListener() async {
    if (_controller.value.position >= _controller.value.duration) {
      // Video has completed, ensure minimum 2-second delay
      final elapsed = DateTime
          .now()
          .difference(_startTime!)
          .inSeconds;
      if (elapsed < 2) {
        await Future.delayed(Duration(seconds: 2 - elapsed));
      }

      if (!mounted) return;

      // Check first launch
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool("isFirstTime") ?? true;

      if (versionCheckController.versionCheckResponse.value?.isCompatible == true) {
        if (isFirstTime) {
          // Don't set isFirstTime to false here - let walkthrough handle it
          // Navigate to walkthrough, which will then navigate to show_app_module
          GoRouter.of(context).go(AppRoutes.walkthrough);
        } else {
          // Not first time - check if user has seen app module
          final hasSeenAppModule = prefs.getBool("hasSeenAppModule") ?? false;
          if (!hasSeenAppModule) {
            // User has seen walkthrough but not app module - show it
            GoRouter.of(context).go(AppRoutes.showAppModule);
          } else {
            // User has seen both - go to main screen
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
  }

  @override
  void dispose() {
    // Remove listener and dispose controller
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Full-screen video
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:go_router/go_router.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../core/controller/version_check/version_check_controller.dart';
// import '../core/route_management/app_routes.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: VideoPlayerScreen(),
//     );
//   }
// }
//
// class VideoPlayerScreen extends StatefulWidget {
//   const VideoPlayerScreen({super.key});
//
//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
// }
//
// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   final VersionCheckController versionCheckController = Get.put(VersionCheckController());
//   DateTime? _startTime;
//
//   @override
//   void initState() {
//     super.initState();
//     _startTime = DateTime.now();
//     fetchVersion();
//     _waitAndRedirect();
//   }
//
//   void fetchVersion() async {
//     await versionCheckController.verifyAppCompatibity(context: context);
//   }
//
//   Future<void> _waitAndRedirect() async {
//     // Ensure minimum 2-second delay
//     final elapsed = DateTime.now().difference(_startTime!).inSeconds;
//     if (elapsed < 2) {
//       await Future.delayed(Duration(seconds: 2 - elapsed));
//     }
//
//     if (!mounted) return;
//
//     final prefs = await SharedPreferences.getInstance();
//     final isFirstTime = prefs.getBool("isFirstTime") ?? true;
//
//     if (versionCheckController.versionCheckResponse.value?.isCompatible == true) {
//       if (isFirstTime) {
//         await prefs.setBool("isFirstTime", false);
//         GoRouter.of(context).go(AppRoutes.walkthrough);
//       } else {
//         GoRouter.of(context).go(AppRoutes.bottomNav);
//       }
//     } else {
//       final Uri uri = Uri.parse(
//           'https://play.google.com/store/apps/details?id=com.wti.cabbooking&pcampaignid=web_share');
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       }
//     }
//   }
//
//   Future<void> redirectToWeb(String url) async {
//     final Uri uri = Uri.parse(url);
//     if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//       throw Exception("Could not launch $url");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Image(
//           image: AssetImage('assets/images/wti_logo.png'), // your logo here
//           width: 50,
//           height: 50,
//         ),
//       ),
//     );
//   }
// }
