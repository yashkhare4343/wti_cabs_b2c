import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_home/self_drive_home_screen.dart';
import '../../../core/controller/self_drive/search_inventory_sd_controller/search_inventory_sd_controller.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../self_drive_final_page_st1/self_drive_final_page_s1.dart';

class SelfDriveAllInventory extends StatefulWidget {
  final String? city;
  final String? fromDate;
  final String? fromTime;
  final String? toDate;
  final String? toTime;
  final String? selectedMonth;
  const SelfDriveAllInventory(
      {super.key,
      this.city,
      this.fromDate,
      this.fromTime,
      this.toDate,
      this.toTime,
      this.selectedMonth});

  @override
  State<SelfDriveAllInventory> createState() => _SelfDriveAllInventoryState();
}

class _SelfDriveAllInventoryState extends State<SelfDriveAllInventory> {
  final SearchInventorySdController searchInventorySdController =
      Get.put(SearchInventorySdController());
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;
  bool _isLoadingMore = false;
  int _page = 1; // Track the current page for pagination

  @override
  void initState() {
    super.initState();
    // searchInventorySdController.fetchAllInventory(context: context);
    // _scrollController.addListener(_onScroll);
  }

  // void fetchInventoryData({bool isLoadMore = false}) async {
  //   if (_isLoadingMore) return; // Prevent multiple simultaneous API calls
  //   setState(() {
  //     _isLoadingMore = true;
  //   });
  //
  //   // await searchInventorySdController.fetchAllInventory(
  //   //   context: context,
  //   //   // page: isLoadMore ? _page + 1 : _page, // Enable this when backend supports pagination
  //   // );
  //
  //   setState(() {
  //     if (isLoadMore) _page++;
  //     _isLoadingMore = false;
  //   });
  // }
  //
  // void _onScroll() {
  //   if (_isLoadingMore) return; // Already fetching, ignore
  //
  //   const threshold = 200; // px from bottom before triggering load more
  //   if (_scrollController.position.pixels >=
  //       _scrollController.position.maxScrollExtent - threshold) {
  //     fetchInventoryData(isLoadMore: true);
  //   }
  // }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.homebg, // Status bar color set to white
      statusBarIconBrightness: Brightness.dark, // Dark icons for visibility
    ));
    return PopScope(
      canPop: true, // 🚀 Stops the default "pop and close app"
      onPopInvoked: (didPop) {
        // This will be called for hardware back and gesture
        GoRouter.of(context).push(AppRoutes.selfDriveHome);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE9E9ED),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: [
                ModifyRental(
                  city: widget.city,
                  fromDate: widget.fromDate,
                  fromTime: widget.fromTime,
                  toDate: widget.toDate,
                  toTime: widget.toTime,
                  selectedMonth: widget.selectedMonth,
                ),
                SizedBox(
                  height: 8,
                ),
                Expanded(
                  child: Obx(() {
                    final rides = searchInventorySdController
                            .topRatedRidesResponse.value?.result ??
                        [];

                    if (rides.isEmpty && !_isLoadingMore) {
                      return const Center(child: Text("No rides available"));
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ListView.builder(
                        key: const PageStorageKey(
                            "SelfDriveAllInventoryList"), // 👈 preserves scroll position
                        controller:
                            _scrollController, // Attach ScrollController
                        itemCount: rides.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == rides.length) {
                            // Show loading indicator at the end of the list
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final vehicle = rides[index].vehicleId;
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0.3,
                            margin: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Carousel
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: Stack(
                                    children: [
                                      CarouselSlider(
                                        items: rides[index].vehicleId?.images?.map((img) {
                                          return CachedNetworkImage(
                                            imageUrl: img,
                                            fit: BoxFit.fill,
                                            useOldImageOnUrlChange: true,
                                            memCacheHeight: 300,
                                            memCacheWidth: 550,
                                            placeholder: (context, url) => Shimmer.fromColors(
                                              baseColor: Colors.grey.shade300,
                                              highlightColor: Colors.grey.shade100,
                                              child: Container(
                                                width: double.infinity,
                                                height: 280, // same as CarouselSlider height
                                                color: Colors.grey,
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => const Icon(Icons.error, size: 50),
                                          );
                                        }).toList(),
                                        options: CarouselOptions(
                                          height: 280,
                                          viewportFraction: 1.0,
                                          enableInfiniteScroll: true,
                                          autoPlay: false,
                                          onPageChanged: (index, reason) {
                                            setState(() {
                                              _currentIndex = index;
                                            });
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: SizedBox(
                                          height: 20,
                                          child: Transform.translate(
                                            offset: const Offset(0.0, 0.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: rides[index]
                                                  .vehicleId!
                                                  .images!
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                final isActive =
                                                    _currentIndex == entry.key;
                                                return Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(horizontal: 2),
                                                  width: 40,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? Colors.white
                                                        : Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (rides[index]
                                              .vehicleId
                                              ?.vehiclePromotionTag !=
                                          null)
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.25),
                                                  blurRadius: 6,
                                                  offset: Offset(2, 4),
                                                ),
                                              ],
                                            ),
                                            child: Image.asset(
                                              rides[index]
                                                          .vehicleId!
                                                          .vehiclePromotionTag!
                                                          .toLowerCase() ==
                                                      'popular'
                                                  ? 'assets/images/popular.png'
                                                  : 'assets/images/trending.png',
                                              width: 106,
                                              height: 28,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Car Info
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 16.0,
                                      left: 16.0,
                                      right: 16.0,
                                      bottom: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle?.modelName ?? "",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20,
                                          color: Color(0xFF000000),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            "${vehicle?.vehicleRating ?? "-"}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF373737),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.star,
                                              color: Color(0xFFFEC200),
                                              size: 16),
                                          const SizedBox(width: 4),
                                          const Text(
                                            "450 Reviews",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF373737),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 12,
                                        children: [
                                          _InfoIcon(
                                              icon: Icons
                                                  .airline_seat_recline_extra,
                                              text:
                                                  "${vehicle?.specs?.seats ?? "--"} Seat"),
                                          _InfoIcon(
                                              icon: Icons.work,
                                              text:
                                                  "${vehicle?.specs?.luggageCapacity ?? "--"} luggage bag"),
                                          _InfoIcon(
                                              icon: Icons.speed,
                                              text:
                                                  "${vehicle?.specs?.mileageLimit ?? "--"} km/rental"),
                                          _InfoIcon(
                                              icon: Icons.settings,
                                              text:
                                                  "${vehicle?.specs?.transmission ?? "--"}"),
                                          const _InfoIcon(
                                              icon: Icons.calendar_today,
                                              text: "Min. 2 days rental"),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Divider(color: Color(0xFFDCDCDC)),
                                ),

                                // Price + Button
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "AED ${rides[index].tariffMonthly?.base ?? "--"}/month",
                                            style: const TextStyle(
                                              color: Color(0xFF2F2F2F),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "AED ${rides[index].tariffDaily?.base ?? "--"}/day",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20,
                                              color: Color(0xFF131313),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFE8262B),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 10),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            Platform.isIOS
                                                ? CupertinoPageRoute(
                                              builder: (_) =>  SelfDriveFinalPageS1(vehicleId: vehicle?.id??"", isHomePage: false),
                                            )
                                                : MaterialPageRoute(
                                              builder: (_) =>  SelfDriveFinalPageS1(vehicleId: vehicle?.id??"", isHomePage: false),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          "Book Now",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoIcon({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF979797)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}

class ModifyRental extends StatefulWidget {
  final String? city;
  final String? fromDate;
  final String? fromTime;
  final String? toDate;
  final String? toTime;
  final String? selectedMonth;

  const ModifyRental(
      {super.key,
      this.city,
      this.fromDate,
      this.fromTime,
      this.toDate,
      this.toTime,
      this.selectedMonth});
  @override
  State<ModifyRental> createState() => _ModifyRentalState();
}

class _ModifyRentalState extends State<ModifyRental> {
  final SearchInventorySdController searchInventorySdController =
      Get.put(SearchInventorySdController());

  void showTopPopup(
      BuildContext context,
      Widget child,
      String? city,
      String? fromDate,
      String? fromTime,
      String? toDate,
      String? toTime,
      String? selectedMonth) {
    showGeneralDialog(
      barrierLabel: "TopPopup",
      barrierDismissible: true,
      barrierColor: Colors.black38,
      transitionDuration: Duration(milliseconds: 400),
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: IntrinsicHeight(
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.13),
                          Row(
                            children: [
                              Obx(() {
                                return Text(
                                  searchInventorySdController
                                              .selectedIndex.value ==
                                          0
                                      ? 'Daily/Weekly Rental'
                                      : 'Monthly Rental',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF002CC0)),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime parsedDate = DateFormat("d/M").parse(widget.fromDate ?? '');
    String formattedDate = DateFormat("d MMM").format(parsedDate);
    DateTime parsedToDate = DateFormat("d/M").parse(widget.toDate ?? '');
    String formattedToDate = DateFormat("d MMM").format(parsedToDate);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, // background color
        borderRadius: BorderRadius.circular(12), // ✅ 12px border radius
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                  child: const BackButton()),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.city ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF000000)),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          searchInventorySdController.selectedIndex.value == 0
                              ? '${formattedDate} ${widget.fromTime} - ${formattedToDate} ${widget.toTime}'
                              : '${formattedDate} ${widget.fromTime} - ${widget.selectedMonth} Month',
                          style: TextStyle(
                              color: Color(0xFF595959),
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              searchInventorySdController.selectedIndex.value ==
                                      0
                                  ? Text(
                                      'Daily Rental',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF002CC0),
                                      ),
                                    )
                                  : Text(
                                      'Monthly Rental',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF002CC0),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              InkWell(
                  splashColor: Colors.transparent,
                  onTap: () {
                    showTopPopup(
                        context,
                        searchInventorySdController.selectedIndex.value == 0
                            ? DailyRentalSearchCard()
                            : MonthlyRentalSearchCard(),
                        widget.city,
                        widget.fromDate,
                        widget.fromTime,
                        widget.toDate,
                        widget.toTime,
                        widget.selectedMonth);
                  },
                  child: Icon(Icons.edit, size: 20, color: Color(0xFF7A7A7A))),
            ],
          ),
        ],
      ),
    );
  }
}
