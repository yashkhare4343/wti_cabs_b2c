import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/common_widget/buttons/outline_button.dart';
import 'package:wti_cabs_user/core/controller/banner/banner_controller.dart';
import 'package:wti_cabs_user/core/controller/manage_booking/upcoming_booking_controller.dart';
import 'package:wti_cabs_user/core/controller/popular_destination/popular_destination.dart';
import 'package:wti_cabs_user/core/controller/usp_controller/usp_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

import '../../common_widget/loader/popup_loader.dart';
import '../../core/controller/auth/mobile_controller.dart';
import '../../core/controller/auth/otp_controller.dart';
import '../../core/controller/auth/register_controller.dart';
import '../../core/controller/auth/resend_otp_controller.dart';
import '../../core/controller/currency_controller/currency_controller.dart';
import '../../core/controller/download_receipt/download_receipt_controller.dart';
import '../../core/controller/profile_controller/profile_controller.dart';
import '../../core/services/storage_services.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../bottom_nav/bottom_nav.dart';
import '../user_fill_details/user_fill_details.dart';

class ManageBookings extends StatefulWidget {
  @override
  _ManageBookingsState createState() => _ManageBookingsState();
}

class _ManageBookingsState extends State<ManageBookings> with SingleTickerProviderStateMixin {
  final UpcomingBookingController upcomingBookingController =
  Get.put(UpcomingBookingController());
  String convertUtcToLocal(String utcTimeString, String timezoneString) {
    // Parse UTC time
    DateTime utcTime = DateTime.parse(utcTimeString);

    // Get the location based on timezone string like "Asia/Kolkata"
    final location = tz.getLocation(timezoneString);

    // Convert UTC to local time in given timezone
    final localTime = tz.TZDateTime.from(utcTime, location);

    // Format the local time as "28 July, 2025"
    final formatted = DateFormat("d MMMM, yyyy, hh:mm a").format(localTime);

    return formatted;
  }

  int selectedDriveType = 0; // 0: Chauffeur's, 1: Self Drive
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    upcomingBookingController.isLoggedIn.value == true ? upcomingBookingController.fetchUpcomingBookingsData() : upcomingBookingController.reset();
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0.7,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Illustration or image can be added here
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(Icons.lock_outline, size: 48, color: Colors.blue.shade400),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Log in to view your bookings",
                    textAlign: TextAlign.center,
                    style: CommonFonts.headline2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Access, manage, and update your bookings securely.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: MainButton(text: 'Login', onPressed: (){
                      _showAuthBottomSheet();
                    }),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
    final ProfileController profileController = Get.put(ProfileController());

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

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserFillDetails(
              name: result?.user?.displayName ?? '',
              email: result?.user?.email ?? '',
              phone: result?.user?.phoneNumber ?? ''), // your login widget
        ),
      );

      // if (result != null) {
      //   final Map<String, dynamic> requestData = {
      //     "firstName": result.user?.displayName,
      //     // "lastName": "Sahni",
      //     "contact": result.user?.phoneNumber ?? '000000000',
      //     "contactCode": "91",
      //     "countryName": "India",
      //     // "address": "String",
      //     // "city": "String",
      //     "gender": "MALE",
      //     // "postalCode": "String",
      //     "emailID": result.user?.email
      //     // "password": "String"
      //     // "otp": {
      //     //     "code": "Number",
      //     //     "otpExpiry": ""
      //     // }
      //   };
      //   await registerController
      //       .verifySignup(requestData: requestData, context: context)
      //       .then((value) {
      //     Navigator.of(context).pop();
      //   });
      //   print("✅ User signed in: ${result.user?.email}");
      //
      //   // close the bottom sheet
      // } else {
      //   print("❌ Google Sign-In cancelled or failed");
      // }
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
                return ClipRRect(
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
                                                      phone: ''), // your login widget
                                                ),
                                              );   // open register sheet
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
                );
              },
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final driveTypes = ["Chauffeur's Drive"];

    return PopScope(
      canPop: false, // 🚀 Stops the default "pop and close app"
      onPopInvoked: (didPop) {
        // This will be called for hardware back and gesture
        GoRouter.of(context).go(AppRoutes.initialPage);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Manage Bookings",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.scaffoldBgPrimary1,
          automaticallyImplyLeading: false,
          // leading: Icon(
          //   Icons.arrow_back,
          //   color: Colors.black,
          //   size: 20,
          // ),
        ),
        backgroundColor: AppColors.scaffoldBgPrimary1,
        body: Obx((){
          if(upcomingBookingController.isLoading.value){
            return ListView.builder(
                 itemCount: 5,
                itemBuilder: (context, index){
                   return Container(
                     height: 120,
                       margin: EdgeInsets.only(bottom: 8, left: 16, ),
                       child: BookingCardShimmer());
                });
          }
          if (upcomingBookingController.isLoggedIn.value == false) {
            return _buildLoginPrompt(context);
          }
         return Column(
            children: [
              SizedBox(height: 12),
              // Drive Type Toggle
              Container(
                // height: 46,
                width: MediaQuery.of(context).size.width * 0.8,
                // padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: StorageServices.instance.read('token')==null ? Center(
                    child: MainButton(text: 'Login/Register', onPressed: (){
                    }),
                  ) : Row(
                    children: List.generate(1, (index) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedDriveType = index),
                          child: Container(
                            padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedDriveType == index
                                  ? Color(0xFF002CC0)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              driveTypes[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: selectedDriveType == index
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Color(0xFF002CC0),
                  unselectedLabelColor: Color(0xFF494949),
                  indicatorColor: Color(0xFF002CC0),
                  labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF002CC0)),
                  tabs: [
                    Tab(
                      text: "Upcoming",
                    ),
                    Tab(text: "Completed"),
                    Tab(text: "Cancelled"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Upcoming
                    BookingList(),
                    // Completed (empty for now)
                    CompletedBookingList(),
                    // Cancelled (empty for now)
                    CanceledBookingList(),
                  ],
                ),
              ),
            ],
          );
        })
      ),
    );
  }
}

class BookingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use a ListView.builder for dynamic data
    return BookingCard();
  }
}

class BookingCard extends StatefulWidget {
  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  final UpcomingBookingController upcomingBookingController =
  Get.put(UpcomingBookingController());
  final PdfDownloadController pdfCtrl = Get.put(PdfDownloadController());
  final CurrencyController currencyController = Get.put(CurrencyController());

  String? convertUtcToLocal(String? utcTimeString, String timezoneString) {
    if (utcTimeString == null || utcTimeString.isEmpty) return null;

    try {
      // Initialize timezones only once, ideally in main()
      tz.initializeTimeZones();

      final utcTime = DateTime.parse(utcTimeString); // This was throwing
      final location = tz.getLocation(timezoneString);
      final localTime = tz.TZDateTime.from(utcTime, location);

      // Format: 25 July 2025, 05:34 PM
      return DateFormat("d MMMM yyyy, \n hh:mm a").format(localTime);
    } catch (e) {
      debugPrint("Date conversion error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (upcomingBookingController.upcomingBookingResponse.value?.result ==
          null) {
        return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: upcomingBookingController.confirmedBookings?.length,
            itemBuilder: (BuildContext context, int index) {
              return BookingCardShimmer();
            });

        // ⏳ Show loading until data is ready
      }

      if (upcomingBookingController.confirmedBookings.isNotEmpty) {
        Center(
          child: Text('No Upcoming Booking Found'),
        );
      }

      return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: upcomingBookingController.confirmedBookings?.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              elevation: 0,
              color: Colors.white,
              margin: EdgeInsets.only(bottom: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(width: 1, color: Color(0xFFCECECE)),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
// Car Row
                    Row(
                      children: [
// Image
                        Image.network(
                          upcomingBookingController.confirmedBookings?[index]
                              .vehicleDetails?.imageUrl ??
                              '',
                          width: 84,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/inventory_car.png',
                              width: 84,
                              height: 64,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                        SizedBox(width: 12),

// Car Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                upcomingBookingController
                                    .confirmedBookings?[index]
                                    .vehicleDetails
                                    ?.type ??
                                    "",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF373737)),
                              ),
                              SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Booking ID: ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF929292),
                                          fontWeight: FontWeight.w500),
                                    ),
                                    TextSpan(
                                      text: upcomingBookingController
                                          .confirmedBookings?[index].id,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF222222),
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Booking Type: ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF929292),
                                          fontWeight: FontWeight.w500),
                                    ),
                                    TextSpan(
                                      text: upcomingBookingController
                                          .confirmedBookings?[index]
                                          .tripTypeDetails
                                          ?.tripType ??
                                          '',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF002CC0),
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 2),
                              FutureBuilder<double>(
                                future: currencyController.convertPrice(
                                  upcomingBookingController
                                      .confirmedBookings?[index]
                                      .recieptId
                                      ?.fareDetails
                                      ?.amountPaid
                                      ?.toDouble() ??
                                      0.0,
                                ),
                                builder: (context, snapshot) {
                                  final convertedValue = snapshot.data ??
                                      upcomingBookingController
                                          .confirmedBookings?[index]
                                          .recieptId
                                          ?.fareDetails
                                          ?.amountPaid
                                          ?.toDouble() ??
                                      0.0;

                                  return Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Paid Amount: ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF929292),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                          "${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF2B2B2B),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                              ,
                            ],
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 12),
                    Divider(
                      thickness: 1,
                      color: Color(0xFFF2F2F2),
                    ),
                    SizedBox(height: 12),
