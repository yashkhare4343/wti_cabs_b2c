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

import 'package:get/get.dart';
import '../../../config/enviornment_config.dart';
import '../../response/api_response.dart';
import '../../services/storage_services.dart';
import '../../model/corporate/crp_login_response/crp_login_response.dart';
import '../../controller/corporate/crp_login_controller/crp_login_controller.dart';

class CprApiService {
  CprApiService._internal();
  static final CprApiService _instance = CprApiService._internal();
  factory CprApiService() => _instance;

  final String baseUrl = 'http://103.208.202.180:120/api/Info';
  // final String baseUrl = 'http://192.168.1.60:120/api/Info';

  final String priceBaseUrl = EnvironmentConfig.priceBaseUrl;

  // Corporate APIs use the corporate key (`crpKey`) as the auth token.
  Future<String?> _getToken() async => await StorageServices.instance.read('crpKey');
  Future<String?> _getRefreshToken() async => await StorageServices.instance.read('refreshToken');

  Future<void> _saveToken(String token) async =>
      await StorageServices.instance.save('crpKey', token);
  
  /// Fallback loader for corporate email (used for `user`/`email` query params)
  Future<String?> _getEmailFallback() async {
    final storedEmail = await StorageServices.instance.read('email');
    if (storedEmail != null && storedEmail.isNotEmpty && storedEmail != 'null') {
      return storedEmail;
    }
    final prefs = await SharedPreferences.getInstance();
    final prefsEmail = prefs.getString('email');
    if (prefsEmail != null && prefsEmail.isNotEmpty && prefsEmail != 'null') {
      return prefsEmail;
    }
    return null;
  }

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

  // ===================== 🔐 Re-login with stored credentials =====================
  Future<String?> _getPasswordFallback() async {
    final storedPassword = await StorageServices.instance.read('crpPassword');
    if (storedPassword != null && storedPassword.isNotEmpty && storedPassword != 'null') {
      return storedPassword;
    }
    final prefs = await SharedPreferences.getInstance();
    final prefsPassword = prefs.getString('crpPassword');
    if (prefsPassword != null && prefsPassword.isNotEmpty && prefsPassword != 'null') {
      return prefsPassword;
    }
    return null;
  }

  Future<bool> _reLoginWithStoredCredentials() async {
    try {
      final email = await _getEmailFallback();
      final password = await _getPasswordFallback();

      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Cannot re-login: missing stored email or password');
        }
        return false;
      }

      final params = {
        'email': email,
        'password': password,
        'android_gcm': '',
        'ios_token': '',
      };

      final uri = Uri.parse('$baseUrl/GetLoginInfoV1')
          .replace(queryParameters: params.map((k, v) => MapEntry(k, v.toString())));

      final headers = {
        'Content-Type': 'application/json',
        // Always use app basic auth for login, not the (possibly expired) crpKey
        'Authorization': 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
      };

      if (kDebugMode) {
        debugPrint('🔐 Re-login attempt with stored credentials');
        debugPrint('📡 [GET] Login URL: $uri');
      }

      final response = await http.get(uri, headers: headers);

      if (kDebugMode) {
        debugPrint('🔐 Re-login status: ${response.statusCode}');
        debugPrint('🔐 Re-login body: ${response.body}');
      }

      if (response.statusCode != 200) {
        return false;
      }

      // Handle wrapped / nested JSON like "\"{...}\""
      dynamic jsonBody = jsonDecode(response.body);
      try {
        if (jsonBody is String &&
            ((jsonBody.startsWith('{') && jsonBody.endsWith('}')) ||
                (jsonBody.startsWith('[') && jsonBody.endsWith(']')))) {
          jsonBody = jsonDecode(jsonBody);
        }
      } catch (e) {
        debugPrint('⚠️ Error decoding re-login body twice: $e');
      }

      final CrpLoginResponse loginResponse;

      if (jsonBody is Map<String, dynamic>) {
        loginResponse = CrpLoginResponse.fromJson(jsonBody);
      } else {
        // Fallback – at least capture message
        loginResponse =
            CrpLoginResponse.fromJson({'sMessage': jsonBody.toString()});
      }

      if (loginResponse.bStatus != true ||
          (loginResponse.key == null || loginResponse.key!.isEmpty)) {
        if (kDebugMode) {
          debugPrint('⚠️ Re-login failed: invalid status or key');
        }
        return false;
      }

      // Persist the new token & core session details
      await _saveToken(loginResponse.key ?? '');
      await StorageServices.instance.save('crpId', loginResponse.corpID?.toString() ?? '');
      await StorageServices.instance.save('branchId', loginResponse.branchID?.toString() ?? '');
      await StorageServices.instance.save('guestId', loginResponse.guestID.toString());
      await StorageServices.instance.save('guestName', loginResponse.guestName ?? '');

