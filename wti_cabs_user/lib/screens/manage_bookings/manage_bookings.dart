import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/common_widget/buttons/outline_button.dart';
import 'package:wti_cabs_user/core/controller/manage_booking/upcoming_booking_controller.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

import '../../common_widget/loader/popup_loader.dart';
import '../../core/controller/download_receipt/download_receipt_controller.dart';
import '../../core/services/storage_services.dart';

class ManageBookings extends StatefulWidget {
  @override
  _ManageBookingsState createState() => _ManageBookingsState();
}

class _ManageBookingsState extends State<ManageBookings> with SingleTickerProviderStateMixin {
  final UpcomingBookingController upcomingBookingController =
  Get.put(UpcomingBookingController());
  String convertUtcToLocal(String utcTimeString, String timezoneString) {
    // Parse UTC time
    DateTime utcTime = DateTime.parse(utcTimeString);

    // Get the location based on timezone string like "Asia/Kolkata"
    final location = tz.getLocation(timezoneString);

    // Convert UTC to local time in given timezone
    final localTime = tz.TZDateTime.from(utcTime, location);

    // Format the local time as "28 July, 2025"
    final formatted = DateFormat("d MMMM, yyyy, hh:mm a").format(localTime);

    return formatted;
  }

  int selectedDriveType = 0; // 0: Chauffeur's, 1: Self Drive
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    upcomingBookingController.fetchUpcomingBookingsData();
  }

  @override
  Widget build(BuildContext context) {
    final driveTypes = ["Chauffeur's Drive", "Self Drive"];
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Bookings",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.scaffoldBgPrimary1,
        leading: Icon(
          Icons.arrow_back,
          color: Colors.black,
          size: 20,
        ),
      ),
      backgroundColor: AppColors.scaffoldBgPrimary1,
      body: Column(
        children: [
          SizedBox(height: 12),
          // Drive Type Toggle
          Container(
            // height: 46,
            width: MediaQuery.of(context).size.width * 0.8,
            // padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: List.generate(2, (index) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedDriveType = index),
                      child: Container(
                        padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedDriveType == index
                              ? Color(0xFF002CC0)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          driveTypes[index],
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedDriveType == index
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TabBar(
              controller: _tabController,
              labelColor: Color(0xFF002CC0),
              unselectedLabelColor: Color(0xFF494949),
              indicatorColor: Color(0xFF002CC0),
              labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF002CC0)),
              tabs: [
                Tab(
                  text: "Upcoming",
                ),
                Tab(text: "Completed"),
                Tab(text: "Cancelled"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Upcoming
                BookingList(),
                // Completed (empty for now)
                CompletedBookingList(),
                // Cancelled (empty for now)
                CanceledBookingList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use a ListView.builder for dynamic data
    return BookingCard();
  }
}

class BookingCard extends StatefulWidget {
  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  final UpcomingBookingController upcomingBookingController =
  Get.put(UpcomingBookingController());
  final PdfDownloadController pdfCtrl = Get.put(PdfDownloadController());

  String? convertUtcToLocal(String? utcTimeString, String timezoneString) {
    if (utcTimeString == null || utcTimeString.isEmpty) return null;

    try {
      // Initialize timezones only once, ideally in main()
      tz.initializeTimeZones();

      final utcTime = DateTime.parse(utcTimeString); // This was throwing
      final location = tz.getLocation(timezoneString);
      final localTime = tz.TZDateTime.from(utcTime, location);

      // Format: 25 July 2025, 05:34 PM
      return DateFormat("d MMMM yyyy, hh:mm a").format(localTime);
    } catch (e) {
      debugPrint("Date conversion error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (upcomingBookingController.upcomingBookingResponse.value?.result ==
          null) {
        return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: upcomingBookingController.confirmedBookings?.length,
            itemBuilder: (BuildContext context, int index) {
              return buildShimmer();
            });

        // ⏳ Show loading until data is ready
      }

      if (upcomingBookingController.confirmedBookings.isNotEmpty) {
        Center(
          child: Text('No Upcoming Booking Found'),
        );
      }

      return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: upcomingBookingController.confirmedBookings?.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              elevation: 0,
              color: Colors.white,
              margin: EdgeInsets.only(bottom: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(width: 1, color: Color(0xFFCECECE)),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
// Car Row
                    Row(
                      children: [
// Image
                        Image.network(
                          upcomingBookingController.confirmedBookings?[index]
                              .vehicleDetails?.imageUrl ??
                              '',
                          width: 84,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/inventory_car.png',
                              width: 84,
                              height: 64,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                        SizedBox(width: 12),

// Car Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                upcomingBookingController
                                    .confirmedBookings?[index]
                                    .vehicleDetails
                                    ?.type ??
                                    "",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF373737)),
                              ),
                              SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Booking ID: ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF929292),
                                          fontWeight: FontWeight.w500),
                                    ),
                                    TextSpan(
                                      text: upcomingBookingController
                                          .confirmedBookings?[index].id,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF222222),
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Booking Type: ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF929292),
                                          fontWeight: FontWeight.w500),
                                    ),
                                    TextSpan(
                                      text: upcomingBookingController
                                          .confirmedBookings?[index]
                                          .tripTypeDetails
                                          ?.tripType ??
                                          '',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF002CC0),
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Paid Amount: ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF929292),
                                          fontWeight: FontWeight.w500),
                                    ),
                                    TextSpan(
                                      text: upcomingBookingController
                                          .confirmedBookings?[index]
                                          .recieptId
                                          ?.fareDetails
                                          ?.amountPaid
                                          .toString() ??
                                          '',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF2B2B2B),
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 12),
                    Divider(
                      thickness: 1,
                      color: Color(0xFFF2F2F2),
                    ),
                    SizedBox(height: 12),
