import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/booking_details_final/booking_details_final.dart';
import 'package:wti_cabs_user/screens/booking_ride/booking_ride.dart';
import 'package:wti_cabs_user/screens/bottom_nav/bottom_nav.dart';
import 'package:wti_cabs_user/screens/home/home_screen.dart';
import 'package:wti_cabs_user/screens/inventory_list_screen/inventory_list.dart';
import 'package:wti_cabs_user/screens/manage_bookings/manage_bookings.dart';
import 'package:wti_cabs_user/screens/map_picker/map_picker.dart';
import 'package:wti_cabs_user/screens/offers/offers.dart';
import 'package:wti_cabs_user/screens/payment_status/payment_failure.dart';
import 'package:wti_cabs_user/screens/payment_status/payment_success.dart';
import 'package:wti_cabs_user/screens/profile/profile.dart';
import 'package:wti_cabs_user/screens/select_currency/select_currency.dart';
import 'package:wti_cabs_user/screens/select_location/airport/airport_select_pickup.dart';
import 'package:wti_cabs_user/screens/select_location/select_drop.dart';
import 'package:wti_cabs_user/screens/select_location/select_pickup.dart';
import 'package:wti_cabs_user/screens/splash_screen.dart';
import 'package:wti_cabs_user/screens/walkthrough/walkthrough.dart';
import '../../main.dart';
import '../../screens/cancel_screen/cancel_booking_screen.dart';
import '../../screens/cancel_screen/cancelled booking.dart';
import '../../screens/contact/contact.dart';

class AppPages {
  static Page _platformPage(Widget child) {
    if (Platform.isIOS) {
      return CupertinoPage(child: child);
    }
    return MaterialPage(child: child);
  }

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(
        path: AppRoutes.initialPage,
        pageBuilder: (context, state) => _platformPage(SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.walkthrough,
        pageBuilder: (context, state) => _platformPage(Walkthrough()),
      ),
      GoRoute(
        path: AppRoutes.bottomNav,
        pageBuilder: (context, state) => _platformPage(BottomNavScreen()),
      ),

      GoRoute(
        path: AppRoutes.bookingRide,
        pageBuilder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return _platformPage(BookingRide(initialTab: tab));
        },
      ),
      GoRoute(
        path: AppRoutes.choosePickup,
        pageBuilder: (context, state) => _platformPage(SelectPickup()),
      ),
      GoRoute(
        path: AppRoutes.chooseDrop,
        pageBuilder: (context, state) => _platformPage(SelectDrop()),
      ),
      GoRoute(
        path: AppRoutes.airportChoosePick,
        pageBuilder: (context, state) => _platformPage(AirportSelectPickup()),
      ),
      GoRoute(
        path: AppRoutes.airportChooseDrop,
        pageBuilder: (context, state) => _platformPage(AirportSelectPickup()),
      ),
      GoRoute(
        path: AppRoutes.inventoryList,
        pageBuilder: (context, state) {
          final requestData = state.extra as Map<String, dynamic>;
          return _platformPage(InventoryList(requestData: requestData));
        },
      ),
      GoRoute(
        path: AppRoutes.bookingDetailsFinal,
        pageBuilder: (context, state) => _platformPage(BookingDetailsFinal()),
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        pageBuilder: (context, state) => _platformPage(PaymentSuccessPage()),
      ),
      GoRoute(
        path: AppRoutes.paymentFailure,
        pageBuilder: (context, state) {
          final Map<String, dynamic>? provisionalData =
          state.extra as Map<String, dynamic>?;
          return _platformPage(PaymentFailurePage(provisionalData: provisionalData));
        },
      ),
      GoRoute(
        path: AppRoutes.offers,
        pageBuilder: (context, state) => _platformPage(Offers()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => _platformPage(Profile()),
      ),
      GoRoute(
        path: AppRoutes.manageBookings,
        pageBuilder: (context, state) => _platformPage(ManageBookings()),
      ),
      GoRoute(
        path: AppRoutes.cancelBooking,
        pageBuilder: (context, state) {
          final bookingMap = state.extra as Map<String, dynamic>;
          return _platformPage(CancelBookingScreen(booking: bookingMap));
        },
      ),
      GoRoute(
        path: AppRoutes.cancelledBooking,
        pageBuilder: (context, state) {
          final bookingMap = state.extra as Map<String, dynamic>;
          return _platformPage(CancelledBookingScreen(booking: bookingMap));
        },
      ),
      GoRoute(
        path: AppRoutes.selectCurrency,
        pageBuilder: (context, state) => _platformPage(SelectCurrencyScreen()),
      ),
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _platformPage(SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.contact,
        pageBuilder: (context, state) => _platformPage(Contact()),
      ),
    ],
  );
}
