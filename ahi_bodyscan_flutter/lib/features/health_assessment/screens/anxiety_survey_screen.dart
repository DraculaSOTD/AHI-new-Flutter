import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/anxiety_survey_result.dart';
import '../widgets/survey_question_widget.dart';
import '../services/health_assessment_orchestrator.dart';

/// GAD-7 (Generalized Anxiety Disorder-7) Anxiety Survey Screen
///
/// Assesses anxiety symptoms over the last two weeks with 7 questions.
/// Can be used standalone or as part of the health assessment flow.
class AnxietySurveyScreen extends StatefulWidget {
  final Function(AnxietySurveyResult)? onComplete;

  const AnxietySurveyScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<AnxietySurveyScreen> createState() => _AnxietySurveyScreenState();
}

class _AnxietySurveyScreenState extends State<AnxietySurveyScreen> {
  final _scrollController = ScrollController();

  // Question scores (null = not answered, 0-3 = answered)
  int? _q1Score; // Nervous, anxious, or on edge
  int? _q2Score; // Not being able to stop or control worrying
  int? _q3Score; // Worrying too much about different things
  int? _q4Score; // Trouble relaxing
  int? _q5Score; // Being so restless that it's hard to sit still
  int? _q6Score; // Becoming easily annoyed or irritable
  int? _q7Score; // Feeling afraid as if something awful might happen

  bool get _allQuestionsAnswered =>
      _q1Score != null &&
      _q2Score != null &&
      _q3Score != null &&
      _q4Score != null &&
      _q5Score != null &&
      _q6Score != null &&
      _q7Score != null;

  int get _totalScore =>
      (_q1Score ?? 0) +
      (_q2Score ?? 0) +
      (_q3Score ?? 0) +
      (_q4Score ?? 0) +
      (_q5Score ?? 0) +
      (_q6Score ?? 0) +
      (_q7Score ?? 0);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitSurvey() async {
    if (!_allQuestionsAnswered) {
      _showError('Please answer all questions before continuing.');
      return;
    }

    final result = AnxietySurveyResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      completedAt: DateTime.now(),
      nervousAnxiousScore: _q1Score!,
      uncontrollableWorryScore: _q2Score!,
      worryingTooMuchScore: _q3Score!,
      troubleRelaxingScore: _q4Score!,
      restlessnessScore: _q5Score!,
      easilyAnnoyedScore: _q6Score!,
      feelingAfraidScore: _q7Score!,
    );

    // If callback provided, use it (standalone mode)
    if (widget.onComplete != null) {
      widget.onComplete!(result);
      return;
    }

    // Otherwise, we're in health assessment flow - use orchestrator
    final orchestrator = context.read<HealthAssessmentOrchestrator>();
    await orchestrator.saveAnxietySurvey(result);

    if (!mounted) return;

    // Navigate to next step (depression survey) - using push to maintain back stack
    context.push('/health-assessment/depression');
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
          // User went back - clear anxiety survey and all future steps
          final orchestrator = context.read<HealthAssessmentOrchestrator>();
          await orchestrator.clearStepsAfter(AssessmentStep.disclaimer);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Anxiety Survey'),
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
                  'GAD-7 Anxiety Assessment',
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
                // Question 1
                SurveyQuestionWidget(
                  questionText: 'Feeling nervous, anxious, or on edge?',
                  selectedScore: _q1Score,
                  onScoreSelected: (score) => setState(() => _q1Score = score),
                ),
                const SizedBox(height: 16),

                // Question 2
                SurveyQuestionWidget(
                  questionText: 'Not being able to stop or control worrying?',
                  selectedScore: _q2Score,
                  onScoreSelected: (score) => setState(() => _q2Score = score),
                ),
                const SizedBox(height: 16),

                // Question 3
                SurveyQuestionWidget(
                  questionText: 'Worrying too much about different things?',
                  selectedScore: _q3Score,
                  onScoreSelected: (score) => setState(() => _q3Score = score),
                ),
                const SizedBox(height: 16),

                // Question 4
                SurveyQuestionWidget(
                  questionText: 'Trouble relaxing?',
                  selectedScore: _q4Score,
                  onScoreSelected: (score) => setState(() => _q4Score = score),
                ),
                const SizedBox(height: 16),

                // Question 5
                SurveyQuestionWidget(
                  questionText: 'Being so restless that it is hard to sit still?',
                  selectedScore: _q5Score,
                  onScoreSelected: (score) => setState(() => _q5Score = score),
                ),
                const SizedBox(height: 16),

                // Question 6
                SurveyQuestionWidget(
                  questionText: 'Becoming easily annoyed or irritable?',
                  selectedScore: _q6Score,
                  onScoreSelected: (score) => setState(() => _q6Score = score),
                ),
                const SizedBox(height: 16),

                // Question 7
                SurveyQuestionWidget(
                  questionText: 'Feeling afraid, as if something awful might happen?',
                  selectedScore: _q7Score,
                  onScoreSelected: (score) => setState(() => _q7Score = score),
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
                            '$_totalScore / 21',
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
    return count;
  }

  double _getProgress() {
    return _getAnsweredCount() / 7.0;
  }

  Color _getScoreColor() {
    if (_totalScore <= 4) return AppColors.success;
    if (_totalScore <= 9) return Colors.lightGreen;
    if (_totalScore <= 14) return Colors.orange;
    return AppColors.error;
  }

  String _getSeverityText() {
    if (_totalScore <= 4) return 'Minimal Anxiety';
    if (_totalScore <= 9) return 'Mild Anxiety';
    if (_totalScore <= 14) return 'Moderate Anxiety';
    return 'Severe Anxiety';
  }
}
