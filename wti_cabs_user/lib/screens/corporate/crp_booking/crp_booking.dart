import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../common_widget/loader/popup_loader.dart';
import '../../../common_widget/snackbar/custom_snackbar.dart';
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
import '../../../core/controller/corporate/crp_fiscal_year_controller/crp_fiscal_year_controller.dart';

/// Booking Status Constants
/// Status codes: 0 = Pending, 1 = Confirmed, 2 = Dispatched, 3 = Missed, 4 = Cancelled, 5 = Void, 6 = Allocated
class BookingStatus {
  // Numeric status codes
  static const int pending = 0;
  static const int confirmed = 1;
  static const int dispatched = 2;
  static const int missed = 3;
  static const int cancelled = 4;
  static const int voidStatus = 5;
  static const int allocated = 6;
  static const int all = -1;

  // Status string values (as returned from API)
  static const String pendingStr = 'Pending';
  static const String confirmedStr = 'Confirmed';
  static const String dispatchedStr = 'Dispatched';
  static const String missedStr = 'Missed';
  static const String cancelledStr = 'Cancelled';
  static const String voidStr = 'Void';
  static const String allocatedStr = 'Allocated';

  // Tab-to-Status Mapping
  // Upcoming Tab → Status IN (0, 1, 2, 6) - Pending, Confirmed, Dispatched, Allocated
  static const List<String> confirmedTabStatuses = [
    pendingStr,
    confirmedStr,
    dispatchedStr,
    allocatedStr,
  ];

  // Completed Tab → Effective status "Completed"
  // (Status is "Dispatched" AND currentDispatchStatusId == 6 (Close))
  static const List<String> completedTabStatuses = [];

  // Cancelled Tab → Status IN (3, 4, 5) - Missed, Cancelled, Void
  static const List<String> cancelledTabStatuses = [
    missedStr,
    cancelledStr,
    voidStr,
  ];

  /// Check if a booking belongs to a specific tab
  /// Handles case-insensitive matching for robustness
  /// If status is "Dispatched" and currentDispatchStatusId is 6 (Close), treat as completed
  static bool belongsToTab(CrpBookingHistoryItem booking, BookingTab tab) {
    final status = booking.status;
    if (status == null || status.isEmpty) return false;
    final normalizedStatus = status.trim().toLowerCase();
    
    // Get effective status: If Dispatched with currentDispatchStatusId == 6 (Close), treat as Completed
    final effectiveStatus = getEffectiveStatus(booking);
    final effectiveStatusLower = effectiveStatus.toLowerCase();

    switch (tab) {
      case BookingTab.confirmed:
        // Exclude completed bookings from confirmed tab
        if (effectiveStatusLower == 'completed') return false;
        return confirmedTabStatuses
            .any((s) => s.toLowerCase() == normalizedStatus);
      case BookingTab.completed:
        // Include bookings that are effectively completed (Dispatched with Close status)
        if (effectiveStatusLower == 'completed') return true;
        return completedTabStatuses
            .any((s) => s.toLowerCase() == normalizedStatus);
      case BookingTab.cancelled:
        return cancelledTabStatuses
            .any((s) => s.toLowerCase() == normalizedStatus);
    }
  }
  
  /// Get effective status for a booking
  /// If status is "Dispatched" and currentDispatchStatusId is 6 (Close), return "Completed"
  static String getEffectiveStatus(CrpBookingHistoryItem booking) {
    final status = booking.status;
    if (status == null || status.isEmpty) return status ?? 'Pending';
    
    final normalizedStatus = status.trim().toLowerCase();
    // If status is "Dispatched" and currentDispatchStatusId is 6 (Close), treat as "Completed"
    if (normalizedStatus == 'dispatched' && booking.currentDispatchStatusId == 6) {
      return 'Completed';
    }
    
    return status;
  }
}

