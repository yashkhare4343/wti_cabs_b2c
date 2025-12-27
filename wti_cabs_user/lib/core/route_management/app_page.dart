import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/booking_details_final/booking_details_final.dart';
import 'package:wti_cabs_user/screens/booking_ride/booking_ride.dart';
import 'package:wti_cabs_user/screens/bottom_nav/bottom_nav.dart';
import 'package:wti_cabs_user/screens/corporate/corporate_landing_page/corporate_landing_page.dart';
import 'package:wti_cabs_user/screens/corporate/corporate_login/cpr_login.dart';
import 'package:wti_cabs_user/screens/corporate/crp_inventory/crp_inventory.dart';
import 'package:wti_cabs_user/screens/corporate/crp_register/crp_register.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_car_models/crp_car_models_response.dart';
import 'package:wti_cabs_user/screens/inventory_list_screen/inventory_list.dart';
import 'package:wti_cabs_user/screens/manage_bookings/manage_bookings.dart';
import 'package:wti_cabs_user/screens/map_picker/map_picker.dart';
import 'package:wti_cabs_user/screens/my_account/my_account.dart';
import 'package:wti_cabs_user/screens/offers/offers.dart';
import 'package:wti_cabs_user/screens/payment_status/payment_failure.dart';
import 'package:wti_cabs_user/screens/payment_status/payment_success.dart';
import 'package:wti_cabs_user/screens/profile/profile.dart';
import 'package:wti_cabs_user/screens/select_currency/select_currency.dart';
import 'package:wti_cabs_user/screens/select_location/airport/airport_select_pickup.dart';
import 'package:wti_cabs_user/screens/select_location/select_drop.dart';
import 'package:wti_cabs_user/screens/select_location/select_pickup.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_all_inventory/self_drive_all_inventory.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_bottom_nav/bottom_nav.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_cancel_screen/self_drive_cancel_screen.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_final_page_st1/self_drive_final_page_s1.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_home/self_drive_home_screen.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_payment_status/self_drive_payment_success.dart';
import 'package:wti_cabs_user/screens/walkthrough/walkthrough.dart';
import '../../main.dart';
import '../../screens/cancel_screen/cancel_booking_screen.dart';
import '../../screens/cancel_screen/cancelled booking.dart';
import '../../screens/contact/contact.dart';
import '../../screens/corporate/cpr_profile_response/cpr_profile_response.dart';
import '../../screens/corporate/crp_booking_engine/crp_booking_engine.dart';
import '../../screens/corporate/crp_home_screen/crp_home_screen.dart';
import '../../screens/corporate/select_drop/crp_select_drop.dart';
import '../../screens/corporate/select_drop/crp_drop_search_screen.dart';
import '../../screens/corporate/select_pickup/crp_select_pickup.dart';
import '../../screens/corporate/select_pickup/crp_pickup_search_screen.dart';
import '../../screens/corporate/crp_booking_confirmation/crp_booking_confirmation.dart';
import '../../screens/corporate/crp_booking_details/crp_booking_details.dart';
import '../../screens/corporate/cpr_modify_booking/cpr_modify_booking.dart';
import '../../screens/corporate/corporate_bottom_nav/corporate_bottom_nav.dart';
import '../../screens/corporate/cpr_redirect_screen/cpr_redirect_screen.dart';
import '../../screens/corporate/crp_edit_profile/crp_edit_profile.dart';
import '../../screens/corporate/crp_edit_profile/crp_edit_profile_form.dart';
import '../../screens/corporate/cpr_change_password/cpr_change_password.dart';
import '../../screens/select_location/airport/airport_select_drop.dart';
import '../../screens/self_drive/self_drive_payment_failure/self_drive_payment_failure.dart';
import '../model/corporate/crp_booking_data/crp_booking_data.dart';
import '../model/corporate/crp_booking_history/crp_booking_history_response.dart';
import '../model/booking_engine/suggestions_places_response.dart';

class AppPages {
  static Page _platformPage(Widget child) {
    return Platform.isIOS ? CupertinoPage(child: child) : MaterialPage(child: child);
  }

