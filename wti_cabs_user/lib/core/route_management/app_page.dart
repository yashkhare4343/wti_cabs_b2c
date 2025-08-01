import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/booking_details_final/booking_details_final.dart';
import 'package:wti_cabs_user/screens/booking_ride/booking_ride.dart';
import 'package:wti_cabs_user/screens/bottom_nav/bottom_nav.dart';
import 'package:wti_cabs_user/screens/home/home_screen.dart';
import 'package:wti_cabs_user/screens/inventory_list_screen/inventory_list.dart';
import 'package:wti_cabs_user/screens/offers/offers.dart';
import 'package:wti_cabs_user/screens/payment_status/payment_failure.dart';
import 'package:wti_cabs_user/screens/payment_status/payment_success.dart';
import 'package:wti_cabs_user/screens/profile/profile.dart';
import 'package:wti_cabs_user/screens/select_location/airport/airport_select_pickup.dart';
import 'package:wti_cabs_user/screens/select_location/select_drop.dart';
import 'package:wti_cabs_user/screens/select_location/select_pickup.dart';

import '../../main.dart';

class AppPages{
   static final GoRouter router = GoRouter(
      navigatorKey: navigatorKey,
      routes: [
         GoRoute(
           path: AppRoutes.initialPage,
           builder: (context, state) => BottomNavScreen(),
         ),
        GoRoute(
          path: AppRoutes.bookingRide,
          builder: (context, state) => BookingRide(),
        ),
        GoRoute(
          path: AppRoutes.choosePickup,
          builder: (context, state) => SelectPickup(),
        ),
        GoRoute(
          path: AppRoutes.chooseDrop,
          builder: (context, state) => SelectDrop(),
        ),
        GoRoute(
          path: AppRoutes.airportChoosePick,
          builder: (context, state) => AirportSelectPickup(),
        ),
        GoRoute(
          path: AppRoutes.airportChooseDrop,
          builder: (context, state) => AirportSelectPickup(),
        ),
        GoRoute(
          path: AppRoutes.inventoryList,
          builder: (context, state) => InventoryList(),
        ),
        GoRoute(
          path: AppRoutes.bookingDetailsFinal,
          builder: (context, state) => BookingDetailsFinal(),
        ),
        GoRoute(
          path: AppRoutes.paymentSuccess,
          builder: (context, state) => PaymentSuccessPage(),
        ),
        GoRoute(
          path: AppRoutes.paymentFailure,
          builder: (context, state) => PaymentFailurePage(),
        ),
        GoRoute(
          path: AppRoutes.offers,
          builder: (context, state) => Offers(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => Profile(),
        ),
      ],
   );
}