// Pickup and Drop
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    RotationTransition(
                                        turns: new AlwaysStoppedAnimation(
                                            40 / 360),
                                        child: Icon(Icons.navigation_outlined,
                                            size: 16,
                                            color: Color(0xFF002CC0))),
                                    SizedBox(width: 4),
                                    Text("Pickup",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF002CC0),
                                            fontWeight: FontWeight.w500)),
                                  ]),
                              SizedBox(height: 2),
                              Text(
                                  upcomingBookingController
                                      .confirmedBookings?[index]
                                      .source
                                      ?.address ??
                                      'Source not found',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF333333),
                                      fontWeight: FontWeight.w600)),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/calendar_clock.svg',
                                    height: 12,
                                    width: 12,
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                      convertUtcToLocal(
                                          upcomingBookingController
                                              .confirmedBookings?[index]
                                              .startTime
                                              .toString() ??
                                              '',
                                          upcomingBookingController
                                              .confirmedBookings?[index]
                                              .timezone ??
                                              '') ??
                                          'No Pickup Date Found',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF808080),
                                          fontWeight: FontWeight.w400),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 75,
                          color: Color(0xFFF2F2F2),
                          margin: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(Icons.pin_drop_outlined,
                                        size: 16, color: Color(0xFF002CC0)),
                                    SizedBox(width: 4),
                                    Text("Drop",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF002CC0),
                                            fontWeight: FontWeight.w500)),
                                  ]),
                              SizedBox(height: 2),
                              Text(
                                  upcomingBookingController
                                      .confirmedBookings?[index]
                                      .destination
                                      ?.address ??
                                      "Destination not found",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF333333),
                                      fontWeight: FontWeight.w600)),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/calendar_clock.svg',
                                    height: 12,
                                    width: 12,
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  if(upcomingBookingController.confirmedBookings[index].countryName?.toLowerCase() == 'india')
                                  (upcomingBookingController
                                      .confirmedBookings[index].tripTypeDetails?.basicTripType == 'LOCAL') ? SizedBox() :  Text(
                                      convertUtcToLocal(
                                          upcomingBookingController
                                              .confirmedBookings[index]
                                              .endTime
                                              .toString() ??
                                              '',
                                          upcomingBookingController
                                              .confirmedBookings[index]
                                              .timezone ??
                                              '') ??
                                          'No Drop Date Found',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF808080),
                                          fontWeight: FontWeight.w400)),
                                  if(upcomingBookingController.confirmedBookings[index].countryName?.toLowerCase() != 'india')
                                    Text(
                                        convertUtcToLocal(
                                            upcomingBookingController
                                                .confirmedBookings[index]
                                                .endTime
                                                .toString() ??
                                                '',
                                            upcomingBookingController
                                                .confirmedBookings[index]
                                                .timezone ??
                                                '') ??
                                            'No Drop Date Found',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF808080),
                                            fontWeight: FontWeight.w400)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        CommonOutlineButton(
                          text: 'Download Receipt',
                          onPressed: pdfCtrl.isDownloading.value
                              ? () {}
                              : () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const PopupLoader(
                                message: 'Downloading Receipt....',
                              ),
                            );
                            await pdfCtrl
                                .downloadReceiptPdf(
                                upcomingBookingController.confirmedBookings
                                    [index].id ??
                                    '',
                                context)
                                .then((value) {
                              GoRouter.of(context).pop();
                            });
                          },
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            final booking = upcomingBookingController.confirmedBookings?[index];
                            if (booking != null) {
                              final bookingMap = {
                                "id": booking.id,
                                "vehicleType": booking.vehicleDetails?.type,
                                "pickup": booking.source?.address,
                                "drop": booking.destination?.address,
                                "tripType": booking.tripTypeDetails?.tripType,
                                "amountPaid": booking.recieptId?.fareDetails?.amountPaid,
                                "startTime": booking.startTime,
                                "endTime": booking.endTime,
                                "timezone": booking.timezone,
                                "paymentId" : booking.razorpayPaymentId,
                                "recieptId" : booking.razorpayReceiptId
                              };

                              context.push('/cancelBooking', extra: bookingMap);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.mainButtonBg, // Background color
                            foregroundColor:
                            Colors.white, // Text (and ripple) color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                          child: Text(
                            'Manage Booking',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
    });
  }
}