  // ✅ All app routes
  static final List<GoRoute> routeList = [
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
      pageBuilder: (context, state) => _platformPage(AirportSelectDrop()),
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
      path: AppRoutes.contact,
      pageBuilder: (context, state) => _platformPage(Contact()),
    ),
    GoRoute(
      path: AppRoutes.selfDriveHome,
      pageBuilder: (context, state) => _platformPage(SelfDriveHomeScreen()),
    ),
    GoRoute(
      path: AppRoutes.selfDriveAllInventory,
      pageBuilder: (context, state) => _platformPage(SelfDriveAllInventory()),
    ),
    GoRoute(
      path: AppRoutes.selfDriveFinalPageS1,
      pageBuilder: (context, state) => _platformPage(SelfDriveFinalPageS1()),
    ),
    GoRoute(
      path: AppRoutes.selfDrivePaymentSuccess,
      builder: (context, state) => SelfDrivePaymentSuccessPage(),
    ),
    GoRoute(
      path: AppRoutes.selfDrivePaymentFailure,
      builder: (context, state) => PaymentReservationFailure(),
    ),
    GoRoute(
      path: AppRoutes.selfDriveBottomSheet,
      builder: (context, state) => SelfDriveBottomNavScreen(),
    ),
    GoRoute(
      path: AppRoutes.selfDriveCancelBooking,
      pageBuilder: (context, state) {
        final orderRefNo = state.extra as Map<String, dynamic>;
        return _platformPage(SelfDriveCancelBookingScreen(orderRefNo: orderRefNo));
      },
    ),
    GoRoute(
      path: AppRoutes.myAccount,
      pageBuilder: (context, state) => _platformPage(MyAccount()),
    ),
    GoRoute(
      path: AppRoutes.cprRedirect,
      pageBuilder: (context, state) => _platformPage(const CprRedirectScreen()),
    ),
    GoRoute(
      path: AppRoutes.cprLogin,
      pageBuilder: (context, state) => _platformPage(CprLogin()),
    ),
    GoRoute(
      path: AppRoutes.cprRegister,
      pageBuilder: (context, state) => _platformPage(CprRegister()),
    ),
    GoRoute(
      path: AppRoutes.cprHomeScreen,
      pageBuilder: (context, state) => _platformPage(CprHomeScreen()),
    ),
    GoRoute(
      path: AppRoutes.cprBookingEngine,
      pageBuilder: (context, state) {
        // Handle both String (legacy) and Map (with selected place) formats
        final extra = state.extra;
        String? selectedPickupType;
        Map<String, dynamic>? selectedPickupPlaceJson;
        Map<String, dynamic>? selectedDropPlaceJson;
        
        if (extra is Map<String, dynamic>) {
          selectedPickupType = extra['selectedPickupType'] as String?;
          selectedPickupPlaceJson = extra['selectedPickupPlace'] as Map<String, dynamic>?;
          selectedDropPlaceJson = extra['selectedDropPlace'] as Map<String, dynamic>?;
        } else if (extra is String) {
          selectedPickupType = extra;
        }
        
        SuggestionPlacesResponse? selectedPickupPlace;
        if (selectedPickupPlaceJson != null) {
          try {
            selectedPickupPlace = SuggestionPlacesResponse.fromJson(selectedPickupPlaceJson);
          } catch (e) {
            // If parsing fails, continue without the place
            print('Error parsing selectedPickupPlace: $e');
          }
        }
        
        SuggestionPlacesResponse? selectedDropPlace;
        if (selectedDropPlaceJson != null) {
          try {
            selectedDropPlace = SuggestionPlacesResponse.fromJson(selectedDropPlaceJson);
          } catch (e) {
            // If parsing fails, continue without the place
            print('Error parsing selectedDropPlace: $e');
          }
        }
        
        return _platformPage(CprBookingEngine(
          selectedPickupType: selectedPickupType,
          selectedPickupPlace: selectedPickupPlace,
          selectedDropPlace: selectedDropPlace,
        ));
      },
    ),
    GoRoute(
      path: AppRoutes.cprSelectPickup,
      pageBuilder: (context, state) {
        final selectedPickupType = state.extra as String?;
        return _platformPage(CrpSelectPickupScreen(selectedPickupType: selectedPickupType));
      },
    ),
    GoRoute(
      path: AppRoutes.cprPickupSearch,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final selectedPickupType = extra?['selectedPickupType'] as String?;
        return _platformPage(CrpPickupSearchScreen(selectedPickupType: selectedPickupType));
      },
    ),
    GoRoute(
      path: AppRoutes.cprSelectDrop,
      pageBuilder: (context, state) {
        final selectedPickupType = state.extra as String?;
        return _platformPage(CrpSelectDropScreen(selectedPickupType: selectedPickupType));
      },
    ),
    GoRoute(
      path: AppRoutes.cprDropSearch,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final selectedPickupType = extra?['selectedPickupType'] as String?;
        return _platformPage(CrpDropSearchScreen(selectedPickupType: selectedPickupType));
      },
    ),
    GoRoute(
      path: AppRoutes.cprInventory,
      pageBuilder: (context, state) {
        final bookingData = state.extra as Map<String, dynamic>?;
        return _platformPage(CrpInventory(bookingData: bookingData));
      },
    ),
    GoRoute(
      path: AppRoutes.cprBookingConfirmation,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final carModelJson = extra?['carModel'] as Map<String, dynamic>?;
        final bookingData = extra?['bookingData'] as Map<String, dynamic>?;
        return _platformPage(
          CrpBookingConfirmation(
            selectedCar: carModelJson != null ? CrpCarModel.fromJson(carModelJson) : null,
            bookingData: bookingData != null ? CrpBookingData.fromJson(bookingData) : null,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.cprBookingDetails,
      pageBuilder: (context, state) {
        final booking = state.extra as CrpBookingHistoryItem;
        return _platformPage(CrpBookingDetails(booking: booking));
      },
    ),
    GoRoute(
      path: AppRoutes.cprModifyBooking,
      pageBuilder: (context, state) {
        final extra = state.extra;
        String orderId = '';
        String? carModelName;
        
        if (extra is String) {
          orderId = extra;
        } else if (extra is Map<String, dynamic>) {
          orderId = extra['orderId'] as String? ?? '';
          carModelName = extra['carModelName'] as String?;
        } else {
          orderId = state.uri.queryParameters['orderId'] ?? '';
          carModelName = state.uri.queryParameters['carModelName'];
        }
        
        return _platformPage(CprModifyBooking(
          orderId: orderId,
          initialCarModelName: carModelName,
        ));
      },
    ),
    GoRoute(
      path: AppRoutes.cprBottomNav,
      pageBuilder: (context, state) => _platformPage(CorporateBottomNavScreen()),
    ),
    GoRoute(
      path: AppRoutes.cprLandingPage,
      pageBuilder: (context, state) => _platformPage(CorporateLandingPage()),
    ),
    GoRoute(
      path: AppRoutes.cprEditProfile,
      pageBuilder: (context, state) => _platformPage(const CrpEditProfile()),
    ),
    GoRoute(
      path: AppRoutes.cprEditProfileForm,
      pageBuilder: (context, state) {
        final extraData = state.extra as Map<String, dynamic>?;
        final profile = extraData?['profile'] as CprProfileResponse?;
        final email = extraData?['email'] as String?;
        final token = extraData?['token'] as String?;
        final guestID = extraData?['guestID'] as int?;
        return _platformPage(CrpEditProfileForm(
          profile: profile,
          email: email,
          token: token,
          guestID: guestID,
        ));
      },
    ),
    GoRoute(
      path: AppRoutes.cprChangePassword,
      pageBuilder: (context, state) => _platformPage(const CprChangePassword()),
    ),
  ];

  // ✅ Router with configurable initial location
  static GoRouter routerWithInitial(String initialLocation) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: initialLocation,
      routes: routeList,
    );
  }
}
