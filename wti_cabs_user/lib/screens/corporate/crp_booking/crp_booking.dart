import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_booking_history_controller/crp_booking_history_controller.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_booking_history/crp_booking_history_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import '../../../common_widget/loader/shimmer/corporate_shimmer.dart';
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
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());
  bool _showShimmer = true;
  
  // Filter state
  String _selectedCategory = 'Car Rental City';
  String? _selectedCity;
  String? _selectedCarProvider;
  String? _selectedBookingMonth;
  String? _selectedFiscalYear;

  @override
  void initState() {
    super.initState();
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
      _controller.fetchBookingHistory(context);
    });
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

          if (_controller.bookings.isEmpty) {
            return const Center(
              child: Text(
                'No bookings found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _controller.fetchBookingHistory(context),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _controller.bookings.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Filters Button
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showFilterBottomSheet(context),
                                child: _buildFilterButton('Filters', Icons.filter_list),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                }

                final booking = _controller.bookings[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildBookingCard(booking),
                );
              },
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
        borderRadius: BorderRadius.circular(8),
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
    final CarProviderController carProviderController = Get.put(CarProviderController());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedCity: _selectedCity,
        selectedCarProvider: _selectedCarProvider ?? carProviderController.selectedCarProvider.value?.providerName,
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
          // Apply filters logic here
          Navigator.pop(context);
          // You can add filter application logic here
        },
        onClear: () {
          setState(() {
            _selectedCity = null;
            _selectedCarProvider = null;
            _selectedBookingMonth = null;
            _selectedFiscalYear = null;
          });
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
                                isConfirmed
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 18,
                                color: isConfirmed
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                booking.status ?? 'Pending',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isConfirmed
                                      ? Colors.green
                                      : Colors.red,
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
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Edit Booking',
                    () {
                      context.push(
                        AppRoutes.cprBookingDetails,
                        extra: booking,
                      );
                    },
                  ),
                ),
                // const SizedBox(width: 12),
                // Expanded(
                //   child: _buildActionButton(
                //     'Feedback',
                //     () {
                //       // Handle feedback
                //     },
                //   ),
                // ),
              ],
            ),
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
  final CrpBranchListController _branchController = Get.find<CrpBranchListController>();
  final CarProviderController _carProviderController = Get.put(CarProviderController());
  String _searchQuery = '';
  
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
    _currentCity = widget.selectedCity ?? _branchController.selectedBranchName.value;
    // Set default selected car provider from controller (always use controller value)
    _currentCarProvider = _carProviderController.selectedCarProvider.value?.providerName;
    // Always set booking month to current month (ignore previous selection)
    _currentBookingMonth = _getCurrentMonth();
    // Set default fiscal year to 2026
    _currentFiscalYear = widget.selectedFiscalYear ?? '2026';
    _fetchBranches();
    _fetchCarProviders();
    
    // Add listener to search controller for filtering
    widget.searchController.addListener(_onSearchChanged);
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return _months[now.month - 1]; // month is 1-12, list index is 0-11
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = widget.searchController.text;
    });
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  Future<void> _fetchBranches() async {
    final corpId = await StorageServices.instance.read('crpId');
    if (corpId != null && corpId.isNotEmpty) {
      await _branchController.fetchBranches(corpId);
      // After fetching, set default selected city if not already set
      if (_currentCity == null && _branchController.selectedBranchName.value != null) {
        setState(() {
          _currentCity = _branchController.selectedBranchName.value;
        });
      }
    }
  }

  Future<void> _fetchCarProviders() async {
    if (_carProviderController.carProviderList.isEmpty && !_carProviderController.isLoading.value) {
      await _carProviderController.fetchCarProviders(context);
    }
    // Always set selected car provider from controller (like city does)
    if (_carProviderController.selectedCarProvider.value != null) {
      setState(() {
        _currentCarProvider = _carProviderController.selectedCarProvider.value?.providerName;
      });
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
            child: TextField(
              controller: widget.searchController,
              decoration: InputDecoration(
                hintText: 'Search Criteria',
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
                  Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        widget.onCityChanged(_currentCity ?? '');
                        widget.onCarProviderChanged(_currentCarProvider ?? '');
                        widget.onBookingMonthChanged(_currentBookingMonth ?? '');
                        widget.onFiscalYearChanged(_currentFiscalYear ?? '');
                        widget.onApply();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(8),
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
                          borderRadius: BorderRadius.circular(8),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4082F1)
              : Colors.white,
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : const Color(0xFF939393),
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

        // Filter branches based on search
        final searchQuery = _searchQuery.toLowerCase();
        final filteredBranches = searchQuery.isEmpty
            ? _branchController.branchNames
            : _branchController.branchNames
                .where((name) => name.toLowerCase().contains(searchQuery))
                .toList();

        if (filteredBranches.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No cities found',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF939393),
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: filteredBranches.length,
          itemBuilder: (context, index) {
            final branchName = filteredBranches[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < filteredBranches.length - 1 ? 16 : 0,
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

        // Filter car providers based on search
        final searchQuery = _searchQuery.toLowerCase();
        final filteredProviders = searchQuery.isEmpty
            ? _carProviderController.carProviderList
            : _carProviderController.carProviderList
                .where((provider) => 
                    (provider.providerName ?? '').toLowerCase().contains(searchQuery))
                .toList();

        if (filteredProviders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No car providers found',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF939393),
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: filteredProviders.length,
          itemBuilder: (context, index) {
            final provider = filteredProviders[index];
            final providerName = provider.providerName ?? '';
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < filteredProviders.length - 1 ? 16 : 0,
              ),
              child: _buildCarProviderRadioOption(providerName, providerName),
            );
          },
        );
      });
    } else if (_currentCategory == 'Booking Month') {
      // Filter months based on search
      final searchQuery = _searchQuery.toLowerCase();
      final filteredMonths = searchQuery.isEmpty
          ? _months
          : _months
              .where((month) => month.toLowerCase().contains(searchQuery))
              .toList();

      if (filteredMonths.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No months found',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF939393),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        );
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: filteredMonths.length,
        itemBuilder: (context, index) {
          final month = filteredMonths[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < filteredMonths.length - 1 ? 16 : 0,
            ),
            child: _buildBookingMonthRadioOption(month, month),
          );
        },
      );
    } else if (_currentCategory == 'Search Fiscal Year') {
      // Filter fiscal years based on search
      final searchQuery = _searchQuery.toLowerCase();
      final filteredYears = searchQuery.isEmpty
          ? _fiscalYears
          : _fiscalYears
              .where((year) => year.toLowerCase().contains(searchQuery))
              .toList();

      if (filteredYears.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No fiscal years found',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF939393),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        );
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: filteredYears.length,
        itemBuilder: (context, index) {
          final year = filteredYears[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < filteredYears.length - 1 ? 16 : 0,
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
