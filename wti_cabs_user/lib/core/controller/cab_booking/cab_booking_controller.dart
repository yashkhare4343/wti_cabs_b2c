import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/common_widget/loader/full_screen_gif/full_screen_gif.dart';
import 'package:wti_cabs_user/core/controller/coupons/apply_coupon_controller.dart';
import 'package:wti_cabs_user/core/controller/currency_controller/currency_controller.dart';
import 'package:wti_cabs_user/core/model/cab_booking/india_cab_booking.dart';
import 'package:wti_cabs_user/core/model/cab_booking/global_cab_booking.dart';
import 'package:wti_cabs_user/common_widget/loader/popup_loader.dart';
import 'package:wti_cabs_user/core/api/api_services.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

import '../../model/inventory/global_response.dart';
import '../../model/inventory/india_response.dart';
import '../../controller/inventory/search_cab_inventory_controller.dart';
import '../../route_management/app_routes.dart';

class CabBookingController extends GetxController {
  Rx<IndiaCabBooking?> indiaData = Rx<IndiaCabBooking?>(null);
  Rx<GlobalBookingFlat?> globalData = Rx<GlobalBookingFlat?>(null);
  Rx<IndiaFareDetailsResponse?> indiaFareDetails = Rx<IndiaFareDetailsResponse?>(null);
  final ApplyCouponController applyCouponController = Get.put(ApplyCouponController());
  RxBool isLoading = false.obs;
  RxInt selectedOption = 0.obs;

  // NEW: Extra selected facilities (label -> price)
  RxMap<String, double> selectedExtras = <String, double>{}.obs;

  // Assume country is stored separately
  String? country;
              double get baseFare {
                final value = isIndia
                    ? (indiaFareDetails.value?.fareDetails?.baseFare?.toDouble() ?? 
                       indiaData.value?.inventory?.carTypes?.fareDetails?.baseFare?.toDouble() ?? 0.0)
                    : (globalData.value?.totalFare ?? 0.0);
                debugPrint('baseFare: $value');
                return value;
              }

  double get nightCharges {
    if (isIndia && indiaFareDetails.value?.fareDetails?.chargeMapping != null) {
      // Extract from chargeMapping
      for (var charge in indiaFareDetails.value!.fareDetails!.chargeMapping!) {
        if (charge.label?.toLowerCase().contains('night') == true) {
          return charge.amount?.toDouble() ?? 0.0;
        }
      }
    }
    final included = indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.nightCharges?.isIncludedInGrandTotal == true;
    final amount = included ? (indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.nightCharges?.amount?.toDouble() ?? 0.0) : 0.0;
    debugPrint('nightCharges (included: $included): $amount');
    return isIndia ? amount : 0.0;
  }

  double get tollCharges {
    final included = indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.tollCharges?.isIncludedInGrandTotal == true;
    final amount = included ? (indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.tollCharges?.amount?.toDouble() ?? 0.0) : 0.0;
    debugPrint('tollCharges (included: $included): $amount');
    return isIndia ? amount : 0.0;
  }

  double get waitingCharges {
    final included = indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.waitingCharges?.isIncludedInGrandTotal == true;
    final amount = included ? (indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.waitingCharges?.amount?.toDouble() ?? 0.0) : 0.0;
    debugPrint('waitingCharges (included: $included): $amount');
    return isIndia ? amount : 0.0;
  }

  double get parkingCharges {
    final included = indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.parkingCharges?.isIncludedInGrandTotal == true;
    final amount = included ? (indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.parkingCharges?.amount?.toDouble() ?? 0.0) : 0.0;
    debugPrint('parkingCharges (included: $included): $amount');
    return isIndia ? amount : 0.0;
  }

  double get stateTax {
    if (isIndia && indiaFareDetails.value?.fareDetails?.chargeMapping != null) {
      // Extract tax from chargeMapping
      for (var charge in indiaFareDetails.value!.fareDetails!.chargeMapping!) {
        if (charge.label?.toLowerCase().contains('tax') == true) {
          return charge.amount?.toDouble() ?? 0.0;
        }
      }
    }
    final included = indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.stateTax?.isIncludedInGrandTotal == true;
    final amount = included ? (indiaData.value?.inventory?.carTypes?.fareDetails?.extraCharges?.stateTax?.amount?.toDouble() ?? 0.0) : 0.0;
    debugPrint('stateTax (included: $included): $amount');
    return isIndia ? amount : 0.0;
  }

