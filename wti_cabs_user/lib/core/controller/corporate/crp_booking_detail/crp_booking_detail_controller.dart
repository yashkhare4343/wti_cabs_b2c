import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/corporate/cpr_api_services.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_booking_details_response/booking_details_response.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_driver_details/crp_driver_details_response.dart';
import 'package:wti_cabs_user/core/model/profile/profile_response.dart';

class CrpBookingDetailsController extends GetxController {
  var isLoading = false.obs;
  var crpBookingDetailResponse = Rxn<CrpBookingDetailsResponse>();
  var driverDetailsResponse = Rxn<CrpDriverDetailsResponse>();
  var isLoadingDriverDetails = false.obs;
  RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

// Holds API response

  // Inject your API service or use directly
  Future<void> fetchBookingData(String orderId, String token, String user) async {
    isLoading.value = true;

    try {
      final response = await CprApiService().getRequest('GetBooking_detail_byorderId?OrderID=$orderId&token=$token&user=$user');
      crpBookingDetailResponse.value = CrpBookingDetailsResponse.fromJson(response);
      print('yash fetch crp booking detail response : ${crpBookingDetailResponse.value}');
    } catch (e) {
      print('Error fetching data: $e');
      // Optionally show error dialog/snackbar
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch driver details
  Future<void> fetchDriverDetails(String orderId, String token, String user) async {
    isLoadingDriverDetails.value = true;

    try {
      final response = await CprApiService().getRequest('GetDriveDetails?OrderID=$orderId&token=$token&user=$user');
      driverDetailsResponse.value = CrpDriverDetailsResponse.fromJson(response);
      print('yash fetch driver details response : ${driverDetailsResponse.value}');
    } catch (e, stackTrace) {
      print('Error fetching driver details: $e');
      print('Stack trace: $stackTrace');
      driverDetailsResponse.value = null;
    } finally {
      isLoadingDriverDetails.value = false;
    }
  }
}