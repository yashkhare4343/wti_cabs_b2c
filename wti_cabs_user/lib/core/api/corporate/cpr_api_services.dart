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

import '../../../config/enviornment_config.dart';
import '../../response/api_response.dart';
import '../../services/storage_services.dart';

class CprApiService {
  CprApiService._internal();
  static final CprApiService _instance = CprApiService._internal();
  factory CprApiService() => _instance;

  final String baseUrl = 'http://103.208.202.180:120/api/Info';
  // final String baseUrl = 'http://192.168.1.60:120/api/Info';

  final String priceBaseUrl = EnvironmentConfig.priceBaseUrl;

  Future<String?> _getToken() async => await StorageServices.instance.read('token');
  Future<String?> _getRefreshToken() async => await StorageServices.instance.read('refreshToken');

  Future<void> _saveToken(String token) async =>
      await StorageServices.instance.save('token', token);

  // ===================== 🔄 Refresh Token Logic =====================
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final url = Uri.parse('$baseUrl/auth/refresh');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'refresh_token': refreshToken});

      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        if (newToken != null) {
          await _saveToken(newToken);
          if (kDebugMode) debugPrint("✅ Token refreshed successfully");
          return true;
        }
      }

      if (kDebugMode) debugPrint("⚠️ Token refresh failed: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("❌ Refresh token error: $e");
      return false;
    }
  }

  // ===================== 🧠 Generic Retry Wrapper =====================
  Future<http.Response> _sendRequestWithRetry(Future<http.Response> Function() requestFn) async {
    http.Response response = await requestFn();

    if (response.statusCode == 401 || response.statusCode == 403) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newResponse = await requestFn();
        return newResponse;
      }
    }

    return response;
  }

  // ===================== 🟢 GET =====================
  Future<Map<String, dynamic>> getRequest(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token != null
          ? 'Basic $token'
          : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
    };

    final response = await _sendRequestWithRetry(() => http.get(url, headers: headers));
    debugPrint('🌐 GET $url → ${response.statusCode}');

    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    throw Exception("❌ ${response.statusCode} - ${body['message'] ?? 'Error'}");
  }

  // ===================== 🟡 POST =====================
  Future<Map<String, dynamic>> postRequest(
      String endpoint, Map<String, dynamic> data, BuildContext context) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token != null
          ? 'Basic $token'
          : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
    };

    final response = await _sendRequestWithRetry(() =>
        http.post(url, headers: headers, body: jsonEncode(data)));

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) return body;

    final errorMessage = body['message'] ?? "Unexpected error";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
    throw Exception(errorMessage);
  }

  Future<T> getRequestNew<T>(
      String endpoint,
      T Function(Map<String, dynamic>) fromJson,
      ) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();

    Future<http.Response> sendRequest() async {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': token != null
            ? 'Basic $token'
            : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
      };

      if (kDebugMode) {
        debugPrint('🌐 GET Request: $url');
        debugPrint('🧾 Headers: $headers');
      }

      return await http.get(url, headers: headers);
    }

    // 🔄 Step 1: Make request
    http.Response response = await sendRequest();

    // 🔄 Step 2: Handle token expiry
    if (response.statusCode == 401 || response.statusCode == 403) {
      if (kDebugMode) debugPrint("⚠️ Token expired, trying to refresh...");
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newToken = await _getToken(); // get updated token
        response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Basic $newToken',
          },
        );
      }
    }

    // 🧠 Step 3: Decode and parse
    if (kDebugMode) {
      debugPrint("✅ Response Status: ${response.statusCode}");
      debugPrint("📥 Response Body:\n${response.body}");
    }

    final Map<String, dynamic> jsonData = json.decode(response.body);

    if (response.statusCode == 200) {
      return fromJson(jsonData);
    } else {
      final errorMessage = jsonData['message'] ?? 'Unknown error occurred';
      throw Exception("❌ Failed: $errorMessage");
    }
  }

  Future<T> getRequestCrp<T>(
      String endpoint,
      Map<String, dynamic> params,
      T Function(dynamic) fromJson,
      BuildContext context,
      ) async {
    // 🧩 Build the full URL
    final uri = Uri.parse('$baseUrl/$endpoint')
        .replace(queryParameters: params.map((k, v) => MapEntry(k, v.toString())));

    print('yash crp url is : ${'$baseUrl/$endpoint'}');

    final token = await _getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token != null
          ? 'Basic $token'
          : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
    };

    // 🧾 Debug logging
    debugPrint('📡 [GET] Request URL: $uri');
    debugPrint('📦 Request Headers: $headers');
    debugPrint('🧮 Query Params: $params');

    final response =
    await _sendRequestWithRetry(() => http.get(uri, headers: headers));

    dynamic body = response.body;
    debugPrint('📥 Raw Response Body: $body');

    // 🧩 Handle possible escaped or malformed responses
    try {
      if (body is String && body.isNotEmpty) {
        // Handle wrapped JSON cases step-by-step
        if (body.startsWith('"') && body.endsWith('"')) {
          body = jsonDecode(body);
          debugPrint('🔁 Decoded once from wrapped string');
        }

        if (body is String &&
            ((body.startsWith('{') && body.endsWith('}')) ||
                (body.startsWith('[') && body.endsWith(']')))) {
          body = jsonDecode(body);
          debugPrint('🔁 Decoded twice for nested JSON');
        }
      }

      // 🧹 Handle empty or invalid response gracefully
      if (body == null || (body is String && body.trim().isEmpty)) {
        debugPrint('⚠️ Empty response body — returning empty JSON object');
        body = {};
      }
    } catch (e) {
      debugPrint('❌ Error decoding GET response: $e');
    }

    debugPrint('✅ Final Decoded Body: $body');

    // ✅ Success
    if (response.statusCode == 200) return fromJson(body);

    // ❌ Handle API errors
    final errorMessage =
    (body is Map && body['message'] != null) ? body['message'] : body.toString();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );

    throw Exception(errorMessage);
  }

  Future<Map<String, dynamic>> getRequestCurrency(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    // Fetch token if available
    String? token = await _getToken();

    // 🧠 Local helper function to send GET request
    Future<http.Response> sendRequest(String? currentToken) async {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': currentToken != null
            ? 'Basic $currentToken'
            : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
      };

      if (kDebugMode) {
        debugPrint('🌐 GET Request (Currency): $url');
        debugPrint('🧾 Headers: $headers');
      }

      return await http.get(url, headers: headers);
    }

    try {
      // 🔹 Step 1: First request
      http.Response response = await sendRequest(token);

      // 🔄 Step 2: If token expired, refresh and retry once
      if (response.statusCode == 401 || response.statusCode == 403) {
        if (kDebugMode) debugPrint("⚠️ Token expired — refreshing...");

        final refreshed = await _refreshToken();
        if (refreshed) {
          final newToken = await _getToken();
          response = await sendRequest(newToken);
        } else {
          throw Exception("❌ Token refresh failed");
        }
      }

      // ✅ Step 3: Handle final response
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
          "Failed to get data. "
              "Status Code: ${response.statusCode}, "
              "Error: ${errorResponse['message'] ?? 'Unknown error'}",
        );
      }
    } catch (e) {
      debugPrint("❌ Network error: $e");
      throw Exception("Error: $e");
    }
  }

  // ===================== 🔵 POST (Generic Model Parser) =====================
  Future<T> postRequestNew<T>(
      String endpoint,
      Map<String, dynamic> data,
      T Function(dynamic) fromJson,
      BuildContext context,
      ) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token != null
          ? 'Basic $token'
          : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
    };

    final response = await _sendRequestWithRetry(
          () => http.post(url, headers: headers, body: jsonEncode(data)),
    );

    dynamic body = response.body;

    // 🧩 Handle possible escaped response formats
    try {
      if (body is String) {
        // Decode until it's no longer wrapped in quotes
        while (body is String && body.startsWith('"') && body.endsWith('"')) {
          body = jsonDecode(body);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error decoding response: $e');
    }

    if (response.statusCode == 200) return fromJson(body);

    final errorMessage =
    (body is Map && body['message'] != null) ? body['message'] : body.toString();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );

    throw Exception(errorMessage);
  }

  Future<T> postRequestParamsNew<T>(
      String endpoint,
      Map<String, dynamic> params,
      T Function(dynamic) fromJson,
      BuildContext context,
      ) async {
    // Encode params as query string
    final uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: params.map((k, v) => MapEntry(k, v.toString())));

    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token != null
          ? 'Basic $token'
          : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
    };

    final response = await _sendRequestWithRetry(
          () => http.post(uri, headers: headers), // ✅ no body
    );

    dynamic body = response.body;

    try {
      if (body is String) {
        while (body is String && body.startsWith('"') && body.endsWith('"')) {
          body = jsonDecode(body);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error decoding response: $e');
    }

    if (response.statusCode == 200) return fromJson(body);

    final errorMessage =
    (body is Map && body['message'] != null) ? body['message'] : body.toString();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );

    throw Exception(errorMessage);
  }




  Future<Map<String, dynamic>> postRequestWithStatus({
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    // Get the stored token (if you’re using Basic or Bearer)
    String? token = await _getToken();

    // Define function that sends the actual request
    Future<http.Response> sendRequest(String? currentToken) async {
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': currentToken != null
            ? 'Basic $currentToken'
            : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
        'x-platform': 'APP',
      };

      final mergedHeaders = {
        ...defaultHeaders,
        if (headers != null) ...headers,
      };

      if (kDebugMode) {
        debugPrint('📤 POST Request: $url');
        debugPrint('🧾 Headers: $mergedHeaders');
        debugPrint('📦 Body: ${jsonEncode(data)}');
      }

      return await http.post(url, headers: mergedHeaders, body: jsonEncode(data));
    }

    // 🔄 Step 1: First attempt
    http.Response response = await sendRequest(token);

    // 🔄 Step 2: Token refresh if expired
    if (response.statusCode == 401 || response.statusCode == 403) {
      if (kDebugMode) debugPrint("⚠️ Token expired — attempting refresh...");
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newToken = await _getToken();
        response = await sendRequest(newToken); // Retry with new token
      } else {
        if (kDebugMode) debugPrint("❌ Token refresh failed");
        throw Exception("Token refresh failed");
      }
    }

    // 🧠 Step 3: Parse response
    if (kDebugMode) {
      debugPrint("✅ Response Status: ${response.statusCode}");
      debugPrint("📥 Response Body:\n${response.body}");
    }

    try {
      final decoded = jsonDecode(response.body);
      return {
        "statusCode": response.statusCode,
        "body": decoded,
      };
    } catch (e) {
      debugPrint("❌ Failed to decode response: $e");
      throw Exception("Failed to parse server response.");
    }
  }


  // ===================== 🟠 PATCH =====================
  Future<Map<String, dynamic>> patchRequest(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final token = await _getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic $token',
    };

    final response = await _sendRequestWithRetry(() =>
        http.patch(url, headers: headers, body: jsonEncode(data)));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : {};
    }

    final err = jsonDecode(response.body);
    ApiResponse.showSnackbar("Error", err['message'] ?? "Patch failed");
    throw Exception("Failed with ${response.statusCode}");
  }

  // ===================== 💰 PRICE POST =====================
  Future<Map<String, dynamic>> postPriceRequest(
      String endpoint, Map<String, dynamic> data, BuildContext context) async {
    final url = Uri.parse('$priceBaseUrl/$endpoint');
    final token = await _getToken();

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await _sendRequestWithRetry(() =>
        http.post(url, headers: headers, body: jsonEncode(data)));

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) return responseData;

    final errorMessage = responseData['message'] ?? "An unexpected error occurred.";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
    throw Exception(errorMessage);
  }

  // ===================== 🧾 Download PDF =====================
  Future<void> downloadPdfWithHttp({
    required String endpoint,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    required String filePath,
  }) async {
    final url = Uri.parse("$baseUrl/$endpoint");
    final response = await _sendRequestWithRetry(() =>
        http.post(url, headers: headers, body: jsonEncode(body)));

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
    final url = Uri.parse('$baseUrl/$endpoint');

    final response = await _sendRequestWithRetry(() => http.get(url, headers: headers));

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
  }
}
