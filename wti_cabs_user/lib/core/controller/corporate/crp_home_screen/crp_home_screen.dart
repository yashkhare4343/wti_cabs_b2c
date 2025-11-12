import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../common_widget/textformfield/read_only_textformfield.dart';
import '../../../../utility/constants/colors/app_colors.dart';

class CprHomeScreen extends StatefulWidget {
  const CprHomeScreen({super.key});

  @override
  State<CprHomeScreen> createState() => _CprHomeScreenState();
}

class _CprHomeScreenState extends State<CprHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(
        children: [
          SizedBox(
            height: 300,
              child: TopBanner())
        ],
      )),
    );
  }
}

class TopBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove appBar for a cleaner look
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient Sky Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/crp_home_banner.png'), // Use your image path here
                fit: BoxFit.cover, // Choose fit as per your layout
              ),
            ),
          ),
          // Foreground content
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row for logo and button
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
                      Row(
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
                              onPressed:   () async{
                              },
                              child: const Text(
                                "Personal Cab",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )

                          // upcomingBookingController
                          //             .isLoggedIn.value ==
                          //         true
                          //     ? InkWell(
                          //         splashColor: Colors.transparent,
                          //         onTap: () async {
                          //           print(
                          //               'homepage yash token for profile : ${await StorageServices.instance.read('token') == null}');
                          //           if (await StorageServices
                          //                   .instance
                          //                   .read('token') ==
                          //               null) {
                          //             _showAuthBottomSheet();
                          //           }
                          //           if (await StorageServices
                          //                   .instance
                          //                   .read('token') !=
                          //               null) {
                          //             GoRouter.of(context)
                          //                 .push(AppRoutes.profile);
                          //           }
                          //         },
                          //         child: SizedBox(
                          //           width: 30,
                          //           height: 30,
                          //           child: NameInitialHomeCircle(
                          //               name: profileController
                          //                       .profileResponse
                          //                       .value
                          //                       ?.result
                          //                       ?.firstName ??
                          //                   ''),
                          //         ),
                          //       )
                          //     : InkWell(
                          //         splashColor: Colors.transparent,
                          //         onTap: () async {
                          //           print(
                          //               'homepage yash token for profile : ${await StorageServices.instance.read('token') == null}');
                          //           if (await StorageServices
                          //                   .instance
                          //                   .read('token') ==
                          //               null) {
                          //             _showAuthBottomSheet();
                          //           }
                          //           if (await StorageServices
                          //                   .instance
                          //                   .read('token') !=
                          //               null) {
                          //             GoRouter.of(context)
                          //                 .push(AppRoutes.profile);
                          //           }
                          //         },
                          //         child: Transform.translate(
                          //           offset: Offset(0.0, -4.0),
                          //           child: const CircleAvatar(
                          //             foregroundColor:
                          //                 Colors.transparent,
                          //             backgroundColor:
                          //                 Colors.transparent,
                          //             radius: 14,
                          //             backgroundImage: AssetImage(
                          //               'assets/images/user.png',
                          //             ),
                          //           ),
                          //         ),
                          //       ),
                        ],
                      )
                    ],
                  ),
                ),
                SizedBox(height: 40),
                // Search field
                GestureDetector(
                  onTap: () async {
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
                SizedBox(height: 48),

                // Car image with background buildings
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
