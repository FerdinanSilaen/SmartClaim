class DashboardSummary {
  final int totalClaims;
  final int totalAcc;
  final int totalReject;
  final double approvalRate;
  final double totalIncurred;
  final double totalApproved;
  final double totalNotapproved;

  DashboardSummary({
    required this.totalClaims,
    required this.totalAcc,
    required this.totalReject,
    required this.approvalRate,
    required this.totalIncurred,
    required this.totalApproved,
    required this.totalNotapproved,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalClaims: (json['total_claims'] as num).toInt(),
      totalAcc: (json['total_acc'] as num).toInt(),
      totalReject: (json['total_reject'] as num).toInt(),
      approvalRate: (json['approval_rate'] as num).toDouble(),
      totalIncurred: (json['total_incurred'] as num).toDouble(),
      totalApproved: (json['total_approved'] as num).toDouble(),
      totalNotapproved:
          (json['total_notapproved'] as num).toDouble(),
    );
  }
}