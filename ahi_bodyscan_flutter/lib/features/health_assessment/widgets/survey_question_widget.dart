import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Reusable widget for mental health survey questions (GAD-7, PHQ-9)
///
/// Displays a question with 4-point scale response options:
/// - 0: Not at all
/// - 1: Several days
/// - 2: More than half the days
/// - 3: Nearly every day
class SurveyQuestionWidget extends StatelessWidget {
  final String questionText;
  final int? selectedScore; // Current score (0-3 or null if not answered)
  final Function(int) onScoreSelected;
  final bool isRequired;
  final String? helpText;

  const SurveyQuestionWidget({
    super.key,
    required this.questionText,
    required this.selectedScore,
    required this.onScoreSelected,
    this.isRequired = true,
    this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    questionText,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                if (isRequired)
                  Text(
                    '*',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            if (helpText != null) ...[
              const SizedBox(height: 8),
              Text(
                helpText!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Response options
            _buildResponseOption(
              score: 0,
              label: 'Not at all',
              icon: Icons.sentiment_very_satisfied,
              color: AppColors.success,
            ),
            const SizedBox(height: 8),
            _buildResponseOption(
              score: 1,
              label: 'Several days',
              icon: Icons.sentiment_satisfied,
              color: Colors.lightGreen,
            ),
            const SizedBox(height: 8),
            _buildResponseOption(
              score: 2,
              label: 'More than half the days',
              icon: Icons.sentiment_neutral,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildResponseOption(
              score: 3,
              label: 'Nearly every day',
              icon: Icons.sentiment_dissatisfied,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseOption({
    required int score,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedScore == score;

    return InkWell(
      onTap: () => onScoreSelected(score),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.white,
                border: Border.all(
                  color: isSelected ? color : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            // Icon
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[500],
              size: 22,
            ),

            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? color : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yes/No question widget for PAR-Q fitness screening
class YesNoQuestionWidget extends StatelessWidget {
  final String questionText;
  final bool? selectedAnswer; // true = Yes, false = No, null = not answered
  final Function(bool) onAnswerSelected;
  final bool isRequired;
  final bool highlightYes; // Highlight "Yes" as warning (for safety questions)

  const YesNoQuestionWidget({
    super.key,
    required this.questionText,
    required this.selectedAnswer,
    required this.onAnswerSelected,
    this.isRequired = true,
    this.highlightYes = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    questionText,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                if (isRequired)
                  Text(
                    '*',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Yes/No options
            Row(
              children: [
                Expanded(
                  child: _buildYesNoOption(
                    value: true,
                    label: 'Yes',
                    icon: highlightYes ? Icons.warning : Icons.check_circle,
                    color: highlightYes ? AppColors.error : AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildYesNoOption(
                    value: false,
                    label: 'No',
                    icon: highlightYes ? Icons.check_circle : Icons.cancel,
                    color: highlightYes ? AppColors.success : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoOption({
    required bool value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedAnswer == value;

    return InkWell(
      onTap: () => onAnswerSelected(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[500],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
