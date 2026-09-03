import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prediction_data.dart';


class PredictionService {
  static const String baseUrl =
      'http://127.0.0.1:8000';


  // ============================================================
  // MODEL STATUS
  // ============================================================

  static Future<PredictionModelStatus>
      getModelStatus() async {

    final uri = Uri.parse(
      '$baseUrl/api/prediction/status',
    );

    final response =
        await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil status model '
        '(HTTP ${response.statusCode})',
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
  }


  // ============================================================
  // FILTERS
  // ============================================================

  static Future<PredictionFilters>
      getFilters() async {

    final uri = Uri.parse(
      '$baseUrl/api/prediction/filters',
    );

    final response =
        await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil filter Prediction '
        '(HTTP ${response.statusCode})',
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
  }


  // ============================================================
  // PREDICT
  // ============================================================

  static Future<PredictionResult>
      predict({
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

    final payload =
        <String, dynamic>{
      'incurred_amt':
          incurredAmount,
      'length_of_stay':
          lengthOfStay,
      'coverage_id':
          coverageId,
      'plan_code':
          planCode,
      'admission_type':
          admissionType,
      'claim_type':
          claimType,
      'corp_code':
          corpCode,
      'provider_code':
          providerCode,
      'primary_diagnosis':
          primaryDiagnosis,
    };

    try {
      final response =
          await http.post(
        uri,
        headers: {
          'Content-Type':
              'application/json',
        },
        body:
            jsonEncode(
          payload,
        ),
      );

      if (response.statusCode != 200) {
        String detail =
            response.body;

        try {
          final decoded =
              jsonDecode(
            response.body,
          );

          if (
              decoded is Map &&
              decoded['detail'] != null) {
            detail =
                decoded['detail']
                    .toString();
          }
        } catch (_) {}

        throw Exception(
          'Prediction gagal '
          '(HTTP ${response.statusCode})\n'
          '$detail',
        );
      }

      final decoded =
          jsonDecode(
        response.body,
      );

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
    } catch (error) {
      throw Exception(
        'Gagal menjalankan Prediction: '
        '$error',
      );
    }
  }
}