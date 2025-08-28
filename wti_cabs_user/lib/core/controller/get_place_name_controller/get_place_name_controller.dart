import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import 'package:wti_cabs_user/core/model/auth/register/register_response.dart';
import 'package:wti_cabs_user/core/model/getPlaceName/getPlaceName_response.dart';
import '../../api/api_services.dart';
import '../../services/storage_services.dart';

class GetPlaceNameController extends GetxController {
  Rx<GetPlaceNameResponse?> getPlaceNameResponse = Rx<GetPlaceNameResponse?>(null);
  RxBool isLoading = false.obs;

  /// Fetch booking data based on the given country and request body
  Future<void> fetchPlaceName({
    required double lat,
    required double lng,
    required BuildContext context,
  }) async {

    final Map<String, dynamic> requestData = {};

    isLoading.value = true;
    try {
      final response = await ApiService().postRequestNew<GetPlaceNameResponse>(
        'google/getPlaceNameOnLatLng?lat=$lat&lng=$lng',
        requestData,
        GetPlaceNameResponse.fromJson,
        context,
      );
      getPlaceNameResponse.value = response;
    } finally {
      isLoading.value = false;
    }
  }

}
