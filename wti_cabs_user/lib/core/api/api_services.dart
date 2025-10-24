import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// import 'package:wti_cabs/core/model/upload_image/upload_image.dart';
import '../../common_widget/loader/popup_loader.dart';
import '../../config/enviornment_config.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../response/api_response.dart';
import '../services/storage_services.dart';

class ApiService {
  // Private constructor for singleton
  ApiService._internal();

  // The single instance
  static final ApiService _instance = ApiService._internal();

  // Factory constructor returns the same instance
  factory ApiService() => _instance;

  // Base URLs
  // final String baseUrl = '${EnvironmentConfig.baseUrl}/global/app/v1';
  // final String baseUrl = 'http://13.200.168.251:3002/global/app/v1';
  final String baseUrl = 'https://www.wticabs.com:3001/global/app/v1';

  final String priceBaseUrl = EnvironmentConfig.priceBaseUrl;

  Future<String?> _getToken() async {
    return await StorageServices.instance.read('token');
  }

  Future<Map<String, dynamic>> getRequest(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();
    print('yash token : $token');
    final basicAuth = token !=null ? 'Basic $token' : 'Basic ${base64Encode(utf8.encode('harsh:123'))}';
    // final basicAuth = 'Basic ${base64Encode(utf8.encode('harsh:123'))}';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };

    print('url is : $baseUrl/$endpoint');
    print('header is : $headers');


    try {
      final response = await http.get(url, headers: headers);
      print('response is : ${response.body}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
            "Failed to get data. Status Code: ${response.statusCode}, Error: ${errorResponse['message'] ?? 'Unknown error'}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
//
  Future<Map<String, dynamic>> getRequestCurrency(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    // final token = await _getToken();
    // print('yash token : $token');
    // final basicAuth = 'Basic ${base64Encode(utf8.encode('harsh:123'))}';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic aGFyc2g6MTIz',
    };

    print('url is : $baseUrl/$endpoint');
    print('header is : $headers');


    try {
      final response = await http.get(url, headers: headers);
      print('response is : ${response.body}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
            "Failed to get data. Status Code: ${response.statusCode}, Error: ${errorResponse['message'] ?? 'Unknown error'}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }


  // new get request
  Future<T> getRequestNew<T>(
      String endpoint,
      T Function(Map<String, dynamic>) fromJson,
      ) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();
    // final basicAuth = token !=null ? 'Basic $token' : 'Basic ${base64Encode(utf8.encode('harsh:123'))}';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic aGFyc2g6MTIz',
    };

    if (kDebugMode) {
      debugPrint('🌐 GET Request: $url');
      debugPrint('🧾 Headers: $headers');
    }

    try {
      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        debugPrint("✅ Response Status: ${response.statusCode}");
        debugPrint("📥 Response Body:\n${response.body}");
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (response.statusCode == 200) {
        return fromJson(jsonData); // ✅ deserialize with parser
      } else {
        final errorMessage = jsonData['message'] ?? 'Unknown error occurred';
        throw Exception("❌ Failed: $errorMessage");
      }
    } catch (e) {
      debugPrint("❌ Network error: $e");
      throw Exception("❌ Exception: $e");
    }
  }

  Future<double> getCurrencyConversionRate({
    required String from,
  }) async {
    final basicAuth = 'Basic ${base64Encode(utf8.encode('harsh:123'))}';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic aGFyc2g6MTIz',
    };
    final url = Uri.parse("$baseUrl/currency/convert?from=$from");
    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["currencyConverted"] == true) {
        return (data["data"] as num).toDouble();
      }
    }

    throw Exception("Failed to fetch rate $from");
  }

  Future<Map<String, dynamic>> postRequest(
      String endpoint,
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken(); // (if needed, or remove if unused)
    final basicAuth = 'Basic ${base64Encode(utf8.encode('harsh:123'))}';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };

    // 🔍 Pretty print request body
    if (kDebugMode) {
      final encoder = JsonEncoder.withIndent('  ');
      debugPrint('📤 POST Request to: $url');
      debugPrint('🧾 Headers: $headers');
      debugPrint('📦 Request Body:\n${encoder.convert(data)}');
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      );

