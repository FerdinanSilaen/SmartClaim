import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/claim_record.dart';
import '../services/claim_service.dart';

class ClaimExplorerContent extends StatefulWidget {
  const ClaimExplorerContent({super.key});

  @override
  State<ClaimExplorerContent> createState() =>
      _ClaimExplorerContentState();
}

class _ClaimExplorerContentState
    extends State<ClaimExplorerContent> {
  final TextEditingController _searchController =
      TextEditingController();

  ClaimFilters? _filters;
  ClaimPage? _claimPage;

  bool _loadingFilters = true;
  bool _loadingClaims = true;

  String? _error;

  // ============================================================
  // MULTI SELECT FILTER STATE
  // ============================================================

  final Set<String> _selectedStatuses = <String>{};
  final Set<String> _selectedCoverages = <String>{};
  final Set<String> _selectedClaimTypes = <String>{};
  final Set<String> _selectedAdmissionTypes = <String>{};

  int _page = 1;
  int _limit = 25;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadFilters(),
      _loadClaims(),
    ]);
  }

  // ============================================================
  // LOAD FILTER
  // ============================================================

  Future<void> _loadFilters() async {
    if (mounted) {
      setState(() {
        _loadingFilters = true;
      });
    }

    try {
      final result = await ClaimService.getFilters();

      if (!mounted) return;

      setState(() {
        _filters = result;
        _loadingFilters = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingFilters = false;
        _error = error.toString();
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

    return values.join(',');
  }

  // ============================================================
  // LOAD CLAIM
  // ============================================================

  Future<void> _loadClaims() async {
    if (mounted) {
      setState(() {
        _loadingClaims = true;
        _error = null;
      });
    }

    try {
      final result = await ClaimService.getClaims(
        page: _page,
        limit: _limit,
        search: _searchController.text,
        status: _encodeSelected(
          _selectedStatuses,
        ),
        coverage: _encodeSelected(
          _selectedCoverages,
        ),
        claimType: _encodeSelected(
          _selectedClaimTypes,
        ),
        admissionType: _encodeSelected(
          _selectedAdmissionTypes,
        ),
      );

      if (!mounted) return;

      setState(() {
        _claimPage = result;
        _page = result.page;
        _loadingClaims = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingClaims = false;
        _error = error.toString();
      });
    }
  }

  // ============================================================
  // APPLY FILTER
  // ============================================================

  Future<void> _applyFilters() async {
    setState(() {
      _page = 1;
    });

    await _loadClaims();
  }

  // ============================================================
  // RESET FILTER
  // ============================================================

  Future<void> _resetFilters() async {
    _searchController.clear();

    setState(() {
      _selectedStatuses.clear();
      _selectedCoverages.clear();
      _selectedClaimTypes.clear();
      _selectedAdmissionTypes.clear();

      _page = 1;
    });

    await _loadClaims();
  }

  // ============================================================
  // FORMATTER
  // ============================================================

  String _formatNumber(num value) {
    return NumberFormat(
      '#,##0',
      'id_ID',
    ).format(value);
  }

  String _formatRupiah(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusCode(
    String rawStatus,
  ) {
    if (rawStatus.endsWith('.0')) {
      return rawStatus.substring(
        0,
        rawStatus.length - 2,
      );
    }

    return rawStatus;
  }

  bool _isApproved(
    String rawStatus,
  ) {
    final status = _statusCode(
      rawStatus,
    );

    return status == '40' ||
        status == '58' ||
        status == '80';
  }

  String _statusLabel(
    String rawStatus,
  ) {
    final code = _statusCode(
      rawStatus,
    );

    return _isApproved(rawStatus)
        ? 'ACC ($code)'
        : 'Reject ($code)';
  }

  Color _statusColor(
    String status,
  ) {
    return _isApproved(status)
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
  }

  Color _statusSoftColor(
    String status,
  ) {
    return _isApproved(status)
        ? const Color(0xFFECFDF3)
        : const Color(0xFFFEF2F2);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final pageData = _claimPage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Claim Explorer',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Cari, filter, dan investigasi data klaim kesehatan',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          _buildFilterCard(),

          const SizedBox(height: 18),

          if (_error != null) ...[
            _buildErrorCard(),
            const SizedBox(height: 18),
          ],

          _buildResultSummary(
            pageData,
          ),

          const SizedBox(height: 14),

          _buildTableCard(
            pageData,
          ),

          const SizedBox(height: 16),

          if (pageData != null)
            _buildPagination(
              pageData,
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CARD
  // ============================================================

  Widget _buildFilterCard() {
    final filters = _filters;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(
            0xFFE2E8F0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 16,
            offset: const Offset(
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
              const Icon(
                Icons.tune_rounded,
                size: 20,
                color: Color(
                  0xFF2563EB,
                ),
              ),

              const SizedBox(width: 8),

              const Text(
                'Search & Filter',
                style: TextStyle(
                  color: Color(
                    0xFF0F172A,
                  ),
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const Spacer(),

              if (_loadingFilters)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ======================================================
          // SEARCH
          // ======================================================

          TextField(
            controller:
                _searchController,
            onSubmitted: (_) =>
                _applyFilters(),
            decoration:
                InputDecoration(
              hintText:
                  'Cari CLAIMS_ID, provider, perusahaan, diagnosis...',
              prefixIcon:
                  const Icon(
                Icons.search_rounded,
              ),
              suffixIcon:
                  IconButton(
                tooltip: 'Cari',
                onPressed:
                    _applyFilters,
                icon: const Icon(
                  Icons
                      .arrow_forward_rounded,
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
                horizontal: 14,
                vertical: 16,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                borderSide:
                    const BorderSide(
                  color: Color(
                    0xFFE2E8F0,
                  ),
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                borderSide:
                    const BorderSide(
                  color: Color(
                    0xFFE2E8F0,
                  ),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                borderSide:
                    const BorderSide(
                  color: Color(
                    0xFF2563EB,
                  ),
                  width: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ======================================================
          // MULTI SELECT FILTERS
          // ======================================================

          LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final width =
                  constraints.maxWidth;

              final fieldWidth =
                  width < 720
                      ? width
                      : width < 1100
                          ? (width - 12) /
                              2
                          : (width - 36) /
                              4;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // STATUS
                  SizedBox(
                    width: fieldWidth,
                    child:
                        _multiSelectFilter(
                      label: 'Status',
                      items:
                          filters
                                  ?.statuses ??
                              const <
                                  String>[],
                      selectedValues:
                          _selectedStatuses,
                      itemLabel:
                          _statusLabel,
                      onChanged:
                          (values) {
                        setState(() {
                          _selectedStatuses
                            ..clear()
                            ..addAll(
                              values,
                            );
                        });
                      },
                    ),
                  ),

                  // COVERAGE
                  SizedBox(
                    width: fieldWidth,
                    child:
                        _multiSelectFilter(
                      label: 'Coverage',
                      items:
                          filters
                                  ?.coverages ??
                              const <
                                  String>[],
                      selectedValues:
                          _selectedCoverages,
                      onChanged:
                          (values) {
                        setState(() {
                          _selectedCoverages
                            ..clear()
                            ..addAll(
                              values,
                            );
                        });
                      },
                    ),
                  ),

                  // CLAIM TYPE
                  SizedBox(
                    width: fieldWidth,
                    child:
                        _multiSelectFilter(
                      label:
                          'Claim Type',
                      items:
                          filters
                                  ?.claimTypes ??
                              const <
                                  String>[],
                      selectedValues:
                          _selectedClaimTypes,
                      onChanged:
                          (values) {
                        setState(() {
                          _selectedClaimTypes
                            ..clear()
                            ..addAll(
                              values,
                            );
                        });
                      },
                    ),
                  ),

                  // ADMISSION TYPE
                  SizedBox(
                    width: fieldWidth,
                    child:
                        _multiSelectFilter(
                      label:
                          'Admission Type',
                      items:
                          filters
                                  ?.admissionTypes ??
                              const <
                                  String>[],
                      selectedValues:
                          _selectedAdmissionTypes,
                      onChanged:
                          (values) {
                        setState(() {
                          _selectedAdmissionTypes
                            ..clear()
                            ..addAll(
                              values,
                            );
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // ======================================================
          // ACTIVE FILTER CHIPS
          // ======================================================

          if (_hasActiveFilters())
            Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 14,
              ),
              child:
                  _buildActiveFilters(),
            ),

          // ======================================================
          // ACTION BUTTONS
          // ======================================================

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed:
                    _loadingClaims
                        ? null
                        : _applyFilters,
                icon: const Icon(
                  Icons
                      .filter_alt_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Terapkan Filter',
                ),
                style:
                    FilledButton
                        .styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF2563EB,
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),

              OutlinedButton.icon(
                onPressed:
                    _loadingClaims
                        ? null
                        : _resetFilters,
                icon: const Icon(
                  Icons
                      .restart_alt_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Reset',
                ),
                style:
                    OutlinedButton
                        .styleFrom(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),

              OutlinedButton.icon(
                onPressed:
                    _loadingClaims
                        ? null
                        : _loadClaims,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Refresh',
                ),
                style:
                    OutlinedButton
                        .styleFrom(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE FILTER
  // ============================================================

  bool _hasActiveFilters() {
    return _selectedStatuses
            .isNotEmpty ||
        _selectedCoverages
            .isNotEmpty ||
        _selectedClaimTypes
            .isNotEmpty ||
        _selectedAdmissionTypes
            .isNotEmpty;
  }

  Widget _buildActiveFilters() {
    final chips = <Widget>[];

    for (final value
        in _selectedStatuses) {
      chips.add(
        _activeFilterChip(
          label:
              _statusLabel(value),
          onDeleted: () {
            setState(() {
              _selectedStatuses
                  .remove(value);
            });
          },
        ),
      );
    }

    for (final value
        in _selectedCoverages) {
      chips.add(
        _activeFilterChip(
          label: value,
          onDeleted: () {
            setState(() {
              _selectedCoverages
                  .remove(value);
            });
          },
        ),
      );
    }

    for (final value
        in _selectedClaimTypes) {
      chips.add(
        _activeFilterChip(
          label: value,
          onDeleted: () {
            setState(() {
              _selectedClaimTypes
                  .remove(value);
            });
          },
        ),
      );
    }

    for (final value
        in _selectedAdmissionTypes) {
      chips.add(
        _activeFilterChip(
          label: value,
          onDeleted: () {
            setState(() {
              _selectedAdmissionTypes
                  .remove(value);
            });
          },
        ),
      );
    }

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: chips,
    );
  }

  Widget _activeFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Container(
      padding:
          const EdgeInsets.only(
        left: 10,
        right: 4,
        top: 5,
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFEFF6FF,
        ),
        borderRadius:
            BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color: const Color(
            0xFFBFDBFE,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(
                0xFF1D4ED8,
              ),
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(width: 3),

          InkWell(
            borderRadius:
                BorderRadius.circular(
              999,
            ),
            onTap: onDeleted,
            child: const Padding(
              padding:
                  EdgeInsets.all(3),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: Color(
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
  //
  // PERBAIKAN UTAMA:
  // Tidak menggunakan InputDecorator + labelText.
  // Label dan nilai dibuat manual dua baris supaya tidak overlap.
  // ============================================================

  Widget _multiSelectFilter({
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
    final displayText =
        _multiSelectDisplayText(
      selectedValues,
      itemLabel,
    );

    final disabled =
        _loadingFilters ||
            items.isEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        onTap: disabled
            ? null
            : () {
                _showMultiSelectDialog(
                  label: label,
                  items: items,
                  selectedValues:
                      selectedValues,
                  onChanged:
                      onChanged,
                  itemLabel:
                      itemLabel,
                );
              },
        child: Container(
          height: 58,
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: disabled
                ? const Color(
                    0xFFF1F5F9,
                  )
                : const Color(
                    0xFFF8FAFC,
                  ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: const Color(
                0xFFE2E8F0,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color: Color(
                          0xFF64748B,
                        ),
                        fontSize: 10,
                        fontWeight:
                            FontWeight
                                .w500,
                        height: 1,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      displayText,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: TextStyle(
                        color: disabled
                            ? const Color(
                                0xFF94A3B8,
                              )
                            : selectedValues
                                    .isEmpty
                                ? const Color(
                                    0xFF64748B,
                                  )
                                : const Color(
                                    0xFF0F172A,
                                  ),
                        fontSize: 13,
                        fontWeight:
                            selectedValues
                                    .isEmpty
                                ? FontWeight
                                    .w400
                                : FontWeight
                                    .w600,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              if (selectedValues
                  .isNotEmpty)
                Container(
                  constraints:
                      const BoxConstraints(
                    minWidth: 24,
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFDBEAFE,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      999,
                    ),
                  ),
                  child: Text(
                    '${selectedValues.length}',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color: Color(
                        0xFF1D4ED8,
                      ),
                      fontSize: 10,
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
                ),

              if (selectedValues
                  .isNotEmpty)
                const SizedBox(
                  width: 6,
                ),

              Icon(
                Icons
                    .keyboard_arrow_down_rounded,
                size: 20,
                color: disabled
                    ? const Color(
                        0xFFCBD5E1,
                      )
                    : const Color(
                        0xFF64748B,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPLAY FILTER VALUE
  // ============================================================

  String _multiSelectDisplayText(
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
              (value) =>
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
              (item) {
                final labelText =
                    itemLabel?.call(
                          item,
                        ) ??
                        item;

                if (searchQuery
                    .trim()
                    .isEmpty) {
                  return true;
                }

                return labelText
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
                    BorderRadius
                        .circular(
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

              // ================================================
              // TITLE
              // ================================================

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
                          BorderRadius
                              .circular(
                        11,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .filter_list_rounded,
                      color: Color(
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
                    tooltip: 'Tutup',
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

              // ================================================
              // CONTENT
              // ================================================

              content: SizedBox(
                width: 430,
                height: 480,
                child: Column(
                  children: [
                    // SEARCH
                    TextField(
                      controller:
                          searchController,
                      onChanged:
                          (value) {
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
                        filled: true,
                        fillColor:
                            const Color(
                          0xFFF8FAFC,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
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
                              BorderRadius
                                  .circular(
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
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(
                              0xFF2563EB,
                            ),
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // SELECT ALL / CLEAR
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed:
                              () {
                            setDialogState(
                              () {
                                temporarySelected
                                  ..clear()
                                  ..addAll(
                                    items,
                                  );
                              },
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .select_all_rounded,
                            size: 17,
                          ),
                          label:
                              const Text(
                            'Pilih Semua',
                          ),
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        TextButton.icon(
                          onPressed:
                              () {
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
                          '${temporarySelected.length}/${items.length}',
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF64748B,
                            ),
                            fontSize:
                                11,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ),

                    const Divider(
                      height: 16,
                      color: Color(
                        0xFFE2E8F0,
                      ),
                    ),

                    // OPTION LIST
                    Expanded(
                      child:
                          filteredItems
                                  .isEmpty
                              ? const Center(
                                  child:
                                      Text(
                                    'Pilihan tidak ditemukan.',
                                    style:
                                        TextStyle(
                                      color:
                                          Color(
                                        0xFF64748B,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView
                                  .separated(
                                  itemCount:
                                      filteredItems
                                          .length,
                                  separatorBuilder:
                                      (
                                    context,
                                    index,
                                  ) =>
                                          const SizedBox(
                                    height:
                                        4,
                                  ),
                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {
                                    final item =
                                        filteredItems[
                                            index];

                                    final checked =
                                        temporarySelected
                                            .contains(
                                      item,
                                    );

                                    final text =
                                        itemLabel?.call(
                                              item,
                                            ) ??
                                            item;

                                    return Material(
                                      color: checked
                                          ? const Color(
                                              0xFFEFF6FF,
                                            )
                                          : Colors
                                              .transparent,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        10,
                                      ),
                                      child:
                                          InkWell(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          10,
                                        ),
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
                                        child:
                                            Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal:
                                                8,
                                            vertical:
                                                5,
                                          ),
                                          child:
                                              Row(
                                            children: [
                                              Checkbox(
                                                value:
                                                    checked,
                                                activeColor:
                                                    const Color(
                                                  0xFF2563EB,
                                                ),
                                                onChanged:
                                                    (
                                                  value,
                                                ) {
                                                  setDialogState(
                                                    () {
                                                      if (value ==
                                                          true) {
                                                        temporarySelected.add(
                                                          item,
                                                        );
                                                      } else {
                                                        temporarySelected.remove(
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
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),

              // ================================================
              // ACTIONS
              // ================================================

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
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
                    Icons.check_rounded,
                    size: 17,
                  ),
                  label: const Text(
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

    if (result != null) {
      onChanged(result);
    }
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFEF2F2,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: const Color(
            0xFFFECACA,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .error_outline_rounded,
            color: Color(
              0xFFDC2626,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _error ??
                  'Terjadi kesalahan.',
              style:
                  const TextStyle(
                color: Color(
                  0xFF991B1B,
                ),
                fontSize: 12,
              ),
            ),
          ),

          TextButton(
            onPressed:
                _loadClaims,
            child: const Text(
              'Coba lagi',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT SUMMARY
  // ============================================================

  Widget _buildResultSummary(
    ClaimPage? pageData,
  ) {
    final total =
        pageData?.total ?? 0;

    final count =
        pageData?.items.length ??
            0;

    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration:
              BoxDecoration(
            color: const Color(
              0xFFEFF6FF,
            ),
            borderRadius:
                BorderRadius
                    .circular(
              999,
            ),
          ),
          child: Text(
            _loadingClaims
                ? 'Memuat data...'
                : '${_formatNumber(total)} klaim ditemukan',
            style:
                const TextStyle(
              color: Color(
                0xFF1D4ED8,
              ),
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(width: 10),

        if (!_loadingClaims)
          Text(
            'Menampilkan $count data pada halaman $_page',
            style:
                const TextStyle(
              color: Color(
                0xFF64748B,
              ),
              fontSize: 12,
            ),
          ),

        const Spacer(),

        const Text(
          'Klik baris untuk melihat detail',
          style: TextStyle(
            color: Color(
              0xFF94A3B8,
            ),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildTableCard(
    ClaimPage? pageData,
  ) {
    if (_loadingClaims &&
        pageData == null) {
      return Container(
        height: 360,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: const Color(
              0xFFE2E8F0,
            ),
          ),
        ),
        child: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final items =
        pageData?.items ??
            const <ClaimRecord>[];

    if (items.isEmpty &&
        !_loadingClaims) {
      return Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: const Color(
              0xFFE2E8F0,
            ),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons
                    .search_off_rounded,
                size: 44,
                color: Color(
                  0xFF94A3B8,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Tidak ada klaim yang cocok dengan filter.',
                style: TextStyle(
                  color: Color(
                    0xFF64748B,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius
                    .circular(
              18,
            ),
            border: Border.all(
              color: const Color(
                0xFFE2E8F0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.025,
                ),
                blurRadius: 14,
                offset:
                    const Offset(
                  0,
                  5,
                ),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius
                    .circular(
              18,
            ),
            child:
                SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty
                        .all(
                  const Color(
                    0xFFF8FAFC,
                  ),
                ),
                dataRowMinHeight: 58,
                dataRowMaxHeight: 68,
                columnSpacing: 24,
                headingTextStyle:
                    const TextStyle(
                  color: Color(
                    0xFF475569,
                  ),
                  fontWeight:
                      FontWeight
                          .w700,
                  fontSize: 11,
                ),
                dataTextStyle:
                    const TextStyle(
                  color: Color(
                    0xFF334155,
                  ),
                  fontSize: 11,
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'CLAIMS ID',
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'STATUS',
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'COVERAGE',
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'PROVIDER',
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ADMISSION',
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'DIAGNOSIS',
                    ),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(
                      'INCURRED',
                    ),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(
                      'APPROVED',
                    ),
                  ),
                ],
                rows: items.map(
                  (item) {
                    return DataRow(
                      onSelectChanged:
                          (_) {
                        _showClaimDetail(
                          item,
                        );
                      },
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 130,
                            child: Text(
                              item.claimsId,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color:
                                    Color(
                                  0xFF0F172A,
                                ),
                              ),
                            ),
                          ),
                        ),

                        DataCell(
                          _statusBadge(
                            item.claimsStatus,
                          ),
                        ),

                        DataCell(
                          _simpleBadge(
                            item.coverageId,
                            const Color(
                              0xFF7C3AED,
                            ),
                            const Color(
                              0xFFF5F3FF,
                            ),
                          ),
                        ),

                        DataCell(
                          SizedBox(
                            width: 190,
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  item.providerName,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                                const SizedBox(
                                  height:
                                      2,
                                ),
                                Text(
                                  item.providerCode,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        Color(
                                      0xFF94A3B8,
                                    ),
                                    fontSize:
                                        10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        DataCell(
                          SizedBox(
                            width: 90,
                            child: Text(
                              item.admissionDate,
                            ),
                          ),
                        ),

                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  item.primaryDiagnosis,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                                const SizedBox(
                                  height:
                                      2,
                                ),
                                Text(
                                  item.primaryDiagnosisDesc,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        Color(
                                      0xFF64748B,
                                    ),
                                    fontSize:
                                        10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            _formatRupiah(
                              item.incurredAmt,
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            _formatRupiah(
                              item.approvedAmt,
                            ),
                            style:
                                const TextStyle(
                              color: Color(
                                0xFF15803D,
                              ),
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ).toList(),
              ),
            ),
          ),
        ),

        if (_loadingClaims)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.55,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    18,
                  ),
                ),
                child:
                    const Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination(
    ClaimPage pageData,
  ) {
    final totalPages =
        pageData.totalPages < 1
            ? 1
            : pageData.totalPages;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child: Wrap(
        alignment:
            WrapAlignment
                .spaceBetween,
        crossAxisAlignment:
            WrapCrossAlignment
                .center,
        spacing: 14,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                'Rows per page',
                style: TextStyle(
                  color: Color(
                    0xFF64748B,
                  ),
                  fontSize: 11,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              DropdownButton<int>(
                value: _limit,
                underline:
                    const SizedBox
                        .shrink(),
                items:
                    const [
                  25,
                  50,
                  100,
                ].map(
                  (value) =>
                      DropdownMenuItem<
                          int>(
                    value: value,
                    child: Text(
                      '$value',
                    ),
                  ),
                ).toList(),
                onChanged:
                    _loadingClaims
                        ? null
                        : (value) async {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(() {
                              _limit =
                                  value;
                              _page =
                                  1;
                            });

                            await _loadClaims();
                          },
              ),
            ],
          ),

          Text(
            'Halaman $_page dari $totalPages',
            style:
                const TextStyle(
              color: Color(
                0xFF475569,
              ),
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed:
                    _loadingClaims ||
                            _page <= 1
                        ? null
                        : () async {
                            setState(() {
                              _page -=
                                  1;
                            });

                            await _loadClaims();
                          },
                icon: const Icon(
                  Icons
                      .chevron_left_rounded,
                  size: 18,
                ),
                label:
                    const Text(
                  'Previous',
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              FilledButton.icon(
                onPressed:
                    _loadingClaims ||
                            _page >=
                                totalPages
                        ? null
                        : () async {
                            setState(() {
                              _page +=
                                  1;
                            });

                            await _loadClaims();
                          },
                icon:
                    const Text(
                  'Next',
                ),
                label: const Icon(
                  Icons
                      .chevron_right_rounded,
                  size: 18,
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
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _statusBadge(
    String status,
  ) {
    final accent =
        _statusColor(
      status,
    );

    final soft =
        _statusSoftColor(
      status,
    );

    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius:
            BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color:
              accent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  Widget _simpleBadge(
    String text,
    Color accent,
    Color soft,
  ) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius:
            BorderRadius.circular(
          999,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // CLAIM DETAIL
  // ============================================================

  void _showClaimDetail(
    ClaimRecord item,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel:
          'Tutup detail klaim',
      barrierColor:
          Colors.black.withValues(
        alpha: 0.25,
      ),
      transitionDuration:
          const Duration(
        milliseconds: 240,
      ),
      pageBuilder: (
        context,
        animation,
        secondaryAnimation,
      ) {
        return SafeArea(
          child: Align(
            alignment:
                Alignment.centerRight,
            child: Material(
              color:
                  Colors.transparent,
              child: Container(
                width: 520,
                constraints:
                    const BoxConstraints(
                  maxWidth: 520,
                ),
                margin:
                    const EdgeInsets
                        .all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(
                    22,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .black
                          .withValues(
                        alpha: 0.12,
                      ),
                      blurRadius:
                          28,
                      offset:
                          const Offset(
                        -8,
                        0,
                      ),
                    ),
                  ],
                ),
                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets
                          .all(
                    24,
                  ),
                  child:
                      _claimDetailContent(
                    context,
                    item,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        final curved =
            CurvedAnimation(
          parent: animation,
          curve:
              Curves.easeOutCubic,
        );

        return SlideTransition(
          position:
              Tween<Offset>(
            begin:
                const Offset(
              0.08,
              0,
            ),
            end:
                Offset.zero,
          ).animate(
            curved,
          ),
          child:
              FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // CLAIM DETAIL CONTENT
  // ============================================================

  Widget _claimDetailContent(
    BuildContext dialogContext,
    ClaimRecord item,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFEFF6FF,
                ),
                borderRadius:
                    BorderRadius
                        .circular(
                  13,
                ),
              ),
              child: const Icon(
                Icons
                    .description_outlined,
                color: Color(
                  0xFF2563EB,
                ),
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
                  const Text(
                    'Claim Detail',
                    style:
                        TextStyle(
                      color: Color(
                        0xFF0F172A,
                      ),
                      fontSize:
                          19,
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    item.claimsId,
                    style:
                        const TextStyle(
                      color: Color(
                        0xFF64748B,
                      ),
                      fontSize:
                          12,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              tooltip: 'Tutup',
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

        const SizedBox(
          height: 18,
        ),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statusBadge(
              item.claimsStatus,
            ),

            _simpleBadge(
              item.coverageId,
              const Color(
                0xFF7C3AED,
              ),
              const Color(
                0xFFF5F3FF,
              ),
            ),

            _simpleBadge(
              item.claimType,
              const Color(
                0xFF0891B2,
              ),
              const Color(
                0xFFECFEFF,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 22,
        ),

        _detailSection(
          title:
              'Claim Information',
          children: [
            _detailRow(
              'CLAIMS_ID',
              item.claimsId,
            ),

            _detailRow(
              'Status',
              _statusLabel(
                item.claimsStatus,
              ),
            ),

            _detailRow(
              'Claim Type',
              item.claimType,
            ),

            _detailRow(
              'Coverage',
              item.coverageId,
            ),

            _detailRow(
              'Plan Code',
              item.planCode,
            ),

            _detailRow(
              'Admission Date',
              item.admissionDate,
            ),

            _detailRow(
              'Admission Type',
              item.admissionType,
            ),

            _detailRow(
              'Length of Stay',
              '${item.lengthOfStay} hari',
            ),
          ],
        ),

        const SizedBox(
          height: 16,
        ),

        _detailSection(
          title:
              'Corporation & Provider',
          children: [
            _detailRow(
              'Corp Code',
              item.corpCode,
            ),

            _detailRow(
              'Corporation',
              item.corpName,
            ),

            _detailRow(
              'Provider Code',
              item.providerCode,
            ),

            _detailRow(
              'Provider',
              item.providerName,
            ),
          ],
        ),

        const SizedBox(
          height: 16,
        ),

        _detailSection(
          title: 'Diagnosis',
          children: [
            _detailRow(
              'Primary Diagnosis',
              item.primaryDiagnosis,
            ),

            _detailRow(
              'Description',
              item.primaryDiagnosisDesc,
            ),
          ],
        ),

        const SizedBox(
          height: 16,
        ),

        _detailSection(
          title: 'Financial',
          children: [
            _detailRow(
              'Incurred Amount',
              _formatRupiah(
                item.incurredAmt,
              ),
            ),

            _detailRow(
              'Approved Amount',
              _formatRupiah(
                item.approvedAmt,
              ),
              valueColor:
                  const Color(
                0xFF15803D,
              ),
            ),

            _detailRow(
              'Not Approved',
              _formatRupiah(
                item.notApprovedAmt,
              ),
              valueColor:
                  const Color(
                0xFFDC2626,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL SECTION
  // ============================================================

  Widget _detailSection({
    required String title,
    required List<Widget>
        children,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF8FAFC,
        ),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: const Color(
            0xFFE2E8F0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              color: Color(
                0xFF0F172A,
              ),
              fontSize: 13,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style:
                  const TextStyle(
                color: Color(
                  0xFF64748B,
                ),
                fontSize: 11,
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ??
                    const Color(
                      0xFF0F172A,
                    ),
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}