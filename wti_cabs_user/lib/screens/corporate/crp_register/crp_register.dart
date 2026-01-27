import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/common_widget/crp_branch_selectbox/crp_branch_selectbox.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_get_entity_all/crp_get_entity_list_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_register_controller/crp_register_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/verify_corporate/verify_corporate_controller.dart';

import '../../../common_widget/dropdown/cpr_select_box.dart';
import '../../../common_widget/textformfield/crp_text_form_field.dart';
import '../../../common_widget/snackbar/custom_snackbar.dart';
import '../../../core/api/corporate/cpr_api_services.dart';
import '../../../core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart';
import '../../../core/model/corporate/get_entity_list/get_entity_list_response.dart';
import '../../../core/controller/corporate/crp_gender/crp_gender_controller.dart';
import '../../../core/model/corporate/crp_gender_response/crp_gender_response.dart';
import '../../../core/route_management/app_routes.dart';
import '../../../utility/constants/colors/app_colors.dart';
import 'package:http/http.dart' as http;


class CprRegister extends StatefulWidget {
  const CprRegister({super.key});

  @override
  State<CprRegister> createState() => _CprRegisterState();
}

class _CprRegisterState extends State<CprRegister> {
  String? selectedDomain;
  Entity? selectedEntity;

  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneNoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final empIdController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final CrpGetEntityListController crpGetEntityListController =
      Get.put(CrpGetEntityListController());

  final FocusNode emailFocusNode = FocusNode();

  bool _autoValidate = false;
  bool _isEmailValid = false;
  String? _emailError;

  final VerifyCorporateController verifyCorporateController =
      Get.put(VerifyCorporateController());
  final CrpBranchListController crpGetBranchListController =
      Get.put(CrpBranchListController());

  bool _isValidating = false; // Prevent duplicate validation calls

  final CrpRegisterController crpRegisterController = Get.put(CrpRegisterController());
  // specific error
  String? _emailFieldError;
  String? _phoneFieldError;
  String? _entityFieldError;
  String? genderError;

  final GenderController _genderController = Get.put(GenderController());