Widget buildDownloadButton({
  required String title,
  required VoidCallback onPressed,
}) {
  return OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.mainButtonBg, // Text & icon color
      side: BorderSide(color: AppColors.mainButtonBg), // Border color
      minimumSize: Size(double.infinity, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    icon: Icon(
      Icons.download,
      color: AppColors.mainButtonBg,
    ),
    label: Text(title),
    onPressed: onPressed,
  );
}

// completed bookings
class CompletedBookingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use a ListView.builder for dynamic data
    return CompletedBookingCard();
  }
}

class CompletedBookingCard extends StatefulWidget {
  @override
  State<CompletedBookingCard> createState() => _CompletedBookingCardState();
}

class _CompletedBookingCardState extends State<CompletedBookingCard> {
  final UpcomingBookingController upcomingBookingController =
  Get.put(UpcomingBookingController());
  final PdfDownloadController pdfCtrl = Get.put(PdfDownloadController());
  final CurrencyController currencyController = Get.put(CurrencyController());

  String? convertUtcToLocal(String? utcTimeString, String timezoneString) {
    if (utcTimeString == null || utcTimeString.isEmpty) return null;

    try {
      // Initialize timezones only once, ideally in main()
      tz.initializeTimeZones();

      final utcTime = DateTime.parse(utcTimeString); // This was throwing
      final location = tz.getLocation(timezoneString);
      final localTime = tz.TZDateTime.from(utcTime, location);

      // Format: 25 July 2025, 05:34 PM
      return DateFormat("d MMMM yyyy, hh:mm a").format(localTime);
    } catch (e) {
      debugPrint("Date conversion error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (upcomingBookingController.isLoading.value) {
        return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: upcomingBookingController.completedBookings?.length,
            itemBuilder: (BuildContext context, int index) {
              return BookingCardShimmer();
            });

        // ⏳ Show loading until data is ready
      }

      if (upcomingBookingController.completedBookings.isEmpty) {
        return Center(
          child: Text('No Completed Booking Found'),
        );
      }

      return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: upcomingBookingController.completedBookings?.length,
          itemBuilder: (BuildContext context, int index) {
            return Stack(
              children: [
                Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: EdgeInsets.only(bottom: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(width: 1, color: Color(0xFFCECECE)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Car Row
                        Row(
                          children: [
                            // Image
                            Image.network(
                              upcomingBookingController
                                  .completedBookings?[index]
                                  .vehicleDetails
                                  ?.imageUrl ??
                                  '',
                              width: 84,
                              height: 64,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/inventory_car.png',
                                  width: 84,
                                  height: 64,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                            SizedBox(width: 12),

                            // Car Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    upcomingBookingController
                                        .completedBookings?[index]
                                        .vehicleDetails
                                        ?.type ??
                                        "",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF373737)),
                                  ),
                                  SizedBox(height: 2),
                                  FutureBuilder<double>(
                                    future: currencyController.convertPrice(
                                      upcomingBookingController
                                          .completedBookings?[index]
                                          .recieptId
                                          ?.fareDetails
                                          ?.amountPaid
                                          ?.toDouble() ??
                                          0.0,
                                    ),
                                    builder: (context, snapshot) {
                                      final convertedValue = snapshot.data ??
                                          upcomingBookingController
                                              .completedBookings?[index]
                                              .recieptId
                                              ?.fareDetails
                                              ?.amountPaid
                                              ?.toDouble() ??
                                          0.0;

                                      return Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'Paid Amount: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF929292),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                              "${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF2B2B2B),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Booking Type: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF929292),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        TextSpan(
                                          text: upcomingBookingController
                                              .completedBookings?[index]
                                              .tripTypeDetails
                                              ?.tripType ??
                                              '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF002CC0),
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Paid Amount: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF929292),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        TextSpan(
                                          text: upcomingBookingController
                                              .completedBookings?[index]
                                              .recieptId
                                              ?.fareDetails
                                              ?.amountPaid
                                              .toString() ??
                                              '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF2B2B2B),
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 12),
                        Divider(
                          thickness: 1,
                          color: Color(0xFFF2F2F2),
                        ),
                        SizedBox(height: 12),
                        // Pickup and Drop
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        RotationTransition(
                                            turns: new AlwaysStoppedAnimation(
                                                40 / 360),
                                            child: Icon(
                                                Icons.navigation_outlined,
                                                size: 16,
                                                color: Color(0xFF002CC0))),
                                        SizedBox(width: 4),
                                        Text("Pickup",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF002CC0),
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                  SizedBox(height: 2),
                                  Text(
                                      upcomingBookingController
                                          .completedBookings?[index]
                                          .source
                                          ?.address ??
                                          'Source not found',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/calendar_clock.svg',
                                        height: 12,
                                        width: 12,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                          convertUtcToLocal(
                                              upcomingBookingController
                                                  .completedBookings?[
                                              index]
                                                  .startTime
                                                  .toString() ??
                                                  '',
                                              upcomingBookingController
                                                  .completedBookings?[
                                              index]
                                                  .timezone ??
                                                  '') ??
                                              'No Pickup Date Found',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF808080),
                                              fontWeight: FontWeight.w400)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 75,
                              color: Color(0xFFF2F2F2),
                              margin: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        Icon(Icons.pin_drop_outlined,
                                            size: 16, color: Color(0xFF002CC0)),
                                        SizedBox(width: 4),
                                        Text("Drop",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF002CC0),
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                  SizedBox(height: 2),
                                  Text(
                                      upcomingBookingController
                                          .completedBookings?[index]
                                          .destination
                                          ?.address ??
                                          "Destination not found",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/calendar_clock.svg',
                                        height: 12,
                                        width: 12,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      (upcomingBookingController
                                          .completedBookings[index].tripTypeDetails?.basicTripType == 'LOCAL') ? SizedBox() :   Text(
                                          convertUtcToLocal(
                                              upcomingBookingController
                                                  .completedBookings[
                                              index]
                                                  .endTime
                                                  .toString() ??
                                                  '',
                                              upcomingBookingController
                                                  .completedBookings[
                                              index]
                                                  .timezone ??
                                                  '') ??
                                              'No Drop Date Found',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF808080),
                                              fontWeight: FontWeight.w400)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            upcomingBookingController
                                .confirmedBookings[index].countryName
                                ?.toLowerCase() ==
                                'india'
                                ? CommonOutlineButton(
                              text: 'Download Invoice',
                              onPressed: () async {
                                // TODO: downloadInvoicePdf()
                                showDialog(
                                  context: context,
                                  barrierDismissible:
                                  false,
                                  builder: (_) =>
                                  const PopupLoader(
                                    message:
                                    'Downloading Invoice...',
                                  ),
                                );
                                await pdfCtrl
                                    .downloadChauffeurEInvoice(
                                    context:
                                    context,
                                    objectId: await StorageServices
                                        .instance
                                        .read(
                                        'reservationId') ??
                                        '')
                                    .then((value) {
                                  GoRouter.of(context)
                                      .pop();
                                });
                              },
                            )
                                : SizedBox(),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: pdfCtrl.isDownloading.value
                                  ? () {}
                                  : () async {
                                await pdfCtrl
                                    .downloadReceiptPdf(
                                    upcomingBookingController
                                        .completedBookings[index].id ??
                                        '',
                                    context)
                                    .then((value) {
                                  GoRouter.of(context).pop();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                AppColors.mainButtonBg, // Background color
                                foregroundColor:
                                Colors.white, // Text (and ripple) color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                              child: Text(
                                'Manage Booking',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ))
              ],
            );
          });
    });
  }
}

