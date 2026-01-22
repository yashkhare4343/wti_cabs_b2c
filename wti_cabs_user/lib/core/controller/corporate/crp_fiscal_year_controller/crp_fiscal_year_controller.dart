import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CrpFiscalYearController extends GetxController {
  // Keep this aligned with corporate API base in `CprApiService`,
  // but use direct HTTP here (no auto user/email params).
  static const String _baseUrl = 'http://services.aaveg.co.in/api/Info';

  final isLoading = false.obs;
  final years = <int>[].obs; // e.g. [2025, 2026]

  Future<void> fetchFiscalYears(BuildContext context) async {
    try {
      isLoading.value = true;

      // API: {{baseUrl}}/api/Info/GetFiscal
      // Our corporate base already includes `/api/Info`, so endpoint is `/GetFiscal`.
      // Response example: "[{\"FinancialYear\":2026,\"Year\":\"2025-2026\"}]"
      final uri = Uri.parse('$_baseUrl/GetFiscal');
      final response = await http.get(
        uri,
        headers: const {
          'Content-Type': 'application/json',
        },
      );

      dynamic body = response.body;
      try {
        if (body is String && body.isNotEmpty) {
          // First decode: might be a JSON string (wrapped) or actual JSON.
          body = jsonDecode(body);
          // If still a string containing JSON, decode again.
          if (body is String &&
              ((body.startsWith('[') && body.endsWith(']')) ||
                  (body.startsWith('{') && body.endsWith('}')))) {
            body = jsonDecode(body);
          }
        }
      } catch (e) {
        debugPrint('CRP Fiscal Year Decode Error: $e');
      }

      final List<dynamic> list = body is List ? body : <dynamic>[];
      final Set<int> extractedYears = <int>{};

      for (final item in list) {
        if (item is! Map) continue;
        final yearRange = item['Year']?.toString() ?? '';

        // Extract 4-digit years from strings like "2025-2026"
        for (final match in RegExp(r'\b\d{4}\b').allMatches(yearRange)) {
          final parsed = int.tryParse(match.group(0) ?? '');
          if (parsed != null) extractedYears.add(parsed);
        }
      }

      final sorted = extractedYears.toList()..sort();
      years.assignAll(sorted);
    } catch (e) {
      debugPrint('CRP Fiscal Year Fetch Error: $e');
      years.clear();
    } finally {
      isLoading.value = false;
    }
  }
}

