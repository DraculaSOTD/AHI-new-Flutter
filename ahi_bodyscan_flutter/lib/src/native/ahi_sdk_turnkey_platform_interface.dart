//
//  AHI
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ahi_sdk_turnkey_method_channel.dart';

abstract class TkPlatform extends PlatformInterface {
  /// Constructs a TkPlatform.
  TkPlatform() : super(token: _token);

  static final Object _token = Object();

  static TkPlatform _instance = TkMethodChannel();

  /// The default instance of [TkPlatform] to use.
  ///
  /// Defaults to [TkMethodChannel].
  static TkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TkPlatform] when
  /// they register themselves.
  static set instance(TkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> setupMultiScanSDK(String token) {
    throw UnimplementedError('setupMultiScanSDK() has not been implemented.');
  }

  Future<void> authorizeUser(Map<String, dynamic> ahiConfigTokens) {
    throw UnimplementedError('authorizeUser() has not been implemented.');
  }

  Future<bool> getUserAuthorizedState() {
    throw UnimplementedError('getUserAuthorizedState() has not been implemented.');
  }

  Future<bool> areAHIResourcesAvailable() {
    throw UnimplementedError(
        'areAHIResourcesAvailable() has not been implemented.');
  }

  Future<bool> downloadAHIResources() {
    throw UnimplementedError(
        'downloadAHIResources() has not been implemented.');
  }

  Future<List<int>> checkAHIResourcesDownloadSize() {
    throw UnimplementedError(
        'checkAHIResourcesDownloadSize() has not been implemented.');
  }

  Future<bool> requestCameraPermissions() {
    throw UnimplementedError(
        'requestCameraPermissions() has not been implemented.');
  }

  Future<Map<String, dynamic>> startFaceScan(Map<String, dynamic> options) {
    throw UnimplementedError('startFaceScan() has not been implemented.');
  }

  Future<Map<String, dynamic>> startFingerScan(Map<String, dynamic> options) {
    throw UnimplementedError('startFingerScan() has not been implemented.');
  }

  Future<Map<String, dynamic>> startBodyScan(Map<String, dynamic> options) {
    throw UnimplementedError('startBodyScan() has not been implemented.');
  }

  Future<Map<String, dynamic>> getBodyScanExtras(Map<String, dynamic> result) {
    throw UnimplementedError('getBodyScanExtras() has not been implemented.');
  }

  Future<void> overrideFingerFeatures(Map<String, dynamic> features) {
    throw UnimplementedError(
        'overrideFingerFeatures() has not been implemented.');
  }

  Future<void> overrideFaceFeatures(Map<String, dynamic> features) {
    throw UnimplementedError(
        'overrideFaceFeatures() has not been implemented.');
  }

  Future<void> overrideBodyFeatures(Map<String, dynamic> features) {
    throw UnimplementedError(
        'overrideBodyFeatures() has not been implemented.');
  }

  Future<void> overrideMultiFeatures(Map<String, dynamic> features) {
    throw UnimplementedError(
        'overrideMultiFeatures() has not been implemented.');
  }

  Future<String> getMultiScanStatus() {
    throw UnimplementedError('getMultiScanStatus() has not been implemented.');
  }

  Future<dynamic> getMultiScanDetails() {
    throw UnimplementedError('getMultiScanDetails() has not been implemented.');
  }

  Future<void> deauthorizeUser() {
    throw UnimplementedError('deauthorizeUser() has not been implemented.');
  }

  Future<Error?> releaseMultiScanSDK() {
    throw UnimplementedError('releaseMultiScanSDK() has not been implemented.');
  }

  Future<void> setMultiScanPersistenceDelegate(
      List<Map<String, dynamic>> result) {
    throw UnimplementedError(
        'setMultiScanPersistenceDelegate() has not been implemented.');
  }

  Future<void> dismissView() {
    throw UnimplementedError('dismissView() has not been implemented.');
  }
}