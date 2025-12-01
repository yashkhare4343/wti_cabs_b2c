import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/api/corporate/cpr_api_services.dart';
import '../../../model/corporate/crp_car_provider_response/crp_car_provider_response.dart';
import '../../../services/storage_services.dart';

class CarProviderController extends GetxController {
  RxList<CarProviderModel> carProviderList = <CarProviderModel>[].obs;
  Rx<CarProviderModel?> selectedCarProvider = Rx<CarProviderModel?>(null);
  var isLoading = false.obs;

  Future<void> fetchCarProviders(BuildContext context) async {
    try {
      isLoading.value = true;
      
      // Get token and user from storage
      final token = await StorageServices.instance.read('crpKey');
      final user = await StorageServices.instance.read('email');
      
      final params = {
        'token': token ?? '',
        'user': user ?? '',
      };

      await CprApiService().getRequestCrp<List<CarProviderModel>>(
        "GetCarProviders",
        params,
        (body) {
          // Handle both direct list and wrapped response
          if (body is List) {
            return CarProviderModel.listFromJson(body);
          } else if (body is Map) {
            // Check for common wrapped response patterns
            if (body.containsKey('providers') && body['providers'] is List) {
              return CarProviderModel.listFromJson(body['providers']);
            } else if (body.containsKey('data') && body['data'] is List) {
              return CarProviderModel.listFromJson(body['data']);
            } else if (body.containsKey('result') && body['result'] is List) {
              return CarProviderModel.listFromJson(body['result']);
            }
            // If it's a map but no list found, try to parse as single item
            return [];
          }
          return CarProviderModel.listFromJson(body);
        },
        context,
      ).then((data) {
        // Remove duplicates based on providerID
        final uniqueProviders = <int, CarProviderModel>{};
        for (final provider in data) {
          if (provider.providerID != null) {
            uniqueProviders[provider.providerID!] = provider;
          }
        }
        carProviderList.value = uniqueProviders.values.toList();
        
        if (carProviderList.isNotEmpty && selectedCarProvider.value == null) {
          // Optionally set first item as default
          // selectedCarProvider.value = carProviderList.first;
        }
      });
    } catch (e) {
      debugPrint("Car Provider Fetch Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void selectCarProvider(CarProviderModel? model) {
    selectedCarProvider.value = model;
  }
}

