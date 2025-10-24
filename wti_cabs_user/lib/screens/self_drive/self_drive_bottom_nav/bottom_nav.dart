import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/controller/auth/mobile_controller.dart';
import 'package:wti_cabs_user/core/controller/auth/otp_controller.dart';
import 'package:wti_cabs_user/core/controller/auth/register_controller.dart';
import 'package:wti_cabs_user/core/controller/auth/resend_otp_controller.dart';
import 'package:wti_cabs_user/core/controller/current_location/current_location_controller.dart';
import 'package:wti_cabs_user/core/controller/profile_controller/profile_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/contact/contact.dart';
import 'package:wti_cabs_user/screens/home/home_screen.dart';
import 'package:wti_cabs_user/screens/manage_bookings/manage_bookings.dart';
import 'package:wti_cabs_user/screens/offers/offers.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_contact/self_drive_contact.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_home/self_drive_home_screen.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_manage_bookings/manage_bookings.dart';

import '../../../core/controller/booking_ride_controller.dart';
import '../../../core/controller/manage_booking/upcoming_booking_controller.dart';
import '../../../core/controller/popular_destination/popular_destination.dart';
import '../../../core/controller/usp_controller/usp_controller.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../../user_fill_details/user_fill_details.dart';

// Signature and structure remains unchanged
class SelfDriveBottomNavScreen extends StatefulWidget {
  final int? initialIndex;
  const SelfDriveBottomNavScreen({super.key, this.initialIndex});

  @override
  State<SelfDriveBottomNavScreen> createState() =>
      _SelfDriveBottomNavScreenState();
}

class _SelfDriveBottomNavScreenState extends State<SelfDriveBottomNavScreen>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  // Controllers initialization remains unchanged
  final LocationController locationController = Get.put(LocationController());
  final BookingRideController bookingRideController =
  Get.put(BookingRideController());
  final PopularDestinationController popularDestinationController =
  Get.put(PopularDestinationController());
  final UspController uspController = Get.put(UspController());

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
    WidgetsBinding.instance.addObserver(this);
    _setStatusBarColor();
  }

  void homeApiLoading() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await popularDestinationController.fetchPopularDestinations();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setStatusBarColor();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _setStatusBarColor();
    }
  }

  void _setStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.blue2,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final List<Widget> _screens = [
    SelfDriveHomeScreen(),
    SelfDriveManageBooking(),
    SelfDriveContact(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // REFACTORED: Custom BottomNavigationBarItem builder with reduced padding for less height
  BottomNavigationBarItem _buildBarItem(
      IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    // Define colors
    const Color selectedIconColor = Colors.white;
    const Color unselectedIconColor = AppColors.grey4;
    const Color selectedBackgroundColor = AppColors.blue2;

    return BottomNavigationBarItem(
      label: label,
      icon: Padding(
        // Reduced vertical padding here
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Container(
          // Reduced vertical padding inside the pill
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? selectedBackgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: isSelected ? selectedIconColor : unselectedIconColor,
            size: 22, // Slightly smaller icon
          ),
        ),
      ),
      // Active icon is necessary for BottomNavigationBar to function correctly
      activeIcon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: selectedBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: selectedIconColor,
            size: 22, // Slightly smaller icon
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    homeApiLoading();
    return WillPopScope(
      onWillPop: () async {
        _setStatusBarColor();
        return true;
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Material(
          elevation: 10.0,
          shadowColor: Color(0x33BCBCBC),
          child: Container(
            color: Colors.white,
            // Removed overall padding on the container for minimum height
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.black,
              unselectedItemColor: AppColors.grey4,
              // Reduced font size for a compact look
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
              type: BottomNavigationBarType.fixed,
              items: [
                _buildBarItem(Icons.home_filled, 'Home', 0),
                _buildBarItem(Icons.work_outline, 'Bookings', 1),
                _buildBarItem(Icons.phone_in_talk_outlined, 'Contact', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}