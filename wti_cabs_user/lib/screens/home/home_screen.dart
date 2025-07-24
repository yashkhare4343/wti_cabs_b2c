import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/common_widget/textformfield/read_only_textformfield.dart';

import '../../core/route_management/app_routes.dart';
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
    _setStatusBarColor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _showBottomSheet();
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

        final fullAddress = components
            .where((s) => s.trim().isNotEmpty)
            .join(', ');

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Reapply status bar color when navigating back
        _setStatusBarColor();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.homebg,
        body: SafeArea(
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
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // const CircleAvatar(
                                    //   radius: 24,
                                    //   backgroundImage: AssetImage('assets/images/user.png'),
                                    // ),
                                    Transform.translate(
                                      offset: Offset(0.0, 4.0),
                                      child: Container(
                                        width: 28, // same as 24dp with padding
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(0, 44, 192, 0.1), // deep blue
                                          borderRadius: BorderRadius.circular(4), // rounded square
                                        ),
                                        child: const Icon(
                                          Icons.density_medium_outlined,
                                          color: Color.fromRGBO(0, 17, 73, 1),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                           Text(
                                            "Good Morning! Yash",
                                            style: CommonFonts.HomeTextBold,
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                width: MediaQuery.of(context).size.width * 0.45,
                                                child: Text(
                                                  address,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: CommonFonts.greyTextMedium,
                                                ),
                                              ),
                                              // const SizedBox(width:),
                                              const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: AppColors.greyText6,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Transform.translate(
                                      offset: Offset(0.0, -4.0),
                                      child: Image.asset('assets/images/wallet.png', height: 31, width: 28,)),
                                  SizedBox(width: 12,),
                                  Transform.translate(
                                    offset: Offset(0.0, -4.0),
                                    child: const CircleAvatar(
                                      radius: 14,
                                      backgroundImage: AssetImage('assets/images/user.png'),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            GoRouter.of(context).push(AppRoutes.bookingRide);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ReadOnlyTextFormField(
                              controller: TextEditingController(text: 'Where to?'),
                              icon: Icons.search,
                              prefixText: '',
                              onTap: () {
                                GoRouter.of(context).push(AppRoutes.bookingRide);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFC6CD00), Color(0xFF00DC3E)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12), // Only top corners
                                        bottom: Radius.circular(12), // Only top corners
                                      ),
                                    ),
                                    child: Text('Popular', style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white
                                    ),),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              SizedBox(height: 20,),
              // why wti carousel
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Why Wise Travel India', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),),
                  ],
                ),
              ),
              SizedBox(height: 12,),
              Padding(
                padding: EdgeInsets.only(left: 12),
                  child: CustomCarousel())
            ],
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
        'subtitle': 'Kick off your journey with 20% off your first cab booking.',
      },
      {
        'image': 'assets/images/sd_availbility.png',
        'title': 'Self Drive Availibility',
        'subtitle': 'Self Drive from the same platform',
      },
      {
        'image': 'assets/images/part_payment.png',
        'title': 'Part Payment',
        'subtitle': 'Kick off your journey with 20% off your first cab booking.',
      },
    ];

    final List<Widget> items = data.map((item) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 96,
            width: MediaQuery.of(context).size.width * 0.55,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(8), // ✅ Only top corners
              ),              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Opacity(
              opacity: 0.90,
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Container(
            height: 26,
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            color: Colors.white,
            width: MediaQuery.of(context).size.width * 0.54,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            // decoration: BoxDecoration(
            //   borderRadius: BorderRadius.vertical(
            //     bottom: Radius.circular(8), // ✅ Only top corners
            //   ),
            // ),
            child: Text(
              item['subtitle']!,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF4F4F4F)),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.54,
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
        height: 160,
        viewportFraction: 0.44,
        enableInfiniteScroll: false,
        padEnds: false,
        enlargeCenterPage: false,
      ),
      items: items,
    );
  }
}