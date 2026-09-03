class MonthlyTrend {
  final String month;
  final int totalClaims;
  final int totalAcc;
  final int totalReject;
  final double totalIncurred;
  final double totalApproved;

  MonthlyTrend({
    required this.month,
    required this.totalClaims,
    required this.totalAcc,
    required this.totalReject,
    required this.totalIncurred,
    required this.totalApproved,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] ?? '',
      totalClaims: (json['total_claims'] as num).toInt(),
      totalAcc: (json['total_acc'] as num).toInt(),
      totalReject: (json['total_reject'] as num).toInt(),
      totalIncurred: (json['total_incurred'] as num).toDouble(),
      totalApproved: (json['total_approved'] as num).toDouble(),
    );
  }
}