//
//  AHI Multi-Scan Bridge
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge for communicating with the AHI native SDK
class TkMultiScanBridge {
  static const MethodChannel _methodChannel = MethodChannel('ahi_sdk_turnkey');
  static TkMultiScanBridge? _instance;

  /// Singleton access to the bridge
  static TkMultiScanBridge get instance {
    _instance ??= TkMultiScanBridge._();
    return _instance!;
  }

  TkMultiScanBridge._();

  /// Setup the multi-scan SDK with token
  Future<void> setupMultiScanSDK(String token) async {
    try {
      await _methodChannel.invokeMethod('setupMultiScanSDK', token);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.setupMultiScanSDK error: $e');
      }
      rethrow;
    }
  }

  /// Authorize user with AHI config tokens
  Future<void> authorizeUser(Map<String, dynamic> ahiConfigTokens) async {
    try {
      await _methodChannel.invokeMethod('authorizeUser', ahiConfigTokens);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.authorizeUser error: $e');
      }
      rethrow;
    }
  }

  /// Check if user is authorized
  Future<bool> getUserAuthorizedState() async {
    try {
      return await _methodChannel.invokeMethod('getUserAuthorizedState') as bool;
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.getUserAuthorizedState error: $e');
      }
      return false;
    }
  }

  /// Check if AHI resources are available
  Future<bool> areAHIResourcesAvailable() async {
    try {
      return await _methodChannel.invokeMethod('areAHIResourcesAvailable') as bool;
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.areAHIResourcesAvailable error: $e');
      }
      return false;
    }
  }

  /// Download AHI resources
  Future<bool> downloadAHIResources() async {
    try {
      return await _methodChannel.invokeMethod('downloadAHIResources') as bool;
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.downloadAHIResources error: $e');
      }
      rethrow;
    }
  }

  /// Check AHI resources download size
  Future<List<int>> checkAHIResourcesDownloadSize() async {
    try {
      final List<dynamic> result = await _methodChannel
          .invokeMethod('checkAHIResourcesDownloadSize') as List<dynamic>;
      return result.map((dynamic e) => int.parse(e.toString())).toList();
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.checkAHIResourcesDownloadSize error: $e');
      }
      return [];
    }
  }

  /// Request camera permissions
  Future<bool> requestCameraPermissions() async {
    try {
      return await _methodChannel.invokeMethod('requestCameraPermissions') as bool;
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.requestCameraPermissions error: $e');
      }
      return false;
    }
  }

  /// Start face scan with options
  Future<Map<String, dynamic>> startFaceScan(Map<String, dynamic> options) async {
    try {
      final dynamic result = await _methodChannel.invokeMethod('startFaceScan', options);
      
      if (kDebugMode) {
        print('TkMultiScanBridge.startFaceScan result: $result');
      }
      
      if (result == null) {
        throw Exception('Face scan returned null result');
      }
      
      return Map<String, dynamic>.from(result as Map<dynamic, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.startFaceScan error: $e');
      }
      rethrow;
    }
  }

  /// Start finger scan with options
  Future<Map<String, dynamic>> startFingerScan(Map<String, dynamic> options) async {
    try {
      final dynamic result = await _methodChannel.invokeMethod('startFingerScan', options);
      
      if (kDebugMode) {
        print('TkMultiScanBridge.startFingerScan result: $result');
      }
      
      if (result == null) {
        throw Exception('Finger scan returned null result');
      }
      
      return Map<String, dynamic>.from(result as Map<dynamic, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.startFingerScan error: $e');
      }
      rethrow;
    }
  }

  /// Start body scan with options
  Future<Map<String, dynamic>> startBodyScan(Map<String, dynamic> options) async {
    try {
      final dynamic result = await _methodChannel.invokeMethod('startBodyScan', options);
      
      if (kDebugMode) {
        print('TkMultiScanBridge.startBodyScan result: $result');
      }
      
      if (result == null) {
        throw Exception('Body scan returned null result');
      }
      
      return Map<String, dynamic>.from(result as Map<dynamic, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.startBodyScan error: $e');
      }
      rethrow;
    }
  }

  /// Get body scan extras
  Future<Map<String, dynamic>> getBodyScanExtras(Map<String, dynamic> result) async {
    try {
      final dynamic extras = await _methodChannel.invokeMethod('getBodyScanExtras', result);
      
      if (kDebugMode) {
        print('TkMultiScanBridge.getBodyScanExtras result: $extras');
      }
      
      if (extras == null) {
        throw Exception('Body scan extras returned null result');
      }
      
      return Map<String, dynamic>.from(extras as Map<dynamic, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.getBodyScanExtras error: $e');
      }
      rethrow;
    }
  }

  /// Override finger features
  Future<void> overrideFingerFeatures(Map<String, dynamic> features) async {
    try {
      await _methodChannel.invokeMethod('overrideFingerFeatures', features);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.overrideFingerFeatures error: $e');
      }
      rethrow;
    }
  }

  /// Override face features
  Future<void> overrideFaceFeatures(Map<String, dynamic> features) async {
    try {
      await _methodChannel.invokeMethod('overrideFaceFeatures', features);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.overrideFaceFeatures error: $e');
      }
      rethrow;
    }
  }

  /// Override body features
  Future<void> overrideBodyFeatures(Map<String, dynamic> features) async {
    try {
      await _methodChannel.invokeMethod('overrideBodyFeatures', features);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.overrideBodyFeatures error: $e');
      }
      rethrow;
    }
  }

  /// Override multi features
  Future<void> overrideMultiFeatures(Map<String, dynamic> features) async {
    try {
      await _methodChannel.invokeMethod('overrideMultiFeatures', features);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.overrideMultiFeatures error: $e');
      }
      rethrow;
    }
  }

  /// Get multi scan status
  Future<String> getMultiScanStatus() async {
    try {
      return await _methodChannel.invokeMethod('getMultiScanStatus') as String;
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.getMultiScanStatus error: $e');
      }
      return 'unknown';
    }
  }

  /// Get multi scan details
  Future<dynamic> getMultiScanDetails() async {
    try {
      return await _methodChannel.invokeMethod('getMultiScanDetails');
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.getMultiScanDetails error: $e');
      }
      return null;
    }
  }

  /// Deauthorize user
  Future<void> deauthorizeUser() async {
    try {
      await _methodChannel.invokeMethod('deauthorizeUser');
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.deauthorizeUser error: $e');
      }
      rethrow;
    }
  }

  /// Release multi scan SDK
  Future<Error?> releaseMultiScanSDK() async {
    try {
      return await _methodChannel.invokeMethod('releaseMultiScanSDK');
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.releaseMultiScanSDK error: $e');
      }
      return Error();
    }
  }

  /// Set multi scan persistence delegate
  Future<void> setMultiScanPersistenceDelegate(List<Map<String, dynamic>> result) async {
    try {
      await _methodChannel.invokeMethod('setMultiScanPersistenceDelegate', result);
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.setMultiScanPersistenceDelegate error: $e');
      }
      rethrow;
    }
  }

  /// Dismiss view
  Future<void> dismissView() async {
    try {
      await _methodChannel.invokeMethod('dismissView');
    } catch (e) {
      if (kDebugMode) {
        print('TkMultiScanBridge.dismissView error: $e');
      }
      rethrow;
    }
  }
}