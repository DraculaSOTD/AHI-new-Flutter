import '../../../core/services/logging_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/profile_service.dart';
import '../services/metronome_service.dart';
import '../services/health_assessment_orchestrator.dart';

/// Active 3-Minute Step Test Screen
///
/// Runs the step test with audio metronome, timer, and visual guidance.
/// Automatically navigates to post-exercise face scan when complete.
class FitnessStepTestActiveScreen extends StatefulWidget {
  final double stepHeightCm;
  final VoidCallback? onTestComplete;

  const FitnessStepTestActiveScreen({
    super.key,
    required this.stepHeightCm,
    this.onTestComplete,
  });

  @override
  State<FitnessStepTestActiveScreen> createState() =>
      _FitnessStepTestActiveScreenState();
}

class _FitnessStepTestActiveScreenState
    extends State<FitnessStepTestActiveScreen> with TickerProviderStateMixin {
  static const Duration testDuration = Duration(minutes: 3);

  late MetronomeService _metronome;
  Timer? _countdownTimer;
  Duration _remainingTime = testDuration;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isComplete = false;
  int _currentBeat = 0;
  int _currentStep = 0;

  late AnimationController _pulseController;
  late AnimationController _stepIndicatorController;

  int _bpm = 96;

  @override
  void initState() {
    super.initState();

    // Get user gender for BPM calculation
    _loadUserProfile();

    // Initialize metronome
    _metronome = MetronomeService(
      onBeat: (beatCount) {
        setState(() {
          _currentBeat = beatCount;
          _currentStep = _metronome.getTotalSteps();
        });
        _stepIndicatorController.forward(from: 0);
      },
      onCycleComplete: () {
        // Optional: haptic feedback on each complete cycle
        HapticFeedback.lightImpact();
      },
    );

    // Pulse animation for timer
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Step indicator animation
    _stepIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Auto-start after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isRunning) {
        _startTest();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    final profileService = context.read<ProfileService>();
    final profile = profileService.selectedProfile;
    if (profile != null) {
      setState(() {
        _bpm = MetronomeService.getRecommendedBpm(gender: profile.gender);
      });
    }
  }

  Future<void> _startTest() async {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    // Start metronome
    await _metronome.start(bpm: _bpm);

    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime -= const Duration(seconds: 1);
        } else {
          _completeTest();
        }
      });
    });

    LoggingService.info('Step test started', tag: 'FitnessStepTest', context: {'bpm': _bpm, 'duration': '3 minutes'});
  }

  Future<void> _pauseTest() async {
    _countdownTimer?.cancel();
    _metronome.pause();
    setState(() {
      _isPaused = true;
    });
    LoggingService.info('Step test paused', tag: 'FitnessStepTest');
  }

  Future<void> _resumeTest() async {
    await _metronome.resume();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime -= const Duration(seconds: 1);
        } else {
          _completeTest();
        }
      });
    });
    setState(() {
      _isPaused = false;
    });
    LoggingService.info('Step test resumed', tag: 'FitnessStepTest');
  }

  Future<void> _completeTest() async {
    _countdownTimer?.cancel();
    await _metronome.stop();

    setState(() {
      _isRunning = false;
      _isComplete = true;
    });

    LoggingService.success('Step test complete', tag: 'FitnessStepTest', context: {'totalSteps': _currentStep});

    // Show completion dialog, then navigate to post-exercise face scan
    if (mounted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            const Text('Test Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Great job! You completed the 3-minute step test.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$_currentStep',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Steps',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.face, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next: Complete a face scan to measure your recovery heart rate',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: _navigateToPostExerciseFaceScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
            ),
            child: const Text('Continue to Face Scan'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToPostExerciseFaceScan() async {
    Navigator.of(context).pop(); // Close dialog

    if (widget.onTestComplete != null) {
      widget.onTestComplete!();
      return;
    }

    // Save to orchestrator
    final orchestrator = context.read<HealthAssessmentOrchestrator>();
    // We'll save the actual heart rates after the face scan
    // For now, just advance the step
    await orchestrator.completeStepTest(
      restingHeartRate: 0, // Will be updated after face scan
      postExerciseHeartRate: 0, // Will be updated after face scan
    );

    if (!mounted) return;

    // Navigate to post-exercise face scan
    context.push('/scan/face/camera', extra: { // Using push
      'scanNumber': 1,
      'isPartOfAssessment': true,
      'scanType': 'post_exercise',
    });
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Step Test?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Exit screen
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _metronome.dispose();
    _pulseController.dispose();
    _stepIndicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remainingTime.inSeconds / testDuration.inSeconds);
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // User went back - clear step test active and all future steps
          final orchestrator = context.read<HealthAssessmentOrchestrator>();
          await orchestrator.clearStepsAfter(AssessmentStep.stepTestPrep);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('3-Minute Step Test'),
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                  minHeight: 8,
                ),
                const SizedBox(height: AppDimensions.spacingXLarge),

                const Spacer(),

                // Timer display
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(
                              0.3 * _pulseController.value,
                            ),
                            blurRadius: 40,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Circular progress
                          SizedBox(
                            width: 280,
                            height: 280,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 16,
                              backgroundColor:
                                  AppColors.textSecondary.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.success,
                              ),
                            ),
                          ),
                          // Timer text
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$minutes:${seconds.toString().padLeft(2, '0')}',
                                style: AppTypography.displayLarge.copyWith(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'remaining',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Step counter
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    boxShadow: [AppShadows.medium],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard('Steps', '$_currentStep'),
                          _buildStatCard('BPM', '$_bpm'),
                          _buildStatCard('Beats', '$_currentBeat'),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingMedium),
                      // Step sequence indicator
                      AnimatedBuilder(
                        animation: _stepIndicatorController,
                        builder: (context, child) {
                          final beatInCycle = (_currentBeat % 4);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBeatDot(0, beatInCycle, 'L ↑'),
                              const SizedBox(width: 12),
                              _buildBeatDot(1, beatInCycle, 'R ↑'),
                              const SizedBox(width: 12),
                              _buildBeatDot(2, beatInCycle, 'L ↓'),
                              const SizedBox(width: 12),
                              _buildBeatDot(3, beatInCycle, 'R ↓'),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Control buttons
                if (!_isComplete) ...[
                  if (!_isRunning || _isPaused)
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? _resumeTest : _startTest,
                        icon: Icon(_isRunning ? Icons.play_arrow : Icons.start),
                        label: Text(_isRunning ? 'Resume' : 'Start Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: _pauseTest,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Test'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBeatDot(int beatIndex, int currentBeat, String label) {
    final isActive = beatIndex == currentBeat;
    final isPast = beatIndex < currentBeat;

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.primaryPurple
                : isPast
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.textSecondary.withValues(alpha: 0.1),
            border: Border.all(
              color: isActive ? AppColors.primaryPurple : Colors.transparent,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isActive
                    ? Colors.white
                    : isPast
                        ? AppColors.success
                        : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
