import 'package:get/get.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class SelectedTripController extends GetxController {
  // Stores the selected car/item data
  Rxn<AnalyticsEventItem> selectedItem = Rxn<AnalyticsEventItem>();

  // Stores analytics/event parameters
  RxMap<String, dynamic> parameters = <String, dynamic>{}.obs;

  // Set initial item and parameter data
  void setTripData({
    required AnalyticsEventItem item,
    required Map<String, dynamic> params,
  }) {
    selectedItem.value = item;
    parameters.assignAll(params);
  }

  // ✅ Add or merge custom parameters
  void addCustomParameters(Map<String, dynamic> newParams) {
    parameters.addAll(newParams);
  }

  // Clear data when needed
  void clearTripData() {
    selectedItem.value = null;
    parameters.clear();
  }
}
