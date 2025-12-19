import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

import 'package:another_flushbar/flushbar.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wti_cabs_user/common_widget/progress_page/progress_page.dart';
import 'package:wti_cabs_user/common_widget/textformfield/read_only_textformfield.dart';
import 'package:wti_cabs_user/core/controller/banner/banner_controller.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/core/controller/choose_pickup/choose_pickup_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import 'package:wti_cabs_user/core/controller/manage_booking/upcoming_booking_controller.dart';
import 'package:wti_cabs_user/core/controller/popular_destination/popular_destination.dart';
import 'package:wti_cabs_user/core/controller/source_controller/source_controller.dart';
import 'package:wti_cabs_user/core/controller/usp_controller/usp_controller.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:wti_cabs_user/core/model/home_page_images/home_page_image_response.dart';
import 'package:wti_cabs_user/screens/booking_ride/booking_ride.dart';
import 'package:wti_cabs_user/screens/corporate/corporate_bottom_nav/corporate_bottom_nav.dart';
import 'package:wti_cabs_user/screens/corporate/corporate_landing_page/corporate_landing_page.dart';
import 'package:wti_cabs_user/screens/user_fill_details/user_fill_details.dart';

import '../../common_widget/buttons/main_button.dart';
import '../../common_widget/drawer/custom_drawer.dart';
import '../../common_widget/loader/full_screen_gif/full_screen_gif.dart';
import '../../common_widget/loader/module_transition/module_transition_loader.dart';
import '../../common_widget/loader/popup_loader.dart';
import '../../common_widget/name_initials/name_initial.dart';
import '../../core/controller/auth/mobile_controller.dart';
import '../../core/controller/auth/otp_controller.dart';
import '../../core/controller/auth/register_controller.dart';
import '../../core/controller/auth/resend_otp_controller.dart';
import '../../core/controller/choose_drop/choose_drop_controller.dart';
import '../../core/controller/currency_controller/currency_controller.dart';
import '../../core/controller/download_receipt/download_receipt_controller.dart';
import '../../core/controller/drop_location_controller/drop_location_controller.dart';
import '../../core/controller/profile_controller/profile_controller.dart';
import '../../core/controller/self_drive/date_time_self_drive/date_time_self_drive.dart';
import '../../core/controller/self_drive/fetch_all_cities_controller/fetch_all_cities_controller.dart';
import '../../core/controller/self_drive/fetch_fleet_sd_homepage/fetch_fleet_sd_homepage_controller.dart';
import '../../core/controller/self_drive/fetch_most_popular_location/fetch_most_popular_location_controller.dart';
import '../../core/controller/self_drive/fetch_top_rated_rides_controller/fetch_top_rated_rides_controller.dart';
import '../../core/controller/self_drive/file_upload_controller/file_upload_controller.dart';
import '../../core/controller/self_drive/google_lat_lng_controller/google_lat_lng_controller.dart';
import '../../core/controller/self_drive/sd_google_suggestions/sd_google_suggestions_controller.dart';
import '../../core/controller/self_drive/search_inventory_sd_controller/search_inventory_sd_controller.dart';
import '../../core/controller/self_drive/self_drive_booking_details/self_drive_booking_details_controller.dart';
import '../../core/controller/self_drive/self_drive_manage_booking/self_drive_manage_booking_controller.dart';
import '../../core/controller/self_drive/self_drive_payment_status/self_drive_payment_booking_controller.dart';
import '../../core/controller/self_drive/self_drive_stripe_payment/sd_create_stripe_payment.dart';
import '../../core/controller/self_drive/self_drive_upload_file_controller/self_drive_upload_file_controller.dart';
import '../../core/controller/self_drive/service_hub/service_hub_controller.dart';
import '../../core/model/booking_engine/suggestions_places_response.dart';
import '../../core/route_management/app_routes.dart';
import '../../core/services/storage_services.dart';
import '../../core/services/trip_history_services.dart';
import '../../firebase_options.dart';
import '../../main.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../bottom_nav/bottom_nav.dart';
import '../corporate/cpr_redirect_screen/cpr_redirect_screen.dart';
import '../inventory_list_screen/inventory_list.dart';
import '../select_location/select_drop.dart';
import '../trip_history_controller/trip_history_controller.dart';
import '../../core/api/corporate/cpr_api_services.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'dart:convert'; // for jsonEncode
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng
import 'dart:math' as math; // 👈 ADD THIS LINE

