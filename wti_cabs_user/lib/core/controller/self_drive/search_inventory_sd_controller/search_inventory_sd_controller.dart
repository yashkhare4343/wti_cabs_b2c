import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/common_widget/loader/shimmer/inventory_shimmer.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/controller/self_drive/fetch_all_cities_controller/fetch_all_cities_controller.dart';
import 'package:wti_cabs_user/core/model/self_drive/top_rated_rides_model/top_rated_rides_response.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_all_inventory/self_drive_all_inventory.dart';
import '../../../../common_widget/loader/shimmer/shimmer.dart';
import '../../../../utility/constants/fonts/common_fonts.dart';
import '../../../services/storage_services.dart';

class SearchInventorySdController extends GetxController {
  Rx<TopRatedRidesResponse?> topRatedRidesResponse =
      Rx<TopRatedRidesResponse?>(null);
  final FetchAllCitiesController fetchAllCitiesController =
      Get.find<FetchAllCitiesController>();
  RxBool isLoading = false.obs;

  RxString city = 'Dubai'.obs;
  RxString cityId = '688362a53e4b6745a358bc5f'.obs;
  RxString countryCode = 'UAE'.obs;
  RxString countryId = ''.obs;
  RxInt selectedIndex = 0.obs;
  RxInt selectedMonth = 1.obs;

  Rx<DateTime> fromDate = DateTime.now().add(const Duration(days: 2)).obs;
  Rx<TimeOfDay> fromTime = TimeOfDay(hour: 0, minute: 0).obs;
  Rx<DateTime> toDate = DateTime.now().add(const Duration(days: 3)).obs;
  Rx<TimeOfDay> toTime = TimeOfDay(hour: 0, minute: 0).obs;

  /// --- FILTER STATES ---
  RxString selectedVehicleClass = 'All'.obs; // All, Economy, SUV
  RxString selectedPriceOrder = 'None'.obs; // LowToHigh, HighToLow, None

  /// --- Master list to keep unfiltered data ---
  List<VehicleResult> allRides = [];

  void setVehicleClass(String value) {
    selectedVehicleClass.value = value;
    applyFilters();
  }

  void setPriceOrder(String value) {
    selectedPriceOrder.value = value;
    applyFilters();
  }

  /// --- FILTER LOGIC ---
  void applyFilters() {
    if (allRides.isEmpty) return;

    var filteredList = List<VehicleResult>.from(allRides);

    // Filter by vehicle class
    if (selectedVehicleClass.value != 'All') {
      filteredList = filteredList.where((ride) {
        final vehicleClass =
            ride.vehicleId?.specs?.carClass?.toLowerCase() ?? '';
        return vehicleClass.contains(selectedVehicleClass.value.toLowerCase());
      }).toList();
    }

    // Sort by price
    final useDaily =
        topRatedRidesResponse.value?.result?.first.searchedPlan == 'Daily';
    filteredList.sort((a, b) {
      final priceA =
          useDaily ? (a.tariffDaily?.base ?? 0) : (a.tariffMonthly?.base ?? 0);
      final priceB =
          useDaily ? (b.tariffDaily?.base ?? 0) : (b.tariffMonthly?.base ?? 0);

      if (selectedPriceOrder.value == 'LowToHigh')
        return priceA.compareTo(priceB);
      if (selectedPriceOrder.value == 'HighToLow')
        return priceB.compareTo(priceA);
      return 0;
    });

    topRatedRidesResponse.value = TopRatedRidesResponse(
      success: topRatedRidesResponse.value?.success ?? true,
      message: topRatedRidesResponse.value?.message ?? '',
      result: filteredList,
    );
  }

  /// --- FETCH INVENTORY ---
  Future<void> fetchAllInventory({required BuildContext context}) async {
    isLoading.value = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: FullPageShimmer()),
    );
    try {



      final Map<String, dynamic> requestData = {
        "source": {
          "city": city.value,
          "countryCode": 'AE',
          "countryId": "68835bbacd2ef39904163d27"
        },
        "pickup": {
          "date":
              "${fromDate.value.day}/${fromDate.value.month}/${fromDate.value.year}",
          "time":
              "${fromTime.value.hour.toString().padLeft(2, '0')}:${fromTime.value.minute.toString().padLeft(2, '0')}"
        },
        if (selectedIndex.value == 0)
          "drop": {
            "date":
                "${toDate.value.day}/${toDate.value.month}/${toDate.value.year}",
            "time":
                "${toTime.value.hour.toString().padLeft(2, '0')}:${toTime.value.minute.toString().padLeft(2, '0')}"
          },
        if (selectedIndex.value == 1)
          "drop": {
            "date":
                "${fromDate.value.day}/${fromDate.value.month}/${fromDate.value.year}",
            "time":
                "${fromTime.value.hour.toString().padLeft(2, '0')}:${fromTime.value.minute.toString().padLeft(2, '0')}"
          },
        "plan_type": selectedIndex.value == 1 ? 2 : 1,
        "vehicle_class": selectedVehicleClass.value.toLowerCase(),
        if (selectedIndex.value == 1) "duration_months": selectedMonth.value
      };

      final response =
          await SelfDriveApiService().postRequestNew<TopRatedRidesResponse>(
        'inventory/getAllInventory',
        requestData,
        TopRatedRidesResponse.fromJson,
        context,
      );

      topRatedRidesResponse.value = response;

      // ✅ Store master list
      allRides = response.result ?? [];

      // ✅ Apply filters if any
      applyFilters();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
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
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Inventory not found', style: CommonFonts.primaryButtonText),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