// Pickup and Drop
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    RotationTransition(
                                        turns: new AlwaysStoppedAnimation(
                                            40 / 360),
                                        child: Icon(Icons.navigation_outlined,
                                            size: 16,
                                            color: Color(0xFF002CC0))),
                                    SizedBox(width: 4),
                                    Text("Pickup",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF002CC0),
                                            fontWeight: FontWeight.w500)),
                                  ]),
                              SizedBox(height: 2),
                              Text(
                                  upcomingBookingController
                                      .confirmedBookings?[index]
                                      .source
                                      ?.address ??
                                      'Source not found',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF333333),
                                      fontWeight: FontWeight.w600)),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/calendar_clock.svg',
                                    height: 12,
                                    width: 12,
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                      convertUtcToLocal(
                                          upcomingBookingController
                                              .confirmedBookings?[index]
                                              .startTime
                                              .toString() ??
                                              '',
                                          upcomingBookingController
                                              .confirmedBookings?[index]
                                              .timezone ??
                                              '') ??
                                          'No Pickup Date Found',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF808080),
                                          fontWeight: FontWeight.w400)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 75,
                          color: Color(0xFFF2F2F2),
                          margin: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(Icons.pin_drop_outlined,
                                        size: 16, color: Color(0xFF002CC0)),
                                    SizedBox(width: 4),
                                    Text("Drop",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF002CC0),
                                            fontWeight: FontWeight.w500)),
                                  ]),
                              SizedBox(height: 2),
                              Text(
                                  upcomingBookingController
                                      .confirmedBookings?[index]
                                      .destination
                                      ?.address ??
                                      "Destination not found",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF333333),
                                      fontWeight: FontWeight.w600)),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/calendar_clock.svg',
                                    height: 12,
                                    width: 12,
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  (upcomingBookingController
                                      .confirmedBookings[index].tripTypeDetails?.basicTripType == 'LOCAL') ? SizedBox() :  Text(
                                      convertUtcToLocal(
                                          upcomingBookingController
                                              .confirmedBookings[index]
                                              .endTime
                                              .toString() ??
                                              '',
                                          upcomingBookingController
                                              .confirmedBookings[index]
                                              .timezone ??
                                              '') ??
                                          'No Drop Date Found',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF808080),
                                          fontWeight: FontWeight.w400)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        CommonOutlineButton(
                          text: 'Download Receipt',
                          onPressed: pdfCtrl.isDownloading.value
                              ? () {}
                              : () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const PopupLoader(
                                message: 'Downloading Receipt....',
                              ),
                            );
                            await pdfCtrl
                                .downloadReceiptPdf(
                                upcomingBookingController
                                    .completedBookings?[index].id ??
                                    '',
                                context)
                                .then((value) {
                              GoRouter.of(context).pop();
                            });
                          },
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
// Handle button press
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.mainButtonBg, // Background color
                            foregroundColor:
                            Colors.white, // Text (and ripple) color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                          child: Text(
                            'Manage Booking',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
    });
  }
}

