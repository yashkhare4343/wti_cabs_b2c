import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_booking_history_controller/crp_booking_history_controller.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_booking_history/crp_booking_history_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../corporate_bottom_nav/corporate_bottom_nav.dart';
import '../../../common_widget/buttons/outline_button.dart';
import '../../../core/services/storage_services.dart';
import '../../../core/controller/corporate/crp_login_controller/crp_login_controller.dart';

class CrpBooking extends StatefulWidget {
  const CrpBooking({super.key});

  @override
  State<CrpBooking> createState() => _CrpBookingState();
}

class _CrpBookingState extends State<CrpBooking> {
  final TextEditingController _searchController = TextEditingController();
  final CrpBookingHistoryController _controller =
      Get.put(CrpBookingHistoryController());
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        // Search Bar
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFFD9D9D9),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search previous bookings',
                              hintStyle: TextStyle(
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
                            onChanged: (value) {
                              // Search can be wired up later
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Filters and Sort Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildFilterButton('Filters', Icons.filter_list),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilterButton('Sort', Icons.sort),
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

  Widget _buildBookingCard(CrpBookingHistoryItem booking) {
    final bool isConfirmed = booking.status == 'Confirmed';

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image and Service Type Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/inventory_car.png',
                    width: 84,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 84,
                        height: 64,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF002CC0),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isConfirmed
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 16,
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
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Route Visualization
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vertical Line with Circle and Square
                Column(
                  children: [
                    // Circle at top
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF002CC0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Vertical Line
                    Container(
                      width: 2,
                      height: 35,
                      color: const Color(0xFF002CC0),
                    ),
                    // Square at bottom
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF002CC0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Pickup and Drop Locations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup Location
                      Text(
                        'Passenger: ${booking.passenger ?? '-'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontFamily: 'Montserrat',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Drop Location
                      Text(
                        'Cab Required: ${booking.cabRequiredOn ?? '-'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontFamily: 'Montserrat',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Driver Details Link
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to driver details
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Driver Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF002CC0),
                        fontFamily: 'Montserrat',
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Booking ID and Date
            Wrap(
              children: [
                Text(
                  'Booking No ${booking.bookingNo ?? booking.bookingId ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Status: ${booking.status ?? '-'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Montserrat',
                  ),
                ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Feedback',
                    () {
                      // Handle feedback
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
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
            color: Color(0xFF002CC0),
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }
}
