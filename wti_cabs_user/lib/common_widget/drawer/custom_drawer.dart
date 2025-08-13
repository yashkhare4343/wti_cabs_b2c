import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

import '../../core/services/storage_services.dart';
import '../../main.dart';

class CustomDrawerSheet extends StatefulWidget {
  const CustomDrawerSheet({super.key});

  @override
  State<CustomDrawerSheet> createState() => _CustomDrawerSheetState();
}

class _CustomDrawerSheetState extends State<CustomDrawerSheet> {
  bool isLogin = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkLogin();
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

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.8;

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
                    'Are you sure you want to log out?',
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
                          onPressed: () {
                            Navigator.of(dialogContext).pop(); // close popup
                            StorageServices.instance.clear();
                            // Get.deleteAll(force: true);
                            Navigator.of(dialogContext)
                                .pop(); // close popup first

                            // Clear data
                            StorageServices.instance.clear();

                            // Show success popup/snackbar
                            Future.delayed(const Duration(milliseconds: 200),
                                () {
                              showDialog(
                                context: navigatorKey.currentContext!,
                                barrierDismissible: false,
                                builder: (_) {
                                  // Start auto-close timer
                                  Future.delayed(const Duration(seconds: 2),
                                      () {
                                    if (Navigator.of(
                                            navigatorKey.currentContext!)
                                        .canPop()) {
                                      Navigator.of(navigatorKey.currentContext!)
                                          .pop();
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
                            GoRouter.of(context).go(AppRoutes.initialPage);
                          },
                          child: Text(
                            'Logout',
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
                      height: 17,
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
                  height: 22,
                ),

                /// Drawer Items
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/india_logo.svg',
                    height: 16,
                    width: 24,
                  ),
                  title: 'Country',
                  subtitle: 'India',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/payments.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Currency',
                  subtitle: 'Select Currency',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/refer.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Refer & Earn',
                  subtitle: 'Driving Licence, Passport, ID etc.',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/language.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/docs.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Documents',
                  subtitle: 'Driving Licence, Passport, ID etc.',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/legal.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Legal',
                  subtitle: 'Privacy Policy, Terms & Conditions',
                  onTap: () {},
                ),
                isLogin == true ? _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/logout.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Sign Out',
                  subtitle: 'Driving Licence, Passport, ID etc.',
                  onTap: () {
                    showLogoutDialog(context);
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
                  SizedBox(
                    height: 4,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF929292),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
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
