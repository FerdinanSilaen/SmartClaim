// ============================================================
// NUMBER HELPER
// ============================================================

double _number(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value?.toString() ?? '',
      ) ??
      0;
}


// ============================================================
// ENTITY OPTION
// ============================================================

class PredictionEntityOption {
  final String code;
  final String name;

  const PredictionEntityOption({
    required this.code,
    required this.name,
  });

  factory PredictionEntityOption.fromJson(
    Map<String, dynamic> json,
  ) {
    return PredictionEntityOption(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  String get displayLabel {
    if (name.trim().isEmpty) {
      return code;
    }

    return '$code - $name';
  }
}


// ============================================================
// FILTERS
// ============================================================

class PredictionFilters {
  final List<String> coverages;
  final List<String> planCodes;
  final List<String> admissionTypes;
  final List<String> claimTypes;
  final List<String> diagnoses;

  final List<PredictionEntityOption> providers;
  final List<PredictionEntityOption> corporations;

  const PredictionFilters({
    required this.coverages,
    required this.planCodes,
    required this.admissionTypes,
    required this.claimTypes,
    required this.diagnoses,
    required this.providers,
    required this.corporations,
  });

  factory PredictionFilters.fromJson(
    Map<String, dynamic> json,
  ) {
    List<String> stringList(dynamic value) {
      if (value is! List) {
        return [];
      }

      return value
          .map(
            (item) => item.toString(),
          )
          .where(
            (item) => item.trim().isNotEmpty,
          )
          .toList();
    }

    List<PredictionEntityOption> entityList(
      dynamic value,
    ) {
      if (value is! List) {
        return [];
      }

      return value
          .whereType<Map>()
          .map(
            (item) =>
                PredictionEntityOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    return PredictionFilters(
      coverages: stringList(
        json['coverages'],
      ),
      planCodes: stringList(
        json['plan_codes'],
      ),
      admissionTypes: stringList(
        json['admission_types'],
      ),
      claimTypes: stringList(
        json['claim_types'],
      ),
      diagnoses: stringList(
        json['diagnoses'],
      ),
      providers: entityList(
        json['providers'],
      ),
      corporations: entityList(
        json['corporations'],
      ),
    );
  }
}


// ============================================================
// MODEL STATUS
// ============================================================

class PredictionModelStatus {
  final bool ready;
  final String modelName;
  final String modelVersion;
  final String target;

  final double r2;
  final double mae;
  final double rmse;

  final bool automaticRetraining;
  final String explainableAi;

  const PredictionModelStatus({
    required this.ready,
    required this.modelName,
    required this.modelVersion,
    required this.target,
    required this.r2,
    required this.mae,
    required this.rmse,
    required this.automaticRetraining,
    required this.explainableAi,
  });

  factory PredictionModelStatus.fromJson(
    Map<String, dynamic> json,
  ) {
    return PredictionModelStatus(
      ready: json['ready'] == true,
      modelName:
          json['model_name']?.toString() ?? '',
      modelVersion:
          json['model_version']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      r2: _number(json['r2']),
      mae: _number(json['mae']),
      rmse: _number(json['rmse']),
      automaticRetraining:
          json['automatic_retraining'] == true,
      explainableAi:
          json['explainable_ai']?.toString() ?? '',
    );
  }
}


// ============================================================
// PREDICTION RESULT
// ============================================================

class PredictionResult {
  final String modelName;
  final String modelVersion;
  final String target;

  final double incurredAmount;
  final double predictedApprovedAmount;
  final double estimatedDifference;
  final double approvalRatio;

  const PredictionResult({
    required this.modelName,
    required this.modelVersion,
    required this.target,
    required this.incurredAmount,
    required this.predictedApprovedAmount,
    required this.estimatedDifference,
    required this.approvalRatio,
  });

  factory PredictionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return PredictionResult(
      modelName:
          json['model_name']?.toString() ?? '',
      modelVersion:
          json['model_version']?.toString() ?? '',
      target:
          json['target']?.toString() ?? '',
      incurredAmount:
          _number(json['incurred_amt']),
      predictedApprovedAmount:
          _number(
        json['predicted_approved_amt'],
      ),
      estimatedDifference:
          _number(
        json['estimated_difference'],
      ),
      approvalRatio:
          _number(json['approval_ratio']),
    );
  }
}


// ============================================================
// GEMINI ANALYSIS RESULT
// ============================================================

class GeminiClaimAnalysis {
  final String status;
  final String model;
  final String analysis;

  final double incurredAmount;
  final double predictedApprovedAmount;
  final double estimatedDifference;
  final double approvalRatio;

  const GeminiClaimAnalysis({
    required this.status,
    required this.model,
    required this.analysis,
    required this.incurredAmount,
    required this.predictedApprovedAmount,
    required this.estimatedDifference,
    required this.approvalRatio,
  });

  factory GeminiClaimAnalysis.fromJson(
    Map<String, dynamic> json,
  ) {
    return GeminiClaimAnalysis(
      status:
          json['status']?.toString() ?? '',
      model:
          json['model']?.toString() ?? '',
      analysis:
          json['analysis']?.toString() ?? '',
      incurredAmount:
          _number(json['incurred_amount']),
      predictedApprovedAmount:
          _number(
        json['predicted_approved_amount'],
      ),
      estimatedDifference:
          _number(
        json['estimated_difference'],
      ),
      approvalRatio:
          _number(json['approval_ratio']),
    );
  }
}