Widget buildShimmer() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 96,
                height: 66,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(height: 12, width: 40, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 40, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 60, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 16, height: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget buildDownloadButton({
  required String title,
  required VoidCallback onPressed,
}) {
  return OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.mainButtonBg, // Text & icon color
      side: BorderSide(color: AppColors.mainButtonBg), // Border color
      minimumSize: Size(double.infinity, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    icon: Icon(
      Icons.download,
      color: AppColors.mainButtonBg,
    ),
    label: Text(title),
    onPressed: onPressed,
  );
}

// completed bookings
class CompletedBookingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use a ListView.builder for dynamic data
    return CompletedBookingCard();
  }
}

class CompletedBookingCard extends StatefulWidget {
  @override
  State<CompletedBookingCard> createState() => _CompletedBookingCardState();
}

class _CompletedBookingCardState extends State<CompletedBookingCard> {
  final UpcomingBookingController upcomingBookingController =
  Get.put(UpcomingBookingController());
  final PdfDownloadController pdfCtrl = Get.put(PdfDownloadController());

  String? convertUtcToLocal(String? utcTimeString, String timezoneString) {
    if (utcTimeString == null || utcTimeString.isEmpty) return null;

    try {
      // Initialize timezones only once, ideally in main()
      tz.initializeTimeZones();

      final utcTime = DateTime.parse(utcTimeString); // This was throwing
      final location = tz.getLocation(timezoneString);
      final localTime = tz.TZDateTime.from(utcTime, location);

      // Format: 25 July 2025, 05:34 PM
      return DateFormat("d MMMM yyyy, hh:mm a").format(localTime);
    } catch (e) {
      debugPrint("Date conversion error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (upcomingBookingController.isLoading.value) {
        return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: upcomingBookingController.completedBookings?.length,
            itemBuilder: (BuildContext context, int index) {
              return buildShimmer();
            });

        // ⏳ Show loading until data is ready
      }

      if (upcomingBookingController.completedBookings.isEmpty) {
        return Center(
          child: Text('No Completed Booking Found'),
        );
      }

      return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: upcomingBookingController.completedBookings?.length,
          itemBuilder: (BuildContext context, int index) {
            return Stack(
              children: [
                Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: EdgeInsets.only(bottom: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(width: 1, color: Color(0xFFCECECE)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Car Row
                        Row(
                          children: [
                            // Image
                            Image.network(
                              upcomingBookingController
                                  .completedBookings?[index]
                                  .vehicleDetails
                                  ?.imageUrl ??
                                  '',
                              width: 84,
                              height: 64,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/inventory_car.png',
                                  width: 84,
                                  height: 64,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                            SizedBox(width: 12),

                            // Car Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    upcomingBookingController
                                        .completedBookings?[index]
                                        .vehicleDetails
                                        ?.type ??
                                        "",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF373737)),
                                  ),
                                  SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Booking ID: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF929292),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        TextSpan(
                                          text: upcomingBookingController
                                              .completedBookings?[index].id,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF222222),
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Booking Type: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF929292),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        TextSpan(
                                          text: upcomingBookingController
                                              .completedBookings?[index]
                                              .tripTypeDetails
                                              ?.tripType ??
                                              '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF002CC0),
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Paid Amount: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF929292),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        TextSpan(
                                          text: upcomingBookingController
                                              .completedBookings?[index]
                                              .recieptId
                                              ?.fareDetails
                                              ?.amountPaid
                                              .toString() ??
                                              '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF2B2B2B),
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 12),
                        Divider(
                          thickness: 1,
                          color: Color(0xFFF2F2F2),
                        ),
                        SizedBox(height: 12),
                        // Pickup and Drop
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        RotationTransition(
                                            turns: new AlwaysStoppedAnimation(
                                                40 / 360),
                                            child: Icon(
                                                Icons.navigation_outlined,
                                                size: 16,
                                                color: Color(0xFF002CC0))),
                                        SizedBox(width: 4),
                                        Text("Pickup",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF002CC0),
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                  SizedBox(height: 2),
                                  Text(
                                      upcomingBookingController
                                          .completedBookings?[index]
                                          .source
                                          ?.address ??
                                          'Source not found',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/calendar_clock.svg',
                                        height: 12,
                                        width: 12,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                          convertUtcToLocal(
                                              upcomingBookingController
                                                  .completedBookings?[
                                              index]
                                                  .startTime
                                                  .toString() ??
                                                  '',
                                              upcomingBookingController
                                                  .completedBookings?[
                                              index]
                                                  .timezone ??
                                                  '') ??
                                              'No Pickup Date Found',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF808080),
                                              fontWeight: FontWeight.w400)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 75,
                              color: Color(0xFFF2F2F2),
                              margin: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        Icon(Icons.pin_drop_outlined,
                                            size: 16, color: Color(0xFF002CC0)),
                                        SizedBox(width: 4),
                                        Text("Drop",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF002CC0),
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                  SizedBox(height: 2),
                                  Text(
                                      upcomingBookingController
                                          .completedBookings?[index]
                                          .destination
                                          ?.address ??
                                          "Destination not found",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/calendar_clock.svg',
                                        height: 12,
                                        width: 12,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      (upcomingBookingController
                                          .completedBookings[index].tripTypeDetails?.basicTripType == 'LOCAL') ? SizedBox() :   Text(
                                          convertUtcToLocal(
                                              upcomingBookingController
                                                  .completedBookings[
                                              index]
                                                  .endTime
                                                  .toString() ??
                                                  '',
                                              upcomingBookingController
                                                  .completedBookings[
                                              index]
                                                  .timezone ??
                                                  '') ??
                                              'No Drop Date Found',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF808080),
                                              fontWeight: FontWeight.w400)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            upcomingBookingController
                                .confirmedBookings[index].countryName
                                ?.toLowerCase() ==
                                'india'
                                ? CommonOutlineButton(
                              text: 'Download Invoice',
                              onPressed: () async {
                                // TODO: downloadInvoicePdf()
                                showDialog(
                                  context: context,
                                  barrierDismissible:
                                  false,
                                  builder: (_) =>
                                  const PopupLoader(
                                    message:
                                    'Downloading Invoice...',
                                  ),
                                );
                                await pdfCtrl
                                    .downloadChauffeurEInvoice(
                                    context:
                                    context,
                                    objectId: await StorageServices
                                        .instance
                                        .read(
                                        'reservationId') ??
                                        '')
                                    .then((value) {
                                  GoRouter.of(context)
                                      .pop();
                                });
                              },
                            )
                                : SizedBox(),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: pdfCtrl.isDownloading.value
                                  ? () {}
                                  : () async {
                                await pdfCtrl
                                    .downloadReceiptPdf(
                                    upcomingBookingController
                                        .completedBookings?[index].id ??
                                        '',
                                    context)
                                    .then((value) {
                                  GoRouter.of(context).pop();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                AppColors.mainButtonBg, // Background color
                                foregroundColor:
                                Colors.white, // Text (and ripple) color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                              child: Text(
                                'Manage Booking',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ))
              ],
            );
          });
    });
  }
}

