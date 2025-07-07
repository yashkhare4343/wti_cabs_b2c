import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/controller/auth/mobile_controller.dart';
import 'package:wti_cabs_user/screens/home/home_screen.dart';

import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    // Register as WidgetsBindingObserver to listen for lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // Fetch location and show bottom sheet
    _setStatusBarColor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBottomSheet();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reapply status bar color when dependencies change (e.g., navigation)
    _setStatusBarColor();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reapply status bar color when the app resumes
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
    // Remove observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }



  void _showBottomSheet() {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController phoneController = TextEditingController();
    PhoneNumber number = PhoneNumber(isoCode: 'IN');

    bool hasError = false;
    String? errorMessage;
    bool isButtonEnabled = false;
   final MobileController mobileController = Get.put(MobileController());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void _validatePhone(String value) {
              if (value.isEmpty) {
                errorMessage = "Mobile number is required";
                hasError = true;
                isButtonEnabled = false;
              } else if (value.length < 10) {
                errorMessage = "Please enter at least 10 digits";
                hasError = true;
                isButtonEnabled = false;
              } else {
                errorMessage = null;
                hasError = false;
                isButtonEnabled = true;
              }
              setModalState(() {});
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Material(
                      color: Colors.white,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Invite & Earn Banner
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF6DD),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text("Invite & Earn!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        Text("Invite your Friends & Get Up to"),
                                        Text("INR 2000*", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Image.asset('assets/images/offer.png', fit: BoxFit.contain, width: 85, height: 85),
                                ],
                              ),
                            ),

                            // Login Box
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: const [
                                      Text("Login or Create an Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      SizedBox(width: 8),
                                      SizedBox(width: 40, height: 4, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF3563FF)))),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Phone Field
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.only(left: 16.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: hasError ? Colors.red : Colors.grey),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12.0),
                                            child: InternationalPhoneNumberInput(
                                              onInputChanged: (PhoneNumber number) {
                                                _validatePhone(phoneController.text.trim());
                                              },
                                              selectorConfig: const SelectorConfig(
                                                selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                                                useBottomSheetSafeArea: true,
                                                showFlags: true,
                                              ),
                                              ignoreBlank: false,
                                              autoValidateMode: AutovalidateMode.disabled,
                                              selectorTextStyle: const TextStyle(color: Colors.black),
                                              initialValue: number,
                                              textFieldController: phoneController,
                                              formatInput: false,
                                              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: false),
                                              validator: (_) => null,
                                              maxLength: 10,
                                              inputDecoration: InputDecoration(
                                                hintText: "Enter Mobile Number",
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                                prefixIcon: Container(width: 1, color: Colors.grey,),
                                                border: InputBorder.none,
                                                errorText: null,

                                              ),
                                              onSaved: (_) {},
                                            ),
                                          ),
                                        ),
                                        if (errorMessage != null) ...[
                                          const SizedBox(height: 8),
                                          Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // Continue Button
                                  Obx(() => SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: Opacity(
                                      opacity: ((errorMessage == null) && (phoneController.text.isNotEmpty)) ? 1.0 : 0.4,
                                      child: MainButton(
                                        text: 'Continue',
                                        isLoading: mobileController.isLoading.value,
                                        onPressed: ((errorMessage == null) && (phoneController.text.isNotEmpty))
                                            ? () {
                                          mobileController.verifyMobile(
                                            mobile: phoneController.text.trim(),
                                            context: context,
                                          );
                                        }
                                            : () {},
                                      ),
                                    ),
                                  )),


                                  const SizedBox(height: 16),

                                  // Divider with Text
                                  Row(
                                    children: const [
                                      Expanded(child: Divider(thickness: 1)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text("Or Login Via", style: TextStyle(fontSize: 12, color: Colors.black54)),
                                      ),
                                      Expanded(child: Divider(thickness: 1)),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Google Login
                                  Center(
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          padding: const EdgeInsets.all(1),
                                          decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                                          child: CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.white,
                                            child: Image.asset('assets/images/google_icon.png', fit: BoxFit.contain, width: 29, height: 29),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text("Google", style: TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Terms & Conditions
                                  Column(
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          text: "By logging in, I understand & agree to Wise Travel India Limited ",
                                          style: CommonFonts.bodyText3Medium,
                                          children: [
                                            TextSpan(text: "Terms & Conditions", style: CommonFonts.bodyText3MediumBlue),
                                            TextSpan(text: ", "),
                                            TextSpan(text: "Privacy Policy", style: CommonFonts.bodyText3MediumBlue),
                                            TextSpan(text: ", and User agreement", style: CommonFonts.bodyText3MediumBlue),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  final List<Widget> _screens = [
    HomeScreen(),
    Center(child: Text("Offers")),

    Center(child: Text("Bookings")),
    Center(child: Text("My Profile")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildBarItem(
      IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              icon,
              color: isSelected ? Colors.black : AppColors.grey4,
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
    onWillPop: () async {
      // Reapply status bar color when navigating back
      _setStatusBarColor();
      return true;
    },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            // color: Colors.white,
            boxShadow: [
              BoxShadow(
                offset: Offset(0, -4),
                blurRadius: 20,
                spreadRadius: 0,
                color: Color(0x66BCBCBC), // #BCBCBC40
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: BottomNavigationBar(
              backgroundColor: Colors.white,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.black,
              unselectedItemColor: AppColors.grey4,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
              type: BottomNavigationBarType.fixed,
              items: [
                _buildBarItem(Icons.home_outlined, 'Home', 0),
                _buildBarItem(Icons.local_offer_outlined, 'Offers', 1),
                _buildBarItem(Icons.work_outline, 'Bookings', 2),
                _buildBarItem(Icons.person_outline, 'My Profile', 3),
              ],
            ),
          ),
        ),

      ),
    );
  }
}


