import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_services_controller/crp_sevices_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/verify_corporate/verify_corporate_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';

import '../../../../common_widget/textformfield/read_only_textformfield.dart';
import '../../../../utility/constants/colors/app_colors.dart';
import '../../../core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart';
import '../../../core/services/storage_services.dart';
import '../../../utility/constants/fonts/common_fonts.dart';

class CprHomeScreen extends StatefulWidget {
  const CprHomeScreen({super.key});

  @override
  State<CprHomeScreen> createState() => _CprHomeScreenState();
}

class _CprHomeScreenState extends State<CprHomeScreen> {

  final params = {
    'CorpID' : StorageServices.instance.read('crpId'),
    'BranchID' : StorageServices.instance.read('branchId')
  };

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // runTypeController.fetchRunTypes(verifyCorporateController.cprID.value, crpGetBranchListController.selectedBranchId.value??'', context);
    runTypeController.fetchRunTypes(params, context);


    // Fetch branches and show bottom sheet when screen appears
    _fetchBranchesAndShowBottomSheet();
  }


  Future<void> _fetchBranchesAndShowBottomSheet() async {
    // Get corporate ID - use from verifyCorporateController or fallback to params
    final corpId = await StorageServices.instance.read('crpId');
    
    // Fetch branches
    await crpGetBranchListController.fetchBranches(corpId ?? '');
    
    // Show bottom sheet after a short delay to ensure screen is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showBranchSelectorBottomSheet();
          }
        });
      }
    });
  }

  Future<void> _showBranchSelectorBottomSheet() async {
    // Fetch branches if not already loaded
    if (crpGetBranchListController.branchNames.isEmpty) {
      final corpId = await StorageServices.instance.read('crpId');
      await crpGetBranchListController.fetchBranches(corpId ?? '');
    }
    
    final items = crpGetBranchListController.branchNames;
    final selected = crpGetBranchListController.selectedBranchName.value ?? '';

    if (items.isEmpty) {
      Get.snackbar("No Branches", "No branches found for this corporate ID",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              String searchQuery = '';
              List<String> filteredItems = items;

              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Container(
                          height: 5,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.mainButtonBg.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.location_city_rounded,
                                color: AppColors.mainButtonBg,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Select Location",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setModalState(() {
                                searchQuery = value;
                                filteredItems = items.where((item) {
                                  return item.toLowerCase().contains(value.toLowerCase());
                                }).toList();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Search location...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey.shade600,
                                size: 22,
                              ),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey.shade600,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          searchQuery = '';
                                          filteredItems = items;
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Results Count
                      if (searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "${filteredItems.length} ${filteredItems.length == 1 ? 'result' : 'results'} found",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Branch List
                      Flexible(
                        child: filteredItems.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No locations found",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Try searching with a different term",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final name = filteredItems[index];
                                  final isSelected = name == selected;

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        crpGetBranchListController.selectBranch(name);
                                        Navigator.pop(context);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.mainButtonBg.withOpacity(0.08)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          border: isSelected
                                              ? Border.all(
                                                  color: AppColors.mainButtonBg.withOpacity(0.3),
                                                  width: 1.5,
                                                )
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.mainButtonBg
                                                    : Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.location_on_rounded,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey.shade600,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? AppColors.mainButtonBg
                                                      : const Color(0xFF1A1A1A),
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.mainButtonBg,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  final CrpServicesController runTypeController = Get.put(CrpServicesController());
  final VerifyCorporateController verifyCorporateController = Get.put(VerifyCorporateController());
  final CrpBranchListController crpGetBranchListController =
  Get.put(CrpBranchListController());



  // getImageForService
  String getImageForService(int id) {
    switch (id) {
      case 1:
        return 'assets/images/rental.png';         // Local / Disposal
      case 2:
        return 'assets/images/airport.png';        // Airport
      case 3:
        return 'assets/images/outstation.png';     // One Way Outstation
      case 4:
        return 'assets/images/self_drive.png';     // Self Drive
      default:
        return 'assets/images/rental.png';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(
        children: [
          SizedBox(
            height: 300,
              child: TopBanner()),
          // services dynamic
          SizedBox(height: 20),
         // selected location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text('Selected Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),),
              ],
            ),
          ),
          SizedBox(height: 10,),
         Obx(()=> Material(
           color: Colors.transparent,
           child: InkWell(
             onTap: () async {
               await _showBranchSelectorBottomSheet();
             },
             borderRadius: BorderRadius.circular(8),
             child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0),
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.grey.shade300),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(
                       crpGetBranchListController.selectedBranchName.value??'Select Location',
                       style: TextStyle(
                         fontSize: 15,
                         color: Colors.black87,
                       ),
                     ),
                     Icon(
                       Icons.arrow_forward_ios,
                       size: 16,
                       color: Colors.grey.shade600,
                     ),
                   ],
                 ),
               ),
             ),
           ),
         )),
          SizedBox(height: 16,),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),),
              ],
            ),
          ),
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() {
              final list = runTypeController.runTypes.value?.runTypes ?? [];

              if (list.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Calculate crossAxisCount based on number of services
              // Each service should take equal width
              final crossAxisCount = list.length > 3 ? 3 : list.length;
              final fixedHeight = 120.0;
              final screenWidth = MediaQuery.of(context).size.width;
              final horizontalPadding = 24.0; // 12 on each side
              final crossAxisSpacing = 12.0;
              final availableWidth = screenWidth - horizontalPadding;
              final itemWidth = (availableWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
              final childAspectRatio = itemWidth / fixedHeight;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length > 3 ? 3 : list.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: crossAxisSpacing,
                ),
                itemBuilder: (context, index) {
                  final item = list[index];

                  return InkWell(
                    splashColor: Colors.transparent,
                    onTap: () {
                      GoRouter.of(context).push(AppRoutes.cprBookingEngine);
                    },
                    child: Container(
                      height: fixedHeight,
                      padding: const EdgeInsets.all(10),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 60,
                            child: Image.asset(
                              getImageForService(item.runTypeID ?? 0),
                              fit: BoxFit.contain,
                            ),
                          ),

                          Text(
                            item.run ?? "",
                            style: CommonFonts.blueText1,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          )

        ],
      )),
    );
  }
}

class TopBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  GoRouter.of(context).push(AppRoutes.cprSelectPickup);
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
                      GoRouter.of(context).push(AppRoutes.cprSelectPickup);
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
    );
  }
}
