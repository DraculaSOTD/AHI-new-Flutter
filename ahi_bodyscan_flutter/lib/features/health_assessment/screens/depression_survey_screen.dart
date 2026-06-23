import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/depression_survey_result.dart';
import '../widgets/survey_question_widget.dart';
import '../services/health_assessment_orchestrator.dart';

/// PHQ-9 (Patient Health Questionnaire-9) Depression Survey Screen
///
/// Assesses depression symptoms over the last two weeks with 9 questions.
/// Includes critical detection for self-harm thoughts (Q9).
/// Can be used standalone or as part of the health assessment flow.
class DepressionSurveyScreen extends StatefulWidget {
  final Function(DepressionSurveyResult)? onComplete;

  const DepressionSurveyScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<DepressionSurveyScreen> createState() => _DepressionSurveyScreenState();
}

class _DepressionSurveyScreenState extends State<DepressionSurveyScreen> {
  final _scrollController = ScrollController();

  // Question scores (null = not answered, 0-3 = answered)
  int? _q1Score; // Little interest or pleasure in doing things
  int? _q2Score; // Feeling down, depressed, or hopeless
  int? _q3Score; // Trouble falling/staying asleep, or sleeping too much
  int? _q4Score; // Feeling tired or having little energy
  int? _q5Score; // Poor appetite or overeating
  int? _q6Score; // Feeling bad about yourself
  int? _q7Score; // Trouble concentrating
  int? _q8Score; // Moving or speaking slowly / being fidgety
  int? _q9Score; // Thoughts of hurting yourself or being better off dead

  bool get _allQuestionsAnswered =>
      _q1Score != null &&
      _q2Score != null &&
      _q3Score != null &&
      _q4Score != null &&
      _q5Score != null &&
      _q6Score != null &&
      _q7Score != null &&
      _q8Score != null &&
      _q9Score != null;

  int get _totalScore =>
      (_q1Score ?? 0) +
      (_q2Score ?? 0) +
      (_q3Score ?? 0) +
      (_q4Score ?? 0) +
      (_q5Score ?? 0) +
      (_q6Score ?? 0) +
      (_q7Score ?? 0) +
      (_q8Score ?? 0) +
      (_q9Score ?? 0);

  bool get _hasSelfHarmThoughts => (_q9Score ?? 0) > 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _submitSurvey() {
    if (!_allQuestionsAnswered) {
      _showError('Please answer all questions before continuing.');
      return;
    }

    // Show critical warning if self-harm thoughts detected
    if (_hasSelfHarmThoughts) {
      _showCriticalWarning();
      return;
    }

    _completeAndProceed();
  }

  Future<void> _completeAndProceed() async {
    final result = DepressionSurveyResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      completedAt: DateTime.now(),
      littleInterestScore: _q1Score!,
      feelingDownScore: _q2Score!,
      sleepProblemsScore: _q3Score!,
      tiredLowEnergyScore: _q4Score!,
      appetiteProblemsScore: _q5Score!,
      feelingBadAboutSelfScore: _q6Score!,
      concentrationProblemsScore: _q7Score!,
      movementProblemsScore: _q8Score!,
      selfHarmThoughtsScore: _q9Score!,
    );

    // If callback provided, use it (standalone mode)
    if (widget.onComplete != null) {
      widget.onComplete!(result);
      return;
    }

    // Otherwise, we're in health assessment flow - use orchestrator
    final orchestrator = context.read<HealthAssessmentOrchestrator>();
    await orchestrator.saveDepressionSurvey(result);

    if (!mounted) return;

