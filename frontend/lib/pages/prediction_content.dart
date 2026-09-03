import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/prediction_data.dart';
import '../services/prediction_service.dart';


class PredictionContent
    extends StatefulWidget {
  const PredictionContent({
    super.key,
  });

  @override
  State<PredictionContent>
      createState() =>
          _PredictionContentState();
}


class _PredictionContentState
    extends State<PredictionContent> {

  final _formKey =
      GlobalKey<FormState>();

  final _incurredController =
      TextEditingController();

  final _lengthOfStayController =
      TextEditingController(
    text: '0',
  );


  PredictionFilters? filters;
  PredictionModelStatus? modelStatus;
  PredictionResult? result;
  GeminiClaimAnalysis? geminiAnalysis;


  bool initialLoading = true;
  bool predicting = false;
  bool analyzingWithGemini = false;

  String? errorMessage;
  String? geminiErrorMessage;

  int _requestId = 0;


  String? selectedCoverage;
  String? selectedPlanCode;
  String? selectedAdmissionType;
  String? selectedClaimType;
  String? selectedCorpCode;
  String? selectedProviderCode;
  String? selectedDiagnosis;


  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadInitialData();
  }


  @override
  void dispose() {
    _incurredController.dispose();
    _lengthOfStayController.dispose();

    super.dispose();
  }


  // ============================================================
  // LOAD INITIAL
  // ============================================================

  Future<void> _loadInitialData() async {
    setState(() {
      initialLoading = true;
      errorMessage = null;
    });

    try {
      final values =
          await Future.wait([
        PredictionService
            .getModelStatus(),

        PredictionService
            .getFilters(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        modelStatus =
            values[0]
                as PredictionModelStatus;

        filters =
            values[1]
                as PredictionFilters;

        // ========================================================
        // HIDDEN OPTIONAL INPUTS
        // ========================================================
        // Field berikut tidak ditampilkan di form untuk sementara.
        // Nilai UNKNOWN tetap dikirim ke backend agar endpoint
        // Prediction tetap menerima struktur input yang lengkap.
        // Kalau field nanti ditampilkan lagi, hapus // pada blok
        // widget di _buildPredictionForm() dan pilih nilainya.

        selectedPlanCode = 'UNKNOWN';
        selectedAdmissionType = 'UNKNOWN';
        selectedClaimType = 'UNKNOWN';
        selectedCorpCode = 'UNKNOWN';
        selectedProviderCode = 'UNKNOWN';
        selectedDiagnosis = 'UNKNOWN';

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
  // PREDICT
  // ============================================================

  Future<void> _predict() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (
        selectedCoverage == null ||
        selectedPlanCode == null ||
        selectedAdmissionType == null ||
        selectedClaimType == null ||
        selectedCorpCode == null ||
        selectedProviderCode == null ||
        selectedDiagnosis == null) {

      setState(() {
        errorMessage =
            'Data input Prediction belum siap. '
            'Silakan refresh halaman.';
      });

      return;
    }

    final incurred =
        _parseAmount(
      _incurredController.text,
    );

    final lengthOfStay =
        double.tryParse(
          _lengthOfStayController.text
              .trim(),
        ) ??
        0;

    final requestId = ++_requestId;
    final coverageId = selectedCoverage!;

    setState(() {
      predicting = true;
      analyzingWithGemini = false;
      errorMessage = null;
      geminiErrorMessage = null;
      result = null;
      geminiAnalysis = null;
    });

    try {
      final prediction =
          await PredictionService.predict(
        incurredAmount:
            incurred,
        lengthOfStay:
            lengthOfStay,
        coverageId:
            coverageId,
        planCode:
            selectedPlanCode!,
        admissionType:
            selectedAdmissionType!,
        claimType:
            selectedClaimType!,
        corpCode:
            selectedCorpCode!,
        providerCode:
            selectedProviderCode!,
        primaryDiagnosis:
            selectedDiagnosis!,
      );

      if (!mounted || requestId != _requestId) {
        return;
      }

      setState(() {
        result = prediction;
        predicting = false;
        analyzingWithGemini = true;
      });

      try {
        final analysis =
            await PredictionService
                .analyzeWithGemini(
          prediction: prediction,
          coverageId: coverageId,
          lengthOfStay: lengthOfStay,
        );

        if (!mounted || requestId != _requestId) {
          return;
        }

        setState(() {
          geminiAnalysis = analysis;
          analyzingWithGemini = false;
        });
      } catch (error) {
        if (!mounted || requestId != _requestId) {
          return;
        }

        setState(() {
          analyzingWithGemini = false;
          geminiErrorMessage = error.toString();
        });
      }
    } catch (error) {
      if (!mounted || requestId != _requestId) {
        return;
      }

      setState(() {
        predicting = false;
        analyzingWithGemini = false;
        errorMessage =
            error.toString();
      });
    }
  }


  // ============================================================
  // RESET
  // ============================================================

  void _reset() {
    _requestId++;

    _incurredController.clear();

    _lengthOfStayController.text =
        '0';

    setState(() {
      selectedCoverage = null;

      // Hidden field tetap memakai nilai default.
      selectedPlanCode = 'UNKNOWN';
      selectedAdmissionType = 'UNKNOWN';
      selectedClaimType = 'UNKNOWN';
      selectedCorpCode = 'UNKNOWN';
      selectedProviderCode = 'UNKNOWN';
      selectedDiagnosis = 'UNKNOWN';

      result = null;
      geminiAnalysis = null;
      errorMessage = null;
      geminiErrorMessage = null;
      predicting = false;
      analyzingWithGemini = false;
    });
  }


  // ============================================================
  // FORMAT
  // ============================================================

  double _parseAmount(
    String value,
  ) {
    final cleaned =
        value.replaceAll(
      RegExp(
        r'[^0-9]',
      ),
      '',
    );

    return double.tryParse(
          cleaned,
        ) ??
        0;
  }


  String _rupiah(
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


  String _percent(
    double value,
  ) {
    return '${NumberFormat(
      '0.00',
      'id_ID',
    ).format(value)}%';
  }


  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (initialLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }


    if (
        errorMessage != null &&
        filters == null) {

      return Center(
        child: Container(
          width: 520,
          margin:
              const EdgeInsets.all(
            28,
          ),
          padding:
              const EdgeInsets.all(
            28,
          ),
          decoration:
              _cardDecoration(),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
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
                'Prediction belum dapat dimuat',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 18,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                errorMessage!,
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
                  Icons.refresh_rounded,
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


    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(
        28,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // ==================================================
          // HEADER
          // ==================================================

          _buildHeader(),

          const SizedBox(
            height: 22,
          ),


          // ==================================================
          // FORM
          // ==================================================

          _buildPredictionForm(),


          if (errorMessage != null) ...[
            const SizedBox(
              height: 16,
            ),

            _buildErrorCard(),
          ],


          if (result != null) ...[
            const SizedBox(
              height: 26,
            ),

            _buildResultSection(
              result!,
            ),

            const SizedBox(
              height: 22,
            ),

            _buildGeminiSection(),
          ],


          const SizedBox(
            height: 40,
          ),
        ],
      ),
    );
  }


  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final status =
        modelStatus;

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.centerLeft,
          end:
              Alignment.centerRight,
          colors: [
            Color(
              0xFF1D4ED8,
            ),
            Color(
              0xFF4F46E5,
            ),
            Color(
              0xFF7C3AED,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prediction',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 28,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  'Estimate approved claim amount '
                  'using machine learning',
                  style:
                      TextStyle(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.82,
                    ),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _headerBadge(
                      Icons.hub_rounded,
                      status?.modelName ??
                          'Random Forest',
                    ),

                    _headerBadge(
                      Icons.verified_rounded,
                      status?.modelVersion ??
                          'v1',
                    ),

                    _headerBadge(
                      Icons.lock_outline_rounded,
                      'Auto Retrain OFF',
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
            width: 78,
            height: 78,
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.13,
              ),
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
            ),
            child:
                const Icon(
              Icons.auto_graph_rounded,
              color:
                  Colors.white,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }


  Widget _headerBadge(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white
                .withValues(
          alpha: 0.14,
        ),
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                Colors.white,
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            text,
            style:
                const TextStyle(
              color:
                  Colors.white,
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
  // FORM
  // ============================================================

  Widget _buildPredictionForm() {
    final data =
        filters!;

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration:
          _cardDecoration(),
      child: Form(
        key:
            _formKey,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _sectionIcon(
                  Icons.description_outlined,
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
                        'Claim Information',
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
                        'Masukkan karakteristik '
                        'klaim yang akan diprediksi',
                        style:
                            TextStyle(
                          fontSize: 11,
                          color:
                              Color(
                            0xFF94A3B8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 22,
            ),

            LayoutBuilder(
              builder:
                  (
                context,
                constraints,
              ) {
                final width =
                    constraints.maxWidth;

                final fieldWidth =
                    width < 720
                        ? width
                        : (
                            width - 16
                          ) /
                          2;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [

                    // ========================================
                    // INCURRED
                    // ========================================

                    SizedBox(
                      width:
                          fieldWidth,
                      child:
                          TextFormField(
                        controller:
                            _incurredController,
                        keyboardType:
                            TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],
                        decoration:
                            _inputDecoration(
                          label:
                              'Incurred Amount',
                          hint:
                              'Contoh: 5000000',
                          icon:
                              Icons.payments_outlined,
                          prefixText:
                              'Rp ',
                        ),
                        validator:
                            (value) {
                          final amount =
                              _parseAmount(
                            value ?? '',
                          );

                          if (amount <=
                              0) {
                            return 'Masukkan nilai incurred yang valid';
                          }

                          return null;
                        },
                      ),
                    ),


                    // ========================================
                    // LOS
                    // ========================================

                    SizedBox(
                      width:
                          fieldWidth,
                      child:
                          TextFormField(
                        controller:
                            _lengthOfStayController,
                        keyboardType:
                            TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],
                        decoration:
                            _inputDecoration(
                          label:
                              'Length of Stay',
                          hint:
                              'Jumlah hari',
                          icon:
                              Icons.hotel_outlined,
                          suffixText:
                              'Hari',
                        ),
                        validator:
                            (value) {
                          final parsed =
                              double.tryParse(
                            value ?? '',
                          );

                          if (
                              parsed == null ||
                              parsed < 0) {
                            return 'Length of stay tidak valid';
                          }

                          return null;
                        },
                      ),
                    ),


                    _stringDropdown(
                      width:
                          fieldWidth,
                      label:
                          'Coverage',
                      value:
                          selectedCoverage,
                      values:
                          data.coverages,
                      icon:
                          Icons.health_and_safety_outlined,
                      onChanged:
                          (value) {
                        setState(() {
                          selectedCoverage =
                              value;
                        });
                      },
                    ),


                    // ========================================================
                    // HIDDEN INPUTS - sementara tidak ditampilkan
                    // Hapus // pada widget yang ingin dimunculkan kembali.
                    // ========================================================

                    // _stringDropdown(
                      // width:
                          // fieldWidth,
                      // label:
                          // 'Claim Type',
                      // value:
                          // selectedClaimType,
                      // values:
                          // data.claimTypes,
                      // icon:
                          // Icons.category_outlined,
                      // onChanged:
                          // (value) {
                        // setState(() {
                          // selectedClaimType =
                              // value;
                        // });
                      // },
                    // ),
//
//
                    // _stringDropdown(
                      // width:
                          // fieldWidth,
                      // label:
                          // 'Admission Type',
                      // value:
                          // selectedAdmissionType,
                      // values:
                          // data.admissionTypes,
                      // icon:
                          // Icons.local_hospital_outlined,
                      // onChanged:
                          // (value) {
                        // setState(() {
                          // selectedAdmissionType =
                              // value;
                        // });
                      // },
                    // ),
//
//
                    // _stringDropdown(
                      // width:
                          // fieldWidth,
                      // label:
                          // 'Plan Code',
                      // value:
                          // selectedPlanCode,
                      // values:
                          // data.planCodes,
                      // icon:
                          // Icons.assignment_outlined,
                      // onChanged:
                          // (value) {
                        // setState(() {
                          // selectedPlanCode =
                              // value;
                        // });
                      // },
                    // ),
//
//
                    // _entityDropdown(
                      // width:
                          // fieldWidth,
                      // label:
                          // 'Corporation',
                      // value:
                          // selectedCorpCode,
                      // values:
                          // data.corporations,
                      // icon:
                          // Icons.business_outlined,
                      // onChanged:
                          // (value) {
                        // setState(() {
                          // selectedCorpCode =
                              // value;
                        // });
                      // },
                    // ),
//
//
                    // _entityDropdown(
                      // width:
                          // fieldWidth,
                      // label:
                          // 'Provider',
                      // value:
                          // selectedProviderCode,
                      // values:
                          // data.providers,
                      // icon:
                          // Icons.apartment_outlined,
                      // onChanged:
                          // (value) {
                        // setState(() {
                          // selectedProviderCode =
                              // value;
                        // });
                      // },
                    // ),
//
//
                    // _stringDropdown(
                      // width:
                          // fieldWidth,
                      // label:
                          // 'Primary Diagnosis',
                      // value:
                          // selectedDiagnosis,
                      // values:
                          // data.diagnoses,
                      // icon:
                          // Icons.medical_information_outlined,
                      // onChanged:
                          // (value) {
                        // setState(() {
                          // selectedDiagnosis =
                              // value;
                        // });
                      // },
                    // ),
                  ],
                );
              },
            ),

            const SizedBox(
              height: 22,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      FilledButton.icon(
                    onPressed:
                        predicting ||
                                analyzingWithGemini
                            ? null
                            : _predict,
                    icon:
                        predicting ||
                                analyzingWithGemini
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.auto_graph_rounded,
                              ),
                    label:
                        Text(
                      predicting
                          ? 'Predicting...'
                          : analyzingWithGemini
                              ? 'Analyzing...'
                              : 'Predict Claim',
                    ),
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF2563EB,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                OutlinedButton.icon(
                  onPressed:
                      predicting ||
                              analyzingWithGemini
                          ? null
                          : _reset,
                  icon:
                      const Icon(
                    Icons.restart_alt_rounded,
                  ),
                  label:
                      const Text(
                    'Reset',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // RESULT
  // ============================================================

  Widget _buildResultSection(
    PredictionResult data,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Prediction Result',
          style:
              TextStyle(
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
          height: 4,
        ),

        const Text(
          'Estimasi nilai approved berdasarkan Random Forest',
          style:
              TextStyle(
            color:
                Color(
              0xFF94A3B8,
            ),
            fontSize: 11,
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        LayoutBuilder(
          builder:
              (
            context,
            constraints,
          ) {
            final width =
                constraints.maxWidth;

            final cardWidth =
                width < 760
                    ? width
                    : (
                        width - 32
                      ) /
                      3;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _metricCard(
                  width:
                      cardWidth,
                  icon:
                      Icons.receipt_long_outlined,
                  title:
                      'Incurred Amount',
                  value:
                      _rupiah(
                    data.incurredAmount,
                  ),
                  subtitle:
                      'Nilai klaim diajukan',
                  accent:
                      const Color(
                    0xFFF59E0B,
                  ),
                ),

                _metricCard(
                  width:
                      cardWidth,
                  icon:
                      Icons.verified_outlined,
                  title:
                      'Predicted Approved',
                  value:
                      _rupiah(
                    data.predictedApprovedAmount,
                  ),
                  subtitle:
                      'Hasil Random Forest',
                  accent:
                      const Color(
                    0xFF16A34A,
                  ),
                ),

                _metricCard(
                  width:
                      cardWidth,
                  icon:
                      Icons.remove_circle_outline_rounded,
                  title:
                      'Estimated Difference',
                  value:
                      _rupiah(
                    data.estimatedDifference,
                  ),
                  subtitle:
                      'Estimasi tidak approved',
                  accent:
                      const Color(
                    0xFFDC2626,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(
          height: 16,
        ),

        _approvalRatioCard(
          data,
        ),
      ],
    );
  }


  Widget _approvalRatioCard(
    PredictionResult data,
  ) {
    final progress =
        (
          data.approvalRatio /
          100
        ).clamp(
          0.0,
          1.0,
        );

    return Container(
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
              const Expanded(
                child: Text(
                  'Predicted Approval Ratio',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(
                      0xFF334155,
                    ),
                  ),
                ),
              ),

              Text(
                _percent(
                  data.approvalRatio,
                ),
                style:
                    const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(
                    0xFF16A34A,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            child:
                LinearProgressIndicator(
              value:
                  progress,
              minHeight: 10,
              backgroundColor:
                  const Color(
                0xFFE2E8F0,
              ),
              color:
                  const Color(
                0xFF16A34A,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GEMINI AI ANALYSIS
  // ============================================================

  Widget _buildGeminiSection() {
    if (analyzingWithGemini) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: _geminiCardDecoration(),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF7C3AED),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generating AI Analysis...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Gemini sedang menganalisis hasil Random Forest.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (geminiErrorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFDE68A),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gemini AI Analysis belum tersedia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    geminiErrorMessage!,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hasil prediksi Random Forest tetap valid dan dapat digunakan.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final data = geminiAnalysis;

    if (data == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _geminiCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF7C3AED),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gemini AI Analysis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Analisis hasil Random Forest • ${data.model}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: Color(0xFF16A34A),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'AI Generated',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE0E7FF),
              ),
            ),
            child: SelectableText(
              data.analysis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.65,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Analisis AI merupakan penjelasan tambahan dan bukan keputusan final approval atau reject.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  BoxDecoration _geminiCardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF8FAFF),
          Color(0xFFF5F3FF),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFFC7D2FE),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A4F46E5),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  // ============================================================
  // GENERIC UI
  // ============================================================

  Widget _metricCard({
    required double width,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      width: width,
      padding:
          const EdgeInsets.all(
        18,
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
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color:
                      accent.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  size: 18,
                  color: accent,
                ),
              ),

              const Spacer(),

              Container(
                width: 7,
                height: 7,
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
            height: 15,
          ),

          Text(
            title,
            style:
                const TextStyle(
              fontSize: 11,
              color:
                  Color(
                0xFF64748B,
              ),
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(
                0xFF0F172A,
              ),
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            subtitle,
            style:
                const TextStyle(
              fontSize: 9,
              color:
                  Color(
                0xFF94A3B8,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _stringDropdown({
    required double width,
    required String label,
    required String? value,
    required List<String> values,
    required IconData icon,
    required ValueChanged<String?>
        onChanged,
  }) {
    return SizedBox(
      width: width,
      child:
          DropdownButtonFormField<String>(
        initialValue:
            values.contains(value)
                ? value
                : null,
        isExpanded: true,
        decoration:
            _inputDecoration(
          label:
              label,
          icon:
              icon,
        ),
        items:
            values
                .map(
                  (item) =>
                      DropdownMenuItem<String>(
                    value: item,
                    child:
                        Text(
                      item,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        onChanged:
            onChanged,
        validator:
            (current) {
          if (current == null) {
            return 'Pilih $label';
          }

          return null;
        },
      ),
    );
  }


  // Dipertahankan karena akan dipakai lagi jika Corporation/Provider
  // ditampilkan kembali.
  // ignore: unused_element
  Widget _entityDropdown({
    required double width,
    required String label,
    required String? value,
    required List<PredictionEntityOption>
        values,
    required IconData icon,
    required ValueChanged<String?>
        onChanged,
  }) {
    final valid =
        values.any(
      (item) =>
          item.code == value,
    );

    return SizedBox(
      width: width,
      child:
          DropdownButtonFormField<String>(
        initialValue:
            valid
                ? value
                : null,
        isExpanded: true,
        decoration:
            _inputDecoration(
          label:
              label,
          icon:
              icon,
        ),
        items:
            values
                .map(
                  (item) =>
                      DropdownMenuItem<String>(
                    value:
                        item.code,
                    child:
                        Text(
                      item.displayLabel,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        onChanged:
            onChanged,
        validator:
            (current) {
          if (current == null) {
            return 'Pilih $label';
          }

          return null;
        },
      ),
    );
  }


  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText:
          label,
      hintText:
          hint,
      prefixIcon:
          Icon(
        icon,
        size: 19,
      ),
      prefixText:
          prefixText,
      suffixText:
          suffixText,
      filled: true,
      fillColor:
          const Color(
        0xFFF8FAFC,
      ),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
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
    );
  }


  Widget _sectionIcon(
    IconData icon,
  ) {
    return Container(
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
          Icon(
        icon,
        color:
            const Color(
          0xFF2563EB,
        ),
        size: 20,
      ),
    );
  }


  Widget _buildErrorCard() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFFEF2F2,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFFECACA,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color:
                Color(
              0xFFDC2626,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child:
                Text(
              errorMessage!,
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


  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color:
          Colors.white,
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      border:
          Border.all(
        color:
            const Color(
          0xFFE2E8F0,
        ),
      ),
      boxShadow: const [
        BoxShadow(
          color:
              Color(
            0x080F172A,
          ),
          blurRadius: 18,
          offset:
              Offset(
            0,
            6,
          ),
        ),
      ],
    );
  }
}
