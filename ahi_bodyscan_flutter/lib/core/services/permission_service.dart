import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'logging_service.dart';

/// Centralized runtime-permission handling.
///
/// Requests every permission the app needs up front (on first open) instead of
/// lazily at each scan screen. All requests are best-effort: a denied or failed
/// permission must never block app startup — the scan-preparation screens still
/// re-request as a safety net.
class PermissionService {
  /// Request every runtime permission the app needs, in sequence.
  ///
  /// - Camera (all platforms) — face/body scan capture.
  /// - Ignore battery optimizations (Android only) — keeps the OS from killing
  ///   the native scan worker mid-scan on aggressive OEMs.
  ///
  /// Never throws.
  static Future<void> requestStartupPermissions() async {
    await _request(Permission.camera, 'camera');
    if (Platform.isAndroid) {
      await _request(Permission.ignoreBatteryOptimizations, 'batteryOptimization');
    }
  }

  /// Check-then-request a single permission. No dialog is shown if it's already
  /// granted (or permanently denied). Swallows and logs any error.
  static Future<void> _request(Permission p, String label) async {
    try {
      final status = await p.status;
      if (!status.isGranted) {
        await p.request();
      }
      final result = await p.status;
      LoggingService.info(
        'Startup permission',
        tag: 'PermissionService',
        context: {'permission': label, 'status': result.toString()},
      );
    } catch (e) {
      LoggingService.warning(
        'Startup permission request failed',
        tag: 'PermissionService',
        context: {'permission': label, 'error': e.toString()},
      );
    }
  }
}