// keep this as is

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String address = '';
  List<Map<String, dynamic>> recentTrips = [];
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  final PopularDestinationController popularDestinationController =
      Get.put(PopularDestinationController());
  final UspController uspController = Get.put(UspController());
  final BannerController bannerController = Get.put(BannerController());

  final TripHistoryController tripController = Get.put(TripHistoryController());
  // ✅ Use single instance to avoid conflicts
  final PlaceSearchController placeSearchController =
      Get.put(PlaceSearchController(), permanent: true);
  final SourceLocationController sourceController =
      Get.put(SourceLocationController());
  final DestinationLocationController destinationLocationController =
      Get.put(DestinationLocationController());
  final ProfileController profileController = Get.put(ProfileController());
  final UpcomingBookingController upcomingBookingController =
      Get.put(UpcomingBookingController());
  final CurrencyController currencyController = Get.put(CurrencyController());
  final LoginInfoController crploginInfoController = Get.put(LoginInfoController());
  void showUpcomingServiceModal(BuildContext context, String tabName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                '$tabName Service Coming Soon!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We are working hard to launch this service for you. Stay tuned!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Got it"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void resetAllControllers() {
    // Delete existing controller instances (if already registered)
    Get.delete<ServiceHubController>(force: true);
    Get.delete<FileUploadController>(force: true);
    Get.delete<SdCreateStripePaymentController>(force: true);
    Get.delete<SelfDrivePaymentBookingController>(force: true);
    Get.delete<SelfDriveManageBookingController>(force: true);
    Get.delete<PdfDownloadController>(force: true);
    Get.delete<FetchSdBookingDetailsController>(force: true);
    // Get.delete<SearchInventorySdController>(force: true);
    Get.delete<SdGoogleSuggestionsController>(force: true);
    Get.delete<GoogleLatLngController>(force: true);
    Get.delete<FileUploadValidController>(force: true);
    Get.delete<FetchTopRatedRidesController>(force: true);
    Get.delete<FetchMostPopularLocationController>(force: true);
    Get.delete<FetchAllFleetsController>(force: true);
    Get.delete<FetchAllCitiesController>(force: true);
    Get.delete<DateTimeController>(force: true);

    // Recreate fresh instances (reinitialize all)
    Get.put(FileUploadController());
    Get.put(SdCreateStripePaymentController());
    Get.put(SelfDrivePaymentBookingController());
    Get.put(SelfDriveManageBookingController());
    Get.put(PdfDownloadController());
    Get.put(FetchSdBookingDetailsController());
    Get.put(SearchInventorySdController());
    Get.put(SdGoogleSuggestionsController());
    Get.put(GoogleLatLngController());
    Get.put(FileUploadValidController());
    Get.put(FetchTopRatedRidesController());
    Get.put(FetchMostPopularLocationController());
    Get.put(FetchAllFleetsController());
    Get.put(FetchAllCitiesController());

  }

  String? crpKey;

  void loaderCrpToken() async{
    crpKey = await StorageServices.instance.read('crpKey');

    // If a corporate session already exists, silently refresh it by
    // calling the corporate login API with the stored email/password.
    if (crpKey != null && crpKey!.isNotEmpty) {
      try {
        await CprApiService().reLoginWithStoredCredentials();
      } catch (e) {
        debugPrint('❌ Corporate re-login from HomeScreen failed: $e');
      }
    }
  }

  Future<void> _handleCorporateEntry(BuildContext context) async {
    if (!mounted) return;

    setState(() => _isCorporateLoading = true);
    try {
      await Navigator.of(context).push(
        PlatformFlipPageRoute(
          builder: (_) => const CprRedirectScreen(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCorporateLoading = false);
      }
    }
  }

  // corporte page transitiion loader
  bool _isCorporateLoading = false;


  @override
  void initState() {
    super.initState();

    // Register as WidgetsBindingObserver to listen for lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // Fetch location and show bottom sheet
    profileController.checkLoginStatus();

    popularDestinationController.fetchPopularDestinations();
    // ✅ Fetch USP data on first load
    uspController.fetchUsps().catchError((e) {
      debugPrint("❌ Error fetching USP: $e");
      // Retry after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) uspController.fetchUsps(forceRefresh: true);
      });
    });
    // ✅ Force fetch images on first load
    bannerController.fetchImages().catchError((e) {
      debugPrint("❌ Error fetching banners: $e");
      // Retry after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) bannerController.fetchImages(forceRefresh: true);
      });
    });

    // ✅ Fetch location in background, don't block UI
    fetchCurrentLocationAndAddress().catchError((e) {
      debugPrint("❌ Error fetching location: $e");
    });

    _setStatusBarColor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileController.fetchData();
      // _showBottomSheet();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logScreenView();
      // _showBottomSheet();
    });
    loaderCrpToken();

  }

  Future<void> logScreenView() async{
    final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
    await _analytics.logScreenView(
      screenName: 'HomeScreen',
      screenClass: 'Rides',
      parameters: {
        'event':'screen_view',
      },// or 'OutStation', depending on widget
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
        statusBarColor: AppColors.homebg,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  bool isDrawerOpen = false;

  void toggleDrawer() {
    setState(() {
      isDrawerOpen = !isDrawerOpen;
    });
  }

  @override
  void dispose() {
    // Remove observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: const BoxConstraints(minHeight: 300),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Text(
                'Hello from Bottom Sheet!',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  final List<String> imageList = [
    'assets/images/main_banner.png',
    'assets/images/main_banner.png',
    'assets/images/main_banner.png',
  ];
  final Duration _duration = Duration(milliseconds: 300);

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
        // // ✅ Prefill controllers
        // nameController.text = result.user?.displayName ?? '';
        // emailController.text = result.user?.email ?? '';
        // mobileController.text = result.user?.phoneNumber ?? '';
        //
        // gender = "MALE"; // default or based on preference
        //
        // print("✅ User signed in: ${result.user?.email}");
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
                                            : () => _handleGoogleLogin(
                                                setModelState),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                padding:
                                                    const EdgeInsets.all(1),
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
                                                  style:
                                                      TextStyle(fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 24,
                                      ),
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
                                                Platform.isIOS
                                                    ? const SizedBox(height: 4)
                                                    : SizedBox(),
                                                Platform.isIOS
                                                    ? const Text("Apple",
                                                        style: TextStyle(
                                                            fontSize: 13))
                                                    : SizedBox()
                                              ],
                                            )
                                          : SizedBox()
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
                                              children: []
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
        // Returning user — load data from local storage
        String userId =
            await StorageServices.instance.read('appleUserId') ?? '';
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
    final CurrencyController currencyController = Get.put(CurrencyController());

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
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Platform.isIOS
                                                          ? const SizedBox(
                                                              height: 4)
                                                          : SizedBox(),
                                                      Platform.isIOS
                                                          ? const Text("Apple",
                                                              style: TextStyle(
                                                                  fontSize: 13))
                                                          : SizedBox()
                                                    ],
                                                  )
                                                : SizedBox()
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

  final LoginInfoController loginInfoController = Get.put(LoginInfoController());

  @override
  Widget build(BuildContext context) {
    final double drawerWidth = MediaQuery.of(context).size.width * 0.8;
    return WillPopScope(
      onWillPop: () async {
        // Reapply status bar color when navigating back
        _setStatusBarColor();
        return false;
      },
      child: (_isCorporateLoading)
          ? Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Stack(
                  children: [
                    // Center loader + text
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Switching to corporate...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom helper text
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 32,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Please wait while we take you to your corporate dashboard.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Scaffold(
        backgroundColor: Color(0xFFE9E9ED),
        // backgroundColor: AppColors.homebg,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [

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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      // const CircleAvatar(
                                      //   radius: 24,
                                      //   backgroundImage: AssetImage('assets/images/user.png'),
                                      // ),
                                      // InkWell(
                                      //   splashColor: Colors.transparent,
                                      //   onTap: () {
                                      //     showGeneralDialog(
                                      //       context: context,
                                      //       barrierDismissible: true,
                                      //       barrierLabel: "Drawer",
                                      //       barrierColor: Colors
                                      //           .black54, // transparent black background
                                      //       transitionDuration: const Duration(
                                      //           milliseconds: 300),
                                      //       pageBuilder: (_, __, ___) =>
                                      //           const CustomDrawerSheet(),
                                      //       transitionBuilder:
                                      //           (_, anim, __, child) {
                                      //         return SlideTransition(
                                      //           position: Tween<Offset>(
                                      //             begin: const Offset(-1,
                                      //                 0), // slide in from left
                                      //             end: Offset.zero,
                                      //           ).animate(CurvedAnimation(
                                      //             parent: anim,
                                      //             curve: Curves.easeOutCubic,
                                      //           )),
                                      //           child: child,
                                      //         );
                                      //       },
                                      //     );
                                      //   },
                                      //   child: Transform.translate(
                                      //     offset: Offset(0.0, -4.0),
                                      //     child: Container(
                                      //       width:
                                      //           28, // same as 24dp with padding
                                      //       height: 28,
                                      //       decoration: BoxDecoration(
                                      //         color: Color.fromRGBO(
                                      //             0, 44, 192, 0.1), // deep blue
                                      //         borderRadius:
                                      //             BorderRadius.circular(
                                      //                 4), // rounded square
                                      //       ),
                                      //       child: const Icon(
                                      //         Icons.density_medium_outlined,
                                      //         color:
                                      //             Color.fromRGBO(0, 17, 73, 1),
                                      //         size: 16,
                                      //       ),
                                      //     ),
                                      //   ),
                                      // ),
                                      // const SizedBox(width: 12),
                                      Transform.translate(
                                        offset: Offset(0.0, -4.0),
                                        child: SizedBox(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                // Row(
                                //   children: [
                                //     // Transform.translate(
                                //     //     offset: Offset(0.0, -4.0),
                                //     //     child: Image.asset(
                                //     //       'assets/images/wallet.png',
                                //     //       height: 31,
                                //     //       width: 28,
                                //     //     )),
                                //     SizedBox(
                                //       width: 12,
                                //     ),
                                //     // Go Corporate
                                    Container(
                                      height: 35,
                                      decoration: BoxDecoration(
                                        /*gradient: const LinearGradient(
                                          colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),*/
                                        color: AppColors.mainButtonBg,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent, // transparent to show gradient
                                          shadowColor: Colors.transparent, // remove default shadow
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                        ),
                                        onPressed: _isCorporateLoading ? null : () async {
                                          await _handleCorporateEntry(context);
                                        },
                                        child: const Text(
                                          "Go Corporate",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                //     // upcomingBookingController
                                //     //             .isLoggedIn.value ==
                                //     //         true
                                //     //     ? InkWell(
                                //     //         splashColor: Colors.transparent,
                                //     //         onTap: () async {
                                //     //           print(
                                //     //               'homepage yash token for profile : ${await StorageServices.instance.read('token') == null}');
                                //     //           if (await StorageServices
                                //     //                   .instance
                                //     //                   .read('token') ==
                                //     //               null) {
                                //     //             _showAuthBottomSheet();
                                //     //           }
                                //     //           if (await StorageServices
                                //     //                   .instance
                                //     //                   .read('token') !=
                                //     //               null) {
                                //     //             GoRouter.of(context)
                                //     //                 .push(AppRoutes.profile);
                                //     //           }
                                //     //         },
                                //     //         child: SizedBox(
                                //     //           width: 30,
                                //     //           height: 30,
                                //     //           child: NameInitialHomeCircle(
                                //     //               name: profileController
                                //     //                       .profileResponse
                                //     //                       .value
                                //     //                       ?.result
                                //     //                       ?.firstName ??
                                //     //                   ''),
                                //     //         ),
                                //     //       )
                                //     //     : InkWell(
                                //     //         splashColor: Colors.transparent,
                                //     //         onTap: () async {
                                //     //           print(
                                //     //               'homepage yash token for profile : ${await StorageServices.instance.read('token') == null}');
                                //     //           if (await StorageServices
                                //     //                   .instance
                                //     //                   .read('token') ==
                                //     //               null) {
                                //     //             _showAuthBottomSheet();
                                //     //           }
                                //     //           if (await StorageServices
                                //     //                   .instance
                                //     //                   .read('token') !=
                                //     //               null) {
                                //     //             GoRouter.of(context)
                                //     //                 .push(AppRoutes.profile);
                                //     //           }
                                //     //         },
                                //     //         child: Transform.translate(
                                //     //           offset: Offset(0.0, -4.0),
                                //     //           child: const CircleAvatar(
                                //     //             foregroundColor:
                                //     //                 Colors.transparent,
                                //     //             backgroundColor:
                                //     //                 Colors.transparent,
                                //     //             radius: 14,
                                //     //             backgroundImage: AssetImage(
                                //     //               'assets/images/user.png',
                                //     //             ),
                                //     //           ),
                                //     //         ),
                                //     //       ),
                                //   ],
                                // )
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () async {
                              bookingRideController.fromHomePage.value = true;
                              Navigator.pushAndRemoveUntil(
                                context,
                                Platform.isIOS
                                    ? CupertinoPageRoute(
                                  builder: (context) => const SelectDrop(fromInventoryScreen: false),
                                )
                                    : MaterialPageRoute(
                                  builder: (context) => const SelectDrop(fromInventoryScreen: false),
                                ),
                                    (route) => false, // removes ALL previous routes
                              );
                              await fetchCurrentLocationAndAddress();
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: ReadOnlyTextFormField(
                                controller:
                                    TextEditingController(text: 'Where to?'),
                                icon: Icons.search,
                                prefixText: '',
                                onTap: () {
                                  bookingRideController.prefilledDrop.value =
                                      '';

                                  GoRouter.of(context).go(AppRoutes.chooseDrop);
                                },
                                // onTap: () {
                                //   if (placeSearchController
                                //       .suggestions.isEmpty) {
                                //     showDialog(
                                //       context: context,
                                //       barrierDismissible: false,
                                //       builder: (_) => const PopupLoader(
                                //         message: "Go to Search Booking",
                                //       ),
                                //     );
                                //     fetchCurrentLocationAndAddress();
                                //     GoRouter.of(context)
                                //         .push(AppRoutes.choosePickup);
                                //     GoRouter.of(context).pop();
                                //   } else if (placeSearchController
                                //       .suggestions.isNotEmpty) {
                                //     showDialog(
                                //       context: context,
                                //       barrierDismissible: false,
                                //       builder: (_) => const PopupLoader(
                                //         message: "Go to Search Booking",
                                //       ),
                                //     );
                                //     fetchCurrentLocationAndAddress();
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(
                                //         builder: (context) => const SelectDrop(fromInventoryScreen: false),
                                //       ),
                                //     );
                                //     GoRouter.of(context).pop();
                                //   } else {
                                //     showDialog(
                                //       context: context,
                                //       barrierDismissible: false,
                                //       builder: (_) => const PopupLoader(
                                //         message: "Go to Search Booking",
                                //       ),
                                //     );
                                //     fetchCurrentLocationAndAddress();
                                //     GoRouter.of(context)
                                //         .push(AppRoutes.bookingRide);
                                //     GoRouter.of(context).pop();
                                //   }
                                // },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Obx(() {
                            return Text(
                              tripController.topRecentTrips.isEmpty
                                  ? 'Popular Destinations'
                                  : 'Recent Destination',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black),
                            );
                          }),
                          // SizedBox(
                          //   height: 16,
                          // ),
                        ],
                      ),
                    ),
                    // Container(
                    //     padding: EdgeInsets.symmetric(horizontal: 8),
                    //     height: 170,
                    //     child: BorderedListView()),

                    RecentTripList(),
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
                              bookingRideController.selectedIndex.value = 0;

                              // Start fetching location asynchronously without waiting
                              fetchCurrentLocationAndAddress();

                              // Navigate immediately
                              if (Platform.isAndroid) {
                                GoRouter.of(context)
                                    .push(AppRoutes.bookingRide);
                              } else {
                                navigatorKey.currentContext
                                    ?.push(AppRoutes.bookingRide);
                              }
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
                                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 6.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/airport.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Text('Airport',
                                        style: CommonFonts.blueText1),
                                    SizedBox(height: 8,),
                                  bookingRideController.selectedIndex.value == 0 ?  Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                      child: Container(
                                        height: 3,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF888888), // background line
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ) : SizedBox()

                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            onTap: () {
                              bookingRideController
                                  .selectedIndex.value = 1;
                              fetchCurrentLocationAndAddress();
                              // Navigate immediately
                              if (Platform.isAndroid) {
                                GoRouter.of(context)
                                    .push(AppRoutes.bookingRide);
                              } else {
                                navigatorKey.currentContext
                                    ?.push(AppRoutes.bookingRide);
                              }
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
                                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 6.0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.topCenter,
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(0.0, -15.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFC6CD00),
                                              Color(0xFF00DC3E)
                                            ],
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

                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [

                                        Expanded(
                                          child: Image.asset(
                                            'assets/images/outstation.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        Text('Outstation',
                                            style: CommonFonts.blueText1),
                                        SizedBox(height: 8,),
                                        (bookingRideController.selectedIndex.value == 1)?  Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                          child: Container(
                                            height: 3,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF888888), // background line
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                        ) : SizedBox()
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            onTap: () {
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
                                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 6.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/rental.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Text('Rental',
                                        style: CommonFonts.blueText1),
                                    SizedBox(height: 8,),
                                    (bookingRideController.selectedIndex.value == 2)?  Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                      child: Container(
                                        height: 3,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF888888), // background line
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ) : SizedBox()
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            onTap: () async {
                              bookingRideController.selectedIndex.value = 3;
                              // Step 1: Update currency logic first
                              currencyController.setSelfDriveCurrency();

                              // Step 2: Show the transition loader (Chauffeur → Self Drive)
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) =>
                                      const ModuleTransitionLoader(),
                                ),
                              );

                              // Step 3: Wait for animation to complete
                              await Future.delayed(const Duration(seconds: 2));

                              // Step 4: Close the loader and navigate via GoRouter
                              if (context.mounted) {
                                // Close loader overlay
                                Navigator.of(context).pop();

                                // Use GoRouter for navigation
                                GoRouter.of(context)
                                    .push(AppRoutes.selfDriveBottomSheet);
                                resetAllControllers();
                              }
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
                                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 6.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/self_drive.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Text('Self Drive',
                                        style: CommonFonts.blueText1),
                                    SizedBox(height: 8,),
                                    (bookingRideController.selectedIndex.value == 3 )?  Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                      child: Container(
                                        height: 3,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF888888), // background line
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ) : SizedBox()
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                        final fullImageUrl = "$baseUrl$imageUrl".trim();
                        
                        // ✅ Validate URL before loading
                        if (fullImageUrl.isEmpty || !fullImageUrl.startsWith('http')) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                width: double.infinity,
                                height: 124,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: CachedNetworkImage(
                              imageUrl: fullImageUrl,
                              fit: BoxFit.fill,
                              width: double.infinity,
                              height: 124,
                              useOldImageOnUrlChange: true,
                              fadeInDuration: const Duration(milliseconds: 300),
                              fadeOutDuration: const Duration(milliseconds: 200),
                              memCacheWidth: 1500, // ✅ Optimize memory usage
                              httpHeaders: const {
                                'Cache-Control': 'max-age=31536000', // Cache for 1 year
                              },
                              cacheKey: fullImageUrl, // ✅ Unique cache key
                              placeholder: (context, url) => Shimmer.fromColors(
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
                              ),
                              errorWidget: (context, url, error) {
                                // ✅ Retry on error - show placeholder that can be tapped to retry
                                return GestureDetector(
                                  onTap: () {
                                    // Force rebuild to retry loading
                                    bannerController.fetchImages(forceRefresh: true);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 124,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.refresh, color: Colors.grey),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                SizedBox(
                  height: 20,
                ),
                // why wti carousel
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Why Wise Travel India',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: CustomCarousel()),
                SizedBox(
                  height: 12,
                ),
                // special offers
                // SizedBox(
                //   height: 20,
                // ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Special Offers',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                // CustomTabBar(),

                // Carbon emission, women safety
                SizedBox(
                  width: double.infinity,
                  height: 174,
                  child: Obx(() {
                    if (bannerController.isLoading.value) {
                      // 🔥 Shimmer placeholders
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: MediaQuery.of(context).size.width * 0.75,
                              height: 174,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          },
                        ),
                      );
                    }

                    final images = bannerController.homepageImageResponse.value
                        ?.result?.bottomBanner?.images;
                    final baseUrl = bannerController
                            .homepageImageResponse.value?.result?.baseUrl ??
                        '';

                    if (images == null || images.isEmpty) {
                      return const Center(child: Text("No banners available"));
                    }

                    return CarouselSlider.builder(
                      itemCount: images.length,
                      options: CarouselOptions(
                        height: 174,
                        viewportFraction: 0.75,
                        enlargeCenterPage: false,
                        autoPlay: true,
                      ),
                      itemBuilder: (context, index, realIdx) {
                        final imageUrl = "$baseUrl${images[index].url ?? ''}".trim();
                        
                        // ✅ Validate URL before loading
                        if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.fill,
                              useOldImageOnUrlChange: true,
                              fadeInDuration: const Duration(milliseconds: 300),
                              fadeOutDuration:
                                  const Duration(milliseconds: 200),
                              memCacheWidth: 1500, // ✅ sharp banners
                              httpHeaders: const {
                                'Cache-Control': 'max-age=31536000', // Cache for 1 year
                              },
                              cacheKey: imageUrl, // ✅ Unique cache key
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  width: double.infinity,
                                  height: 174,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                // ✅ Retry on error
                                return GestureDetector(
                                  onTap: () {
                                    bannerController.fetchImages(forceRefresh: true);
                                  },
                                  child: Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.refresh, color: Colors.grey),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),

                SizedBox(
                  height: 16,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomCarousel extends StatefulWidget {
  const CustomCarousel({super.key});

  @override
  State<CustomCarousel> createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel>
    with AutomaticKeepAliveClientMixin {
  final UspController uspController = Get.put(UspController(), permanent: true);

  @override
  void initState() {
    super.initState();
    // ✅ Force fetch on first load with error handling
    uspController.fetchUsps().catchError((e) {
      debugPrint("❌ Error fetching USP: $e");
      // Retry after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) uspController.fetchUsps(forceRefresh: true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for keep-alive

    return Obx(() {
      if (uspController.isLoading.value) {
        return _buildShimmerCarousel(context);
      }

      final uspData = uspController.uspResponse.value?.data ?? [];
      if (uspData.isEmpty) {
        return const Center(child: Text("No USP found"));
      }

      return CarouselSlider(
        options: CarouselOptions(
          height: 190,
          viewportFraction: 0.47,
          enableInfiniteScroll: false,
          padEnds: false,
          enlargeCenterPage: false,
        ),
        items: uspData.map((item) {
          final imgUrl = (item.imgUrl ?? '').trim();
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // image
              Container(
                height: 106,
                width: MediaQuery.of(context).size.width * 0.56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: imgUrl.isEmpty || !imgUrl.startsWith('http')
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: imgUrl,
                          fit: BoxFit.fill,
                          useOldImageOnUrlChange: true,
                          memCacheHeight: 300,
                          memCacheWidth: 550,
                          httpHeaders: const {
                            'Cache-Control': 'max-age=31536000', // Cache for 1 year
                          },
                          cacheKey: imgUrl, // ✅ Unique cache key
                          fadeInDuration: const Duration(milliseconds: 300),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              color: Colors.grey,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            // ✅ Retry on error
                            return GestureDetector(
                              onTap: () {
                                uspController.fetchUsps(forceRefresh: true);
                              },
                              child: Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.refresh, color: Colors.grey),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              // title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.white,
                width: MediaQuery.of(context).size.width * 0.56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item.title ?? '',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

              // description
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                color: Colors.white,
                width: MediaQuery.of(context).size.width * 0.56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item.desc ?? '',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF4F4F4F)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),

              // bottom filler
              Container(
                width: MediaQuery.of(context).size.width * 0.56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
              ),
            ],
          );
        }).toList(),
      );
    });
  }

  Widget _buildShimmerCarousel(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 190,
        viewportFraction: 0.47,
        enableInfiniteScroll: false,
        padEnds: false,
      ),
      items: List.generate(
        4,
        (_) => _buildShimmerItem(context),
      ),
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 106,
          width: MediaQuery.of(context).size.width * 0.56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(color: Colors.grey, width: double.infinity),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: Colors.white,
          width: MediaQuery.of(context).size.width * 0.56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 12,
              color: Colors.grey,
              width: double.infinity,
            ),
          ),
        ),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          color: Colors.white,
          width: MediaQuery.of(context).size.width * 0.56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              children: [
                Container(
                    height: 10, color: Colors.grey, width: double.infinity),
                const SizedBox(height: 6),
                Container(
                    height: 10, color: Colors.grey, width: double.infinity),
              ],
            ),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class UspCard extends StatefulWidget {
  final dynamic item; // replace with your USP model
  const UspCard({super.key, required this.item});

  @override
  State<UspCard> createState() => _UspCardState();
}

class _UspCardState extends State<UspCard> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // required for keep-alive

    final item = widget.item;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // image
        Container(
          height: 106,
          width: MediaQuery.of(context).size.width * 0.56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: CachedNetworkImage(
              imageUrl: item.imgUrl ?? '',
              fit: BoxFit.cover,
              useOldImageOnUrlChange: true,
              memCacheHeight: 300,
              memCacheWidth: 550,
              httpHeaders: const {
                'Cache-Control': 'max-age=31536000', // Cache for 1 year
              },
              cacheKey: item.imgUrl ?? '', // ✅ Unique cache key
              fadeInDuration: const Duration(milliseconds: 300),
              fadeOutDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  color: Colors.grey,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              errorWidget: (context, url, error) {
                // ✅ Retry on error
                return GestureDetector(
                  onTap: () {
                    Get.find<UspController>().fetchUsps(forceRefresh: true);
                  },
                  child: Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.refresh, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: Colors.white,
          width: MediaQuery.of(context).size.width * 0.56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            item.title ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),

        // description
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          color: Colors.white,
          width: MediaQuery.of(context).size.width * 0.56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            item.desc ?? '',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4F4F4F),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),

        // bottom filler
        Container(
          width: MediaQuery.of(context).size.width * 0.56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({super.key});

  @override
  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  int selectedIndex = 0;

  final List<String> tabs = [
    'Top Offers',
    'Outstation Cabs',
    'Airport Transfer',
    'Pilgrimage',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scrollable Tab Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final bool isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = 0;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: isSelected
                            ? AppColors.mainButtonBg
                            : Color(0xFF7A7A7A)),
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.mainButtonBg
                          : Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Corresponding Content
        Container(
          margin: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
          child: getSelectedTabContent(selectedIndex),
        ),
      ],
    );
  }

  /// Returns different container for each tab
  Widget getSelectedTabContent(int index) {
    switch (index) {
      case 0:
        return TravelCarousel();
      case 1:
        return TravelCarousel();
      case 2:
        return TravelCarousel();
      case 3:
        return TravelCarousel();
      default:
        return const SizedBox.shrink();
    }
  }
}

class TravelCarousel extends StatelessWidget {
  final List<String> imagePaths = [
    'assets/images/sp1.png',
    'assets/images/sp2.png',
    'assets/images/sp1.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: CarouselSlider.builder(
        itemCount: imagePaths.length,
        options: CarouselOptions(
          height: MediaQuery.of(context).size.width *
              0.76, // Match with SizedBox height
          viewportFraction: 0.65,
          enlargeCenterPage: false,
          enableInfiniteScroll: true,
          padEnds: false,
          clipBehavior: Clip.antiAlias,
        ),
        itemBuilder: (context, index, realIndex) {
          return TravelOfferCard(imagePath: imagePaths[index]);
        },
      ),
    );
  }
}

class TravelOfferCard extends StatelessWidget {
  final String imagePath;

  const TravelOfferCard({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        right: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8), bottom: Radius.circular(8)),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 132,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // ✅ Handle missing asset images gracefully
                  return Container(
                    width: double.infinity,
                    height: 132,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Text(
              'Flat ₹200 OFF on your first airport ride',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF000000),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Text(
              'Kick off your journey with 20% off your first cab booking.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF4F4F4F),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFE6EAF9),
                  foregroundColor: AppColors.mainButtonBg,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Book Now',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BorderedListView extends StatefulWidget {
  @override
  State<BorderedListView> createState() => _BorderedListViewState();
}

class _BorderedListViewState extends State<BorderedListView> {
  List<String> _topRecentTrips = [];

  @override
  void initState() {
    super.initState();
  }

  final List<Map<String, String>> items = [
    {
      "title": "Indira Gandhi International Airport",
      "subtitle": "New Delhi, Delhi",
      "icon": Icons.home_outlined.codePoint.toString()
    },
    {
      "title": "Ambiance Mall",
      "subtitle": "Sector 24, Gurugram, Haryana",
      "icon": Icons.star_border.codePoint.toString()
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _topRecentTrips.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: const Color.fromRGBO(44, 44, 111, 0.15),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                EdgeInsets.only(left: 16), // removes horizontal padding
            dense: true, // makes it more compact
            minVerticalPadding: 0, // removes vertical padding
            leading: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(51, 51, 51, 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                'assets/images/history.svg',
                height: 16,
                width: 16,
              ),
            ),
            title: Text(
              items[index]["title"]!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              items[index]["subtitle"]!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF4F4F4F),
              ),
            ),
            tileColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}

class RecentTripList extends StatefulWidget {
  @override
  _RecentTripListState createState() => _RecentTripListState();
}

class _RecentTripListState extends State<RecentTripList> {
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  final PlaceSearchController placeSearchController =
      Get.put(PlaceSearchController());
  final DropPlaceSearchController dropPlaceSearchController =
      Get.put(DropPlaceSearchController());
  final TripHistoryController tripController = Get.put(TripHistoryController());
  final PopularDestinationController popularDestinationController =
      Get.put(PopularDestinationController());
  final DestinationLocationController dropLocationController =
      Get.put(DestinationLocationController());
  final SearchInventorySdController searchInventorySdController =
      Get.put(SearchInventorySdController());

  String address = '';
  List<Map<String, dynamic>> recentTrips = [];
  final UspController uspController = Get.put(UspController());

  // ✅ Use the same controller instance from parent to avoid conflicts
  final SourceLocationController sourceController =
      Get.put(SourceLocationController());
  final TripHistoryController tripHistoryController =
      Get.put(TripHistoryController());

  Future<void> fetchCurrentLocationAndAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(
          'yash current location : ${position.latitude}, ${position.longitude}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      print(
          'yash testing current lat/lng ${position.latitude}, ${position.longitude}');

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final components = <String>[
          p.name ?? '',
          p.street ?? '',
          p.subLocality ?? '',
          p.locality ?? '',
          p.administrativeArea ?? '',
          p.postalCode ?? '',
          p.country ?? '',
        ];

        final fullAddress =
            components.where((s) => s.trim().isNotEmpty).join(', ');

        setState(() {
          address = fullAddress;
        });

        // ✅ Fix: Use placeSearchController consistently
        await placeSearchController.searchPlaces(fullAddress, context);
        
        if (placeSearchController.suggestions.isEmpty) {
          throw Exception('No suggestions found for current location');
        }
        
        bookingRideController.prefilled.value = address;
        placeSearchController.placeId.value =
            placeSearchController.suggestions.first.placeId;

        // ✅ Ensure getLatLngDetails completes before proceeding
        await placeSearchController.getLatLngDetails(
            placeSearchController.suggestions.first.placeId, context);
        
        // ✅ Wait a bit to ensure lat/lng is set in controller
        int retryCount = 0;
        while (placeSearchController.getPlacesLatLng.value == null && retryCount < 5) {
          await Future.delayed(const Duration(milliseconds: 200));
          retryCount++;
        }
        
        if (placeSearchController.getPlacesLatLng.value == null) {
          throw Exception('Failed to get source location coordinates');
        }
        
        await StorageServices.instance.save(
            'sourcePlaceId', placeSearchController.suggestions.first.placeId);
        await StorageServices.instance.save(
            'sourceTitle', placeSearchController.suggestions.first.primaryText);
        await StorageServices.instance
            .save('sourceCity', placeSearchController.suggestions.first.city);
        await StorageServices.instance
            .save('sourceState', placeSearchController.suggestions.first.state);
        await StorageServices.instance.save(
            'sourceCountry', placeSearchController.suggestions.first.country);
        // ✅ Ensure country is saved (required for request data)
        await StorageServices.instance.save(
            'country', placeSearchController.suggestions.first.country);
        sourceController.setPlace(
          placeId: placeSearchController.suggestions.first.placeId,
          title: placeSearchController.suggestions.first.primaryText,
          city: placeSearchController.suggestions.first.city,
          state: placeSearchController.suggestions.first.state,
          country: placeSearchController.suggestions.first.country,
          types: placeSearchController.suggestions.first.types,
          terms: placeSearchController
              .suggestions.first.terms, // List<Map> -> List<Term>
        );
        print(
            'akash country: ${placeSearchController.suggestions.first.country}');
        if (placeSearchController.suggestions.first.types.isNotEmpty) {
          await StorageServices.instance.save('sourceTypes',
              jsonEncode(placeSearchController.suggestions.first.types));
        }
        if (placeSearchController.suggestions.first.terms.isNotEmpty) {
          await StorageServices.instance.save('sourceTerms',
              jsonEncode(placeSearchController.suggestions.first.terms));
        }
      } else {
        address = 'Address not found';
        throw Exception('Address not found');
      }

      print('Current location address: $address');
    } catch (e) {
      print('Error fetching location/address: $e');
      rethrow; // ✅ Re-throw to handle in calling function
    }
  }

  void _handlePlaceSelection(
      BuildContext context, SuggestionPlacesResponse place) {
    // Step 1️⃣ — Update Rx values first (Drop API context)
    bookingRideController.prefilledDrop.value = place.primaryText;
    dropPlaceSearchController.dropPlaceId.value = place.placeId;

    // FocusScope.of(context).unfocus();
    // Navigator.of(context).push(
    //   Platform.isIOS
    //       ? CupertinoPageRoute(
    //     builder: (_) => const BookingRide(),
    //   )
    //       : MaterialPageRoute(
    //     builder: (_) => const BookingRide(),
    //   ),
    // );
    // Step 3️⃣ — Run Drop API first, then current location
    Future.microtask(() async {
      try {
        // --- Drop LatLng API ---
        print('API Call: getLatLngForDrop for placeId: ${place.placeId}');
        await dropPlaceSearchController.getLatLngForDrop(
            place.placeId, context);

        // --- Pickup LatLng API ---
        final pickupPlaceId = placeSearchController.placeId.value;
        if (pickupPlaceId.isNotEmpty) {
          print('API Call: getLatLngDetails for pickupPlaceId: $pickupPlaceId');
          await placeSearchController.getLatLngDetails(pickupPlaceId, context);
        }

        // --- Record trip ---
        tripController.recordTrip(
          bookingRideController.prefilled.value,
          pickupPlaceId,
          place.primaryText,
          place.placeId,
          context,
        );

        // --- Storage operations ---
        StorageServices.instance.save('destinationPlaceId', place.placeId);
        StorageServices.instance.save('destinationTitle', place.primaryText);
        if (place.types.isNotEmpty) {
          StorageServices.instance
              .save('destinationTypes', jsonEncode(place.types));
        }
        if (place.terms.isNotEmpty) {
          StorageServices.instance
              .save('destinationTerms', jsonEncode(place.terms));
        }

        // --- Update destination controller ---
        dropLocationController.setPlace(
          placeId: place.placeId,
          title: place.primaryText,
          city: place.city,
          state: place.state,
          country: place.country,
          types: place.types,
          terms: place.terms,
        );

        // Step 4️⃣ — Finally fetch current location
        // await fetchCurrentLocationAndAddress();
      } catch (e, st) {
        debugPrint('❌ Error in _handlePlaceSelection: $e\n$st');
      }
    });
  }

  Future<Map<String, dynamic>> _buildRequestData(BuildContext context) async {
    final now = DateTime.now();
    final searchDate = now.toIso8601String().split('T').first;
    final searchTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final offset = now.timeZoneOffset.inMinutes;
    final BookingRideController bookingRideController =
        Get.put(BookingRideController());
    final PlaceSearchController placeSearchController =
        Get.put(PlaceSearchController());
    final DropPlaceSearchController dropPlaceSearchController =
        Get.put(DropPlaceSearchController());

    final keys = [
      'country',
      'userOffset',
      'userDateTime',
      'userTimeWithOffset',
      'actualTimeWithOffset',
      'actualOffset',
      'timeZone',
      'sourceTitle',
      'sourcePlaceId',
      'sourceTypes',
      'sourceTerms',
      'destinationPlaceId',
      'destinationTitle',
      'destinationTypes',
      'destinationTerms',
    ];

    final values = await Future.wait(keys.map(StorageServices.instance.read));
    final data = Map<String, dynamic>.fromIterables(keys, values);

    return {
      "timeOffSet": -offset,
      "countryName": data['country'],
      "searchDate": searchDate,
      "searchTime": searchTime,
      "offset": int.parse(data['userOffset'] ?? '0'),
      "pickupDateAndTime": bookingRideController.convertLocalToUtc(),
      "returnDateAndTime": "",
      "tripCode": "2",
      "source": {
        "sourceTitle": data['sourceTitle'],
        "sourcePlaceId": data['sourcePlaceId'],
        "sourceCity":
            placeSearchController.getPlacesLatLng.value?.city.toString(),
        "sourceState":
            placeSearchController.getPlacesLatLng.value?.state.toString(),
        "sourceCountry":
            placeSearchController.getPlacesLatLng.value?.country.toString(),
        "sourceType": _parseList<String>(data['sourceTypes']),
        "sourceLat":
            placeSearchController.getPlacesLatLng.value?.latLong.lat.toString(),
        "sourceLng":
            placeSearchController.getPlacesLatLng.value?.latLong.lng.toString(),
        "terms": _parseList<Map<String, dynamic>>(data['sourceTerms']),
      },
      "destination": {
        "destinationTitle": data['destinationTitle'],
        "destinationPlaceId": data['destinationPlaceId'],
        "destinationCity":
            dropPlaceSearchController.dropLatLng.value?.city.toString(),
        "destinationState":
            dropPlaceSearchController.dropLatLng.value?.state.toString(),
        "destinationCountry":
            dropPlaceSearchController.dropLatLng.value?.country.toString(),
        "destinationType": _parseList<String>(data['destinationTypes']),
        "destinationLat":
            dropPlaceSearchController.dropLatLng.value?.latLong.lat.toString(),
        "destinationLng":
            dropPlaceSearchController.dropLatLng.value?.latLong.lng.toString(),
        "terms": _parseList<Map<String, dynamic>>(data['destinationTerms']),
      },
      "packageSelected": {"km": "", "hours": ""},
      "stopsArray": [],
      "pickUpTime": {
        "time": data['actualTimeWithOffset'],
        "offset": data['actualOffset'],
        "timeZone": data['timeZone']
      },
      "dropTime": {},
      "mindate": {
        "date": data['userTimeWithOffset'],
        "time": data['userTimeWithOffset'],
        "offset": data['userOffset'],
        "timeZone": data['timeZone']
      },
      "isGlobal": (data['country']?.toLowerCase() == 'india') ? false : true,
    };
  }

  List<T> _parseList<T>(dynamic json) {
    if (json != null && json.isNotEmpty) {
      return List<T>.from(jsonDecode(json));
    }
    return [];
  }

  void resetDropSelection(BuildContext context) {
    // 1. Dismiss the FullScreenGifLoader dialog if it's open
    // 2. Reset controller states
    bookingRideController.prefilledDrop.value =
        ''; // Clear prefilled drop value
    dropPlaceSearchController.dropPlaceId.value = ''; // Clear drop place ID
    dropPlaceSearchController.dropSuggestions.clear(); // Clear drop suggestions

    // 3. Clear storage data related to destination
    StorageServices.instance.delete('destinationPlaceId');
    StorageServices.instance.delete('destinationTitle');
    StorageServices.instance.delete('destinationCity');
    StorageServices.instance.delete('destinationState');
    StorageServices.instance.delete('destinationCountry');
    StorageServices.instance.delete('destinationTypes');
    StorageServices.instance.delete('destinationTerms');

    // 4. Optionally reset location-related data
    // If fetchCurrentLocationAndAddress stores data, reset it (implementation depends on your setup)
    // Example: Reset any cached location data
    // locationController.clearLocation(); // Uncomment if you have such a method

    // 5. Prevent any pending navigation
    // If GoRouter has pending navigation, clear it (optional, depending on your use case)
    // GoRouter.of(context).clearStack(); // Uncomment if you want to reset the navigation stack
  }

  @override
  Widget build(BuildContext context) {
    popularDestinationController.fetchPopularDestinations();
    return tripController.topRecentTrips.isNotEmpty
        ? Obx(() {
            if (tripController.topRecentTrips.isEmpty) {
              return const Text("No recent trips");
            }

            return SizedBox(
              height: tripController.topRecentTrips.length != 1 ? 180 : 95,
              child: ListView.builder(
                itemCount: tripController.topRecentTrips.length >= 2
                    ? 2
                    : tripController.topRecentTrips.length,
                itemBuilder: (context, index) {
                  final trip = tripController.topRecentTrips[index];
                  final pickup = trip['pickup']['title'];
                  final dropTitle = trip['drop']['title'] ?? '';
                  final dropPlaceId = trip['drop']['placeId'] ?? '';
                  final parts = dropTitle.split(',');

                  final mainTitle = parts.first.trim();
                  final subTitle =
                      parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
                  final count = trip['count'];

                  return InkWell(
                    splashColor: Colors.transparent,
                    onTap: () async {
                      // 🚀 1️⃣ Instant feedback: show loader
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => FullScreenGifLoader(),
                      );
                      // GoRouter.of(context).go(AppRoutes.bottomNav);
                      // resetDropSelection(context);

                      // 🚀 2️⃣ Fetch current location first (must be awaited)
                      try {
                        // ✅ Check if source location already exists
                        final existingSourcePlaceId = await StorageServices.instance.read('sourcePlaceId');
                        if (existingSourcePlaceId == null || existingSourcePlaceId.isEmpty) {
                          // Only fetch if not already available
                          await fetchCurrentLocationAndAddress();
                        } else {
                          // ✅ Verify lat/lng is available
                          if (placeSearchController.getPlacesLatLng.value == null) {
                            // Try to get lat/lng from existing placeId
                            await placeSearchController.getLatLngDetails(existingSourcePlaceId, context);
                            // Wait for lat/lng to be set
                            int retryCount = 0;
                            while (placeSearchController.getPlacesLatLng.value == null && retryCount < 5) {
                              await Future.delayed(const Duration(milliseconds: 300));
                              retryCount++;
                            }
                          }
                        }
                      } catch (e) {
                        debugPrint("❌ Error fetching current location: $e");
                        // Don't return - try to continue with existing data
                        final existingSourcePlaceId = await StorageServices.instance.read('sourcePlaceId');
                        if (existingSourcePlaceId == null || existingSourcePlaceId.isEmpty) {
                          Navigator.pop(context);
                          return;
                        }
                      }
                      
                      bookingRideController.prefilledDrop.value = dropTitle;
                      dropPlaceSearchController.dropPlaceId.value = dropPlaceId;

                      // 🚀 3️⃣ Background work (non-blocking but awaited for correctness)
                      try {
                        await dropPlaceSearchController.searchDropPlaces(
                            dropTitle, context);
                        if (dropPlaceSearchController.dropSuggestions.isEmpty) {
                          Navigator.pop(context);
                          return;
                        }

                        final dropSuggestion =
                            dropPlaceSearchController.dropSuggestions.first;

                        // Fetch LatLng (optional if already available)
                        await dropPlaceSearchController.getLatLngForDrop(
                            dropPlaceId, context);

                        // Save destination details in Storage
                        StorageServices.instance
                            .save('destinationPlaceId', dropPlaceId);
                        StorageServices.instance
                            .save('destinationTitle', dropTitle);
                        StorageServices.instance
                            .save('destinationCity', dropSuggestion.city);
                        StorageServices.instance
                            .save('destinationState', dropSuggestion.state);
                        StorageServices.instance
                            .save('destinationCountry', dropSuggestion.country);
                        if (dropSuggestion.types.isNotEmpty) {
                          StorageServices.instance.save('destinationTypes',
                              jsonEncode(dropSuggestion.types));
                        }
                        if (dropSuggestion.terms.isNotEmpty) {
                          StorageServices.instance.save('destinationTerms',
                              jsonEncode(dropSuggestion.terms));
                        }

                        // Update controller state
                        dropLocationController.setPlace(
                          placeId: dropPlaceId,
                          title: dropTitle,
                          city: dropSuggestion.city,
                          state: dropSuggestion.state,
                          country: dropSuggestion.country,
                          types: dropSuggestion.types,
                          terms: dropSuggestion.terms,
                        );

                        // 🚀 4️⃣ Verify source location is ready before building request
                        final sourcePlaceId = await StorageServices.instance.read('sourcePlaceId');
                        if (sourcePlaceId == null || sourcePlaceId.isEmpty) {
                          Navigator.pop(context);
                          debugPrint("❌ Source location not available");
                          return;
                        }
                        
                        // Ensure source lat/lng is available
                        int sourceRetryCount = 0;
                        while (placeSearchController.getPlacesLatLng.value == null && sourceRetryCount < 10) {
                          await Future.delayed(const Duration(milliseconds: 300));
                          sourceRetryCount++;
                        }
                        
                        if (placeSearchController.getPlacesLatLng.value == null) {
                          Navigator.pop(context);
                          debugPrint("❌ Source lat/lng not available after retries");
                          return;
                        }
                        
                        // 🚀 5️⃣ Verify drop location lat/lng is available
                        int dropRetryCount = 0;
                        while (dropPlaceSearchController.dropLatLng.value == null && dropRetryCount < 10) {
                          await Future.delayed(const Duration(milliseconds: 300));
                          dropRetryCount++;
                        }
                        
                        if (dropPlaceSearchController.dropLatLng.value == null) {
                          Navigator.pop(context);
                          debugPrint("❌ Drop lat/lng not available after retries");
                          return;
                        }
                        
                        // 🚀 6️⃣ Build request data
                        final requestData = await _buildRequestData(context);
                        
                        // 🚀 7️⃣ Validate request data before navigation
                        if (requestData['source'] == null || 
                            requestData['destination'] == null ||
                            requestData['source']['sourceLat'] == null ||
                            requestData['source']['sourceLng'] == null ||
                            requestData['destination']['destinationLat'] == null ||
                            requestData['destination']['destinationLng'] == null) {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          debugPrint("❌ Request data incomplete: $requestData");
                          return;
                        }

                        // Close loader before navigation
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }

                        // 🚀 8️⃣ Navigate safely with requestData
                        // GoRouter.of(context).push(
                        //   AppRoutes.inventoryList,
                        //   extra: requestData,
                        // );

                        Navigator.of(context).push(
                          Platform.isIOS
                              ? CupertinoPageRoute(
                                  builder: (_) => InventoryList(
                                    requestData: requestData,
                                    fromRecentSearch: true,
                                  ),
                                )
                              : MaterialPageRoute(
                                  builder: (context) => InventoryList(
                                    requestData: requestData,
                                    fromRecentSearch: true,
                                  ),
                                ),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        debugPrint("❌ Error during drop setup: $e");
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.zero,
                      margin: const EdgeInsets.only(
                          bottom: 8, left: 16, right: 16, top: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F192653),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 16),
                        dense: true,
                        minVerticalPadding: 0,
                        leading: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(51, 51, 51, 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/history.svg',
                            height: 16,
                            width: 16,
                          ),
                        ),
                        title: Text(
                          mainTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          subTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4F4F4F),
                          ),
                          maxLines: 1,
                        ),
                        tileColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          })
        : Obx(() {
            final popularTitle = popularDestinationController.popularResponse
                    .value?.popularAirports?.first.primaryText ??
                '';
            final popularPlaceId = popularDestinationController
                    .popularResponse.value?.popularAirports?.first.placeId ??
                '';
            final popularParts = popularTitle.split(',');

            final mainPopularTitle = popularParts.first.trim();
            final subPopularTitle = popularParts.length > 1
                ? popularParts.sublist(1).join(',').trim()
                : '';
            // outstation
            final popularTitleOutStation = popularDestinationController
                    .popularResponse.value?.popularCities?.first.primaryText ??
                '';

            final popularplaceIDOutStation = popularDestinationController
                    .popularResponse.value?.popularCities?.first.placeId ??
                '';
            final popularPartsOutStation = popularTitleOutStation.split(',');

            final popularMainPopularTitle = popularPartsOutStation.first.trim();
            final popularSubPopularTitle = popularPartsOutStation.length > 1
                ? popularParts.sublist(1).join(',').trim()
                : '';

            return Column(
              children: [
                InkWell(
                  splashColor: Colors.transparent,
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => FullScreenGifLoader(),
                    );
                    // GoRouter.of(context).go(AppRoutes.bottomNav);
                    // resetDropSelection(context);

                    // 🚀 2️⃣ Fetch current location first (must be awaited)
                    try {
                      // ✅ Check if source location already exists
                      final existingSourcePlaceId = await StorageServices.instance.read('sourcePlaceId');
                      if (existingSourcePlaceId == null || existingSourcePlaceId.isEmpty) {
                        // Only fetch if not already available
                        await fetchCurrentLocationAndAddress();
                      } else {
                        // ✅ Verify lat/lng is available
                        if (placeSearchController.getPlacesLatLng.value == null) {
                          // Try to get lat/lng from existing placeId
                          await placeSearchController.getLatLngDetails(existingSourcePlaceId, context);
                          // Wait for lat/lng to be set
                          int retryCount = 0;
                          while (placeSearchController.getPlacesLatLng.value == null && retryCount < 5) {
                            await Future.delayed(const Duration(milliseconds: 300));
                            retryCount++;
                          }
                        }
                      }
                    } catch (e) {
                      debugPrint("❌ Error fetching current location: $e");
                      // Don't return - try to continue with existing data
                      final existingSourcePlaceId = await StorageServices.instance.read('sourcePlaceId');
                      if (existingSourcePlaceId == null || existingSourcePlaceId.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }
                    }
                    
                    bookingRideController.prefilledDrop.value = popularTitle;
                    dropPlaceSearchController.dropPlaceId.value =
                        popularPlaceId;

                    // 🚀 3️⃣ Background work (non-blocking but awaited for correctness)
                    try {
                      await dropPlaceSearchController.searchDropPlaces(
                          popularTitle, context);
                      if (dropPlaceSearchController.dropSuggestions.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }

                      final dropSuggestion =
                          dropPlaceSearchController.dropSuggestions.first;

                      // Fetch LatLng (optional if already available)
                      await dropPlaceSearchController.getLatLngForDrop(
                          popularPlaceId, context);

                      // Save destination details in Storage
                      StorageServices.instance
                          .save('destinationPlaceId', popularPlaceId);
                      StorageServices.instance
                          .save('destinationTitle', popularTitle);
                      StorageServices.instance
                          .save('destinationCity', dropSuggestion.city);
                      StorageServices.instance
                          .save('destinationState', dropSuggestion.state);
                      StorageServices.instance
                          .save('destinationCountry', dropSuggestion.country);
                      if (dropSuggestion.types.isNotEmpty) {
                        StorageServices.instance.save('destinationTypes',
                            jsonEncode(dropSuggestion.types));
                      }
                      if (dropSuggestion.terms.isNotEmpty) {
                        StorageServices.instance.save('destinationTerms',
                            jsonEncode(dropSuggestion.terms));
                      }

                      // Update controller state
                      dropLocationController.setPlace(
                        placeId: popularPlaceId,
                        title: popularTitle,
                        city: dropSuggestion.city,
                        state: dropSuggestion.state,
                        country: dropSuggestion.country,
                        types: dropSuggestion.types,
                        terms: dropSuggestion.terms,
                      );

                      // 🚀 4️⃣ Verify source location is ready before building request
                      final sourcePlaceId = await StorageServices.instance.read('sourcePlaceId');
                      if (sourcePlaceId == null || sourcePlaceId.isEmpty) {
                        Navigator.pop(context);
                        debugPrint("❌ Source location not available");
                        return;
                      }
                      
                      // Ensure source lat/lng is available
                      int sourceRetryCount = 0;
                      while (placeSearchController.getPlacesLatLng.value == null && sourceRetryCount < 10) {
                        await Future.delayed(const Duration(milliseconds: 300));
                        sourceRetryCount++;
                      }
                      
                      if (placeSearchController.getPlacesLatLng.value == null) {
                        Navigator.pop(context);
                        debugPrint("❌ Source lat/lng not available after retries");
                        return;
                      }
                      
                      // 🚀 5️⃣ Verify drop location lat/lng is available
                      int dropRetryCount = 0;
                      while (dropPlaceSearchController.dropLatLng.value == null && dropRetryCount < 10) {
                        await Future.delayed(const Duration(milliseconds: 300));
                        dropRetryCount++;
                      }
                      
                      if (dropPlaceSearchController.dropLatLng.value == null) {
                        Navigator.pop(context);
                        debugPrint("❌ Drop lat/lng not available after retries");
                        return;
                      }

                      // 🚀 6️⃣ Build request data
                      final requestData = await _buildRequestData(context);
                      
                      // 🚀 7️⃣ Validate request data before navigation
                      if (requestData['source'] == null || 
                          requestData['destination'] == null ||
                          requestData['source']['sourceLat'] == null ||
                          requestData['source']['sourceLng'] == null ||
                          requestData['destination']['destinationLat'] == null ||
                          requestData['destination']['destinationLng'] == null) {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        debugPrint("❌ Request data incomplete: $requestData");
                        return;
                      }

                      // Close loader before navigation
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }

                      // 🚀 8️⃣ Navigate safely with requestData
                      Navigator.of(context).push(
                        Platform.isIOS
                            ? CupertinoPageRoute(
                                builder: (_) => InventoryList(
                                  requestData: requestData,
                                  fromRecentSearch: true,
                                ),
                              )
                            : MaterialPageRoute(
                                builder: (context) => InventoryList(
                                  requestData: requestData,
                                  fromRecentSearch: true,
                                ),
                              ),
                      );
                    } catch (e) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      debugPrint("❌ Error during drop setup: $e");
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 0,
                    ),
                    margin: const EdgeInsets.only(
                        bottom: 8, left: 16, right: 16, top: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: const Color.fromRGBO(44, 44, 111, 0.15),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.only(
                          left: 16), // removes horizontal padding
                      dense: true, // makes it more compact
                      minVerticalPadding: 0, // removes vertical padding
                      leading: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(51, 51, 51, 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/history.svg',
                          height: 16,
                          width: 16,
                        ),
                      ),
                      title: Text(
                        mainPopularTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        subPopularTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4F4F4F),
                        ),
                      ),
                      tileColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => FullScreenGifLoader(),
                    );
                    // GoRouter.of(context).go(AppRoutes.bottomNav);
                    // resetDropSelection(context);

                    // 🚀 2️⃣ Fetch current location first (must be awaited)
                    try {
                      // ✅ Check if source location already exists
                      final existingSourcePlaceId = await StorageServices.instance.read('sourcePlaceId');
                      if (existingSourcePlaceId == null || existingSourcePlaceId.isEmpty) {
                        // Only fetch if not already available
                        await fetchCurrentLocationAndAddress();
                      } else {
                        // ✅ Verify lat/lng is available
                        if (placeSearchController.getPlacesLatLng.value == null) {
                          // Try to get lat/lng from existing placeId
                          await placeSearchController.getLatLngDetails(existingSourcePlaceId, context);
                          // Wait for lat/lng to be set
                          int retryCount = 0;
                          while (placeSearchController.getPlacesLatLng.value == null && retryCount < 5) {
                            await Future.delayed(const Duration(milliseconds: 300));
                            retryCount++;
                          }
                        }
                      }
                    } catch (e) {
                      debugPrint("❌ Error fetching current location: $e");
                      // Don't return - try to continue with existing data
                      final existingSourcePlaceId = await StorageServices.instance.read('sourcePlaceId');
                      if (existingSourcePlaceId == null || existingSourcePlaceId.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }
                    }
                    
                    bookingRideController.prefilledDrop.value = popularTitleOutStation;
                    dropPlaceSearchController.dropPlaceId.value =
                        popularplaceIDOutStation;

                    // 🚀 3️⃣ Background work (non-blocking but awaited for correctness)
                    try {
                      await dropPlaceSearchController.searchDropPlaces(
                          popularTitleOutStation, context);
                      if (dropPlaceSearchController.dropSuggestions.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }

                      final dropSuggestion =
                          dropPlaceSearchController.dropSuggestions.first;

                      // Fetch LatLng (optional if already available)
                      await dropPlaceSearchController.getLatLngForDrop(
                          popularplaceIDOutStation, context);

                      // Save destination details in Storage
                      StorageServices.instance
                          .save('destinationPlaceId', popularplaceIDOutStation);
                      StorageServices.instance
                          .save('destinationTitle', popularTitleOutStation);
                      StorageServices.instance
                          .save('destinationCity', dropSuggestion.city);
                      StorageServices.instance
                          .save('destinationState', dropSuggestion.state);
                      StorageServices.instance
                          .save('destinationCountry', dropSuggestion.country);
                      if (dropSuggestion.types.isNotEmpty) {
                        StorageServices.instance.save('destinationTypes',
                            jsonEncode(dropSuggestion.types));
                      }
                      if (dropSuggestion.terms.isNotEmpty) {
                        StorageServices.instance.save('destinationTerms',
                            jsonEncode(dropSuggestion.terms));
                      }

                      // Update controller state
                      dropLocationController.setPlace(
                        placeId: popularplaceIDOutStation,
                        title: popularTitleOutStation,
                        city: dropSuggestion.city,
                        state: dropSuggestion.state,
                        country: dropSuggestion.country,
                        types: dropSuggestion.types,
                        terms: dropSuggestion.terms,
                      );

                      // 🚀 4️⃣ Verify source location is ready before building request
                      final sourcePlaceId = await StorageServices.instance.read('sourcePlaceId');
                      if (sourcePlaceId == null || sourcePlaceId.isEmpty) {
                        Navigator.pop(context);
                        debugPrint("❌ Source location not available");
                        return;
                      }
                      
                      // Ensure source lat/lng is available
                      int sourceRetryCount = 0;
                      while (placeSearchController.getPlacesLatLng.value == null && sourceRetryCount < 10) {
                        await Future.delayed(const Duration(milliseconds: 300));
                        sourceRetryCount++;
                      }
                      
                      if (placeSearchController.getPlacesLatLng.value == null) {
                        Navigator.pop(context);
                        debugPrint("❌ Source lat/lng not available after retries");
                        return;
                      }
                      
                      // 🚀 5️⃣ Verify drop location lat/lng is available
                      int dropRetryCount = 0;
                      while (dropPlaceSearchController.dropLatLng.value == null && dropRetryCount < 10) {
                        await Future.delayed(const Duration(milliseconds: 300));
                        dropRetryCount++;
                      }
                      
                      if (dropPlaceSearchController.dropLatLng.value == null) {
                        Navigator.pop(context);
                        debugPrint("❌ Drop lat/lng not available after retries");
                        return;
                      }

                      // 🚀 6️⃣ Build request data
                      final requestData = await _buildRequestData(context);
                      
                      // 🚀 7️⃣ Validate request data before navigation
                      if (requestData['source'] == null || 
                          requestData['destination'] == null ||
                          requestData['source']['sourceLat'] == null ||
                          requestData['source']['sourceLng'] == null ||
                          requestData['destination']['destinationLat'] == null ||
                          requestData['destination']['destinationLng'] == null) {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        debugPrint("❌ Request data incomplete: $requestData");
                        return;
                      }

                      // Close loader before navigation
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }

                      // 🚀 8️⃣ Navigate safely with requestData
                      Navigator.of(context).push(
                        Platform.isIOS
                            ? CupertinoPageRoute(
                                builder: (_) => InventoryList(
                                  requestData: requestData,
                                  fromRecentSearch: true,
                                ),
                              )
                            : MaterialPageRoute(
                                builder: (context) => InventoryList(
                                  requestData: requestData,
                                  fromRecentSearch: true,
                                ),
                              ),
                      );
                    } catch (e) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      debugPrint("❌ Error during drop setup: $e");
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 0,
                    ),
                    margin: const EdgeInsets.only(
                        bottom: 8, left: 16, right: 16, top: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromRGBO(44, 44, 111, 0.15),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.only(
                          left: 16), // removes horizontal padding
                      dense: true, // makes it more compact
                      minVerticalPadding: 0, // removes vertical padding
                      leading: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(51, 51, 51, 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/history.svg',
                          height: 16,
                          width: 16,
                        ),
                      ),
                      title: Text(
                        popularMainPopularTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        popularDestinationController.popularResponse.value
                                ?.popularCities?.first.city ??
                            '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4F4F4F),
                        ),
                      ),
                      tileColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              ],
            );
          });
  }
}