      if (kDebugMode) {
        debugPrint("✅ Response Status: ${response.statusCode}");
        debugPrint("📥 Response Body:\n${response.body}");
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        final errorMessage = responseData['message'] ?? "An unexpected error occurred.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: CommonFonts.primaryButtonText),
            backgroundColor: Colors.red,
          ),
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Network error: $e");
      }
      throw Exception("Failed to connect to the server.");
    }
  }
  Future<Map<String, dynamic>> postPriceRequest(String endpoint, Map<String, dynamic> data, BuildContext context) async {
    final url = Uri.parse('$priceBaseUrl/$endpoint');
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(url, headers: headers, body: json.encode(data));
      if (kDebugMode) {
        print("Response status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        final errorMessage = responseData['message'] ?? "An unexpected error occurred.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: CommonFonts.primaryButtonText),
            backgroundColor: Colors.red,
          ),
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Network error: $e");
      }
      throw Exception("Failed to connect to the server.");
    }
  }


  Future<T> postRequestNew<T>(
      String endpoint,
      Map<String, dynamic> data,
      T Function(Map<String, dynamic>) fromJson,
      BuildContext context,
      ) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken(); // if unused, you may safely remove it
    final basicAuth = 'Basic ${base64Encode(utf8.encode('harsh:123'))}';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };

    if (kDebugMode) {
      final encoder = JsonEncoder.withIndent('  ');
      debugPrint('📤 POST Request to: $url');
      debugPrint('🧾 Headers: $headers');
      debugPrint('📦 Request Body:\n${encoder.convert(data)}');
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      );

      if (kDebugMode) {
        debugPrint("✅ Response Status: ${response.statusCode}");
        debugPrint("📥 Response Body:\n${response.body}");
      }

      if (response.body.isEmpty) {
        debugPrint("❗ Empty response body");
        throw Exception("Server returned an empty response.");
      }

      final decodedBody = json.decode(response.body);

      if (decodedBody == null) {
        debugPrint("❗ Decoded response is null");
        throw Exception("Failed to decode response.");
      }

      if (decodedBody is! Map<String, dynamic>) {
        debugPrint("❗ Response is not a Map<String, dynamic>: $decodedBody");
        throw Exception("Unexpected response format from server.");
      }

      if (response.statusCode == 200) {
        return fromJson(decodedBody);
      } else {
        final errorMessage = decodedBody['message'] ?? "An unexpected error occurred.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: CommonFonts.primaryButtonText),
            backgroundColor: Colors.red,
          ),
        );
        throw Exception(errorMessage);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint("❌ Network error: $e");
        debugPrint("🪵 Stack trace: $stack");
      }
      throw Exception("Failed to connect to the server.");
    }
  }

  Future<Map<String, dynamic>> patchRequest(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();
    final basicAuth = 'Basic $token';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };

    try {
      final response = await http.patch(url, headers: headers, body: json.encode(data));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty ? json.decode(response.body) : {};
      } else {
        final errorResponse = json.decode(response.body);
        ApiResponse.showSnackbar("Error", errorResponse['message'] ?? "An unexpected error occurred.");
        throw Exception("Failed to patch data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // ==== post method with status
  Future<Map<String, dynamic>> postRequestWithStatus({
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
      'x-platform':'APP'
    };

    final mergedHeaders = {
      ...defaultHeaders,
      if (headers != null) ...headers,
    };

    final response = await http.post(
      url,
      headers: mergedHeaders,
      body: jsonEncode(data),
    );

    return {
      "statusCode": response.statusCode,
      "body": jsonDecode(response.body),
    };
  }

  // ==============

  Future<void> downloadPdfWithHttp({
    required String endpoint,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    required String filePath,
  }) async {
    final url = Uri.parse("$baseUrl/$endpoint");

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    print('yash download reciept body : ${jsonEncode(body)}');

    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception("Failed to download PDF. Status: ${response.statusCode}");
    }
  }

  Future<void> downloadPdfFromGetApi({
    required BuildContext context,
    required String endpoint,
    required String fileName,
    required Map<String, String> headers,
  }) async {
    try {
      // ✅ Permission check for Android
      // if (Platform.isAndroid) {
      //   final androidInfo = await DeviceInfoPlugin().androidInfo;
      //   final sdkInt = androidInfo.version.sdkInt;
      //
      //   PermissionStatus permissionStatus;
      //
      //   if (sdkInt >= 30) {
      //     permissionStatus = await Permission.manageExternalStorage.request();
      //   } else {
      //     permissionStatus = await Permission.storage.request();
      //   }
      //
      //   if (!permissionStatus.isGranted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text("❌ Storage permission denied."),
      //         backgroundColor: Colors.red,
      //       ),
      //     );
      //     return;
      //   }
      // }

      final url = Uri.parse('$baseUrl/$endpoint');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = "${dir.path}/$fileName";

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        GoRouter.of(context).pop();

        await OpenFile.open(filePath);
      } else {
        throw Exception("Failed to download PDF. Status: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait to complete bookings'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}