import 'dart:convert';
import 'dart:io';

import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wti_cabs_user/common_widget/datepicker/self_drive/from_date_time_picker_tile.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/controller/self_drive/fetch_all_cities_controller/fetch_all_cities_controller.dart';
import 'package:wti_cabs_user/core/controller/self_drive/self_drive_booking_details/self_drive_booking_details_controller.dart';
import 'package:wti_cabs_user/screens/profile/profile.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_final_page_st1/self_drive_final_page_s1.dart';

import '../../../common_widget/buttons/main_button.dart';
import '../../../common_widget/drawer/custom_drawer.dart';
import '../../../common_widget/loader/module_transition/module_transition_loader.dart';
import '../../../common_widget/loader/shimmer/inventory_shimmer.dart';
import '../../../common_widget/name_initials/name_initial.dart';
import '../../../core/controller/auth/mobile_controller.dart';
import '../../../core/controller/auth/otp_controller.dart';
import '../../../core/controller/auth/register_controller.dart';
import '../../../core/controller/auth/resend_otp_controller.dart';
import '../../../core/controller/banner/banner_controller.dart';
import '../../../core/controller/manage_booking/upcoming_booking_controller.dart';
import '../../../core/controller/profile_controller/profile_controller.dart';
import '../../../core/controller/self_drive/date_time_self_drive/date_time_self_drive.dart';
import '../../../core/controller/self_drive/fetch_fleet_sd_homepage/fetch_fleet_sd_homepage_controller.dart';
import '../../../core/controller/self_drive/fetch_top_rated_rides_controller/fetch_top_rated_rides_controller.dart';
import '../../../core/controller/self_drive/search_inventory_sd_controller/search_inventory_sd_controller.dart';
import '../../../core/model/self_drive/get_all_cities/get_all_cities_response.dart';
import '../../../core/route_management/app_routes.dart';
import '../../../core/services/storage_services.dart';
import '../../../main.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../../bottom_nav/bottom_nav.dart';
import '../../map_picker/map_picker.dart';
import '../../user_fill_details/user_fill_details.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;

class SelfDriveHomeScreen extends StatefulWidget {
  const SelfDriveHomeScreen({super.key});

  @override
  State<SelfDriveHomeScreen> createState() => _SelfDriveHomeScreenState();
}

class _SelfDriveHomeScreenState extends State<SelfDriveHomeScreen> {
  late final ProfileController profileController;
  late final BookingRideController bookingRideController;
  late final BannerController bannerController;
  late final FetchAllCitiesController fetchAllCitiesController;
  final CurrencyController currencyController = Get.put(CurrencyController());
  String? city = "Dubai"; // default selected

  @override
  void initState() {
    super.initState();

    // Initialize GetX controllers here
    profileController = Get.put(ProfileController());
    bookingRideController = Get.put(BookingRideController());
    bannerController = Get.put(BannerController());
    fetchAllCitiesController = Get.put(FetchAllCitiesController());
    fetchSelfDriveHomeApi();
  }

  void fetchSelfDriveHomeApi() {
    fetchAllCitiesController.fetchAllCities();
  }
  String address = '';


  Future<void> fetchCurrentLocationAndAddress() async {
    final loc = location.Location();

    // ✅ Ensure service is enabled
    if (!(await loc.serviceEnabled()) && !(await loc.requestService())) return;

    // ✅ Ensure permission
    var permission = await loc.hasPermission();
    if (permission == location.PermissionStatus.denied) {
      permission = await loc.requestPermission();
      if (permission != location.PermissionStatus.granted) return;
    }

    // ✅ Fetch current location
    final locData = await loc.getLocation();
    if (locData.latitude == null || locData.longitude == null) return;

    await _getAddressAndPrefillFromLatLng(
      LatLng(locData.latitude!, locData.longitude!),
    );
  }

