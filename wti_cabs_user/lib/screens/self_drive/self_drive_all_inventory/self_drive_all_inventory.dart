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
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/controller/self_drive/self_drive_booking_details/self_drive_booking_details_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/inventory_list_screen/inventory_list.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_home/self_drive_home_screen.dart';
import '../../../common_widget/loader/shimmer/shimmer.dart';
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

// ✅ UI Updated version, signature untouched
class _SelfDriveAllInventoryState extends State<SelfDriveAllInventory> {
  final SearchInventorySdController searchInventorySdController =
  Get.put(SearchInventorySdController());
  final ScrollController _scrollController = ScrollController();
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
  Get.put(FetchSdBookingDetailsController());
  int _currentIndex = 0;
  bool _isLoadingMore = false;
  int _page = 1;
  final CurrencyController currencyController = Get.put(CurrencyController());

  num getFakePriceWithPercent(num baseFare, num percent) =>
      (baseFare * 100) / (100 - percent);

  @override
  void initState() {
    super.initState();
    // _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Container(
          width: MediaQuery.of(context).size.width, // full width
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filter by Vehicle Class",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002CC0))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ["All", "Economy", "SUV"].map((cls) {
                  final selected =
                      searchInventorySdController.selectedVehicleClass.value == cls;
                  return ChoiceChip(
                    label: Text(cls),
                    selected: selected,
                    onSelected: (_) {
                      searchInventorySdController.setVehicleClass(cls);
                      Navigator.pop(context); // close sheet
                    },
                    selectedColor: const Color(0xFF002CC0),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Container(
          width: MediaQuery.of(context).size.width, // full width
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Sort by Price",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002CC0))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ["None", "LowToHigh", "HighToLow"].map((order) {
                  final selected =
                      searchInventorySdController.selectedPriceOrder.value ==
                          order;
                  return ChoiceChip(
                    label: Text(order == "None"
                        ? "Default"
                        : order == "LowToHigh"
                        ? "Low → High"
                        : "High → Low"),
                    selected: selected,
                    onSelected: (_) {
                      searchInventorySdController.setPriceOrder(order);
                      Navigator.pop(context); // close sheet
                    },
                    selectedColor: const Color(0xFF002CC0),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.homebg,
      statusBarIconBrightness: Brightness.dark,
    ));

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        GoRouter.of(context).push(AppRoutes.selfDriveBottomSheet);
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
                const SizedBox(height: 8),
                Expanded(
                  child: Obx(() {
                    final rides =
                        searchInventorySdController.topRatedRidesResponse.value?.result ??
                            [];

                    if (rides.isEmpty && !_isLoadingMore) {
                      return const Center(
                          child: Text("No rides available",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54)));
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ListView.builder(
                        key: const PageStorageKey(
                            "SelfDriveAllInventoryList"),
                        controller: _scrollController,
                        itemCount: rides.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == rides.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFFE8262B))),
                            );
                          }

                          final vehicle = rides[index].vehicleId;
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Carousel
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: Stack(
                                    children: [
                                      CarouselSlider(
                                        items: rides[index]
                                            .vehicleId
                                            ?.images
                                            ?.map((img) {
                                          return CachedNetworkImage(
                                            imageUrl: img,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 280,
                                            placeholder: (context, url) =>
                                                Shimmer.fromColors(
                                                  baseColor: Colors.grey.shade300,
                                                  highlightColor:
                                                  Colors.grey.shade100,
                                                  child: Container(
                                                    width: double.infinity,
                                                    height: 280,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                            const Icon(Icons.error,
                                                size: 50),
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
                                      // Carousel indicator
                                      Positioned(
                                        bottom: 8,
                                        left: 0,
                                        right: 0,
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
                                            return AnimatedContainer(
                                              duration:
                                              const Duration(milliseconds: 300),
                                              margin: const EdgeInsets.symmetric(
                                                  horizontal: 3),
                                              width: isActive ? 24 : 16,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? Colors.white
                                                    : Colors.grey.shade400,
                                                borderRadius:
                                                BorderRadius.circular(2),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      // Promotion tag
                                      if (vehicle?.vehiclePromotionTag != null)
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: Image.asset(
                                            vehicle!.vehiclePromotionTag!
                                                .toLowerCase() ==
                                                'popular'
                                                ? 'assets/images/popular.png'
                                                : 'assets/images/trending.png',
                                            width: 106,
                                            height: 28,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Car info
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 16, 16, 8),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle?.modelName ?? "",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 20,
                                            color: Color(0xFF000000)),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            "${vehicle?.vehicleRating ?? "-"}",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF373737)),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.star,
                                              color: Color(0xFFFEC200),
                                              size: 16),
                                          const SizedBox(width: 6),
                                          const Text(
                                            "450 Reviews",
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF373737)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 6,
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
                                const Divider(color: Color(0xFFDCDCDC)),
                                // Price + Button
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          FutureBuilder<double>(
                                            future: currencyController.convertPrice(
                                              getFakePriceWithPercent(
                                                  searchInventorySdController
                                                      .selectedIndex
                                                      .value ==
                                                      0
                                                      ? (rides[index]
                                                      .tariffDaily
                                                      ?.base ??
                                                      0)
                                                      : (rides[index]
                                                      .tariffMonthly
                                                      ?.base ??
                                                      0),
                                                  20)
                                                  .toDouble(),
                                            ),
                                            builder: (context, snapshot) {
                                              final convertedValue =
                                                  snapshot.data ??
                                                      getFakePriceWithPercent(
                                                          searchInventorySdController
                                                              .selectedIndex
                                                              .value ==
                                                              0
                                                              ? (rides[index]
                                                              .tariffDaily
                                                              ?.base ??
                                                              0)
                                                              : (rides[index]
                                                              .tariffMonthly
                                                              ?.base ??
                                                              0),
                                                          20)
                                                          .toDouble();
                                              return Text(
                                                '${currencyController.selectedCurrency.value.symbol}${convertedValue.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 4),
                                          FutureBuilder<double>(
                                            future: currencyController.convertPrice(
                                              (searchInventorySdController
                                                  .selectedIndex
                                                  .value ==
                                                  0
                                                  ? (rides[index].tariffDaily
                                                  ?.base ??
                                                  0)
                                                  : (rides[index].tariffMonthly
                                                  ?.base ??
                                                  0))
                                                  .toDouble(),
                                            ),
                                            builder: (context, snapshot) {
                                              final convertedPrice =
                                                  snapshot.data ?? 0;
                                              return Text(
                                                searchInventorySdController
                                                    .selectedIndex
                                                    .value ==
                                                    0
                                                    ? "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}/day"
                                                    : "${currencyController.selectedCurrency.value.symbol} ${convertedPrice.toStringAsFixed(2)}/Month",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  color: Color(0xFF131313),
                                                ),
                                              );
                                            },
                                          )
                                        ],
                                      ),
                                      const Spacer(),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          const Color(0xFFE8262B),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 28, vertical: 12),
                                        ),
                                        onPressed: () async {
                                          // 1️⃣ Show the shimmer
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) => const Center(
                                                child: FullPageShimmer()),
                                          );

                                          // 2️⃣ Fetch data
                                          await fetchSdBookingDetailsController
                                              .fetchBookingDetails(vehicle?.id ?? "", false);

                                          // 3️⃣ Close shimmer
                                          if (context.mounted) {
                                            Navigator.of(context).pop(); // remove shimmer

                                            // 4️⃣ Navigate to final page
                                            Navigator.of(context).push(
                                              Platform.isIOS
                                                  ? CupertinoPageRoute(
                                                builder: (_) => SelfDriveFinalPageS1(
                                                  vehicleId: vehicle?.id ?? "",
                                                  isHomePage: false,
                                                ),
                                              )
                                                  : MaterialPageRoute(
                                                builder: (_) => SelfDriveFinalPageS1(
                                                  vehicleId: vehicle?.id ?? "",
                                                  isHomePage: false,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text(
                                          "Book Now",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white),
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
        bottomNavigationBar: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showFilterSheet(context),
                  icon: const Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: Colors.black87,
                  ),
                  label: const Text(
                    "Filter",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showSortSheet(context),
                  icon: const Icon(
                    Icons.sort,
                    size: 16,
                    color: Colors.black87,
                  ),
                  label: const Text(
                    "Sort",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                              GoRouter.of(context).push(AppRoutes.selfDriveBottomSheet);
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