  double get driverCharge {
    final value = isIndia
        ? (indiaData.value?.inventory?.carTypes?.fareDetails?.totalDriverCharges?.toDouble() ?? 0.0)
        : 0.0;
    debugPrint('driverCharge: $value');
    return value;
  }

  double get extraFacilityCharges {
    final value = selectedExtras.values.fold(0.0, (sum, item) => sum + item);
    debugPrint('extraFacilityCharges: $value');
    return value;
  }


  double get actualFare {
    final subtotal = baseFare +
        nightCharges +
        tollCharges +
        waitingCharges +
        parkingCharges +
        stateTax +
        driverCharge+
        extraFacilityCharges;

    debugPrint('actualFare subtotal: $subtotal');
    return subtotal;
  }

  double get totalFare {
    // If we have fare details from new API, use totalFare directly (it already includes tax)
    if (isIndia && indiaFareDetails.value?.fareDetails?.totalFare != null) {
      final apiTotalFare = indiaFareDetails.value!.fareDetails!.totalFare!.toDouble();
      // Apply coupon discount if applicable
      if (applyCouponController.isCouponApplied.value) {
        final discountedFare = applyCouponController.applyCouponResponse.value?.newTotalAmount;
        if (discountedFare != null) {
          // Calculate tax on discounted amount and add it
          final tax = discountedFare * 0.05;
          return discountedFare + tax;
        }
      }
      return apiTotalFare;
    }

    // Fallback to calculating from individual charges
    double subtotal;

    if (applyCouponController.isCouponApplied == false) {
      // No coupon → just sum all charges
      subtotal = baseFare +
          nightCharges +
          tollCharges +
          waitingCharges +
          parkingCharges +
          stateTax +
          driverCharge +
          extraFacilityCharges;
      debugPrint('Coupon not applied. Subtotal: $subtotal');
    } else {

      // Coupon applied → take discounted amount (without tax from API)
      final discountedFare =
          applyCouponController.applyCouponResponse.value?.newTotalAmount ??
              baseFare +
                  nightCharges +
                  tollCharges +
                  waitingCharges +
                  parkingCharges +
                  stateTax +
                  driverCharge +
                  extraFacilityCharges;

      subtotal = discountedFare.toDouble();

      debugPrint('Coupon applied. Discounted subtotal (before tax): $subtotal');
    }

    // Add tax locally (only once, based on subtotal)
    final tax = isIndia ? subtotal * 0.05 : 0;
    final total = subtotal + tax;

    debugPrint('Tax (5% if India): $tax');
    debugPrint('Total Fare: $total');

    return total;
  }

  double get taxCharge{
    double subtotal;

    if (applyCouponController.isCouponApplied == false) {
      // No coupon → just sum all charges
      subtotal = baseFare +
          nightCharges +
          tollCharges +
          waitingCharges +
          parkingCharges +
          stateTax +
          driverCharge +
          extraFacilityCharges;
      debugPrint('Coupon not applied. Subtotal: $subtotal');
    } else {
      // Coupon applied → take discounted amount (without tax from API)
      final discountedFare =
          applyCouponController.applyCouponResponse.value?.newTotalAmount ??
              baseFare;

      subtotal = discountedFare +
          nightCharges +
          tollCharges +
          waitingCharges +
          parkingCharges +
          stateTax +
          driverCharge +
          extraFacilityCharges;

      debugPrint('Coupon applied. Discounted subtotal (before tax): $subtotal');
    }

    final tax = isIndia ? subtotal * 0.05 : 0;
    print('yash tAX : $tax');

    return tax.toDouble();
  }

  double get partFare {
    final value = totalFare * 0.20;
    debugPrint('Part fare (20% of totalFare): $value');
    return value;
  }

  double get amountTobeCollected {
    final value = totalFare - partFare;
    debugPrint('Amount to be collected (totalFare - partFare): $value');
    return value;
  }



  bool get isIndia => (country?.toLowerCase() ?? '') == 'india';

  void toggleExtraFacility(String label, double amount, bool isSelected) {
    if (isSelected) {
      selectedExtras[label] = amount;
    } else {
      selectedExtras.remove(label);
    }
  }

  // store choose extras id in array
  RxList<String> selectedExtrasIds = <String>[].obs;

