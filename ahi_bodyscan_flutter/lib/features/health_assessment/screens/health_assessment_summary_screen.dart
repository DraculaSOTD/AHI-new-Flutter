import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/lambda_service.dart';
import '../../../services/profile_service.dart';
import '../services/health_assessment_orchestrator.dart';
import '../models/health_assessment.dart';

/// Health Assessment Summary Screen
///
/// Displays comprehensive results from the complete health assessment:
/// - Overall health risk stratification
/// - Mental health scores (GAD-7, PHQ-9) with severity levels
/// - Fitness test results and cardio fitness level
/// - Averaged vital signs from 3 face scans
/// - Body scan results (if completed)
/// - Personalized recommendations
class HealthAssessmentSummaryScreen extends StatefulWidget {
  /// When non-null the screen renders a previously-saved assessment in
  /// read-only "history" mode: it does not read the live orchestrator,
  /// re-submit to Lambda, mutate assessment steps on back, or show the
  /// complete/save actions. Used when opening a report from Reports history.
  final HealthAssessment? historyAssessment;

  const HealthAssessmentSummaryScreen({super.key, this.historyAssessment});

  @override
  State<HealthAssessmentSummaryScreen> createState() =>
      _HealthAssessmentSummaryScreenState();
}

class _HealthAssessmentSummaryScreenState
    extends State<HealthAssessmentSummaryScreen> {
  bool _lambdaInFlight = false;
  bool _lambdaTried = false;

  /// True when viewing a saved assessment from Reports history.
  bool get _isHistory => widget.historyAssessment != null;

  @override
  void initState() {
    super.initState();
    // History mode renders a finished, persisted assessment — nothing to submit.
    if (_isHistory) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _submitLambdaIfNeeded();
    });
  }

  /// One-shot Lambda submission at the very end of the assessment. Combines
  /// the averaged face-scan vitals with the profile demographics and submits
  /// to the existing `/bha/` endpoint. Cached on the orchestrator so re-entry
  /// to the summary doesn't trigger a second call.
  Future<void> _submitLambdaIfNeeded() async {
    if (_lambdaTried || _lambdaInFlight) return;
    final orchestrator = context.read<HealthAssessmentOrchestrator>();
    final assessment = orchestrator.currentAssessment;
    if (assessment == null) return;
    if (assessment.lambdaResult != null) return; // already submitted earlier

    setState(() {
      _lambdaInFlight = true;
      _lambdaTried = true;
    });

    try {
      final scanResults = _averagedScanResults(assessment);
      final userData = _buildUserData(assessment);
      LoggingService.info(
          'Submitting end-of-assessment payload to Lambda',
          tag: 'AssessmentSummary');
      final result = await LambdaService.submitForHealthAssessment(
        scanResults: scanResults,
        userData: userData,
      );
      await orchestrator
          .updateAssessment((a) => a.copyWith(lambdaResult: result));
    } catch (e, st) {
      LoggingService.error('Lambda submission failed',
          error: e, stackTrace: st, tag: 'AssessmentSummary');
      // Cache a fromScanOnly fallback so we don't keep retrying.
      final fallback = HealthAssessmentResult.fromScanOnly(
          _averagedScanResults(assessment));
      await orchestrator
          .updateAssessment((a) => a.copyWith(lambdaResult: fallback));
    } finally {
      if (mounted) setState(() => _lambdaInFlight = false);
    }
  }

  /// Field-wise average across all face-scan measurements. Null fields are
  /// skipped so a missing reading on one scan doesn't poison the average.
  Map<String, dynamic> _averagedScanResults(HealthAssessment a) {
    final measurements = a.vitalSigns?.measurements ?? const [];
    num? avg(num? Function(dynamic m) pick) {
      final values = measurements.map(pick).whereType<num>().toList();
      if (values.isEmpty) return null;
      final sum = values.fold<num>(0, (s, v) => s + v);
      return sum / values.length;
    }
    final bpm = avg((m) => m.heartRate as num?);
    final rr = avg((m) => m.respiratoryRate as num?);
    final spo2 = avg((m) => m.oxygenSaturation as num?);
    final sys = avg((m) => m.systolicBP as num?);
    final dia = avg((m) => m.diastolicBP as num?);
    final hrv = avg((m) => m.heartRateVariability as num?);

    // Most-common stress label across the three; last wins on tie.
    final stressLabels = measurements
        .map((m) => m.stressLevel?.toString())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    String? stressLabel;
    if (stressLabels.isNotEmpty) {
      final counts = <String, int>{};
      for (final s in stressLabels) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
      stressLabel = counts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    final scanResults = <String, dynamic>{
      'heartRate': bpm?.round() ?? 0,
      'respiratoryRate': rr?.round() ?? 0,
      'oxygenSaturation': spo2?.round() ?? 0,
      'systolicBP': sys?.round() ?? 0,
      'diastolicBP': dia?.round() ?? 0,
      'heartRateVariability': hrv?.round() ?? 0,
      'stressLevel': stressLabel ?? 'Unknown',
      'stressStatus': stressLabel ?? '',
    };

    // Tack on body-scan measurements when the user completed that step.
    final body = a.bodyScanResult;
    if (body != null) {
      scanResults['chestCircumference'] = body.chestInCm;
      scanResults['waistCircumference'] = body.waistInCm;
      scanResults['hipCircumference'] = body.hipsInCm;
      scanResults['thighCircumference'] = body.thighInCm;
      scanResults['inseam'] = body.inseamInCm;
      scanResults['bodyFatPercent'] = body.bodyfatInPercent;
      scanResults['weightPredictionKg'] = body.weightPredictInKg;
    }

    // Tack on step-test results when the user completed the fitness test.
    final fitness = a.fitnessTest;
    if (fitness != null) {
      scanResults['restingHeartRate'] = fitness.restingHeartRate;
      scanResults['postExerciseHeartRate'] = fitness.postExerciseHeartRate;
    }

    // Full post-exercise (step-test cool-down) face scan vitals — the user
    // wants these treated as step-test results in the Lambda payload, not
    // averaged into the resting baseline.
    final post = a.postExerciseFaceScan;
    if (post != null) {
      scanResults['postExerciseHeartRate'] = post.heartRate ?? 0;
      scanResults['postExerciseRespiratoryRate'] = post.respiratoryRate ?? 0;
      scanResults['postExerciseOxygenSaturation'] =
          post.oxygenSaturation ?? 0;
      scanResults['postExerciseSystolicBP'] = post.systolicBP ?? 0;
      scanResults['postExerciseDiastolicBP'] = post.diastolicBP ?? 0;
      scanResults['postExerciseHeartRateVariability'] =
          post.heartRateVariability ?? 0;
      scanResults['postExerciseStressLevel'] =
          post.stressLevel ?? 'Unknown';
      scanResults['postExerciseStressStatus'] = post.stressLevel ?? '';
    }

    return scanResults;
  }

  Map<String, dynamic> _buildUserData(HealthAssessment a) {
    final profile = ProfileService().selectedProfile;
    return {
      'age': profile?.age ?? 30,
      'gender': profile?.gender.toLowerCase() ?? 'male',
      'height': profile?.heightInCm ?? 170,
      'weight': profile?.weightInKg ?? 70,
    };
  }

  @override
  Widget build(BuildContext context) {
    // In history mode we render the passed-in saved assessment and never touch
    // the live orchestrator. In the live flow we watch the orchestrator.
    final orchestrator =
        _isHistory ? null : context.watch<HealthAssessmentOrchestrator>();
    final assessment = widget.historyAssessment ?? orchestrator?.currentAssessment;

    if (assessment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment Summary')),
        body: const Center(
          child: Text('No assessment data available'),
        ),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && orchestrator != null) {
          // User went back - clear summary and allow re-review
          await orchestrator.clearStepsAfter(AssessmentStep.bodyScan);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Health Assessment Summary'),
          elevation: 0,
          backgroundColor: Colors.white,
        ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          // Android 15+ edge-to-edge zeros out MediaQuery.padding inside the
          // tab shell, so the Scaffold body can flow under the system nav.
          // Go direct to the FlutterView for the true inset (mirrors
          // profile_editor_screen.dart).
          padding: EdgeInsets.fromLTRB(
            AppDimensions.paddingLarge,
            AppDimensions.paddingLarge,
            AppDimensions.paddingLarge,
            AppDimensions.paddingLarge +
                MediaQueryData.fromView(View.of(context))
                    .viewPadding
                    .bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall risk level card
              _buildOverallRiskCard(context, assessment),
              const SizedBox(height: AppDimensions.spacingLarge),

              // Duration and completion info
              _buildCompletionInfoCard(context, assessment),
              const SizedBox(height: AppDimensions.spacingLarge),

              // Mental Health Section
              if (assessment.anxietySurvey != null ||
                  assessment.depressionSurvey != null) ...[
                _buildSectionHeader('Mental Health Assessment'),
                const SizedBox(height: AppDimensions.spacingMedium),
                if (assessment.anxietySurvey != null)
                  _buildAnxietyCard(context, assessment),
                if (assessment.depressionSurvey != null) ...[
                  const SizedBox(height: AppDimensions.spacingMedium),
                  _buildDepressionCard(context, assessment),
                ],
                const SizedBox(height: AppDimensions.spacingLarge),
              ],

              // Fitness Section
              if (assessment.fitnessTest != null) ...[
                _buildSectionHeader('Physical Fitness'),
                const SizedBox(height: AppDimensions.spacingMedium),
                _buildFitnessCard(context, assessment),
                const SizedBox(height: AppDimensions.spacingLarge),
              ],

              // Individual Face Scans Section
              if (assessment.vitalSigns != null && assessment.vitalSigns!.measurements.isNotEmpty) ...[
                _buildSectionHeader('Face Scan Results'),
                const SizedBox(height: AppDimensions.spacingMedium),
                ...List.generate(
                  assessment.vitalSigns!.measurements.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
                    child: _buildIndividualFaceScanCard(
                      context,
                      assessment.vitalSigns!.measurements[index],
                      index + 1,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLarge),
              ],

              // Vital Signs Section
              if (assessment.vitalSigns != null) ...[
                _buildSectionHeader('Vital Signs (3-Scan Average)'),
                const SizedBox(height: AppDimensions.spacingMedium),
                _buildVitalSignsCard(context, assessment),
                const SizedBox(height: AppDimensions.spacingLarge),
              ],

              // Body Scan Section
              if (assessment.bodyScanResult != null) ...[
                _buildSectionHeader('Body Composition'),
                const SizedBox(height: AppDimensions.spacingMedium),
                _buildBodyScanCard(context, assessment),
                const SizedBox(height: AppDimensions.spacingLarge),
              ],

              // Recommendations
              _buildSectionHeader('Recommendations'),
              const SizedBox(height: AppDimensions.spacingMedium),
              _buildRecommendationsCard(context, assessment),
              const SizedBox(height: AppDimensions.spacingXLarge),

              // Live-flow actions only. History mode is read-only — these
              // mutate orchestrator state, so they're hidden when reviewing a
              // saved report.
              if (orchestrator != null) ...[
                // Complete Assessment Button
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: () => _completeAssessment(context, orchestrator),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete Assessment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _saveForLater(context, orchestrator),
                    icon: const Icon(Icons.bookmark),
                    label: const Text('Save and Return Later'),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                  ),
                ),
            ],
          ),
        ),
      ),
    ), // PopScope child
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.headlineMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryPurple,
      ),
    );
  }

  Widget _buildOverallRiskCard(BuildContext context, HealthAssessment assessment) {
    final riskLevel = assessment.overallRiskLevel;
    final Color riskColor;
    final IconData riskIcon;
    final String riskTitle;
    final String riskDescription;

    switch (riskLevel) {
      case 'critical':
        riskColor = AppColors.error;
        riskIcon = Icons.warning;
        riskTitle = 'Critical';
        riskDescription = 'Immediate medical attention recommended';
        break;
      case 'high':
        riskColor = AppColors.error;
        riskIcon = Icons.error_outline;
        riskTitle = 'High Risk';
        riskDescription = 'Please consult with a healthcare provider';
        break;
      case 'moderate':
        riskColor = AppColors.warning;
        riskIcon = Icons.info_outline;
        riskTitle = 'Moderate Risk';
        riskDescription = 'Consider lifestyle modifications';
        break;
      case 'low':
      default:
        riskColor = AppColors.success;
        riskIcon = Icons.check_circle_outline;
        riskTitle = 'Low Risk';
        riskDescription = 'Continue maintaining healthy habits';
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [riskColor.withValues(alpha: 0.1), riskColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: riskColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(riskIcon, color: riskColor, size: 32),
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Health Risk',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  riskTitle,
                  style: AppTypography.headlineLarge.copyWith(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  riskDescription,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionInfoCard(BuildContext context, HealthAssessment assessment) {
    final duration = DateTime.now().difference(assessment.startedAt);
    final minutes = duration.inMinutes;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [AppShadows.small],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            Icons.timer,
            'Duration',
            '$minutes min',
            AppColors.info,
          ),
          Container(width: 1, height: 40, color: AppColors.borderLight),
          _buildInfoItem(
            Icons.calendar_today,
            'Date',
            _formatDate(assessment.startedAt),
            AppColors.primaryPurple,
          ),
          Container(width: 1, height: 40, color: AppColors.borderLight),
          _buildInfoItem(
            Icons.assignment_turned_in,
            'Status',
            'Complete',
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAnxietyCard(BuildContext context, HealthAssessment assessment) {
    final anxiety = assessment.anxietySurvey!;
    final score = anxiety.totalScore;
    final severity = anxiety.severityLevel;

    return _buildScoreCard(
      title: 'Anxiety (GAD-7)',
      score: score,
      maxScore: 21,
      severity: severity,
      icon: Icons.psychology,
      severityDescriptions: {
        'minimal': 'Minimal anxiety symptoms',
        'mild': 'Mild anxiety - monitor symptoms',
        'moderate': 'Moderate anxiety - consider support',
        'severe': 'Severe anxiety - seek professional help',
      },
    );
  }

  Widget _buildDepressionCard(BuildContext context, HealthAssessment assessment) {
    final depression = assessment.depressionSurvey!;
    final score = depression.totalScore;
    final severity = depression.severityLevel;
    final hasSelfHarm = depression.hasSelfHarmThoughts;

    return _buildScoreCard(
      title: 'Depression (PHQ-9)',
      score: score,
      maxScore: 27,
      severity: severity,
      icon: Icons.favorite,
      severityDescriptions: {
        'minimal': 'Minimal depression symptoms',
        'mild': 'Mild depression - monitor symptoms',
        'moderate': 'Moderate depression - consider support',
        'moderately_severe': 'Moderately severe - seek professional help',
        'severe': 'Severe depression - immediate help needed',
      },
      criticalWarning: hasSelfHarm
          ? 'Self-harm thoughts detected - please seek immediate support'
          : null,
    );
  }

  Widget _buildScoreCard({
    required String title,
    required int score,
    required int maxScore,
    required String severity,
    required IconData icon,
    required Map<String, String> severityDescriptions,
    String? criticalWarning,
  }) {
    final Color severityColor = _getSeverityColor(severity);
    final String description = severityDescriptions[severity] ?? '';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [AppShadows.small],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryPurple, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$score / $maxScore',
                      style: AppTypography.displaySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (criticalWarning != null) ...[
            const SizedBox(height: AppDimensions.spacingMedium),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      criticalWarning,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFitnessCard(BuildContext context, HealthAssessment assessment) {
    final fitness = assessment.fitnessTest!;
    final isSafe = fitness.isSafeForExercise;
    final fitnessLevel = fitness.fitnessLevel ?? 'unknown';
    final restingHR = fitness.restingHeartRate;
    final postExHR = fitness.postExerciseHeartRate;
    final recovery = (restingHR != null && postExHR != null)
        ? postExHR - restingHR
        : null;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [AppShadows.small],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: AppColors.primaryPurple, size: 24),
              const SizedBox(width: 8),
              Text(
                'Fitness Assessment',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildFitnessMetric(
                  'Safety Status',
                  isSafe ? 'Safe' : 'Caution',
                  isSafe ? AppColors.success : AppColors.warning,
                  isSafe ? Icons.check_circle : Icons.warning,
                ),
              ),
              Expanded(
                child: _buildFitnessMetric(
                  'Fitness Level',
                  _formatFitnessLevel(fitnessLevel),
                  _getFitnessLevelColor(fitnessLevel),
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          if (restingHR != null && postExHR != null) ...[
            const SizedBox(height: AppDimensions.spacingMedium),
            const Divider(),
            const SizedBox(height: AppDimensions.spacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHRMetric('Resting HR', '$restingHR BPM'),
                _buildHRMetric('Post-Exercise', '$postExHR BPM'),
                if (recovery != null)
                  _buildHRMetric('Recovery', '+$recovery BPM'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFitnessMetric(String label, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.bodyLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHRMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalSignsCard(BuildContext context, HealthAssessment assessment) {
    final vitals = assessment.vitalSigns!;
    final scanCount = vitals.measurements.length;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [AppShadows.small],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                'Vital Signs Summary',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Averaged from $scanCount consecutive scans',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          _buildVitalsGrid(vitals),
        ],
      ),
    );
  }

  Widget _buildVitalsGrid(VitalSignsResults vitals) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildVitalItem(
                'Heart Rate',
                vitals.averageHeartRate?.toStringAsFixed(0) ?? '--',
                'BPM',
                Icons.favorite,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVitalItem(
                'Blood Pressure',
                vitals.averageSystolicBP != null && vitals.averageDiastolicBP != null
                    ? '${vitals.averageSystolicBP!.toStringAsFixed(0)}/${vitals.averageDiastolicBP!.toStringAsFixed(0)}'
                    : '--',
                'mmHg',
                Icons.monitor_heart,
                AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildVitalItem(
                'Respiratory',
                vitals.averageRespiratoryRate?.toStringAsFixed(0) ?? '--',
                'br/min',
                Icons.air,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVitalItem(
                'SpO2',
                vitals.averageOxygenSaturation?.toStringAsFixed(0) ?? '--',
                '%',
                Icons.water_drop,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildVitalItem(
                'HRV',
                vitals.averageHRV?.toStringAsFixed(1) ?? '--',
                'ms',
                Icons.graphic_eq,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVitalItem(
                'Stress Level',
                vitals.mostCommonStressLevel ?? '--',
                '',
                Icons.psychology,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualFaceScanCard(
    BuildContext context,
    FaceScanMeasurement measurement,
    int scanNumber,
  ) {
    final timestamp = measurement.timestamp;
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [AppShadows.small],
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.face,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Face Scan $scanNumber',
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Recorded at $timeStr',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          // Compact vital signs grid for individual scan
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCompactVitalItem(
                      'HR',
                      measurement.heartRate?.toString() ?? '--',
                      'BPM',
                      Icons.favorite,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactVitalItem(
                      'BP',
                      measurement.systolicBP != null && measurement.diastolicBP != null
                          ? '${measurement.systolicBP}/${measurement.diastolicBP}'
                          : '--',
                      'mmHg',
                      Icons.monitor_heart,
                      AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactVitalItem(
                      'SpO2',
                      measurement.oxygenSaturation?.toString() ?? '--',
                      '%',
                      Icons.water_drop,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactVitalItem(
                      'Resp',
                      measurement.respiratoryRate?.toString() ?? '--',
                      'br/min',
                      Icons.air,
                      AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactVitalItem(
                      'HRV',
                      measurement.heartRateVariability?.toStringAsFixed(1) ?? '--',
                      'ms',
                      Icons.graphic_eq,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactVitalItem(
                      'Stress',
                      measurement.stressLevel ?? '--',
                      '',
                      Icons.psychology,
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVitalItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            unit,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyScanCard(BuildContext context, HealthAssessment assessment) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [AppShadows.small],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.accessibility_new, color: AppColors.primaryPurple, size: 24),
              const SizedBox(width: 8),
              Text(
                'Body Composition Scan',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Scan completed successfully',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          const Divider(),
          const SizedBox(height: AppDimensions.spacingMedium),

          // Body measurements grid
          Text(
            'Circumferences',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildBodyMeasurement(
                  'Chest',
                  assessment.bodyScanResult?.chestInCm != null
                    ? '${assessment.bodyScanResult!.chestInCm!.toInt()}'
                    : '--',
                  'cm',
                  Icons.straighten,
                  AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBodyMeasurement(
                  'Waist',
                  assessment.bodyScanResult?.waistInCm != null
                    ? '${assessment.bodyScanResult!.waistInCm!.toInt()}'
                    : '--',
                  'cm',
                  Icons.straighten,
                  AppColors.secondaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildBodyMeasurement(
                  'Hips',
                  assessment.bodyScanResult?.hipsInCm != null
                    ? '${assessment.bodyScanResult!.hipsInCm!.toInt()}'
                    : '--',
                  'cm',
                  Icons.straighten,
                  AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBodyMeasurement(
                  'Thigh',
                  assessment.bodyScanResult?.thighInCm != null
                    ? '${assessment.bodyScanResult!.thighInCm!.toInt()}'
                    : '--',
                  'cm',
                  Icons.straighten,
                  AppColors.secondaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),

          // Body composition
          Text(
            'Body Composition',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildBodyMeasurement(
                  'Body Fat',
                  assessment.bodyScanResult?.bodyfatInPercent != null
                    ? assessment.bodyScanResult!.bodyfatInPercent!.toStringAsFixed(1)
                    : '--',
                  '%',
                  Icons.pie_chart,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBodyMeasurement(
                  'Muscle Mass',
                  assessment.bodyScanResult?.muscleMassInKg != null
                    ? assessment.bodyScanResult!.muscleMassInKg!.toStringAsFixed(1)
                    : '--',
                  'kg',
                  Icons.fitness_center,
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),

          // View detailed results button
          OutlinedButton.icon(
            onPressed: () {
              // Navigate to detailed body scan results
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('View detailed results in Reports section'),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('View Detailed Results'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryPurple),
              foregroundColor: AppColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMeasurement(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context, HealthAssessment assessment) {
    final recommendations = _getRecommendations(assessment);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.05),
            AppColors.info.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.primaryPurple, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Personalized Recommendations',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right,
                      color: AppColors.primaryPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<String> _getRecommendations(HealthAssessment assessment) {
    final recommendations = <String>[];

    // Mental health recommendations
    if (assessment.anxietySurvey != null) {
      final anxietyScore = assessment.anxietySurvey!.totalScore;
      if (anxietyScore >= 15) {
        recommendations.add(
          'Consider consulting with a mental health professional about anxiety symptoms',
        );
      } else if (anxietyScore >= 10) {
        recommendations.add('Practice stress-reduction techniques like meditation or deep breathing');
      }
    }

    if (assessment.depressionSurvey != null) {
      if (assessment.depressionSurvey!.hasSelfHarmThoughts) {
        recommendations.add(
          'URGENT: Contact a crisis hotline or mental health professional immediately',
        );
      } else if (assessment.depressionSurvey!.totalScore >= 10) {
        recommendations.add(
          'Consider speaking with a healthcare provider about depression symptoms',
        );
      }
    }

    // Fitness recommendations
    if (assessment.fitnessTest != null) {
      final fitness = assessment.fitnessTest!;
      if (!fitness.isSafeForExercise) {
        recommendations.add(
          'Consult with a physician before starting a new exercise program',
        );
      }
      if (fitness.fitnessLevel == 'poor' || fitness.fitnessLevel == 'below_average') {
        recommendations.add(
          'Gradually increase physical activity with low-impact exercises like walking',
        );
      }
    }

    // Vital signs recommendations
    if (assessment.vitalSigns != null) {
      final vitals = assessment.vitalSigns!;
      if (vitals.averageSystolicBP != null && vitals.averageSystolicBP! > 140) {
        recommendations.add(
          'Elevated blood pressure detected - monitor and discuss with healthcare provider',
        );
      }
      if (vitals.mostCommonStressLevel == 'High') {
        recommendations.add('Stress levels are elevated - consider relaxation techniques');
      }
    }

    // General recommendations
    if (recommendations.isEmpty) {
      recommendations.addAll([
        'Continue maintaining a healthy lifestyle with regular exercise',
        'Ensure adequate sleep (7-9 hours per night)',
        'Maintain a balanced diet rich in fruits and vegetables',
        'Stay hydrated throughout the day',
      ]);
    } else {
      recommendations.add('Maintain a balanced diet and regular sleep schedule');
      recommendations.add('Consider scheduling a check-up with your healthcare provider');
    }

    return recommendations;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'minimal':
        return AppColors.success;
      case 'mild':
        return AppColors.info;
      case 'moderate':
        return AppColors.warning;
      case 'moderately_severe':
      case 'severe':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getFitnessLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'excellent':
      case 'superior':
        return AppColors.success;
      case 'good':
      case 'above_average':
        return AppColors.info;
      case 'average':
        return AppColors.warning;
      case 'below_average':
      case 'poor':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatFitnessLevel(String level) {
    return level
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _completeAssessment(
    BuildContext context,
    HealthAssessmentOrchestrator orchestrator,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Assessment?'),
        content: const Text(
          'Your assessment results will be saved to your profile. You can view them anytime in your Reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    // Capture stable references before awaiting — orchestrator.completeAssessment
    // calls notifyListeners() which rebuilds this screen with assessment=null
    // (the empty-state Scaffold) and silently drops any context.go fired
    // afterwards. The captured router + messenger survive the rebuild.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await orchestrator.completeAssessment();

    router.go('/home');
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Health assessment completed successfully!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveForLater(
    BuildContext context,
    HealthAssessmentOrchestrator orchestrator,
  ) async {
    // Assessment is already saved automatically, just navigate away. Use the
    // captured router/messenger pattern in case orchestrator state changes
    // in flight.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    router.go('/home');
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Assessment saved - you can continue later'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}
