import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/model/auth/mobile/mobile_response.dart';
import 'package:wti_cabs_user/core/model/auth/register/register_response.dart';
import 'package:wti_cabs_user/core/model/profile/update_profile_response.dart';
import '../../../common_widget/loader/popup_loader.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../../api/api_services.dart';
import '../../services/storage_services.dart';

class UpdateProfileController extends GetxController {
  Rx<UpdateProfileController?> updateProfileResponse =
      Rx<UpdateProfileController?>(null);
  RxBool isLoading = false.obs;

  /// Fetch booking data based on the given country and request body
  Future<void> updateProfile({
    required final Map<String, dynamic> requestData,
    required BuildContext context,
  }) async {
    try {
      print('yash update profile req body : ${requestData}');

      final response = await ApiService()
          .patchRequest('user/updateUserDetails', requestData);
      updateProfileResponse.value =
          UpdateProfileResponse.fromJson(response) as UpdateProfileController?;
      print('yash update profile response : ${updateProfileResponse.value}');
      // Show success message (as snackbar or dialog)
      _successLoader('Profile updated Successfully', context);
    } catch (e) {
      Navigator.pop(context);
      Get.snackbar("Error", e.toString());

    } finally {
      isLoading.value = false;
    }
  }
}

void _showLoader(String message, BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true, // Prevent closing by tapping outside
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 16),
                Text(message, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    },
  );
  Future.delayed(const Duration(seconds: 3), () {
    Navigator.pop(context); // Close loader
  });
  // Fake delay to simulate loading
}
void _successLoader(String message, BuildContext outerContext) {
  showDialog(
    context: outerContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      // Start delayed closure using outerContext
      Future.delayed(const Duration(seconds: 1), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop(); // Close dialog
        }

        if (Navigator.of(outerContext).canPop()) {
          Navigator.of(outerContext).pop(); // Navigate back
        }
      });

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(message, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    },
  );
}