      // Update LoginInfoController if it exists to keep it in sync
      try {
        if (Get.isRegistered<LoginInfoController>()) {
          final loginInfoController = Get.find<LoginInfoController>();
          loginInfoController.crpLoginInfo.value = loginResponse;
          if (kDebugMode) debugPrint('✅ Updated LoginInfoController after re-login');
        }
      } catch (e) {
        // Controller might not be initialized yet, that's ok
        if (kDebugMode) debugPrint('ℹ️ LoginInfoController not found, skipping update: $e');
      }

      if (kDebugMode) debugPrint('✅ Corporate token refreshed via re-login');
      return true;
    } catch (e, st) {
      debugPrint('❌ Error during corporate re-login: $e');
      debugPrint('📄 Stacktrace: $st');
      return false;
    }
  }

  /// Public helper so UI/controllers can explicitly trigger a corporate re-login
  /// using the stored email & password (if available).
  ///
  /// This simply forwards to the internal `_reLoginWithStoredCredentials`
  /// which is already used by the retry logic above.
  Future<bool> reLoginWithStoredCredentials() async {
    return _reLoginWithStoredCredentials();
  }

  // ===================== 🧠 Generic Retry Wrapper =====================
  Future<http.Response> _sendRequestWithRetry(
      Future<http.Response> Function() requestFn) async {
    http.Response response = await requestFn();

    if (response.statusCode == 401 || response.statusCode == 403) {
      // First try refresh-token flow
      final refreshed = await _refreshToken();
      if (refreshed) {
        return await requestFn();
      }

      // If refresh-token failed, try to re-login with stored credentials
      final reLoggedIn = await _reLoginWithStoredCredentials();
      if (reLoggedIn) {
        return await requestFn();
      }
    }

    return response;
  }

  /// Public helper so controllers/screens can also benefit from 401 → re-login logic
  Future<http.Response> sendRequestWithRetry(
      Future<http.Response> Function() requestFn) async {
    return _sendRequestWithRetry(requestFn);
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

    dynamic body = jsonDecode(response.body);
    
    // Handle double-encoded JSON strings
    if (body is String) {
      // If body is a string, it might be a JSON-encoded string that needs decoding
      if (body.startsWith('"') && body.endsWith('"')) {
        body = jsonDecode(body);
        debugPrint('🔁 Decoded once from wrapped string');
      }
      
      // If it's still a string and looks like JSON, decode it again
      if (body is String && 
          ((body.startsWith('{') && body.endsWith('}')) ||
           (body.startsWith('[') && body.endsWith(']')))) {
        body = jsonDecode(body);
        debugPrint('🔁 Decoded twice for nested JSON');
      }
    }
    
    // Ensure we return a Map
    if (body is Map<String, dynamic>) {
      if (response.statusCode == 200) return body;
      throw Exception("❌ ${response.statusCode} - ${body['message'] ?? 'Error'}");
    } else {
      // If body is not a Map, try to convert or throw error
      debugPrint('⚠️ Response body is not a Map: ${body.runtimeType}');
      if (response.statusCode == 200) {
        // Try to return as empty map or handle gracefully
        return <String, dynamic>{};
      }
      throw Exception("❌ ${response.statusCode} - Unexpected response format");
    }
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

    // 🔄 Step 1 & 2: Make request with retry (refresh token / re-login on 401)
    http.Response response = await _sendRequestWithRetry(() => sendRequest());

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
    // ✅ Automatically add token and user to params if not already present
    final token = await _getToken();
    final userEmail = await _getEmailFallback();
    
    // Always ensure email and user are set from storage if available
    // This handles cases where params might have null values
    if (userEmail != null && userEmail.isNotEmpty) {
      final emailParam = params['email']?.toString();
      final userParam = params['user']?.toString();
      
      // Replace email if it's null, empty, or the string "null"
      if (emailParam == null || emailParam.isEmpty || emailParam == 'null') {
        params['email'] = userEmail;
        debugPrint('✅ Auto-populated email from storage: $userEmail');
      }
      
      // Replace user if it's null, empty, or the string "null"
      if (userParam == null || userParam.isEmpty || userParam == 'null') {
        params['user'] = userEmail;
        debugPrint('✅ Auto-populated user from storage: $userEmail');
      }
    } else {
      // Remove null/empty email and user to avoid sending them
      if (params['email'] == null || params['email'].toString() == 'null' || params['email'].toString().isEmpty) {
        params.remove('email');
        debugPrint('⚠️ Email not found in storage, removing from params');
      }
      if (params['user'] == null || params['user'].toString() == 'null' || params['user'].toString().isEmpty) {
        params.remove('user');
        debugPrint('⚠️ User not found in storage, removing from params');
      }
    }
    
    // Add token to params if not already present and token exists
    if (!params.containsKey('token') && token != null && token.isNotEmpty) {
      params['token'] = token;
      debugPrint('✅ Auto-added token to query params');
    } else if (params.containsKey('token') && (params['token'] == null || params['token'].toString() == 'null' || params['token'].toString().isEmpty)) {
      // Replace null/empty token if it exists
      if (token != null && token.isNotEmpty) {
        params['token'] = token;
        debugPrint('✅ Replaced null/empty token with valid token');
      } else {
        params.remove('token');
      }
    }
    
    // Add GuestID to params if not already present or if it's empty
    final guestIDFromStorage = await StorageServices.instance.read('guestId');
    if (!params.containsKey('GuestID') && guestIDFromStorage != null && guestIDFromStorage.isNotEmpty) {
      params['GuestID'] = guestIDFromStorage;
      debugPrint('✅ Auto-added GuestID from storage to query params');
    } else if (params.containsKey('GuestID') && (params['GuestID'] == null || params['GuestID'].toString() == 'null' || params['GuestID'].toString().isEmpty)) {
      // Replace null/empty GuestID if it exists
      if (guestIDFromStorage != null && guestIDFromStorage.isNotEmpty) {
        params['GuestID'] = guestIDFromStorage;
        debugPrint('✅ Replaced null/empty GuestID with value from storage');
      }
    }
    
    // 🧩 Build the full URL
    final uri = Uri.parse('$baseUrl/$endpoint')
        .replace(queryParameters: params.map((k, v) => MapEntry(k, v.toString())));

    print('yash crp url is : ${'$baseUrl/$endpoint'}');

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
      // 🔹 Step 1 & 2: First request + retry via generic handler
      http.Response response = await _sendRequestWithRetry(() => sendRequest(token));

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
    // ✅ Automatically add token and user to params if not already present
    final token = await _getToken();
    final userEmail = await _getEmailFallback();
    
    // Always ensure email and user are set from storage if available
    // This handles cases where params might have null values
    if (userEmail != null && userEmail.isNotEmpty) {
      final emailParam = params['email']?.toString();
      final userParam = params['user']?.toString();
      
      // Replace email if it's null, empty, or the string "null"
      if (emailParam == null || emailParam.isEmpty || emailParam == 'null') {
        params['email'] = userEmail;
        debugPrint('✅ Auto-populated email from storage (POST): $userEmail');
      }
      
      // Replace user if it's null, empty, or the string "null"
      if (userParam == null || userParam.isEmpty || userParam == 'null') {
        params['user'] = userEmail;
        debugPrint('✅ Auto-populated user from storage (POST): $userEmail');
      }
    } else {
      // Remove null/empty email and user to avoid sending them
      if (params['email'] == null || params['email'].toString() == 'null' || params['email'].toString().isEmpty) {
        params.remove('email');
        debugPrint('⚠️ Email not found in storage, removing from params (POST)');
      }
      if (params['user'] == null || params['user'].toString() == 'null' || params['user'].toString().isEmpty) {
        params.remove('user');
        debugPrint('⚠️ User not found in storage, removing from params (POST)');
      }
    }
    
    // Add token to params if not already present and token exists
    if (!params.containsKey('token') && token != null && token.isNotEmpty) {
      params['token'] = token;
      debugPrint('✅ Auto-added token to query params (POST)');
    } else if (params.containsKey('token') && (params['token'] == null || params['token'].toString() == 'null')) {
      // Replace null token if it exists
      if (token != null && token.isNotEmpty) {
        params['token'] = token;
        debugPrint('✅ Replaced null token with valid token (POST)');
      } else {
        params.remove('token');
      }
    }
    
    // Encode params as query string
    final uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: params.map((k, v) => MapEntry(k, v.toString())));
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

  // ===================== 📝 POST Make Booking =====================
  Future<Map<String, dynamic>> postMakeBooking(
    Map<String, dynamic> params,
    BuildContext context,
  ) async {
    return await postRequestParamsNew<Map<String, dynamic>>(
      "PostMakeBooking",
      params,
      (body) {
        if (body is Map) {
          return Map<String, dynamic>.from(body);
        }
        return {"response": body};
      },
      context,
    );
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

    // 🔄 Step 1 & 2: First attempt + retry via generic handler
    http.Response response = await _sendRequestWithRetry(() => sendRequest(token));

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
