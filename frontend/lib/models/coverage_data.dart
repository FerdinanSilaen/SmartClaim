class CoverageData {
  final String coverageId;
  final int totalClaims;
  final int totalAcc;
  final int totalReject;
  final double totalApproved;

  CoverageData({
    required this.coverageId,
    required this.totalClaims,
    required this.totalAcc,
    required this.totalReject,
    required this.totalApproved,
  });

  factory CoverageData.fromJson(Map<String, dynamic> json) {
    return CoverageData(
      coverageId: json['coverage_id'] ?? 'Unknown',
      totalClaims: (json['total_claims'] as num).toInt(),
      totalAcc: (json['total_acc'] as num).toInt(),
      totalReject: (json['total_reject'] as num).toInt(),
      totalApproved: (json['total_approved'] as num).toDouble(),
    );
  }
}