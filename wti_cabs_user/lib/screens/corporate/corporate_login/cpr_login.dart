import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
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

  void _validateAndSubmit(Map<String, dynamic> params) async {
    // setState(() => _autoValidate = true);



    // Validate form
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    print('✅ Form is valid, proceed to API call');

    await loginInfoController.fetchLoginInfo(params, context);

    final response = loginInfoController.crpLoginInfo.value;
    if(response?.bStatus == true){
      StorageServices.instance.save('crpKey', response?.key??'');
      StorageServices.instance.save('crpId', response?.corpID??'');
      StorageServices.instance.save('branchId', response?.branchID??'');
      StorageServices.instance.save('guestId', response?.guestID.toString()??'');

      GoRouter.of(context).push(AppRoutes.cprHomeScreen);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _showBottomSheet();
    });  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                isPassword: false,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Password is required";
                                  }
                                  if (value.length < 6) {
                                    return "Minimum 6 characters required";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // A little spacing between icons and button
                      const SizedBox(height: 6),

                      // Sign-in button with rounded top corners and no overlay
                      GestureDetector(
                        onTap: () {
                          // your sign in action
                          final Map<String, dynamic> params = {
                            "password": passwordController.text.trim(),
                            "android_gcm": "", // replace with actual GCM token if available
                            "ios_token": "",   // replace with actual iOS token if available
                            "email": emailController.text.trim(), // decoded %40 → @
                          };
                          _validateAndSubmit(params);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Container(
                            height: 48,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              // subtle gradient similar to screenshot
                              color: Color(0xFF01ACF2),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10),
                                bottom: Radius.circular(10),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x2203A9F4),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'SIGN IN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8,),
                      InkWell(
                        splashColor: Colors.transparent,
                        onTap: (){
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            GoRouter.of(context).push(AppRoutes.cprRegister);
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                            children: [
                              const TextSpan(text: "Don’t have an account? "),
                              TextSpan(
                                text: "Register",
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
                      )

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
                  ],))

          ],
        ),
      ),
    );


  }
}

