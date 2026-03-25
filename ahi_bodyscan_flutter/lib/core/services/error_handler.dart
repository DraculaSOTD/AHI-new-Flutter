import 'package:flutter/material.dart';
import '../../services/error/error_handling_service.dart';
import '../widgets/dialogs/dialogs.dart';
import 'logging_service.dart';

/// Centralized error handler for AHI BodyScan Flutter App
///
/// This service provides a unified API for error handling across the app,
/// combining retry logic, structured logging, and user-friendly error dialogs.
///
/// Example:
/// ```dart
/// try {
///   await ErrorHandler.executeWithRetry(
///     () => sdkService.initializeSdk(),
///     operationName: 'SDK Initialization',
///     context: context,
///   );
/// } catch (e) {
///   // Error already logged and shown to user
/// }
/// ```
class ErrorHandler {
  ErrorHandler._(); // Private constructor

  /// Execute operation with automatic retry, logging, and error UI
  ///
  /// [operation] - The async operation to execute
  /// [operationName] - Human-readable name for logging
  /// [context] - Optional BuildContext for showing error dialog
  /// [showDialog] - Whether to show error dialog on failure (default: true)
  /// [maxAttempts] - Maximum retry attempts (default: 3)
  /// [onError] - Optional custom error handler
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    required String operationName,
    BuildContext? context,
    bool showDialog = true,
    int maxAttempts = 3,
    void Function(Exception)? onError,
  }) async {
    try {
      LoggingService.info('Starting operation: $operationName');

      final result = await ErrorHandlingService.executeWithRetry<T>(
        operation,
        operationName: operationName,
        maxAttempts: maxAttempts,
        shouldRetry: ErrorHandlingService.isRetryableError,
      );

      LoggingService.success('Operation completed: $operationName');
      return result;

    } on Exception catch (e, stackTrace) {
      LoggingService.error(
        'Operation failed: $operationName',
        error: e,
        stackTrace: stackTrace,
        context: {'maxAttempts': maxAttempts},
      );

      if (onError != null) {
        onError(e);
      }

      if (showDialog && context != null && context.mounted) {
        await _showErrorDialog(context, operationName, e);
      }

      rethrow;
    }
  }

  /// Execute WebSocket operation with automatic retry
  static Future<T> executeWebSocketWithRetry<T>(
    Future<T> Function() operation, {
    required String operationName,
    BuildContext? context,
    bool showDialog = true,
  }) async {
    try {
      LoggingService.info('Starting WebSocket operation: $operationName');

      final result = await ErrorHandlingService.executeWebSocketWithRetry<T>(
        operation,
        operationName: operationName,
      );

      LoggingService.success('WebSocket operation completed: $operationName');
      return result;

    } on Exception catch (e, stackTrace) {
      LoggingService.error(
        'WebSocket operation failed: $operationName',
        error: e,
        stackTrace: stackTrace,
      );

      if (showDialog && context != null && context.mounted) {
        await _showErrorDialog(context, operationName, e);
      }

      rethrow;
    }
  }

  /// Execute camera operation with automatic retry
  static Future<T> executeCameraWithRetry<T>(
    Future<T> Function() operation, {
    required String operationName,
    BuildContext? context,
    bool showDialog = true,
  }) async {
    try {
      LoggingService.info('Starting camera operation: $operationName');

      final result = await ErrorHandlingService.executeCameraWithRetry<T>(
        operation,
        operationName: operationName,
      );

      LoggingService.success('Camera operation completed: $operationName');
      return result;

    } on Exception catch (e, stackTrace) {
      LoggingService.error(
        'Camera operation failed: $operationName',
        error: e,
        stackTrace: stackTrace,
      );

      if (showDialog && context != null && context.mounted) {
        await _showErrorDialog(context, operationName, e);
      }

      rethrow;
    }
  }

  /// Execute operation with circuit breaker pattern
  static Future<T> executeWithCircuitBreaker<T>(
    Future<T> Function() operation, {
    required String operationName,
    BuildContext? context,
    bool showDialog = true,
    int failureThreshold = 5,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      LoggingService.info('Starting operation with circuit breaker: $operationName');

      final result = await ErrorHandlingService.executeWithCircuitBreaker<T>(
        operation,
        operationName: operationName,
        failureThreshold: failureThreshold,
        timeout: timeout,
      );

      LoggingService.success('Circuit breaker operation completed: $operationName');
      return result;

    } on CircuitBreakerOpenException catch (e, stackTrace) {
      LoggingService.warning(
        'Circuit breaker open: $operationName',
        context: {'failureThreshold': failureThreshold},
      );

      if (showDialog && context != null && context.mounted) {
        await ErrorDialog.showWarning(
          context,
          title: 'Service Temporarily Unavailable',
          message: ErrorHandlingService.getUserFriendlyMessage(e),
        );
      }

      rethrow;

    } on Exception catch (e, stackTrace) {
      LoggingService.error(
        'Circuit breaker operation failed: $operationName',
        error: e,
        stackTrace: stackTrace,
      );

      if (showDialog && context != null && context.mounted) {
        await _showErrorDialog(context, operationName, e);
      }

      rethrow;
    }
  }

  /// Handle error with logging and optional dialog
  ///
  /// Use this for errors that don't need retry logic
  static Future<void> handleError(
    Exception error,
    StackTrace stackTrace, {
    required String operationName,
    BuildContext? context,
    bool showDialog = true,
    Map<String, dynamic>? additionalContext,
  }) async {
    LoggingService.error(
      operationName,
      error: error,
      stackTrace: stackTrace,
      context: additionalContext,
    );

    if (showDialog && context != null && context.mounted) {
      await _showErrorDialog(context, operationName, error);
    }
  }

  /// Show error dialog with user-friendly message
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String operationName,
    required Exception error,
    VoidCallback? onRetry,
  }) async {
    if (!context.mounted) return;

    final userMessage = ErrorHandlingService.getUserFriendlyMessage(error);

    await ErrorDialog.show(
      context,
      title: 'Error',
      message: userMessage,
      onRetry: onRetry,
    );
  }

  /// Log error and rethrow (useful in catch blocks when you want to log but not handle)
  static Never logAndRethrow(
    Exception error,
    StackTrace stackTrace, {
    required String operationName,
    Map<String, dynamic>? context,
  }) {
    LoggingService.error(
      operationName,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    throw error;
  }

  /// Internal method to show error dialog
  static Future<void> _showErrorDialog(
    BuildContext context,
    String operationName,
    Exception error,
  ) async {
    if (!context.mounted) return;

    final userMessage = ErrorHandlingService.getUserFriendlyMessage(error);

    await ErrorDialog.show(
      context,
      title: 'Error',
      message: userMessage,
    );
  }

  /// Get user-friendly error message (without showing dialog)
  static String getUserFriendlyMessage(Exception error) {
    return ErrorHandlingService.getUserFriendlyMessage(error);
  }

  /// Check if an error is retryable
  static bool isRetryable(Exception error) {
    return ErrorHandlingService.isRetryableError(error);
  }
}

/// Extension for easier error handling from any class
extension ErrorHandlerExtension on Object {
  /// Handle error with automatic logging
  Future<void> handleError(
    Exception error,
    StackTrace stackTrace, {
    String? operationName,
    BuildContext? context,
    bool showDialog = true,
    Map<String, dynamic>? additionalContext,
  }) async {
    await ErrorHandler.handleError(
      error,
      stackTrace,
      operationName: operationName ?? runtimeType.toString(),
      context: context,
      showDialog: showDialog,
      additionalContext: additionalContext,
    );
  }
}
