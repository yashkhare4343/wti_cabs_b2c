import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';

class ConnectivityController extends GetxController {
  var isOnline = true.obs; // Observable variable for network status
  final Connectivity _connectivity = Connectivity();

  @override
  void onInit() {
    super.onInit();
    checkInitialConnection();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void checkInitialConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool hasConnection = results.any((result) =>
    result == ConnectivityResult.mobile || result == ConnectivityResult.wifi);
    isOnline.value = hasConnection;
  }

}
