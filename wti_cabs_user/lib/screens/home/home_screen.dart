import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/common_widget/textformfield/read_only_textformfield.dart';

import '../../common_widget/drawer/custom_drawer.dart';
import '../../core/route_management/app_routes.dart';
import '../../core/services/trip_history_services.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String address = '';

  @override
  void initState() {
    super.initState();
    // Register as WidgetsBindingObserver to listen for lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // Fetch location and show bottom sheet
    fetchCurrentLocationAndAddress();
    _loadRecentTrips();
    _setStatusBarColor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _showBottomSheet();
    });
  }

  List<String> _topRecentTrips = [];

  Future<void> _loadRecentTrips() async {
    final trips = await TripHistoryService.getTop2Trips();
    setState(() {
      _topRecentTrips = trips;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reapply status bar color when dependencies change (e.g., navigation)
    _setStatusBarColor();
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

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final components = <String>[
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
      } else {
        address = 'Address not found';
      }

      print('Current location address: $address');
    } catch (e) {
      print('Error fetching location/address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location/address: $e')),
      );
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

  @override
  Widget build(BuildContext context) {
    _loadRecentTrips();
    final double drawerWidth = MediaQuery.of(context).size.width * 0.8;

    return WillPopScope(
      onWillPop: () async {
        // Reapply status bar color when navigating back
        _setStatusBarColor();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.homebg,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        onTap: () {
                                          showGeneralDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            barrierLabel: "Drawer",
                                            barrierColor: Colors
                                                .black54, // transparent black background
                                            transitionDuration: const Duration(
                                                milliseconds: 300),
                                            pageBuilder: (_, __, ___) =>
                                                const CustomDrawerSheet(),
                                            transitionBuilder:
                                                (_, anim, __, child) {
                                              return SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(-1,
                                                      0), // slide in from left
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
                                            width:
                                                28, // same as 24dp with padding
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Color.fromRGBO(
                                                  0, 44, 192, 0.1), // deep blue
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      4), // rounded square
                                            ),
                                            child: const Icon(
                                              Icons.density_medium_outlined,
                                              color:
                                                  Color.fromRGBO(0, 17, 73, 1),
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
                                    Transform.translate(
                                        offset: Offset(0.0, -4.0),
                                        child: Image.asset(
                                          'assets/images/wallet.png',
                                          height: 31,
                                          width: 28,
                                        )),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      onTap: (){
                                        GoRouter.of(context).push(AppRoutes.profile);
                                      },
                                      child: Transform.translate(
                                        offset: Offset(0.0, -4.0),
                                        child: const CircleAvatar(
                                          radius: 14,
                                          backgroundImage: AssetImage(
                                              'assets/images/user.png'),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              GoRouter.of(context).push(AppRoutes.bookingRide);
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
                                  GoRouter.of(context)
                                      .push(AppRoutes.bookingRide);
                                },
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
                          Text(
                            'Popular Destinations',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                          SizedBox(
                            height: 16,
                          ),
                        ],
                      ),
                    ),
                    // Container(
                    //     padding: EdgeInsets.symmetric(horizontal: 8),
                    //     height: 170,
                    //     child: BorderedListView()),

                    SizedBox(
                      height: 12,
                    ),
                    ..._topRecentTrips.map((trip) {
                      final parts = trip.split(','); // e.g. ["jaipur", "rajasthan", "india"]
                      final title = parts.first.trim(); // jaipur
                      final subtitle = parts.length >= 2 ? parts[1].trim() : ''; // rajasthan

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: const Color.fromRGBO(44, 44, 111, 0.15),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
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
                            title, // main city
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            subtitle, // state or 2nd part
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
                    }),

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

                    // Positioned(
                    //   top: 200,
                    //   left: 0,
                    //   right: 0,
                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(horizontal: 16),
                    //     child: Row(
                    //       children: [
                    //         Expanded(
                    //           child: Container(
                    //             height: 80,
                    //             margin: const EdgeInsets.symmetric(horizontal: 4),
                    //             decoration: BoxDecoration(
                    //               color: Colors.white,
                    //               borderRadius: BorderRadius.circular(12),
                    //               boxShadow: const [
                    //                 BoxShadow(
                    //                   color: Color(0x1F192653),
                    //                   offset: Offset(0, 3),
                    //                   blurRadius: 12,
                    //                 ),
                    //               ],
                    //             ),
                    //             child: Padding(
                    //               padding: const EdgeInsets.all(8.0),
                    //               child: Column(
                    //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                 children: [
                    //                   Expanded(
                    //                     child: Image.asset(
                    //                       'assets/images/airport.png',
                    //                       fit: BoxFit.contain,
                    //                     ),
                    //                   ),
                    //                    Text(
                    //                     'Airport',
                    //                     style: CommonFonts.blueText1,
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //         Expanded(
                    //           child: Container(
                    //             height: 80,
                    //             margin: const EdgeInsets.symmetric(horizontal: 4),
                    //             decoration: BoxDecoration(
                    //               color: Colors.white,
                    //               borderRadius: BorderRadius.circular(12),
                    //               boxShadow: const [
                    //                 BoxShadow(
                    //                   color: Color(0x1F192653),
                    //                   offset: Offset(0, 3),
                    //                   blurRadius: 12,
                    //                 ),
                    //               ],
                    //             ),
                    //             child: Padding(
                    //               padding: const EdgeInsets.all(8.0),
                    //               child: Column(
                    //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                 children: [
                    //                   Expanded(
                    //                     child: Image.asset(
                    //                       'assets/images/outstation.png',
                    //                       fit: BoxFit.contain,
                    //                     ),
                    //                   ),
                    //                    Text(
                    //                     'Outstation',
                    //                     style: CommonFonts.blueText1,
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //         Expanded(
                    //           child: Container(
                    //             height: 80,
                    //             margin: const EdgeInsets.symmetric(horizontal: 4),
                    //             decoration: BoxDecoration(
                    //               color: Colors.white,
                    //               borderRadius: BorderRadius.circular(12),
                    //               boxShadow: const [
                    //                 BoxShadow(
                    //                   color: Color(0x1F192653),
                    //                   offset: Offset(0, 3),
                    //                   blurRadius: 12,
                    //                 ),
                    //               ],
                    //             ),
                    //             child: Padding(
                    //               padding: const EdgeInsets.all(8.0),
                    //               child: Column(
                    //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                 children: [
                    //                   Expanded(
                    //                     child: Image.asset(
                    //                       'assets/images/rental.png',
                    //                       fit: BoxFit.contain,
                    //                     ),
                    //                   ),
                    //                    Text(
                    //                     'Self Drive',
                    //                     style: CommonFonts.blueText1,
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //         Expanded(
                    //           child: Container(
                    //             height: 80,
                    //             margin: const EdgeInsets.symmetric(horizontal: 4),
                    //             decoration: BoxDecoration(
                    //               color: Colors.white,
                    //               borderRadius: BorderRadius.circular(12),
                    //               boxShadow: const [
                    //                 BoxShadow(
                    //                   color: Color(0x1F192653),
                    //                   offset: Offset(0, 3),
                    //                   blurRadius: 12,
                    //                 ),
                    //               ],
                    //             ),
                    //             child: Padding(
                    //               padding: const EdgeInsets.all(8.0),
                    //               child: Column(
                    //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                 children: [
                    //                   Expanded(
                    //                     child: Image.asset(
                    //                       'assets/images/self_drive.png',
                    //                       fit: BoxFit.contain,
                    //                     ),
                    //                   ),
                    //                   Text(
                    //                     'City Ride',
                    //                     style: CommonFonts.blueText1,
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                // border: Border.all(
                                //   color: Color(0xFFD9D9D9),
                                //   width: 1,
                                // ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/airport.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Text(
                                      'Airport',
                                      style: CommonFonts.blueText1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Image.asset(
                                            'assets/images/outstation.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        Text(
                                          'Outstation',
                                          style: CommonFonts.blueText1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: 0.9,
                                  child: Transform.translate(
                                    offset: Offset(14.0, -12.0),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFC6CD00),
                                            Color(0xFF00DC3E)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(
                                              12), // Only top corners
                                          bottom: Radius.circular(
                                              12), // Only top corners
                                        ),
                                      ),
                                      child: Text(
                                        'Popular',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 80,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/rental.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Text(
                                      'Rental',
                                      style: CommonFonts.blueText1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 80,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/self_drive.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Text(
                                      'Self Drive',
                                      style: CommonFonts.blueText1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 124,
                  child: CarouselSlider.builder(
                    itemCount: imageList.length,
                    options: CarouselOptions(
                      height: 124, // Fixed height for carousel
                      viewportFraction: 1.0,
                      enlargeCenterPage: false,
                      autoPlay: true,
                    ),
                    itemBuilder: (context, index, realIdx) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        width: double.infinity,
                        child: Image.asset(
                          imageList[index],
                          fit: BoxFit.fill,
                        ),
                      );
                    },
                  ),
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
                  height: 12,
                ),
                Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: CustomCarousel()),
                SizedBox(
                  height: 20,
                ),
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
                CustomTabBar()
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomCarousel extends StatelessWidget {
  const CustomCarousel({super.key});

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
                  item['image']!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
            color: Colors.white,
            width: MediaQuery.of(context).size.width * 0.50,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              item['title']!,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Container(
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            color: Colors.white,
            width: MediaQuery.of(context).size.width * 0.56,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            // decoration: BoxDecoration(
            //   borderRadius: BorderRadius.vertical(
            //     bottom: Radius.circular(8), // ✅ Only top corners
            //   ),
            // ),
            child: Text(
              item['subtitle']!,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF4F4F4F)),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
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
    }).toList();

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
                    selectedIndex = index;
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
    _loadRecentTrips();
  }

  Future<void> _loadRecentTrips() async {
    final trips = await TripHistoryService.getTop2Trips();
    setState(() {
      _topRecentTrips = trips;
    });
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
            contentPadding: EdgeInsets.only(left: 16), // removes horizontal padding
            dense: true,                     // makes it more compact
            minVerticalPadding: 0,           // removes vertical padding
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
