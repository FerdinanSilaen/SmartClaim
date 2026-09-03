import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analytics_data.dart';

class AnalyticsService {
  static const String baseUrl =
      'http://127.0.0.1:8000';

  // ============================================================
  // GET ANALYTICS FILTERS
  // ============================================================

  static Future<AnalyticsFilters>
      getFilters() async {
    final uri = Uri.parse(
      '$baseUrl/api/analytics/filters',
    );

    try {
      final response =
          await http.get(uri);

      if (response.statusCode !=
          200) {
        throw Exception(
          'Gagal mengambil filter Analytics '
          '(HTTP ${response.statusCode})\n'
          '${response.body}',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Format response Analytics Filters tidak valid.',
        );
      }

      return AnalyticsFilters.fromJson(
        decoded,
      );
    } catch (error) {
      throw Exception(
        'Gagal terhubung ke Analytics API: $error',
      );
    }
  }

  // ============================================================
  // GET ANALYTICS OVERVIEW
  //
  // MULTIFILTER FORMAT:
  //
  // year=2025,2026
  // coverage=GP,DENTAL
  // claim_type=M,R
  // result=ACC,REJECT
  // provider_code=P001,P002
  // corp_code=C001,C002
  // ============================================================

  static Future<AnalyticsOverview>
      getOverview({
    String? year,
    String? coverage,
    String? claimType,
    String? result,
    String? providerCode,
    String? corpCode,
  }) async {
    final query =
        <String, String>{};

    // ==========================================================
    // YEAR
    // ==========================================================

    final cleanYear =
        _cleanFilterValue(
      year,
    );

    if (cleanYear != null) {
      query['year'] =
          cleanYear;
    }

    // ==========================================================
    // COVERAGE
    // ==========================================================

    final cleanCoverage =
        _cleanFilterValue(
      coverage,
    );

    if (cleanCoverage != null) {
      query['coverage'] =
          cleanCoverage;
    }

    // ==========================================================
    // CLAIM TYPE
    // ==========================================================

    final cleanClaimType =
        _cleanFilterValue(
      claimType,
    );

    if (cleanClaimType != null) {
      query['claim_type'] =
          cleanClaimType;
    }

    // ==========================================================
    // RESULT
    // ==========================================================

    final cleanResult =
        _cleanFilterValue(
      result,
    );

    if (cleanResult != null) {
      query['result'] =
          cleanResult;
    }

    // ==========================================================
    // PROVIDER
    // ==========================================================

    final cleanProvider =
        _cleanFilterValue(
      providerCode,
    );

    if (cleanProvider != null) {
      query['provider_code'] =
          cleanProvider;
    }

    // ==========================================================
    // CORPORATION
    // ==========================================================

    final cleanCorporation =
        _cleanFilterValue(
      corpCode,
    );

    if (cleanCorporation != null) {
      query['corp_code'] =
          cleanCorporation;
    }

    // ==========================================================
    // BUILD URL
    // ==========================================================

    final uri = Uri.parse(
      '$baseUrl/api/analytics/overview',
    ).replace(
      queryParameters:
          query.isEmpty
              ? null
              : query,
    );

    try {
      final response =
          await http.get(uri);

      if (response.statusCode !=
          200) {
        throw Exception(
          'Gagal mengambil Analytics Overview '
          '(HTTP ${response.statusCode})\n'
          '${response.body}',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Format response Analytics Overview tidak valid.',
        );
      }

      // ========================================================
      // BACKEND ERROR RESPONSE CHECK
      // ========================================================

      if (decoded.containsKey(
        'error',
      )) {
        throw Exception(
          decoded['error']
              .toString(),
        );
      }

      return AnalyticsOverview.fromJson(
        decoded,
      );
    } catch (error) {
      throw Exception(
        'Gagal terhubung ke Analytics API: $error',
      );
    }
  }

  // ============================================================
  // CLEAN MULTI FILTER VALUE
  //
  // Contoh:
  //
  // " GP , DENTAL ,, H&S "
  //
  // menjadi:
  //
  // "GP,DENTAL,H&S"
  // ============================================================

  static String? _cleanFilterValue(
    String? value,
  ) {
    if (value == null) {
      return null;
    }

    final values =
        value
            .split(',')
            .map(
              (item) =>
                  item.trim(),
            )
            .where(
              (item) =>
                  item.isNotEmpty,
            )
            .toSet()
            .toList();

    if (values.isEmpty) {
      return null;
    }

    return values.join(',');
  }
}