// canceled bookings
class CanceledBookingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use a ListView.builder for dynamic data
    return CanceledBookingCard();
  }
}

class CanceledBookingCard extends StatefulWidget {
  @override
  State<CanceledBookingCard> createState() => _CanceledBookingCardState();
}

class _CanceledBookingCardState extends State<CanceledBookingCard> {
  final UpcomingBookingController upcomingBookingController =
  Get.put(UpcomingBookingController());
  final PdfDownloadController pdfCtrl = Get.put(PdfDownloadController());

  String? convertUtcToLocal(String? utcTimeString, String timezoneString) {
    if (utcTimeString == null || utcTimeString.isEmpty) return null;

    try {
      // Initialize timezones only once, ideally in main()
      tz.initializeTimeZones();

      final utcTime = DateTime.parse(utcTimeString); // This was throwing
      final location = tz.getLocation(timezoneString);
      final localTime = tz.TZDateTime.from(utcTime, location);

      // Format: 25 July 2025, 05:34 PM
      return DateFormat("d MMMM yyyy, hh:mm a").format(localTime);
    } catch (e) {
      debugPrint("Date conversion error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (upcomingBookingController.isLoading.value) {
        return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: upcomingBookingController.cancelledBookings?.length,
            itemBuilder: (BuildContext context, int index) {
              return buildShimmer();
            });

        // ⏳ Show loading until data is ready
      }

      if (upcomingBookingController.cancelledBookings.value.isEmpty) {
        return Center(
          child: Text('No Cancelled Booking Found'),
        );
        // ⏳ Show loading until data is ready
      }

      return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: upcomingBookingController.cancelledBookings?.length,
          itemBuilder: (BuildContext context, int index) {
            return Stack(
              children: [
                Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: EdgeInsets.only(bottom: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(width: 1, color: Color(0xFFCECECE)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Car Row
                        Row(
                          children: [
                            // Image
                            Image.network(
                              upcomingBookingController
                                  .cancelledBookings?[index]
                                  .vehicleDetails
                                  ?.imageUrl ??
                                  '',
                              width: 84,
                              height: 64,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/inventory_car.png',
                                  width: 84,
                                  height: 64,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                            SizedBox(width: 12),

                            // Car Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    upcomingBookingController
                                        .cancelledBookings?[index]
                                        .vehicleDetails
                                        ?.type ??
                                        "",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF373737)),
                                  ),
                                  SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Booking ID: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF929292),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        TextSpan(
                                          text: upcomingBookingController
                                              .cancelledBookings?[index].id,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF222222),
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Booking Type: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF929292),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        TextSpan(
                                          text: upcomingBookingController
                                              .cancelledBookings?[index]
                                              .tripTypeDetails
                                              ?.tripType ??
                                              '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF002CC0),
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Paid Amount: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF929292),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        TextSpan(
                                          text: upcomingBookingController
                                              .cancelledBookings?[index]
                                              .recieptId
                                              ?.fareDetails
                                              ?.amountPaid
                                              .toString() ??
                                              '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF2B2B2B),
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 12),
                        Divider(
                          thickness: 1,
                          color: Color(0xFFF2F2F2),
                        ),
                        SizedBox(height: 12),
                        // Pickup and Drop
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        RotationTransition(
                                            turns: new AlwaysStoppedAnimation(
                                                40 / 360),
                                            child: Icon(
                                                Icons.navigation_outlined,
                                                size: 16,
                                                color: Color(0xFF002CC0))),
                                        SizedBox(width: 4),
                                        Text("Pickup",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF002CC0),
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                  SizedBox(height: 2),
                                  Text(
                                      upcomingBookingController
                                          .cancelledBookings?[index]
                                          .source
                                          ?.address ??
                                          'Source not found',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/calendar_clock.svg',
                                        height: 12,
                                        width: 12,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                          convertUtcToLocal(
                                              upcomingBookingController
                                                  .cancelledBookings?[
                                              index]
                                                  .startTime
                                                  .toString() ??
                                                  '',
                                              upcomingBookingController
                                                  .cancelledBookings?[
                                              index]
                                                  .timezone ??
                                                  '') ??
                                              'No Pickup Date Found',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF808080),
                                              fontWeight: FontWeight.w400)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 75,
                              color: Color(0xFFF2F2F2),
                              margin: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        Icon(Icons.pin_drop_outlined,
                                            size: 16, color: Color(0xFF002CC0)),
                                        SizedBox(width: 4),
                                        Text("Drop",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF002CC0),
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                  SizedBox(height: 2),
                                  (upcomingBookingController
                                      .cancelledBookings[index].tripTypeDetails?.basicTripType == 'LOCAL') ? SizedBox() :   Text(
                                      upcomingBookingController
                                          .cancelledBookings[index]
                                          .destination
                                          ?.address ??
                                          "Destination not found",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/calendar_clock.svg',
                                        height: 12,
                                        width: 12,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                          convertUtcToLocal(
                                              upcomingBookingController
                                                  .cancelledBookings?[
                                              index]
                                                  .endTime
                                                  .toString() ??
                                                  '',
                                              upcomingBookingController
                                                  .cancelledBookings?[
                                              index]
                                                  .timezone ??
                                                  '') ??
                                              'No Drop Date Found',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF808080),
                                              fontWeight: FontWeight.w400)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            CommonOutlineButton(
                              text: 'Download Receipt',
                              onPressed: pdfCtrl.isDownloading.value
                                  ? () {}
                                  : () async {
                                await pdfCtrl
                                    .downloadReceiptPdf(
                                    upcomingBookingController
                                        .completedBookings?[index].id ??
                                        '',
                                    context)
                                    .then((value) {
                                  GoRouter.of(context).pop();
                                });
                              },
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Handle button press
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                AppColors.mainButtonBg, // Background color
                                foregroundColor:
                                Colors.white, // Text (and ripple) color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                              child: Text(
                                'Manage Booking',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelled',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ))
              ],
            );
          });
    });
  }
}
