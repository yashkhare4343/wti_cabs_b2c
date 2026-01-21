import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/common_widget/loader/custom_loader.dart';
import 'package:wti_cabs_user/common_widget/name_initials/name_initial.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/controller/manage_booking/upcoming_booking_controller.dart';
import 'package:wti_cabs_user/core/controller/profile_controller/update_profile_controller.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import '../../common_widget/loader/popup_loader.dart';
import '../../core/controller/profile_controller/profile_controller.dart';
import '../../core/route_management/app_routes.dart';
import '../../core/services/cache_services.dart';
import '../../core/services/storage_services.dart';
import '../../main.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../bottom_nav/bottom_nav.dart';

class Profile extends StatefulWidget {
  final bool? fromSelfDrive;
  Profile({super.key, this.fromSelfDrive});

  @override
  State<Profile> createState() => _ProfileState();

  bool isActive = false;
}

void _showLoader(String message, BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpinKitFadingCircle(
                  color: Colors.deepPurple,
                  size: 48.0,
                ),
                SizedBox(height: 16),
                Text(message, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    },
  );

  // Fake delay to simulate loading
  Future.delayed(const Duration(seconds: 3), () {
    Navigator.pop(context); // Close loader
  });
}

void _successLoader(String message, BuildContext outerContext) {
  showDialog(
    context: outerContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      // Start delayed closure using outerContext
      Future.delayed(const Duration(seconds: 1), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop(); // Close dialog
        }

        if (Navigator.of(outerContext).canPop()) {
          Navigator.of(outerContext).pop(); // Navigate back
        }
      });

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(message, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

bool isEdit = true;
String? selectedGender;

class _ProfileState extends State<Profile> {
  final ProfileController profileController = Get.put(ProfileController());
  final UpdateProfileController updateProfileController =
  Get.put(UpdateProfileController());
  final CurrencyController currencyController = Get.put(CurrencyController());
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final UpcomingBookingController upcomingBookingController =
  Get.put(UpcomingBookingController());
  String contact = '';
  String contactCode = '';
  PhoneNumber number = PhoneNumber(isoCode: 'IN');


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
                            // Clear user data but keep corporate session alive
                            StorageServices.instance.clearPreservingCorporate(preserveCorporate: true);
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
                            // Clear user data but keep corporate session alive
                            StorageServices.instance.clearPreservingCorporate(preserveCorporate: true);
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


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    profileController.fetchData().then((_) {
      final result = profileController.profileResponse.value?.result;
      profileController.checkLoginStatus();
      if (result != null) {
        setState(() {
          firstNameController.text = result.firstName ?? '';
          emailController.text = result.emailID ?? '';
          countryController.text = result.countryName ?? '';
          phoneNoController.text = result.contact?.toString() ?? '';
          contactCode = result.contactCode??'';
          cityController.text = result.city??'';
          stateController.text = result.stateName??'';

        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // iOS interactive swipe-back needs a real pop.
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    return PopScope(
      // Allow iOS swipe-back; keep Android back routing intact.
      canPop: isIOS,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Android back should route to the appropriate home.
        if (widget.fromSelfDrive == true) {
          GoRouter.of(context).push(AppRoutes.selfDriveBottomSheet);
        } else {
          GoRouter.of(context).push(AppRoutes.bottomNav);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBgPrimary2,
        appBar: AppBar(
          backgroundColor: AppColors.scaffoldBgPrimary2,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF192653),
              size: 20,
            ),
            onPressed: () {
              // Always use push (matches existing Android behavior).
              if (widget.fromSelfDrive == true) {
                GoRouter.of(context).push(AppRoutes.selfDriveBottomSheet);
              } else {
                GoRouter.of(context).push(AppRoutes.bottomNav);
              }
              setState(() {
                isEdit = false;
              });
            },
          ),
          centerTitle: true,
          title: const Text(
            "Profile",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFF192653),
              ),
              elevation: 8,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 45),
              splashRadius: 20,
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'signout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, size: 18, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'signout') {
                  // Handle sign-out logic
                  showLogoutDialog(context);
                } else if (value == 'delete') {
                  // Handle delete account logic
                  showDeleteDialog(context);
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Obx(() {
            if (profileController.isLoading == true) {
              return PopupLoader(message: 'Loading...');
            }
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 28),
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 32,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 16.0, bottom: isEdit != true ? 12 : 2),
                            child: Text(
                              "General Details",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Fields marked with * are mandatory',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF6D6D6D)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              EditableTextField(
                                label: "Full name *",
                                value: profileController.profileResponse.value
                                    ?.result?.firstName ??
                                    '',
                                controller: firstNameController,
                              ),
                              const SizedBox(height: 12),
                              EditableTextField(
                                label: "Email ID *",
                                value: profileController.profileResponse.value
                                    ?.result?.emailID ??
                                    '',
                                controller: emailController,
                              ),
                              const SizedBox(height: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:  const Color(0xFFE2E2E2),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFFF7F7F7),
                                ),
                                child: SizedBox(
                                  height: 48,
                                  child: InternationalPhoneNumberInput(
                                    selectorConfig: const SelectorConfig(
                                      selectorType:
                                      PhoneInputSelectorType.BOTTOM_SHEET,
                                      useBottomSheetSafeArea: true,
                                      showFlags: true,
                                    ),
                                    selectorTextStyle: const TextStyle(
                                      // ✅ smaller selector text
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    initialValue: number,
                                    textFieldController: phoneNoController,
                                    textStyle: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    onFieldSubmitted: (value) {

                                    },
                                    keyboardType:
                                    const TextInputType.numberWithOptions(
                                        signed: true),
                                    maxLength: 10,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return "Mobile number is required";
                                      }
                                      if (value.length != 10 ||
                                          !RegExp(r'^[0-9]+$').hasMatch(value)) {
                                        return "Enter valid 10-digit mobile number";
                                      }
                                      // trigger validation manually

                                      return null;
                                    },
                                    inputDecoration: const InputDecoration(
                                      hintText: "ENTER MOBILE NUMBER",
                                      hintStyle: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                      counterText: "",
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                      EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    formatInput: false,
                                    onInputChanged: (PhoneNumber value) async {
                                      contact = (value.phoneNumber
                                          ?.replaceAll(' ', '')
                                          .replaceFirst(
                                          value.dialCode ?? '', '')) ??
                                          '';
                                      contactCode =
                                          value.dialCode!.replaceAll('+', '');
                                      await StorageServices.instance
                                          .save('contactCode', contactCode ?? '');
                                      await StorageServices.instance
                                          .save('contact', contact ?? '');
                                    },
                                  ),
                                ),
                              ),
                              // EditableTextField(
                              //   label: "Mobile No *",
                              //   value:
                              //   "${profileController.profileResponse.value?.result?.contactCode} ${profileController.profileResponse.value?.result?.contact}",
                              //   controller: phoneNoController,
                              // ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: EditableTextField(
                                      label: "City",
                                      value: profileController.profileResponse.value
                                          ?.result?.city??"",
                                      controller: cityController,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: EditableTextField(
                                      label: "State",
                                      value: profileController.profileResponse.value
                                          ?.result?.stateName??"",
                                      controller: stateController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              EditableTextField(
                                label: "Nationality",
                                value: profileController.profileResponse.value
                                    ?.result?.countryName ??
                                    '',
                                controller: countryController,
                                readOnly: isEdit == false ? true : false,
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: const Color(0xFF000088),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 13),
                                  ),
                                  onPressed: () async {
                                    // Close loader
                                    _showLoader('Loading..', context);
                                    final Map<String, dynamic> requestData = {
                                      "firstName":
                                      firstNameController.text.trim(),
                                      "contact":
                                      phoneNoController.text.trim() ??
                                          '0000000000',
                                      "contactCode": contactCode,
                                      "countryName": currencyController.country.value,
                                      "gender": selectedGender,
                                      "city" : cityController.text.trim(),
                                      "stateName" : stateController.text.trim(),
                                      "emailID": emailController.text.trim()
                                    };
                                    await updateProfileController
                                        .updateProfile(
                                        requestData: requestData,
                                        context: context)
                                        .then((value) {
                                      _successLoader(
                                          'Profile Updated Successfully',
                                          context);
                                    });

                                    // / GoRouter.of(context).pop();
                                  },
                                  child: const Text(
                                    "Save Details",
                                    style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(() {
                        if(upcomingBookingController.isLoggedIn.value == true){
                          return NameInitialCircle(
                              name: profileController.profileResponse
                                  .value?.result?.firstName ??
                                  '');
                        }
                        return Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.only(bottom: 16),
                              child: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  radius: 40,
                                  child: Image.asset(
                                    'assets/images/user.png',
                                    width: 80,
                                    height: 80,
                                  )),
                            ),
                            isEdit == true
                                ? Positioned(
                              bottom: 5,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 28,
                                width: 28,
                                padding: EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: Color(0xFF002CC0),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            )
                                : SizedBox(),
                          ],
                        );
                      })
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class CustomDropdownField extends StatefulWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  State<CustomDropdownField> createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<CustomDropdownField> {
  late String selectedValue;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
    selectedValue = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  "Select ${widget.label}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.options.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey.shade200, height: 1),
                    itemBuilder: (context, index) {
                      final option = widget.options[index];
                      return ListTile(
                        title: Text(option),
                        onTap: () {
                          setState(() => selectedValue = option);
                          widget.onChanged(option);
                          _controller.text = selectedValue;
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusNode.hasFocus;

    return GestureDetector(
      onTap: _showBottomSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused ? Colors.blue : const Color(0xFFE2E2E2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF7F7F7),
        ),
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: true,
          onTap: () {
            _showBottomSheet();
          },
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            suffixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_drop_down_outlined,
                size: 24,
              ),
            ),
            label: ((isFocused))
                ? Transform.translate(
                offset: Offset(0, 4.0), child: Text(widget.label))
                : Container(
                padding: EdgeInsets.symmetric(
                    vertical: (_controller.text.isNotEmpty) ? 8 : 0),
                margin: EdgeInsets.only(
                    bottom: (_controller.text.isNotEmpty) ? 8 : 0),
                child: Text(widget.label)),
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isFocused ? Colors.blue : const Color(0xFF7D7D7D),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          ),
        ),
      ),
    );
  }
}

class EditableTextField extends StatefulWidget {
  final String label;
  final String value;
  final bool? readOnly;
  final VoidCallback? onTap;
  final TextEditingController? controller;

  const EditableTextField({
    super.key,
    required this.label,
    required this.value,
    this.readOnly,
    this.onTap,
    this.controller,
  });

  @override
  State<EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isExternalController = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(() => setState(() {}));

    _isExternalController = widget.controller != null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (!_isExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(
          color: isFocused ? Colors.blue : const Color(0xFFE2E2E2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFF7F7F7),
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: widget.readOnly ?? false,
        onTap: widget.onTap,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          label: isFocused
              ? Transform.translate(
            offset: const Offset(0, 8.0),
            child: Text(widget.label),
          )
              : Padding(
            padding:
            EdgeInsets.only(top: _controller.text.isNotEmpty ? 8 : 0),
            child: Text(widget.label),
          ),
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isFocused ? Colors.blue : const Color(0xFF7D7D7D),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        ),
      ),
    );
  }
}

Widget buildShimmer() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 96,
                height: 66,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(height: 12, width: 40, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 40, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 60, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 16, height: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    ),
  );
}