import '../../src/ahi_sdk_turnkey.dart';
import '../config/app_config.dart';
import 'logging_service.dart';

/// Service to initialize AHI Native SDK
class AHISDKService {
  static bool _isInitialized = false;
  static bool _isAuthorized = false;
  static bool _resourcesReady = false;
  
  /// Initialize the native AHI SDK
  static Future<void> initializeSDK() async {
    try {
      LoggingService.info('Initializing AHI Native SDK', tag: 'AHISDKService');

      // Setup the MultiScan SDK with token from configuration
      final token = AppConfig.ahiSDKToken;
      LoggingService.info('Using AHI SDK token from environment configuration', tag: 'AHISDKService');
      await AHITurnkey.instance.setup(token);
      _isInitialized = true;

      LoggingService.success('AHI Native SDK initialized successfully', tag: 'AHISDKService');

      // Check if resources are available
      await checkResources();

      LoggingService.success('AHI Native SDK ready for scanning', tag: 'AHISDKService');

    } catch (e, stackTrace) {
      LoggingService.error(
        'Failed to initialize AHI Native SDK',
        error: e,
        stackTrace: stackTrace,
        tag: 'AHISDKService',
      );
      rethrow;
    }
  }
  
  /// Check and download resources if needed
  static Future<void> checkResources() async {
    try {
      LoggingService.info('Checking AHI resources', tag: 'AHISDKService');

      final available = await AHITurnkey.instance.areResourcesAvailable();

      if (!available) {
        LoggingService.info('Downloading AHI resources', tag: 'AHISDKService');

        // Get resource size info
        final sizeInfo = await AHITurnkey.instance.checkResourcesDownloadSize();
        final downloadedBytes = sizeInfo[0];
        final totalBytes = sizeInfo[1];

        LoggingService.debug(
          'Resource download size information',
          tag: 'AHISDKService',
          context: {
            'downloaded_mb': (downloadedBytes / (1024 * 1024)).toStringAsFixed(2),
            'total_mb': (totalBytes / (1024 * 1024)).toStringAsFixed(2),
          },
        );

        // Start download
        final downloadSuccess = await AHITurnkey.instance.downloadResources();

        if (downloadSuccess) {
          LoggingService.success('AHI resources downloaded successfully', tag: 'AHISDKService');
          _resourcesReady = true;
        } else {
          LoggingService.error('Failed to download AHI resources', tag: 'AHISDKService');
        }
      } else {
        LoggingService.success('AHI resources already available', tag: 'AHISDKService');
        _resourcesReady = true;
      }
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error checking AHI resources',
        error: e,
        stackTrace: stackTrace,
        tag: 'AHISDKService',
      );
      _resourcesReady = false;
    }
  }
  
  /// Authorize user for scanning
  static Future<void> authorizeUser({
    required String userId,
    required String salt,
    required String userEmail,
    required List<String> claims,
  }) async {
    try {
      LoggingService.info(
        'Authorizing user for AHI services',
        tag: 'AHISDKService',
        context: {'userId': userId, 'claimCount': claims.length},
      );

      await AHITurnkey.instance.authorizeUser(userId, salt, userEmail, claims);
      _isAuthorized = true;

      LoggingService.success('User authorized successfully', tag: 'AHISDKService');
    } catch (e, stackTrace) {
      LoggingService.error(
        'Failed to authorize user',
        error: e,
        stackTrace: stackTrace,
        tag: 'AHISDKService',
      );
      rethrow;
    }
  }
  
  /// Deauthorize user
  static Future<void> deauthorizeUser() async {
    try {
      await AHITurnkey.instance.deauthorizeUser();
      _isAuthorized = false;
      LoggingService.success('User deauthorized', tag: 'AHISDKService');
    } catch (e, stackTrace) {
      LoggingService.error(
        'Failed to deauthorize user',
        error: e,
        stackTrace: stackTrace,
        tag: 'AHISDKService',
      );
      rethrow;
    }
  }
  
  /// Get SDK status
  static Future<String> getStatus() async {
    try {
      return await AHITurnkey.instance.getStatus();
    } catch (e) {
      return 'Error: $e';
    }
  }
  
  /// Check if user is authorized
  static Future<bool> isUserAuthorized() async {
    try {
      return await AHITurnkey.instance.getUserAuthorizedState();
    } catch (e) {
      return false;
    }
  }
  
  /// Release SDK
  static Future<void> release() async {
    try {
      await AHITurnkey.instance.release();
      _isInitialized = false;
      _isAuthorized = false;
      _resourcesReady = false;
      LoggingService.success('AHI SDK released', tag: 'AHISDKService');
    } catch (e, stackTrace) {
      LoggingService.error(
        'Failed to release AHI SDK',
        error: e,
        stackTrace: stackTrace,
        tag: 'AHISDKService',
      );
    }
  }
  
  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isAuthorized => _isAuthorized;
  static bool get resourcesReady => _resourcesReady;
  static bool get isReady => _isInitialized && _resourcesReady;
  
  static String get statusMessage {
    if (!_isInitialized) {
      return 'SDK not initialized';
    }
    if (!_resourcesReady) {
      return 'Resources not ready';
    }
    if (!_isAuthorized) {
      return 'User not authorized';
    }
    return 'Ready for scanning';
  }
}