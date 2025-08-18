import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:wti_cabs_user/core/controller/banner/banner_controller.dart';
import 'package:wti_cabs_user/core/controller/popular_destination/popular_destination.dart';
import 'package:wti_cabs_user/core/controller/usp_controller/usp_controller.dart';

import '../core/controller/auth/mobile_controller.dart';
import '../core/controller/auth/otp_controller.dart';
import '../core/controller/manage_booking/upcoming_booking_controller.dart';
import '../core/controller/profile_controller/profile_controller.dart';
import 'bottom_nav/bottom_nav.dart';

class AuthScreen extends StatefulWidget {
  final String phoneNo;
  const AuthScreen({super.key, required this.phoneNo});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController phoneController;
  final TextEditingController otpTextEditingController = TextEditingController();
  final MobileController mobileController = Get.put(MobileController());
  final OtpController otpController = Get.put(OtpController());
  final UpcomingBookingController upcomingBookingController = Get.put(UpcomingBookingController());
  final ProfileController profileController = Get.put(ProfileController());
  final UspController uspController = Get.put(UspController());
  final BannerController bannerController = Get.put(BannerController());
  final PopularDestinationController popularDestinationController = Get.put(PopularDestinationController());



  bool hasError = false;
  String? errorMessage;
  bool isButtonEnabled = false;
  bool showOtpField = false;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: widget.phoneNo);
    _validatePhone(phoneController.text);
  }

  void _validatePhone(String value) {
    setState(() {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    PhoneNumber number = PhoneNumber(isoCode: 'IN');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Enter your mobile number",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "We will send you a 4-digit verification code",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 25),
              if (!showOtpField)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: InternationalPhoneNumberInput(
                    onInputChanged: (_) => _validatePhone(phoneController.text.trim()),
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                      useBottomSheetSafeArea: true,
                      showFlags: true,
                    ),
                    initialValue: number,
                    textFieldController: phoneController,
                    maxLength: 10,
                    inputDecoration: const InputDecoration(
                      hintText: "Mobile Number",
                      hintStyle: TextStyle(fontSize: 16, color: Colors.black54),
                      border: InputBorder.none,
                      counterText: "",
                    ),
                  ),
                ),
              if (showOtpField)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: OtpTextField(
                    otpController: otpTextEditingController,
                    mobileNo: phoneController.text.trim(),
                  ),
                ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isButtonEnabled ? _handleContinue : null,
                  child: Text(
                    showOtpField ? 'Verify' : 'Continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              if (!showOtpField)
                const Text(
                  "By continuing, you agree to our Terms of Service & Privacy Policy.",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (showOtpField) {
      final isVerified = await otpController.verifyOtp(
        mobile: phoneController.text.trim(),
        otp: otpTextEditingController.text.trim(),
        context: context,
      );

      if (isVerified) {
        // ✅ Run all fetches in parallel
        await Future.wait([
          profileController.fetchData(),
        ]);

        // ✅ Mark logged in (triggers Obx immediately if used in UI)
        upcomingBookingController.isLoggedIn.value = true;

        // ✅ Fetch bookings but don’t block navigation
        upcomingBookingController.fetchUpcomingBookingsData();

        // ✅ Navigate immediately without extra delay
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => BottomNavScreen()),
        );
      }
    } else {
      await mobileController.verifyMobile(
        mobile: phoneController.text.trim(),
        context: context,
      );
      if (mobileController.mobileData.value?.userAssociated == true) {
        setState(() {
          showOtpField = true;
          errorMessage = null;
          isButtonEnabled = true;
        });
      }
    }
  }
}