  @override
  void initState() {
    super.initState();

    // 🔁 Reset all inputs and selections when screen appears
    nameController.clear();
    phoneNoController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    empIdController.clear();
    selectedEntity = null;
    _autoValidate = false;
    _emailError = null;
    _emailFieldError = null;
    _phoneFieldError = null;
    _entityFieldError = null;
    genderError = null;

    // Defer Rx updates & dropdown data fetch to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      crpGetBranchListController.selectedBranchName.value = null;
      crpGetBranchListController.selectedBranchId.value = null;
      _genderController.selectGender(null);
      _genderController.fetchGender(context);
    });

    // Validate when user leaves the email field (on blur)
    emailFocusNode.addListener(() async {
      // Only validate on blur if not already validating and email is not empty
      if (!emailFocusNode.hasFocus &&
          emailController.text.trim().isNotEmpty &&
          !_isValidating) {
        await _validateEmail();
        // Trigger validation to show error immediately
        WidgetsBinding.instance.addPostFrameCallback((_) async{
          _emailFieldKey.currentState?.validate();
        });
      }
    });
  }

  @override
  void dispose() {
    emailFocusNode.removeListener(() {});
    emailFocusNode.dispose();
    emailController.dispose();
    nameController.dispose();
    phoneNoController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    empIdController.dispose();
    super.dispose();
  }

  void _showGenderBottomSheet() {
    final list = _genderController.genderList;
    showModalBottomSheet<GenderModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  'Select Gender',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isSelected =
                        _genderController.selectedGender.value == item;
                    return ListTile(
                      title: Text(item.gender ?? ''),
                      trailing: isSelected
                          ? const Icon(Icons.check,
                              color: AppColors.mainButtonBg)
                          : null,
                      onTap: () {
                        setState(() {
                          genderError = null;
                        });
                        _genderController.selectGender(item);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _validateAndSubmit(Map<String, dynamic> params) async {
    setState(() => _autoValidate = true);

    // Reset field errors
    _emailFieldError = null;
    _phoneFieldError = null;
    _entityFieldError = null;

    // Validate form fields
    final isValid = _formKey.currentState?.validate() ?? false;

    // Validate gender (mandatory)
    bool extraValid = true;
    if (_genderController.selectedGender.value == null) {
      setState(() {
        genderError = 'Please select a gender';
      });
      extraValid = false;
    }

    if (!isValid || !extraValid) return;

    print('✅ Form is valid, proceed to API call');

    await crpRegisterController.verifyCrpRegister(params, context);

    final response = crpRegisterController.crpRegisterResponse.value;
    if (response != null) {
      final msg = response.msg ?? '';
      if (msg.startsWith('-1')) {
        // Email error
        setState(() {
          _emailFieldError = msg.substring(3).trim();
        });
      } else if (msg.startsWith('0')) {
        // Phone error
        setState(() {
          _phoneFieldError = msg.substring(2).trim();
        });
      } else if (msg.startsWith('-2')) {
        // Entity selection error
        setState(() {
          _entityFieldError = msg.substring(3).trim();
        });
      } else {
        // Success - Extract message between commas (e.g., "2324, Register Successfully, true" -> "Register Successfully")
        FocusScope.of(context).unfocus();
        String displayMsg = msg;
        if (msg.contains(',')) {
          final parts = msg.split(',');
          if (parts.length >= 2) {
            displayMsg = parts[1].trim();
          }
        }
        CustomSuccessSnackbar.show(context, displayMsg);
        context.push(AppRoutes.cprLandingPage);
      }
    } else {
      CustomFailureSnackbar.show(context, 'Registration failed. Please try again.');
    }
  }

  /// 🔍 Validate email using regex and call API if valid
  Future<void> _validateEmail() async {
    if (_isValidating) return; // Prevent duplicate calls
    _isValidating = true;

    final email = emailController.text.trim();
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    // Basic client-side validation
    if (email.isEmpty) {
      setState(() {
        _emailError = "Email is required";
        _isEmailValid = false;
      });
      _revalidateFields();
      _isValidating = false;
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _emailError = "Enter a valid email address";
        _isEmailValid = false;
      });
      _revalidateFields();
      _isValidating = false;
      return;
    }

    // Clear any previous error
    setState(() {
      _emailError = null;
      _isEmailValid = false;
    });
    _revalidateFields();

    try {
      await verifyCorporateController.verifyCorporate(email, selectedEntity?.entityId.toString()??'');
      final response = verifyCorporateController.cprVerifyResponse.value;

      if (response == null) {
        setState(() {
          _emailError = "Unable to verify email. Try again.";
          _isEmailValid = false;
        });
        _revalidateFields();
        return;
      }

      final code = response.code;
      final msg = response.msg ?? "";

      debugPrint("🔍 Corporate Verify -> Code: $code | Msg: $msg");

      if (code == 1) {
        setState(() {
          _emailError = msg.isNotEmpty ? msg : "Corporate not registered";
          _isEmailValid = false;
        });
      } else if (code == 0) {
        // ✅ Valid
        setState(() {
          _emailError = null;
          _isEmailValid = true;
        });
      } else {
        // Unexpected response
        setState(() {
          _emailError = msg.isNotEmpty ? msg : "Unexpected server response";
          _isEmailValid = false;
        });
      }
      await crpGetEntityListController.fetchAllEntities(email, verifyCorporateController.cprID.value);
      await crpGetBranchListController.fetchBranches(verifyCorporateController.cprID.value);
      _revalidateFields();
    } catch (e) {
      debugPrint("❌ Corporate email validation error: $e");
      setState(() {
        _emailError = "Error validating email";
        _isEmailValid = false;
      });
      _revalidateFields();
    } finally {
      _isValidating = false;
    }
  }

  /// 🔁 Helper: Re-run validations for field + form
  void _revalidateFields() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emailFieldKey.currentState?.validate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // ✅ required for iOS swipe
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          // 🔑 delay + use root context
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              GoRouter.of(context).push(AppRoutes.cprLandingPage);
            }
          });
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            reverse: true,
            padding: const EdgeInsets.all(20.0),
            child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: Obx(() {
                  // if(crpGetEntityListController.isLoading.value){
                  //   return Center(child: const CupertinoActivityIndicator());
                  // }


                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Transform.translate(
                            offset: const Offset(-15.0, 0.0),
                            child: IconButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                GoRouter.of(context).push(AppRoutes.cprLandingPage);
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: Colors.black,
                              ),
                              tooltip: 'Back',
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/wti_logo.svg',
                                  height: 17,
                                  width: 15,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.mainButtonBg,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 8),
                                    ),
                                    onPressed: () {},
                                    child: const Text(
                                      "Corporate",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48), // keep center alignment
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Welcome to the Team',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ✅ Name
                      CprTextFormField(
                        controller: nameController,
                        hintText: "Enter Name*",
                        labelText: "Name *",
                        validator: (value) => value == null || value.isEmpty
                            ? "Name is required"
                            : null,
                      ),

                      const SizedBox(height: 14),

                      // ✅ Phone
                      CprTextFormField(
                        controller: phoneNoController,
                        hintText: "Enter Phone Number*",
                        labelText: "Phone Number*",
                        keyboardType: TextInputType.phone,
                        isMobileNo: true,
                        validator: (value) {
                          if (_phoneFieldError != null) return _phoneFieldError;

                          if (value == null || value.isEmpty) {
                            return "Phone number is required";
                          }
                          if (value.length < 10) {
                            return "Minimum 10 digits required";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Email with focus + async API validation
                      CprTextFormField(
                          fieldKey: _emailFieldKey,
                          controller: emailController,
                          focusNode: emailFocusNode,
                          hintText: "Enter your email*",
                          labelText: "Enter Official Email ID (Used as login ID)*",
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            // Check API validation error first (highest priority)
                            // This will show the error when _emailError is set
                            if (_emailFieldError != null) return _emailFieldError;

                            if (_emailError != null && _emailError!.isNotEmpty) {
                              return _emailError;
                            }
                            // Basic validation
                            if (value == null || value.isEmpty) {
                              return "Email is required";
                            }
                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegex.hasMatch(value)) {
                              return "Enter a valid email address";
                            }
                            // If email format is valid but API validation hasn't run yet, return null
                            // The API validation will be triggered on field submit or blur
                            return null;
                          },
                          onFieldSubmitted: (_) async {
                            // Validate email when user submits the field (presses enter/done)
                            final email = emailController.text.trim();

                            // First, do basic validation (format check)
                            _emailFieldKey.currentState?.validate();

                            if (email.isNotEmpty) {
                              // Run API validation
                              await _validateEmail();
                              // The _validateEmail() method already triggers validation via addPostFrameCallback
                              // But we also trigger it here to ensure it shows immediately
                              if (mounted) {
                                // Small delay to ensure state is updated
                                await Future.delayed(
                                    const Duration(milliseconds: 50));
                                _emailFieldKey.currentState?.validate();
                                // Remove focus to show the error clearly
                                emailFocusNode.unfocus();
                              }
                            }
                          },
                          onChanged: (value) {
                            // Always rebuild to update dropdown visibility
                            setState(() {
                              // Clear error when user starts typing (for better UX)
                              if (_emailError != null && value.isNotEmpty) {
                                _emailError = null;
                                _isEmailValid = false;
                              }
                              
                              // Clear dropdowns when email is cleared
                              if (value.trim().isEmpty) {
                                selectedEntity = null;
                                crpGetBranchListController.selectedBranchName.value = null;
                                crpGetBranchListController.selectedBranchId.value = null;
                                crpGetEntityListController.getAllEntityList.value = null;
                              }
                            });

                            // 🔥 Force revalidation to show/hide error text dynamically
                            _revalidateFields();
                          }),


                      const SizedBox(height: 14),

                      // ✅ Gender
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // const Text(
                          //   'Gender *',
                          //   style: TextStyle(
                          //     fontSize: 14,
                          //     fontWeight: FontWeight.w500,
                          //     color: Color(0xFF374151),
                          //   ),
                          // ),
                          // const SizedBox(height: 10),
                          Obx(() {
                            final hasError = genderError != null && genderError!.isNotEmpty;
                            return GestureDetector(
                              onTap: () {
                                setState(() => genderError = null);
                                _showGenderBottomSheet();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: hasError
                                        ? Colors.red.shade400
                                        : const Color(0xFFE2E2E2),
                                    width: hasError ? 1.5 : 1,
                                  ),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _genderController
                                                .selectedGender.value?.gender ??
                                            'Select Gender*',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: hasError
                                              ? Colors.red.shade700
                                              : const Color(0xFF333333),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: hasError
                                          ? Colors.red.shade400
                                          : const Color(0xFF6B7280),
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          if (genderError != null) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 16, color: Colors.red.shade600),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      genderError!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ✅ Password
                      CprTextFormField(
                        controller: passwordController,
                        hintText: "Enter Password*",
                        labelText: "Password*",
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // ✅ Confirm Password
                      CprTextFormField(
                        controller: confirmPasswordController,
                        hintText: "Enter Confirm Password*",
                        labelText: "Confirm Password*",
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Confirm password is required";
                          }
                          if (value != passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // ✅ Employee ID
                      CprTextFormField(
                        controller: empIdController,
                        hintText: "Enter Employee ID",
                        labelText: "Employee ID",
                        validator: (value) => null,
                      ),
                      const SizedBox(height: 14),

                      // City - Only show if email is not empty and verification passed
                      emailController.text.trim().isNotEmpty &&
                              verifyCorporateController.cprVerifyResponse.value?.code ==
                              0
                          ? CorporateBranchDropdown(
                              corpId:
                                  selectedEntity?.entityId.toString() ?? '')
                          : const SizedBox.shrink(),
                      const SizedBox(height: 8),
                      // Entity List - Only show if email is not empty
                      emailController.text.trim().isNotEmpty
                          ? CprSelectBox(
                              labelText: "Choose Corporate",
                              hintText: "",
                              items: crpGetEntityListController
                                      .getAllEntityList.value?.getEntityList
                                      ?.map((val) => val.entityName ?? '')
                                      .toList() ??
                                  [],
                              selectedValue: selectedEntity?.entityName,
                              onChanged: (value) {
                                setState(() {
                                  selectedEntity = crpGetEntityListController
                                      .getAllEntityList.value?.getEntityList
                                      ?.firstWhere((e) => e.entityName == value);
                                });
                                print(
                                    "Selected Entity ID: ${selectedEntity?.entityId}");
                                print(
                                    "Selected Entity Name: ${selectedEntity?.entityName}");
                              },
                            )
                          : const SizedBox.shrink(),

                      const SizedBox(height: 20),

                      // ✅ Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                               onPressed: crpRegisterController.isLoading.value?(){} : (){
                                final Map<String, dynamic> params = {
                                  "guestName": nameController.text.trim(),
                                  "corporate_Name": verifyCorporateController.cprName.value,
                                  "CorpID": int.parse(verifyCorporateController.cprID.value),
                                  "mobile": phoneNoController.text.trim(),
                                  "emailID": emailController.text.trim(),
                                  "password": passwordController.text.trim(),
                                  "employeeID": empIdController.text.trim(),
                                  "branchID": crpGetBranchListController.selectedBranchId.value,
                                  "location": crpGetBranchListController.selectedBranchName.value,
                                  "IP": "local",
                                  "android_gcm": "",
                                  "ios_token": "",
                                  "EntityID": selectedEntity?.entityId!=null? selectedEntity?.entityId : "",
                                  "ManagerEmail": "",
                                  "register_sourceID": "MOBILE",
                                  "gender":_genderController.selectedGender.value?.genderID
                                };
                                _validateAndSubmit(params);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4082F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: crpRegisterController.isLoading.value? SizedBox(
                                width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(color: Colors.white,)) : const Text(
                                "Register Now",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // const SizedBox(width: 12),
                          // Expanded(
                          //   child: ElevatedButton(
                          //     onPressed: () {},
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Colors.white,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(16),
                          //         side: const BorderSide(color: Colors.black12),
                          //       ),
                          //       padding: const EdgeInsets.symmetric(vertical: 14),
                          //     ),
                          //     child: const Text(
                          //       "Cancel",
                          //       style: TextStyle(
                          //         color: Colors.black,
                          //         fontSize: 15,
                          //         fontWeight: FontWeight.w600,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  );
                })),
          ),
        ),
      ),
    );
  }
}