    // Navigate to the first face scan — fitness-screening was removed from
    // the assessment flow per spec (Anxiety → Depression → 3× Face Scan →
    // Body Scan → Step Test).
    context.push('/scan/face/camera', extra: {'isPartOfAssessment': true});
  }

  void _showCriticalWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Important Notice')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have indicated thoughts of self-harm. Your safety is our top priority.',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please seek immediate help:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildResourceLink('988 Suicide & Crisis Lifeline', '988'),
            _buildResourceLink('Crisis Text Line', 'Text HOME to 741741'),
            _buildResourceLink('Emergency Services', '911'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You are not alone. Professional help is available 24/7.',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.blue[900],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeAndProceed();
            },
            child: const Text('I Understand, Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceLink(String label, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.phone, size: 16, color: AppColors.primaryPurple),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: info),
                ],
              ),
            ),
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
          // User went back - clear depression survey and all future steps
          final orchestrator = context.read<HealthAssessmentOrchestrator>();
          await orchestrator.clearStepsAfter(AssessmentStep.anxietySurvey);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Depression Survey'),
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
                  'PHQ-9 Depression Assessment',
                  style: AppTypography.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Over the last two weeks, how often have you been bothered by the following problems?',
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
                      '${_getAnsweredCount()}/9',
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
                // Question 1
                SurveyQuestionWidget(
                  questionText: 'Little interest or pleasure in doing things?',
                  selectedScore: _q1Score,
                  onScoreSelected: (score) => setState(() => _q1Score = score),
                ),
                const SizedBox(height: 16),

                // Question 2
                SurveyQuestionWidget(
                  questionText: 'Feeling down, depressed, or hopeless?',
                  selectedScore: _q2Score,
                  onScoreSelected: (score) => setState(() => _q2Score = score),
                ),
                const SizedBox(height: 16),

                // Question 3
                SurveyQuestionWidget(
                  questionText: 'Trouble falling or staying asleep, or sleeping too much?',
                  selectedScore: _q3Score,
                  onScoreSelected: (score) => setState(() => _q3Score = score),
                ),
                const SizedBox(height: 16),

                // Question 4
                SurveyQuestionWidget(
                  questionText: 'Feeling tired or having little energy?',
                  selectedScore: _q4Score,
                  onScoreSelected: (score) => setState(() => _q4Score = score),
                ),
                const SizedBox(height: 16),

                // Question 5
                SurveyQuestionWidget(
                  questionText: 'Poor appetite or overeating?',
                  selectedScore: _q5Score,
                  onScoreSelected: (score) => setState(() => _q5Score = score),
                ),
                const SizedBox(height: 16),

                // Question 6
                SurveyQuestionWidget(
                  questionText: 'Feeling bad about yourself – or that you are a failure or have let yourself or your family down?',
                  selectedScore: _q6Score,
                  onScoreSelected: (score) => setState(() => _q6Score = score),
                ),
                const SizedBox(height: 16),

                // Question 7
                SurveyQuestionWidget(
                  questionText: 'Trouble concentrating on things, such as reading the newspaper or watching television?',
                  selectedScore: _q7Score,
                  onScoreSelected: (score) => setState(() => _q7Score = score),
                ),
                const SizedBox(height: 16),

                // Question 8
                SurveyQuestionWidget(
                  questionText: 'Moving or speaking so slowly that other people could have noticed? Or the opposite – being so fidgety or restless that you have been moving around a lot more than usual?',
                  selectedScore: _q8Score,
                  onScoreSelected: (score) => setState(() => _q8Score = score),
                ),
                const SizedBox(height: 16),

                // Question 9 - CRITICAL
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _q9Score != null && _q9Score! > 0
                          ? AppColors.error
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sensitive Question',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SurveyQuestionWidget(
                          questionText: 'Thoughts that you would be better off dead, or of hurting yourself in some way?',
                          selectedScore: _q9Score,
                          onScoreSelected: (score) => setState(() => _q9Score = score),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Current score preview (if all answered)
                if (_allQuestionsAnswered) ...[
                  Card(
                    color: _getScoreColor(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Your Preliminary Score',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_totalScore / 27',
                            style: AppTypography.headingLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getSeverityText(),
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
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
                          'This survey is for informational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.blue[900],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Bottom padding for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _allQuestionsAnswered ? _submitSurvey : null,
        backgroundColor: _allQuestionsAnswered
            ? AppColors.primaryPurple
            : Colors.grey[400],
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Continue'),
      ),
      ), // PopScope child
    );
  }

  int _getAnsweredCount() {
    int count = 0;
    if (_q1Score != null) count++;
    if (_q2Score != null) count++;
    if (_q3Score != null) count++;
    if (_q4Score != null) count++;
    if (_q5Score != null) count++;
    if (_q6Score != null) count++;
    if (_q7Score != null) count++;
    if (_q8Score != null) count++;
    if (_q9Score != null) count++;
    return count;
  }

  double _getProgress() {
    return _getAnsweredCount() / 9.0;
  }

  Color _getScoreColor() {
    if (_totalScore <= 4) return AppColors.success;
    if (_totalScore <= 9) return Colors.lightGreen;
    if (_totalScore <= 14) return Colors.orange;
    if (_totalScore <= 19) return Colors.deepOrange;
    return AppColors.error;
  }

  String _getSeverityText() {
    if (_totalScore <= 4) return 'Minimal Depression';
    if (_totalScore <= 9) return 'Mild Depression';
    if (_totalScore <= 14) return 'Moderate Depression';
    if (_totalScore <= 19) return 'Moderately Severe Depression';
    return 'Severe Depression';
  }
}
