import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/claim_record.dart';

class ClaimService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ============================================================
  // HELPER
  // Mengubah:
  //
  // "GP,DENTAL,OPTIC"
  //
  // menjadi:
  //
  // ["GP", "DENTAL", "OPTIC"]
  //
  // Ini diperlukan supaya query URL dapat dikirim sebagai:
  //
  // coverage=GP&coverage=DENTAL&coverage=OPTIC
  // ============================================================

  static List<String> _parseMultiValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return <String>[];
    }

    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  // ============================================================
  // GET CLAIMS
  // ============================================================

  static Future<ClaimPage> getClaims({
    int page = 1,
    int limit = 25,
    String search = '',
    String? status,
    String? coverage,
    String? claimType,
    String? admissionType,
  }) async {
    // ==========================================================
    // VALIDASI PAGINATION
    // ==========================================================

    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1 ? 25 : limit;

    // ==========================================================
    // PARSE MULTI SELECT
    // ==========================================================

    final statuses = _parseMultiValue(status);
    final coverages = _parseMultiValue(coverage);
    final claimTypes = _parseMultiValue(claimType);
    final admissionTypes = _parseMultiValue(
      admissionType,
    );

    // ==========================================================
    // QUERY PARAMETERS
    //
    // Map<String, dynamic> digunakan supaya value bisa berupa
    // String maupun List<String>.
    //
    // List<String> akan menghasilkan repeated query parameter.
    //
    // Contoh:
    //
    // status=40&status=58
    // ==========================================================

    final query = <String, dynamic>{
      'page': safePage.toString(),
      'limit': safeLimit.toString(),
    };

    // ==========================================================
    // SEARCH
    // ==========================================================

    final cleanedSearch = search.trim();

    if (cleanedSearch.isNotEmpty) {
      query['search'] = cleanedSearch;
    }

    // ==========================================================
    // STATUS MULTI SELECT
    // ==========================================================

    if (statuses.isNotEmpty) {
      query['status'] = statuses;
    }

    // ==========================================================
    // COVERAGE MULTI SELECT
    // ==========================================================

    if (coverages.isNotEmpty) {
      query['coverage'] = coverages;
    }

    // ==========================================================
    // CLAIM TYPE MULTI SELECT
    // ==========================================================

    if (claimTypes.isNotEmpty) {
      query['claim_type'] = claimTypes;
    }

    // ==========================================================
    // ADMISSION TYPE MULTI SELECT
    // ==========================================================

    if (admissionTypes.isNotEmpty) {
      query['admission_type'] = admissionTypes;
    }

    // ==========================================================
    // BUILD URL
    // ==========================================================

    final uri = Uri.parse(
      '$baseUrl/claims',
    ).replace(
      queryParameters: query,
    );

    try {
      // ========================================================
      // REQUEST
      // ========================================================

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
        },
      );

      // ========================================================
      // HTTP ERROR
      // ========================================================

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil data klaim '
          '(HTTP ${response.statusCode})\n'
          '${response.body}',
        );
      }

      // ========================================================
      // DECODE RESPONSE
      // ========================================================

      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Format response Claim Explorer tidak valid.',
        );
      }

      // ========================================================
      // RETURN MODEL
      // ========================================================

      return ClaimPage.fromJson(decoded);
    } catch (error) {
      throw Exception(
        'Gagal terhubung ke Claim Explorer API: $error',
      );
    }
  }

  // ============================================================
  // GET CLAIM FILTERS
  // ============================================================

  static Future<ClaimFilters> getFilters() async {
    final uri = Uri.parse(
      '$baseUrl/claims/filters',
    );

    try {
      // ========================================================
      // REQUEST
      // ========================================================

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
        },
      );

      // ========================================================
      // HTTP ERROR
      // ========================================================

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil filter klaim '
          '(HTTP ${response.statusCode})\n'
          '${response.body}',
        );
      }

      // ========================================================
      // DECODE RESPONSE
      // ========================================================

      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Format response filter Claim Explorer '
          'tidak valid.',
        );
      }

      // ========================================================
      // RETURN MODEL
      // ========================================================

      return ClaimFilters.fromJson(decoded);
    } catch (error) {
      throw Exception(
        'Gagal terhubung ke Claim Explorer API: $error',
      );
    }
  }
}