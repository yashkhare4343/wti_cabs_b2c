import 'package:flutter/material.dart';

class FullScreenGifLoader extends StatefulWidget {
  const FullScreenGifLoader({Key? key}) : super(key: key);

  @override
  State<FullScreenGifLoader> createState() => _FullScreenGifLoaderState();
}

class _FullScreenGifLoaderState extends State<FullScreenGifLoader> {
  final List<Map<String, dynamic>> usps = [
    {"icon": Icons.directions_car_rounded, "text": "Comfortable rides"},
    {"icon": Icons.access_time_rounded, "text": "On-time guarantee"},
    {"icon": Icons.attach_money_rounded, "text": "Best price assured"},
  ];

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startUspRotation();
  }

  void _startUspRotation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          currentIndex = (currentIndex + 1) % usps.length;
        });
        _startUspRotation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // subtle grey bg like MMT
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.black12,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Foreground Car Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  "assets/images/promotion.jpeg",
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

              // USP animation
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Row(
                    key: ValueKey(currentIndex),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(usps[currentIndex]["icon"], color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        usps[currentIndex]["text"],
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
