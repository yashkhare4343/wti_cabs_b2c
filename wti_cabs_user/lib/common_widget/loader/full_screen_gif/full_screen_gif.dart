import 'package:flutter/material.dart';
import 'package:wti_cabs_user/common_widget/loader/popup_loader.dart';

class FullScreenGifLoader extends StatefulWidget {
  const FullScreenGifLoader({Key? key}) : super(key: key);

  @override
  State<FullScreenGifLoader> createState() => _FullScreenGifLoaderState();
}

class _FullScreenGifLoaderState extends State<FullScreenGifLoader> {
  // final List<Map<String, dynamic>> usps = [
  //   {"icon": Icons.directions_car_rounded, "text": "Comfortable rides"},
  //   {"icon": Icons.access_time_rounded, "text": "On-time guarantee"},
  //   {"icon": Icons.attach_money_rounded, "text": "Best price assured"},
  // ];
  //
  // int currentIndex = 0;
  //
  // @override
  // void initState() {
  //   super.initState();
  //   _startUspRotation();
  // }
  //
  // void _startUspRotation() {
  //   Future.delayed(const Duration(seconds: 2), () {
  //     if (mounted) {
  //       setState(() {
  //         currentIndex = (currentIndex + 1) % usps.length;
  //       });
  //       _startUspRotation();
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // subtle grey bg like MMT
      body: Center(
        child: PopupLoader(message: 'Search Inventeries'),
      ),
    );
  }
}
