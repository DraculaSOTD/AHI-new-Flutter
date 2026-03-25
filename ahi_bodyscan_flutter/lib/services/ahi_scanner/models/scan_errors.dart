/// Exception class for AHI Scanner errors
class AHIScanError implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const AHIScanError({
    required this.code,
    required this.message,
    this.details,
  });

  /// Common error codes
  static const String notInitialized = 'NOT_INITIALIZED';
  static const String resourcesNotReady = 'RESOURCES_NOT_READY';
  static const String userCancelled = 'USER_CANCELLED';
  static const String cameraPermissionDenied = 'CAMERA_PERMISSION_DENIED';
  static const String initFailed = 'INIT_FAILED';
  static const String downloadFailed = 'DOWNLOAD_FAILED';
  static const String scanFailed = 'SCAN_FAILED';
  static const String invalidInput = 'INVALID_INPUT';
  static const String networkError = 'NETWORK_ERROR';
  static const String timeoutError = 'TIMEOUT_ERROR';
  static const String unknownError = 'UNKNOWN_ERROR';

  /// Create error from platform exception
  factory AHIScanError.fromPlatformException(Exception e) {
    if (e.toString().contains('USER_CANCELLED')) {
      return const AHIScanError(
        code: userCancelled,
        message: 'Scan cancelled by user',
      );
    }
    
    if (e.toString().contains('CAMERA')) {
      return const AHIScanError(
        code: cameraPermissionDenied,
        message: 'Camera permission required for scanning',
      );
    }
    
    if (e.toString().contains('TIMEOUT')) {
      return const AHIScanError(
        code: timeoutError,
        message: 'Scan operation timed out',
      );
    }
    
    return AHIScanError(
      code: unknownError,
      message: 'An unexpected error occurred: ${e.toString()}',
      details: e,
    );
  }

  /// Check if error is recoverable
  bool get isRecoverable {
    switch (code) {
      case userCancelled:
      case cameraPermissionDenied:
      case networkError:
      case timeoutError:
        return true;
      case initFailed:
      case resourcesNotReady:
      case notInitialized:
        return false;
      default:
        return true; // Assume recoverable by default
    }
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (code) {
      case notInitialized:
        return 'Scanner not initialized. Please restart the app.';
      case resourcesNotReady:
        return 'Scanner resources not ready. Please check your internet connection and try again.';
      case userCancelled:
        return 'Scan was cancelled.';
      case cameraPermissionDenied:
        return 'Camera permission is required to perform scans. Please grant permission in settings.';
      case initFailed:
        return 'Failed to initialize scanner. Please check your internet connection and try again.';
      case downloadFailed:
        return 'Failed to download scanner resources. Please check your internet connection.';
      case scanFailed:
        return 'Scan failed. Please try again or contact support if the problem persists.';
      case invalidInput:
        return 'Invalid input provided. Please check your information and try again.';
      case networkError:
        return 'Network error occurred. Please check your internet connection and try again.';
      case timeoutError:
        return 'Scan timed out. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get suggested action for error
  String get suggestedAction {
    switch (code) {
      case notInitialized:
        return 'Restart the application';
      case resourcesNotReady:
        return 'Check internet connection and retry download';
      case userCancelled:
        return 'Tap to start scan again';
      case cameraPermissionDenied:
        return 'Go to Settings → Privacy → Camera';
      case initFailed:
        return 'Check internet connection and restart app';
      case downloadFailed:
        return 'Check internet connection and retry';
      case scanFailed:
        return 'Try scanning again or contact support';
      case invalidInput:
        return 'Verify your information and retry';
      case networkError:
        return 'Check internet connection and retry';
      case timeoutError:
        return 'Try scanning again';
      default:
        return 'Try again or contact support';
    }
  }

  @override
  String toString() {
    return 'AHIScanError(code: $code, message: $message${details != null ? ', details: $details' : ''})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AHIScanError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => code.hashCode ^ message.hashCode;
}

/// Error result wrapper for scan operations
class ScanErrorResult<T> {
  final T? data;
  final AHIScanError? error;
  final bool isSuccess;

  const ScanErrorResult._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Create successful result
  factory ScanErrorResult.success(T data) {
    return ScanErrorResult._(
      data: data,
      isSuccess: true,
    );
  }

  /// Create error result
  factory ScanErrorResult.error(AHIScanError error) {
    return ScanErrorResult._(
      error: error,
      isSuccess: false,
    );
  }

  /// Get data or throw error
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ?? const AHIScanError(
      code: AHIScanError.unknownError,
      message: 'Unknown error occurred',
    );
  }

  /// Map result to different type
  ScanErrorResult<R> map<R>(R Function(T) transform) {
    if (isSuccess && data != null) {
      return ScanErrorResult.success(transform(data!));
    }
    return ScanErrorResult.error(error!);
  }

  /// Handle result with callbacks
  R when<R>({
    required R Function(T data) success,
    required R Function(AHIScanError error) error,
  }) {
    if (isSuccess && data != null) {
      return success(data!);
    }
    return error(this.error!);
  }
}