import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';

class Walkthrough extends StatefulWidget {
  const Walkthrough({super.key});

  @override
  State<Walkthrough> createState() => _WalkthroughState();
}

class _WalkthroughState extends State<Walkthrough> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/images/wk1.png",
      "title": "Seamless Airport Transfers, Anytime You Fly",
      "subtitle": "Reliable, on-time airport cabs across India—arrive or depart with ease and comfort."
    },
    {
      "image": "assets/images/wk2.png",
      "title": "Ride with Comfort, Anytime, Anywhere",
      "subtitle": "Experience reliable, safe, and convenient cab services across India – from airport pickups to daily office commutes.q"
    },
    {
      "image": "assets/images/wk3.png",
      "title": "Travel Safely",
      "subtitle": "Verified drivers and secure rides every time."
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skip() {
    _finishOnboarding();
  }

  void _finishOnboarding() {
    GoRouter.of(context).go(AppRoutes.bottomNav);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          final page = _pages[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(
                page["image"]!,
                fit: BoxFit.cover,
              ),
              // Blurred bottom overlay
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      color: Colors.black.withOpacity(0.3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            page["title"]!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            page["subtitle"]!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Page indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _pages.length,
                                  (dotIndex) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentPage == dotIndex ? 12 : 8,
                                height: _currentPage == dotIndex ? 12 : 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == dotIndex
                                      ? Colors.white
                                      : Colors.white54,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_currentPage != _pages.length - 1)
                                TextButton(
                                  onPressed: _skip,
                                  child: const Text(
                                    "Skip",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              else
                                const SizedBox(width: 64), // Placeholder

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _nextPage,
                                child: Text(
                                  _currentPage == _pages.length - 1
                                      ? "Get Started"
                                      : "Next",
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
