import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/analytics_data.dart';
import '../services/analytics_service.dart';

class AnalyticsContent extends StatefulWidget {
  const AnalyticsContent({
    super.key,
  });

  @override
  State<AnalyticsContent> createState() =>
      _AnalyticsContentState();
}

class _AnalyticsContentState
    extends State<AnalyticsContent> {
  AnalyticsFilters? filters;
  AnalyticsOverview? overview;

  bool initialLoading = true;
  bool overviewLoading = false;

  String? errorMessage;

  // ============================================================
  // MULTI SELECT FILTER STATE
  // ============================================================

  final Set<String> selectedYears =
      <String>{};

  final Set<String> selectedCoverages =
      <String>{};

  final Set<String> selectedClaimTypes =
      <String>{};

  final Set<String> selectedResults =
      <String>{};

  final Set<String> selectedProviders =
      <String>{};

  final Set<String> selectedCorporations =
      <String>{};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadInitialData();
  }

  // ============================================================
  // INITIAL LOAD
  // ============================================================

  Future<void> _loadInitialData() async {
    setState(() {
      initialLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await Future.wait<dynamic>(
        [
          AnalyticsService.getFilters(),
          AnalyticsService.getOverview(),
        ],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        filters =
            result[0] as AnalyticsFilters;

        overview =
            result[1] as AnalyticsOverview;

        initialLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        initialLoading = false;
        errorMessage =
            error.toString();
      });
    }
  }

  // ============================================================
  // ENCODE MULTI SELECT
  // ============================================================

  String? _encodeSelected(
    Set<String> values,
  ) {
    if (values.isEmpty) {
      return null;
    }

    final sorted =
        values.toList()
          ..sort();

    return sorted.join(',');
  }

  // ============================================================
  // LOAD OVERVIEW
  // ============================================================

  Future<void> _loadOverview() async {
    if (!mounted) {
      return;
    }

    setState(() {
      overviewLoading = true;
      errorMessage = null;
    });

    try {
      final data =
          await AnalyticsService.getOverview(
        year: _encodeSelected(
          selectedYears,
        ),
        coverage: _encodeSelected(
          selectedCoverages,
        ),
        claimType: _encodeSelected(
          selectedClaimTypes,
        ),
        result: _encodeSelected(
          selectedResults,
        ),
        providerCode: _encodeSelected(
          selectedProviders,
        ),
        corpCode: _encodeSelected(
          selectedCorporations,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        overview = data;
        overviewLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        overviewLoading = false;
        errorMessage =
            error.toString();
      });
    }
  }

  // ============================================================
  // RESET FILTER
  // ============================================================

  Future<void> _resetFilters() async {
    setState(() {
      selectedYears.clear();
      selectedCoverages.clear();
      selectedClaimTypes.clear();
      selectedResults.clear();
      selectedProviders.clear();
      selectedCorporations.clear();
    });

    await _loadOverview();
  }

  // ============================================================
  // ACTIVE FILTER COUNT
  // ============================================================

  int get _activeFilters {
    int count = 0;

    if (selectedYears.isNotEmpty) {
      count++;
    }

    if (selectedCoverages.isNotEmpty) {
      count++;
    }

    if (selectedClaimTypes.isNotEmpty) {
      count++;
    }

    if (selectedResults.isNotEmpty) {
      count++;
    }

    if (selectedProviders.isNotEmpty) {
      count++;
    }

    if (selectedCorporations.isNotEmpty) {
      count++;
    }

    return count;
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String _formatNumber(
    num value,
  ) {
    return NumberFormat(
      '#,##0',
      'id_ID',
    ).format(
      value,
    );
  }

  String _formatRupiah(
    double value,
  ) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(
      value,
    );
  }

  String _formatPercent(
    double value,
  ) {
    return '${NumberFormat(
      '0.00',
      'id_ID',
    ).format(value)}%';
  }

  String _formatCompactMoney(
    double value,
  ) {
    if (value >= 1000000000) {
      return 'Rp ${NumberFormat(
        '0.00',
        'id_ID',
      ).format(
        value / 1000000000,
      )} Miliar';
    }

    if (value >= 1000000) {
      return 'Rp ${NumberFormat(
        '0.00',
        'id_ID',
      ).format(
        value / 1000000,
      )} Juta';
    }

    return _formatRupiah(
      value,
    );
  }

  // ============================================================
  // PROVIDER / CORPORATION LABEL
  // ============================================================

  String _providerLabel(
    String code,
  ) {
    final data = filters;

    if (data == null) {
      return code;
    }

    for (final item
        in data.providers) {
      if (item.code == code) {
        return item.label;
      }
    }

    return code;
  }

  String _corporationLabel(
    String code,
  ) {
    final data = filters;

    if (data == null) {
      return code;
    }

    for (final item
        in data.corporations) {
      if (item.code == code) {
        return item.label;
      }
    }

    return code;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (
        initialLoading &&
        overview == null) {
      return const Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            CircularProgressIndicator(),

            SizedBox(
              height: 16,
            ),

            Text(
              'Menyiapkan Analytics...',
              style: TextStyle(
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (
        errorMessage != null &&
        overview == null) {
      return _buildInitialError();
    }

    final data =
        overview ??
        const AnalyticsOverview(
          totalClaims: 0,
          totalAcc: 0,
          totalReject: 0,
          approvalRate: 0,
          totalIncurred: 0,
          totalApproved: 0,
          totalNotApproved: 0,
          avgIncurred: 0,
          avgApproved: 0,
          avgLengthOfStay: 0,
          approvedAmountRatio: 0,
        );

    return Stack(
      children: [
        SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            28,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(
                height: 24,
              ),

              _buildAnalyticsBanner(
                data,
              ),

              const SizedBox(
                height: 22,
              ),

              _buildFilterPanel(),

              if (errorMessage != null) ...[
                const SizedBox(
                  height: 14,
                ),

                _buildInlineError(),
              ],

              const SizedBox(
                height: 28,
              ),

              _buildSectionTitle(
                'Analytics Overview',
                'Ringkasan berdasarkan filter yang dipilih',
              ),

              const SizedBox(
                height: 16,
              ),

              _buildKpiCards(
                data,
              ),

              const SizedBox(
                height: 30,
              ),

              _buildSectionTitle(
                'Financial Analysis',
                'Perbandingan nilai incurred, approved, dan not approved',
              ),

              const SizedBox(
                height: 16,
              ),

              _buildFinancialAnalysis(
                data,
              ),

              const SizedBox(
                height: 30,
              ),

              _buildSectionTitle(
                'Claim Performance',
                'Komposisi ACC, Reject, dan approval value',
              ),

              const SizedBox(
                height: 16,
              ),

              _buildClaimPerformance(
                data,
              ),

              const SizedBox(
                height: 40,
              ),
            ],
          ),
        ),

        if (overviewLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child:
                LinearProgressIndicator(
              minHeight: 3,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(
                    0xFF0F172A,
                  ),
                ),
              ),

              SizedBox(
                height: 5,
              ),

              Text(
                'Analisis mendalam pola, biaya, dan karakteristik klaim kesehatan',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Color(
                    0xFF64748B,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 16,
        ),

        OutlinedButton.icon(
          onPressed:
              overviewLoading
                  ? null
                  : _loadOverview,
          icon: const Icon(
            Icons.refresh_rounded,
          ),
          label: const Text(
            'Refresh',
          ),
          style:
              OutlinedButton.styleFrom(
            foregroundColor:
                const Color(
              0xFF2563EB,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BANNER
  // ============================================================

  Widget _buildAnalyticsBanner(
    AnalyticsOverview data,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.centerLeft,
          end:
              Alignment.centerRight,
          colors: [
            Color(0xFF312E81),
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(
              0xFF4F46E5,
            ).withValues(
              alpha: 0.18,
            ),
            blurRadius: 24,
            offset:
                const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interactive Analytics Workspace',
                  style: TextStyle(
                    color:
                        Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                const Text(
                  'Gunakan multifilter untuk mengeksplorasi pola klaim secara dinamis.',
                  style: TextStyle(
                    color:
                        Color(
                      0xFFE0E7FF,
                    ),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _bannerBadge(
                      Icons
                          .filter_alt_rounded,
                      _activeFilters == 0
                          ? 'All Data'
                          : '$_activeFilters Filter Aktif',
                    ),

                    _bannerBadge(
                      Icons
                          .description_outlined,
                      '${_formatNumber(
                        data.totalClaims,
                      )} Claims',
                    ),

                    _bannerBadge(
                      Icons
                          .check_circle_outline,
                      '${_formatPercent(
                        data.approvalRate,
                      )} Approval',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 20,
          ),

          Container(
            width: 76,
            height: 76,
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerBadge(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color:
              Colors.white.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            text,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER PANEL
  // ============================================================

  Widget _buildFilterPanel() {
    final data = filters;

    if (data == null) {
      return const SizedBox.shrink();
    }

    final providerCodes =
        data.providers
            .map(
              (item) =>
                  item.code,
            )
            .toList();

    final corporationCodes =
        data.corporations
            .map(
              (item) =>
                  item.code,
            )
            .toList();

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFE2E8F0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha: 0.03,
            ),
            blurRadius: 16,
            offset:
                const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEFF6FF,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color:
                      Color(
                    0xFF2563EB,
                  ),
                  size: 20,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Filters',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(
                          0xFF0F172A,
                        ),
                      ),
                    ),

                    SizedBox(
                      height: 2,
                    ),

                    Text(
                      'Pilih lebih dari satu nilai pada setiap filter',
                      style:
                          TextStyle(
                        color:
                            Color(
                          0xFF94A3B8,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              TextButton.icon(
                onPressed:
                    _activeFilters == 0 ||
                            overviewLoading
                        ? null
                        : _resetFilters,
                icon: const Icon(
                  Icons
                      .restart_alt_rounded,
                ),
                label:
                    const Text(
                  'Reset Filter',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // ==================================================
              // YEAR
              // ==================================================

              _multiSelectFilter(
                width: 160,
                label: 'Year',
                items: data.years
                    .map(
                      (year) =>
                          year.toString(),
                    )
                    .toList(),
                selectedValues:
                    selectedYears,
                onChanged: (
                  values,
                ) {
                  setState(() {
                    selectedYears
                      ..clear()
                      ..addAll(
                        values,
                      );
                  });
                },
              ),

              // ==================================================
              // COVERAGE
              // ==================================================

              _multiSelectFilter(
                width: 190,
                label: 'Coverage',
                items:
                    data.coverages,
                selectedValues:
                    selectedCoverages,
                onChanged: (
                  values,
                ) {
                  setState(() {
                    selectedCoverages
                      ..clear()
                      ..addAll(
                        values,
                      );
                  });
                },
              ),

              // ==================================================
              // CLAIM TYPE
              // ==================================================

              _multiSelectFilter(
                width: 180,
                label:
                    'Claim Type',
                items:
                    data.claimTypes,
                selectedValues:
                    selectedClaimTypes,
                onChanged: (
                  values,
                ) {
                  setState(() {
                    selectedClaimTypes
                      ..clear()
                      ..addAll(
                        values,
                      );
                  });
                },
              ),

              // ==================================================
              // RESULT
              // ==================================================

              _multiSelectFilter(
                width: 180,
                label: 'Result',
                items:
                    data.results,
                selectedValues:
                    selectedResults,
                onChanged: (
                  values,
                ) {
                  setState(() {
                    selectedResults
                      ..clear()
                      ..addAll(
                        values,
                      );
                  });
                },
              ),

              // ==================================================
              // PROVIDER
              // ==================================================

              _multiSelectFilter(
                width: 310,
                label: 'Provider',
                items:
                    providerCodes,
                selectedValues:
                    selectedProviders,
                itemLabel:
                    _providerLabel,
                onChanged: (
                  values,
                ) {
                  setState(() {
                    selectedProviders
                      ..clear()
                      ..addAll(
                        values,
                      );
                  });
                },
              ),

              // ==================================================
              // CORPORATION
              // ==================================================

              _multiSelectFilter(
                width: 310,
                label:
                    'Corporation',
                items:
                    corporationCodes,
                selectedValues:
                    selectedCorporations,
                itemLabel:
                    _corporationLabel,
                onChanged: (
                  values,
                ) {
                  setState(() {
                    selectedCorporations
                      ..clear()
                      ..addAll(
                        values,
                      );
                  });
                },
              ),
            ],
          ),

          // ======================================================
          // ACTIVE FILTER CHIPS
          // ======================================================

          if (_activeFilters > 0) ...[
            const SizedBox(
              height: 16,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (selectedYears
                    .isNotEmpty)
                  _filterChip(
                    'Year',
                    selectedYears,
                    () {
                      setState(() {
                        selectedYears
                            .clear();
                      });
                    },
                  ),

                if (selectedCoverages
                    .isNotEmpty)
                  _filterChip(
                    'Coverage',
                    selectedCoverages,
                    () {
                      setState(() {
                        selectedCoverages
                            .clear();
                      });
                    },
                  ),

                if (selectedClaimTypes
                    .isNotEmpty)
                  _filterChip(
                    'Claim Type',
                    selectedClaimTypes,
                    () {
                      setState(() {
                        selectedClaimTypes
                            .clear();
                      });
                    },
                  ),

                if (selectedResults
                    .isNotEmpty)
                  _filterChip(
                    'Result',
                    selectedResults,
                    () {
                      setState(() {
                        selectedResults
                            .clear();
                      });
                    },
                  ),

                if (selectedProviders
                    .isNotEmpty)
                  _filterChip(
                    'Provider',
                    selectedProviders,
                    () {
                      setState(() {
                        selectedProviders
                            .clear();
                      });
                    },
                  ),

                if (selectedCorporations
                    .isNotEmpty)
                  _filterChip(
                    'Corporation',
                    selectedCorporations,
                    () {
                      setState(() {
                        selectedCorporations
                            .clear();
                      });
                    },
                  ),
              ],
            ),
          ],

          const SizedBox(
            height: 18,
          ),

          // ======================================================
          // APPLY FILTER BUTTON
          // ======================================================

          SizedBox(
            width: double.infinity,
            child:
                FilledButton.icon(
              onPressed:
                  overviewLoading
                      ? null
                      : _loadOverview,
              icon: const Icon(
                Icons
                    .filter_alt_rounded,
                size: 18,
              ),
              label: const Text(
                'Terapkan Filter',
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF2563EB,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _filterChip(
    String label,
    Set<String> values,
    VoidCallback onDelete,
  ) {
    return Container(
      padding:
          const EdgeInsets.only(
        left: 11,
        right: 4,
        top: 5,
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color:
            const Color(
          0xFFEFF6FF,
        ),
        borderRadius:
            BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFBFDBFE,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Text(
            '$label: ${values.length}',
            style:
                const TextStyle(
              color:
                  Color(
                0xFF1D4ED8,
              ),
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            width: 3,
          ),

          InkWell(
            onTap: onDelete,
            borderRadius:
                BorderRadius.circular(
              999,
            ),
            child: const Padding(
              padding:
                  EdgeInsets.all(
                3,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color:
                    Color(
                  0xFF2563EB,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MULTI SELECT FILTER
  // ============================================================

  Widget _multiSelectFilter({
    required double width,
    required String label,
    required List<String> items,
    required Set<String>
        selectedValues,
    required ValueChanged<
            Set<String>>
        onChanged,
    String Function(String)?
        itemLabel,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(
              left: 2,
              bottom: 6,
            ),
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF475569,
                ),
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          InkWell(
            onTap:
                overviewLoading
                    ? null
                    : () {
                        _showMultiSelectDialog(
                          label:
                              label,
                          items:
                              items,
                          selectedValues:
                              selectedValues,
                          onChanged:
                              onChanged,
                          itemLabel:
                              itemLabel,
                        );
                      },
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            child: Container(
              height: 46,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF8FAFC,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color:
                      selectedValues
                              .isEmpty
                          ? const Color(
                              0xFFE2E8F0,
                            )
                          : const Color(
                              0xFF93C5FD,
                            ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedSummary(
                        selectedValues,
                        itemLabel,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          TextStyle(
                        color:
                            selectedValues
                                    .isEmpty
                                ? const Color(
                                    0xFF94A3B8,
                                  )
                                : const Color(
                                    0xFF0F172A,
                                  ),
                        fontSize: 12,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ),

                  if (selectedValues
                      .isNotEmpty) ...[
                    const SizedBox(
                      width: 6,
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFDBEAFE,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          999,
                        ),
                      ),
                      child: Text(
                        '${selectedValues.length}',
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFF1D4ED8,
                          ),
                          fontSize:
                              10,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    width: 6,
                  ),

                  const Icon(
                    Icons
                        .keyboard_arrow_down_rounded,
                    size: 19,
                    color:
                        Color(
                      0xFF64748B,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECTED SUMMARY
  // ============================================================

  String _selectedSummary(
    Set<String> selectedValues,
    String Function(String)?
        itemLabel,
  ) {
    if (selectedValues.isEmpty) {
      return 'Semua';
    }

    final labels =
        selectedValues
            .map(
              (
                value,
              ) =>
                  itemLabel?.call(
                    value,
                  ) ??
                  value,
            )
            .toList();

    if (labels.length <= 2) {
      return labels.join(', ');
    }

    return '${labels.take(2).join(', ')} +${labels.length - 2}';
  }

  // ============================================================
  // MULTI SELECT DIALOG
  // ============================================================

  Future<void>
      _showMultiSelectDialog({
    required String label,
    required List<String> items,
    required Set<String>
        selectedValues,
    required ValueChanged<
            Set<String>>
        onChanged,
    String Function(String)?
        itemLabel,
  }) async {
    final temporarySelected =
        Set<String>.from(
      selectedValues,
    );

    final searchController =
        TextEditingController();

    String searchQuery = '';

    final result =
        await showDialog<
            Set<String>>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final filteredItems =
                items.where(
              (
                item,
              ) {
                final text =
                    itemLabel?.call(
                          item,
                        ) ??
                        item;

                if (searchQuery
                    .trim()
                    .isEmpty) {
                  return true;
                }

                return text
                    .toLowerCase()
                    .contains(
                      searchQuery
                          .trim()
                          .toLowerCase(),
                    );
              },
            ).toList();

            return AlertDialog(
              backgroundColor:
                  Colors.white,
              surfaceTintColor:
                  Colors.white,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              titlePadding:
                  const EdgeInsets
                      .fromLTRB(
                22,
                20,
                14,
                0,
              ),
              contentPadding:
                  const EdgeInsets
                      .fromLTRB(
                22,
                16,
                22,
                0,
              ),
              actionsPadding:
                  const EdgeInsets
                      .fromLTRB(
                16,
                12,
                16,
                16,
              ),

              // ==================================================
              // TITLE
              // ==================================================

              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFEFF6FF,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .filter_list_rounded,
                      color:
                          Color(
                        0xFF2563EB,
                      ),
                      size: 20,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          label,
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF0F172A,
                            ),
                            fontSize:
                                17,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          '${temporarySelected.length} dipilih',
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF64748B,
                            ),
                            fontSize:
                                11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip:
                        'Tutup',
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop();
                    },
                    icon: const Icon(
                      Icons
                          .close_rounded,
                    ),
                  ),
                ],
              ),

              // ==================================================
              // CONTENT
              // ==================================================

              content: SizedBox(
                width: 520,
                height: 480,
                child: Column(
                  children: [
                    // ============================================
                    // SEARCH
                    // ============================================

                    TextField(
                      controller:
                          searchController,
                      onChanged: (
                        value,
                      ) {
                        setDialogState(
                          () {
                            searchQuery =
                                value;
                          },
                        );
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'Cari $label...',
                        prefixIcon:
                            const Icon(
                          Icons
                              .search_rounded,
                          size: 20,
                        ),
                        suffixIcon:
                            searchQuery
                                    .isEmpty
                                ? null
                                : IconButton(
                                    onPressed:
                                        () {
                                      searchController
                                          .clear();

                                      setDialogState(
                                        () {
                                          searchQuery =
                                              '';
                                        },
                                      );
                                    },
                                    icon:
                                        const Icon(
                                      Icons
                                          .close_rounded,
                                      size:
                                          18,
                                    ),
                                  ),
                        filled: true,
                        fillColor:
                            const Color(
                          0xFFF8FAFC,
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              12,
                          vertical:
                              12,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(
                              0xFFE2E8F0,
                            ),
                          ),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(
                              0xFFE2E8F0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ============================================
                    // SELECT ALL / CLEAR
                    // ============================================

                    Row(
                      children: [
                        TextButton.icon(
                          onPressed:
                              () {
                            setDialogState(
                              () {
                                temporarySelected
                                    .addAll(
                                  filteredItems,
                                );
                              },
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .done_all_rounded,
                            size: 17,
                          ),
                          label:
                              const Text(
                            'Pilih Semua',
                          ),
                        ),

                        TextButton.icon(
                          onPressed:
                              temporarySelected
                                      .isEmpty
                                  ? null
                                  : () {
                                      setDialogState(
                                        () {
                                          temporarySelected
                                              .clear();
                                        },
                                      );
                                    },
                          icon:
                              const Icon(
                            Icons
                                .remove_done_rounded,
                            size: 17,
                          ),
                          label:
                              const Text(
                            'Hapus Semua',
                          ),
                        ),

                        const Spacer(),

                        Text(
                          '${filteredItems.length} opsi',
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF94A3B8,
                            ),
                            fontSize:
                                11,
                          ),
                        ),
                      ],
                    ),

                    const Divider(
                      height: 1,
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    // ============================================
                    // ITEM LIST
                    // ============================================

                    Expanded(
                      child:
                          filteredItems
                                  .isEmpty
                              ? const Center(
                                  child:
                                      Text(
                                    'Data tidak ditemukan.',
                                    style:
                                        TextStyle(
                                      color:
                                          Color(
                                        0xFF94A3B8,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount:
                                      filteredItems
                                          .length,
                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {
                                    final item =
                                        filteredItems[
                                            index];

                                    final text =
                                        itemLabel?.call(
                                              item,
                                            ) ??
                                            item;

                                    final checked =
                                        temporarySelected
                                            .contains(
                                      item,
                                    );

                                    return InkWell(
                                      onTap:
                                          () {
                                        setDialogState(
                                          () {
                                            if (checked) {
                                              temporarySelected
                                                  .remove(
                                                item,
                                              );
                                            } else {
                                              temporarySelected
                                                  .add(
                                                item,
                                              );
                                            }
                                          },
                                        );
                                      },
                                      borderRadius:
                                          BorderRadius.circular(
                                        10,
                                      ),
                                      child:
                                          Padding(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal:
                                              4,
                                          vertical:
                                              3,
                                        ),
                                        child:
                                            Row(
                                          children: [
                                            Checkbox(
                                              value:
                                                  checked,
                                              onChanged:
                                                  (
                                                value,
                                              ) {
                                                setDialogState(
                                                  () {
                                                    if (value ==
                                                        true) {
                                                      temporarySelected
                                                          .add(
                                                        item,
                                                      );
                                                    } else {
                                                      temporarySelected
                                                          .remove(
                                                        item,
                                                      );
                                                    }
                                                  },
                                                );
                                              },
                                            ),

                                            const SizedBox(
                                              width:
                                                  5,
                                            ),

                                            Expanded(
                                              child:
                                                  Text(
                                                text,
                                                style:
                                                    TextStyle(
                                                  color: checked
                                                      ? const Color(
                                                          0xFF1D4ED8,
                                                        )
                                                      : const Color(
                                                          0xFF334155,
                                                        ),
                                                  fontSize:
                                                      13,
                                                  fontWeight: checked
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ACTIONS
              // ==================================================

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                      const Text(
                    'Batal',
                  ),
                ),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(
                      Set<String>.from(
                        temporarySelected,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons
                        .check_rounded,
                    size: 17,
                  ),
                  label:
                      const Text(
                    'Gunakan Pilihan',
                  ),
                  style:
                      FilledButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF2563EB,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    searchController.dispose();

    if (
        result != null &&
        mounted) {
      onChanged(
        result,
      );
    }
  }

  // ============================================================
  // KPI
  // ============================================================

  Widget _buildKpiCards(
    AnalyticsOverview data,
  ) {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
        int columns = 4;

        if (
            constraints.maxWidth <
            700) {
          columns = 1;
        } else if (
            constraints.maxWidth <
            1100) {
          columns = 2;
        }

        final width =
            (
              constraints.maxWidth -
              (
                (columns - 1) *
                16
              )
            ) /
            columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _kpiCard(
              width: width,
              title:
                  'Filtered Claims',
              value:
                  _formatNumber(
                data.totalClaims,
              ),
              subtitle:
                  'Jumlah klaim hasil filter',
              icon:
                  Icons
                      .description_outlined,
              accent:
                  const Color(
                0xFF2563EB,
              ),
              soft:
                  const Color(
                0xFFEFF6FF,
              ),
            ),

            _kpiCard(
              width: width,
              title:
                  'Avg Incurred',
              value:
                  _formatRupiah(
                data.avgIncurred,
              ),
              subtitle:
                  'Rata-rata nilai pengajuan',
              icon:
                  Icons
                      .receipt_long_rounded,
              accent:
                  const Color(
                0xFFF97316,
              ),
              soft:
                  const Color(
                0xFFFFF7ED,
              ),
            ),

            _kpiCard(
              width: width,
              title:
                  'Approval Rate',
              value:
                  _formatPercent(
                data.approvalRate,
              ),
              subtitle:
                  'Persentase klaim ACC',
              icon:
                  Icons
                      .verified_rounded,
              accent:
                  const Color(
                0xFF16A34A,
              ),
              soft:
                  const Color(
                0xFFECFDF3,
              ),
            ),

            _kpiCard(
              width: width,
              title:
                  'Avg Length of Stay',
              value:
                  '${NumberFormat(
                '0.00',
                'id_ID',
              ).format(
                data.avgLengthOfStay,
              )} Hari',
              subtitle:
                  'Rata-rata lama perawatan',
              icon:
                  Icons.hotel_rounded,
              accent:
                  const Color(
                0xFF7C3AED,
              ),
              soft:
                  const Color(
                0xFFF5F3FF,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Color soft,
  }) {
    return Container(
      width: width,
      constraints:
          const BoxConstraints(
        minHeight: 160,
      ),
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration:
                    BoxDecoration(
                  color: soft,
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 22,
                ),
              ),

              const Spacer(),

              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(
                  color: accent,
                  shape:
                      BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            title,
            style:
                const TextStyle(
              color:
                  Color(
                0xFF64748B,
              ),
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          FittedBox(
            fit:
                BoxFit.scaleDown,
            alignment:
                Alignment.centerLeft,
            child: Text(
              value,
              style:
                  const TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(
                  0xFF0F172A,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            subtitle,
            style:
                const TextStyle(
              color:
                  Color(
                0xFF94A3B8,
              ),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FINANCIAL ANALYSIS
  // ============================================================

  Widget _buildFinancialAnalysis(
    AnalyticsOverview data,
  ) {
    final maxValue =
        data.totalIncurred <= 0
            ? 1.0
            : data.totalIncurred;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration:
          _cardDecoration(),
      child: Column(
        children: [
          _financialMetric(
            title:
                'Total Incurred',
            value:
                data.totalIncurred,
            maxValue:
                maxValue,
            color:
                const Color(
              0xFFF59E0B,
            ),
            icon:
                Icons
                    .receipt_long_rounded,
          ),

          const SizedBox(
            height: 24,
          ),

          _financialMetric(
            title:
                'Total Approved',
            value:
                data.totalApproved,
            maxValue:
                maxValue,
            color:
                const Color(
              0xFF16A34A,
            ),
            icon:
                Icons
                    .payments_rounded,
          ),

          const SizedBox(
            height: 24,
          ),

          _financialMetric(
            title:
                'Not Approved',
            value:
                data.totalNotApproved,
            maxValue:
                maxValue,
            color:
                const Color(
              0xFFDC2626,
            ),
            icon:
                Icons
                    .money_off_rounded,
          ),
        ],
      ),
    );
  }

  Widget _financialMetric({
    required String title,
    required double value,
    required double maxValue,
    required Color color,
    required IconData icon,
  }) {
    final progress =
        maxValue > 0
            ? (
                value /
                maxValue
              ).clamp(
                0.0,
                1.0,
              )
            : 0.0;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
                  BoxDecoration(
                color:
                    color.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 19,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Color(
                        0xFF64748B,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    _formatCompactMoney(
                      value,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight
                              .w800,
                      color:
                          Color(
                        0xFF0F172A,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              _formatRupiah(
                value,
              ),
              style:
                  const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 11,
        ),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(
            999,
          ),
          child:
              LinearProgressIndicator(
            value:
                progress.toDouble(),
            minHeight: 8,
            backgroundColor:
                const Color(
              0xFFF1F5F9,
            ),
            valueColor:
                AlwaysStoppedAnimation<
                    Color>(
              color,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CLAIM PERFORMANCE
  // ============================================================

  Widget _buildClaimPerformance(
    AnalyticsOverview data,
  ) {
    final accRate =
        data.totalClaims > 0
            ? data.totalAcc /
                data.totalClaims
            : 0.0;

    final rejectRate =
        data.totalClaims > 0
            ? data.totalReject /
                data.totalClaims
            : 0.0;

    final amountRate =
        (
          data.approvedAmountRatio /
          100
        ).clamp(
          0.0,
          1.0,
        );

    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
        final compact =
            constraints.maxWidth <
            900;

        final statusCard =
            _performanceCard(
          title:
              'Claim Status Composition',
          icon:
              Icons
                  .donut_large_rounded,
          accent:
              const Color(
            0xFF2563EB,
          ),
          children: [
            _performanceRow(
              label: 'ACC',
              value:
                  '${_formatNumber(
                data.totalAcc,
              )} Claims',
              percent:
                  accRate,
              color:
                  const Color(
                0xFF16A34A,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            _performanceRow(
              label: 'Reject',
              value:
                  '${_formatNumber(
                data.totalReject,
              )} Claims',
              percent:
                  rejectRate,
              color:
                  const Color(
                0xFFDC2626,
              ),
            ),
          ],
        );

        final approvalCard =
            _performanceCard(
          title:
              'Financial Approval',
          icon:
              Icons
                  .account_balance_wallet_rounded,
          accent:
              const Color(
            0xFF7C3AED,
          ),
          children: [
            _performanceRow(
              label:
                  'Approved Amount Ratio',
              value:
                  _formatPercent(
                data.approvedAmountRatio,
              ),
              percent:
                  amountRate.toDouble(),
              color:
                  const Color(
                0xFF7C3AED,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            _performanceRow(
              label:
                  'Claim Approval Rate',
              value:
                  _formatPercent(
                data.approvalRate,
              ),
              percent:
                  (
                    data.approvalRate /
                    100
                  ).clamp(
                    0.0,
                    1.0,
                  ).toDouble(),
              color:
                  const Color(
                0xFF0891B2,
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            children: [
              statusCard,

              const SizedBox(
                height: 16,
              ),

              approvalCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
                  statusCard,
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child:
                  approvalCard,
            ),
          ],
        );
      },
    );
  }

  Widget _performanceCard({
    required String title,
    required IconData icon,
    required Color accent,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration:
          _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  color:
                      accent.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(
                    0xFF0F172A,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          ...children,
        ],
      ),
    );
  }

  Widget _performanceRow({
    required String label,
    required String value,
    required double percent,
    required Color color,
  }) {
    final safePercent =
        percent.clamp(
          0.0,
          1.0,
        );

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(
                color: color,
                shape:
                    BoxShape.circle,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(
                    0xFF475569,
                  ),
                ),
              ),
            ),

            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(
                  0xFF0F172A,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 10,
        ),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(
            999,
          ),
          child:
              LinearProgressIndicator(
            value:
                safePercent.toDouble(),
            minHeight: 9,
            backgroundColor:
                const Color(
              0xFFF1F5F9,
            ),
            valueColor:
                AlwaysStoppedAnimation<
                    Color>(
              color,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              const TextStyle(
            color:
                Color(
              0xFF0F172A,
            ),
            fontSize: 18,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          subtitle,
          style:
              const TextStyle(
            color:
                Color(
              0xFF94A3B8,
            ),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      border: Border.all(
        color:
            const Color(
          0xFFE2E8F0,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color:
              Colors.black
                  .withValues(
            alpha: 0.03,
          ),
          blurRadius: 18,
          offset:
              const Offset(
            0,
            7,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INITIAL ERROR
  // ============================================================

  Widget _buildInitialError() {
    return Center(
      child: Container(
        margin:
            const EdgeInsets.all(
          28,
        ),
        padding:
            const EdgeInsets.all(
          28,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          border: Border.all(
            color:
                const Color(
              0xFFFECACA,
            ),
          ),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              color:
                  Color(
                0xFFDC2626,
              ),
              size: 42,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Analytics gagal dimuat',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              errorMessage ?? '',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            FilledButton.icon(
              onPressed:
                  _loadInitialData,
              icon:
                  const Icon(
                Icons
                    .refresh_rounded,
              ),
              label:
                  const Text(
                'Coba Lagi',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INLINE ERROR
  // ============================================================

  Widget _buildInlineError() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color:
            const Color(
          0xFFFEF2F2,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFFECACA,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .error_outline_rounded,
            color:
                Color(
              0xFFDC2626,
            ),
            size: 18,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              errorMessage ?? '',
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF991B1B,
                ),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}