import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/controller/self_drive/fetch_all_cities_controller/fetch_all_cities_controller.dart';
import 'package:wti_cabs_user/core/model/self_drive/top_rated_rides_model/top_rated_rides_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_all_inventory/self_drive_all_inventory.dart';

import '../../../services/storage_services.dart';

class SearchInventorySdController extends GetxController {
  Rx<TopRatedRidesResponse?> topRatedRidesResponse = Rx<TopRatedRidesResponse?>(null);
  final FetchAllCitiesController fetchAllCitiesController = Get.find<FetchAllCitiesController>();
  RxBool isLoading = false.obs;
  RxString city = 'Dubai'.obs;
  RxString cityId = '688362a53e4b6745a358bc5f'.obs;
  RxString countryCode = 'UAE'.obs;
  RxString countryId = ''.obs;
  RxInt selectedIndex = 0.obs;
  RxInt selectedMonth = 1.obs;

  /// Default: pickup = tomorrow, drop = day after tomorrow
  Rx<DateTime> fromDate = DateTime.now().add(const Duration(days: 1)).obs; // tomorrow
  Rx<TimeOfDay> fromTime = TimeOfDay(hour: 0, minute: 0).obs;
  Rx<DateTime> toDate = DateTime.now().add(const Duration(days: 2)).obs; // day after tomorrow
  Rx<TimeOfDay> toTime = TimeOfDay(hour: 0, minute: 0).obs;


  /// Fetch booking data based on the given country and request body
  Future<void> fetchAllInventory({
    required BuildContext context,
  }) async {

    isLoading.value = true;
    try {
      final Map<String, dynamic> requestData = {
          "source": {
            "city": city.value ?? "Dubai",
            "countryCode": countryCode.value ?? 'UAE',
            "countryId": "68835bbacd2ef39904163d27"
            // "countryId": countryId.value??""
          },
          "pickup": {
            "date": "${fromDate.value.day}/${fromDate.value.month}/${fromDate.value.year}",
            "time": "${fromTime.value.hour.toString().padLeft(2, '0')}:${fromTime.value.minute.toString().padLeft(2, '0')}"
          },
        if(selectedIndex.value == 0)  "drop": {
            "date": "${toDate.value.day}/${toDate.value.month}/${toDate.value.year}",
            "time": "${toTime.value.hour.toString().padLeft(2, '0')}:${toTime.value.minute.toString().padLeft(2, '0')}"
          },
        if(selectedIndex.value == 1)  "drop": {
            "date": "${fromDate.value.day}/${fromDate.value.month}/${fromDate.value.year}",
            "time": "${fromTime.value.hour.toString().padLeft(2, '0')}:${fromTime.value.minute.toString().padLeft(2, '0')}"
          },
          "plan_type": selectedIndex.value == 1 ? 2 : 1,
          "vehicle_class": "all",
    };

      final response = await SelfDriveApiService().postRequestNew<TopRatedRidesResponse>(
        'inventory/getAllInventory',
        requestData,
        TopRatedRidesResponse.fromJson,
        context,
      );
      topRatedRidesResponse.value = response;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // GoRouter.of(context).push(AppRoutes.selfDriveAllInventory);
        if (!context.mounted) return; // ✅ prevents crash

        Navigator.of(context).push(
          Platform.isIOS
              ? CupertinoPageRoute(
            builder: (_) => SelfDriveAllInventory(
              city: city.value,
              fromDate: "${fromDate.value.day}/${fromDate.value.month}",
              fromTime:
              "${fromTime.value.hour.toString().padLeft(2, '0')}:${fromTime.value.minute.toString().padLeft(2, '0')}",
              toDate: "${toDate.value.day}/${toDate.value.month}",
              toTime:
              "${toTime.value.hour.toString().padLeft(2, '0')}:${toTime.value.minute.toString().padLeft(2, '0')}",
              selectedMonth: selectedMonth.value.toString(),
            ),
          )
              : MaterialPageRoute(
            builder: (_) => SelfDriveAllInventory(
              city: city.value,
              fromDate: "${fromDate.value.day}/${fromDate.value.month}",
              fromTime:
              "${fromTime.value.hour.toString().padLeft(2, '0')}:${fromTime.value.minute.toString().padLeft(2, '0')}",
              toDate: "${toDate.value.day}/${toDate.value.month}",
              toTime:
              "${toTime.value.hour.toString().padLeft(2, '0')}:${toTime.value.minute.toString().padLeft(2, '0')}",
              selectedMonth: selectedMonth.value.toString(),
            ),
          ),
        );
      });

      print('getAllInventoty request data : $requestData');
      print('getAllInventoty response data : $response');
    } finally {
      isLoading.value = false;
    }
  }
}
