//
//  AHI
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ahi_sdk_turnkey_platform_interface.dart';

/// An implementation of [TkPlatform] that uses method channels.
class TkMethodChannel extends TkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('ahi_sdk_turnkey');

  @override
  Future<void> setupMultiScanSDK(String token) async {
    return methodChannel.invokeMethod('setupMultiScanSDK', token);
  }

  @override
  Future<void> authorizeUser(Map<String, dynamic> ahiConfigTokens) async {
    return methodChannel.invokeMethod('authorizeUser', ahiConfigTokens);
  }

  @override
  Future<bool> areAHIResourcesAvailable() async {
    return await methodChannel.invokeMethod('areAHIResourcesAvailable') as bool;
  }

  @override
  Future<bool> downloadAHIResources() async {
    return await methodChannel.invokeMethod('downloadAHIResources') as bool;
  }

  @override
  Future<List<int>> checkAHIResourcesDownloadSize() async {
    try {
      final List<dynamic> result = await methodChannel
          .invokeMethod('checkAHIResourcesDownloadSize') as List<dynamic>;
      return result.map((dynamic e) => int.parse(e.toString())).toList();
    } catch (e) {
      return Future.error('Error with AHI resources download: $e');
    }
  }

  @override
  Future<bool> requestCameraPermissions() async {
    return await methodChannel.invokeMethod('requestCameraPermissions') as bool;
  }

  @override
  Future<Map<String, dynamic>> startFaceScan(
      Map<String, dynamic> options) async {
    try {
      final dynamic result =
          await methodChannel.invokeMethod('startFaceScan', options);
      if (kDebugMode) {
        print('startFaceScan result: $result');
      }
      if (result == null) {
        return Future.error('Error face scan return null');
      }
      return Map<String, dynamic>.from(result as Map<dynamic, dynamic>);
    } catch (e) {
      return Future.error('Error with face scan: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> startFingerScan(
      Map<String, dynamic> options) async {
    try {
      final dynamic result =
          await methodChannel.invokeMethod('startFingerScan', options);
      if (kDebugMode) {
        print('startFingerScan result: $result');
      }
      if (result == null) {
        return Future.error('Error finger scan return null');
      }
      return Map<String, dynamic>.from(result as Map<dynamic, dynamic>);
    } catch (e) {
      return Future.error('Error with finger scan: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> startBodyScan(
      Map<String, dynamic> options) async {
    try {
      final dynamic result =
          await methodChannel.invokeMethod('startBodyScan', options);
      if (kDebugMode) {
        print('startBodyScan result: $result');
      }
      if (result == null) {
        return Future.error('Error body scan return null');
      }
      return Map<String, dynamic>.from(result as Map<dynamic, dynamic>);
    } catch (e) {
      return Future.error('Error with body scan: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getBodyScanExtras(
      Map<String, dynamic> result) async {
    try {
      final dynamic extras =
          await methodChannel.invokeMethod('getBodyScanExtras', result);
      if (kDebugMode) {
        print('getBodyScanExtras result: $result');
      }
      if (extras == null) {
        return Future.error('Error body scan extras return null');
      }
      return Map<String, dynamic>.from(extras as Map<dynamic, dynamic>);
    } catch (e) {
      return Future.error('Error with body scan extras: $e');
    }
  }

  @override
  Future<void> overrideFingerFeatures(Map<String, dynamic> features) async {
    return methodChannel.invokeMethod('overrideFingerFeatures', features);
  }

  @override
  Future<void> overrideFaceFeatures(Map<String, dynamic> features) async {
    return methodChannel.invokeMethod('overrideFaceFeatures', features);
  }

  @override
  Future<void> overrideBodyFeatures(Map<String, dynamic> features) async {
    return methodChannel.invokeMethod('overrideBodyFeatures', features);
  }

  @override
  Future<void> overrideMultiFeatures(Map<String, dynamic> features) async {
    return methodChannel.invokeMethod('overrideMultiFeatures', features);
  }

  @override
  Future<dynamic> getMultiScanDetails() async {
    return methodChannel.invokeMethod('getMultiScanDetails');
  }

  @override
  Future<String> getMultiScanStatus() async {
    return await methodChannel.invokeMethod('getMultiScanStatus') as String;
  }

  @override
  Future<void> deauthorizeUser() async {
    return methodChannel.invokeMethod('deauthorizeUser');
  }

  @override
  Future<Error?> releaseMultiScanSDK() async {
    return methodChannel.invokeMethod('releaseMultiScanSDK');
  }

  @override
  Future<void> setMultiScanPersistenceDelegate(
      List<Map<String, dynamic>> result) async {
    return methodChannel.invokeMethod(
        'setMultiScanPersistenceDelegate', result);
  }

  @override
  Future<void> dismissView() async {
    return methodChannel.invokeMethod('dismissView');
  }

  @override
  Future<bool> getUserAuthorizedState() async {
    return await methodChannel.invokeMethod('getUserAuthorizedState') as bool;
  }
}