/// Booking Tab Enum
enum BookingTab {
  confirmed,
  completed,
  cancelled,
}

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
  final CrpFeedbackQuestionsController _feedbackController =
      Get.put(CrpFeedbackQuestionsController());
  final CrpFiscalYearController _fiscalYearController =
      Get.put(CrpFiscalYearController());
  bool _showShimmer = true;
  bool _hasLoadedData = false; // Track if data has been loaded at least once

  // Tab state - default to Confirmed (observable for reactive UI updates)
  final Rx<BookingTab> _selectedTab = BookingTab.confirmed.obs;

  // All bookings fetched from API (unfiltered)
  final RxList<CrpBookingHistoryItem> _allBookings =
      <CrpBookingHistoryItem>[].obs;

  // Pre-filtered + pre-sorted lists per tab (reactive)
  final RxList<CrpBookingHistoryItem> _upcomingBookings =
      <CrpBookingHistoryItem>[].obs;
  final RxList<CrpBookingHistoryItem> _completedBookings =
      <CrpBookingHistoryItem>[].obs;
  final RxList<CrpBookingHistoryItem> _cancelledBookings =
      <CrpBookingHistoryItem>[].obs;

  int _compareDateTimeNullable(DateTime? a, DateTime? b, {required bool ascending}) {
    if (a == null && b == null) return 0;
    if (a == null) return 1; // nulls last
    if (b == null) return -1; // nulls last
    return ascending ? a.compareTo(b) : b.compareTo(a);
  }

  void _rebuildAndSortTabLists() {
    final upcoming = <CrpBookingHistoryItem>[];
    final completed = <CrpBookingHistoryItem>[];
    final cancelled = <CrpBookingHistoryItem>[];

    for (final booking in _allBookings) {
      if (BookingStatus.belongsToTab(booking, BookingTab.completed)) {
        completed.add(booking);
      } else if (BookingStatus.belongsToTab(booking, BookingTab.cancelled)) {
        cancelled.add(booking);
      } else if (BookingStatus.belongsToTab(booking, BookingTab.confirmed)) {
        upcoming.add(booking);
      }
    }

    // Upcoming: pickupDateTime ASC (nearest first)
    upcoming.sort((a, b) => _compareDateTimeNullable(
          a.pickupDateTimeLocal,
          b.pickupDateTimeLocal,
          ascending: true,
        ));

    // Completed: completedDateTime DESC (most recent first)
    completed.sort((a, b) => _compareDateTimeNullable(
          a.completedDateTimeLocal,
          b.completedDateTimeLocal,
          ascending: false,
        ));

    // Cancelled: cancelledDateTime DESC (most recent first)
    cancelled.sort((a, b) => _compareDateTimeNullable(
          a.cancelledDateTimeLocal,
          b.cancelledDateTimeLocal,
          ascending: false,
        ));

    _upcomingBookings.assignAll(upcoming);
    _completedBookings.assignAll(completed);
    _cancelledBookings.assignAll(cancelled);
  }

  // Filtered bookings based on selected tab (reactive)
  List<CrpBookingHistoryItem> get _filteredBookings {
    switch (_selectedTab.value) {
      case BookingTab.confirmed:
        return _upcomingBookings;
      case BookingTab.completed:
        return _completedBookings;
      case BookingTab.cancelled:
        return _cancelledBookings;
    }
  }

  // Filter state
  String _selectedCategory = 'Office Branches';
  String? _selectedCity = 'All'; // Default to 'All'
  int _selectedFiscalYear = 0; // 0 = All years

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
    if (branchName == null || branchName == 'All') return null;
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

    // Get branch ID from selected branch, defaulting to '0' if 'All' is selected
    final branchId = _getBranchIdFromName(_selectedCity) ?? '0';

    // If branch is selected, update it in storage
    if (branchId != '0') {
      await StorageServices.instance.save('branchId', branchId);
    }
    await StorageServices.instance.save('branchId', branchId);

    // Fetch booking history with filters (status = -1 to get ALL, then filter on frontend)
    final criteria = _filterSearchController.text.trim();
    await _fetchBookings(
      branchId: branchId,
      monthId: 0,
      providerId: 0,
      fiscalYear: _selectedFiscalYear,
      criteria: criteria,
    );
  }

  /// Fetch bookings from API and store in _allBookings, then filter based on selected tab
  Future<void> _fetchBookings({
    String? branchId,
    int? monthId,
    int providerId = 0,
    int fiscalYear = 0,
    String criteria = '',
  }) async {
    // Fetch with status = -1 (ALL) to get all bookings
    await _controller.fetchBookingHistory(
      context,
      branchId: branchId ?? '0',
      monthId: monthId ?? 0,
      providerId: providerId,
      fiscalYear: fiscalYear,
      criteria: criteria,
      status: BookingStatus.all, // Fetch all statuses (-1)
    );

    // Update _allBookings with fetched data
    _allBookings.assignAll(_controller.bookings);
    _rebuildAndSortTabLists();
    
    // Mark that data has been loaded
    _hasLoadedData = true;
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
      // Fetch fiscal years for filter
      await _fiscalYearController.fetchFiscalYears(context);
      // Fetch feedback questions status
      await _feedbackController.fetchFeedbackQuestions(context);
      // Fetch with saved or default values
      await _loadAndFetchBookings();
    });
  }

  Future<void> _loadSavedFilters() async {
    final savedCity =
        await StorageServices.instance.read('filter_selected_city');
    _selectedCity = savedCity ?? 'All'; // Default to 'All' if nothing is saved

    final savedFiscal =
        await StorageServices.instance.read('filter_selected_fiscal_year');
    _selectedFiscalYear = int.tryParse(savedFiscal?.toString() ?? '') ?? 0;
  }

  Future<void> _saveFilters() async {
    if (_selectedCity != null) {
      await StorageServices.instance
          .save('filter_selected_city', _selectedCity!);
    }
    await StorageServices.instance
        .save('filter_selected_fiscal_year', _selectedFiscalYear.toString());
  }

  Future<void> _loadAndFetchBookings() async {
    final branchId = _getBranchIdFromName(_selectedCity) ?? '0';
    final criteria = _filterSearchController.text.trim();

    await _fetchBookings(
      branchId: branchId,
      monthId: 0,
      providerId: 0,
      fiscalYear: _selectedFiscalYear,
      criteria: criteria,
    );
  }

  /// Handle tab change - reset pagination and filter data
  void _onTabChanged(BookingTab tab) {
    _selectedTab.value = tab;
    // Data is already filtered via _filteredBookings getter
    // No need to refetch, just update UI
  }

  /// Get empty state message based on selected tab
  String _getEmptyStateMessage() {
    switch (_selectedTab.value) {
      case BookingTab.confirmed:
        return 'No upcoming bookings found';
      case BookingTab.completed:
        return 'No completed bookings found';
      case BookingTab.cancelled:
        return 'No cancelled bookings found';
    }
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

  /// Extract numeric booking ID from booking number
  /// Example: "WTI-DEL20260102-3518818" -> "3518818"
  String? _extractNumericBookingId(CrpBookingHistoryItem booking) {
    // Try bookingNo first (e.g., "WTI-DEL20260102-3518818")
    if (booking.bookingNo != null && booking.bookingNo!.isNotEmpty) {
      final parts = booking.bookingNo!.split('-');
      if (parts.isNotEmpty) {
        // Get the last part after the last hyphen
        final lastPart = parts.last;
        // Check if it's numeric
        if (RegExp(r'^\d+$').hasMatch(lastPart)) {
          return lastPart;
        }
      }
    }
    
    // Fallback to bookingId or id if available
    if (booking.bookingId != null) {
      return booking.bookingId.toString();
    }
    if (booking.id != null) {
      return booking.id.toString();
    }
    
    return null;
  }

  /// Download DutySlip PDF and open it directly in PDF viewer
  Future<void> _downloadDutySlip(CrpBookingHistoryItem booking) async {
    try {
      // Extract numeric booking ID from booking number
      final numericBookingId = _extractNumericBookingId(booking);
      
      if (numericBookingId == null || numericBookingId.isEmpty) {
        if (mounted) {
          CustomFailureSnackbar.show(context, 'Booking ID not found');
        }
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopupLoader(message: 'Downloading DutySlip...'),
      );

      // Construct invoice URL with extracted numeric booking ID
      final invoiceUrl = 'http://office.aaveg.co.in/Mt/PrintFullDS_Digital?BookingID=$numericBookingId';

      // Request storage permissions (for Android)
      if (Platform.isAndroid) {
        // Android 13+ → use these new permissions
        if (await Permission.photos.isDenied) {
          await Permission.photos.request();
        }
        if (await Permission.videos.isDenied) {
          await Permission.videos.request();
        }
        // Older Android (for writing to /storage/emulated/0/Download)
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
      }

      // Determine download directory
      // Use app's external storage directory (works on all Android versions including 13+)
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
        if (dir != null) {
          // Create Downloads subfolder in app's external storage for better organization
          dir = Directory('${dir.path}/Download');
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        if (mounted) {
          GoRouter.of(context).pop(); // Close loader
          CustomFailureSnackbar.show(context, 'Could not access download directory');
        }
        return;
      }

      // Download the PDF
      final uri = Uri.parse(invoiceUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Ensure directory exists before saving
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        // Save the PDF file
        final fileName = 'dutyslip_$numericBookingId.pdf';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes);

        // Close loader dialog
        if (mounted) {
          GoRouter.of(context).pop();
        }

        // Open the PDF file directly in PDF viewer
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done && mounted) {
          CustomSuccessSnackbar.show(context, 'PDF saved to ${dir.path}. Opening...');
        }
      } else if (response.statusCode == 500) {
        if (mounted) {
          GoRouter.of(context).pop(); // Close loader
          CustomFailureSnackbar.show(context, 'The booking is still in progress. The DutySlip will be available once the trip is completed.');
        }
      } else {
        if (mounted) {
          GoRouter.of(context).pop(); // Close loader
          CustomFailureSnackbar.show(context, 'Failed to download DutySlip. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        GoRouter.of(context).pop(); // Close loader
        CustomFailureSnackbar.show(context, 'Error downloading DutySlip: ${e.toString()}');
      }
    }
  }

  /// Download Invoice PDF and open it directly in PDF viewer
  /// Uses: http://office.aaveg.co.in/Mt/PrintAsPDF_F7?bid=$bookingId
  Future<void> _downloadInvoice(CrpBookingHistoryItem booking) async {
    try {
      final numericBookingId = _extractNumericBookingId(booking);

      if (numericBookingId == null || numericBookingId.isEmpty) {
        if (mounted) {
          CustomFailureSnackbar.show(context, 'Booking ID not found');
        }
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopupLoader(message: 'Downloading Invoice...'),
      );

      final invoiceUrl =
          'http://office.aaveg.co.in/Mt/PrintAsPDF_F7?bid=$numericBookingId';

      // Request storage permissions (for Android)
      if (Platform.isAndroid) {
        // Android 13+ → use these new permissions
        if (await Permission.photos.isDenied) {
          await Permission.photos.request();
        }
        if (await Permission.videos.isDenied) {
          await Permission.videos.request();
        }
        // Older Android (for writing to /storage/emulated/0/Download)
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
      }

      // Determine download directory
      // Use app's external storage directory (works on all Android versions including 13+)
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
        if (dir != null) {
          // Create Downloads subfolder in app's external storage for better organization
          dir = Directory('${dir.path}/Download');
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        if (mounted) {
          GoRouter.of(context).pop(); // Close loader
          CustomFailureSnackbar.show(context, 'Could not access download directory');
        }
        return;
      }

      final uri = Uri.parse(invoiceUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final fileName = 'invoice_$numericBookingId.pdf';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          GoRouter.of(context).pop();
        }

        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done && mounted) {
          CustomSuccessSnackbar.show(context, 'PDF saved to ${dir.path}. Opening...');
        }
      } else if (response.statusCode == 500) {
        if (mounted) {
          GoRouter.of(context).pop(); // Close loader
          CustomFailureSnackbar.show(context, 'The booking is still in progress. The invoice will be available once the trip is completed.');
        }
      } else {
        if (mounted) {
          GoRouter.of(context).pop(); // Close loader
          CustomFailureSnackbar.show(context, 'Failed to download invoice. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        GoRouter.of(context).pop(); // Close loader
        CustomFailureSnackbar.show(context, 'Error downloading invoice: ${e.toString()}');
      }
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
          // Show loader if loading OR if data hasn't been loaded yet
          if (_controller.isLoading.value || !_hasLoadedData) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => _loadAndFetchBookings(),
            child: Column(
              children: [
                // Tabs - Confirmed, Completed, Cancelled
                _buildTabBar(),
                // Filters Button - Always visible
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 0.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showFilterBottomSheet(context),
                        child:
                            _buildFilterButton('Filters', Icons.tune_outlined),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                // Content: Either empty state or bookings list
                Expanded(
                  child: Obx(() {
                    final filteredBookings = _filteredBookings;
                    final emptyMessage = _getEmptyStateMessage();
                    return filteredBookings.isEmpty
                        ? Center(
                            child: Text(
                              emptyMessage,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: filteredBookings.length,
                            itemBuilder: (context, index) {
                              final booking = filteredBookings[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildBookingCard(booking),
                              );
                            },
                          );
                  }),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Build tab bar for Confirmed, Completed, Cancelled
  /// Matches the exact design: white container with grey border, pill-shaped selected tab
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 19, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
            color: const Color(0x40000000),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Obx(() => _buildTabItem(
                    'Upcoming',
                    BookingTab.confirmed,
                    _selectedTab.value == BookingTab.confirmed,
                  )),
            ),
            Expanded(
              child: Obx(() => _buildTabItem(
                    'Completed',
                    BookingTab.completed,
                    _selectedTab.value == BookingTab.completed,
                  )),
            ),
            Expanded(
              child: Obx(() => _buildTabItem(
                    'Cancelled',
                    BookingTab.cancelled,
                    _selectedTab.value == BookingTab.cancelled,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual tab item
  /// Selected tab: blue pill-shaped background with white text
  /// Unselected tab: transparent background with grey text
  Widget _buildTabItem(String label, BookingTab tab, bool isSelected) {
    return GestureDetector(
      onTap: () => _onTabChanged(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4082F1) : Colors.transparent,
          borderRadius:
              BorderRadius.circular(20), // Pill-shaped for selected tab
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Color(0xFF939393),
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, IconData icon) {
    return Container(
      height: 30,
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.black,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down_outlined,
            size: 22,
            color: Color(0xFF1C1B1F),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedCity: _selectedCity,
        selectedFiscalYear: _selectedFiscalYear,
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
            _selectedCity = 'All';
            _selectedFiscalYear = 0;
          });
          // Reset tab to Confirmed (default)
          _selectedTab.value = BookingTab.confirmed;
          // Clear saved filters
          await StorageServices.instance.delete('filter_selected_city');
          await StorageServices.instance.delete('filter_selected_fiscal_year');

          // Clear search criteria text as well
          _filterSearchController.clear();

          Navigator.pop(context);
          // Reset to default values and fetch
          await _fetchBookings(
            branchId: '0',
            monthId: 0,
            providerId: 0,
            fiscalYear: 0,
            criteria: '',
          );
        },
      ),
    );
  }

  /// Build status badge with pill design and different colors/icons for each status
  Widget _buildStatusBadge(CrpBookingHistoryItem booking) {
    // Get effective status (handles Dispatched + Close -> Completed)
    final effectiveStatus = BookingStatus.getEffectiveStatus(booking);
    // Normalize status to handle case variations
    final normalizedStatus = effectiveStatus.trim().toLowerCase();

    // Define colors and icons for each status
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    IconData icon;

    if (normalizedStatus == 'confirmed') {
      backgroundColor = const Color(0xFFECFDD7); // Light green
      textColor = const Color(0xFF7CC521); // Dark green
      iconColor = const Color(0xFF7CC521);
      icon = Icons.check_circle_outline;
    } else if (normalizedStatus == 'allocated' ||
        normalizedStatus == 'completed') {
      backgroundColor = const Color(0xFFE3F2FD); // Light blue
      textColor = const Color(0xFF2196F3); // Dark blue
      iconColor = const Color(0xFF2196F3);
      icon = Icons.check_circle;
    } else if (normalizedStatus == 'cancelled' ||
        normalizedStatus == 'canceled') {
      backgroundColor = const Color(0xFFFFEBEE); // Light red/pink
      textColor = const Color(0xFFE91E63); // Dark pink/red
      iconColor = const Color(0xFFE91E63);
      icon = Icons.cancel;
    } else if (normalizedStatus == 'pending') {
      backgroundColor = const Color(0xFFFFF3E0); // Light orange
      textColor = const Color(0xFFFF9800); // Dark orange
      iconColor = const Color(0xFFFF9800);
      icon = Icons.access_time;
    } else if (normalizedStatus == 'dispatched') {
      backgroundColor = const Color(0xFFF3E5F5); // Light purple
      textColor = const Color(0xFF9C27B0); // Dark purple
      iconColor = const Color(0xFF9C27B0);
      icon = Icons.check_circle;
    } else if (normalizedStatus == 'missed') {
      backgroundColor = const Color(0xFFE0E0E0); // Light grey
      textColor = const Color(0xFF757575); // Dark grey
      iconColor = const Color(0xFF757575);
      icon = Icons.warning;
    } else if (normalizedStatus == 'void') {
      backgroundColor = const Color(0xFFE0E0E0); // Light grey
      textColor = const Color(0xFF757575); // Dark grey
      iconColor = const Color(0xFF757575);
      icon = Icons.block;
    } else {
      // Default for unknown statuses
      backgroundColor = const Color(0xFFF5F5F5); // Light grey
      textColor = const Color(0xFF757575); // Dark grey
      iconColor = const Color(0xFF757575);
      icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20), // Pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            effectiveStatus,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(width: 6),
          Center(
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
        ],
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
                        ],
                      ),
                      Text(
                        booking.model?.replaceAll(RegExp(r'\s*\[.*?\]'), '') ?? '-',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF939393),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge with pill design
                _buildStatusBadge(booking),
              ],
            ),
            const SizedBox(height: 16),
            // Middle Section: Route Visualization
            Builder(
              builder: (context) {
                final pickupAddress = booking.pickupAddress;
                final dropAddress = booking.dropAddress;
                // Only show pickup if it's not null, not empty (trimmed), and not the string "null"
                final hasPickupAddress = pickupAddress != null && 
                    pickupAddress.trim().isNotEmpty && 
                    pickupAddress.trim().toLowerCase() != 'null';
                // Only show drop if it's not null, not empty (trimmed), and not the string "null"
                final hasDropAddress = dropAddress != null && 
                    dropAddress.trim().isNotEmpty && 
                    dropAddress.trim().toLowerCase() != 'null';
                
                // Only show route visualization if at least one address exists
                if (!hasPickupAddress && !hasDropAddress) {
                  return const SizedBox.shrink();
                }
                
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vertical Line with Circle and Square
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: SizedBox(
                          width: 28,
                          child: Column(
                            children: [
                              // Circle with dot (pickup icon) - only show if pickup exists
                              if (hasPickupAddress)
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFA4FF59),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              // Vertical line (only show if both pickup and drop exist)
                              if (hasPickupAddress && hasDropAddress)
                                Expanded(
                                  child: CustomPaint(
                                    painter: VerticalDashedLinePainter(),
                                    child: const SizedBox(width: 2),
                                  ),
                                ),
                              // Square end (drop icon) - only show if drop exists and is not null
                              if (hasDropAddress)
                                Container(
                                  width: 15,
                                  height: 15,
                                  padding: EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB179),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(0.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Pickup and Drop Locations
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pickup Location - only show if pickup exists
                            if (hasPickupAddress && pickupAddress != null)
                              Text(
                                pickupAddress.trim(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F4F4F),
                                  fontFamily: 'Montserrat',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            // Drop Location - only show if drop exists and is not null or "null"
                            if (hasDropAddress && dropAddress != null) ...[
                              if (hasPickupAddress) const SizedBox(height: 16),
                              Text(
                                dropAddress.trim(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F4F4F),
                                  fontFamily: 'Montserrat',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
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
                      // Show Download buttons for completed statuses (Allocated, or Dispatched with Close status)
                      Builder(
                        builder: (context) {
                          final effectiveStatus = BookingStatus.getEffectiveStatus(booking).toLowerCase().trim();
                          if (effectiveStatus == 'allocated' || effectiveStatus == 'completed') {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 24,
                                  child: ElevatedButton(
                                    onPressed: () => _downloadDutySlip(booking),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDCEAFD), // bg color
                                      elevation: 0,
                                      padding: const EdgeInsets.all(5), // padding
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15), // border-radius
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset('assets/images/bookmark.png', width: 12, height: 12,),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Download DutySlip',
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                            color: Color(0xFF7B7B7B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 24,
                                  child: ElevatedButton(
                                    onPressed: () => _downloadInvoice(booking),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDCEAFD), // bg color
                                      elevation: 0,
                                      padding: const EdgeInsets.all(5), // padding
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15), // border-radius
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset('assets/images/bookmark.png', width: 12, height: 12,),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Download Invoice',
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                            color: Color(0xFF7B7B7B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
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
              // Show feedback button for Dispatched bookings (regardless of currentDispatchStatusId)
              final effectiveStatus = BookingStatus.getEffectiveStatus(booking).toLowerCase().trim();
              final showFeedbackButton = _feedbackController
                      .feedbackQuestionsResponse.value?.bStatus ==
                  true && (booking.status?.toLowerCase().trim() == 'dispatched');

              return Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Booking Detail',
                      () async {
                        // Store original booking ID for finding updated booking
                        final originalBookingId = booking.bookingId;
                        final originalBookingNo = booking.bookingNo;
                        
                        // Navigate to booking details screen
                        // Passes booking object which includes currentDispatchStatusId
                        // Also passes refresh callback to update parent list when refreshing
                        final result = await GoRouter.of(context).push<bool>(
                          AppRoutes.cprBookingDetails,
                          extra: {
                            'booking': booking,
                            'onRefreshParent': () async {
                              // Refresh booking list when details screen refreshes
                              await _loadAndFetchBookings();
                            },
                            'getUpdatedBooking': () async {
                              // Find and return the updated booking from the refreshed list
                              try {
                                final updatedBooking = _allBookings.firstWhere(
                                  (b) => 
                                    (originalBookingId != null && b.bookingId == originalBookingId) ||
                                    (originalBookingNo != null && b.bookingNo == originalBookingNo),
                                  orElse: () => booking, // Fallback to original booking if not found
                                );
                                return updatedBooking;
                              } catch (e) {
                                return booking; // Fallback to original booking on error
                              }
                            },
                          },
                        );
                        // If booking was modified or cancelled, refresh the booking list
                        // This ensures we fetch updated booking data after modification
                        if (result == true && mounted) {
                          // Add a small delay to ensure navigation is complete
                          await Future.delayed(const Duration(milliseconds: 100));
                          // Refresh booking data to show updated information
                          await _loadAndFetchBookings();
                        }
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

// Custom painter for vertical dashed line with dots
class VerticalDashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7B7B7B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    const dotHeight = 3.0;
    const dotSpacing = 4.0;
    final totalDotHeight = dotHeight + dotSpacing;
    
    // Calculate number of dots based on available height
    final numberOfDots = (size.height / totalDotHeight).floor().clamp(3, 50);
    
    // Center the dots vertically
    final totalDotsHeight = numberOfDots * totalDotHeight - dotSpacing;
    final startY = (size.height - totalDotsHeight) / 2;
    
    // Draw dots
    for (int i = 0; i < numberOfDots; i++) {
      final y = startY + (i * totalDotHeight);
      canvas.drawCircle(
        Offset(size.width / 2, y),
        dotHeight / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Filter Bottom Sheet Widget
class _FilterBottomSheet extends StatefulWidget {
  final String selectedCategory;
  final String? selectedCity;
  final int selectedFiscalYear;
  final TextEditingController searchController;
  final Function(String) onCategoryChanged;
  final Function(String) onCityChanged;
  final Function(int) onFiscalYearChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    required this.selectedCategory,
    required this.selectedCity,
    required this.selectedFiscalYear,
    required this.searchController,
    required this.onCategoryChanged,
    required this.onCityChanged,
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
  late int _currentFiscalYear;
  final CrpBranchListController _branchController =
      Get.find<CrpBranchListController>();
  final CrpFiscalYearController _fiscalYearController =
      Get.find<CrpFiscalYearController>();

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.selectedCategory;
    // Set default selected city from widget, defaulting to 'All'
    _currentCity = widget.selectedCity ?? 'All';
    _currentFiscalYear = widget.selectedFiscalYear;
    _fetchBranches();
    if (_fiscalYearController.years.isEmpty) {
      // Safe to call again; controller caches results in-memory.
      _fiscalYearController.fetchFiscalYears(context);
    }
  }

  Future<void> _fetchBranches() async {
    final corpId = await StorageServices.instance.read('crpId');
    if (corpId != null && corpId.isNotEmpty) {
      await _branchController.fetchBranches(corpId);
      // After fetching, set default to 'All' if not already set
      if (_currentCity == null) {
        setState(() {
          _currentCity = 'All';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.55,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
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
          // Main Content - Grid Layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fiscal Year
                    const Text(
                      'Fiscal Year',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFiscalYearOptions(),
                    const SizedBox(height: 20),

                    // Office Branches Label
                    const Text(
                      'Office Branches',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Grid of Branch Buttons
                    _buildFilterOptions(),
                  ],
                ),
              ),
            ),
          ),
          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
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
                        widget.onCityChanged(_currentCity ?? 'All');
                        widget.onFiscalYearChanged(_currentFiscalYear);
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
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: const Color(0xFF4082F1),
                        width: 1,
                      ),
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _currentCity = 'All';
                          _currentFiscalYear = 0;
                        });
                        widget.onFiscalYearChanged(0);
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
    return Obx(() {
      if (_branchController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      // Create a list with 'All' at the beginning, followed by branch names
      final List<String> branchList = ['All', ..._branchController.branchNames];

      if (branchList.isEmpty) {
        return const Center(
          child: Text(
            'No branches available',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF939393),
              fontFamily: 'Montserrat',
            ),
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
        ),
        itemCount: branchList.length,
        itemBuilder: (context, index) {
          final branchName = branchList[index];
          return _buildBranchButton(branchName, branchName);
        },
      );
    });
  }

  Widget _buildFiscalYearOptions() {
    return Obx(() {
      if (_fiscalYearController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Static "All" (0) + dynamic years from API (e.g. 2025, 2026)
      final List<int> options = [0, ..._fiscalYearController.years];

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: options.map((year) {
          final label = year == 0 ? 'All' : year.toString();
          return _buildFiscalYearChip(label, year);
        }).toList(),
      );
    });
  }

  Widget _buildFiscalYearChip(String label, int value) {
    final isSelected = _currentFiscalYear == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFiscalYear = value;
        });
        widget.onFiscalYearChanged(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4082F1) : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF484848),
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildBranchButton(String label, String value) {
    final isSelected = _currentCity == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentCity = value;
        });
        widget.onCityChanged(value);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4082F1)
              : const Color(0xFFE8E8E8), // Light grey background
          borderRadius: BorderRadius.circular(36),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF484848), // Dark grey text for unselected
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildCarProviderRadioOption(String label, String value) {
  //   final isSelected = _currentCarProvider == value;
  //   return InkWell(
  //     onTap: () {
  //       setState(() {
  //         _currentCarProvider = value;
  //       });
  //       widget.onCarProviderChanged(value);
  //     },
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 20,
  //           height: 20,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             border: Border.all(
  //               color: isSelected
  //                   ? const Color(0xFF4082F1)
  //                   : const Color(0xFF939393),
  //               width: 2,
  //             ),
  //           ),
  //           child: isSelected
  //               ? Center(
  //                   child: Container(
  //                     width: 12,
  //                     height: 12,
  //                     decoration: const BoxDecoration(
  //                       shape: BoxShape.circle,
  //                       color: Color(0xFF4082F1),
  //                     ),
  //                   ),
  //                 )
  //               : null,
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Text(
  //             label,
  //             style: const TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w400,
  //               color: Color(0xFF333333),
  //               fontFamily: 'Montserrat',
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
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
  final CrpFeedbackQuestionsController _feedbackController =
      Get.put(CrpFeedbackQuestionsController());

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
    final questionId =
        _feedbackController.feedbackQuestionsResponse.value?.noOfQuestions ??
            _feedbackController.feedbackQuestions.length;

    if (guestId == 0) {
      CustomFailureSnackbar.show(context, 'Guest ID not found', duration: const Duration(seconds: 2));
      return;
    }

    if (orderId == 0) {
      CustomFailureSnackbar.show(context, 'Order ID not found', duration: const Duration(seconds: 2));
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
