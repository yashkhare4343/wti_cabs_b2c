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
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/contact/contact.dart';
import 'package:wti_cabs_user/screens/home/home_screen.dart';
import 'package:wti_cabs_user/screens/manage_bookings/manage_bookings.dart';
import 'package:wti_cabs_user/screens/offers/offers.dart';

import '../../core/services/storage_services.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen>
    with WidgetsBindingObserver {
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

  void _showRegisterSheet(BuildContext context) {
    final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController mobileController = TextEditingController();
    String gender = "MALE";
    PhoneNumber number = PhoneNumber(isoCode: 'IN');
    bool isGoogleLoading = false;
    bool hasError = false;
    String? errorMessage;
    bool isButtonEnabled = false;
    bool showOtpField = false;

    Future<UserCredential?> signInWithGoogle() async {
      try {
        final GoogleSignIn _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId:
              '350350132251-9s1qaevcbivf6oj2nmg1t1kk65hned1b.apps.googleusercontent.com', // Web Client ID
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

      if (result != null) {
        // ✅ Prefill controllers
        nameController.text = result.user?.displayName ?? '';
        emailController.text = result.user?.email ?? '';
        mobileController.text = result.user?.phoneNumber ?? '';

        gender = "MALE"; // default or based on preference

        print("✅ User signed in: ${result.user?.email}");
      } else {
        print("❌ Google Sign-In cancelled or failed");
      }
    }

    Future<void> signOutFromGoogle() async {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();

        // Sign out from Google account
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }

        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();

        print("✅ User signed out successfully");
      } catch (e) {
        print("❌ Error signing out: $e");
      }
    }


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModelState) {
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
              setModelState(() {});
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.95,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Material(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Form(
                        key: _registerFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Invite & Earn!",
                                            style: CommonFonts.heading1Bold),
                                        const SizedBox(height: 8),
                                        Text("Invite your Friends & Get Up to",
                                            style: CommonFonts.bodyText6),
                                        Text("INR 2000*",
                                            style: CommonFonts.bodyText6Bold),
                                      ],
                                    ),
                                  ),
                                  Image.asset('assets/images/offer.png',
                                      width: 85, height: 85),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Register",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: nameController,
                                    decoration: const InputDecoration(
                                      labelText: "Full Name",
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                            ? "Name required"
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: "Email",
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) =>
                                        val == null || !val.contains('@')
                                            ? "Valid email required"
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: hasError
                                              ? Colors.red
                                              : Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: InternationalPhoneNumberInput(
                                        onInputChanged: (_) => _validatePhone(
                                            mobileController.text.trim()),
                                        selectorConfig: const SelectorConfig(
                                          selectorType: PhoneInputSelectorType
                                              .BOTTOM_SHEET,
                                          useBottomSheetSafeArea: true,
                                          showFlags: true,
                                        ),
                                        ignoreBlank: false,
                                        autoValidateMode:
                                            AutovalidateMode.disabled,
                                        selectorTextStyle: const TextStyle(
                                            color: Colors.black),
                                        initialValue: number,
                                        textFieldController: mobileController,
                                        formatInput: false,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(signed: true),
                                        validator: (_) => null,
                                        maxLength: 10,
                                        inputDecoration: const InputDecoration(
                                          hintText: "Enter Mobile Number",
                                          counterText: "",
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text("Gender"),
                                  Row(
                                    children: [
                                      Radio<String>(
                                        value: "MALE",
                                        groupValue: gender,
                                        onChanged: (val) {
                                          setModelState(
                                              () => gender = val ?? "MALE");
                                        },
                                      ),
                                      const Text("Male"),
                                      const SizedBox(width: 12),
                                      Radio<String>(
                                        value: "FEMALE",
                                        groupValue: gender,
                                        onChanged: (val) {
                                          setModelState(
                                              () => gender = val ?? "FEMALE");
                                        },
                                      ),
                                      const Text("Female"),
                                      const SizedBox(width: 12),
                                      Radio<String>(
                                        value: "Others",
                                        groupValue: gender,
                                        onChanged: (val) {
                                          setModelState(
                                              () => gender = val ?? "Others");
                                        },
                                      ),
                                      const Text("Others"),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: MainButton(
                                      text: 'Submit',
                                      onPressed: () async {
                                        if (_registerFormKey.currentState
                                                ?.validate() ??
                                            false) {
                                          final Map<String, dynamic>
                                              requestData = {
                                            "firstName":
                                                nameController.text.trim(),
                                            "contact":
                                                mobileController.text.trim()??'0000000000',
                                            "contactCode": "91",
                                            "countryName": "India",
                                            "gender": gender,
                                            "emailID":
                                                emailController.text.trim()
                                          };

                                          await Get.find<RegisterController>()
                                              .verifySignup(
                                            requestData: requestData,
                                            context: context,
                                          );

                                          Navigator.of(context).pop();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: const [
                                      Expanded(child: Divider(thickness: 1)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text("Or Login Via",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54)),
                                      ),
                                      Expanded(child: Divider(thickness: 1)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: isGoogleLoading
                                        ? null
                                        : () =>
                                            _handleGoogleLogin(setModelState),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            padding: const EdgeInsets.all(1),
                                            decoration: const BoxDecoration(
                                                color: Colors.grey,
                                                shape: BoxShape.circle),
                                            child: CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.white,
                                              child: isGoogleLoading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    )
                                                  : Image.asset(
                                                      'assets/images/google_icon.png',
                                                      fit: BoxFit.contain,
                                                      width: 29,
                                                      height: 29,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text("Google",
                                              style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: (){
                                      signOutFromGoogle();
                                    },
                                    child: Column(
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            text:
                                                "By logging in, I understand & agree to Wise Travel India Limited ",
                                            style: CommonFonts.bodyText3Medium,
                                            children: [
                                              TextSpan(
                                                  text: "Terms & Conditions",
                                                  style: CommonFonts
                                                      .bodyText3MediumBlue),
                                              TextSpan(text: ", "),
                                              TextSpan(
                                                  text: "Privacy Policy",
                                                  style: CommonFonts
                                                      .bodyText3MediumBlue),
                                              TextSpan(
                                                  text: ", and User agreement",
                                                  style: CommonFonts
                                                      .bodyText3MediumBlue),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
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

  void _showBottomSheet() {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController otpTextEditingController =
        TextEditingController();
    final MobileController mobileController = Get.put(MobileController());
    final OtpController otpController = Get.put(OtpController());
    final ResendOtpController resendOtpController =
        Get.put(ResendOtpController());
    final RegisterController registerController = Get.put(RegisterController());
    bool isGoogleLoading = false;

    Future<UserCredential?> signInWithGoogle() async {
      try {
        final GoogleSignIn _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId:
              '350350132251-9s1qaevcbivf6oj2nmg1t1kk65hned1b.apps.googleusercontent.com', // Web Client ID
        );

        // Start the sign-in flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print("User cancelled the sign-in flow");
          return null;
        }

        // Obtain the auth tokens
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a Firebase credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase
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

      if (result != null) {
        final Map<String, dynamic> requestData = {
          "firstName": result.user?.displayName,
          // "lastName": "Sahni",
          "contact": result.user?.phoneNumber ?? '000000000',
          "contactCode": "91",
          "countryName": "India",
          // "address": "String",
          // "city": "String",
          "gender": "MALE",
          // "postalCode": "String",
          "emailID": result.user?.email
          // "password": "String"
          // "otp": {
          //     "code": "Number",
          //     "otpExpiry": ""
          // }
        };
        await registerController
            .verifySignup(requestData: requestData, context: context)
            .then((value) {
          Navigator.of(context).pop();
        });
        print("✅ User signed in: ${result.user?.email}");

        // close the bottom sheet
      } else {
        print("❌ Google Sign-In cancelled or failed");
      }
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
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Invite & Earn!",
                                          style: CommonFonts.heading1Bold,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Invite your Friends & Get Up to",
                                          style: CommonFonts.bodyText6,
                                        ),
                                        Text("INR 2000*",
                                            style: CommonFonts.bodyText6Bold),
                                      ],
                                    ),
                                  ),
                                  Image.asset('assets/images/offer.png',
                                      width: 85, height: 85),
                                ],
                              ),
                            ),

                            // Form section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 24),
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
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
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
                                                      : Colors.grey),
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                                      )
                                                          .then((value) {
                                                        GoRouter.of(context)
                                                            .pop();
                                                      });
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
                                                _showRegisterSheet(
                                                    context); // open register sheet
                                              },
                                              child: Text(
                                                  "Don't have an account? Register"),
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 16),

                                      // Divider with Text
                                      if (!showOtpField)
                                        Row(
                                          children: [
                                            const Expanded(
                                                child: Divider(thickness: 1)),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8.0),
                                              child: Text("Or Login Via",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black54)),
                                            ),
                                            const Expanded(
                                                child: Divider(thickness: 1)),
                                          ],
                                        ),

                                      const SizedBox(height: 16),

                                      // Google Login
                                      if (!showOtpField)
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
                                                  decoration:
                                                      const BoxDecoration(
                                                          color: Colors.grey,
                                                          shape:
                                                              BoxShape.circle),
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
                                                            fit: BoxFit.contain,
                                                            width: 29,
                                                            height: 29,
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text("Google",
                                                    style: TextStyle(
                                                        fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 20),

                                      // Terms & Conditions
                                      Column(
                                        children: [
                                          Text.rich(
                                            TextSpan(
                                              text:
                                                  "By logging in, I understand & agree to Wise Travel India Limited ",
                                              style:
                                                  CommonFonts.bodyText3Medium,
                                              children: [
                                                TextSpan(
                                                    text: "Terms & Conditions",
                                                    style: CommonFonts
                                                        .bodyText3MediumBlue),
                                                TextSpan(text: ", "),
                                                TextSpan(
                                                    text: "Privacy Policy",
                                                    style: CommonFonts
                                                        .bodyText3MediumBlue),
                                                TextSpan(
                                                    text:
                                                        ", and User agreement",
                                                    style: CommonFonts
                                                        .bodyText3MediumBlue),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
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
    Offers(),
    ManageBookings(),
    Contact(),
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
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w400),
              type: BottomNavigationBarType.fixed,
              items: [
                _buildBarItem(Icons.house, 'Home', 0),
                _buildBarItem(Icons.local_offer_outlined, 'Services', 1),
                _buildBarItem(Icons.work_outline, 'Bookings', 2),
                _buildBarItem(Icons.phone, 'Contact', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OtpTextField extends StatefulWidget {
  final TextEditingController otpController;
  final String mobileNo;
  OtpTextField(
      {super.key, required this.otpController, required this.mobileNo});
  @override
  State<OtpTextField> createState() => _OtpTextFieldState();
}

class _OtpTextFieldState extends State<OtpTextField> {
  bool hasError = false;

  int secondsRemaining = 20;
  bool enableResend = false;
  Timer? _timer;
  final ResendOtpController resendOtpController =
      Get.put(ResendOtpController());

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      enableResend = false;
      secondsRemaining = 20;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining == 0) {
        timer.cancel();
        setState(() {
          enableResend = true;
        });
      } else {
        setState(() {
          secondsRemaining--;
        });
      }
    });
  }

  void _resendOtp() async {
    widget.otpController.clear();
    await resendOtpController
        .verifyResendOtp(mobile: widget.mobileNo, context: context)
        .then((value) {
      _startCountdown(); // Restart timer
    });
  }

  void _validateOtp(String value) {
    if (value.length == 6) {
      // validate OTP here
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      onChanged: _validateOtp,
      decoration: InputDecoration(
        hintText: "Enter OTP",
        counterText: "",
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.key),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 0, left: 12),
          child: SizedBox(
            width: 100,
            child: enableResend
                ? TextButton(
                    onPressed: _resendOtp,
                    child: const Text(
                      "Resend OTP",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue2),
                    ),
                  )
                : Center(
                    child: Text(
                      "00:${secondsRemaining.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
