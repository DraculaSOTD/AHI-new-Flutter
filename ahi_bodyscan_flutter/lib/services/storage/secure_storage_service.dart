import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/services/logging_service.dart';

/// Secure storage service for authentication tokens and sensitive data
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainItemAccessibility.first_unlock_this_device,
    ),
  );

  // Keys for different types of stored data
  static const String _authTokenKey = 'ahi_auth_token';
  static const String _accessTokenKey = 'vastmindz_access_token';
  static const String _userCredentialsKey = 'user_credentials';
  static const String _scanHistoryKey = 'scan_history';

  /// Store authentication token securely
  static Future<void> storeAuthToken(String token) async {
    try {
      await _storage.write(key: _authTokenKey, value: token);
      LoggingService.debug('Auth token stored securely', tag: 'SecureStorage');
    } catch (e) {
      LoggingService.error('Failed to store auth token', error: e, tag: 'SecureStorage');
      rethrow;
    }
  }

  /// Retrieve authentication token
  static Future<String?> getAuthToken() async {
    try {
      final token = await _storage.read(key: _authTokenKey);
      if (token != null) {
        LoggingService.debug('Auth token retrieved', tag: 'SecureStorage');
      }
      return token;
    } catch (e) {
      LoggingService.error('Failed to retrieve auth token', error: e, tag: 'SecureStorage');
      return null;
    }
  }

  /// Store VastMindz access token
  static Future<void> storeAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      LoggingService.debug('Access token stored securely', tag: 'SecureStorage');
    } catch (e) {
      LoggingService.error('Failed to store access token', error: e, tag: 'SecureStorage');
      rethrow;
    }
  }

  /// Retrieve VastMindz access token
  static Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token != null) {
        LoggingService.debug('Access token retrieved', tag: 'SecureStorage');
      }
      return token;
    } catch (e) {
      LoggingService.error('Failed to retrieve access token', error: e, tag: 'SecureStorage');
      return null;
    }
  }

  /// Store user credentials
  static Future<void> storeUserCredentials(Map<String, dynamic> credentials) async {
    try {
      final jsonString = jsonEncode(credentials);
      await _storage.write(key: _userCredentialsKey, value: jsonString);
      LoggingService.debug('User credentials stored securely', tag: 'SecureStorage');
    } catch (e) {
      LoggingService.error('Failed to store user credentials', error: e, tag: 'SecureStorage');
      rethrow;
    }
  }

  /// Retrieve user credentials
  static Future<Map<String, dynamic>?> getUserCredentials() async {
    try {
      final jsonString = await _storage.read(key: _userCredentialsKey);
      if (jsonString != null) {
        LoggingService.debug('User credentials retrieved', tag: 'SecureStorage');
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      LoggingService.error('Failed to retrieve user credentials', error: e, tag: 'SecureStorage');
      return null;
    }
  }

  /// Store scan history (encrypted)
  static Future<void> storeScanHistory(List<Map<String, dynamic>> scanHistory) async {
    try {
      final jsonString = jsonEncode(scanHistory);
      await _storage.write(key: _scanHistoryKey, value: jsonString);
      LoggingService.debug('Scan history stored securely', tag: 'SecureStorage', context: {'count': scanHistory.length});
    } catch (e) {
      LoggingService.error('Failed to store scan history', error: e, tag: 'SecureStorage');
      rethrow;
    }
  }

  /// Retrieve scan history
  static Future<List<Map<String, dynamic>>> getScanHistory() async {
    try {
      final jsonString = await _storage.read(key: _scanHistoryKey);
      if (jsonString != null) {
        final history = jsonDecode(jsonString) as List;
        LoggingService.debug('Scan history retrieved', tag: 'SecureStorage', context: {'count': history.length});
        return history.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      LoggingService.error('Failed to retrieve scan history', error: e, tag: 'SecureStorage');
      return [];
    }
  }

  /// Clear specific data type
  static Future<void> clearAuthToken() async {
    try {
      await _storage.delete(key: _authTokenKey);
      LoggingService.info('Auth token cleared', tag: 'SecureStorage');
    } catch (e) {
      LoggingService.error('Failed to clear auth token', error: e, tag: 'SecureStorage');
    }
  }

  static Future<void> clearAccessToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      LoggingService.info('Access token cleared', tag: 'SecureStorage');
    } catch (e) {
      LoggingService.error('Failed to clear access token', error: e, tag: 'SecureStorage');
    }
  }

  static Future<void> clearUserCredentials() async {
    try {
      await _storage.delete(key: _userCredentialsKey);
      LoggingService.info('User credentials cleared', tag: 'SecureStorage');
    } catch (e) {
      LoggingService.error('Failed to clear user credentials', error: e, tag: 'SecureStorage');
    }
  }

  static Future<void> clearScanHistory() async {
    try {
      await _storage.delete(key: _scanHistoryKey);
      LoggingService.info('Scan history cleared', tag: 'SecureStorage');
    } catch (e) {
      LoggingService.error('Failed to clear scan history', error: e, tag: 'SecureStorage');
    }
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      LoggingService.info('All secure storage cleared', tag: 'SecureStorage');
    } catch (e) {
      LoggingService.error('Failed to clear all storage', error: e, tag: 'SecureStorage');
    }
  }

  /// Check if auth token exists and is valid
  static Future<bool> hasValidAuthToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if access token exists and is valid
  static Future<bool> hasValidAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get all stored keys (for debugging)
  static Future<Map<String, String>> getAllKeys() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      LoggingService.error('Failed to read all keys', error: e, tag: 'SecureStorage');
      return {};
    }
  }

  /// Check storage availability
  static Future<bool> isAvailable() async {
    try {
      await _storage.write(key: 'test_key', value: 'test_value');
      await _storage.delete(key: 'test_key');
      return true;
    } catch (e) {
      LoggingService.error('Secure storage not available', error: e, tag: 'SecureStorage');
      return false;
    }
  }
}

/// Exception for storage-related errors
class SecureStorageException implements Exception {
  final String message;
  final dynamic originalException;

  SecureStorageException(this.message, [this.originalException]);

  @override
  String toString() => 'SecureStorageException: $message';
}