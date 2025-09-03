import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:wti_cabs_user/screens/verify_mobile.dart';

import '../../common_widget/buttons/main_button.dart';
import '../../core/controller/auth/mobile_controller.dart';
import '../../core/controller/auth/otp_controller.dart';
import '../../core/controller/auth/register_controller.dart';
import '../../core/controller/auth/resend_otp_controller.dart';
import '../../core/controller/profile_controller/profile_controller.dart';
import '../../core/route_management/app_routes.dart';
import '../../core/services/storage_services.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../bottom_nav/bottom_nav.dart';

class UserFillDetails extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  const UserFillDetails({super.key, required this.name, required this.email, required this.phone});

  @override
  State<UserFillDetails> createState() => _UserFillDetailsState();
}

class _UserFillDetailsState extends State<UserFillDetails> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? contact;
  String? contactCode;
  PhoneNumber number = PhoneNumber(isoCode: 'IN');
  final RegisterController registerController = Get.put(RegisterController());
  final ProfileController profileController = Get.put(ProfileController());



  String? _selectedGender = 'Male';

  // ✅ Validators
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Name is required";
    }
    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
      return "Enter a valid name";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    if (!RegExp(r"^[0-9]{10}$").hasMatch(value)) {
      return "Enter a valid 10-digit phone number";
    }
    return null;
  }

  String? _validateGender(String? value) {
    if (value == null) {
      return "Please select gender";
    }
    return null;
  }


  void _showAuthBottomSheet(String phoneNo) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController phoneController = TextEditingController(text: phoneNo);
    final TextEditingController otpTextEditingController =
    TextEditingController();
    final MobileController mobileController = Get.put(MobileController());
    final OtpController otpController = Get.put(OtpController());

    bool isGoogleLoading = false;

    PhoneNumber number = PhoneNumber(isoCode: 'IN');
    bool hasError = false;
    String? errorMessage;
    bool isButtonEnabled = phoneController.text.length == 10 ? true : false;
    bool showOtpField = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validatePhone(phoneNo);
      _formKey.currentState?.validate();
    });

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
              }
              else {
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
                                    autovalidateMode: AutovalidateMode.always, // validates on change
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
                                                AutovalidateMode.always,
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
                                              final isVerified = await otpController.verifyOtp(
                                                mobile: phoneController.text.trim(),
                                                otp: otpTextEditingController.text.trim(),
                                                context: context,
                                              );

                                              otpController.hasError.value = !isVerified;

                                              if (isVerified) {
                                                final rootContext = context; // capture before pushing the dialog

                                                Navigator.of(context).push(
                                                  DialogRoute(
                                                    context: context,
                                                    builder: (_) {
                                                      return AlertDialog(
                                                        title: Text("From Dialog"),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              // Open bottom sheet using root context
                                                              showModalBottomSheet(
                                                                context: rootContext,
                                                                isScrollControlled: true,
                                                                backgroundColor: Colors.transparent,
                                                                builder: (_) {
                                                                  return Container(
                                                                    height: 200,
                                                                    color: Colors.white,
                                                                    child: Center(
                                                                      child: ElevatedButton(
                                                                        onPressed: () {
                                                                          Navigator.of(rootContext, rootNavigator: true).pop(); // close sheet
                                                                          Navigator.of(rootContext, rootNavigator: true).pop(); // close dialog
                                                                          GoRouter.of(rootContext).go(AppRoutes.bottomNav);
                                                                        },
                                                                        child: Text("Go Home"),
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            child: Text("Open Sheet"),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                );



                                                // Show popup loader

                                                // Simulate 1-second wait
                                                // await Future.delayed(const Duration(seconds: 3));
                                                //
                                                // // Mark logged in
                                                // await profileController.fetchData();
                                                // GoRouter.of(context).pop();




                                                // Navigate
                                              }


                                            } catch (e) {
                                              otpController.hasError.value = true;

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
    _nameController.text = widget.name;
    _emailController.text = widget.email;
    _phoneController.text = widget.phone;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Create your account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),

                // Name
                CommonFormField(
                  label: 'Full Name',
                  hintText: "Full Name",
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  validator: _validateName,
                  onChanged: _validateName,
                ),
                const SizedBox(height: 16),

                // Email
                CommonFormField(
                  label: 'Email',
                  hintText: "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  onChanged: _validateEmail,
                ),
                const SizedBox(height: 16),

                // Phone Number
                Container(
                  padding: EdgeInsets.only(left: 8.0, top: 0.0, bottom: 0.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black87,
                      width: 1,
                    ),
                  ),
                  child: InternationalPhoneNumberInput(
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                      useBottomSheetSafeArea: true,
                      showFlags: true,
                    ),
                    initialValue: number,
                    textFieldController: _phoneController,
                    onFieldSubmitted: (value){
                      _formKey.currentState!.validate();
                    },
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    maxLength: 10,

                    validator: (value) {
                      if (value == null || value.length != 10) {
                        return "Enter valid 10-digit mobile number";
                      }
                      return null;
                    },
                    inputDecoration: const InputDecoration(
                      hintText: "Enter Mobile Number",
                      counterText: "",
                      border: InputBorder.none,
                    ),
                    formatInput: false, // 🚀 This disables auto spacing
                    onInputChanged: (PhoneNumber value) async {
                      // Remove spaces from the actual contact number
                      contact = (value.phoneNumber
                          ?.replaceAll(' ', '')
                          .replaceFirst(value.dialCode ?? '', '')) ??
                          '';
                      contactCode = value.dialCode?.replaceAll('+', '');
                      await StorageServices.instance.save('contactCode', contactCode??'');
                      await StorageServices.instance.save('contact', contact??'');
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Gender Selection
                const Text(
                  "Gender",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: "Male",
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    const Text("Male"),
                    Radio<String>(
                      value: "Female",
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    const Text("Female"),
                    Radio<String>(
                      value: "Other",
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    const Text("Other"),
                  ],
                ),
                if (_selectedGender == null)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, top: 4),
                    child: Text(
                      "Please select gender",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async{
                      if (_formKey.currentState!.validate() &&
                          _selectedGender != null) {
                        // ✅ Form is valid
                          final Map<String, dynamic> requestData = {
                            "firstName": _nameController.text.trim(),
                            // "lastName": "Sahni",
                            "contact": _phoneController.text.trim() ?? '000000000',
                            "contactCode": "91",
                            "countryName": "India",
                            // "address": "String",
                            // "city": "String",
                            "gender": "MALE",
                            // "postalCode": "String",
                            "emailID": _emailController.text.trim()
                            // "password": "String"
                            // "otp": {
                            //     "code": "Number",
                            //     "otpExpiry": ""
                            // }
                          };
                          await registerController
                              .verifySignup(requestData: requestData, context: context)
                              .then((value) {
                            // _showAuthBottomSheet(_phoneController.text.trim());
                            // GoRouter.of(context).push(_phoneController.text.trim());
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AuthScreen(phoneNo: _phoneController.text.trim()),
                              ),
                            );
                          });
                      }
                    },
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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
}



class CommonFormField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const CommonFormField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Permanent Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black87, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
