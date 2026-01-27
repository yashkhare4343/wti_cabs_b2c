import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
import 'package:wti_cabs_user/screens/my_account/my_account.dart';
import 'package:wti_cabs_user/screens/offers/offers.dart';
import 'package:wti_cabs_user/screens/profile/profile.dart';

import '../../common_widget/loader/popup_loader.dart';
import '../../core/controller/banner/banner_controller.dart';
import '../../core/controller/booking_ride_controller.dart';
import '../../core/controller/choose_pickup/choose_pickup_controller.dart';
import '../../core/controller/currency_controller/currency_controller.dart';
import '../../core/controller/drop_location_controller/drop_location_controller.dart';
import '../../core/controller/manage_booking/upcoming_booking_controller.dart';
import '../../core/controller/popular_destination/popular_destination.dart';
import '../../core/controller/source_controller/source_controller.dart';
import '../../core/controller/usp_controller/usp_controller.dart';
import '../../core/services/storage_services.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../trip_history_controller/trip_history_controller.dart';
import '../user_fill_details/user_fill_details.dart';

class BottomNavScreen extends StatefulWidget {
  final int? initialIndex;
  const BottomNavScreen({super.key, this.initialIndex});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  final LocationController locationController = Get.put(LocationController());
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  final PopularDestinationController popularDestinationController =
      Get.put(PopularDestinationController());
  final UspController uspController = Get.put(UspController());
  final BannerController bannerController = Get.put(BannerController());

  final TripHistoryController tripController = Get.put(TripHistoryController());
  final PlaceSearchController searchController =
      Get.put(PlaceSearchController());
  final PlaceSearchController placeSearchController =
      Get.put(PlaceSearchController());
  final SourceLocationController sourceController =
      Get.put(SourceLocationController());
  final DestinationLocationController destinationLocationController =
      Get.put(DestinationLocationController());
  final UpcomingBookingController upcomingBookingController =
      Get.put(UpcomingBookingController());
  @override
  void initState() {
    super.initState();
    // Register as WidgetsBindingObserver to listen for lifecycle changes
    _selectedIndex = widget.initialIndex ?? 0; // default to 0 if null
    WidgetsBinding.instance.addObserver(this);
    // Fetch location and show bottom sheet
    _setStatusBarColor();
    _saveModulePreference(); // Track that user is accessing personal/retail module
  }