// canceled bookings
class CanceledBookingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use a ListView.builder for dynamic data
    return CanceledBookingCard();
  }
}

class CanceledBookingCard extends StatefulWidget {
  @override
  State<CanceledBookingCard> createState() => _CanceledBookingCardState();
}

class _CanceledBookingCardState extends State<CanceledBookingCard> {
  final UpcomingBookingController upcomingBookingController =
  Get.put(UpcomingBookingController());
  final PdfDownloadController pdfCtrl = Get.put(PdfDownloadController());
  final CurrencyController currencyController = Get.put(CurrencyController());

  String? convertUtcToLocal(String? utcTimeString, String timezoneString) {
    if (utcTimeString == null || utcTimeString.isEmpty) return null;

    try {
      // Initialize timezones only once, ideally in main()
      tz.initializeTimeZones();

      final utcTime = DateTime.parse(utcTimeString); // This was throwing
      final location = tz.getLocation(timezoneString);
      final localTime = tz.TZDateTime.from(utcTime, location);

      // Format: 25 July 2025, 05:34 PM
      return DateFormat("d MMMM yyyy, hh:mm a").format(localTime);
    } catch (e) {
      debugPrint("Date conversion error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (upcomingBookingController.isLoading.value) {
        return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: upcomingBookingController.cancelledBookings?.length,
            itemBuilder: (BuildContext context, int index) {
              return BookingCardShimmer();
            });

        // ⏳ Show loading until data is ready
      }

      if (upcomingBookingController.cancelledBookings.value.isEmpty) {
        return Center(
          child: Text('No Cancelled Booking Found'),
        );
        // ⏳ Show loading until data is ready
      }

      return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: upcomingBookingController.cancelledBookings?.length,
          itemBuilder: (BuildContext context, int index) {
            return Stack(
              children: [
                Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: EdgeInsets.only(bottom: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(width: 1, color: Color(0xFFCECECE)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Car Row
                        Row(
                          children: [
                            // Image
                            Image.network(
                              upcomingBookingController
                                  .cancelledBookings?[index]
                                  .vehicleDetails
                                  ?.imageUrl ??
                                  '',
                              width: 84,
                              height: 64,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/inventory_car.png',
                                  width: 84,
                                  height: 64,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                            SizedBox(width: 12),

                            // Car Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    upcomingBookingController
                                        .cancelledBookings?[index]
                                        .vehicleDetails
                                        ?.type ??
                                        "",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF373737)),
                                  ),
                                  SizedBox(height: 2),
                                  FutureBuilder<double>(
                                    future: currencyController.convertPrice(
                                      upcomingBookingController
                                          .cancelledBookings?[index]
                                          .recieptId
                                          ?.fareDetails
                                          ?.amountPaid
                                          ?.toDouble() ??
                                          0.0,
                                    ),
                                    builder: (context, snapshot) {
                                      final convertedValue = snapshot.data ??
                                          upcomingBookingController
                                              .cancelledBookings?[index]
                                              .recieptId
                                              ?.fareDetails
                                              ?.amountPaid
                                              ?.toDouble() ??
                                          0.0;

                                      return Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'Paid Amount: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF929292),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                              "${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF2B2B2B),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Booking Type: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF929292),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        TextSpan(
                                          text: upcomingBookingController
                                              .cancelledBookings?[index]
                                              .tripTypeDetails
                                              ?.tripType ??
                                              '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF002CC0),
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Paid Amount: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF929292),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        TextSpan(
                                          text: upcomingBookingController
                                              .cancelledBookings?[index]
                                              .recieptId
                                              ?.fareDetails
                                              ?.amountPaid
                                              .toString() ??
                                              '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF2B2B2B),
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 12),
                        Divider(
                          thickness: 1,
                          color: Color(0xFFF2F2F2),
                        ),
                        SizedBox(height: 12),
                        // Pickup and Drop
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        RotationTransition(
                                            turns: new AlwaysStoppedAnimation(
                                                40 / 360),
                                            child: Icon(
                                                Icons.navigation_outlined,
                                                size: 16,
                                                color: Color(0xFF002CC0))),
                                        SizedBox(width: 4),
                                        Text("Pickup",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF002CC0),
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                  SizedBox(height: 2),
                                  Text(
                                      upcomingBookingController
                                          .cancelledBookings?[index]
                                          .source
                                          ?.address ??
                                          'Source not found',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/calendar_clock.svg',
                                        height: 12,
                                        width: 12,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Expanded(
                                        child: Text(
                                          convertUtcToLocal(
                                              upcomingBookingController
                                                  .cancelledBookings?[index]
                                                  .startTime
                                                  .toString() ??
                                                  '',
                                              upcomingBookingController
                                                  . cancelledBookings?[index]
                                                  .timezone ??
                                                  '') ??
                                              'No Pickup Date Found',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF808080),
                                              fontWeight: FontWeight.w400),
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 75,
                              color: Color(0xFFF2F2F2),
                              margin: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        Icon(Icons.pin_drop_outlined,
                                            size: 16, color: Color(0xFF002CC0)),
                                        SizedBox(width: 4),
                                        Text("Drop",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF002CC0),
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                  SizedBox(height: 2),
                                  (upcomingBookingController
                                      .cancelledBookings[index].tripTypeDetails?.basicTripType == 'LOCAL') ? SizedBox() :   Text(
                                      upcomingBookingController
                                          .cancelledBookings[index]
                                          .destination
                                          ?.address ??
                                          "Destination not found",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/calendar_clock.svg',
                                        height: 12,
                                        width: 12,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Expanded(
                                        child: Text(
                                            convertUtcToLocal(
                                                upcomingBookingController
                                                    .cancelledBookings?[
                                                index]
                                                    .endTime
                                                    .toString() ??
                                                    '',
                                                upcomingBookingController
                                                    .cancelledBookings?[
                                                index]
                                                    .timezone ??
                                                    '') ??
                                                'No Drop Date Found',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF808080),
                                                overflow: TextOverflow.fade,
                                                fontWeight: FontWeight.w400), maxLines: 2,),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            CommonOutlineButton(
                              text: 'Download Receipt',
                              onPressed: pdfCtrl.isDownloading.value
                                  ? () {}
                                  : () async {
                                await pdfCtrl
                                    .downloadReceiptPdf(
                                    upcomingBookingController
                                        .cancelledBookings[index].id ??
                                        '',
                                    context)
                                    .then((value) {
                                  GoRouter.of(context).pop();
                                });
                              },
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Handle button press
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                AppColors.mainButtonBg, // Background color
                                foregroundColor:
                                Colors.white, // Text (and ripple) color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                              child: Text(
                                'Manage Booking',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelled',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ))
              ],
            );
          });
    });
  }
}


class BookingCardShimmer extends StatelessWidget {
  const BookingCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 5, // number of skeleton cards
      itemBuilder: (_, __) {
        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(width: 1, color: Color(0xFFCECECE)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car row
                  Row(
                    children: [
                      Container(
                        width: 84,
                        height: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 14, width: 80, color: Colors.white),
                            const SizedBox(height: 8),
                            Container(height: 12, width: 120, color: Colors.white),
                            const SizedBox(height: 8),
                            Container(height: 12, width: 100, color: Colors.white),
                            const SizedBox(height: 8),
                            Container(height: 12, width: 90, color: Colors.white),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 12),

                  // Pickup and drop row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 12, width: 60, color: Colors.white),
                            const SizedBox(height: 6),
                            Container(height: 12, width: double.infinity, color: Colors.white),
                            const SizedBox(height: 6),
                            Container(height: 12, width: 80, color: Colors.white),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 75, color: Colors.grey[200]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 12, width: 60, color: Colors.white),
                            const SizedBox(height: 6),
                            Container(height: 12, width: double.infinity, color: Colors.white),
                            const SizedBox(height: 6),
                            Container(height: 12, width: 80, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Buttons row
                  Row(
                    children: [
                      Container(height: 32, width: 120, color: Colors.white),
                      const SizedBox(width: 16),
                      Container(height: 32, width: 140, color: Colors.white),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}