  Future<void> _getAddressAndPrefillFromLatLng(LatLng latLng) async {
    try {
      // 1. Reverse geocode to get human-readable address
      final placemarks = await geocoding.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      print('yash current lat/lng is ${latLng.latitude},${latLng.longitude}');

      if (placemarks.isEmpty) {
        setState(() => address = 'Address not found');
        return;
      }

      final place = placemarks.first;
      final components = <String>[
        place.name ?? '',
        place.street ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.administrativeArea ?? '',
        place.postalCode ?? '',
        place.country ?? '',
      ];
      final fullAddress =
      components.where((s) => s.trim().isNotEmpty).join(', ');

      // 2. Show address on UI immediately
      setState(() => address = fullAddress);

      // 3. Try searching the place (may fail or return empty)
      await placeSearchController.searchPlaces(fullAddress, context);

      if (placeSearchController.suggestions.isEmpty) {
        print("No search suggestions found for $fullAddress");
        return; // stop here – do not prefill controllers/storage
      }

      final suggestion = placeSearchController.suggestions.first;

      // 4. Update booking controller ONLY if valid suggestion exists
      bookingRideController.prefilled.value = fullAddress;
      placeSearchController.placeId.value = suggestion.placeId;

      // 5. Fire-and-forget details/storage update
      Future.microtask(() async {
        try {
          await placeSearchController.getLatLngDetails(
              suggestion.placeId, context);

          StorageServices.instance.save('sourcePlaceId', suggestion.placeId);
          StorageServices.instance.save('sourceTitle', suggestion.primaryText);
          StorageServices.instance.save('sourceCity', suggestion.city);
          StorageServices.instance.save('sourceState', suggestion.state);
          StorageServices.instance.save('sourceCountry', suggestion.country);

          if (suggestion.types.isNotEmpty) {
            StorageServices.instance.save(
              'sourceTypes',
              jsonEncode(suggestion.types),
            );
          }

          if (suggestion.terms.isNotEmpty) {
            StorageServices.instance.save(
              'sourceTerms',
              jsonEncode(suggestion.terms),
            );
          }

          sourceController.setPlace(
            placeId: suggestion.placeId,
            title: suggestion.primaryText,
            city: suggestion.city,
            state: suggestion.state,
            country: suggestion.country,
            types: suggestion.types,
            terms: suggestion.terms,
          );

          print('akash country: ${suggestion.country}');
          print('Current location address saved: $fullAddress');
        } catch (err) {
          print('Background save failed: $err');
        }
      });
    } catch (e) {
      print('Error fetching location/address: $e');
      setState(() => address = 'Error fetching address');
    }
  }

  //fake price
  num getFakePriceWithPercent(num baseFare, num percent) =>
      (baseFare * 100) / (100 - percent);

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

