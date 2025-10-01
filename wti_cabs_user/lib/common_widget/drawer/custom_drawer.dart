import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
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
    // TODO: implement initState
    super.initState();
    checkLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileController.fetchData();
      // _showBottomSheet();
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
          serverClientId: '880138699529-in25a6554o0jcp0610fucg4s94k56agt.apps.googleusercontent.com', // Web Client ID
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
              initialChildSize: 0.58,
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
                            // Container(
                            //   width: double.infinity,
                            //   padding: const EdgeInsets.all(16),
                            //   decoration: const BoxDecoration(
                            //     color: Color(0xFFFFF6DD),
                            //     borderRadius: BorderRadius.only(
                            //       topLeft: Radius.circular(12),
                            //       topRight: Radius.circular(12),
                            //     ),
                            //   ),
                            //   child: Row(
                            //     children: [
                            //       Expanded(
                            //         child: Column(
                            //           crossAxisAlignment:
                            //           CrossAxisAlignment.start,
                            //           children: [
                            //             Text(
                            //               "Invite & Earn!",
                            //               style: CommonFonts.heading1Bold,
                            //             ),
                            //             const SizedBox(height: 8),
                            //             Text(
                            //               "Invite your Friends & Get Up to",
                            //               style: CommonFonts.bodyText6,
                            //             ),
                            //             Text("INR 2000*",
                            //                 style: CommonFonts.bodyText6Bold),
                            //           ],
                            //         ),
                            //       ),
                            //       Image.asset('assets/images/offer.png',
                            //           width: 85, height: 85),
                            //     ],
                            //   ),
                            // ),

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
                                            try {
                                              final isVerified =
                                              await otpController
                                                  .verifyOtp(
                                                mobile:
                                                phoneController
                                                    .text
                                                    .trim(),
                                                otp:
                                                otpTextEditingController
                                                    .text
                                                    .trim(),
                                                context: context,
                                              );

                                              otpController.hasError
                                                  .value =
                                              !isVerified;

                                              if (isVerified) {
                                                // Show popup loader

                                                // Simulate 1-second wait
                                                await Future.delayed(
                                                    const Duration(
                                                        seconds: 3));
                                                upcomingBookingController
                                                    .isLoggedIn
                                                    .value = true;
                                                await upcomingBookingController
                                                    .fetchUpcomingBookingsData();
                                                // Mark logged in
                                                await profileController
                                                    .fetchData();

                                                GoRouter.of(context)
                                                    .go(AppRoutes
                                                    .profile);

                                                // Navigate
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
                                              // children: [
                                              //   TextSpan(
                                              //       text: "Terms & Conditions",
                                              //       style: CommonFonts
                                              //           .bodyText3MediumBlue),
                                              //   TextSpan(text: ", "),
                                              //   TextSpan(
                                              //       text: "Privacy Policy",
                                              //       style: CommonFonts
                                              //           .bodyText3MediumBlue),
                                              //   TextSpan(
                                              //       text:
                                              //       ", and User agreement",
                                              //       style: CommonFonts
                                              //           .bodyText3MediumBlue),
                                              // ],
                                              children: []
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


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.homebg, // Status bar color set to white
      statusBarIconBrightness: Brightness.dark, // Dark icons for visibility
    ));
    final double width = MediaQuery.of(context).size.width * 0.8;

    // Log Out
    void showLogoutDialog(BuildContext context) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Message
                  Text(
                    'Are you sure you want to Sign out?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
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
                          onPressed: () async{
                            Navigator.of(dialogContext).pop();
                            // 🚀 Sign out from Google if logged in
                            try {
                              final googleSignIn = GoogleSignIn();
                              if (await googleSignIn.isSignedIn()) {
                            await googleSignIn.signOut();
                            await googleSignIn.disconnect(); // optional but cleans up completely
                            }
                              StorageServices.instance.clear();
                              await CacheHelper.clearAllCache();

                              // 🚀 Also clear in-memory observables
                              final upcomingBookingController = Get.find<UpcomingBookingController>();
                              upcomingBookingController.upcomingBookingResponse.value?.result?.clear();
                              upcomingBookingController.isLoggedIn.value = false;
                              // Get.delete<BookingController>(force: true);
// Remove controller from memory
                              upcomingBookingController.reset();

                              // or completely reset the controller
                              // Get.delete<BookingController>(force: true);
                            } catch (e) {
                            debugPrint("Google sign-out failed: $e");
                            }// close popup
                            // Get.deleteAll(force: true);
                            Navigator.of(dialogContext)
                                .pop(); // close popup first

                            // Clear data
                            StorageServices.instance.clear();

                            // Show success popup/snackbar
                            Future.delayed(const Duration(milliseconds: 200),
                                () async{
                              showDialog(
                                context: navigatorKey.currentContext!,
                                barrierDismissible: false,
                                builder: (_) {
                                  // Start auto-close timer
                                  final upcomingBookingController = Get.find<UpcomingBookingController>();
                                  upcomingBookingController.upcomingBookingResponse.value?.result?.clear();
                                  upcomingBookingController.isLoggedIn.value = false;
                                  StorageServices.instance.read('firstName');
                                  StorageServices.instance.read('contact');
                                   StorageServices.instance.read('emailId');
                                  Future.delayed(const Duration(seconds: 4),
                                      () {
                                    if (Navigator.of(
                                            navigatorKey.currentContext!)
                                        .canPop()) {
                                      Navigator.of(navigatorKey.currentContext!).pushReplacement(
                                        MaterialPageRoute(builder: (_) => BottomNavScreen()),
                                      );

                                      // 🚀 Optional: Navigate to login after close
                                      // context.go("/login");
                                    }
                                  });

                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    backgroundColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 24),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.green, size: 60),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Logout Successful",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          "You have been logged out successfully.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    actionsAlignment: MainAxisAlignment.center,
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(
                                                navigatorKey.currentContext!)
                                            .pop(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.mainButtonBg,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                        ),
                                        child: const Text(
                                          "Okay",
                                          style: TextStyle(
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
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
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

    // Delete Account
    void showDeleteDialog(BuildContext context) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Message
                  Text(
                    'Are you sure you want to delete account?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
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
                          onPressed: () async{
                            Navigator.of(dialogContext).pop();
                            // 🚀 Sign out from Google if logged in
                            try {
                              final googleSignIn = GoogleSignIn();
                              if (await googleSignIn.isSignedIn()) {
                                await googleSignIn.signOut();
                                await googleSignIn.disconnect(); // optional but cleans up completely
                              }
                              StorageServices.instance.clear();
                              await CacheHelper.clearAllCache();

                              // 🚀 Also clear in-memory observables
                              final upcomingBookingController = Get.find<UpcomingBookingController>();
                              upcomingBookingController.upcomingBookingResponse.value?.result?.clear();
                              upcomingBookingController.isLoggedIn.value = false;
                              // Get.delete<BookingController>(force: true);
// Remove controller from memory
                              upcomingBookingController.reset();

                              // or completely reset the controller
                              // Get.delete<BookingController>(force: true);
                            } catch (e) {
                              debugPrint("Google sign-out failed: $e");
                            }// close popup
                            // Get.deleteAll(force: true);
                            Navigator.of(dialogContext)
                                .pop(); // close popup first

                            // Clear data
                            StorageServices.instance.clear();

                            // Show success popup/snackbar
                            Future.delayed(const Duration(milliseconds: 200),
                                    () async{
                                  showDialog(
                                    context: navigatorKey.currentContext!,
                                    barrierDismissible: false,
                                    builder: (_) {
                                      // Start auto-close timer
                                      final upcomingBookingController = Get.find<UpcomingBookingController>();
                                      upcomingBookingController.upcomingBookingResponse.value?.result?.clear();
                                      upcomingBookingController.isLoggedIn.value = false;
                                      StorageServices.instance.read('firstName');
                                      StorageServices.instance.read('contact');
                                      StorageServices.instance.read('emailId');
                                      Future.delayed(const Duration(seconds: 4),
                                              () {
                                            if (Navigator.of(
                                                navigatorKey.currentContext!)
                                                .canPop()) {
                                              Navigator.of(navigatorKey.currentContext!).pushReplacement(
                                                MaterialPageRoute(builder: (_) => BottomNavScreen()),
                                              );

                                              // 🚀 Optional: Navigate to login after close
                                              // context.go("/login");
                                            }
                                          });

                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(16)),
                                        backgroundColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 24),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.green, size: 60),
                                            const SizedBox(height: 16),
                                            const Text(
                                              "Delete Account Successful",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              "Account has been deleted successfully.",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                        actionsAlignment: MainAxisAlignment.center,
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(
                                                navigatorKey.currentContext!)
                                                .pop(),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                              AppColors.mainButtonBg,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 24, vertical: 12),
                                            ),
                                            child: const Text(
                                              "Okay",
                                              style: TextStyle(
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
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



    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          // height: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(34),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset(
                      'assets/images/wti_logo.svg',
                      height: 22,
                      width: 47,
                    ),
                    // InkWell(
                    //   splashColor: Colors.transparent,
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //   },
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       color: Color(0xFFE6EAF9),
                    //       borderRadius: BorderRadius.circular(4),
                    //     ),
                    //     padding: EdgeInsets.all(6.0),
                    //     child: Icon(
                    //       Icons.arrow_back,
                    //       size: 16,
                    //       color: Color(0xFF192653),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                const Divider(),
                SizedBox(
                  height: 8,
                ),

                /// Drawer Items
                // Obx((){
                //   return _buildDrawerItem(
                //     icon: SvgPicture.asset(
                //       'assets/images/india_logo.svg',
                //       height: 16,
                //       width: 24,
                //     ),
                //     title: 'Country',
                //     subtitle: currencyController.country.value,
                //     onTap: () {},
                //   );
                // }),
   Obx((){
                  return _buildDrawerItem(
                    icon: upcomingBookingController.isLoggedIn.value == true? SizedBox(
                      width:30,height: 30,
                      child: NameInitialHomeCircle(
                          name: profileController.profileResponse
                              .value?.result?.firstName ??
                              ''),
                    ) : Icon(Icons.person, color: Colors.grey,),
                    title: 'Profile',
                    subtitle: currencyController.country.value,
                    onTap: () async{
                      if (await StorageServices.instance
                          .read('token') ==
                      null) {
                      _showAuthBottomSheet();
                      }
                      if (await StorageServices.instance
                          .read('token') !=
                      null) {
                      GoRouter.of(context)
                          .push(AppRoutes.profile);
                      }
                    },
                  );
                }),
                _buildDrawerItem(
                  icon: Icon(Icons.work_outline, color: Colors.grey,),
                  title: 'Manage Bookings',
                  subtitle: 'Easily manage or cancel your rides anytime',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => BottomNavScreen(initialIndex: 1,)));
                  },
                ),
                Obx((){
                  return _buildDrawerItem(
                    icon: SvgPicture.asset(
                      'assets/images/payments.svg',
                      height: 20,
                      width: 20,
                    ),
                    title: 'Currency (${currencyController.selectedCurrency.value.code})',
                    subtitle: currencyController.selectedCurrency.value.code,
                    onTap: () {
                      GoRouter.of(context).push(AppRoutes.selectCurrency);
                    },
                  );
                }),
              _buildDrawerItem(
                icon: Icon(Icons.phone, color: Colors.grey,),
                title: 'Contact Us',
                subtitle: 'Get in Touch',
                onTap: () {
                  GoRouter.of(context).push(AppRoutes.contact);
                },
              ),
                // Obx((){
                //   return _buildDrawerItem(
                //     icon: Icon(Icons.phone),
                //     title: 'Contact Us',
                //     subtitle: 'Get in Touch',
                //     onTap: () {
                //       GoRouter.of(context).push(AppRoutes.selectCurrency);
                //     },
                //   );
                // }),

                // _buildDrawerItem(
                //   icon: SvgPicture.asset(
                //     'assets/images/refer.svg',
                //     height: 20,
                //     width: 20,
                //   ),
                //   title: 'Refer & Earn',
                //   subtitle: 'Driving Licence, Passport, ID etc.',
                //   onTap: () {},
                // ),
                // _buildDrawerItem(
                //   icon: SvgPicture.asset(
                //     'assets/images/language.svg',
                //     height: 20,
                //     width: 20,
                //   ),
                //   title: 'Language',
                //   subtitle: 'English',
                //   onTap: () {},
                // ),
                // _buildDrawerItem(
                //   icon: SvgPicture.asset(
                //     'assets/images/docs.svg',
                //     height: 20,
                //     width: 20,
                //   ),
                //   title: 'Documents',
                //   subtitle: 'Driving Licence, Passport, ID etc.',
                //   onTap: () {},
                // ),
                // _buildDrawerItem(
                //   icon: SvgPicture.asset(
                //     'assets/images/legal.svg',
                //     height: 20,
                //     width: 20,
                //   ),
                //   title: 'Legal',
                //   subtitle: 'Privacy Policy, Terms & Conditions',
                //   onTap: () {},
                // ),
                isLogin == true ? _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/logout.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Sign Out',
                  subtitle: 'You will be signed out of your account.',
                  onTap: () {
                    showLogoutDialog(context);
                  },
                ) : SizedBox(),
                isLogin == true ? _buildDrawerItem(
                  icon: Icon(Icons.delete_forever_outlined, color: Colors.redAccent,),
                  title: 'Delete',
                  subtitle: 'You will be signed out of your account.',
                  onTap: () {
                    showDeleteDialog(context);
                  },
                ) : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required Widget icon, // Accepts any widget now
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFFE2E2E2), // Change as needed
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
                width: 24, height: 24, child: icon), // Consistent icon size
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFF3F3F3F)),
                  ),
                  // SizedBox(
                  //   height: 4,
                  // ),
                  // Text(
                  //   subtitle,
                  //   style: const TextStyle(
                  //     color: Color(0xFF929292),
                  //     fontWeight: FontWeight.w500,
                  //     fontSize: 10,
                  //   ),
                  // ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Color(0xFF919191),
            ),
          ],
        ),
      ),
    );
  }
}
