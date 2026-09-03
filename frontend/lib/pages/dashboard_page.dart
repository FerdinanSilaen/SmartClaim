import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/coverage_data.dart';
import '../models/dashboard_summary.dart';
import '../models/monthly_trend.dart';
import '../services/api_service.dart';

import 'analytics_content.dart';
import 'claim_explorer_content.dart';
import 'prediction_content.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardSummary> dashboardFuture;
  late Future<List<MonthlyTrend>> monthlyTrendFuture;
  late Future<List<CoverageData>> coverageFuture;

  // Index coverage yang sedang dipilih pada donut chart.
  // -1 berarti tidak ada coverage yang dipilih.
  int selectedCoverageIndex = -1;

  // Navigasi single-page sidebar.
  // 0 = Dashboard, 1 = Claim Explorer, 2 = Analytics,
  // 3 = Prediction, 4 = Anomaly Monitor, 5 = Settings.
  int selectedMenuIndex = 0;

  @override
  void initState() {
    super.initState();

    dashboardFuture = ApiService.getDashboardSummary();
    monthlyTrendFuture = ApiService.getMonthlyTrend();
    coverageFuture = ApiService.getTopCoverage();
  }

  void refreshDashboard() {
    setState(() {
      dashboardFuture = ApiService.getDashboardSummary();
      monthlyTrendFuture = ApiService.getMonthlyTrend();
      coverageFuture = ApiService.getTopCoverage();
      selectedCoverageIndex = -1;
    });
  }

  String formatNumber(num value) {
    return NumberFormat('#,##0', 'id_ID').format(value);
  }

  String formatRupiah(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String formatPercentage(double value) {
    return '${NumberFormat('0.00', 'id_ID').format(value)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildCurrentContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
// CURRENT CONTENT
// ============================================================

Widget _buildCurrentContent() {
  switch (selectedMenuIndex) {
    case 0:
      return _buildDashboardContent();

    case 1:
      return const ClaimExplorerContent();

    case 2:
      return const AnalyticsContent();

    case 3:
      return const PredictionContent();

    case 4:
    case 5:
      return _buildComingSoonContent();

    default:
      return _buildDashboardContent();
  }
}

  // ============================================================
  // DASHBOARD CONTENT
  // ============================================================

  Widget _buildDashboardContent() {
    return FutureBuilder<DashboardSummary>(
  future: dashboardFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Mengambil data SmartClaim...',
              style: TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFECACA),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Gagal mengambil data SmartClaim',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: refreshDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final data = snapshot.data!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Overview dan monitoring data klaim kesehatan',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 26),

          // ==================================================
          // WELCOME BANNER
          // ==================================================

          _buildWelcomeBanner(data),

          const SizedBox(height: 28),

          // ==================================================
          // CLAIM SUMMARY
          // ==================================================

          const _SectionHeader(
            title: 'Claim Summary',
            subtitle:
                'Ringkasan status seluruh klaim kesehatan',
          ),

          const SizedBox(height: 16),

          _buildClaimSummary(data),

          const SizedBox(height: 30),

          // ==================================================
          // FINANCIAL SUMMARY
          // ==================================================

          const _SectionHeader(
            title: 'Financial Summary',
            subtitle: 'Ringkasan nilai finansial klaim',
          ),

          const SizedBox(height: 16),

          _buildFinancialSummary(data),

          const SizedBox(height: 30),

          // ==================================================
          // SMART INSIGHT
          // ==================================================

          const _SectionHeader(
            title: 'Smart Insight',
            subtitle:
                'Snapshot performa data klaim saat ini',
          ),

          const SizedBox(height: 16),

          _buildSmartInsight(data),

          const SizedBox(height: 30),

          // ==================================================
          // CHART ANALYTICS
          // ==================================================

          const _SectionHeader(
            title: 'Claim Analytics',
            subtitle:
                'Trend bulanan dan distribusi coverage',
          ),

          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 1000;

              if (compact) {
                return Column(
                  children: [
                    _monthlyTrendCard(),
                    const SizedBox(height: 18),
                    _coverageChartCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _monthlyTrendCard(),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _coverageChartCard(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  },
);
  }

  // ============================================================
  // COMING SOON CONTENT
  // ============================================================

  Widget _buildComingSoonContent() {
    final titles = <int, String>{
      3: 'Prediction',
      4: 'Anomaly Monitor',
      5: 'Settings',
    };

    final subtitles = <int, String>{
      3: 'Prediksi nilai klaim menggunakan model machine learning',
      4: 'Deteksi pola klaim yang tidak normal atau mencurigakan',
      5: 'Pengaturan aplikasi SmartClaim',
    };

    final icons = <int, IconData>{
      3: Icons.auto_graph_rounded,
      4: Icons.warning_amber_rounded,
      5: Icons.settings_outlined,
    };

    final title =
        titles[selectedMenuIndex] ?? 'SmartClaim';

    final subtitle =
        subtitles[selectedMenuIndex] ??
        'Fitur sedang disiapkan';

    final icon =
        icons[selectedMenuIndex] ??
        Icons.construction_rounded;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(34),
        constraints: const BoxConstraints(
          maxWidth: 560,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Coming Soon',
                style: TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // WELCOME BANNER
  // ============================================================

  Widget _buildWelcomeBanner(DashboardSummary data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF2563EB),
            Color(0xFF4F46E5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(
              alpha: 0.20,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SmartClaim Health Intelligence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatNumber(data.totalClaims)} klaim telah terhubung dengan sistem analitik.',
                  style: const TextStyle(
                    color: Color(0xFFE0E7FF),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _bannerBadge(
                      Icons.storage_rounded,
                      'PostgreSQL Connected',
                    ),
                    _bannerBadge(
                      Icons.api_rounded,
                      'FastAPI Online',
                    ),
                    _bannerBadge(
                      Icons.analytics_rounded,
                      'Analytics Ready',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CLAIM SUMMARY
  // ============================================================

  Widget _buildClaimSummary(DashboardSummary data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;

        if (constraints.maxWidth < 700) {
          columns = 1;
        } else if (constraints.maxWidth < 1100) {
          columns = 2;
        }

        final width =
            (constraints.maxWidth - ((columns - 1) * 16)) /
            columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _summaryCard(
              width: width,
              title: 'Total Claims',
              value: formatNumber(data.totalClaims),
              icon: Icons.description_outlined,
              accent: const Color(0xFF2563EB),
              softColor: const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              width: width,
              title: 'ACC',
              value: formatNumber(data.totalAcc),
              icon: Icons.check_circle_outline,
              accent: const Color(0xFF16A34A),
              softColor: const Color(0xFFECFDF3),
            ),
            _summaryCard(
              width: width,
              title: 'Reject',
              value: formatNumber(data.totalReject),
              icon: Icons.cancel_outlined,
              accent: const Color(0xFFDC2626),
              softColor: const Color(0xFFFEF2F2),
            ),
            _summaryCard(
              width: width,
              title: 'Approval Rate',
              value:
                  '${data.approvalRate.toStringAsFixed(2)}%',
              icon: Icons.trending_up_rounded,
              accent: const Color(0xFFF59E0B),
              softColor: const Color(0xFFFFFBEB),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FINANCIAL SUMMARY
  // ============================================================

  Widget _buildFinancialSummary(DashboardSummary data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 900 ? 1 : 3;

        final width =
            (constraints.maxWidth - ((columns - 1) * 16)) /
            columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _financialCard(
              width: width,
              title: 'Total Incurred',
              value: formatRupiah(data.totalIncurred),
              subtitle: 'Total nilai pengajuan klaim',
              icon: Icons.receipt_long_rounded,
              accent: const Color(0xFF7C3AED),
              softColor: const Color(0xFFF5F3FF),
            ),
            _financialCard(
              width: width,
              title: 'Total Approved',
              value: formatRupiah(data.totalApproved),
              subtitle: 'Nilai klaim yang disetujui',
              icon: Icons.payments_outlined,
              accent: const Color(0xFF0891B2),
              softColor: const Color(0xFFECFEFF),
            ),
            _financialCard(
              width: width,
              title: 'Not Approved',
              value: formatRupiah(data.totalNotapproved),
              subtitle: 'Nilai yang tidak disetujui',
              icon: Icons.money_off_rounded,
              accent: const Color(0xFFEA580C),
              softColor: const Color(0xFFFFF7ED),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SMART INSIGHT
  // ============================================================

  Widget _buildSmartInsight(DashboardSummary data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _insightChip(
            icon: Icons.check_circle_rounded,
            title: 'Approved Claims',
            value:
                '${formatNumber(data.totalAcc)} klaim',
            accent: const Color(0xFF16A34A),
            softColor: const Color(0xFFECFDF3),
          ),
          _insightChip(
            icon: Icons.cancel_rounded,
            title: 'Rejected Claims',
            value:
                '${formatNumber(data.totalReject)} klaim',
            accent: const Color(0xFFDC2626),
            softColor: const Color(0xFFFEF2F2),
          ),
          _insightChip(
            icon: Icons.percent_rounded,
            title: 'Approval Rate',
            value:
                '${data.approvalRate.toStringAsFixed(2)}%',
            accent: const Color(0xFFF59E0B),
            softColor: const Color(0xFFFFFBEB),
          ),
          _insightChip(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Approved Value',
            value: formatRupiah(data.totalApproved),
            accent: const Color(0xFF0891B2),
            softColor: const Color(0xFFECFEFF),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTHLY TREND CHART
  // ============================================================

  Widget _monthlyTrendCard() {
    return Container(
      height: 410,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 10),
              Text(
                'Monthly Claim Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Jumlah klaim berdasarkan bulan admission',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<MonthlyTrend>>(
              future: monthlyTrendFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat trend\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return const Center(
                    child: Text(
                      'Data trend tidak tersedia',
                    ),
                  );
                }

                final spots = List.generate(
                  data.length,
                  (index) => FlSpot(
                    index.toDouble(),
                    data[index].totalClaims.toDouble(),
                  ),
                );

                final maxClaims = data
                    .map((e) => e.totalClaims)
                    .reduce(
                      (a, b) => a > b ? a : b,
                    );

                return LineChart(
                  LineChartData(
                    minX: 0,
                    maxX:
                        (data.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxClaims * 1.15,
                    borderData: FlBorderData(
                      show: false,
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval:
                          maxClaims > 1000
                          ? 250.0
                          : 100.0,
                      getDrawingHorizontalLine:
                          (value) {
                            return const FlLine(
                              color:
                                  Color(0xFFE2E8F0),
                              strokeWidth: 1,
                            );
                          },
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                      rightTitles:
                          const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 46,
                          getTitlesWidget:
                              (value, meta) {
                                return Text(
                                  formatNumber(
                                    value.toInt(),
                                  ),
                                  style:
                                      const TextStyle(
                                        fontSize: 10,
                                        color: Color(
                                          0xFF64748B,
                                        ),
                                      ),
                                );
                              },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 40,
                          getTitlesWidget:
                              (value, meta) {
                                final index =
                                    value.toInt();

                                if (index < 0 ||
                                    index >=
                                        data.length) {
                                  return const SizedBox
                                      .shrink();
                                }

                                if (data.length > 10 &&
                                    index % 2 != 0) {
                                  return const SizedBox
                                      .shrink();
                                }

                                final month =
                                    data[index].month;

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(
                                        top: 8,
                                      ),
                                  child: Text(
                                    month.length >= 7
                                        ? month.substring(
                                            2,
                                          )
                                        : month,
                                    style:
                                        const TextStyle(
                                          color: Color(
                                            0xFF64748B,
                                          ),
                                          fontSize: 10,
                                        ),
                                  ),
                                );
                              },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData:
                          LineTouchTooltipData(
                            getTooltipItems:
                                (spots) {
                                  return spots.map(
                                    (spot) {
                                      final index =
                                          spot.x
                                              .toInt();

                                      final item =
                                          data[index];

                                      return LineTooltipItem(
                                        '${item.month}\n'
                                        '${formatNumber(item.totalClaims)} klaim\n'
                                        'ACC ${formatNumber(item.totalAcc)} | '
                                        'Reject ${formatNumber(item.totalReject)}',
                                        const TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                        ),
                                      );
                                    },
                                  ).toList();
                                },
                          ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color:
                            const Color(0xFF2563EB),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter:
                              (
                                spot,
                                percent,
                                bar,
                                index,
                              ) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: const Color(
                                    0xFF2563EB,
                                  ),
                                  strokeWidth: 2,
                                  strokeColor:
                                      Colors.white,
                                );
                              },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin:
                                Alignment.topCenter,
                            end:
                                Alignment.bottomCenter,
                            colors: [
                              const Color(
                                0xFF2563EB,
                              ).withValues(
                                alpha: 0.18,
                              ),
                              const Color(
                                0xFF2563EB,
                              ).withValues(
                                alpha: 0.01,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COVERAGE DONUT CHART
  // ============================================================

  Widget _coverageChartCard() {
    return Container(
      height: 410,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.donut_large_rounded,
                color: Color(0xFF7C3AED),
              ),
              SizedBox(width: 10),
              Text(
                'Coverage Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Klik segmen atau legend untuk melihat jumlah dan persentase',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: FutureBuilder<List<CoverageData>>(
              future: coverageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat coverage\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return const Center(
                    child: Text(
                      'Data coverage tidak tersedia',
                    ),
                  );
                }

                final colors = [
                  const Color(0xFF2563EB),
                  const Color(0xFF16A34A),
                  const Color(0xFFF59E0B),
                  const Color(0xFF7C3AED),
                  const Color(0xFFDC2626),
                  const Color(0xFF0891B2),
                  const Color(0xFFEA580C),
                ];

                final totalClaims = data.fold<int>(
                  0,
                  (sum, item) => sum + item.totalClaims,
                );

                final hasSelection =
                    selectedCoverageIndex >= 0 &&
                    selectedCoverageIndex < data.length;

                final selectedItem = hasSelection
                    ? data[selectedCoverageIndex]
                    : null;

                final selectedPercentage =
                    selectedItem != null && totalClaims > 0
                    ? (selectedItem.totalClaims / totalClaims) * 100
                    : 0.0;

                final sections = List.generate(
                  data.length,
                  (index) {
                    final item = data[index];
                    final isSelected =
                        index == selectedCoverageIndex;

                    return PieChartSectionData(
                      value: item.totalClaims.toDouble(),
                      color: colors[index % colors.length],
                      radius: isSelected ? 70 : 60,
                      showTitle: false,
                    );
                  },
                );

                void selectCoverage(int index) {
                  setState(() {
                    if (selectedCoverageIndex == index) {
                      // Klik coverage yang sama sekali lagi untuk reset.
                      selectedCoverageIndex = -1;
                    } else {
                      selectedCoverageIndex = index;
                    }
                  });
                }

                return Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: sections,
                              sectionsSpace: 3,
                              centerSpaceRadius: 55,
                              startDegreeOffset: -90,

                              // =================================================
                              // INTERAKSI DONUT
                              // =================================================
                              pieTouchData: PieTouchData(
                                enabled: true,
                                touchCallback:
                                    (
                                      FlTouchEvent event,
                                      PieTouchResponse?
                                      pieTouchResponse,
                                    ) {
                                      // Hanya simpan pilihan ketika benar-benar
                                      // diklik/tap, bukan hanya saat mouse lewat.
                                      if (event is! FlTapUpEvent) {
                                        return;
                                      }

                                      final touchedSection =
                                          pieTouchResponse
                                              ?.touchedSection;

                                      if (touchedSection ==
                                          null) {
                                        setState(() {
                                          selectedCoverageIndex =
                                              -1;
                                        });
                                        return;
                                      }

                                      final touchedIndex =
                                          touchedSection
                                              .touchedSectionIndex;

                                      if (touchedIndex < 0 ||
                                          touchedIndex >=
                                              data.length) {
                                        return;
                                      }

                                      selectCoverage(
                                        touchedIndex,
                                      );
                                    },
                              ),
                            ),
                            duration:
                                const Duration(
                                  milliseconds: 280,
                                ),
                            curve: Curves.easeOutCubic,
                          ),

                          // =====================================================
                          // INFORMASI DI TENGAH DONUT
                          // =====================================================
                          AnimatedSwitcher(
                            duration:
                                const Duration(
                                  milliseconds: 220,
                                ),
                            child: selectedItem == null
                                ? Column(
                                    key: const ValueKey(
                                      'coverage-total',
                                    ),
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Text(
                                        formatNumber(
                                          totalClaims,
                                        ),
                                        style:
                                            const TextStyle(
                                              fontSize: 21,
                                              fontWeight:
                                                  FontWeight
                                                      .w800,
                                              color: Color(
                                                0xFF0F172A,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(
                                        height: 2,
                                      ),
                                      const Text(
                                        'Claims',
                                        style:
                                            TextStyle(
                                              fontSize: 11,
                                              color: Color(
                                                0xFF94A3B8,
                                              ),
                                            ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    key: ValueKey(
                                      'coverage-${selectedItem.coverageId}',
                                    ),
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Text(
                                        selectedItem
                                            .coverageId,
                                        textAlign:
                                            TextAlign.center,
                                        style:
                                            const TextStyle(
                                              fontSize: 17,
                                              fontWeight:
                                                  FontWeight
                                                      .w800,
                                              color: Color(
                                                0xFF0F172A,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(
                                        height: 2,
                                      ),
                                      Text(
                                        '${formatNumber(selectedItem.totalClaims)} klaim',
                                        style:
                                            const TextStyle(
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                              color: Color(
                                                0xFF475569,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(
                                        height: 2,
                                      ),
                                      Text(
                                        formatPercentage(
                                          selectedPercentage,
                                        ),
                                        style:
                                            TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight
                                                      .w800,
                                              color: colors[
                                                  selectedCoverageIndex %
                                                      colors
                                                          .length],
                                            ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ===========================================================
                    // LEGEND INTERAKTIF
                    // ===========================================================
                    Wrap(
                      spacing: 8,
                      runSpacing: 7,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        data.length,
                        (index) {
                          final item = data[index];
                          final color =
                              colors[index %
                                  colors.length];
                          final isSelected =
                              index ==
                              selectedCoverageIndex;

                          final percentage =
                              totalClaims > 0
                              ? (item.totalClaims /
                                        totalClaims) *
                                    100
                              : 0.0;

                          return Tooltip(
                            message:
                                '${item.coverageId}\n'
                                '${formatNumber(item.totalClaims)} klaim\n'
                                '${formatPercentage(percentage)}',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(
                                      999,
                                    ),
                                onTap: () =>
                                    selectCoverage(
                                      index,
                                    ),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(
                                        milliseconds: 180,
                                      ),
                                  padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 5,
                                      ),
                                  decoration:
                                      BoxDecoration(
                                        color: isSelected
                                            ? color.withValues(
                                                alpha: 0.10,
                                              )
                                            : Colors
                                                  .transparent,
                                        borderRadius:
                                            BorderRadius.circular(
                                              999,
                                            ),
                                        border: Border.all(
                                          color: isSelected
                                              ? color.withValues(
                                                  alpha:
                                                      0.35,
                                                )
                                              : Colors
                                                    .transparent,
                                        ),
                                      ),
                                  child: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(
                                              milliseconds:
                                                  180,
                                            ),
                                        width: isSelected
                                            ? 10
                                            : 9,
                                        height: isSelected
                                            ? 10
                                            : 9,
                                        decoration:
                                            BoxDecoration(
                                              color: color,
                                              shape:
                                                  BoxShape
                                                      .circle,
                                            ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        '${item.coverageId} '
                                        '(${formatNumber(item.totalClaims)})',
                                        style: TextStyle(
                                          color: isSelected
                                              ? const Color(
                                                  0xFF0F172A,
                                                )
                                              : const Color(
                                                  0xFF64748B,
                                                ),
                                          fontSize: 10,
                                          fontWeight:
                                              isSelected
                                              ? FontWeight
                                                    .w700
                                              : FontWeight
                                                    .w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF111827),
            Color(0xFF1E293B),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  'SmartClaim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Health Claim Intelligence',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 40),

          _menuItem(
            Icons.dashboard_rounded,
            'Dashboard',
            index: 0,
          ),
          _menuItem(
            Icons.manage_search_rounded,
            'Claim Explorer',
            index: 1,
          ),
          _menuItem(
            Icons.analytics_outlined,
            'Analytics',
            index: 2,
          ),
          _menuItem(
            Icons.auto_graph_rounded,
            'Prediction',
            index: 3,
          ),
          _menuItem(
            Icons.warning_amber_rounded,
            'Anomaly Monitor',
            index: 4,
          ),

          const Spacer(),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.07,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Status',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 5,
                      backgroundColor:
                          Color(0xFF22C55E),
                    ),
                    SizedBox(width: 9),
                    Text(
                      'API Connected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24),

          _menuItem(
            Icons.settings_outlined,
            'Settings',
            index: 5,
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label, {
    required int index,
  }) {
    final active =
        selectedMenuIndex == index;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 7,
      ),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(
                alpha: 0.12,
              )
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 2,
        ),
        onTap: () {
          if (selectedMenuIndex == index) {
            return;
          }

          setState(() {
            selectedMenuIndex = index;
          });
        },
        leading: Icon(
          icon,
          color: active
              ? Colors.white
              : const Color(
                  0xFF94A3B8,
                ),
          size: 21,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: active
                ? Colors.white
                : const Color(
                    0xFFCBD5E1,
                  ),
            fontSize: 14,
            fontWeight: active
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Claim Health Intelligence',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Smart analytics for claim monitoring',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: refreshDashboard,
              tooltip: 'Refresh Dashboard',
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF4338CA),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    required Color softColor,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(
        minHeight: 155,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.72,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius:
                      BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FINANCIAL CARD
  // ============================================================

  Widget _financialCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Color softColor,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(
        minHeight: 150,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 25,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INSIGHT CHIP
  // ============================================================

  Widget _insightChip({
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
    required Color softColor,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 180,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: accent,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BANNER BADGE
  // ============================================================

  Widget _bannerBadge(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
