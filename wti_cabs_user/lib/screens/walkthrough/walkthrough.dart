import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/fetch_country/fetch_country_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';

class Walkthrough extends StatefulWidget {
  const Walkthrough({super.key});

  @override
  State<Walkthrough> createState() => _WalkthroughState();
}

class _WalkthroughState extends State<Walkthrough> {
  final PageController _controller = PageController();
  final FetchCountryController fetchCountryController = Get.put(FetchCountryController());
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  double _progress = 0.0; // Tracks progress for the active page's progress bar

  final List<String> _imageAssets = [
    "assets/images/wk5.png",
    "assets/images/wk1.png",
    "assets/images/wk2.png",
    "assets/images/wk3.png",
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    fetchCountryController.fetchCurrentCountry();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _progress = 0.0; // Reset progress
    _autoScrollTimer?.cancel(); // Cancel any existing timer
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        setState(() {
          _progress += 0.0167; // 3s = 3000ms, 50ms ticks, 1/60 ≈ 0.0167
          if (_progress >= 1.0) {
            _controller.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
            _progress = 0.0; // Reset progress for the next page
          }
        });
      });

  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _nextPage() {
    _stopAutoScroll();
    if (_currentPage < _imageAssets.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _progress = 0.0; // Reset progress for manual navigation
      _startAutoScroll();
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    _stopAutoScroll();
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _progress = 0.0; // Reset progress for manual navigation
      _startAutoScroll();
    }
  }

  void _skip() {
    _stopAutoScroll();
    _finishOnboarding();
  }

  void _finishOnboarding() {
    if(fetchCountryController.currentCountry.value == 'United Arab Emirates'){
      GoRouter.of(context).go(AppRoutes.selfDriveBottomSheet);
    }
    else{
      GoRouter.of(context).go(AppRoutes.bottomNav);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(), // Disable manual sliding
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                _progress = 0.0; // Reset progress when page changes
              });
              _stopAutoScroll();
              _startAutoScroll();
            },
            itemCount: _imageAssets.length,
            itemBuilder: (context, index) {
              return Image.asset(
                _imageAssets[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),
          // Side edge navigation
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 80, // Width of the left tap area
            child: GestureDetector(
              onTap: _previousPage,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 80, // Width of the right tap area
            child: GestureDetector(
              onTap: _nextPage,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ), // Bottom overlay for progress bar and buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.transparent, // Adjust for your theme if needed
              padding: const EdgeInsets.only(left: 0, right: 0, bottom: 32, top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_imageAssets.length, (index) {
                            final isActive = _currentPage == index;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: isActive
                                  ? Stack(
                                children: [
                                  // Background for active tab (progress bar track)
                                  Container(
                                    width: 32, // Fixed width for progress bar
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white38,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  // Foreground for active tab (progress bar)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 50),
                                    height: 8,
                                    width: 32 * _progress, // Animate width based on progress
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              )
                                  : Container(
                                width: 8, // Dot for inactive tabs
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white38,
                                  shape: BoxShape.circle, // Circular dot for inactive tabs
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      // Buttons Row
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*0.037),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_currentPage != _imageAssets.length - 1)
                              SizedBox(
                                width: 104,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shadowColor: Colors.black.withOpacity(0.3),
                                    elevation: 4,
                                  ),
                                  onPressed: _skip,
                                  child: const Text("Skip"),
                                ),
                              )
                            else
                              const SizedBox(width: 104),
                            SizedBox(width: 16,),
// Placeholder for alignment
                            SizedBox(
                              width: 104,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue[900],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shadowColor: Colors.black.withOpacity(0.3),
                                  elevation: 4,
                                ),
                                onPressed: _nextPage,
                                child: Text(
                                  _currentPage == _imageAssets.length - 1
                                      ? "Get Started"
                                      : "Next",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                  // Indicator Row with Progress Bar for Active Tab and Dots for Others

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}