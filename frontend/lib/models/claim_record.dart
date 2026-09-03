class ClaimRecord {
  final String claimsId;
  final String claimType;
  final String claimsStatus;
  final String corpCode;
  final String corpName;
  final String providerCode;
  final String providerName;
  final String admissionDate;
  final String admissionType;
  final int lengthOfStay;
  final String coverageId;
  final String planCode;
  final String primaryDiagnosis;
  final String primaryDiagnosisDesc;
  final double incurredAmt;
  final double approvedAmt;
  final double notApprovedAmt;

  const ClaimRecord({
    required this.claimsId,
    required this.claimType,
    required this.claimsStatus,
    required this.corpCode,
    required this.corpName,
    required this.providerCode,
    required this.providerName,
    required this.admissionDate,
    required this.admissionType,
    required this.lengthOfStay,
    required this.coverageId,
    required this.planCode,
    required this.primaryDiagnosis,
    required this.primaryDiagnosisDesc,
    required this.incurredAmt,
    required this.approvedAmt,
    required this.notApprovedAmt,
  });

  factory ClaimRecord.fromJson(Map<String, dynamic> json) {
    return ClaimRecord(
      claimsId: _asString(json['claims_id']),
      claimType: _asString(json['claim_type']),
      claimsStatus: _asString(json['claims_status']),
      corpCode: _asString(json['corp_code']),
      corpName: _asString(json['corp_name']),
      providerCode: _asString(json['provider_code']),
      providerName: _asString(json['provider_name']),
      admissionDate: _asString(json['admission_date']),
      admissionType: _asString(json['admission_type']),
      lengthOfStay: _asInt(json['length_of_stay']),
      coverageId: _asString(json['coverage_id']),
      planCode: _asString(json['plan_code']),
      primaryDiagnosis: _asString(json['primary_diagnosis']),
      primaryDiagnosisDesc: _asString(json['primary_diagnosis_desc']),
      incurredAmt: _asDouble(json['incurred_amt']),
      approvedAmt: _asDouble(json['approved_amt']),
      notApprovedAmt: _asDouble(json['notapproved_amt']),
    );
  }

  static String _asString(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class ClaimPage {
  final List<ClaimRecord> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const ClaimPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ClaimPage.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? []);

    return ClaimPage(
      items: rawItems
          .map(
            (item) => ClaimRecord.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      total: _asInt(json['total']),
      page: _asInt(json['page']),
      limit: _asInt(json['limit']),
      totalPages: _asInt(json['total_pages']),
    );
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class ClaimFilters {
  final List<String> statuses;
  final List<String> coverages;
  final List<String> claimTypes;
  final List<String> admissionTypes;

  const ClaimFilters({
    required this.statuses,
    required this.coverages,
    required this.claimTypes,
    required this.admissionTypes,
  });

  factory ClaimFilters.fromJson(Map<String, dynamic> json) {
    return ClaimFilters(
      statuses: _asStringList(json['statuses']),
      coverages: _asStringList(json['coverages']),
      claimTypes: _asStringList(json['claim_types']),
      admissionTypes: _asStringList(json['admission_types']),
    );
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .where((item) => item != null)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
