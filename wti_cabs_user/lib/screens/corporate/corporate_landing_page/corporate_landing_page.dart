import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';

import '../../../core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart';
import '../../../core/controller/corporate/crp_get_entity_all/crp_get_entity_list_controller.dart';
import '../../../core/controller/corporate/verify_corporate/verify_corporate_controller.dart';
import '../../../utility/constants/colors/app_colors.dart';

class CorporateLandingPage extends StatefulWidget {
  const CorporateLandingPage({super.key});

  @override
  State<CorporateLandingPage> createState() => _CorporateLandingPageState();
}

class _CorporateLandingPageState extends State<CorporateLandingPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _showBottomSheet();
    });  }

  final VerifyCorporateController verifyCorporateController = Get.put(VerifyCorporateController());
  final CrpBranchListController crpBranchListController = Get.put(CrpBranchListController());
  final CrpGetEntityListController crpGetEntityListController = Get.put(CrpGetEntityListController());

  void _showBottomSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true, // for full height if needed
      barrierColor: Colors.transparent, // 👈 removes dark overlay
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.width * 0.8, // 30% of screen height
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Hello 👋 This sheet opened automatically!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  static const _icon1 = 'assets/images/sp_offers.png';
  static const _icon2 = 'assets/images/currency_rupee_circle.png';
  static const _icon3 = 'assets/images/invoice.png';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height*0.66,
                child: Image.asset(
                  'assets/images/corporate_landing.png',
                  fit: BoxFit.cover,
                ),
              ),
              Transform.translate(
                offset: const Offset(0.0, -20.0),
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height*0.3,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),   // 👈 top left corner
                        topRight: Radius.circular(20),  // 👈 top right corner
                      ),

                    ) , child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 30,),
                    // Icons row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _PromoItem(
                            iconAsset: _icon1,
                            title: 'Special\nCorporate Fare',
                            // small tweak to match screenshot line breaks
                          ),
                          _PromoItem(
                            iconAsset: _icon2,
                            title: 'Zero\nCancelation Fees',
                          ),
                          _PromoItem(
                            iconAsset: _icon3,
                            title: 'Guaranteed GST\nInvoices',
                          ),
                        ],
                      ),
                    ),

                    // A little spacing between icons and button
                    const SizedBox(height: 6),

                    // Sign-in button with rounded top corners and no overlay
                    GestureDetector(
                      onTap: () {
                        // your sign in action
                        GoRouter.of(context).push(AppRoutes.cprLogin);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          height: 40,
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
                    SizedBox(height: 10,),
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
                         GoRouter.of(context).push(AppRoutes.cprEditProfile);
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
    );


  }
}

class _PromoItem extends StatelessWidget {
  final String iconAsset;
  final String title;
  const _PromoItem({required this.iconAsset, required this.title});

  @override
  Widget build(BuildContext context) {
    // control icon and text sizes to match screenshot proportions
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          // icon container
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            child: Image.asset(
              iconAsset,
              fit: BoxFit.contain,
              // If you don't have custom icons, replace Image.asset with an Icon(...) for quick testing.
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF192653), // dark bluish text
              fontSize: 12,
              height: 1.05,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }
}