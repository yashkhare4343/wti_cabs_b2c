import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/booking_ride/booking_ride.dart';
import 'package:wti_cabs_user/screens/home/home_screen.dart';
import 'package:wti_cabs_user/screens/select_location/select_drop.dart';
import 'package:wti_cabs_user/screens/select_location/select_pickup.dart';

import '../../main.dart';

class AppPages{
   static final GoRouter router = GoRouter(
      navigatorKey: navigatorKey,
      routes: [
         GoRoute(
           path: AppRoutes.initialPage,
           builder: (context, state) => HomeScreen(),
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
      ],
   );
}