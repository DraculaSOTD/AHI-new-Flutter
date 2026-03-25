//
//  AHI Body Scan Processing Page
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../ahi_waiting_widget.dart';

class TkBodyScanProcessingPage extends StatefulWidget {
  const TkBodyScanProcessingPage({
    super.key,
    required this.onProcessingComplete,
    required this.onCancel,
  });

  final Function(Map<String, dynamic>) onProcessingComplete;
  final VoidCallback onCancel;

  @override
  State<TkBodyScanProcessingPage> createState() => _TkBodyScanProcessingPageState();
}

class _TkBodyScanProcessingPageState extends State<TkBodyScanProcessingPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  int _currentPhase = 0;
  double _progress = 0.0;

  final List<ProcessingPhase> _phases = [
    ProcessingPhase(
      title: 'Analyzing pose',
      description: 'Detecting body landmarks and joints',
      duration: Duration(seconds: 2),
    ),
    ProcessingPhase(
      title: 'Extracting silhouette',
      description: 'Separating body from background',
      duration: Duration(seconds: 3),
    ),
    ProcessingPhase(
      title: 'Processing measurements',
      description: 'Calculating body dimensions using AI',
      duration: Duration(seconds: 4),
    ),
    ProcessingPhase(
      title: 'Generating results',
      description: 'Compiling your body composition analysis',
      duration: Duration(seconds: 2),
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _startProcessing();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startProcessing() async {
    for (int i = 0; i < _phases.length; i++) {
      setState(() {
        _currentPhase = i;
      });

      // Simulate processing time with incremental progress
      final phase = _phases[i];
      final steps = 20;
      final stepDuration = Duration(milliseconds: phase.duration.inMilliseconds ~/ steps);
      
      for (int step = 0; step <= steps; step++) {
        await Future.delayed(stepDuration);
        if (mounted) {
          setState(() {
            _progress = (i + (step / steps)) / _phases.length;
          });
        }
      }
    }

    // Simulate successful processing result
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onProcessingComplete({
        'success': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        // Mock data - in real implementation, this would come from native SDK
        'cm_adj_chest': 95.2,
        'cm_adj_waist': 82.1,
        'cm_adj_hips': 98.5,
        'cm_adj_thigh': 58.3,
        'cm_adj_inseam': 76.8,
        'percent_adj_bodyFat': 18.5,
        'kg_adj_weightPredict': 72.3,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhase = _phases[_currentPhase];
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Spacer for center alignment
                  const Text(
                    'Processing Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated processing indicator
                  AnimatedBuilder(
                    animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: const TkWaitingWidget(
                            size: 200,
                            showTitle: false,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple,
                          ),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_progress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Current phase info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          currentPhase.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentPhase.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Phase indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_phases.length, (index) {
                      final isCompleted = index < _currentPhase;
                      final isCurrent = index == _currentPhase;
                      
                      return Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? AppColors.primaryPurple
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Bottom info
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'Please keep the app open while we process your scan',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessingPhase {
  const ProcessingPhase({
    required this.title,
    required this.description,
    required this.duration,
  });

  final String title;
  final String description;
  final Duration duration;
}