  void toggleExtraId(String id, bool isSelected) {
    if (isSelected) {
      if (!selectedExtrasIds.contains(id)) {
        selectedExtrasIds.add(id);
      }
    } else {
      selectedExtrasIds.remove(id);
    }
    print("🆔 Selected Extras: $selectedExtrasIds");
  }

  // Optional: clear all
  void clearSelectedExtras() {
    selectedExtrasIds.clear();
  }

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  var isFormValid = false.obs;

  void validateForm() {
    final isValid = formKey.currentState?.validate() ?? false;
    isFormValid.value = isValid;
  }

  void showAllChargesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final currencyController = Get.find<CurrencyController>();
        final isIndiaCountry = isIndia;

        // For India: Use chargeMapping from new API
        if (isIndiaCountry && indiaFareDetails.value?.fareDetails?.chargeMapping != null) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.45,
            minChildSize: 0.45,
            maxChildSize: 0.9,
            builder: (_, controller) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadIndiaChargeMapping(currencyController),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("Failed to load charges"));
                    }

                    final chargeList = snapshot.data!;
                    final symbol = currencyController.selectedCurrency.value.symbol;
                    final totalFare = indiaFareDetails.value?.fareDetails?.totalFare?.toDouble() ?? 0.0;

                    return ListView(
                      controller: controller,
                      children: [
                        Center(
                          child: Container(
                            height: 5,
                            width: 40,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const Text(
                          "Fare Breakdown",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Show all charges from chargeMapping
                        for (var charge in chargeList)
                          if (charge['amount'] != null && (charge['amount'] as num) != 0)
                            _buildRow(
                              charge['label'] as String,
                              "$symbol${charge['convertedAmount'].toStringAsFixed(2)}",
                            ),

                        const Divider(thickness: 1, height: 24),

                        FutureBuilder<double>(
                          future: currencyController.convertPrice(totalFare),
                          builder: (context, totalSnapshot) {
                            final totalConverted = totalSnapshot.data ?? totalFare;
                            return _buildRow(
                              "Total Fare",
                              "$symbol${totalConverted.toStringAsFixed(2)}",
                              isBold: true,
                              highlight: true,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        }

        // For non-India: Use old way
        Future<Map<String, double>> loadConvertedValues() async {
          final results = await Future.wait([
            currencyController.convertPrice(baseFare),
            currencyController.convertPrice(nightCharges),
            currencyController.convertPrice(tollCharges),
            currencyController.convertPrice(waitingCharges),
            currencyController.convertPrice(parkingCharges),
            currencyController.convertPrice(stateTax),
            currencyController.convertPrice(driverCharge),
            currencyController.convertPrice(extraFacilityCharges),
            currencyController.convertPrice(actualFare),
            currencyController.convertPrice(taxCharge),
            currencyController.convertPrice(totalFare),
            if (applyCouponController.isCouponApplied.value)
              currencyController.convertPrice(
                applyCouponController.applyCouponResponse.value?.discountAmount?.toDouble() ?? 0.0,
              ),
          ]);

          return {
            "baseFare": results[0],
            "nightCharges": results[1],
            "tollCharges": results[2],
            "waitingCharges": results[3],
            "parkingCharges": results[4],
            "stateTax": results[5],
            "driverCharge": results[6],
            "extras": results[7],
            "subtotal": results[8],
            "tax": results[9],
            "total": results[10],
            if (applyCouponController.isCouponApplied.value)
              "discount": results.last,
          };
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<Map<String, double>>(
                future: Future.delayed(
                  const Duration(milliseconds: 500), // ⏳ fake loader
                  loadConvertedValues,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: Text("Failed to load charges"));
                  }

                  final data = snapshot.data!;
                  final symbol = currencyController.selectedCurrency.value.symbol;

                  return ListView(
                    controller: controller,
                    children: [
                      Center(
                        child: Container(
                          height: 5,
                          width: 40,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const Text(
                        "Fare Breakdown",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      if ((data['baseFare'] ?? 0) != 0)
                        _buildRow("Base Fare", "$symbol${data['baseFare']!.toStringAsFixed(2)}"),
                      if ((data['nightCharges'] ?? 0) != 0)
                        _buildRow("Night Charges", "$symbol${data['nightCharges']!.toStringAsFixed(2)}"),
                      if ((data['tollCharges'] ?? 0) != 0)
                        _buildRow("Toll Charges", "$symbol${data['tollCharges']!.toStringAsFixed(2)}"),
                      if ((data['waitingCharges'] ?? 0) != 0)
                        _buildRow("Waiting Charges", "$symbol${data['waitingCharges']!.toStringAsFixed(2)}"),
                      if ((data['parkingCharges'] ?? 0) != 0)
                        _buildRow("Parking Charges", "$symbol${data['parkingCharges']!.toStringAsFixed(2)}"),
                      if ((data['stateTax'] ?? 0) != 0)
                        _buildRow("State Tax", "$symbol${data['stateTax']!.toStringAsFixed(2)}"),
                      if ((data['driverCharge'] ?? 0) != 0)
                        _buildRow("Driver Charge", "$symbol${data['driverCharge']!.toStringAsFixed(2)}"),
                      if ((data['extras'] ?? 0) != 0)
                        _buildRow("Extras", "$symbol${data['extras']!.toStringAsFixed(2)}"),

                      const Divider(thickness: 1, height: 24),

                      _buildRow("Subtotal", "$symbol${data['subtotal']!.toStringAsFixed(2)}", isBold: true),
                      _buildRow("Tax include (5%)", "$symbol${data['tax']!.toStringAsFixed(2)}", isBold: true),

                      if ((data['discount'] ?? 0) != 0)
                        _buildRow("Coupon Applied", "-$symbol${data['discount']!.toStringAsFixed(2)}"),

                      _buildRow("Total Fare", "$symbol${data['total']!.toStringAsFixed(2)}",
                          isBold: true, highlight: true),
                    ],
                  );

                },
              ),
            );
          },
        );
      },
    );
  }

  /// Load India charge mapping with converted prices
  Future<List<Map<String, dynamic>>> _loadIndiaChargeMapping(CurrencyController currencyController) async {
    final chargeMapping = indiaFareDetails.value?.fareDetails?.chargeMapping;
    if (chargeMapping == null || chargeMapping.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> convertedCharges = [];
    
    for (var charge in chargeMapping) {
      final amount = charge.amount?.toDouble() ?? 0.0;
      final convertedAmount = await currencyController.convertPrice(amount);
      
      convertedCharges.add({
        'label': charge.label ?? '',
        'amount': amount,
        'convertedAmount': convertedAmount,
      });
    }

    return convertedCharges;
  }

  /// Helper row widget
  Widget _buildRow(String label, String value,
      {bool isBold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w400)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
              color: highlight ? AppColors.mainButtonBg : Colors.black,
            ),
          ),
        ],
      ),
    );
  }


  /// Fetch India inventory data from new API
  Future<void> fetchIndiaInventoryData({
    required Map<String, dynamic> requestData,
    required BuildContext context,
  }) async {
    print('📤 India Inventory API request: $requestData');

    try {
      final response = await ApiService().postRequest(
        'inventory/searchInventorySingleCarDetails',
        requestData,
        context,
      );

      print('📥 India Inventory API response: $response');

      // Transform the new API response to match IndiaCabBooking structure
      if (response != null) {
        try {
          // Convert response to Map<String, dynamic> if needed
          final Map<String, dynamic> responseMap = response is Map<String, dynamic>
              ? response
              : Map<String, dynamic>.from(response as Map);
          
          // Map the new response structure to the existing model
          final transformedResponse = _transformIndiaInventoryResponse(responseMap, requestData);
          
          // Ensure transformed response is properly typed
          final Map<String, dynamic> finalResponse = transformedResponse is Map<String, dynamic>
              ? transformedResponse
              : Map<String, dynamic>.from(transformedResponse);
          
          indiaData.value = IndiaCabBooking.fromJson(finalResponse);
          print('✅ India inventory response transformed: ${indiaData.value?.toJson()}');
        } catch (transformError, stackTrace) {
          print("❌ Error transforming response: $transformError");
          print("Stack trace: $stackTrace");
          rethrow;
        }
      } else {
        print('⚠️ India: Response is null or invalid.');
      }

      globalData.value = null;
    } catch (e, stackTrace) {
      print("❌ Error fetching India inventory data: $e");
      print("Stack trace: $stackTrace");
    } finally {
      // no-op: outer caller (fetchBookingData) manages loader & isLoading
    }
  }

  /// Fetch India fare details from new API
  Future<void> fetchIndiaFareDetails({
    required Map<String, dynamic> requestData,
    required BuildContext context,
  }) async {
    print('📤 India Fare Details API request: $requestData');

    try {
      final response = await ApiService().postRequest(
        'inventory/searchInventorySingleCarFareDetails',
        requestData,
        context,
      );

      print('📥 India Fare Details API response: $response');

      // Transform the response to match IndiaFareDetailsResponse structure
      if (response != null) {
        try {
          // Convert response to Map<String, dynamic> if needed
          final Map<String, dynamic> responseMap = response is Map<String, dynamic>
              ? response
              : Map<String, dynamic>.from(response as Map);
          
          // Parse the response
          indiaFareDetails.value = IndiaFareDetailsResponse.fromJson(responseMap);
          print('✅ India fare details response parsed: ${indiaFareDetails.value?.toJson()}');
        } catch (parseError, stackTrace) {
          print("❌ Error parsing fare details response: $parseError");
          print("Stack trace: $stackTrace");
        }
      } else {
        print('⚠️ India Fare Details: Response is null or invalid.');
      }
    } catch (e, stackTrace) {
      print("❌ Error fetching India fare details: $e");
      print("Stack trace: $stackTrace");
      // Don't show error snackbar here as it's called from booking_details_final
    }
  }

  /// Helper method to safely cast maps
  Map<String, dynamic>? _safeCastMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Transform new India inventory API response to match IndiaCabBooking model
  Map<String, dynamic> _transformIndiaInventoryResponse(
    Map<String, dynamic> response,
    Map<String, dynamic> requestData,
  ) {
    // Try to get existing inventory data from SearchCabInventoryController
    Map<String, dynamic>? existingInventoryData;
    Map<String, dynamic>? existingInventoryBase;
    try {
      final searchCabInventoryController = Get.find<SearchCabInventoryController>();
      final indiaResponse = searchCabInventoryController.indiaData.value;
      if (indiaResponse != null && indiaResponse.result != null) {
        // Get base inventory data (distanceBooked, etc.)
        if (indiaResponse.result!.inventory != null) {
          existingInventoryBase = {
            'distance_booked': indiaResponse.result!.inventory!.distanceBooked,
            'is_instant_available': indiaResponse.result!.inventory!.isInstantAvailable,
            'is_part_payment_allowed': indiaResponse.result!.inventory!.isPartPaymentAllowed,
            'communication_type': indiaResponse.result!.inventory!.communicationType,
            'verification_type': indiaResponse.result!.inventory!.verificationType,
            'start_time': indiaResponse.result!.inventory!.startTime?.toIso8601String(),
          };
        }
        
        // Find the matching car type from the inventory list
        final routeInventoryId = requestData['routeInventoryId'] as String?;
        if (routeInventoryId != null && 
            indiaResponse.result!.inventory != null && 
            indiaResponse.result!.inventory!.carTypes != null) {
          for (var carType in indiaResponse.result!.inventory!.carTypes!) {
            if (carType.routeId == routeInventoryId) {
              // Convert carType to JSON for merging
              existingInventoryData = carType.toJson();
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not get existing inventory data: $e');
    }

    // Extract fare_details from response - handle type casting
    final fareDetailsRaw = response['fare_details'];
    final Map<String, dynamic>? fareDetails = fareDetailsRaw != null
        ? (fareDetailsRaw is Map<String, dynamic>
            ? fareDetailsRaw
            : Map<String, dynamic>.from(fareDetailsRaw as Map))
        : null;
    
    final chargeMappingRaw = fareDetails?['chargeMapping'];
    final List<dynamic>? chargeMapping = chargeMappingRaw != null
        ? (chargeMappingRaw is List
            ? chargeMappingRaw
            : List<dynamic>.from(chargeMappingRaw))
        : null;
    
    // Build extra_charges from chargeMapping
    Map<String, dynamic>? extraCharges;
    if (chargeMapping != null) {
      extraCharges = {};
      
      for (var charge in chargeMapping) {
        // Convert charge to Map<String, dynamic> if needed
        final Map<String, dynamic> chargeMap = charge is Map<String, dynamic>
            ? charge
            : Map<String, dynamic>.from(charge as Map);
        
        final label = chargeMap['label'] as String?;
        final amount = chargeMap['amount'] as num?;
        
        if (label != null && amount != null) {
          if (label.toLowerCase().contains('night')) {
            extraCharges['night_charges'] = {
              'amount': amount,
              'is_applicable': amount > 0,
              'is_included_in_base_fare': false,
              'is_included_in_grand_total': true,
            };
          } else if (label.toLowerCase().contains('toll')) {
            extraCharges['toll_charges'] = {
              'amount': amount,
              'is_applicable': amount > 0,
              'is_included_in_base_fare': false,
              'is_included_in_grand_total': true,
            };
          } else if (label.toLowerCase().contains('waiting')) {
            extraCharges['waiting_charges'] = {
              'amount': amount,
              'is_applicable': amount > 0,
              'is_included_in_base_fare': false,
              'is_included_in_grand_total': true,
            };
          } else if (label.toLowerCase().contains('parking')) {
            extraCharges['parking_charges'] = {
              'amount': amount,
              'is_applicable': amount > 0,
              'is_included_in_base_fare': false,
              'is_included_in_grand_total': true,
            };
          } else if (label.toLowerCase().contains('state') || label.toLowerCase().contains('tax')) {
            extraCharges['state_tax'] = {
              'amount': amount,
              'is_applicable': amount > 0,
              'is_included_in_base_fare': false,
              'is_included_in_grand_total': true,
            };
          }
        }
      }
    }


    // Build fare_details structure - merge with existing if available
    final existingFareDetailsRaw = existingInventoryData?['fare_details'];
    final Map<String, dynamic>? existingFareDetails = existingFareDetailsRaw != null
        ? (existingFareDetailsRaw is Map<String, dynamic>
            ? existingFareDetailsRaw
            : Map<String, dynamic>.from(existingFareDetailsRaw as Map))
        : null;
    
    final transformedFareDetails = <String, dynamic>{
      'base_fare': fareDetails?['base_fare'] ?? existingFareDetails?['base_fare'] ?? 0,
      'per_km_charge': fareDetails?['per_km_charge'] ?? existingFareDetails?['per_km_charge'] ?? 0,
      'per_km_extra_charge': fareDetails?['per_km_extra_charge'] ?? existingFareDetails?['per_km_extra_charge'] ?? 0,
    };
    
    // Add extra_charges if available
    if (extraCharges != null) {
      transformedFareDetails['extra_charges'] = extraCharges;
    } else if (existingFareDetails?['extra_charges'] != null) {
      // Preserve existing extra_charges if new API doesn't provide them
      final extraChargesRaw = existingFareDetails?['extra_charges'];
      final extraChargesCast = _safeCastMap(extraChargesRaw);
      if (extraChargesCast != null) {
        transformedFareDetails['extra_charges'] = extraChargesCast;
      }
    }

    // Build tripType from requestData and response
    // Handle type casting for source and destination
    final sourceRaw = response['source'];
    final Map<String, dynamic>? source = sourceRaw != null
        ? (sourceRaw is Map<String, dynamic>
            ? sourceRaw
            : Map<String, dynamic>.from(sourceRaw as Map))
        : null;
    
    final destinationRaw = response['destination'];
    final Map<String, dynamic>? destination = destinationRaw != null
        ? (destinationRaw is Map<String, dynamic>
            ? destinationRaw
            : Map<String, dynamic>.from(destinationRaw as Map))
        : null;
    
    final tripTypeDetailsRaw = requestData['trip_type_details'];
    final Map<String, dynamic>? tripTypeDetails = tripTypeDetailsRaw != null
        ? (tripTypeDetailsRaw is Map<String, dynamic>
            ? tripTypeDetailsRaw
            : Map<String, dynamic>.from(tripTypeDetailsRaw as Map))
        : null;
    
    final tripType = {
      'isGlobal': requestData['isGlobal'] ?? false,
      'country': requestData['country'] ?? 'india',
      'routeInventoryId': requestData['routeInventoryId'],
      'vehicleId': requestData['vehicleId'],
      'trip_type': requestData['trip_type'],
      'pickUpDateTime': requestData['pickUpDateTime'],
      'dropDateTime': requestData['dropDateTime'],
      'totalKilometers': requestData['totalKilometers'],
      'trip_type_details': tripTypeDetails,
      'package_id': response['package_id'],
      'source': source,
      'destination': destination,
      'tripCode': response['tripCode'],
      'comingFrom': response['comingFrom'],
    };

    // Build inventory structure - merge existing inventory data if available
    Map<String, dynamic> inventoryData = {};
    
    // Start with base inventory data if available
    if (existingInventoryBase != null) {
      inventoryData.addAll(existingInventoryBase);
    }
    
    if (existingInventoryData != null) {
      // Merge existing car type data
      // Note: existingInventoryData is from CarType.toJson(), which uses snake_case for most fields
      // We need to transform it to match the Inventory structure expected by IndiaCabBooking
      final carTypesData = {
        'type': existingInventoryData['type'],
        'subcategory': existingInventoryData['subcategory'],
        'combustion_type': existingInventoryData['combustion_type'],
        'carrier': existingInventoryData['carrier'],
        'make_year_type': existingInventoryData['make_year_type'],
        'base_km': existingInventoryData['base_km'],
        'cancellation_rule': existingInventoryData['cancellation_rule'],
        'model': existingInventoryData['model'],
        'trip_type': existingInventoryData['trip_type'],
        'amenities': _safeCastMap(existingInventoryData['amenities']),
        'extrasIdArray': existingInventoryData['extrasIdArray'],
        'rating': _safeCastMap(existingInventoryData['rating']),
        'seats': existingInventoryData['seats'],
        'luggageCapacity': existingInventoryData['luggageCapacity'],
        'isActive': existingInventoryData['isActive'],
        'pet': existingInventoryData['pet'],
        'carTagLine': existingInventoryData['carTagLine'],
        'fakePercentageOff': existingInventoryData['fakePercentageOff'],
        'carImageUrl': existingInventoryData['carImageUrl'],
        'fleet_id': existingInventoryData['sku_id'], // Use sku_id as fleet_id if needed
        'sku_id': existingInventoryData['sku_id'],
        'source': _safeCastMap(existingInventoryData['source']),
        'fare_details': transformedFareDetails, // Use new API fare details
      };
      
      inventoryData['car_types'] = carTypesData;
    } else {
      // Use minimal structure if no existing data
      inventoryData['car_types'] = {
        'fare_details': transformedFareDetails,
      };
    }

    // Handle offerObject type casting
    final offerObjectRaw = response['offerObject'];
    final Map<String, dynamic>? offerObject = offerObjectRaw != null
        ? (offerObjectRaw is Map<String, dynamic>
            ? offerObjectRaw
            : Map<String, dynamic>.from(offerObjectRaw as Map))
        : <String, dynamic>{};

    // Return transformed structure matching IndiaCabBooking
    return {
      'success': response['success'] ?? true,
      'offerObject': offerObject,
      'tripType': tripType,
      'inventory': inventoryData,
    };
  }

  Future<void> fetchBookingData({
    required String country,
    required Map<String, dynamic> requestData,
    required BuildContext context,
    bool isSecondPage = false,
  }) async {
    isLoading.value = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FullScreenGifLoader(),
    );

    print('📤 Booking request: $requestData');

    try {
      if (country.toLowerCase() == 'india') {
        // 🇮🇳 India flow:
        // 1) Fetch full inventory / booking details
        // 2) Then fetch fare details with the SAME payload
        await fetchIndiaInventoryData(
          requestData: requestData,
          context: context,
        );

        await fetchIndiaFareDetails(
          requestData: requestData,
          context: context,
        );
      } else {
        final response = await ApiService().postRequest(
          'globalSearch/getFinalGlobalVehicleData',
          requestData,
          context,
        );

        // Handle global booking with optional tripTypeDetails
        globalData.value = GlobalBookingFlat.fromJson({
          'result': response['result'] ?? {},
          'tripTypeDetails': response['tripTypeDetails'],
        });

        // if (context.mounted) {
        //   GoRouter.of(context).push(AppRoutes.bookingDetailsFinal);
        // }
        print('✅ Global booking result count: ${globalData.value?.vehicleDetails}');
        print('📌 tripTypeDetails: ${globalData.value?.tripTypeDetails?.tripType ?? "N/A"}');
      }

      // ✅ Close the loader before navigating
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // ✅ Navigate to booking details page after successful fetch
      if (context.mounted) {
        GoRouter.of(context).push(AppRoutes.bookingDetailsFinal);
      }
    } catch (e) {
      print("❌ Error fetching booking data: $e");

      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      Get.snackbar("Error", "Something went wrong, please try again.",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