  Future<void> _saveModulePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lastSelectedModule", "personal");
  }

  void homeApiLoading() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await popularDestinationController.fetchPopularDestinations();
      // await StorageServices.instance.read('token') != null
      //     ? null
      //     : _showAuthBottomSheet();
    });
    // await uspController.fetchUsps();
    // await bannerController.fetchImages();
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
          serverClientId:
              '880138699529-in25a6554o0jcp0610fucg4s94k56agt.apps.googleusercontent.com', // Web Client ID
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
                                                mobileController.text.trim() ??
                                                    '0000000000',
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
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
                                      SizedBox(
                                        width: 24,
                                      ),
                                      Column(
                                        children: [
                                          GestureDetector(
                                            onTap: signInWithApple,
                                            child: Container(
                                              height: 45,
                                              width: 45,
                                              decoration: const BoxDecoration(
                                                color: Colors.black,
                                                shape: BoxShape.circle,
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
                                          Platform.isIOS ? const SizedBox(height: 4) : SizedBox(),
                                          Platform.isIOS ?
                                          const Text("Apple",
                                              style: TextStyle(
                                                  fontSize: 13)) : SizedBox()
                                        ],
                                      )

                                    ],
                                  ),

                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: () {
                                      signOutFromGoogle();
                                    },
                                    child: Column(
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
                                              //       text: ", and User agreement",
                                              //       style: CommonFonts
                                              //           .bodyText3MediumBlue),
                                              // ],
                                              children: []),
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
    final CurrencyController currencyController = Get.put(CurrencyController());

    bool isGoogleLoading = false;

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

        // Always returned
        print('User ID: $userId');

        if (email != null) {
          // First-time login — store data
          await StorageServices.instance.save('appleUserId', userId??'');
          await StorageServices.instance.save('appleEmail', email??'');
          await StorageServices.instance.save('appleName', fullName??'');
          Navigator.of(context).push(
            Platform.isIOS
                ? CupertinoPageRoute(
              builder: (_) => UserFillDetails(
                name: fullName??'',
                email: email ?? '',
                phone: '',
              ),
            )
                : MaterialPageRoute(
              builder: (_) => UserFillDetails(
                name: fullName??'',
                email: email ?? '',
                phone: '',
              ),
            ),
          );


        } else {
          // Returning user — load data from local storage
          String userId = await StorageServices.instance.read('appleUserId')??'';
          String userEmail = await StorageServices.instance.read('appleEmail')??'';
          String userName =  await StorageServices.instance.read('appleName') ?? '';

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

        // (Optional) Use userId + email for backend auth here

      } catch (e) {
        print('❌ Apple Sign-In Error: $e');
      }
    }


    Future<UserCredential?> signInWithGoogle() async {
      try {
        final GoogleSignIn _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId:
          '880138699529-in25a6554o0jcp0610fucg4s94k56agt.apps.googleusercontent.com', // Web Client ID
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
        Platform.isIOS
            ? CupertinoPageRoute(
          builder: (_) => UserFillDetails(
            name: result?.user?.displayName ?? '',
            email: result?.user?.email ?? '',
            phone: result?.user?.phoneNumber ?? '',
          ),
        )
            : MaterialPageRoute(
          builder: (_) => UserFillDetails(
            name: result?.user?.displayName ?? '',
            email: result?.user?.email ?? '',
            phone: result?.user?.phoneNumber ?? '',
          ),
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
              final ProfileController  profileController = ProfileController();
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
                            //               CrossAxisAlignment.start,
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
                                                  Platform.isIOS
                                                      ? CupertinoPageRoute(
                                                    builder: (_) =>
                                                    const UserFillDetails(
                                                      name: '',
                                                      email: '',
                                                      phone: '',
                                                    ),
                                                  )
                                                      : MaterialPageRoute(
                                                    builder: (_) =>
                                                    const UserFillDetails(
                                                      name: '',
                                                      email: '',
                                                      phone: '',
                                                    ),
                                                  ),
                                                ); // open register sheet
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
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
                                                      const EdgeInsets.all(
                                                          1),
                                                      decoration:
                                                      const BoxDecoration(
                                                          color:
                                                          Colors.grey,
                                                          shape: BoxShape
                                                              .circle),
                                                      child: CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor:
                                                        Colors.white,
                                                        child: isGoogleLoading
                                                            ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child: CircularProgressIndicator(
                                                              strokeWidth:
                                                              2),
                                                        )
                                                            : Image.asset(
                                                          'assets/images/google_icon.png',
                                                          fit: BoxFit
                                                              .contain,
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
                                            SizedBox(
                                              width: 24,
                                            ),
                                            Platform.isIOS ? Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: signInWithApple,
                                                  child: Container(
                                                    height: 45,
                                                    width: 45,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.black,
                                                      shape: BoxShape.circle,
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
                                                Platform.isIOS ? const SizedBox(height: 4) : SizedBox(),
                                                Platform.isIOS ?
                                                const Text("Apple",
                                                    style: TextStyle(
                                                        fontSize: 13)) : SizedBox()
                                              ],
                                            ) : SizedBox()

                                          ],
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
                                                //           ", and User agreement",
                                                //       style: CommonFonts
                                                //           .bodyText3MediumBlue),
                                                // ],
                                                children: []),
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
    ManageBookings(),
    Contact(),
    MyAccount()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
  Future<void> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Example: print user data
      print('User ID: ${credential.userIdentifier}');
      print('Email: ${credential.email}');
      print('Name: ${credential.givenName} ${credential.familyName}');

      // TODO: Send credential.identityToken to backend for verification or save locally
    } catch (e) {
      print('Apple Sign-In Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    homeApiLoading();
    return WillPopScope(
      onWillPop: () async {
        // Reapply status bar color when navigating back
        _setStatusBarColor();
        // If BottomNav was pushed on top of another route (e.g. BookingRide),
        // popping would reveal the previous screen again. Block that.
        // If BottomNav is the root (canPop == false), allow the system to pop/exit.
        final canPop = Navigator.of(context).canPop();
        return !canPop;
      },
      child: Scaffold(
        // Keep all tab screens mounted to preserve state (avoid re-fetch/reload)
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
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
                _buildBarItem(Icons.person_outline_outlined, 'Profile', 3),
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
  OtpTextField({
    super.key,
    required this.otpController,
    required this.mobileNo,
  });
  @override
  State<OtpTextField> createState() => _OtpTextFieldState();
}

class _OtpTextFieldState extends State<OtpTextField> {
  int secondsRemaining = 60; // Initial timer set to 5 minutes
  bool enableResend = false;
  bool isLengthOkay = false;
  Timer? _timer;
  final ResendOtpController resendOtpController =
      Get.put(ResendOtpController());
  final OtpController otpController = Get.put(OtpController());

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown({bool isResend = false}) {
    setState(() {
      enableResend = false;
      secondsRemaining =
          isResend ? 60 : 60; // 1 minute for resend, 5 minutes for initial
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
      _startCountdown(isResend: true); // Restart timer with 1 minute
    });
  }

  void _validateOtp(String value) {
    // Reset auth state while typing so UI doesn't show old status
    otpController.isAuth.value = null;

    if (value.length == 6) {
      setState(() {
        isLengthOkay = true;
      });
    } else {
      setState(() {
        isLengthOkay = false;
      });
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.homebg, // Status bar color set to white
      statusBarIconBrightness: Brightness.dark, // Dark icons for visibility
    ));
    return Obx(() {
      final otpLength = widget.otpController.text.length;
      final isLengthOkay = otpLength == 6;
      final authStatus = otpController.isAuth.value; // null / true / false

      Color borderColor = Colors.grey;
      String? statusText;
      Color? statusColor;

      if (isLengthOkay && authStatus != null) {
        if (authStatus) {
          borderColor = Colors.green;
          statusText = "OTP Verified Successfully";
          statusColor = Colors.green;
        } else {
          borderColor = Colors.red;
          statusText = "Incorrect OTP! Please try again";
          statusColor = Colors.red;
        }
      } else if (otpLength > 0 && otpLength != 6) {
        statusText = "OTP should be exactly 6 digits";
        statusColor = Colors.red;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
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
                              color: AppColors.blue2,
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            "${(secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(secondsRemaining % 60).toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Show text for OTP length validation or API response
          if (statusText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 12),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      );
    });
  }
}
