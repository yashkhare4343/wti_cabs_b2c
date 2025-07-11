import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// import 'package:wti_cabs/core/model/upload_image/upload_image.dart';
import '../../config/enviornment_config.dart';
import '../../utility/constants/fonts/common_fonts.dart';
import '../response/api_response.dart';

class ApiService {
  // Private constructor for singleton
  ApiService._internal();

  // The single instance
  static final ApiService _instance = ApiService._internal();

  // Factory constructor returns the same instance
  factory ApiService() => _instance;

  // Base URLs
  // final String baseUrl = '${EnvironmentConfig.baseUrl}/global/app/v1';
  final String baseUrl = 'https://test.wticabs.com:5001/global/app/v1';
  // final String baseUrl = 'https://www.wticabs.com:3001/global/app/v1';

  final String priceBaseUrl = EnvironmentConfig.priceBaseUrl;

  Future<String?> _getToken() async {
    if (Platform.isIOS) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } else {
      final secureStorage = FlutterSecureStorage();
      return await secureStorage.read(key: 'token');
    }
  }

  Future<Map<String, dynamic>> getRequest(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();
    final basicAuth = 'Basic ${base64Encode(utf8.encode('harsh:123'))}';
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

  // new get request
  Future<T> getRequestNew<T>(
      String endpoint,
      T Function(Map<String, dynamic>) fromJson,
      ) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();
    final basicAuth = 'Basic ${base64Encode(utf8.encode('harsh:123'))}';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
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


  Future<Map<String, dynamic>> currencyConverter(String currency) async {
    final url = Uri.parse('http://3.222.206.52:4000/global/app/v1/currency/currencyConversion/$currency');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic aGFyc2g6MTIz',
    };

    try {
      final response = await http.get(url, headers: headers);
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




  // Future<UploadImageResponse?> postMultipart(File imageFile) async {
  //   final String uploadUrl = "https://global.wticabs.com:4001/0auth/v1/AwsRoutes/upload/driverApp";
  //   final token = await _getToken();
  //   final headers = {
  //     'Authorization': token != null ? 'Bearer $token' : '',
  //   };
  //
  //   var request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
  //     ..headers.addAll(headers)
  //     ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
  //
  //   try {
  //     final response = await request.send();
  //     final responseData = await response.stream.bytesToString();
  //     final jsonResponse = json.decode(responseData);
  //
  //     if (response.statusCode == 200) {
  //       return UploadImageResponse.fromJson(jsonResponse);
  //     } else {
  //       throw Exception("Failed to upload image: ${jsonResponse['message'] ?? 'Unknown error'}");
  //     }
  //   } catch (e) {
  //     return null;
  //   }
  // }

  Future<Map<String, dynamic>> patchRequest(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();
    final basicAuth = 'Basic ${base64Encode(utf8.encode('harsh:123'))}';

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

  Future<bool> requestStoragePermissionForPDF() async {
    if (Platform.isAndroid) {
      try {
        final versionMatch = RegExp(r'(\d+)').firstMatch(Platform.operatingSystemVersion);
        final androidVersion = versionMatch != null ? int.parse(versionMatch.group(0)!) : 0;

        if (androidVersion >= 13) {
          final storageStatus = await Permission.manageExternalStorage.status;
          if (!storageStatus.isGranted) {
            final result = await Permission.manageExternalStorage.request();
            return result.isGranted;
          }
          return true;
        } else {
          final storagePermission = await Permission.storage.status;
          if (!storagePermission.isGranted) {
            final result = await Permission.storage.request();
            return result.isGranted;
          }
          return true;
        }
      } catch (e) {
        return false;
      }
    } else if (Platform.isIOS) {
      return true;
    }
    return false;
  }

  Future<void> shareFile(String fileName) async {
    final directory = await getDownloadDirectory();
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    if (await file.exists()) {
      final xFile = XFile(filePath);
      await Share.shareXFiles([xFile], text: "Check out this invoice!");
    } else {
      throw Exception("File does not exist: $filePath");
    }
  }

  Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ?? Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      throw Exception("Unsupported platform.");
    }
  }
}
