import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/controller/manage_booking/upcoming_booking_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/select_currency/select_currency.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import '../../core/controller/auth/mobile_controller.dart';
import '../../core/controller/auth/otp_controller.dart';
import '../../core/controller/auth/register_controller.dart';
import '../../core/controller/auth/resend_otp_controller.dart';
import '../../core/controller/profile_controller/profile_controller.dart';
import '../../core/services/cache_services.dart';
import '../../core/services/storage_services.dart';
import '../../main.dart';
import '../../screens/bottom_nav/bottom_nav.dart';
import '../../screens/user_fill_details/user_fill_details.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../buttons/main_button.dart';
import '../name_initials/name_initial.dart';

final UpcomingBookingController upcomingBookingController =
Get.put(UpcomingBookingController());

class CustomDrawerSheet extends StatefulWidget {
  const CustomDrawerSheet({super.key});

  @override
  State<CustomDrawerSheet> createState() => _CustomDrawerSheetState();
}

class _CustomDrawerSheetState extends State<CustomDrawerSheet> {
  bool isLogin = false;
  final CurrencyController currencyController = Get.put(CurrencyController());
  final ProfileController profileController = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    checkLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileController.fetchData();
    });
  }

  void checkLogin() async {
    if ((await StorageServices.instance.read('token') != null)) {
      setState(() {
        isLogin = true;
      });
    } else {
      setState(() {
        isLogin = false;
      });
    }
  }

  void _showAuthBottomSheet() {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController otpTextEditingController =
    TextEditingController();
    final MobileController mobileController = Get.put(MobileController());
    final OtpController otpController = Get.put(OtpController());
    final ResendOtpController resendOtpController =
    Get.put(ResendOtpController());
    final RegisterController registerController = Get.put(RegisterController());
    final UpcomingBookingController upcomingBookingController =
    Get.put(UpcomingBookingController());

    bool isGoogleLoading = false;

    Future<UserCredential?> signInWithGoogle() async {
      try {
        final GoogleSignIn _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId:
          '880138699529-in25a6554o0jcp0610fucg4s94k56agt.apps.googleusercontent.com',
        );

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print("User cancelled the sign-in flow");
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
        print("✅ Signed in as: ${userCredential.user?.displayName}");
        return userCredential;
      } catch (e) {
        print("❌ Google sign-in failed: $e");
        return null;
      }
    }

    void _handleGoogleLogin(StateSetter setModalState) async {
      setModalState(() => isGoogleLoading = true);

      final result = await signInWithGoogle();

      setModalState(() => isGoogleLoading = false);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserFillDetails(
              name: result?.user?.displayName ?? '',
              email: result?.user?.email ?? '',
              phone: result?.user?.phoneNumber ?? ''),
        ),
      );
    }

    PhoneNumber number = PhoneNumber(isoCode: 'IN');
    bool hasError = false;
    String? errorMessage;
    bool isButtonEnabled = false;
    bool showOtpField = false;

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

            void _validateOtp(String value) {
              if (value.isEmpty) {
                errorMessage = "OTP is required";
                hasError = true;
                isButtonEnabled = false;
              } else if (value.length < 6) {
                errorMessage = "Enter valid 6-digit OTP";
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
              initialChildSize: 0.58,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Material(
                      color: Colors.white,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header banner
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF3563FF), Color(0xFF6B8FFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Welcome Back!",
                                          style: CommonFonts.heading1Bold.copyWith(
                                              color: Colors.white, fontSize: 20),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Explore your travel options",
                                          style: CommonFonts.bodyText6.copyWith(
                                              color: Colors.white70, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Image.asset('assets/images/offer.png',
                                      width: 60, height: 60),
                                ],
                              ),
                            ),

                            // Form section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Dynamic heading
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        showOtpField
                                            ? "OTP Authentication"
                                            : "Login or Create an Account",
                                        style: CommonFonts.heading1Bold.copyWith(
                                            fontSize: 18, color: Colors.black87),
                                      ),
                                      const SizedBox(width: 8),
                                      const SizedBox(
                                        width: 40,
                                        height: 4,
                                        child: DecoratedBox(
                                            decoration: BoxDecoration(
                                                color: Color(0xFF3563FF))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Form body
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        if (!showOtpField)
                                          Container(
                                            padding: const EdgeInsets.only(
                                                left: 16.0),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: hasError
                                                      ? Colors.red
                                                      : Colors.grey.shade300),
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.1),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                              BorderRadius.circular(12.0),
                                              child:
                                              InternationalPhoneNumberInput(
                                                onInputChanged: (_) =>
                                                    _validatePhone(
                                                        phoneController.text
                                                            .trim()),
                                                selectorConfig:
                                                const SelectorConfig(
                                                  selectorType:
                                                  PhoneInputSelectorType
                                                      .BOTTOM_SHEET,
                                                  useBottomSheetSafeArea: true,
                                                  showFlags: true,
                                                ),
                                                ignoreBlank: false,
                                                autoValidateMode:
                                                AutovalidateMode.disabled,
                                                selectorTextStyle:
                                                const TextStyle(
                                                    color: Colors.black),
                                                initialValue: number,
                                                textFieldController:
                                                phoneController,
                                                formatInput: false,
                                                keyboardType:
                                                const TextInputType
                                                    .numberWithOptions(
                                                    signed: true),
                                                validator: (_) => null,
                                                maxLength: 10,
                                                inputDecoration:
                                                InputDecoration(
                                                  hintText:
                                                  "Enter Mobile Number",
                                                  counterText: "",
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 14),
                                                  border: InputBorder.none,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (showOtpField)
                                          OtpTextField(
                                            otpController:
                                            otpTextEditingController,
                                            mobileNo:
                                            phoneController.text.trim(),
                                          ),
                                        if (errorMessage != null) ...[
                                          const SizedBox(height: 8),
                                          Text(errorMessage!,
                                              style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // Button
                                  Obx(() => SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: Opacity(
                                      opacity: !showOtpField
                                          ? isButtonEnabled
                                          ? 1.0
                                          : 0.4
                                          : 1.0,
                                      child: MainButton(
                                        text: showOtpField
                                            ? 'Verify OTP'
                                            : 'Continue',
                                        isLoading: mobileController
                                            .isLoading.value,
                                        onPressed: isButtonEnabled
                                            ? () async {
                                          mobileController
                                              .isLoading.value = true;
                                          await Future.delayed(
                                              const Duration(
                                                  seconds: 2));

                                          if (showOtpField) {
                                            try {
                                              final isVerified =
                                              await otpController
                                                  .verifyOtp(
                                                mobile: phoneController
                                                    .text
                                                    .trim(),
                                                otp:
                                                otpTextEditingController
                                                    .text
                                                    .trim(),
                                                context: context,
                                              );

                                              otpController.hasError
                                                  .value = !isVerified;

                                              if (isVerified) {
                                                await Future.delayed(
                                                    const Duration(
                                                        seconds: 3));
                                                upcomingBookingController
                                                    .isLoggedIn
                                                    .value = true;
                                                await upcomingBookingController
                                                    .fetchUpcomingBookingsData();
                                                await profileController
                                                    .fetchData();
                                                GoRouter.of(context).pop();
                                                GoRouter.of(context)
                                                    .go(AppRoutes.profile);
                                              }
                                            } catch (e) {
                                              otpController.hasError
                                                  .value = true;
                                            }
                                          } else {
                                            await mobileController
                                                .verifyMobile(
                                              mobile: phoneController
                                                  .text
                                                  .trim(),
                                              context: context,
                                            );
                                            if ((mobileController
                                                .mobileData
                                                .value !=
                                                null) &&
                                                (mobileController
                                                    .mobileData
                                                    .value
                                                    ?.userAssociated ==
                                                    true)) {
                                              showOtpField = true;
                                              errorMessage = null;
                                              isButtonEnabled = true;
                                              otpTextEditingController
                                                  .clear();
                                              setModalState(() {});
                                            }
                                          }

                                          mobileController.isLoading
                                              .value = false;
                                        }
                                            : () {},
                                      ),
                                    ),
                                  )),

                                  if (!showOtpField) const SizedBox(height: 8),

                                  Column(
                                    children: [
                                      if (!showOtpField)
                                        Padding(
                                          padding:
                                          const EdgeInsets.only(top: 0.0),
                                          child: Center(
                                            child: TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // close current sheet
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => UserFillDetails(
                                                        name: '',
                                                        email: '',
                                                        phone: ''),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                  "Don't have an account? Register",
                                                  style: CommonFonts.bodyText6
                                                      .copyWith(
                                                      color:
                                                      Color(0xFF3563FF))),
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 16),

                                      if (!showOtpField)
                                        Row(
                                          children: [
                                            const Expanded(
                                                child: Divider(thickness: 1)),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8.0),
                                              child: Text("Or Login Via",
                                                  style: CommonFonts.bodyText6
                                                      .copyWith(
                                                      color:
                                                      Colors.black54)),
                                            ),
                                            const Expanded(
                                                child: Divider(thickness: 1)),
                                          ],
                                        ),

                                      const SizedBox(height: 16),

                                      if (!showOtpField)
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: isGoogleLoading
                                                  ? null
                                                  : () => _handleGoogleLogin(
                                                  setModalState),
                                              child: Center(
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      width: 48,
                                                      height: 48,
                                                      padding:
                                                      const EdgeInsets.all(1),
                                                      decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          shape: BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                  0.2),
                                                              blurRadius: 4,
                                                              offset: Offset(0, 2),
                                                            ),
                                                          ]),
                                                      child: CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor:
                                                        Colors.white,
                                                        child: isGoogleLoading
                                                            ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                          CircularProgressIndicator(
                                                              strokeWidth:
                                                              2),
                                                        )
                                                            : Image.asset(
                                                          'assets/images/google_icon.png',
                                                          fit:
                                                          BoxFit.contain,
                                                          width: 29,
                                                          height: 29,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text("Google",
                                                        style: CommonFonts
                                                            .bodyText6
                                                            .copyWith(
                                                            fontSize: 13)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Platform.isIOS
                                                ? const SizedBox(
                                              width: 24,
                                            )
                                                : SizedBox(),
                                            Platform.isIOS
                                                ? Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: signInWithApple,
                                                  child: Container(
                                                    height: 45,
                                                    width: 45,
                                                    decoration:
                                                    const BoxDecoration(
                                                      color: Colors.black,
                                                      shape:
                                                      BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Image.asset(
                                                        'assets/images/apple.png',
                                                        height: 48,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Platform.isIOS
                                                    ? const SizedBox(
                                                    height: 4)
                                                    : SizedBox(),
                                                Platform.isIOS
                                                    ? Text("Apple",
                                                    style: CommonFonts
                                                        .bodyText6
                                                        .copyWith(
                                                        fontSize:
                                                        13))
                                                    : SizedBox(),
                                              ],
                                            )
                                                : SizedBox(),
                                          ],
                                        ),

                                      const SizedBox(height: 20),

                                      Column(
                                        children: [
                                          Text.rich(
                                            TextSpan(
                                              text:
                                              "By logging in, I understand & agree to Wise Travel India Limited ",
                                              style: CommonFonts.bodyText3Medium
                                                  .copyWith(
                                                  color: Colors.black54,
                                                  fontSize: 12),
                                              children: [],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
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

  Future<void> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final userId = credential.userIdentifier;
      final email = credential.email;
      final fullName =
      '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();

      print('User ID: $userId');

      if (email != null) {
        await StorageServices.instance.save('appleUserId', userId ?? '');
        await StorageServices.instance.save('appleEmail', email ?? '');
        await StorageServices.instance.save('appleName', fullName ?? '');
        Navigator.of(context).push(
          Platform.isIOS
              ? CupertinoPageRoute(
            builder: (_) => UserFillDetails(
              name: fullName ?? '',
              email: email ?? '',
              phone: '',
            ),
          )
              : MaterialPageRoute(
            builder: (_) => UserFillDetails(
              name: fullName ?? '',
              email: email ?? '',
              phone: '',
            ),
          ),
        );
      } else {
        String userId = await StorageServices.instance.read('appleUserId') ?? '';
        String userEmail =
            await StorageServices.instance.read('appleEmail') ?? '';
        String userName =
            await StorageServices.instance.read('appleName') ?? '';

        Navigator.of(context).push(
          Platform.isIOS
              ? CupertinoPageRoute(
            builder: (_) => UserFillDetails(
              name: userName,
              email: userEmail,
              phone: '',
            ),
          )
              : MaterialPageRoute(
            builder: (_) => UserFillDetails(
              name: userName,
              email: userEmail,
              phone: '',
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Apple Sign-In Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.homebg,
      statusBarIconBrightness: Brightness.light,
    ));
    final double width = MediaQuery.of(context).size.width * 0.85;

    void showLogoutDialog(BuildContext context) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Logout',
                    style: CommonFonts.heading1Bold.copyWith(
                        fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to Sign out?',
                    textAlign: TextAlign.center,
                    style: CommonFonts.bodyText6.copyWith(
                        fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: CommonFonts.bodyText6.copyWith(
                                fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: AppColors.mainButtonBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            try {
                              final googleSignIn = GoogleSignIn();
                              if (await googleSignIn.isSignedIn()) {
                                await googleSignIn.signOut();
                                await googleSignIn.disconnect();
                              }
                              StorageServices.instance.clear();
                              await CacheHelper.clearAllCache();

                              final upcomingBookingController =
                              Get.find<UpcomingBookingController>();
                              upcomingBookingController
                                  .upcomingBookingResponse.value?.result
                                  ?.clear();
                              upcomingBookingController.isLoggedIn.value = false;
                              await FirebaseAuth.instance.signOut();
                              upcomingBookingController.reset();
                            } catch (e) {
                              debugPrint("Google sign-out failed: $e");
                            }

                            Future.delayed(const Duration(milliseconds: 200),
                                    () async {
                                  showDialog(
                                    context: navigatorKey.currentContext!,
                                    barrierDismissible: false,
                                    builder: (_) {
                                      final upcomingBookingController =
                                      Get.find<UpcomingBookingController>();
                                      upcomingBookingController
                                          .upcomingBookingResponse.value?.result
                                          ?.clear();
                                      upcomingBookingController.isLoggedIn.value =
                                      false;
                                      StorageServices.instance.read('firstName');
                                      StorageServices.instance.read('contact');
                                      StorageServices.instance.read('emailId');
                                      Future.delayed(const Duration(seconds: 4), () {
                                        if (Navigator.of(navigatorKey.currentContext!)
                                            .canPop()) {
                                          Navigator.of(navigatorKey.currentContext!)
                                              .pushReplacement(
                                            MaterialPageRoute(
                                                builder: (_) => BottomNavScreen()),
                                          );
                                        }
                                      });

                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16)),
                                        backgroundColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 24),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.green, size: 60),
                                            const SizedBox(height: 16),
                                            Text(
                                              "Logout Successful",
                                              style: CommonFonts.heading1Bold.copyWith(
                                                  fontSize: 20, color: Colors.black87),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "You have been logged out successfully.",
                                              textAlign: TextAlign.center,
                                              style: CommonFonts.bodyText6.copyWith(
                                                  fontSize: 14, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                        actionsAlignment: MainAxisAlignment.center,
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(
                                                navigatorKey.currentContext!).pop(),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.mainButtonBg,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 24, vertical: 12),
                                            ),
                                            child: Text(
                                              "Okay",
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                });
                            GoRouter.of(context).go(AppRoutes.bottomNav);
                          },
                          child: Text(
                            'Sign Out',
                            style: CommonFonts.bodyText6.copyWith(
                                fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    void showDeleteDialog(BuildContext context) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Delete Account',
                    style: CommonFonts.heading1Bold.copyWith(
                        fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete account?',
                    textAlign: TextAlign.center,
                    style: CommonFonts.bodyText6.copyWith(
                        fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: CommonFonts.bodyText6.copyWith(
                                fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            try {
                              final googleSignIn = GoogleSignIn();
                              if (await googleSignIn.isSignedIn()) {
                                await googleSignIn.signOut();
                                await googleSignIn.disconnect();
                              }
                              StorageServices.instance.clear();
                              await CacheHelper.clearAllCache();

                              final upcomingBookingController =
                              Get.find<UpcomingBookingController>();
                              upcomingBookingController
                                  .upcomingBookingResponse.value?.result
                                  ?.clear();
                              upcomingBookingController.isLoggedIn.value = false;
                              upcomingBookingController.reset();
                            } catch (e) {
                              debugPrint("Google sign-out failed: $e");
                            }

                            Future.delayed(const Duration(milliseconds: 200),
                                    () async {
                                  showDialog(
                                    context: navigatorKey.currentContext!,
                                    barrierDismissible: false,
                                    builder: (_) {
                                      final upcomingBookingController =
                                      Get.find<UpcomingBookingController>();
                                      upcomingBookingController
                                          .upcomingBookingResponse.value?.result
                                          ?.clear();
                                      upcomingBookingController.isLoggedIn.value =
                                      false;
                                      StorageServices.instance.read('firstName');
                                      StorageServices.instance.read('contact');
                                      StorageServices.instance.read('emailId');
                                      Future.delayed(const Duration(seconds: 4), () {
                                        if (Navigator.of(navigatorKey.currentContext!)
                                            .canPop()) {
                                          Navigator.of(navigatorKey.currentContext!)
                                              .pushReplacement(
                                            MaterialPageRoute(
                                                builder: (_) => BottomNavScreen()),
                                          );
                                        }
                                      });

                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16)),
                                        backgroundColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 24),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.green, size: 60),
                                            const SizedBox(height: 16),
                                            Text(
                                              "Delete Account Successful",
                                              style: CommonFonts.heading1Bold.copyWith(
                                                  fontSize: 20, color: Colors.black87),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Account has been deleted successfully.",
                                              textAlign: TextAlign.center,
                                              style: CommonFonts.bodyText6.copyWith(
                                                  fontSize: 14, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                        actionsAlignment: MainAxisAlignment.center,
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(
                                                navigatorKey.currentContext!).pop(),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.mainButtonBg,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 24, vertical: 12),
                                            ),
                                            child: Text(
                                              "Okay",
                                              style: CommonFonts.bodyText6.copyWith(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                });
                            GoRouter.of(context).go(AppRoutes.bottomNav);
                          },
                          child: Text(
                            'Delete',
                            style: CommonFonts.bodyText6.copyWith(
                                fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if(Platform.isAndroid){
      return SafeArea(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: width,
              height: MediaQuery.of(context).size.height, // Set full height
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(34),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SvgPicture.asset(
                          'assets/images/wti_logo.svg',
                          height: 24,
                          width: 50,
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info
                        Obx(() => Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey.shade200,
                              child: upcomingBookingController.isLoggedIn.value
                                  ? NameInitialHomeCircle(
                                  name: profileController.profileResponse.value
                                      ?.result?.firstName ??
                                      '')
                                  : const Icon(Icons.person,
                                  color: Colors.grey, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  upcomingBookingController.isLoggedIn.value
                                      ? (profileController.profileResponse.value?.result
                                      ?.firstName ??
                                      'Guest')
                                      : 'Guest',
                                  style: CommonFonts.heading1Bold.copyWith(
                                      fontSize: 18, color: Colors.black87),
                                ),
                                Text(
                                  upcomingBookingController.isLoggedIn.value
                                      ? (profileController.profileResponse.value?.result
                                      ?.emailID ??
                                      'Sign in to access your profile')
                                      : 'Sign in to access your profile',
                                  style: CommonFonts.bodyText6.copyWith(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        )),
                        const SizedBox(height: 16),
                        const Divider(thickness: 1, color: Colors.grey),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Obx(() => _buildDrawerItem(
                              icon: upcomingBookingController.isLoggedIn.value
                                  ? SizedBox(
                                width: 24,
                                height: 24,
                                child: NameInitialHomeCircle(
                                    name: profileController.profileResponse.value
                                        ?.result?.firstName ??
                                        ''),
                              )
                                  : const Icon(Icons.person,
                                  color: Colors.grey, size: 24),
                              title: 'Profile',
                              onTap: () async {
                                if (await StorageServices.instance.read('token') ==
                                    null) {
                                  _showAuthBottomSheet();
                                } else {
                                  GoRouter.of(context).push(AppRoutes.profile);
                                }
                              },
                            )),
                            _buildDrawerItem(
                              icon: const Icon(Icons.work_outline,
                                  color: Colors.grey, size: 24),
                              title: 'Manage Bookings',
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        BottomNavScreen(initialIndex: 1)));
                              },
                            ),
                            Obx(() => _buildDrawerItem(
                              icon: SvgPicture.asset(
                                'assets/images/payments.svg',
                                height: 24,
                                width: 24,
                                color: Colors.grey,
                              ),
                              title:
                              'Currency (${currencyController.selectedCurrency.value.code})',
                              onTap: () {
                                GoRouter.of(context).push(AppRoutes.selectCurrency);
                              },
                            )),
                            _buildDrawerItem(
                              icon: const Icon(Icons.phone,
                                  color: Colors.grey, size: 24),
                              title: 'Contact Us',
                              onTap: () {
                                GoRouter.of(context).push(AppRoutes.contact);
                              },
                            ),
                            if (isLogin) ...[
                              _buildDrawerItem(
                                icon: SvgPicture.asset(
                                  'assets/images/logout.svg',
                                  height: 24,
                                  width: 24,
                                  color: Colors.redAccent,
                                ),
                                title: 'Sign Out',
                                onTap: () {
                                  showLogoutDialog(context);
                                },
                              ),
                              // Platform.isIOS? _buildDrawerItem(
                              //   icon: const Icon(Icons.delete_forever_outlined,
                              //       color: Colors.redAccent, size: 24),
                              //   title: 'Delete Account',
                              //   onTap: () {
                              //     showDeleteDialog(context);
                              //   },
                              // ) : SizedBox.shrink(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          height: MediaQuery.of(context).size.height, // Set full height
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(34),
              bottomRight: Radius.circular(34),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30,),
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(34),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset(
                      'assets/images/wti_logo.svg',
                      height: 24,
                      width: 50,
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info
                    Obx(() => Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade200,
                          child: upcomingBookingController.isLoggedIn.value
                              ? NameInitialHomeCircle(
                              name: profileController.profileResponse.value
                                  ?.result?.firstName ??
                                  '')
                              : const Icon(Icons.person,
                              color: Colors.grey, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              upcomingBookingController.isLoggedIn.value
                                  ? (profileController.profileResponse.value?.result
                                  ?.firstName ??
                                  'Guest')
                                  : 'Guest',
                              style: CommonFonts.heading1Bold.copyWith(
                                  fontSize: 18, color: Colors.black87),
                            ),
                            Text(
                              upcomingBookingController.isLoggedIn.value
                                  ? (profileController.profileResponse.value?.result
                                  ?.emailID ??
                                  'Sign in to access your profile')
                                  : 'Sign in to access your profile',
                              style: CommonFonts.bodyText6.copyWith(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    )),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1, color: Colors.grey),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Obx(() => _buildDrawerItem(
                          icon: upcomingBookingController.isLoggedIn.value
                              ? SizedBox(
                            width: 24,
                            height: 24,
                            child: NameInitialHomeCircle(
                                name: profileController.profileResponse.value
                                    ?.result?.firstName ??
                                    ''),
                          )
                              : const Icon(Icons.person,
                              color: Colors.grey, size: 24),
                          title: 'Profile',
                          onTap: () async {
                            if (await StorageServices.instance.read('token') ==
                                null) {
                              _showAuthBottomSheet();
                            } else {
                              GoRouter.of(context).push(AppRoutes.profile);
                            }
                          },
                        )),
                        _buildDrawerItem(
                          icon: const Icon(Icons.work_outline,
                              color: Colors.grey, size: 24),
                          title: 'Manage Bookings',
                          onTap: () {
                            Navigator.of(context).push(
                              Platform.isIOS
                                  ? CupertinoPageRoute(
                                builder: (_) =>  BottomNavScreen(initialIndex: 1,),
                              )
                                  : MaterialPageRoute(
                                builder: (_) =>  BottomNavScreen(initialIndex: 1,),
                              ),
                            );
                          },
                        ),
                        Obx(() => _buildDrawerItem(
                          icon: SvgPicture.asset(
                            'assets/images/payments.svg',
                            height: 24,
                            width: 24,
                            color: Colors.grey,
                          ),
                          title:
                          'Currency (${currencyController.selectedCurrency.value.code})',
                          onTap: () {
                            GoRouter.of(context).push(AppRoutes.selectCurrency);
                          },
                        )),
                        _buildDrawerItem(
                          icon: const Icon(Icons.phone,
                              color: Colors.grey, size: 24),
                          title: 'Contact Us',
                          onTap: () {
                            Navigator.of(context).push(
                              Platform.isIOS
                                  ? CupertinoPageRoute(
                                builder: (_) =>  BottomNavScreen(initialIndex: 2,),
                              )
                                  : MaterialPageRoute(
                                builder: (_) =>  BottomNavScreen(initialIndex: 2,),
                              ),
                            );                          },
                        ),
                        if (isLogin) ...[
                          _buildDrawerItem(
                            icon: SvgPicture.asset(
                              'assets/images/logout.svg',
                              height: 24,
                              width: 24,
                              color: Colors.redAccent,
                            ),
                            title: 'Sign Out',
                            onTap: () {
                              showLogoutDialog(context);
                            },
                          ),
                          _buildDrawerItem(
                            icon: const Icon(Icons.delete_forever_outlined,
                                color: Colors.redAccent, size: 24),
                            title: 'Delete Account',
                            onTap: () {
                              showDeleteDialog(context);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );


  }
  Widget _buildDrawerItem({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 24, height: 24, child: icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CommonFonts.bodyText6.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}