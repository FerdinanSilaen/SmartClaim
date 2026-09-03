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
    List<String> stringList(
      dynamic value,
    ) {
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
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList();
    }

    return PredictionFilters(
      coverages:
          stringList(
        json['coverages'],
      ),
      planCodes:
          stringList(
        json['plan_codes'],
      ),
      admissionTypes:
          stringList(
        json['admission_types'],
      ),
      claimTypes:
          stringList(
        json['claim_types'],
      ),
      diagnoses:
          stringList(
        json['diagnoses'],
      ),
      providers:
          entityList(
        json['providers'],
      ),
      corporations:
          entityList(
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
    double number(
      dynamic value,
    ) {
      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(
            value?.toString() ?? '',
          ) ??
          0;
    }

    return PredictionModelStatus(
      ready:
          json['ready'] == true,
      modelName:
          json['model_name']?.toString() ??
              '',
      modelVersion:
          json['model_version']?.toString() ??
              '',
      target:
          json['target']?.toString() ?? '',
      r2:
          number(
        json['r2'],
      ),
      mae:
          number(
        json['mae'],
      ),
      rmse:
          number(
        json['rmse'],
      ),
      automaticRetraining:
          json['automatic_retraining'] ==
              true,
      explainableAi:
          json['explainable_ai']
                  ?.toString() ??
              'SHAP',
    );
  }
}


// ============================================================
// SHAP FACTOR
// ============================================================

class PredictionFactor {
  final String feature;
  final String label;

  final dynamic value;

  final double contributionPct;
  final String direction;
  final double shapValue;

  const PredictionFactor({
    required this.feature,
    required this.label,
    required this.value,
    required this.contributionPct,
    required this.direction,
    required this.shapValue,
  });

  factory PredictionFactor.fromJson(
    Map<String, dynamic> json,
  ) {
    double number(
      dynamic value,
    ) {
      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(
            value?.toString() ?? '',
          ) ??
          0;
    }

    return PredictionFactor(
      feature:
          json['feature']?.toString() ?? '',
      label:
          json['label']?.toString() ?? '',
      value:
          json['value'],
      contributionPct:
          number(
        json['contribution_pct'],
      ),
      direction:
          json['direction']?.toString() ??
              'neutral',
      shapValue:
          number(
        json['shap_value'],
      ),
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

  final String explainabilityMethod;

  final List<PredictionFactor> topFactors;

  final String explanationSummary;
  final String aiBrief;

  const PredictionResult({
    required this.modelName,
    required this.modelVersion,
    required this.target,
    required this.incurredAmount,
    required this.predictedApprovedAmount,
    required this.estimatedDifference,
    required this.approvalRatio,
    required this.explainabilityMethod,
    required this.topFactors,
    required this.explanationSummary,
    required this.aiBrief,
  });

  factory PredictionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    double number(
      dynamic value,
    ) {
      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(
            value?.toString() ?? '',
          ) ??
          0;
    }

    final rawFactors =
        json['top_factors'];

    final factors =
        rawFactors is List
            ? rawFactors
                .whereType<Map>()
                .map(
                  (item) =>
                      PredictionFactor.fromJson(
                    Map<String, dynamic>.from(
                      item,
                    ),
                  ),
                )
                .toList()
            : <PredictionFactor>[];

    return PredictionResult(
      modelName:
          json['model_name']?.toString() ??
              '',
      modelVersion:
          json['model_version']?.toString() ??
              '',
      target:
          json['target']?.toString() ?? '',
      incurredAmount:
          number(
        json['incurred_amt'],
      ),
      predictedApprovedAmount:
          number(
        json['predicted_approved_amt'],
      ),
      estimatedDifference:
          number(
        json['estimated_difference'],
      ),
      approvalRatio:
          number(
        json['approval_ratio'],
      ),
      explainabilityMethod:
          json['explainability_method']
                  ?.toString() ??
              'SHAP',
      topFactors:
          factors,
      explanationSummary:
          json['explanation_summary']
                  ?.toString() ??
              '',
      aiBrief:
          json['ai_brief']?.toString() ??
              '',
    );
  }
}