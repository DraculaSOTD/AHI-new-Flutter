//
//  AHI SDK Configuration - Manages SDK initialization and authentication
//
//  Copyright (c) AHI. All rights reserved.
//

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ahi_turnkey_bridge/tk_multiscan_bridge.dart';

class AHISDKConfig {
  static final AHISDKConfig _instance = AHISDKConfig._internal();
  factory AHISDKConfig() => _instance;
  AHISDKConfig._internal();

  bool _isInitialized = false;
  bool _isAuthorized = false;
  String? _currentToken;
  
  // AHI SDK Configuration - DataPulseTest1
  // VID: 003b7355, AID: 30e36a53
  static const String _vendorId = '003b7355';
  static const String _applicationId = '30e36a53';
  static const String _secretKey = '2L6tXoTbDufflebBtTr54g==';

  // JWT Token for SDK authentication - Updated with MainActivity.kt token
  // Token expires: September 27, 2029 at 2:35:56 PM UTC (Unix: 1882673356)
  static const String _defaultToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJoUDI1NmoxQW1rY0dVbXpuNStSaFc0cEJyOHNiN004bnRUQU5VSmk3UDF0RmJ4UUFMVVhvNEcxRWVnN20zQUd3NXJnVm5MdFV1M1VUaGV5UW5WbFpuOThpZWlmblFSR05kUHVpMFM5OUpmYjIva0NodHFGRTFSUjh4TEF6ZDBKaVBpUEQ1TEtDblNNZEVHUWhBUGZTbXBETHNBZWd3Q1JkQVVGR1lNRENFZlhIRGlqcVpWSUwzUmlnbGtTQk82Ty9xV1oyOUFyNUlTUVA0d3Y5MW9rKzU5eFFDV08wWVVQMEVQMnJXNFhicVg2dzBDSjNNMTFiQnN1V1daSDFMcGh1dmgyS2cwVjYycW5lUGIzZjQ3WDhzZ1NoWmNyU1hWTUFsVGQ0SC9HZjczZDRUbyt2b0huOThCbmFmOW55RmtiN29oWlVjb3hreGNhR0ExcmFVdEtES1hVRDdOYTlnSzR2dmpNVUk5N25JYXNyZmZ1MWVGdmpUZ1ZvTWNtWTVuN2tzN0E5c09reGhpNGlJMnpqN2JhVjhMS0ZiMitvdFFqa2F3a1VkTDRla3l0eGNCeGdPTmJ1d1d1Ukc5aVdCYWZHNm9KcDM4V2t4SFRhUDdFbmpxWFRSS0t3Nmo4bnloUVZ4c2E2R0ZGQlUzeHM2V3Q1UVQyNmhnOVFHb0dXakVreVBaa2NqczJUSEY3eDdCckhjMzg2Z1ZpZk5tOUpLM3FFV0pnOGIrdXJzSzdpczJaUmhPcG1WN1NBaCs2eHBaVjJiUHBVRzc5WXN6SkZpSzk1V0ozdWNlb21SNUZyMXZRbWR3dFIyWEphMlFPVk8vajlFeERPK3NEeHBxOGtnM2FMT0lxNmQ0Q3p5ZTZLZ2VwZFUvb1p2QjRtMHRSWmpZY3dJWXhta0Y2Qk1iOD0iLCJleHAiOjE4ODI2NzMzNTYsInZlciI6MywiYWlkIjoiYmUzNThlODIifQ.K_DywwafwPO2g4QxOlVz17NO_E1GklCw8X1woeiiKUnEdRYBtubSUSjT2nKh7RBna6RQEGSyS6ny4jAs7mYOElUc0Q4Qh61zj5_C3eaKwRC2mhkb6anMW69QslvCy_HbNec9tpCWHfWsR5DPBLyXfiLF96qHvwfgnAZoCO-sP0gkzbyRWBts-KBuGDmDobVIAHn4XUkj6ibLkDRCY069LpPVyFXIu6s-TF6kZ_349cwIHMUxuNUsB-D_qW6L01jrjUmDzDgfgPfny1fzB7qi4I0cl69nwGCZkusbk49quEegGmeK3TIJrQEFNvBTXukyP8AGUmUWHCijrdl8QM8Cjl2t0PBKbjqEP32V_2di3s73RtdigRftQ8gOv1JjwDAt0NQxMyWw2kiYxUyv8khJBJQ5RJILt9Vn_1G71PAa888CmpjCWO0DIwCq6oKCoDPks1Ucyb3mtd1aedl9oRwBs123swZZmeBQQGB3QY3-LhvV97ZzS3RTobeD-1oZljJIQefOJ6nlzcPuKR2aLnSp7HweqC4BmoaYlFLG_QY9VzZzKWVtZkYYajCR07DbLi0bAKcjAPe2Be8nGqTUyHn8yrYvf3LeUcXukCafW8qMHaetPIvsv1C0aumeXtmK7gdN_G35H6Jg8R27zcVZpkQmUCW5z2p41FvXlsA2QN3yUkA';

  // Test user configuration
  static const String _testUserId = 'datapulsetest1';
  static const String _testUserSalt = 'test-user-salt-datapulse';
  static const Map<String, dynamic> _testUserClaims = {
    'sub': _testUserId,
    'vid': _vendorId,
    'aid': _applicationId,
    'iat': 1234567890,
    'exp': 1762366060, // Token expiration from JWT
  };

