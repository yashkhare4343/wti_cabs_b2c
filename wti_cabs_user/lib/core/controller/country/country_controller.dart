import 'dart:async';
import 'package:get/get.dart';
import '../../services/storage_services.dart';

class CountryController extends GetxController {
  RxString country = ''.obs;
  RxBool isLoading = true.obs; // 🔹 loader state

  @override
  void onInit() {
    super.onInit();
    _loadCountry();
  }

  Future<void> _loadCountry() async {
    isLoading.value = true;

    // 🔹 Fake loader delay
    await Future.delayed(const Duration(seconds: 1));

    final c = await StorageServices.instance.read('country') ?? '';
    country.value = c.toLowerCase().trim();

    isLoading.value = false;
  }

  bool get isIndia => country.value == 'india';
}
