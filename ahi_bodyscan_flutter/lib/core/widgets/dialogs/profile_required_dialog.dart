import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Shows a dialog indicating that a profile is required to proceed
class ProfileRequiredDialog {
  ProfileRequiredDialog._(); // Private constructor

  /// Show profile required dialog
  ///
  /// [context] - BuildContext for showing the dialog
  /// [scanType] - Type of scan that requires a profile (e.g., "Body Scan", "Face Scan")
  /// [navigateToProfiles] - Whether to offer navigation to profile creation (default: true)
  static Future<void> show(
    BuildContext context, {
    required String scanType,
    bool navigateToProfiles = true,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.person_off,
          size: 48,
          color: AppColors.warning,
        ),
        title: const Text('Profile Required'),
        content: Text(
          'Please create and select a profile before starting $scanType.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          if (navigateToProfiles)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/settings'); // Navigate to settings/profiles
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
              ),
              child: const Text('Create Profile'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
              ),
              child: const Text('OK'),
            ),
        ],
      ),
    );
  }

  /// Simple version without navigation option
  static Future<void> showSimple(
    BuildContext context, {
    required String scanType,
  }) {
    return show(context, scanType: scanType, navigateToProfiles: false);
  }
}
