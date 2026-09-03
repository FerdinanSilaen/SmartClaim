// ============================================================
// ANALYTICS DATA MODELS
// ============================================================

// ============================================================
// FILTER ITEM
// Digunakan untuk Provider dan Corporation
// ============================================================

class AnalyticsFilterItem {
  final String code;
  final String label;

  const AnalyticsFilterItem({
    required this.code,
    required this.label,
  });

  factory AnalyticsFilterItem.fromJson(
    Map<String, dynamic> json,
  ) {
    final code = (
      json['code'] ??
      json['provider_code'] ??
      json['corp_code'] ??
      ''
    )
        .toString()
        .trim();

    final name = (
      json['name'] ??
      json['provider_name'] ??
      json['corp_name'] ??
      ''
    )
        .toString()
        .trim();

    final backendLabel = (
      json['label'] ?? ''
    )
        .toString()
        .trim();

    final label =
        backendLabel.isNotEmpty
            ? backendLabel
            : name.isNotEmpty
                ? '$code - $name'
                : code;

    return AnalyticsFilterItem(
      code: code,
      label: label,
    );
  }
}


// ============================================================
// ANALYTICS FILTERS
// ============================================================

class AnalyticsFilters {
  final List<int> years;
  final List<String> coverages;
  final List<String> claimTypes;
  final List<String> results;

  final List<AnalyticsFilterItem> providers;
  final List<AnalyticsFilterItem> corporations;

  const AnalyticsFilters({
    required this.years,
    required this.coverages,
    required this.claimTypes,
    required this.results,
    required this.providers,
    required this.corporations,
  });

  factory AnalyticsFilters.fromJson(
    Map<String, dynamic> json,
  ) {
    return AnalyticsFilters(
      years: _parseIntList(
        json['years'],
      ),

      coverages: _parseStringList(
        json['coverages'],
      ),

      claimTypes: _parseStringList(
        json['claim_types'] ??
        json['claimTypes'],
      ),

      results: _parseStringList(
        json['results'],
      ),

      providers: _parseFilterItems(
        json['providers'],
      ),

      corporations: _parseFilterItems(
        json['corporations'],
      ),
    );
  }
}


// ============================================================
// ANALYTICS OVERVIEW
// ============================================================

class AnalyticsOverview {
  final int totalClaims;

  final int totalAcc;
  final int totalReject;

  final double approvalRate;

  final double totalIncurred;
  final double totalApproved;
  final double totalNotApproved;

  final double avgIncurred;
  final double avgApproved;

  final double avgLengthOfStay;

  final double approvedAmountRatio;

  const AnalyticsOverview({
    required this.totalClaims,
    required this.totalAcc,
    required this.totalReject,
    required this.approvalRate,
    required this.totalIncurred,
    required this.totalApproved,
    required this.totalNotApproved,
    required this.avgIncurred,
    required this.avgApproved,
    required this.avgLengthOfStay,
    required this.approvedAmountRatio,
  });

  factory AnalyticsOverview.fromJson(
    Map<String, dynamic> json,
  ) {
    return AnalyticsOverview(

      // ========================================================
      // TOTAL CLAIMS
      // ========================================================

      totalClaims: _toInt(
        json['total_claims'] ??
        json['totalClaims'],
      ),

      // ========================================================
      // ACC
      // ========================================================

      totalAcc: _toInt(
        json['total_acc'] ??
        json['totalAcc'],
      ),

      // ========================================================
      // REJECT
      // ========================================================

      totalReject: _toInt(
        json['total_reject'] ??
        json['totalReject'],
      ),

      // ========================================================
      // APPROVAL RATE
      // ========================================================

      approvalRate: _toDouble(
        json['approval_rate'] ??
        json['approvalRate'],
      ),

      // ========================================================
      // TOTAL INCURRED
      // ========================================================

      totalIncurred: _toDouble(
        json['total_incurred'] ??
        json['totalIncurred'],
      ),

      // ========================================================
      // TOTAL APPROVED
      // ========================================================

      totalApproved: _toDouble(
        json['total_approved'] ??
        json['totalApproved'],
      ),

      // ========================================================
      // TOTAL NOT APPROVED
      //
      // Backend SmartClaim menggunakan:
      //
      // "total_notapproved"
      //
      // Key lama tetap dipertahankan sebagai fallback.
      // ========================================================

      totalNotApproved: _toDouble(
        json['total_notapproved'] ??
        json['total_not_approved'] ??
        json['totalNotApproved'],
      ),

      // ========================================================
      // AVG INCURRED
      // ========================================================

      avgIncurred: _toDouble(
        json['avg_incurred'] ??
        json['avgIncurred'],
      ),

      // ========================================================
      // AVG APPROVED
      // ========================================================

      avgApproved: _toDouble(
        json['avg_approved'] ??
        json['avgApproved'],
      ),

      // ========================================================
      // AVG LENGTH OF STAY
      // ========================================================

      avgLengthOfStay: _toDouble(
        json['avg_length_of_stay'] ??
        json['avgLengthOfStay'],
      ),

      // ========================================================
      // APPROVED AMOUNT RATIO
      // ========================================================

      approvedAmountRatio: _toDouble(
        json['approved_amount_ratio'] ??
        json['approvedAmountRatio'],
      ),
    );
  }
}


