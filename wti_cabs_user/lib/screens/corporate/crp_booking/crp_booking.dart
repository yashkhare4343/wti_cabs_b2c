import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_booking_history_controller/crp_booking_history_controller.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_booking_history/crp_booking_history_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_feedback_questions_controller/crp_feedback_questions_controller.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_feedback_questions/crp_feedback_questions_response.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import '../../../common_widget/loader/shimmer/corporate_shimmer.dart';
import '../../../core/model/corporate/crp_car_provider_response/crp_car_provider_response.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../corporate_bottom_nav/corporate_bottom_nav.dart';
import '../../../common_widget/buttons/outline_button.dart';
import '../../../core/services/storage_services.dart';
import '../../../core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import '../../../core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart';
import '../../../core/controller/corporate/crp_car_provider/crp_car_provider_controller.dart';

class CrpBooking extends StatefulWidget {
  const CrpBooking({super.key});

  @override
  State<CrpBooking> createState() => _CrpBookingState();
}

class _CrpBookingState extends State<CrpBooking> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _filterSearchController = TextEditingController();
  final CrpBookingHistoryController _controller =
      Get.put(CrpBookingHistoryController());
  final LoginInfoController loginInfoController =
      Get.put(LoginInfoController());
  final CrpBranchListController _branchController =
      Get.find<CrpBranchListController>();
  final CarProviderController _carProviderController =
      Get.put(CarProviderController());
  final CrpFeedbackQuestionsController _feedbackController = Get.put(CrpFeedbackQuestionsController());
  bool _showShimmer = true;

  // Filter state
  String _selectedCategory = 'Car Rental City';
  String? _selectedCity;
  String? _selectedCarProvider;
  String? _selectedBookingMonth;
  String? _selectedFiscalYear;

  // Month name to ID mapping
  final Map<String, int> _monthMap = {
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
  };

  // Helper methods to get IDs from names
  String? _getBranchIdFromName(String? branchName) {
    if (branchName == null) return null;
    try {
      final branch = _branchController.branches.firstWhere(
        (b) => b['BranchName'] == branchName,
        orElse: () => {},
      );
      return branch['BranchID']?.toString();
    } catch (e) {
      return null;
    }
  }

  int? _getProviderIdFromName(String? providerName) {
    if (providerName == null) return null;
    try {
      final provider = _carProviderController.carProviderList.firstWhere(
        (p) => p.providerName == providerName,
        orElse: () => CarProviderModel(),
      );
      return provider.providerID;
    } catch (e) {
      return null;
    }
  }

  int? _getMonthIdFromName(String? monthName) {
    if (monthName == null) return null;
    return _monthMap[monthName];
  }

  int? _getFiscalYearFromString(String? yearString) {
    if (yearString == null) return null;
    return int.tryParse(yearString);
  }

  Future<void> _applyFilters() async {
    // Save filter selections
    await _saveFilters();

    // Get IDs from selected filter values
    final branchId = _getBranchIdFromName(_selectedCity);
    final providerId = _getProviderIdFromName(_selectedCarProvider) ?? 1;
    final monthId = _getMonthIdFromName(_selectedBookingMonth);
    final fiscalYear = _getFiscalYearFromString(_selectedFiscalYear) ?? 2026;

    // If branch is selected, update it in storage
    if (branchId != null) {
      await StorageServices.instance.save('branchId', branchId);
    }

    // Fetch booking history with filters
    final criteria = _filterSearchController.text.trim();
    await _controller.fetchBookingHistory(
      context,
      branchId: branchId,
      monthId: monthId,
      providerId: providerId,
      fiscalYear: fiscalYear,
      criteria: criteria,
    );
  }

  @override
  void initState() {
    super.initState();
    // Load saved filter selections
    _loadSavedFilters();
    // Show shimmer for 0.5 seconds
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showShimmer = false;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ Ensure email is persisted before fetching booking history
      await _ensureEmailPersistence();
      // Fetch feedback questions status
      await _feedbackController.fetchFeedbackQuestions(context);
      // Fetch with saved or default values
      await _loadAndFetchBookings();
    });
  }

  Future<void> _loadSavedFilters() async {
    _selectedCity = await StorageServices.instance.read('filter_selected_city');
    _selectedCarProvider =
        await StorageServices.instance.read('filter_selected_car_provider');
    _selectedBookingMonth =
        await StorageServices.instance.read('filter_selected_booking_month');
    _selectedFiscalYear =
        await StorageServices.instance.read('filter_selected_fiscal_year') ??
            '2026';
  }

  Future<void> _saveFilters() async {
    if (_selectedCity != null) {
      await StorageServices.instance
          .save('filter_selected_city', _selectedCity!);
    }
    if (_selectedCarProvider != null) {
      await StorageServices.instance
          .save('filter_selected_car_provider', _selectedCarProvider!);
    }
    if (_selectedBookingMonth != null) {
      await StorageServices.instance
          .save('filter_selected_booking_month', _selectedBookingMonth!);
    }
    if (_selectedFiscalYear != null) {
      await StorageServices.instance
          .save('filter_selected_fiscal_year', _selectedFiscalYear!);
    }
  }

  Future<void> _loadAndFetchBookings() async {
    final now = DateTime.now();
    final monthId = _getMonthIdFromName(_selectedBookingMonth) ?? now.month;
    final fiscalYear = _getFiscalYearFromString(_selectedFiscalYear) ?? 2026;
    final providerId = _getProviderIdFromName(_selectedCarProvider) ?? 1;
    final branchId = _getBranchIdFromName(_selectedCity);
    final criteria = _filterSearchController.text.trim();

    await _controller.fetchBookingHistory(
      context,
      branchId: branchId,
      monthId: monthId,
      providerId: providerId,
      fiscalYear: fiscalYear,
      criteria: criteria,
    );
  }

  /// Ensure email is persisted in storage for API calls
  Future<void> _ensureEmailPersistence() async {
    try {
      // Check if email exists in StorageServices
      String? email = await StorageServices.instance.read('email');

      // If not found, try SharedPreferences as fallback
      if (email == null || email.isEmpty || email == 'null') {
        final prefs = await SharedPreferences.getInstance();
        email = prefs.getString('email');

        // If found in SharedPreferences, save to StorageServices
        if (email != null && email.isNotEmpty && email != 'null') {
          await StorageServices.instance.save('email', email);
          debugPrint('✅ Email restored from SharedPreferences: $email');
        }
      }

      // If still not found, ensure it's saved if available
      if (email != null && email.isNotEmpty && email != 'null') {
        // Ensure it's in both storage locations
        await StorageServices.instance.save('email', email);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        debugPrint('✅ Email persisted in booking screen: $email');
      } else {
        debugPrint('⚠️ Email not found in storage for booking screen');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring email persistence: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showShimmer) {
      return const CorporateShimmer();
    }
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          context.go(AppRoutes.cprBottomNav);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.05),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: const Text(
            'My Booking',
            style: TextStyle(
              color: Color(0xFF000000),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              // letterSpacing: -0.5,
            ),
          ),
          centerTitle: false,
        ),
        backgroundColor: Colors.white,
        body: Obx(() {
          if (_controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => _loadAndFetchBookings(),
            child: Column(
              children: [
                // Filters Button - Always visible
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showFilterBottomSheet(context),
                          child:
                              _buildFilterButton('Filters', Icons.filter_list),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content: Either empty state or bookings list
                Expanded(
                  child: _controller.bookings.isEmpty
                      ? const Center(
                          child: Text(
                            'No Bookings Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: _controller.bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _controller.bookings[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildBookingCard(booking),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilterButton(String text, IconData icon) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.grey.shade700,
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final CarProviderController carProviderController =
        Get.put(CarProviderController());
    // Get the preselected car provider from saved filters or controller
    final preselectedCarProvider = _selectedCarProvider ??
        carProviderController.selectedCarProvider.value?.providerName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedCity: _selectedCity,
        selectedCarProvider: preselectedCarProvider,
        selectedBookingMonth: _selectedBookingMonth,
        selectedFiscalYear: _selectedFiscalYear ?? '2026',
        searchController: _filterSearchController,
        onCategoryChanged: (category) {
          setState(() {
            _selectedCategory = category;
          });
        },
        onCityChanged: (city) {
          setState(() {
            _selectedCity = city;
          });
        },
        onCarProviderChanged: (carProvider) {
          setState(() {
            _selectedCarProvider = carProvider;
          });
        },
        onBookingMonthChanged: (month) {
          setState(() {
            _selectedBookingMonth = month;
          });
        },
        onFiscalYearChanged: (year) {
          setState(() {
            _selectedFiscalYear = year;
          });
        },
        onApply: () {
          Navigator.pop(context);
          _applyFilters();
        },
        onClear: () async {
          setState(() {
            _selectedCity = null;
            _selectedCarProvider = null;
            _selectedBookingMonth = null;
            _selectedFiscalYear = null;
          });
          // Clear saved filters
          await StorageServices.instance.delete('filter_selected_city');
          await StorageServices.instance.delete('filter_selected_car_provider');
          await StorageServices.instance
              .delete('filter_selected_booking_month');
          await StorageServices.instance.delete('filter_selected_fiscal_year');

          // Clear search criteria text as well
          _filterSearchController.clear();

          Navigator.pop(context);
          // Reset to default values and fetch
          final now = DateTime.now();
          await _controller.fetchBookingHistory(
            context,
            monthId: now.month,
            fiscalYear: 2026,
            criteria: '',
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(CrpBookingHistoryItem booking) {
    final bool isConfirmed = booking.status == 'Confirmed';

    // Format booking date
    String formattedDate = 'N/A';
    if (booking.cabRequiredOn != null && booking.cabRequiredOn!.isNotEmpty) {
      try {
        // Try to parse the date string
        DateTime? parsedDate;
        // Try different date formats
        try {
          parsedDate = DateTime.parse(booking.cabRequiredOn!);
        } catch (e) {
          // If parsing fails, try other formats
          try {
            parsedDate = DateFormat('dd/MM/yyyy').parse(booking.cabRequiredOn!);
          } catch (e2) {
            // If all parsing fails, use current date
            // parsedDate = DateTime.now();
            parsedDate = DateFormat('dd/MM/yyyy').parse(booking.cabRequiredOn!);
          }
        }
        formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);
      } catch (e) {
        formattedDate = booking.cabRequiredOn ?? 'N/A';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Car Icon and Service Type Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Icon (White car icon)
                Container(
                  width: 63,
                  height: 47,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/booking_crp_car.png',
                    width: 60,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Service Type and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.run ?? 'Service',
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF192653),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Badge with checkmark
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isConfirmed ? Icons.check_circle : Icons.cancel,
                                size: 18,
                                color: isConfirmed ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                booking.status ?? 'Pending',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isConfirmed ? Colors.green : Colors.red,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.model ?? '-',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF939393),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // // Middle Section: Route Visualization
            // Row(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     // Vertical Line with Circle and Square
            //     Column(
            //       children: [
            //         // Circle at top
            //         Container(
            //           width: 12,
            //           height: 12,
            //           decoration: const BoxDecoration(
            //             color: Color(0xFF4082F1),
            //             shape: BoxShape.circle,
            //           ),
            //         ),
            //         // Vertical Line
            //         Container(
            //           width: 2,
            //           height: 36,
            //           color: const Color(0xFF4082F1),
            //         ),
            //         // Square at bottom
            //         Container(
            //           width: 12,
            //           height: 12,
            //           decoration: const BoxDecoration(
            //             color: Color(0xFF4082F1),
            //           ),
            //         ),
            //       ],
            //     ),
            //     const SizedBox(width: 12),
            //     // Pickup and Drop Locations
            //     Expanded(
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           // Pickup Location
            //           Text(
            //             booking.passenger ?? 'Pickup location',
            //             style: TextStyle(
            //               fontSize: 13,
            //               color: Colors.grey.shade700,
            //               fontFamily: 'Montserrat',
            //               height: 1.3,
            //             ),
            //             maxLines: 2,
            //             overflow: TextOverflow.ellipsis,
            //           ),
            //           const SizedBox(height: 14),
            //           // Drop Location
            //           Text(
            //             'Drop location',
            //             style: TextStyle(
            //               fontSize: 13,
            //               color: Colors.grey.shade700,
            //               fontFamily: 'Montserrat',
            //               height: 1.3,
            //             ),
            //             maxLines: 2,
            //             overflow: TextOverflow.ellipsis,
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 16),
            // Dashed Line Separator
            CustomPaint(
              painter: DashedLinePainter(),
              child: const SizedBox(
                height: 1,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 16),
            // Bottom Section: Booking ID, Date, and Driver Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking ID and Date (Left side)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passenger Name:- ${booking.passenger ?? booking.passenger ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking ID:- ${booking.bookingNo ?? booking.bookingId ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pickup on:- $formattedDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
                // Driver Details Link (Right side)
                // TextButton(
                //   onPressed: () {
                //     // Navigate to driver details
                //   },
                //   style: TextButton.styleFrom(
                //     padding: EdgeInsets.zero,
                //     minimumSize: Size.zero,
                //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                //     alignment: Alignment.centerRight,
                //   ),
                //   child: Text(
                //     'Driver Details',
                //     style: TextStyle(
                //       fontSize: 12,
                //       fontWeight: FontWeight.w500,
                //       color: Colors.grey.shade700,
                //       fontFamily: 'Montserrat',
                //       decoration: TextDecoration.underline,
                //       decorationColor: Colors.grey.shade700,
                //     ),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 16),
            // Edit Booking and Feedback Buttons
            Obx(() {
              final showFeedbackButton = _feedbackController.feedbackQuestionsResponse.value?.bStatus == true;
              
              return Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Booking Detail',
                      () {
                        context.push(
                          AppRoutes.cprBookingDetails,
                          extra: booking,
                        );
                      },
                    ),
                  ),
                  if (showFeedbackButton) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        'Feedback',
                        () {
                          _showFeedbackDialog(context, booking);
                        },
                      ),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4082F1),
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(
      BuildContext context, CrpBookingHistoryItem booking) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _FeedbackDialog(booking: booking),
    );
  }
}

// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Filter Bottom Sheet Widget
class _FilterBottomSheet extends StatefulWidget {
  final String selectedCategory;
  final String? selectedCity;
  final String? selectedCarProvider;
  final String? selectedBookingMonth;
  final String? selectedFiscalYear;
  final TextEditingController searchController;
  final Function(String) onCategoryChanged;
  final Function(String) onCityChanged;
  final Function(String) onCarProviderChanged;
  final Function(String) onBookingMonthChanged;
  final Function(String) onFiscalYearChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    required this.selectedCategory,
    required this.selectedCity,
    required this.selectedCarProvider,
    required this.selectedBookingMonth,
    required this.selectedFiscalYear,
    required this.searchController,
    required this.onCategoryChanged,
    required this.onCityChanged,
    required this.onCarProviderChanged,
    required this.onBookingMonthChanged,
    required this.onFiscalYearChanged,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _currentCategory;
  late String? _currentCity;
  late String? _currentCarProvider;
  late String? _currentBookingMonth;
  late String? _currentFiscalYear;
  final CrpBranchListController _branchController =
      Get.find<CrpBranchListController>();
  final CarProviderController _carProviderController =
      Get.put(CarProviderController());

  // List of months
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // List of fiscal years
  final List<String> _fiscalYears = [
    '2026',
  ];

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.selectedCategory;
    // Set default selected city from branch controller or widget
    _currentCity =
        widget.selectedCity ?? _branchController.selectedBranchName.value;
    // Set default selected car provider from widget or controller (prioritize widget value)
    _currentCarProvider = widget.selectedCarProvider ??
        _carProviderController.selectedCarProvider.value?.providerName;
    // Always set booking month to current month (ignore previous selection)
    _currentBookingMonth = _getCurrentMonth();
    // Set default fiscal year to 2026
    _currentFiscalYear = widget.selectedFiscalYear ?? '2026';
    _fetchBranches();
    _fetchCarProviders();
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return _months[now.month - 1]; // month is 1-12, list index is 0-11
  }

  Future<void> _fetchBranches() async {
    final corpId = await StorageServices.instance.read('crpId');
    if (corpId != null && corpId.isNotEmpty) {
      await _branchController.fetchBranches(corpId);
      // After fetching, set default selected city if not already set
      if (_currentCity == null &&
          _branchController.selectedBranchName.value != null) {
        setState(() {
          _currentCity = _branchController.selectedBranchName.value;
        });
      }
    }
  }

  Future<void> _fetchCarProviders() async {
    if (_carProviderController.carProviderList.isEmpty &&
        !_carProviderController.isLoading.value) {
      await _carProviderController.fetchCarProviders(context);
    }
    // Set selected car provider from controller if not already set from widget
    // But preserve widget value if it exists
    if (_currentCarProvider == null) {
      if (_carProviderController.selectedCarProvider.value != null) {
        setState(() {
          _currentCarProvider =
              _carProviderController.selectedCarProvider.value?.providerName;
        });
      } else if (_carProviderController.carProviderList.isNotEmpty) {
        // If no selection and list is available, use the first one
        setState(() {
          _currentCarProvider =
              _carProviderController.carProviderList.first.providerName;
        });
      }
    } else {
      // If we have a preselected value, make sure it exists in the list
      // If not, fall back to controller's selection
      final exists = _carProviderController.carProviderList.any(
        (p) => p.providerName == _currentCarProvider,
      );
      if (!exists && _carProviderController.selectedCarProvider.value != null) {
        setState(() {
          _currentCarProvider =
              _carProviderController.selectedCarProvider.value?.providerName;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFE9E9F6), // Light blue background
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF000000)),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFD9D9D9),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: widget.searchController,
              decoration: InputDecoration(
                hintText: 'Search By Booking Number',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF333333),
                  fontFamily: 'Montserrat',
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    'assets/images/search.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF333333),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          // Main Content - Two Pane Layout
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Left Pane - Filter Categories
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildCategoryItem('Car Rental City'),
                          _buildCategoryItem('Car Provider'),
                          _buildCategoryItem('Booking Month'),
                          _buildCategoryItem('Search Fiscal Year'),
                        ],
                      ),
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  // Right Pane - Filter Options
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: _buildFilterOptions(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Apply Button
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4082F1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: TextButton(
                      onPressed: () {
                        widget.onCityChanged(_currentCity ?? '');
                        widget.onCarProviderChanged(_currentCarProvider ?? '');
                        widget
                            .onBookingMonthChanged(_currentBookingMonth ?? '');
                        widget.onFiscalYearChanged(_currentFiscalYear ?? '');
                        widget.onApply();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Clear Filter Button
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: const Color(0xFF4082F1),
                        width: 1,
                      ),
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _currentCity = null;
                          _currentCarProvider = null;
                          _currentBookingMonth = null;
                          _currentFiscalYear = null;
                        });
                        widget.onClear();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Clear Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4082F1),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category) {
    final isSelected = _currentCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentCategory = category;
        });
        widget.onCategoryChanged(category);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Color(0xFF4082F1) : const Color(0xFF939393),
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    if (_currentCategory == 'Car Rental City') {
      return Obx(() {
        if (_branchController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_branchController.branchNames.isEmpty) {
          return const Center(
            child: Text(
              'No cities available',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF939393),
                fontFamily: 'Montserrat',
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _branchController.branchNames.length,
          itemBuilder: (context, index) {
            final branchName = _branchController.branchNames[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    index < _branchController.branchNames.length - 1 ? 16 : 0,
              ),
              child: _buildRadioOption(branchName, branchName),
            );
          },
        );
      });
    } else if (_currentCategory == 'Car Provider') {
      return Obx(() {
        if (_carProviderController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_carProviderController.carProviderList.isEmpty) {
          return const Center(
            child: Text(
              'No car providers available',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF939393),
                fontFamily: 'Montserrat',
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _carProviderController.carProviderList.length,
          itemBuilder: (context, index) {
            final provider = _carProviderController.carProviderList[index];
            final providerName = provider.providerName ?? '';
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    index < _carProviderController.carProviderList.length - 1
                        ? 16
                        : 0,
              ),
              child: _buildCarProviderRadioOption(providerName, providerName),
            );
          },
        );
      });
    } else if (_currentCategory == 'Booking Month') {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final month = _months[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _months.length - 1 ? 16 : 0,
            ),
            child: _buildBookingMonthRadioOption(month, month),
          );
        },
      );
    } else if (_currentCategory == 'Search Fiscal Year') {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _fiscalYears.length,
        itemBuilder: (context, index) {
          final year = _fiscalYears[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _fiscalYears.length - 1 ? 16 : 0,
            ),
            child: _buildFiscalYearRadioOption(year, year),
          );
        },
      );
    }
    return const SizedBox();
  }

  Widget _buildRadioOption(String label, String value) {
    final isSelected = _currentCity == value;
    return InkWell(
      onTap: () {
        setState(() {
          _currentCity = value;
        });
        widget.onCityChanged(value);
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4082F1)
                    : const Color(0xFF939393),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4082F1),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isSelected ? Color(0xFF4082F1) : Color(0xFF333333),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarProviderRadioOption(String label, String value) {
    final isSelected = _currentCarProvider == value;
    return InkWell(
      onTap: () {
        setState(() {
          _currentCarProvider = value;
        });
        widget.onCarProviderChanged(value);
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4082F1)
                    : const Color(0xFF939393),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4082F1),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF333333),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingMonthRadioOption(String label, String value) {
    final isSelected = _currentBookingMonth == value;
    return InkWell(
      onTap: () {
        setState(() {
          _currentBookingMonth = value;
        });
        widget.onBookingMonthChanged(value);
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4082F1)
                    : const Color(0xFF939393),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4082F1),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF333333),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiscalYearRadioOption(String label, String value) {
    final isSelected = _currentFiscalYear == value;
    return InkWell(
      onTap: () {
        setState(() {
          _currentFiscalYear = value;
        });
        widget.onFiscalYearChanged(value);
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4082F1)
                    : const Color(0xFF939393),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4082F1),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF333333),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Feedback Dialog Widget
class _FeedbackDialog extends StatefulWidget {
  final CrpBookingHistoryItem booking;

  const _FeedbackDialog({
    required this.booking,
    super.key,
  });

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final TextEditingController _remarksController = TextEditingController();
  final CrpFeedbackQuestionsController _feedbackController = Get.put(CrpFeedbackQuestionsController());
  
  // Store answers for each question by Q_id (true = Yes, false = No, null = not answered)
  Map<int, bool?> _answers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestions();
    });
  }

  Future<void> _fetchQuestions() async {
    await _feedbackController.fetchFeedbackQuestions(context);
    // Initialize answers map with question IDs
    if (_feedbackController.feedbackQuestions.isNotEmpty) {
      setState(() {
        _answers = {
          for (var question in _feedbackController.feedbackQuestions)
            question.qId ?? 0: null
        };
      });
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Get required parameters
    final guestIdStr = await StorageServices.instance.read('guestId');
    final guestId = int.tryParse(guestIdStr ?? '') ?? 0;
    
    // Get OrderID from booking (use bookingId or id)
    final orderId = widget.booking.bookingId ?? widget.booking.id ?? 0;
    
    // Get QuestionID from response
    final questionId = _feedbackController.feedbackQuestionsResponse.value?.noOfQuestions ?? 
                       _feedbackController.feedbackQuestions.length;
    
    if (guestId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guest ID not found'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (orderId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID not found'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Submit feedback
    final response = await _feedbackController.submitFeedback(
      context: context,
      guestId: guestId,
      orderId: orderId,
      questionId: questionId,
      answers: _answers,
      remarks: _remarksController.text.trim(),
    );
    
    if (response != null) {
      // Close dialog first
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show success/failure message based on bStatus
      final message = response.sMessage ?? 'Feedback submitted';
      final isSuccess = response.bStatus == true;
      final bgColor = isSuccess ? Colors.green : Colors.red;
      final icon = isSuccess ? Icons.check_circle : Icons.error;

      if (mounted) {
        Flushbar(
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(12),
          backgroundColor: bgColor,
          duration: const Duration(seconds: 3),
          icon: Icon(icon, color: Colors.white),
          messageText: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).show(context);
      }
    } else {
      // Error submitting
      if (mounted) {
        Flushbar(
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(12),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
          messageText: const Text(
            'Failed to submit feedback. Please try again.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
        ),
        child: Obx(() {
          if (_feedbackController.isLoading.value) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final questions = _feedbackController.feedbackQuestions;
          
          if (questions.isEmpty) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No feedback questions available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FeedBack',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Questions
                ...List.generate(questions.length, (index) {
                  final question = questions[index];
                  final questionId = question.qId ?? 0;
                  
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < questions.length - 1 ? 20 : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.question ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: _answers[questionId],
                              onChanged: (bool? value) {
                                setState(() {
                                  _answers[questionId] = value;
                                });
                              },
                              activeColor: const Color(0xFF4082F1),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _answers[questionId] = true;
                                });
                              },
                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '|',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade400,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                            Radio<bool>(
                              value: false,
                              groupValue: _answers[questionId],
                              onChanged: (bool? value) {
                                setState(() {
                                  _answers[questionId] = value;
                                });
                              },
                              activeColor: const Color(0xFF4082F1),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _answers[questionId] = false;
                                });
                              },
                              child: const Text(
                                'No',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Remarks Text Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _remarksController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter Remarks here',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFB2B2B2),
                        fontFamily: 'Montserrat',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                Obx(() {
                  final isSubmitting = _feedbackController.isSubmitting.value;
                  
                  return SizedBox(
                    width: double.infinity,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4082F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: isSubmitting ? null : _handleSubmit,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }
}