class BottomCarouselBanner extends StatefulWidget {
  const BottomCarouselBanner({super.key});

  @override
  State<BottomCarouselBanner> createState() => _BottomCarouselBannerState();
}

class _BottomCarouselBannerState extends State<BottomCarouselBanner> {
  final UspController uspController = Get.put(UspController());
  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> data = [
      {
        'image': 'assets/images/free_cancel.png',
        'title': 'Free Cancellation',
        'subtitle': 'Free cancellation on most bookings.',
      },
      {
        'image': 'assets/images/ap_counter.png',
        'title': 'Dedicated Airport Counters',
        'subtitle':
            'Kick off your journey with 20% off your first cab booking.',
      },
      {
        'image': 'assets/images/sd_availbility.png',
        'title': 'Self Drive Availibility',
        'subtitle': 'Self Drive from the same platform',
      },
      {
        'image': 'assets/images/part_payment.png',
        'title': 'Part Payment',
        'subtitle':
            'Kick off your journey with 20% off your first cab booking.',
      },
    ];

    final List<Widget> items = data.map((item) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 106,
                width: MediaQuery.of(context).size.width * 0.56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(8), // ✅ Only top corners
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: 1.0,
                  child: ClipRRect(
                    child: Image.asset(
                      item['image'] ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(8), // ✅ Only top corners
                  ),
                ),
              ),
            ],
          );
        }).toList() ??
        [];

    return CarouselSlider(
      options: CarouselOptions(
        height: 190,
        viewportFraction: 0.47,
        enableInfiniteScroll: false,
        padEnds: false,
        enlargeCenterPage: false,
      ),
      items: items,
    );
  }
}