                                                          Navigator.of(context).push(
                                                            Platform.isIOS
                                                                ? CupertinoPageRoute(
                                                              builder: (_) =>  Profile(fromSelfDrive: true,),
                                                            )
                                                                : MaterialPageRoute(
                                                              builder: (_) =>  Profile(fromSelfDrive: true,),
                                                            ),
                                                          );

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
                                                const SizedBox(height: 4),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async{
        // This will be called for hardware back and gesture
        await currencyController.resetCurrencyAfterSelfDrive();

        GoRouter.of(context).push(AppRoutes.bottomNav);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE9E9ED),
        body: SafeArea(
          child: SingleChildScrollView( // 🔑 makes whole page scrollable
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const SizedBox(height: 20),

                /// 🔹Top HEADER
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      // const CircleAvatar(
                                      //   radius: 24,
                                      //   backgroundImage: AssetImage('assets/images/user.png'),
                                      // ),
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        onTap: () {
                                          showGeneralDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            barrierLabel: "Drawer",
                                            barrierColor:
                                            Colors.black54, // transparent black background
                                            transitionDuration:
                                            const Duration(milliseconds: 300),
                                            pageBuilder: (_, __, ___) =>
                                            const CustomDrawerSheet(),
                                            transitionBuilder: (_, anim, __, child) {
                                              return SlideTransition(
                                                position: Tween<Offset>(
                                                  begin:
                                                  const Offset(-1, 0), // slide in from left
                                                  end: Offset.zero,
                                                ).animate(CurvedAnimation(
                                                  parent: anim,
                                                  curve: Curves.easeOutCubic,
                                                )),
                                                child: child,
                                              );
                                            },
                                          );
                                        },
                                        child: Transform.translate(
                                          offset: Offset(0.0, -4.0),
                                          child: Container(
                                            width: 28, // same as 24dp with padding
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color:
                                              Color.fromRGBO(0, 44, 192, 0.1), // deep blue
                                              borderRadius:
                                              BorderRadius.circular(4), // rounded square
                                            ),
                                            child: const Icon(
                                              Icons.density_medium_outlined,
                                              color: Color.fromRGBO(0, 17, 73, 1),
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Transform.translate(
                                        offset: Offset(0.0, -4.0),
                                        child: SizedBox(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 4,
                                              ),
                                              SvgPicture.asset(
                                                'assets/images/wti_logo.svg',
                                                height: 17,
                                                width: 15,
                                              )
                                              // Text(
                                              //   "Good Morning! Yash",
                                              //   style: CommonFonts.HomeTextBold,
                                              // ),
                                              // Row(
                                              //   children: [
                                              //     Container(
                                              //       width: MediaQuery.of(context)
                                              //               .size
                                              //               .width *
                                              //           0.45,
                                              //       child: Text(
                                              //         address,
                                              //         overflow:
                                              //             TextOverflow.ellipsis,
                                              //         maxLines: 1,
                                              //         style: CommonFonts
                                              //             .greyTextMedium,
                                              //       ),
                                              //     ),
                                              //     // const SizedBox(width:),
                                              //     const Icon(
                                              //       Icons.keyboard_arrow_down,
                                              //       color: AppColors.greyText6,
                                              //       size: 18,
                                              //     ),
                                              //   ],
                                              // ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Obx(() {
                                  return Row(
                                    children: [
                                      // Transform.translate(
                                      //     offset: Offset(0.0, -4.0),
                                      //     child: Image.asset(
                                      //       'assets/images/wallet.png',
                                      //       height: 31,
                                      //       width: 28,
                                      //     )),
                                      SizedBox(
                                        width: 12,
                                      ),
                                      upcomingBookingController.isLoggedIn.value == true
                                          ? InkWell(
                                        splashColor: Colors.transparent,
                                        onTap: () async {
                                          print(
                                              'homepage yash token for profile : ${await StorageServices.instance.read('token') == null}');
                                          if (await StorageServices.instance
                                              .read('token') ==
                                              null) {
                                            _showAuthBottomSheet();
                                          }
                                          if (await StorageServices.instance
                                              .read('token') !=
                                              null) {
                                            GoRouter.of(context).push(AppRoutes.profile);
                                          }
                                        },
                                        child: SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: NameInitialHomeCircle(
                                              name: profileController.profileResponse
                                                  .value?.result?.firstName ??
                                                  ''),
                                        ),
                                      )
                                          : InkWell(
                                        splashColor: Colors.transparent,
                                        onTap: () async {
                                          print(
                                              'homepage yash token for profile : ${await StorageServices.instance.read('token') == null}');
                                          if (await StorageServices.instance
                                              .read('token') ==
                                              null) {
                                            _showAuthBottomSheet();
                                          }
                                          if (await StorageServices.instance
                                              .read('token') !=
                                              null) {
                                            GoRouter.of(context).push(AppRoutes.profile);
                                          }
                                        },
                                        child: Transform.translate(
                                          offset: Offset(0.0, -4.0),
                                          child: const CircleAvatar(
                                            foregroundColor: Colors.transparent,
                                            backgroundColor: Colors.transparent,
                                            radius: 14,
                                            backgroundImage: AssetImage(
                                              'assets/images/user.png',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                })
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 28,
                          ),                      ],
                      ),
                    ),
                    // Container(
                    //     padding: EdgeInsets.symmetric(horizontal: 8),
                    //     height: 170,
                    //     child: BorderedListView()),

                  ],
                ),

                /// 🔹 TABBAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: PillTabBarWithChild(),
                ),

                const SizedBox(height: 20),

