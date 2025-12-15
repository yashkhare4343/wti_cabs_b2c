import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import '../crp_home_screen/crp_home_screen.dart';
import '../crp_booking/crp_booking.dart';
import '../crp_contact_us/crp_contact_us.dart';
import '../crp_profile/crp_profile.dart';

class CorporateBottomNavScreen extends StatefulWidget {
  final int? initialIndex;
  const CorporateBottomNavScreen({super.key, this.initialIndex});

  @override
  State<CorporateBottomNavScreen> createState() => _CorporateBottomNavScreenState();
}

class _CorporateBottomNavScreenState extends State<CorporateBottomNavScreen>
    with WidgetsBindingObserver {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
    WidgetsBinding.instance.addObserver(this);
    _setStatusBarColor();
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
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final List<Widget> _screens = [
    CprHomeScreen(),
    CrpBooking(),
    CrpContactUs(),
    CrpProfile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildBarItem(
      IconData selectedIcon, IconData unselectedIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    // Define colors
    const Color selectedIconColor = Colors.white;
    const Color unselectedIconColor = AppColors.grey4;
    const Color selectedBackgroundColor = AppColors.blue2;

    return BottomNavigationBarItem(
      label: label,
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? selectedBackgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isSelected ? selectedIcon : unselectedIcon,
            color: isSelected ? selectedIconColor : unselectedIconColor,
            size: 22,
          ),
        ),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: selectedBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            selectedIcon,
            color: selectedIconColor,
            size: 22,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Material(
          elevation: 10.0,
          shadowColor: const Color(0x33BCBCBC),
          child: Container(
            color: Colors.white,
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.black,
              unselectedItemColor: AppColors.grey4,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                fontFamily: 'Montserrat',
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 10,
                fontFamily: 'Montserrat',
              ),
              type: BottomNavigationBarType.fixed,
              items: [
                _buildBarItem(Icons.home, Icons.home_outlined, 'Home', 0),
                _buildBarItem(Icons.work, Icons.work_outline, 'Bookings', 1),
                _buildBarItem(Icons.phone_in_talk, Icons.phone_in_talk_outlined, 'Contact', 2),
                _buildBarItem(Icons.person, Icons.person_outline, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

