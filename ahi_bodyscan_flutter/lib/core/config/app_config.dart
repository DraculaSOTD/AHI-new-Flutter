import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration service for the app
/// All environment variables and configuration constants are accessed through this class
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// Initialize the configuration by loading environment variables
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }

  /// Check if the app is running in production mode
  static bool get isProduction => environment == 'production';

  /// Check if the app is running in development mode
  static bool get isDevelopment => environment == 'development';

  // ============================================================================
  // Environment
  // ============================================================================

  /// Current environment (development, staging, production)
  static String get environment =>
      dotenv.get('ENVIRONMENT', fallback: 'development');

  // ============================================================================
  // AHI SDK Configuration
  // ============================================================================

  /// AHI SDK authentication token
  static String get ahiSDKToken {
    final token = dotenv.get('AHI_SDK_TOKEN', fallback: '');
    if (token.isEmpty) {
      throw Exception(
        'AHI_SDK_TOKEN is not set in .env file. '
        'Please copy .env.example to .env and fill in the credentials.',
      );
    }
    return token;
  }

  // ============================================================================
  // Vastmindz SDK Configuration
  // ============================================================================

  /// Vastmindz WebSocket URL for face scan
  static String get vastmindzWebSocketURL {
    final url = dotenv.get('VASTMINDZ_WEBSOCKET_URL', fallback: '');
    if (url.isEmpty) {
      throw Exception(
        'VASTMINDZ_WEBSOCKET_URL is not set in .env file. '
        'Please copy .env.example to .env and fill in the credentials.',
      );
    }
    return url;
  }

  /// Vastmindz authentication token
  static String get vastmindzAuthToken {
    final token = dotenv.get('VASTMINDZ_AUTH_TOKEN', fallback: '');
    if (token.isEmpty) {
      throw Exception(
        'VASTMINDZ_AUTH_TOKEN is not set in .env file. '
        'Please copy .env.example to .env and fill in the credentials.',
      );
    }
    return token;
  }

  // ============================================================================
  // App Constants
  // ============================================================================

  /// App name
  static const String appName = 'AHI BodyScan';

  /// App package identifier
  static const String packageId = 'tech.ahi.bodyscan';

  /// Default FPS for video capture
  static const int defaultFPS = 30;

  /// Support email
  static const String supportEmail = 'support@ahi.tech';

  /// Terms of service URL
  static const String termsOfServiceURL = 'https://www.ahi.tech/terms';

  /// Privacy policy URL
  static const String privacyPolicyURL = 'https://www.ahi.tech/privacy';

  // ============================================================================
  // Debug Settings
  // ============================================================================

  /// Enable debug logging
  static bool get enableDebugLogging => !isProduction;

  /// Enable performance monitoring
  static bool get enablePerformanceMonitoring => isProduction;
}
