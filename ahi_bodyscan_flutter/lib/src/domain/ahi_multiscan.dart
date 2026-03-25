//
//  AHI
//
//  Copyright (c) AHI. All rights reserved.
//

import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../native/ahi_sdk_turnkey_platform_interface.dart';

/// `TkMultiScanBridge` is a singleton class that provides an interface
/// for interacting with the MultiScan SDK. It includes methods for setting up
/// the SDK, authorizing and deauthorizing users, initiating different types of scans,
/// and managing resources.
class TkMultiScanBridge {
  /// Private constructor used to implement this class as a singleton.
  TkMultiScanBridge._();

  /// the one and only instance of this singleton
  static final TkMultiScanBridge instance = TkMultiScanBridge._();

  /// Configure MultiScan services with the associated App token, as provided to the client by AHI.
  Future<void> setupMultiScanSDK(String token) async {
    return TkPlatform.instance.setupMultiScanSDK(token);
  }

  /// Once successfully setup, authorize user to use the AHI service.
  Future<void> authorizeUser(
      String userId, String salt, List<String> claims) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'user_id': userId,
      'salt': salt,
      'claims': claims
    };
    return TkPlatform.instance.authorizeUser(data);
  }

  /// Deauthorizes the current user from the AHI service.
  Future<void> deauthorizeUser() async {
    return TkPlatform.instance.deauthorizeUser();
  }

  /// Auth state
  Future<bool> getUserAuthorizedState() async {
    return TkPlatform.instance.getUserAuthorizedState();
  }

  /// Returns the current Multiscan status of the user.
  Future<String> getMultiScanStatus() async {
    return TkPlatform.instance.getMultiScanStatus();
  }

  /// Returns the current Multiscan details.
  Future<dynamic> getMultiScanDetails() async {
    return TkPlatform.instance.getMultiScanDetails();
  }

  /// Return bool if AHI resources are available
  Future<bool> areAHIResourcesAvailable() async {
    return TkPlatform.instance.areAHIResourcesAvailable();
  }

  /// Trigger download assets
  Future<bool> downloadAHIResources() async {
    return TkPlatform.instance.downloadAHIResources();
  }

  /// Return current downloaded size
  Future<List<int>> checkAHIResourcesDownloadSize() {
    return TkPlatform.instance.checkAHIResourcesDownloadSize();
  }

  /// Initiate FingerScan
  Future<Map<String, dynamic>> initiateFingerScan(
      Map<String, dynamic> options) async {
    return hasCameraPermission()
        .then((bool value) => TkPlatform.instance.startFingerScan(options));
  }

  /// Initiate FaceScan
  Future<Map<String, dynamic>> initiateFaceScan(
      Map<String, dynamic> options) async {
    return hasCameraPermission()
        .then((bool value) => TkPlatform.instance.startFaceScan(options));
  }

  /// Initiate BodyScan
  Future<Map<String, dynamic>> initiateBodyScan(
      Map<String, dynamic> options) async {
    return hasCameraPermission()
        .then((bool value) => TkPlatform.instance.startBodyScan(options));
  }

  /// BodyScan Extras
  Future<Map<String, dynamic>> getBodyScanExtras(
      Map<String, dynamic> result) async {
    return TkPlatform.instance.getBodyScanExtras(result);
  }

  Future<void> overrideFingerFeatures(Map<String, dynamic> features) async {
    return TkPlatform.instance.overrideFingerFeatures(features);
  }

  Future<void> overrideFaceFeatures(Map<String, dynamic> features) async {
    return TkPlatform.instance.overrideFaceFeatures(features);
  }

  Future<void> overrideBodyFeatures(Map<String, dynamic> features) async {
    return TkPlatform.instance.overrideBodyFeatures(features);
  }

  Future<void> overrideMultiFeatures(Map<String, dynamic> features) async {
    return TkPlatform.instance.overrideMultiFeatures(features);
  }

  /// Resets the MultiScan session and clears all data in memory.
  Future<Error?> releaseMultiScanSDK() async {
    return TkPlatform.instance.releaseMultiScanSDK();
  }

  /// Returns the status of the camera permission.
  Future<bool> hasCameraPermission() async {
    bool isGranted;
    if (Platform.isAndroid) {
      final status = await Permission.camera.status;
      isGranted = status.isGranted;
    } else {
      isGranted = await TkPlatform.instance.requestCameraPermissions();
    }
    return isGranted
        ? Future<bool>.value(true)
        : Future.error('Camera permission not granted');
  }

  /// Set the MultiScan Persistence Delegate.
  Future<void> setMultiScanPersistenceDelegate(
      List<Map<String, dynamic>> result) async {
    return TkPlatform.instance.setMultiScanPersistenceDelegate(result);
  }

  // Dismiss Flutter ViewController
  Future<void> dismissView() async {
    return TkPlatform.instance.dismissView();
  }
}