Widget _buildCategoryCard(
  BuildContext context, {
  required String label,
  required String image,
  required VoidCallback onTap,
  String? badge,
}) {
  final size = MediaQuery.of(context).size.width / 5; // 🔑 responsive size

  return InkWell(
    splashColor: Colors.transparent,
    onTap: onTap,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 4),
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
                  child: Image.asset(image, fit: BoxFit.contain),
                ),
                Text(label, style: CommonFonts.blueText1),
              ],
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC6CD00), Color(0xFF00DC3E)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}


// flip page animation
class PlatformFlipPageRoute extends PageRouteBuilder {
  final WidgetBuilder builder;

  PlatformFlipPageRoute({required this.builder})
      : super(
    transitionDuration: const Duration(milliseconds: 3000),
    reverseTransitionDuration: const Duration(milliseconds: 1700),
    pageBuilder: (context, animation, secondaryAnimation) =>
        builder(context),
    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {
      final isIOS =
          Theme.of(context).platform == TargetPlatform.iOS ||
              Theme.of(context).platform == TargetPlatform.macOS;

      final curvedAnim = CurvedAnimation(
        parent: animation,
        curve: isIOS
            ? Curves.easeInOutCubic
            : Curves.easeInOutCubicEmphasized,
      );

      return AnimatedBuilder(
        animation: curvedAnim,
        builder: (context, _) {
          final double rotation = curvedAnim.value * math.pi;
          final Matrix4 transform = Matrix4.identity()
            ..setEntry(3, 2, isIOS ? 0.001 : 0.002) // perspective
            ..rotateY(rotation);

          final bool isBackVisible = rotation > math.pi / 2;
          final double shadowOpacity =
              0.3 * (1 - (rotation / math.pi).abs());

          return Container(
            color: isIOS
                ? CupertinoColors.systemBackground
                : Colors.white,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.black
                        .withOpacity(shadowOpacity.clamp(0, 0.3)),
                  ),
                ),
                Transform(
                  transform: transform,
                  alignment: Alignment.center,
                  child: isBackVisible
                      ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scale(-1.0, 1.0, 1.0),
                    child: child,
                  )
                      : child,
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
