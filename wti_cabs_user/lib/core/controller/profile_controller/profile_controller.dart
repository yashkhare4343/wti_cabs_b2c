import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/model/profile/profile_response.dart';

import '../../api/api_services.dart';
import '../../services/storage_services.dart';

class ProfileController extends GetxController {
  var isLoading = false.obs;
  var profileResponse = Rxn<ProfileResponse>();
  RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  void checkLoginStatus() async{
    final token = await StorageServices.instance.read('token');
    if (token!=null) {
      isLoggedIn.value = true;
     } else {
      isLoggedIn.value = false;
    }
  }// Holds API response

  // Inject your API service or use directly
  Future<void> fetchData() async {
    isLoading.value = true;

    try {
      final response = await ApiService().getRequest('user/getUserDetails');
      profileResponse.value = ProfileResponse.fromJson(response);
      print('yash profile response : ${profileResponse.value}');
      await StorageServices.instance.save('firstName', profileResponse.value?.result?.firstName ?? '');
      await StorageServices.instance.save('contact', profileResponse.value?.result?.contact.toString() ?? '');
      await StorageServices.instance.save('contactCode', profileResponse.value?.result?.contactCode.toString() ?? '');
      await StorageServices.instance.save('emailId', profileResponse.value?.result?.emailID.toString() ?? '');
    } catch (e) {
      print('Error fetching data: $e');
      // Optionally show error dialog/snackbar
    } finally {
      isLoading.value = false;
    }
  }
}