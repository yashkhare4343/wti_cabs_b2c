import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';

import '../../../common_widget/textformfield/crp_text_form_field.dart';
import '../../../core/route_management/app_routes.dart';
import '../../../utility/constants/colors/app_colors.dart';

class CprLogin extends StatefulWidget {
  const CprLogin({super.key});

  @override
  State<CprLogin> createState() => _CprLoginState();
}

class _CprLoginState extends State<CprLogin> {
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());
  bool _isSignInEnabled = false;

  Future<void> _restorePreviousSession() async {
    // Prefill email so users don't have to re-enter after relaunch
    final savedEmail = await StorageServices.instance.read('email') ?? '';
    final prefs = await SharedPreferences.getInstance();
    final fallbackEmail = prefs.getString('email') ?? '';
    final emailToPrefill = savedEmail.isNotEmpty ? savedEmail : fallbackEmail;
    if (emailToPrefill.isNotEmpty) {
      emailController.text = emailToPrefill;
    }

    // If a corporate session exists, jump directly to dashboard
    final existingKey = await StorageServices.instance.read('crpKey');
    if (existingKey != null && existingKey.isNotEmpty && mounted) {
      GoRouter.of(context).go(AppRoutes.cprBottomNav);
    }
  }

  void _validateAndSubmit(Map<String, dynamic> params) async {
    // setState(() => _autoValidate = true);



    // Validate form
    final isValid = _formKey.currentState?.validate() ?? false;
    // if (!isValid) return;

    print('✅ Form is valid, proceed to API call');

    await loginInfoController.fetchLoginInfo(params, context);

    final response = loginInfoController.crpLoginInfo.value;
    if (response?.bStatus == true) {
      // Store all corporate session data
      await StorageServices.instance.save('crpKey', response?.key ?? '');
      await StorageServices.instance.save('crpId', response?.corpID?.toString() ?? '');
      await StorageServices.instance.save('branchId', response?.branchID?.toString() ?? '');
      await StorageServices.instance.save('guestId', response?.guestID.toString() ?? '');
      await StorageServices.instance.save('guestName', response?.guestName ?? '');

      // Store additional prefill-related fields so booking engine can restore them
      await StorageServices.instance
          .save('crpGenderId', response?.genderId.toString() ?? '');
      await StorageServices.instance
          .save('crpEntityId', response?.entityId.toString() ?? '');
      await StorageServices.instance
          .save('crpPayModeId', response?.payModeID.toString() ?? '');
      await StorageServices.instance
          .save('crpCarProviders', response?.carProviders.toString() ?? '');
      await StorageServices.instance.save(
          'crpAdvancedHourToConfirm',
          response?.advancedHourToConfirm.toString() ?? '');

      // ✅ Ensure email & password are saved again after successful login for persistence
      final email = params['email']?.toString() ?? emailController.text.trim();
      final password = params['password']?.toString() ?? passwordController.text.trim();

      if (email.isNotEmpty) {
        await StorageServices.instance.save('email', email);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        debugPrint('✅ Email saved after successful login: $email');
      }

      if (password.isNotEmpty) {
        await StorageServices.instance.save('crpPassword', password);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('crpPassword', password);
        debugPrint('✅ Corporate password saved after successful login');
      }

      // Navigate to corporate bottom nav
      if (context.mounted) {
        GoRouter.of(context).push(AppRoutes.cprBottomNav);
      }
    }

    // await crpRegisterController.verifyCrpRegister(params, context);
    //
    // final response = crpRegisterController.crpRegisterResponse.value;
    // if (response != null) {
    //   final msg = response.msg ?? '';
    //   if (msg.startsWith('-1')) {
    //     // Email error
    //     setState(() {
    //       _emailFieldError = msg.substring(3).trim();
    //     });
    //   } else if (msg.startsWith('0')) {
    //     // Phone error
    //     setState(() {
    //       _phoneFieldError = msg.substring(2).trim();
    //     });
    //   } else if (msg.startsWith('-2')) {
    //     // Entity selection error
    //     setState(() {
    //       _entityFieldError = msg.substring(3).trim();
    //     });
    //   } else {
    //     // Success
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text(msg),
    //         backgroundColor: Colors.green,
    //       ),
    //     );
    //   }
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Registration failed. Please try again.'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    emailController.addListener(_recomputeSignInEnabled);
    passwordController.addListener(_recomputeSignInEnabled);
    _recomputeSignInEnabled();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restorePreviousSession();
      // _showBottomSheet();
    });  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _recomputeSignInEnabled() {
    final nextEnabled = emailController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty;
    if (nextEnabled != _isSignInEnabled && mounted) {
      setState(() => _isSignInEnabled = nextEnabled);
    }
  }

  @override
  void dispose() {
    emailController.removeListener(_recomputeSignInEnabled);
    passwordController.removeListener(_recomputeSignInEnabled);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
        body: SingleChildScrollView(
          reverse: true,
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height*0.6,
                    child: Image.asset(
                      'assets/images/corporate_landing.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0.0, -20.0),
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height*0.45,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),   // 👈 top left corner
                          topRight: Radius.circular(16),  // 👈 top right corner
                        ),

                      ) , child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 30,),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              Text('Welcome Back', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),),
                            ],
                          ),
                        ),
                        // Icons row
                        // SizedBox(height: 20,),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                            CprTextFormField(
                              controller: emailController,
                              hintText: "Enter your email",
                              labelText: "Enter Official Email ID (Used as login ID)   ",
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Email is required";
                                }
                                if (!value.contains("@")) {
                                  return "Enter a valid email";
                                }
                                return null;
                              },
                            ),

                                const SizedBox(height: 16),

                                CprTextFormField(
                                  controller: passwordController,
                                  hintText: "Enter your password",
                                  labelText: "Password",
                                  isPassword: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Password is required";
                                    }
                                    // if (value.length < 6) {
                                    //   return "Minimum 6 characters required";
                                    // }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      GoRouter.of(context).push(AppRoutes.cprForgotPassword);
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          const TextSpan(text: ""),
                                          TextSpan(
                                            text: "Forgot Password",
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.black,
                                                decoration: TextDecoration.underline
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // A little spacing between icons and button
                        const SizedBox(height: 6),

                        // Sign-in button with rounded top corners and no overlay

                       Obx(()=>Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 20.0),
                         child: SizedBox(
                           width: double.infinity,
                           child: ElevatedButton(
                             style: ElevatedButton.styleFrom(
                               elevation: 0, // no default Material shadow
                               backgroundColor: const Color(0xFF2563EB), // change if needed
                               disabledBackgroundColor:
                                   const Color(0xFF2563EB).withOpacity(0.5),
                               disabledForegroundColor: Colors.white.withOpacity(0.9),
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(39),
                               ),
                               padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                             ),
                             onPressed: (!_isSignInEnabled ||
                                     loginInfoController.isLoading.value)
                                 ? null
                                 : () async {
                               FocusScope.of(context).unfocus();
                               // your sign in action
                               final Map<String, dynamic> params = {
                                 "password": passwordController.text.trim(),
                                 "android_gcm": "", // replace with actual GCM token if available
                                 "ios_token": "",   // replace with actual iOS token if available
                                 "email": emailController.text.trim(), // decoded %40 → @
                               };
                               // final Map<String, dynamic> params = {
                               //   "password": 'Test@123',
                               //   "android_gcm": "", // replace with actual GCM token if available
                               //   "ios_token": "",   // replace with actual iOS token if available
                               //   "email": 'developer14@aaveg.co.in', // decoded %40 → @
                               // };
                               await StorageServices.instance.save('email', emailController.text.trim());
                               final prefs = await SharedPreferences.getInstance();
                               await prefs.setString('email', emailController.text.trim());
                               _validateAndSubmit(params);
                             },
                             child: loginInfoController.isLoading.value
                                 ? const SizedBox(
                                     width: 20,
                                     height: 20,
                                     child: CircularProgressIndicator(
                                       color: Colors.white,
                                       strokeWidth: 2,
                                     ),
                                   )
                                 : const Text(
                                     'Sign In',
                                     textAlign: TextAlign.center,
                                     style: TextStyle(
                                       fontFamily: 'Montserrat',
                                       fontWeight: FontWeight.w900, // Black
                                       fontSize: 16,
                                       color: Colors.white,
                                       letterSpacing: 0,
                                     ),
                                   ),
                           ),
                         ),
                       )),
                        SizedBox(height: 8,),


                      ],
                    ),        ),
                  )
                ],
              ),
              Positioned(
                  top: 84,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/wti_logo.svg',
                        height: 17,
                        width: 15,
                      ),
                      SizedBox(width: 8,),
                      Container(
                        height: 30,
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
                          onPressed: (){


                          },
                          child: const Text(
                            "Corporate",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      )
                    ],)),
              // Back button (always pushes retail bottom nav)
              Positioned(
                top: 80,
                left: 8,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 18,
                        ),
                        onPressed: (){
                             GoRouter.of(context).push(AppRoutes.cprLandingPage);
                        },
                      ),
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
}

