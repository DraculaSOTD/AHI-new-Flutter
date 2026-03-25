//
//  AHI App Initialization Service - Sets up all AHI services on app start
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/foundation.dart';
import 'ahi_sdk_config.dart';
import 'ahi_audio_service.dart';
import 'ahi_config_service.dart';

class AHIAppInitService {
  static final AHIAppInitService _instance = AHIAppInitService._internal();
  factory AHIAppInitService() => _instance;
  AHIAppInitService._internal();

  bool _isInitialized = false;

  /// Initialize all AHI services
  Future<bool> initializeApp() async {
    if (_isInitialized) {
      return true;
    }

    try {
      if (kDebugMode) {
        print('AHI: Starting app initialization...');
      }

      // Step 1: Initialize SDK configuration
      await _initializeSDK();

      // Step 2: Initialize audio service
      await _initializeAudioService();

      // Step 3: Preload configurations
      await _preloadConfigurations();

      _isInitialized = true;

      if (kDebugMode) {
        print('AHI: App initialization completed successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AHI: App initialization failed: $e');
      }
      return false;
    }
  }

  /// Initialize the AHI SDK
  Future<void> _initializeSDK() async {
    try {
      final sdkConfig = AHISDKConfig();
      
      // Setup SDK with default configuration
      final success = await sdkConfig.setupSDK();
      
      if (success) {
        if (kDebugMode) {
          print('AHI: SDK initialized and authorized');
        }
      } else {
        if (kDebugMode) {
          print('AHI: SDK initialization completed but authorization failed');
          print('AHI: This is normal for development - scans will use mock data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AHI: SDK initialization error: $e');
      }
      // Don't throw - app should still work with mock data
    }
  }

  /// Initialize audio service
  Future<void> _initializeAudioService() async {
    try {
      await AHIAudioService().initialize();
      if (kDebugMode) {
        print('AHI: Audio service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AHI: Audio service initialization failed: $e');
      }
      // Audio is optional, don't fail app startup
    }
  }

  /// Preload essential configurations
  Future<void> _preloadConfigurations() async {
    try {
      await AHIConfigService().preloadEssentialConfigs();
      if (kDebugMode) {
        print('AHI: Configuration preloading completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AHI: Configuration preloading failed: $e');
      }
      // Configurations can be loaded on demand
    }
  }

  /// Cleanup resources when app is disposed
  Future<void> dispose() async {
    try {
      await AHIAudioService().dispose();
      await AHISDKConfig().release();
      AHIConfigService().clearCache();
      
      _isInitialized = false;
      
      if (kDebugMode) {
        print('AHI: App cleanup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AHI: App cleanup error: $e');
      }
    }
  }

  /// Check if app is fully initialized
  bool get isInitialized => _isInitialized;

  /// Get initialization status details
  Map<String, bool> getInitializationStatus() {
    return {
      'appInitialized': _isInitialized,
      'sdkInitialized': AHISDKConfig().isInitialized,
      'sdkAuthorized': AHISDKConfig().isAuthorized,
      'audioAvailable': AHIAudioService().isAudioAvailable,
    };
  }
}