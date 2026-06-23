import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../main.dart' show kBuildMarker;

/// Centralized logging service for AHI BodyScan Flutter App
///
/// Provides structured logging with different log levels and context.
/// Prepares for future integration with crash reporting (Firebase Crashlytics, Sentry, etc.)
class LoggingService {
  LoggingService._(); // Private constructor

  /// Log levels
  static const String _debugPrefix = '🔍 DEBUG';
  static const String _infoPrefix = 'ℹ️  INFO';
  static const String _warningPrefix = '⚠️  WARNING';
  static const String _errorPrefix = '❌ ERROR';
  static const String _successPrefix = '✅ SUCCESS';

  /// Enable/disable logging (can be toggled based on environment)
  static bool isEnabled = kDebugMode; // Only log in debug mode by default

  /// In-memory ring buffer of recent formatted log lines, kept independent of
  /// [isEnabled] so non-developer testers on release builds can still share
  /// diagnostics. See [writeLogsToTempFile].
  static final List<String> _ringBuffer = <String>[];
  static const int _ringBufferMaxLines = 2000;

  /// Snapshot of every line in the ring buffer joined with newlines.
  static String getBufferedLogs() => _ringBuffer.join('\n');

  /// Writes the in-memory log buffer to a file in the OS temp dir and returns
  /// the file. The Settings screen's "Share diagnostic logs" tile hands this
  /// to share_plus so the user can WhatsApp/Gmail it back to the developer.
  static Future<File> writeLogsToTempFile() async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/ahi-bodyscan-logs.txt');
    final header = [
      'AHI BodyScan diagnostic log',
      'Generated at ${DateTime.now().toIso8601String()}',
      'Build marker: $kBuildMarker',
      '',
    ].join('\n');
    await f.writeAsString('$header${getBufferedLogs()}');
    return f;
  }

  /// Log debug messages (for detailed diagnostic information)
  ///
  /// Example:
  /// ```dart
  /// LoggingService.debug('User tapped scan button', context: {'scanType': 'body'});
  /// ```
  static void debug(String message, {Map<String, dynamic>? context, String? tag}) {
    if (!isEnabled) return;
    _log(_debugPrefix, message, context: context, tag: tag);
  }

  /// Log informational messages (for general information flow)
  ///
  /// Example:
  /// ```dart
  /// LoggingService.info('Scan completed successfully', context: {'duration': '45s'});
  /// ```
  static void info(String message, {Map<String, dynamic>? context, String? tag}) {
    if (!isEnabled) return;
    _log(_infoPrefix, message, context: context, tag: tag);
  }

  /// Log warning messages (for potentially harmful situations)
  ///
  /// Example:
  /// ```dart
  /// LoggingService.warning('Low battery detected', context: {'level': '15%'});
  /// ```
  static void warning(String message, {Map<String, dynamic>? context, String? tag}) {
    if (!isEnabled) return;
    _log(_warningPrefix, message, context: context, tag: tag);
  }

  /// Log error messages (for error events)
  ///
  /// Example:
  /// ```dart
  /// LoggingService.error('SDK initialization failed',
  ///   error: exception,
  ///   stackTrace: stackTrace,
  ///   context: {'sdkVersion': '1.0.0'}
  /// );
  /// ```
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? tag,
  }) {
    if (!isEnabled) return;
    _log(
      _errorPrefix,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      tag: tag,
    );

    // TODO: In production, send to crash reporting service
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
  }

  /// Log success messages (for successful operations)
  ///
  /// Example:
  /// ```dart
  /// LoggingService.success('Profile created successfully', context: {'profileId': 'abc123'});
  /// ```
  static void success(String message, {Map<String, dynamic>? context, String? tag}) {
    if (!isEnabled) return;
    _log(_successPrefix, message, context: context, tag: tag);
  }

  /// Internal logging method
  static void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? tag,
  }) {
    final buffer = StringBuffer();

    // Add level prefix
    buffer.write('$level ');

    // Add tag if provided
    if (tag != null) {
      buffer.write('[$tag] ');
    }

    // Add timestamp
    buffer.write('[${DateTime.now().toIso8601String()}] ');

    // Add message
    buffer.write(message);

    // Add context if provided
    if (context != null && context.isNotEmpty) {
      buffer.write(' | Context: ${_formatContext(context)}');
    }

    // Print the main log message
    final line = buffer.toString();
    debugPrint(line);

    // Push into the ring buffer regardless of debug mode, so a release-build
    // tester can still share recent logs via Settings.
    _ringBuffer.add(line);
    if (_ringBuffer.length > _ringBufferMaxLines) {
      _ringBuffer.removeRange(
          0, _ringBuffer.length - _ringBufferMaxLines);
    }

    // Print error details if provided
    if (error != null) {
      debugPrint('   Error: $error');
    }

    // Print stack trace if provided
    if (stackTrace != null) {
      debugPrint('   Stack Trace:\n$stackTrace');
    }
  }

  /// Format context map for logging
  static String _formatContext(Map<String, dynamic> context) {
    return context.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
  }

  /// Log operation timing
  ///
  /// Example:
  /// ```dart
  /// final stopwatch = LoggingService.startTimer('Scan Operation');
  /// // ... perform operation ...
  /// LoggingService.stopTimer(stopwatch, 'Scan Operation');
  /// ```
  static Stopwatch startTimer(String operationName) {
    debug('Starting: $operationName');
    return Stopwatch()..start();
  }

  /// Stop and log operation timing
  static void stopTimer(Stopwatch stopwatch, String operationName, {Map<String, dynamic>? context}) {
    stopwatch.stop();
    final duration = stopwatch.elapsedMilliseconds;
    info(
      'Completed: $operationName in ${duration}ms',
      context: {...?context, 'duration_ms': duration},
    );
  }

  /// Log a section divider (useful for separating logical blocks in logs)
  static void section(String title) {
    if (!isEnabled) return;
    debugPrint('');
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('  $title');
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('');
  }
}

/// Extension for easier logging from any class
extension LoggableObject on Object {
  /// Get class name for logging tag
  String get logTag => runtimeType.toString();

  /// Log debug message with class name as tag
  void logDebug(String message, {Map<String, dynamic>? context}) {
    LoggingService.debug(message, context: context, tag: logTag);
  }

  /// Log info message with class name as tag
  void logInfo(String message, {Map<String, dynamic>? context}) {
    LoggingService.info(message, context: context, tag: logTag);
  }

  /// Log warning message with class name as tag
  void logWarning(String message, {Map<String, dynamic>? context}) {
    LoggingService.warning(message, context: context, tag: logTag);
  }

  /// Log error message with class name as tag
  void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    LoggingService.error(
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      tag: logTag,
    );
  }

  /// Log success message with class name as tag
  void logSuccess(String message, {Map<String, dynamic>? context}) {
    LoggingService.success(message, context: context, tag: logTag);
  }
}
