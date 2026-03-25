import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';

class BodyScanGuideScreen extends StatefulWidget {
  const BodyScanGuideScreen({super.key});

  @override
  State<BodyScanGuideScreen> createState() => _BodyScanGuideScreenState();
}

class _BodyScanGuideScreenState extends State<BodyScanGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<GuideStep> _steps = [
    GuideStep(
      title: 'Clothing Preparation',
      subtitle: 'Wear form-fitting clothes',
      description: 'For the most accurate measurements, wear tight-fitting athletic wear or underwear. Avoid loose clothing that may interfere with body measurements.',
      icon: Icons.checkroom,
      tips: [
        'Athletic wear or fitted clothing works best',
        'Avoid loose shirts, baggy pants, or dresses', 
        'Underwear provides the most accuracy',
        'Remove shoes and accessories',
      ],
    ),
    GuideStep(
      title: 'Lighting Setup',
      subtitle: 'Find good lighting',
      description: 'Position yourself in a well-lit area with even lighting. Natural daylight or bright indoor lighting works best.',
      icon: Icons.lightbulb_outline,
      tips: [
        'Use natural light when possible',
        'Avoid shadows on your body',
        'Stand away from bright windows behind you',
        'Turn on overhead lights if needed',
      ],
    ),
    GuideStep(
      title: 'Phone Position',
      subtitle: 'Position your device correctly',
      description: 'Place your phone 3-4 feet away at waist height. Make sure your full body will be visible in the frame.',
      icon: Icons.phone_android,
      tips: [
        'Distance: 3-4 feet from your body',
        'Height: At your waist level',
        'Stable surface like a table or tripod',
        'Ensure your full body fits in frame',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Skip',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(_steps.length, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(
                      right: index < _steps.length - 1 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? AppColors.primaryPurple
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                return _buildStepPage(_steps[index]);
              },
            ),
          ),
          
          // Bottom navigation
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                // Back button
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.borderMedium),
                      ),
                      child: const Text('Back'),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                
                const SizedBox(width: 16),
                
                // Next/Start button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _steps.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentPage < _steps.length - 1 ? 'Next' : 'Start Scan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPage(GuideStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple,
                  AppColors.secondaryBlue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              step.icon,
              color: AppColors.textWhite,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            step.title,
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            step.subtitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            step.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Tips section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tips for best results:',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...step.tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Visual guide (placeholder for now)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    step.icon,
                    size: 60,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Visual Guide',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuideStep {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<String> tips;

  const GuideStep({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.tips,
  });
}