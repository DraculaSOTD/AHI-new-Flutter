import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Reusable loading dialog for async operations
class LoadingDialog {
  LoadingDialog._(); // Private constructor

  /// Show a loading dialog with optional message
  ///
  /// [context] - BuildContext for showing the dialog
  /// [message] - Optional message to display (default: "Loading...")
  /// [barrierDismissible] - Whether dialog can be dismissed by tapping outside (default: false)
  ///
  /// Returns the dialog route that can be used to close the dialog:
  /// ```dart
  /// final dialog = LoadingDialog.show(context, message: "Processing...");
  /// // Later...
  /// Navigator.of(context).removeRoute(dialog);
  /// ```
  static Future<void> show(
    BuildContext context, {
    String message = 'Loading...',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => WillPopScope(
        onWillPop: () async => barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show loading dialog with progress indicator (0.0 - 1.0)
  static Future<void> showWithProgress(
    BuildContext context, {
    String message = 'Processing...',
    required double progress,
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => WillPopScope(
        onWillPop: () async => barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  color: AppColors.primaryPurple,
                  backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hide the currently showing loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
