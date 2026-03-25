import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/user_profile.dart';

class ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;
  final bool hasHealthAssessment;

  const ProfileCard({
    super.key,
    required this.profile,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.onDownload,
    this.hasHealthAssessment = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected ? AppColors.primaryPurple.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: AppColors.primaryPurple, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              // Header with avatar and actions
              Row(
                children: [
                  // Profile avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        profile.initials,
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Profile info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.name,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isMainProfile)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'MAIN',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${profile.age} years • ${_capitalizeFirst(profile.gender)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // More actions menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onSelected: (value) => _handleMenuAction(value),
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (onDownload != null)
                        PopupMenuItem(
                          value: 'download',
                          enabled: hasHealthAssessment,
                          child: Row(
                            children: [
                              Icon(
                                Icons.download,
                                size: 16,
                                color: hasHealthAssessment
                                    ? null
                                    : AppColors.textTertiary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Download Report',
                                style: TextStyle(
                                  color: hasHealthAssessment
                                      ? null
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (onShare != null)
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 16),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ),
                        ),
                      if (onDelete != null && !profile.isMainProfile)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                size: 16,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Profile details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Height',
                            profile.heightUnit == 'ft'
                                ? '${profile.heightFeet ?? 0}\'${profile.heightInches ?? 0}"'
                                : '${profile.height.round()} cm',
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            'Weight',
                            '${profile.weight.round()} ${profile.weightUnit}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDetailItem(
                      'Exercise',
                      _formatExerciseLevel(profile.exerciseLevel),
                    ),
                  ],
                ),
              ),
              
              if (isSelected) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Selected Profile',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatExerciseLevel(String level) {
    switch (level) {
      case 'inactive':
        return 'No exercise';
      case 'exercise10Mins':
        return '10 minutes';
      case 'exercise20to60Mins':
        return '20-60 minutes';
      case 'exercise1to3Hours':
        return '1-3 hours';
      case 'exerciseOver3Hours':
        return 'Over 3 hours';
      default:
        return level;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'download':
        if (hasHealthAssessment) {
          onDownload?.call();
        }
        break;
      case 'share':
        onShare?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}