                /// 🔹 SERVICES GRID
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Services',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.count(
                    crossAxisCount: 4, // 🔑 exactly 4 items in a row
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        onTap: () {
                          GoRouter.of(context).push(AppRoutes.selfDriveHome);
                          // Flushbar(
                          //   flushbarPosition: FlushbarPosition.TOP, // ✅ Show at top
                          //   margin: const EdgeInsets.all(12),
                          //   borderRadius: BorderRadius.circular(12),
                          //   backgroundColor: AppColors.blueSecondary,
                          //   duration: const Duration(seconds: 3),
                          //   icon: const Icon(Icons.campaign, color: Colors.white),
                          //   messageText: const Text(
                          //     "Coming soon!",
                          //     style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          //   ),
                          // ).show(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F192653),
                                offset: Offset(0, 3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Image.asset(
                                    'assets/images/self_drive.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Text('Self Drive', style: CommonFonts.blueText1),
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        onTap: () async{
                          bookingRideController.selectedIndex.value = 0;
                          fetchCurrentLocationAndAddress();

                          // Navigate immediately
                          if (Platform.isAndroid) {
                            GoRouter.of(context)
                                .push(AppRoutes.bookingRide);
                          } else {
                            navigatorKey.currentContext
                                ?.push(AppRoutes.bookingRide);
                          }
                          currencyController.resetCurrencyAfterSelfDrive();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F192653),
                                offset: Offset(0, 3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Image.asset(
                                    'assets/images/airport.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Text('Airport', style: CommonFonts.blueText1),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        color: Colors.transparent,
                        child: SizedBox.expand(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter, // 👈 ensures "Popular" centers horizontally
                            children: [
                              InkWell(
                                splashColor: Colors.transparent,
                                onTap: () async{
                                  bookingRideController.selectedIndex.value = 1;
                                  fetchCurrentLocationAndAddress();

                                  // Navigate immediately
                                  if (Platform.isAndroid) {
                                    GoRouter.of(context)
                                        .push(AppRoutes.bookingRide);
                                  } else {
                                    navigatorKey.currentContext
                                        ?.push(AppRoutes.bookingRide);
                                  }
                                  currencyController.resetCurrencyAfterSelfDrive();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1F192653),
                                        offset: Offset(0, 3),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Image.asset(
                                            'assets/images/outstation.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        Text('Outstation', style: CommonFonts.blueText1),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFC6CD00), Color(0xFF00DC3E)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Popular',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        onTap: () async{
                          bookingRideController.selectedIndex.value = 2;
                          fetchCurrentLocationAndAddress();

                          // Navigate immediately
                          if (Platform.isAndroid) {
                            GoRouter.of(context)
                                .push(AppRoutes.bookingRide);
                          } else {
                            navigatorKey.currentContext
                                ?.push(AppRoutes.bookingRide);
                          }
                          currencyController.resetCurrencyAfterSelfDrive();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F192653),
                                offset: Offset(0, 3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Image.asset(
                                    'assets/images/rental.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Text('Rental', style: CommonFonts.blueText1),
                              ],
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 124,
                  child: Obx(() {
                    if (bannerController.isLoading.value) {
                      // 🔥 Shimmer loader while images load
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3, // dummy placeholders
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              width: MediaQuery.of(context).size.width -
                                  32, // full width
                              height: 124,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          },
                        ),
                      );
                    }

                    final images = bannerController
                        .homepageImageResponse.value?.result?.topBanner?.images;

                    if (images == null || images.isEmpty) {
                      return const Center(child: Text("No banners available"));
                    }

                    return CarouselSlider.builder(
                      itemCount: images.length,
                      options: CarouselOptions(
                        height: 124,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        autoPlay: true,
                      ),
                      itemBuilder: (context, index, realIdx) {
                        final baseUrl = bannerController
                            .homepageImageResponse.value?.result?.baseUrl ??
                            '';
                        final imageUrl = images[index].url ?? '';

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.network(
                              "$baseUrl$imageUrl",
                              fit: BoxFit.fill,
                              width: double.infinity,
                              height: 124,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    width: double.infinity,
                                    height: 124,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.broken_image));
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 24),
                /// 🔹 FLEET GRID
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: const Text(
                          'Fleet That Meets Your Needs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212F62),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 400,
                          child: CarGridScreen()),

                      CarCard()
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PillTabBarWithChild extends StatefulWidget {
  @override
  _PillTabBarWithChildState createState() => _PillTabBarWithChildState();
}

class _PillTabBarWithChildState extends State<PillTabBarWithChild> {
  final SearchInventorySdController searchInventorySdController = Get.put(SearchInventorySdController());
  final FetchTopRatedRidesController fetchTopRatedRidesController = Get.put(FetchTopRatedRidesController());

  final tabs = ["Daily Rentals", "Monthly Rentals"];
  final children = [
    // Child for "Daily Rentals" - Remove Expanded
    DailyRentalSearchCard(),
    // Child for "Monthly Rentals"
    MonthlyRentalSearchCard(), // Added const for minor perf
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(()=>Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white,
            border: Border.all(color: Colors.grey!, width: 1),
          ),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = searchInventorySdController.selectedIndex.value == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () async{
                    setState(() {
                      searchInventorySdController.selectedIndex.value = index;
                    });
                   await fetchTopRatedRidesController.fetchAllRides();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8262B) : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: children[searchInventorySdController.selectedIndex.value],
        ),
      ],
    ));
  }
}
//Daily Rental Search Card
class DailyRentalSearchCard extends StatefulWidget {
  final bool ? fromSelfDriveInventoryPage;

  const DailyRentalSearchCard({super.key, this.fromSelfDriveInventoryPage});
  @override
  State<DailyRentalSearchCard> createState() => _DailyRentalSearchCardState();
}

class _DailyRentalSearchCardState extends State<DailyRentalSearchCard> {
  final SearchInventorySdController searchInventorySdController = Get.put(SearchInventorySdController());
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now().add(Duration(days: 3));
  TimeOfDay fromTime = TimeOfDay(hour: 10, minute: 0);
  TimeOfDay toTime = TimeOfDay(hour: 10, minute: 0);
  final FetchAllCitiesController fetchAllCitiesController =
      Get.put(FetchAllCitiesController());



  void _openCityBottomSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true, // important for draggable
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // start at 50% height
          minChildSize: 0.5, // can’t shrink below 50%
          maxChildSize: 0.7, // expand up to 90%
          expand: false,
          builder: (context, scrollController) {
            return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(children: [
                  // Header Row
                  Row(
                    children: [
                      const Icon(Icons.arrow_back),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 8.0),
                          child: Text(
                            "Explore Popular Cities",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(),

                  // Cities List
                  Obx(() {
                    final result = fetchAllCitiesController.getAllCitiesResponse.value?.result;
                    final data = result?.data ?? [];

                    // Group cities by countryCode
                    final Map<String, List<LocationData>> groupedByCountry = {};
                    for (var city in data) {
                      final country = city.countryCode ?? "Unknown";
                      groupedByCountry.putIfAbsent(country, () => []).add(city);
                    }

                    String _getCountryFlag(String code) {
                      switch (code.toUpperCase()) {
                        case "UAE":
                          return "🇦🇪";
                        case "IND":
                          return "🇮🇳";
                        case "USA":
                          return "🇺🇸";
                        case "UK":
                          return "🇬🇧";
                        default:
                          return "🇦🇪"; // fallback globe
                      }
                    }

                    return Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 0,), // Subtle vertical spacing
                        children: groupedByCountry.entries.map((entry) {
                          final countryCode = entry.key;
                          final cities = entry.value;

                          // Find the label for the country, fallback to countryCode if not found
                          final countryLabel = result?.availableInCountries
                              ?.firstWhere(
                                (c) => c.value == countryCode,
                            orElse: () => AvailableCountry(
                              label: countryCode, value: countryCode,
                            ),
                          ).label ?? countryCode;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: Colors.black12,
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: true,
                                collapsedBackgroundColor: Colors.grey.shade50,
                                backgroundColor: Colors.grey.shade50,
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.grey.shade100,
                                  child: Text(
                                    _getCountryFlag(countryCode),
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                title: Text(
                                  countryLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Color(0xFF222B45),
                                  ),
                                ),
                                children: cities.map((cityData) {
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.location_city, color: Colors.grey),
                                    title: Text(
                                      cityData.cityName ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        searchInventorySdController.countryCode.value = cityData.countryCode??'';
                                        searchInventorySdController.city.value = cityData.cityName??'';
                                        searchInventorySdController.countryId.value = cityData.id??'';
                                      });


                                      Navigator.pop(context);
                                    },
                                    hoverColor: Colors.blue.shade50,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                    minLeadingWidth: 28,
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );

                  }),
                ]));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = DateTimeController(
      fromDate: DateTime.now().add(Duration(days: 1)).copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      ),
      fromTime: TimeOfDay(hour: 0, minute: 0),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // City Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 1,
                    offset: Offset(0, 0.1)),
              ],
            ),
            child: InkWell(
              onTap: _openCityBottomSheet,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(()=> Text(
                    searchInventorySdController.city.value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  )),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
          SizedBox(height: 14),
          // Dates & Times
          Row(
            children: [
              // From
              // Expanded(
              //   child: Container(
              //     margin: EdgeInsets.only(right: 7),
              //     padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              //     decoration: BoxDecoration(
              //       color: Colors.white,
              //       borderRadius: BorderRadius.circular(10),
              //       boxShadow: [
              //         BoxShadow(
              //             color: Colors.black26,
              //             blurRadius: 1,
              //             offset: Offset(0, 0.1)),
              //       ],
              //     ),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //       children: [
              //         Column(
              //           mainAxisAlignment: MainAxisAlignment.start,
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text("From",
              //                 style: TextStyle(
              //                     fontSize: 10,
              //                     color: Color(0xFF333333),
              //                     fontWeight: FontWeight.w400)),
              //             SizedBox(height: 2),
              //             Text("${fromDate.day} ${_monthAbbr(fromDate.month)}",
              //                 style: TextStyle(
              //                   fontWeight: FontWeight.w500,
              //                   fontSize: 14,
              //                   color: Color(0xFF333333),
              //                 )),
              //           ],
              //         ),
              //         Column(
              //           mainAxisAlignment: MainAxisAlignment.start,
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text("Time",
              //                 style: TextStyle(
              //                     fontSize: 10,
              //                     color: Color(0xFF333333),
              //                     fontWeight: FontWeight.w400)),
              //             Text("${fromTime.format(context)}",
              //                 style: TextStyle(
              //                   fontWeight: FontWeight.w500,
              //                   fontSize: 14,
              //                   color: Color(0xFF333333),
              //                 )),
              //           ],
              //         )
              //       ],
              //     ),
              //   ),
              // ),
              // DateTimeRangePicker(),

            ],
          ),
          DateTimeRangePicker(isMonthlyRental: false,),

          SizedBox(height: 20),
          // Search Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
              backgroundColor: Color(0xFFE8262B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () async{
              await searchInventorySdController.fetchAllInventory(context: context);
            },
            child: Text("Search",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

// Monthly Rental Search Card
class MonthlyRentalSearchCard extends StatefulWidget {
  @override
  State<MonthlyRentalSearchCard> createState() => _MonthlyRentalSearchCardState();
}

class _MonthlyRentalSearchCardState extends State<MonthlyRentalSearchCard> {
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now().add(Duration(days: 3));
  TimeOfDay fromTime = TimeOfDay(hour: 10, minute: 0);
  TimeOfDay toTime = TimeOfDay(hour: 10, minute: 0);
  final FetchAllCitiesController fetchAllCitiesController =
  Get.put(FetchAllCitiesController());

  final SearchInventorySdController searchInventorySdController = Get.put(SearchInventorySdController());


  void _openCityBottomSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true, // important for draggable
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // start at 50% height
          minChildSize: 0.5, // can’t shrink below 50%
          maxChildSize: 0.7, // expand up to 90%
          expand: false,
          builder: (context, scrollController) {
            return Container(
                padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(children: [
                  // Header Row
                  Row(
                    children: [
                      const Icon(Icons.arrow_back),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 8.0),
                          child: Text(
                            "Explore Popular Cities",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(),

                  // Cities List
                  Obx(() {
                    final result = fetchAllCitiesController.getAllCitiesResponse.value?.result;
                    final data = result?.data ?? [];

                    // Group cities by countryCode
                    final Map<String, List<LocationData>> groupedByCountry = {};
                    for (var city in data) {
                      final country = city.countryCode ?? "Unknown";
                      groupedByCountry.putIfAbsent(country, () => []).add(city);
                    }

                    String _getCountryFlag(String code) {
                      switch (code.toUpperCase()) {
                        case "UAE":
                          return "🇦🇪";
                        case "IND":
                          return "🇮🇳";
                        case "USA":
                          return "🇺🇸";
                        case "UK":
                          return "🇬🇧";
                        default:
                          return "🇦🇪"; // fallback globe
                      }
                    }

                    return Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 0,), // Subtle vertical spacing
                        children: groupedByCountry.entries.map((entry) {
                          final countryCode = entry.key;
                          final cities = entry.value;

                          // Find the label for the country, fallback to countryCode if not found
                          final countryLabel = result?.availableInCountries
                              ?.firstWhere(
                                (c) => c.value == countryCode,
                            orElse: () => AvailableCountry(
                              label: countryCode, value: countryCode,
                            ),
                          ).label ?? countryCode;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: Colors.black12,
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: true,
                                collapsedBackgroundColor: Colors.grey.shade50,
                                backgroundColor: Colors.grey.shade50,
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.grey.shade100,
                                  child: Text(
                                    _getCountryFlag(countryCode),
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                title: Text(
                                  countryLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Color(0xFF222B45),
                                  ),
                                ),
                                children: cities.map((cityData) {
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.location_city, color: Colors.grey),
                                    title: Text(
                                      cityData.cityName ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        searchInventorySdController.countryCode.value = cityData.countryCode??'';
                                        searchInventorySdController.city.value = cityData.cityName??'';
                                        searchInventorySdController.countryId.value = cityData.id??'';
                                      });


                                      Navigator.pop(context);
                                    },
                                    hoverColor: Colors.blue.shade50,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                    minLeadingWidth: 28,
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );

                  }),
                ]));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = DateTimeController(
      fromDate: DateTime.now().add(Duration(days: 1)).copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      ),
      fromTime: TimeOfDay(hour: 0, minute: 0),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // City Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 1,
                    offset: Offset(0, 0.1)),
              ],
            ),
            child: InkWell(
              onTap: _openCityBottomSheet,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(()=>Text(
                    searchInventorySdController.city.value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  )),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
          SizedBox(height: 14),
          // Dates & Times
          Row(
            children: [
              // From
              // Expanded(
              //   child: Container(
              //     margin: EdgeInsets.only(right: 7),
              //     padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              //     decoration: BoxDecoration(
              //       color: Colors.white,
              //       borderRadius: BorderRadius.circular(10),
              //       boxShadow: [
              //         BoxShadow(
              //             color: Colors.black26,
              //             blurRadius: 1,
              //             offset: Offset(0, 0.1)),
              //       ],
              //     ),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //       children: [
              //         Column(
              //           mainAxisAlignment: MainAxisAlignment.start,
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text("From",
              //                 style: TextStyle(
              //                     fontSize: 10,
              //                     color: Color(0xFF333333),
              //                     fontWeight: FontWeight.w400)),
              //             SizedBox(height: 2),
              //             Text("${fromDate.day} ${_monthAbbr(fromDate.month)}",
              //                 style: TextStyle(
              //                   fontWeight: FontWeight.w500,
              //                   fontSize: 14,
              //                   color: Color(0xFF333333),
              //                 )),
              //           ],
              //         ),
              //         Column(
              //           mainAxisAlignment: MainAxisAlignment.start,
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text("Time",
              //                 style: TextStyle(
              //                     fontSize: 10,
              //                     color: Color(0xFF333333),
              //                     fontWeight: FontWeight.w400)),
              //             Text("${fromTime.format(context)}",
              //                 style: TextStyle(
              //                   fontWeight: FontWeight.w500,
              //                   fontSize: 14,
              //                   color: Color(0xFF333333),
              //                 )),
              //           ],
              //         )
              //       ],
              //     ),
              //   ),
              // ),
              // DateTimeRangePicker(),

            ],
          ),
          DateTimeRangePicker(isMonthlyRental: true,),

          SizedBox(height: 20),
          // Search Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
              backgroundColor: Color(0xFFE8262B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () async {
              // Show shimmer overlay screen

              // Fetch your data
              await searchInventorySdController.fetchAllInventory(context: context);
            },
            child: Text("Search",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

// fleet ecomony
class CarGridScreen extends StatefulWidget {
  const CarGridScreen({super.key});

  @override
  State<CarGridScreen> createState() => _CarGridScreenState();
}

class _CarGridScreenState extends State<CarGridScreen> {
  final FetchAllFleetsController fetchAllFleetsController = Get.put(FetchAllFleetsController());
  final CurrencyController currencyController = Get.put(CurrencyController());
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchFleets();
  }
  void fetchFleets() async{
    await fetchAllFleetsController.fetchAllFleets();
  }
  @override
  Widget build(BuildContext context) {
    return Obx(()=>      GridView.builder(
      shrinkWrap: true, // ✅ let GridView take only needed height
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fetchAllFleetsController.getAllFleetResponse.value?.result?.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columns
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      fetchAllFleetsController.getAllFleetResponse.value?.result?[index].imageUrl??'',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
                      },
                    )
                ),
              ),

              Text(
                fetchAllFleetsController.getAllFleetResponse.value?.result?[index].className??'',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF333333)),
              ),
              SizedBox(height: 24,)
            ],
          ),
        );
      },
    )
    );
  }
}




class CarCard extends StatefulWidget {
  const CarCard({super.key});

  @override
  State<CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<CarCard> {
  final FetchTopRatedRidesController fetchTopRatedRidesController = Get.put(FetchTopRatedRidesController());
  final SearchInventorySdController searchInventorySdController = Get.put(SearchInventorySdController());
  final FetchSdBookingDetailsController fetchSdBookingDetailsController = Get.put(FetchSdBookingDetailsController());
  final CurrencyController currencyController = Get.put(CurrencyController());
  int _currentIndex = 0;

  //fake price
  num getFakePriceWithPercent(num baseFare, num percent) =>
      (baseFare * 100) / (100 - percent);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchTopRatedRides();
  }

  void fetchTopRatedRides() async{
    await fetchTopRatedRidesController.fetchAllRides();
  }
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rides = fetchTopRatedRidesController.getAllTopRidesResponse.value?.result ?? [];

      if (rides.isEmpty) {
        return const Center(child: Text("No rides available"));
      }

      return ListView.builder(
        itemCount: rides.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // ✅ safe in nested scroll
        itemBuilder: (context, index) {
          final vehicle = rides[index].vehicleId;
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0.3,
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Carousel

                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      CarouselSlider(
                        items: rides[index].vehicleId?.images?.map((img) {
                          return Image.network(
                            img,
                            fit: BoxFit.fill,
                            width: double.infinity,
                          );
                        }).toList(),
                        options: CarouselOptions(
                          height: 280,
                          viewportFraction: 1.0,
                          enableInfiniteScroll: true,
                          autoPlay: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: 20,
                          child: Transform.translate(
                            offset: const Offset(0.0, 0.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: rides[index].vehicleId!.images!.asMap().entries.map((entry) {
                                final isActive = _currentIndex == entry.key;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.white : Colors.grey,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2), // soft shadow
                                        blurRadius: 4, // spread of shadow
                                        offset: const Offset(0, 2), // vertical shadow
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                     rides[index].vehicleId?.vehiclePromotionTag != null ? Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25), // shadow color
                                blurRadius: 6, // softening
                                offset: Offset(2, 4), // X,Y offset
                              ),
                            ],
                          ),
                          child: Image.asset(
                            rides[index].vehicleId?.vehiclePromotionTag?.toLowerCase()=='popular'?'assets/images/popular.png' : 'assets/images/trending.png',
                            width: 106,
                            height: 28,
                          ),
                        ),
                      ) : SizedBox(),
                    ],
                  ),
                ),

                // Car Info
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0,bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle?.modelName ?? "",
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFF000000))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text("${vehicle?.vehicleRating ?? "-"}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF373737))),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Color(0xFFFEC200), size: 16),
                          const SizedBox(width: 4,),
                          Text("450 Reviews", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF373737))),

                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: [
                          _InfoIcon(icon: Icons.airline_seat_recline_extra, text: "${vehicle?.specs?.seats ?? "--"} Seat"),
                          _InfoIcon(icon: Icons.work, text: "${vehicle?.specs?.luggageCapacity ?? "--"} luggage bag"),
                          // _InfoIcon(icon: Icons.speed, text: "${vehicle?.specs?.mileageLimit ?? "--"} km/rental"),
                          _InfoIcon(icon: Icons.settings, text: "${vehicle?.specs?.transmission ?? "--"}"),
                          const _InfoIcon(icon: Icons.calendar_today, text: "Min. 2 days rental"),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const Divider(color: Color(0xFFDCDCDC),),
                ),

                // Price + Button
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:  [

                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<double>(
                                future: currencyController.convertPrice(
                                  getFakePriceWithPercent(searchInventorySdController.selectedIndex.value == 0
                                      ? (rides[index].tariffDaily?.base ?? 0)
                                      : (rides[index].tariffMonthly?.base ?? 0), 20).toDouble(),
                                ),
                                builder: (context, snapshot) {
                                  final convertedValue = snapshot.data ??
                                      getFakePriceWithPercent(searchInventorySdController.selectedIndex.value == 0
                                          ? (rides[index].tariffDaily?.base ?? 0)
                                          : (rides[index].tariffMonthly?.base ?? 0), 20).toDouble();
                                  return Text(
                                    '${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.grey, // lighter color for cut-off price
                                      decoration: TextDecoration.lineThrough, // 👈 adds cutoff
                                    ),
                                  );
                                },
                              ),
          ]
                          ),

                          SizedBox(height: 4),
                          FutureBuilder<double>(
                            future: currencyController.convertPrice(
                              (searchInventorySdController.selectedIndex.value == 0
                                  ? (rides[index].tariffDaily?.base ?? 0)
                                  : (rides[index].tariffMonthly?.base?? 0))
                                  .toDouble(),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Text(
                                  "Error in conversion",
                                  style: TextStyle(color: Colors.red, fontSize: 11),
                                );
                              }

                              // Show loading or fallback until data is ready
                              final convertedPrice = snapshot.data ?? 0;

                              return Text(
                                searchInventorySdController.selectedIndex.value == 0
                                    ? "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}/day"
                                    : "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}/Month",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF131313),
                                ),
                              );
                            },
                          )

                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE8262B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                        ),
                        onPressed: () async{
          // Step 2: Show the transition loader (Chauffeur → Self Drive)
          Navigator.of(context).push(
          PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => const SelfDriveInventoryShimmer(
          ),
          ),
          );


          // Step 3: Wait for animation to complete
          await Future.delayed(const Duration(seconds: 2));

          // Step 4: Close the loader and navigate via GoRouter
          if (context.mounted) {
            // Close loader overlay
            Navigator.of(context).pop();
          }
                         await fetchSdBookingDetailsController.fetchBookingDetails(vehicle?.id??"", false).then((value){
                            Navigator.of(context).push(
                              Platform.isIOS
                                  ? CupertinoPageRoute(
                                builder: (_) =>  SelfDriveFinalPageS1(vehicleId: vehicle?.id??"", isHomePage: false, isNavigateFromHome: true,),
                              )
                                  : MaterialPageRoute(
                                builder: (_) =>  SelfDriveFinalPageS1(vehicleId: vehicle?.id??"", isHomePage: false, isNavigateFromHome: true,),
                              ),
                            );
                          });
                                               },
                        child: const Text("Book Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

}

class _InfoIcon extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoIcon({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Color(0xFF979797)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
      ],
    );
  }
}


