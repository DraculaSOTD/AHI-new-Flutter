import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';

class NewScanScreen extends StatelessWidget {
  const NewScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Scan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScanOption(
              context,
              icon: Icons.face,
              title: 'Face Scan',
              description: 'Measure vital signs including heart rate, stress levels, and blood pressure',
              duration: '2-3 minutes',
              color: AppColors.primaryPurple,
              onTap: () => context.push('/scan/face/preparation'),
            ),
            const SizedBox(height: 16),
            _buildScanOption(
              context,
              icon: Icons.accessibility_new,
              title: 'Body Scan',
              description: 'Get accurate body measurements and composition analysis',
              duration: '3-5 minutes',
              color: AppColors.secondaryBlue,
              onTap: () => context.push('/scan/user-profile'),
            ),
            const SizedBox(height: 16),
            _buildScanOption(
              context,
              icon: Icons.health_and_safety,
              title: 'Health Assessment',
              description:
                  'Full assessment: mood surveys, 3 face scans, body scan and step test',
              duration: '10-15 minutes',
              color: AppColors.success,
              onTap: () => context.push('/health-assessment/disclaimer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String duration,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Icon(
                  icon,
                  color: AppColors.textWhite,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}