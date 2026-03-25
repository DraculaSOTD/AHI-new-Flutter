//
//  AHI SDK Turnkey - Main Interface
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ahi_turnkey_bridge/tk_multiscan_bridge.dart';
import 'models/ahi_user_data.dart';

/// Interface to AHI Turnkey SDK.
class AHITurnkey {
  /// private constructor
  AHITurnkey._() : super() {
    if (kDebugMode) {
      print('INF: New AHI instance created');
    }
  }

  /// The one and only instance of this singleton
  static final AHITurnkey instance = AHITurnkey._();

  String? _userId;
  String? _userEmail;

  /// Setup AHI services.
  ///
  /// Setup must be called prior to calling any other method. The [token] parameter
  /// contains the AHI app token (provided by AHI).
  Future<void> setup(String token) async {
    return TkMultiScanBridge.instance.setupMultiScanSDK(token);
  }

  /// Release the AHI service.
  Future<Error?> release() async {
    return TkMultiScanBridge.instance.releaseMultiScanSDK();
  }

  /// Get the current connection status.
  Future<String> getStatus() async {
    return TkMultiScanBridge.instance.getMultiScanStatus();
  }

  /// Get the current auth status.
  Future<bool> getUserAuthorizedState() async {
    return TkMultiScanBridge.instance.getUserAuthorizedState();
  }

  /// Get the connection details.
  Future<dynamic> getDetails() async {
    return TkMultiScanBridge.instance.getMultiScanDetails();
  }

  /// User authorization to the MultiScan services.
  Future<void> authorizeUser(
      String userId, String salt, String userEmail, List<String> claims) async {
    try {
      final authConfig = {
        'userId': userId,
        'userSalt': salt,
        'claims': claims,
      };
      await TkMultiScanBridge.instance.authorizeUser(authConfig);
      _userId = userId;
      _userEmail = userEmail;
      return Future<void>.value();
    } catch (error) {
      return Future<void>.error(error);
    }
  }

  /// User de-authorization from AHI services.
  Future<void> deauthorizeUser() async {
    try {
      await TkMultiScanBridge.instance.deauthorizeUser();
      _userId = null;
      return Future<void>.value();
    } catch (error) {
      return Future<void>.error(error);
    }
  }

  /// Check if resources are downloaded for AHI services.
  Future<bool> areResourcesAvailable() async {
    return TkMultiScanBridge.instance.areAHIResourcesAvailable();
  }

  /// Request that resources are downloaded.
  Future<bool> downloadResources() async {
    return TkMultiScanBridge.instance.downloadAHIResources();
  }

  /// Return current downloaded size in bytes.
  Future<List<int>> checkResourcesDownloadSize() {
    return TkMultiScanBridge.instance.checkAHIResourcesDownloadSize();
  }

  /// Initiate FingerScan
  Future<Map<String, dynamic>> initiateFingerScan(
      Map<String, dynamic> options) async {
    return TkMultiScanBridge.instance.startFingerScan(options);
  }

  /// Initiate FaceScan
  Future<Map<String, dynamic>> initiateFaceScan(
      Map<String, dynamic> options) async {
    return TkMultiScanBridge.instance.startFaceScan(options);
  }

  /// Initiate BodyScan
  Future<Map<String, dynamic>> initiateBodyScan(
      Map<String, dynamic> options) async {
    return TkMultiScanBridge.instance.startBodyScan(options);
  }

  /// Get BodyScan Extras (3D mesh)
  Future<Map<String, dynamic>> getBodyScanExtras(
      Map<String, dynamic> result) async {
    return TkMultiScanBridge.instance.getBodyScanExtras(result);
  }

  /// Override finger scan features
  Future<void> overrideFingerFeatures(Map<String, dynamic> options) async {
    TkMultiScanBridge.instance.overrideFingerFeatures(options);
  }

  /// Override face scan features
  Future<void> overrideFaceFeatures(Map<String, dynamic> options) async {
    TkMultiScanBridge.instance.overrideFaceFeatures(options);
  }

  /// Override body scan features
  Future<void> overrideBodyFeatures(Map<String, dynamic> options) async {
    TkMultiScanBridge.instance.overrideBodyFeatures(options);
  }

  /// Override multi scan features
  Future<void> overrideMultiFeatures(Map<String, dynamic> options) async {
    TkMultiScanBridge.instance.overrideMultiFeatures(options);
  }

  /// Set MultiScan persistence delegate
  Future<void> setMultiScanPersistenceDelegate(
      List<Map<String, dynamic>> scanHistoriesResults) {
    return TkMultiScanBridge.instance
        .setMultiScanPersistenceDelegate(scanHistoriesResults);
  }

  /// Dismiss current view
  Future<void> dismissView() async {
    return TkMultiScanBridge.instance.dismissView();
  }
}