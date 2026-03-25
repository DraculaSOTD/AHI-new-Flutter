import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Reusable error dialog for displaying error messages
class ErrorDialog {
  ErrorDialog._(); // Private constructor

  /// Show an error dialog
  ///
  /// [context] - BuildContext for showing the dialog
  /// [title] - Error dialog title (default: "Error")
  /// [message] - Error message to display
  /// [onRetry] - Optional callback for retry action
  static Future<void> show(
    BuildContext context, {
    String title = 'Error',
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          size: 48,
          color: AppColors.error,
        ),
        title: Text(title),
        content: Text(
          message,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
          if (onRetry != null)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRetry();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Show a warning dialog (uses warning color instead of error)
  static Future<void> showWarning(
    BuildContext context, {
    String title = 'Warning',
    required String message,
    VoidCallback? onContinue,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: AppColors.warning,
        ),
        title: Text(title),
        content: Text(
          message,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          if (onContinue != null)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onContinue();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
              child: const Text('Continue'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
              child: const Text('OK'),
            ),
        ],
      ),
    );
  }

  /// Show a success dialog
  static Future<void> showSuccess(
    BuildContext context, {
    String title = 'Success',
    required String message,
    VoidCallback? onDone,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          size: 48,
          color: AppColors.success,
        ),
        title: Text(title),
        content: Text(
          message,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDone?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    String title = 'Confirm',
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          isDangerous ? Icons.warning_amber_rounded : Icons.help_outline,
          size: 48,
          color: isDangerous ? AppColors.error : AppColors.info,
        ),
        title: Text(title),
        content: Text(
          message,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: isDangerous ? AppColors.error : AppColors.primaryPurple,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
