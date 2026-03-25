import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/fitness_test_result.dart';
import '../widgets/survey_question_widget.dart';
import '../services/health_assessment_orchestrator.dart';

/// PAR-Q (Physical Activity Readiness Questionnaire) Fitness Screening
///
/// 7 safety questions to determine if it's safe to proceed with the step test.
/// Any "Yes" answer means the user should consult a doctor before exercising.
/// Can be used standalone or as part of the health assessment flow.
class FitnessScreeningQuestionnaireScreen extends StatefulWidget {
  final Function(FitnessTestResult)? onComplete;
  final VoidCallback? onUnsafeForExercise;

  const FitnessScreeningQuestionnaireScreen({
    super.key,
    this.onComplete,
    this.onUnsafeForExercise,
  });

  @override
  State<FitnessScreeningQuestionnaireScreen> createState() =>
      _FitnessScreeningQuestionnaireScreenState();
}

class _FitnessScreeningQuestionnaireScreenState
    extends State<FitnessScreeningQuestionnaireScreen> {
  final _scrollController = ScrollController();

  // Question answers (null = not answered, true = Yes, false = No)
  bool? _q1Answer; // Heart condition
  bool? _q2Answer; // Chest pain during activity
  bool? _q3Answer; // Chest pain when inactive
  bool? _q4Answer; // Dizziness or loss of consciousness
  bool? _q5Answer; // Bone or joint problem
  bool? _q6Answer; // Takes blood pressure/heart medication
  bool? _q7Answer; // Other reason

  bool get _allQuestionsAnswered =>
      _q1Answer != null &&
      _q2Answer != null &&
      _q3Answer != null &&
      _q4Answer != null &&
      _q5Answer != null &&
      _q6Answer != null &&
      _q7Answer != null;

  bool get _isSafeForExercise =>
      _allQuestionsAnswered &&
      !_q1Answer! &&
      !_q2Answer! &&
      !_q3Answer! &&
      !_q4Answer! &&
      !_q5Answer! &&
      !_q6Answer! &&
      !_q7Answer!;

  int get _yesCount {
    int count = 0;
    if (_q1Answer == true) count++;
    if (_q2Answer == true) count++;
    if (_q3Answer == true) count++;
    if (_q4Answer == true) count++;
    if (_q5Answer == true) count++;
    if (_q6Answer == true) count++;
    if (_q7Answer == true) count++;
    return count;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestionnaire() async {
    if (!_allQuestionsAnswered) {
      _showError('Please answer all questions before continuing.');
      return;
    }

    final result = FitnessTestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      completedAt: DateTime.now(),
      hasHeartCondition: _q1Answer!,
      hasChestPainDuringActivity: _q2Answer!,
      hasChestPainWhenInactive: _q3Answer!,
      hasDizzinessOrLossOfConsciousness: _q4Answer!,
      hasBoneOrJointProblem: _q5Answer!,
      takesPrescriptionDrugs: _q6Answer!,
      hasOtherReason: _q7Answer!,
    );

    if (!_isSafeForExercise) {
      _showUnsafeWarning(result);
    } else {
      await _proceedWithResult(result);
    }
  }

  Future<void> _proceedWithResult(FitnessTestResult result) async {
    // If callback provided, use it (standalone mode)
    if (widget.onComplete != null) {
      widget.onComplete!(result);
      return;
    }

    // Otherwise, we're in health assessment flow - use orchestrator
    final orchestrator = context.read<HealthAssessmentOrchestrator>();
    await orchestrator.saveFitnessScreening(result);

    if (!mounted) return;

    // Navigate based on whether it's safe for exercise
    if (result.isSafeForExercise) {
      context.push('/health-assessment/step-test-prep'); // Using push to maintain back stack
    } else {
      // Skip to face scans - navigate directly to camera (will handle all 3 scans internally)
      context.push('/scan/face/camera', extra: {
        'scanNumber': 1,
        'isPartOfAssessment': true,
      }); // Using push to maintain back stack
    }
  }

  void _showUnsafeWarning(FitnessTestResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Exercise Caution')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Based on your responses, we recommend consulting with a healthcare professional before completing the fitness test.',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your Safety First',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.orange[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can skip the fitness test and continue with the rest of the health assessment.',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.orange[900],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Complete with result but mark as skipped
              if (widget.onUnsafeForExercise != null) {
                widget.onUnsafeForExercise!();
              }
              await _proceedWithResult(result);
            },
            child: const Text('Skip Fitness Test'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to review/edit answers
            },
            child: const Text('Review Answers'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // User went back - clear fitness screening and all future steps
          final orchestrator = context.read<HealthAssessmentOrchestrator>();
          await orchestrator.clearStepsAfter(AssessmentStep.depressionSurvey);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Fitness Screening'),
          elevation: 0,
        ),
      body: Column(
        children: [
          // Header with progress
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAR-Q Safety Screening',
                  style: AppTypography.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please answer the following questions to ensure it is safe for you to complete the step test.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                // Progress indicator
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _getProgress(),
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_getAnsweredCount()}/7',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Questions
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Disclaimer banner
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Answer honestly. Any "Yes" answer means you should consult a doctor before physical activity.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.blue[900],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Question 1
                YesNoQuestionWidget(
                  questionText:
                      'Has your doctor ever said that you have a heart condition and that you should only do physical activity recommended by a doctor?',
                  selectedAnswer: _q1Answer,
                  onAnswerSelected: (answer) => setState(() => _q1Answer = answer),
                ),
                const SizedBox(height: 16),

                // Question 2
                YesNoQuestionWidget(
                  questionText: 'Do you feel pain in your chest when you do physical activity?',
                  selectedAnswer: _q2Answer,
                  onAnswerSelected: (answer) => setState(() => _q2Answer = answer),
                ),
                const SizedBox(height: 16),

                // Question 3
                YesNoQuestionWidget(
                  questionText:
                      'In the past month, have you had chest pain when you were not doing physical activity?',
                  selectedAnswer: _q3Answer,
                  onAnswerSelected: (answer) => setState(() => _q3Answer = answer),
                ),
                const SizedBox(height: 16),

                // Question 4
                YesNoQuestionWidget(
                  questionText:
                      'Do you lose your balance because of dizziness, or do you ever lose consciousness?',
                  selectedAnswer: _q4Answer,
                  onAnswerSelected: (answer) => setState(() => _q4Answer = answer),
                ),
                const SizedBox(height: 16),

                // Question 5
                YesNoQuestionWidget(
                  questionText:
                      'Do you have a bone or joint problem that could be made worse by a change in your physical activity?',
                  selectedAnswer: _q5Answer,
                  onAnswerSelected: (answer) => setState(() => _q5Answer = answer),
                ),
                const SizedBox(height: 16),

                // Question 6
                YesNoQuestionWidget(
                  questionText:
                      'Is your doctor currently prescribing drugs (for example, water pills) for your blood pressure or heart condition?',
                  selectedAnswer: _q6Answer,
                  onAnswerSelected: (answer) => setState(() => _q6Answer = answer),
                ),
                const SizedBox(height: 16),

                // Question 7
                YesNoQuestionWidget(
                  questionText: 'Do you know of any other reason why you should not do physical activity?',
                  selectedAnswer: _q7Answer,
                  onAnswerSelected: (answer) => setState(() => _q7Answer = answer),
                ),
                const SizedBox(height: 24),

                // Safety status preview (if all answered)
                if (_allQuestionsAnswered) ...[
                  Card(
                    color: _isSafeForExercise ? AppColors.success : AppColors.error,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _isSafeForExercise ? Icons.check_circle : Icons.warning,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isSafeForExercise
                                      ? 'Safe to Proceed'
                                      : 'Caution Recommended',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isSafeForExercise
                                      ? 'You can safely complete the fitness test'
                                      : '$_yesCount safety concern${_yesCount > 1 ? 's' : ''} identified',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 100), // Bottom padding for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _allQuestionsAnswered ? _submitQuestionnaire : null,
        backgroundColor:
            _allQuestionsAnswered ? AppColors.primaryPurple : Colors.grey[400],
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Continue'),
      ),
      ), // PopScope child
    );
  }

  int _getAnsweredCount() {
    int count = 0;
    if (_q1Answer != null) count++;
    if (_q2Answer != null) count++;
    if (_q3Answer != null) count++;
    if (_q4Answer != null) count++;
    if (_q5Answer != null) count++;
    if (_q6Answer != null) count++;
    if (_q7Answer != null) count++;
    return count;
  }

  double _getProgress() {
    return _getAnsweredCount() / 7.0;
  }
}
