import '../../../core/services/logging_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';

/// Break screen shown between face scans
///
/// Displays a 60-second countdown timer with rest instructions.
/// Automatically navigates to the next face scan when timer reaches zero.
class FaceScanBreakScreen extends StatefulWidget {
  final int scanNumber; // Which scan just completed (1 or 2)
  final int nextScanNumber; // Which scan is next (2 or 3)
  final Duration breakDuration; // Default 60 seconds
  final VoidCallback? onBreakComplete;
  final bool isPartOfAssessment; // Whether this is part of health assessment

  const FaceScanBreakScreen({
    super.key,
    required this.scanNumber,
    required this.nextScanNumber,
    this.breakDuration = const Duration(seconds: 60),
    this.onBreakComplete,
    this.isPartOfAssessment = false,
  });

  @override
  State<FaceScanBreakScreen> createState() => _FaceScanBreakScreenState();
}

class _FaceScanBreakScreenState extends State<FaceScanBreakScreen>
    with TickerProviderStateMixin {
  late Timer _timer;
  late Duration _remaining;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    LoggingService.info('FaceScanBreakScreen initState', tag: 'FaceScanBreak', context: {'scanNumber': widget.scanNumber, 'nextScanNumber': widget.nextScanNumber, 'isPartOfAssessment': widget.isPartOfAssessment});
    _remaining = widget.breakDuration;

    // Pulse animation for the timer circle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: widget.breakDuration,
    )..forward();

    // Start countdown timer
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        } else {
          _timer.cancel();
          _onBreakComplete();
        }
      });
    });
  }

  void _onBreakComplete() {
    if (widget.onBreakComplete != null) {
      widget.onBreakComplete!();
    } else {
      // Default behavior: launch next face scan using native SDK
      if (mounted) {
        LoggingService.info('Break complete - launching native face scan', tag: 'FaceScanBreak', context: {'nextScanNumber': widget.nextScanNumber, 'isPartOfAssessment': widget.isPartOfAssessment});

        context.push('/scan/face/camera', extra: {
          'isPartOfAssessment': widget.isPartOfAssessment,
        });
      }
    }
  }

  void _skipBreak() {
    _timer.cancel();
    _onBreakComplete();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining.inSeconds / widget.breakDuration.inSeconds;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Rest Break',
          style: AppTypography.headlineSmall,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                         MediaQuery.of(context).padding.top -
                         MediaQuery.of(context).padding.bottom -
                         kToolbarHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
              child: Column(
                children: [
              // Progress indicator
              LinearProgressIndicator(
                value: 1 - progress,
                backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                minHeight: 6,
              ),
              const SizedBox(height: AppDimensions.spacingLarge),

              // Scan progress text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Scan ${widget.scanNumber} of 3 Complete',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXLarge),

              // Timer circle
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withValues(
                            alpha: 0.3 * _pulseController.value,
                          ),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress ring
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryPurple,
                            ),
                          ),
                        ),
                        // Timer text
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_remaining.inSeconds}',
                              style: AppTypography.displayLarge.copyWith(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                            Text(
                              'seconds',
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

              const SizedBox(height: AppDimensions.spacingXLarge),

              // Instructions
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  boxShadow: [AppShadows.small],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.self_improvement,
                      size: 48,
                      color: AppColors.secondaryBlue,
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    Text(
                      'Take a Deep Breath',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSmall),
                    Text(
                      'Please remain seated and relaxed during this break. The next scan will begin automatically in ${_remaining.inSeconds} seconds.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    _buildInstruction(Icons.airline_seat_recline_normal, 'Stay seated'),
                    _buildInstruction(Icons.air, 'Breathe normally'),
                    _buildInstruction(Icons.noise_control_off, 'Avoid talking'),
                    _buildInstruction(Icons.spa, 'Stay relaxed'),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXLarge),

              // Next scan info
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.secondaryBlue),
                    const SizedBox(width: AppDimensions.spacingSmall),
                    Expanded(
                      child: Text(
                        'Scan ${widget.nextScanNumber} of 3 coming up next',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.secondaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingLarge),

              // Skip button
              TextButton(
                onPressed: _skipBreak,
                child: Text(
                  'Skip Break',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