  /// Initialize the AHI SDK
  Future<bool> initialize({String? token}) async {
    if (_isInitialized) {
      return true;
    }

    try {
      final sdkToken = token ?? _getSDKToken();
      
      if (kDebugMode) {
        print('AHI SDK: Initializing with token: ${sdkToken.substring(0, 10)}...');
      }

      await TkMultiScanBridge.instance.setupMultiScanSDK(sdkToken);
      _currentToken = sdkToken;
      _isInitialized = true;
      
      if (kDebugMode) {
        print('AHI SDK: Initialization successful');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AHI SDK: Initialization failed: $e');
      }
      return false;
    }
  }

  /// Authorize user with the SDK
  Future<bool> authorizeUser({
    String? userId,
    String? userSalt,
    Map<String, dynamic>? userClaims,
  }) async {
    if (!_isInitialized) {
      throw Exception('SDK must be initialized before user authorization');
    }

    try {
      final authConfig = {
        'userId': userId ?? _testUserId,
        'userSalt': userSalt ?? _testUserSalt,
        'claims': userClaims ?? _testUserClaims,
      };

      if (kDebugMode) {
        print('AHI SDK: Authorizing user: ${authConfig['userId']}');
      }

      await TkMultiScanBridge.instance.authorizeUser(authConfig);
      _isAuthorized = await TkMultiScanBridge.instance.getUserAuthorizedState();
      
      if (kDebugMode) {
        print('AHI SDK: User authorization successful: $_isAuthorized');
      }
      
      return _isAuthorized;
    } catch (e) {
      if (kDebugMode) {
        print('AHI SDK: User authorization failed: $e');
      }
      return false;
    }
  }

  /// Check if resources are available
  Future<bool> checkResourcesAvailable() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      return await TkMultiScanBridge.instance.areAHIResourcesAvailable();
    } catch (e) {
      if (kDebugMode) {
        print('AHI SDK: Resource check failed: $e');
      }
      return false;
    }
  }

  /// Download resources if needed
  Future<bool> downloadResources() async {
    if (!_isInitialized) {
      throw Exception('SDK must be initialized before downloading resources');
    }

    try {
      if (kDebugMode) {
        print('AHI SDK: Starting resource download...');
      }

      final success = await TkMultiScanBridge.instance.downloadAHIResources();
      
      if (kDebugMode) {
        print('AHI SDK: Resource download ${success ? 'successful' : 'failed'}');
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('AHI SDK: Resource download failed: $e');
      }
      return false;
    }
  }

  /// Get resource download size
  Future<List<int>> getResourceDownloadSize() async {
    if (!_isInitialized) {
      return [];
    }

    try {
      return await TkMultiScanBridge.instance.checkAHIResourcesDownloadSize();
    } catch (e) {
      if (kDebugMode) {
        print('AHI SDK: Failed to get download size: $e');
      }
      return [];
    }
  }

  /// Setup SDK with full initialization
  Future<bool> setupSDK({
    String? token,
    String? userId,
    String? userSalt,
    Map<String, dynamic>? userClaims,
  }) async {
    try {
      // Step 1: Initialize SDK
      final initSuccess = await initialize(token: token);
      if (!initSuccess) {
        return false;
      }

      // Step 2: Authorize user
      final authSuccess = await authorizeUser(
        userId: userId,
        userSalt: userSalt,
        userClaims: userClaims,
      );
      if (!authSuccess) {
        return false;
      }

      // Step 3: Check resources
      final resourcesAvailable = await checkResourcesAvailable();
      if (!resourcesAvailable) {
        if (kDebugMode) {
          print('AHI SDK: Resources not available, will need to download');
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AHI SDK: Full setup failed: $e');
      }
      return false;
    }
  }

  /// Deauthorize user
  Future<void> deauthorizeUser() async {
    if (_isInitialized) {
      try {
        await TkMultiScanBridge.instance.deauthorizeUser();
        _isAuthorized = false;
        
        if (kDebugMode) {
          print('AHI SDK: User deauthorized');
        }
      } catch (e) {
        if (kDebugMode) {
          print('AHI SDK: Deauthorization failed: $e');
        }
      }
    }
  }

  /// Release SDK resources
  Future<void> release() async {
    if (_isInitialized) {
      try {
        await TkMultiScanBridge.instance.releaseMultiScanSDK();
        _isInitialized = false;
        _isAuthorized = false;
        _currentToken = null;
        
        if (kDebugMode) {
          print('AHI SDK: SDK released');
        }
      } catch (e) {
        if (kDebugMode) {
          print('AHI SDK: Release failed: $e');
        }
      }
    }
  }

  /// Get SDK token from environment or config
  String _getSDKToken() {
    // In a production app, this would come from:
    // 1. Environment variables
    // 2. Secure storage
    // 3. Server configuration
    // 4. Build-time configuration
    
    const String? envToken = String.fromEnvironment('AHI_SDK_TOKEN');
    if (envToken != null && envToken.isNotEmpty) {
      return envToken;
    }
    
    return _defaultToken;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthorized => _isAuthorized;
  bool get isReady => _isInitialized && _isAuthorized;
  String? get currentToken => _currentToken;
}