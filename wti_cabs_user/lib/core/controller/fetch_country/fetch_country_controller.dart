import 'package:get/get.dart';

import '../../services/location_service.dart';

class FetchCountryController extends GetxController {
  var currentCountry = ''.obs;

  Future<void> fetchCurrentCountry() async {
    String? country = await LocationService.getCurrentCountry();
    if (country != null) {
      currentCountry.value = country;
      print('🌍 Stored Country: $country');
    } else {
      currentCountry.value = 'Unknown';
    }
  }
}
