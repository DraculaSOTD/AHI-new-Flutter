import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/health_assessment_orchestrator.dart';

/// Preparation screen for the 3-minute step test
///
/// Explains the test procedure and collects step height.
/// Can be used standalone or as part of the health assessment flow.
class FitnessStepTestPreparationScreen extends StatefulWidget {
  final Function(double stepHeightCm)? onBeginTest;

  const FitnessStepTestPreparationScreen({
    super.key,
    this.onBeginTest,
  });

  @override
  State<FitnessStepTestPreparationScreen> createState() =>
      _FitnessStepTestPreparationScreenState();
}

class _FitnessStepTestPreparationScreenState
    extends State<FitnessStepTestPreparationScreen> {
  final _stepHeightController = TextEditingController();
  String _heightUnit = 'cm';

  @override
  void dispose() {
    _stepHeightController.dispose();
    super.dispose();
  }

  Future<void> _beginTest() async {
    if (_stepHeightController.text.isEmpty) {
      _showError('Please enter your step height');
      return;
    }

    double? heightValue = double.tryParse(_stepHeightController.text);
    if (heightValue == null || heightValue <= 0) {
      _showError('Please enter a valid step height');
      return;
    }

    // Convert to cm if needed
    double heightInCm = _heightUnit == 'cm' ? heightValue : heightValue * 2.54;

    // Validate range (15-51 cm)
    if (heightInCm < 15 || heightInCm > 51) {
      _showError('Step height must be between 15-51 cm (6-20 inches)');
      return;
    }

    // If callback provided, use it (standalone mode)
    if (widget.onBeginTest != null) {
      widget.onBeginTest!(heightInCm);
      return;
    }

    // Otherwise, we're in health assessment flow - use orchestrator
    final orchestrator = context.read<HealthAssessmentOrchestrator>();
    await orchestrator.saveStepTestPreparation(stepHeightCm: heightInCm);

    if (!mounted) return;

    // Navigate to active step test screen
    context.push('/health-assessment/step-test-active', extra: { // Using push
      'stepHeightCm': heightInCm,
    });
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
          // User went back - clear step test and all future steps
          final orchestrator = context.read<HealthAssessmentOrchestrator>();
          await orchestrator.clearStepsAfter(AssessmentStep.fitnessScreening);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Step Test Preparation'),
          elevation: 0,
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.fitness_center, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    '3-Minute Step Test',
                    style: AppTypography.headingLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete the step test to assess your cardio fitness level in comparison to your resting state.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // What to expect
            Text(
              'What to Expect',
              style: AppTypography.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.timer,
              title: 'Part 1: 3-Minute Step Test',
              description:
                  'You will step up and down a step at a determined pace for 3 minutes. The app will provide audio beats to guide your stepping rhythm.',
            ),
            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.face,
              title: 'Part 2: Face Scan',
              description:
                  'Immediately after you finish the step test, complete a final face scan to measure your heart rate recovery.',
            ),

            const SizedBox(height: 24),

            // Step instructions
            Text(
              'Stepping Sequence',
              style: AppTypography.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You will be stepping onto the step in an "up up, down down" sequence:',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStepInstruction('1', 'Left foot up', Colors.blue),
                    _buildStepInstruction('2', 'Right foot up', Colors.blue),
                    _buildStepInstruction('3', 'Left foot down', Colors.orange),
                    _buildStepInstruction('4', 'Right foot down', Colors.orange),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.music_note, color: Colors.amber[900], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stepping must be done in sync with the sound being played through your phone. One step for each beat.',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.amber[900],
                                height: 1.4,
                              ),
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

            // Step height input
            Text(
              'Step Height',
              style: AppTypography.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How high is your step?',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _stepHeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Step Height',
                              hintText: _heightUnit == 'cm' ? '15-51' : '6-20',
                              prefixIcon: const Icon(Icons.height),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _heightUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'cm', child: Text('cm')),
                              DropdownMenuItem(value: 'in', child: Text('inches')),
                            ],
                            onChanged: (value) {
                              setState(() => _heightUnit = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Find a step between 15-51cm (6-20 inches) high. Standard stairs work well.',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.blue[900],
                                height: 1.4,
                              ),
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

            // Important reminders
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Important Reminders',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildReminderItem('Keep your phone with you during the test'),
                  _buildReminderItem('Maintain a steady pace with the audio beats'),
                  _buildReminderItem('Stop if you feel dizzy or unwell'),
                  _buildReminderItem('Be ready for the face scan immediately after'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Begin button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _beginTest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow),
                    const SizedBox(width: 8),
                    Text(
                      'Begin Step Test',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ), // SafeArea child
      ), // Scaffold body
      ), // PopScope child
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepInstruction(String number, String instruction, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            instruction,
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.orange[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
