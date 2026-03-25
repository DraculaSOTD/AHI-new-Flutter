//
//  AHI Body Scan Guide Page
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/ahi_user_data.dart';

class TkBodyScanGuidePage extends StatefulWidget {
  const TkBodyScanGuidePage({
    super.key,
    required this.userData,
    required this.onStartScan,
    required this.onCancel,
  });

  final TkUserData userData;
  final VoidCallback onStartScan;
  final VoidCallback onCancel;

  @override
  State<TkBodyScanGuidePage> createState() => _TkBodyScanGuidePageState();
}

class _TkBodyScanGuidePageState extends State<TkBodyScanGuidePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<GuideStep> _steps = [
    GuideStep(
      title: 'Stand 8 feet away',
      description: 'Position yourself about 8 feet (2.4 meters) from your device',
      icon: Icons.straighten,
      color: AppColors.primaryPurple,
    ),
    GuideStep(
      title: 'Wear tight-fitting clothing',
      description: 'For best results, wear form-fitting clothes or workout attire',
      icon: Icons.checkroom,
      color: AppColors.primaryBlue,
    ),
    GuideStep(
      title: 'Clear background',
      description: 'Stand against a plain wall or clear background',
      icon: Icons.wallpaper,
      color: AppColors.accentTeal,
    ),
    GuideStep(
      title: 'Full body visible',
      description: 'Make sure your entire body from head to feet is visible',
      icon: Icons.accessibility_new,
      color: AppColors.primaryPurple,
    ),
    GuideStep(
      title: 'Arms away from body',
      description: 'Keep your arms slightly away from your body',
      icon: Icons.open_in_full,
      color: AppColors.primaryBlue,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: widget.onCancel,
        ),
        title: const Text(
          'Body Scan Guide',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.backgroundWhite,
              child: Column(
                children: [
                  Row(
                    children: List.generate(_steps.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            left: index > 0 ? 4 : 0,
                            right: index < _steps.length - 1 ? 4 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? AppColors.primaryPurple
                                : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Step ${_currentStep + 1} of ${_steps.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Guide content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: step.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: Icon(
                            step.icon,
                            size: 60,
                            color: step.color,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          step.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.backgroundWhite,
              child: SafeArea(
                child: Row(
                  children: [
                    // Previous button
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryPurple),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Previous',
                            style: TextStyle(
                              color: AppColors.primaryPurple,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),

                    const SizedBox(width: 12),

                    // Next/Start button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentStep == _steps.length - 1
                            ? widget.onStartScan
                            : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentStep == _steps.length - 1 ? 'Start Scan' : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuideStep {
  const GuideStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}