// ============================================================
// HELPER: TO INT
// ============================================================

int _toInt(
  dynamic value,
) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  if (value is num) {
    return value.toInt();
  }

  final text =
      value.toString().trim();

  if (text.isEmpty) {
    return 0;
  }

  final intValue =
      int.tryParse(text);

  if (intValue != null) {
    return intValue;
  }

  final doubleValue =
      double.tryParse(text);

  if (doubleValue != null) {
    return doubleValue.toInt();
  }

  return 0;
}


// ============================================================
// HELPER: TO DOUBLE
// ============================================================

double _toDouble(
  dynamic value,
) {
  if (value == null) {
    return 0.0;
  }

  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is num) {
    return value.toDouble();
  }

  final text =
      value.toString().trim();

  if (text.isEmpty) {
    return 0.0;
  }

  return double.tryParse(
        text,
      ) ??
      0.0;
}


// ============================================================
// HELPER: STRING LIST
// ============================================================

List<String> _parseStringList(
  dynamic value,
) {
  if (value is! List) {
    return [];
  }

  final result =
      <String>[];

  for (final item in value) {
    if (item == null) {
      continue;
    }

    final text =
        item.toString().trim();

    if (
        text.isNotEmpty &&
        !result.contains(text)) {
      result.add(text);
    }
  }

  return result;
}


// ============================================================
// HELPER: INT LIST
// ============================================================

List<int> _parseIntList(
  dynamic value,
) {
  if (value is! List) {
    return [];
  }

  final result =
      <int>[];

  for (final item in value) {
    if (item == null) {
      continue;
    }

    int? parsed;

    if (item is int) {
      parsed = item;
    } else if (item is num) {
      parsed = item.toInt();
    } else {
      parsed = int.tryParse(
        item.toString().trim(),
      );
    }

    if (
        parsed != null &&
        !result.contains(parsed)) {
      result.add(parsed);
    }
  }

  return result;
}


// ============================================================
// HELPER: FILTER ITEMS
// ============================================================

List<AnalyticsFilterItem>
    _parseFilterItems(
  dynamic value,
) {
  if (value is! List) {
    return [];
  }

  final result =
      <AnalyticsFilterItem>[];

  final usedCodes =
      <String>{};

  for (final item in value) {
    if (item == null) {
      continue;
    }

    // ========================================================
    // BACKEND MENGIRIM OBJECT
    //
    // Contoh:
    //
    // {
    //   "code": "P001",
    //   "name": "RS ABC"
    // }
    // ========================================================

    if (item is Map) {
      final map =
          Map<String, dynamic>.from(
        item,
      );

      final filterItem =
          AnalyticsFilterItem.fromJson(
        map,
      );

      if (
          filterItem.code.isNotEmpty &&
          !usedCodes.contains(
            filterItem.code,
          )) {
        result.add(
          filterItem,
        );

        usedCodes.add(
          filterItem.code,
        );
      }

      continue;
    }

    // ========================================================
    // BACKEND MENGIRIM STRING
    // ========================================================

    final text =
        item.toString().trim();

    if (
        text.isNotEmpty &&
        !usedCodes.contains(text)) {
      result.add(
        AnalyticsFilterItem(
          code: text,
          label: text,
        ),
      );

      usedCodes.add(
        text,
      );
    }
  }

  return result;
}