import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/coverage_data.dart';
import '../models/dashboard_summary.dart';
import '../models/monthly_trend.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ============================================================
  // DASHBOARD SUMMARY
  // ============================================================

  static Future<DashboardSummary> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/dashboard/summary'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      return DashboardSummary.fromJson(data);
    }

    throw Exception(
      'Gagal mengambil dashboard: ${response.statusCode}',
    );
  }

  // ============================================================
  // MONTHLY TREND
  // ============================================================

  static Future<List<MonthlyTrend>> getMonthlyTrend() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/dashboard/monthly-trend'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data =
          jsonDecode(response.body);

      return data
          .map(
            (item) => MonthlyTrend.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Gagal mengambil monthly trend: ${response.statusCode}',
    );
  }

  // ============================================================
  // TOP COVERAGE
  // ============================================================

  static Future<List<CoverageData>> getTopCoverage() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/dashboard/top-coverage'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data =
          jsonDecode(response.body);

      return data
          .map(
            (item) => CoverageData.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Gagal mengambil coverage: ${response.statusCode}',
    );
  }
}