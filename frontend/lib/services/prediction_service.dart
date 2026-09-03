import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prediction_data.dart';


class PredictionService {
  static const String baseUrl =
      'http://127.0.0.1:8000';

  static const Duration requestTimeout =
      Duration(seconds: 60);


  // ============================================================
  // ERROR DETAIL
  // ============================================================

  static String _errorDetail(
    http.Response response,
  ) {
    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map &&
          decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {
      // Gunakan response body jika JSON tidak valid.
    }

    if (response.body.trim().isNotEmpty) {
      return response.body;
    }

    return 'Tidak ada detail error dari server.';
  }


  // ============================================================
  // MODEL STATUS
  // ============================================================

  static Future<PredictionModelStatus>
      getModelStatus() async {
    final uri = Uri.parse(
      '$baseUrl/api/prediction/status',
    );

    try {
      final response = await http
          .get(uri)
          .timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil status model '
          '(HTTP ${response.statusCode})\n'
          '${_errorDetail(response)}',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Format status model tidak valid.',
        );
      }

      return PredictionModelStatus.fromJson(
        decoded,
      );
    } on TimeoutException {
      throw Exception(
        'Waktu permintaan status model habis.',
      );
    } catch (error) {
      throw Exception(
        'Gagal mengambil status model: $error',
      );
    }
  }


  // ============================================================
  // FILTERS
  // ============================================================

  static Future<PredictionFilters>
      getFilters() async {
    final uri = Uri.parse(
      '$baseUrl/api/prediction/filters',
    );

    try {
      final response = await http
          .get(uri)
          .timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil filter Prediction '
          '(HTTP ${response.statusCode})\n'
          '${_errorDetail(response)}',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Format filter Prediction '
          'tidak valid.',
        );
      }

      return PredictionFilters.fromJson(
        decoded,
      );
    } on TimeoutException {
      throw Exception(
        'Waktu permintaan filter Prediction '
        'habis.',
      );
    } catch (error) {
      throw Exception(
        'Gagal mengambil filter Prediction: '
        '$error',
      );
    }
  }


  // ============================================================
  // PREDICT
  // ============================================================

  static Future<PredictionResult> predict({
    required double incurredAmount,
    required double lengthOfStay,
    required String coverageId,
    required String planCode,
    required String admissionType,
    required String claimType,
    required String corpCode,
    required String providerCode,
    required String primaryDiagnosis,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/prediction/predict',
    );

    final payload = <String, dynamic>{
      'incurred_amt': incurredAmount,
      'length_of_stay': lengthOfStay,
      'coverage_id': coverageId,
      'plan_code': planCode,
      'admission_type': admissionType,
      'claim_type': claimType,
      'corp_code': corpCode,
      'provider_code': providerCode,
      'primary_diagnosis': primaryDiagnosis,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Prediction gagal '
          '(HTTP ${response.statusCode})\n'
          '${_errorDetail(response)}',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Format hasil Prediction '
          'tidak valid.',
        );
      }

      return PredictionResult.fromJson(
        decoded,
      );
    } on TimeoutException {
      throw Exception(
        'Proses Prediction melebihi '
        'batas waktu.',
      );
    } catch (error) {
      throw Exception(
        'Gagal menjalankan Prediction: '
        '$error',
      );
    }
  }


  // ============================================================
  // GEMINI ANALYSIS
  // ============================================================

  static Future<GeminiClaimAnalysis>
      analyzeWithGemini({
    required PredictionResult prediction,
    required String coverageId,
    required double lengthOfStay,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/gemini/analyze-claim',
    );

    final payload = <String, dynamic>{
      'incurred_amount':
          prediction.incurredAmount,
      'predicted_approved_amount':
          prediction.predictedApprovedAmount,
      'coverage_id':
          coverageId,
      'length_of_stay':
          lengthOfStay,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Analisis Gemini gagal '
          '(HTTP ${response.statusCode})\n'
          '${_errorDetail(response)}',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Format hasil analisis Gemini '
          'tidak valid.',
        );
      }

      return GeminiClaimAnalysis.fromJson(
        decoded,
      );
    } on TimeoutException {
      throw Exception(
        'Analisis Gemini melebihi '
        'batas waktu.',
      );
    } catch (error) {
      throw Exception(
        'Gagal menjalankan analisis Gemini: '
        '$error',
      );
    }
  }
}