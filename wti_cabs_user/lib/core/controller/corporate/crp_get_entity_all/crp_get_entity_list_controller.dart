import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';
import 'package:wti_cabs_user/core/model/booking_reservation/booking_reservation_response.dart';

import '../../../api/api_services.dart';
import '../../../api/corporate/cpr_api_services.dart';
import '../../../model/corporate/get_entity_list/get_entity_list_response.dart';
import '../../../model/self_drive/get_all_cities/get_all_cities_response.dart';
import '../crp_branch_list_controller/crp_branch_list_controller.dart';


class CrpGetEntityListController extends GetxController {
  Rx<EntityListResponse?> getAllEntityList = Rx<EntityListResponse?>(null);
  final CrpBranchListController crpGetBranchListController = Get.find<CrpBranchListController>();
  RxBool isLoading = false.obs;

  Future<void> fetchAllEntities(String email, String selectedBranchId) async {
    isLoading.value = true;
    try {
      final result = await CprApiService().getRequestNew<EntityListResponse>(
        'GetUserEntities?email=$email',
        EntityListResponse.fromJson,
      );
      getAllEntityList.value = result;

    } catch (e) {
      print("Failed to fetch entity: $e");
    } finally {
      isLoading.value = false;
    }
  }
}