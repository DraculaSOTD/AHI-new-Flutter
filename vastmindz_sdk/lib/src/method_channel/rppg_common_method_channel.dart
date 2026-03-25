import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../constants/rppg_constants.dart';
import '../analysis_data/analysis_data.dart';
import '../platform_interface/rppg_common_platform_interface.dart';

/// An implementation of [RppgCommonPlatform] that uses method channels.
class MethodChannelRppgCommon extends RppgCommonPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(RppgConstants.methodChannelName);

  /// The event channel used to interact with the native platform for stream data interchange.
  /// CRITICAL FIX: Made non-static and removed const to allow EventChannel recreation between scans.
  /// The const keyword creates a Dart singleton that cannot be listened to multiple times,
  /// causing "Stream has already been listened to" errors on scan 2+.
  /// By removing const, each call creates a fresh EventChannel instance.
  EventChannel get _streamEventChannel =>
      EventChannel(RppgConstants.eventChannelName);

  /// Stream Controller to handle upcoming stream response
  /// Made nullable to allow recreation between scan sessions
  StreamController<AnalysisData>? _streamController;

  /// EventChannel subscription to allow proper cleanup between scans
  StreamSubscription? _eventChannelSubscription;

  @override
  Future<String> getState() async {
    final result =
        await methodChannel.invokeMethod<String>(RppgConstants.getState) ??
            RppgConstants.defaultString;
    return result;
  }

  @override
  Future<bool> isInitialized() async {
    final result =
        await methodChannel.invokeMethod<bool>(RppgConstants.isInitialized) ??
            false;
    return result;
  }

  @override
  Future<bool> askPermissions() async {
    final result =
        await methodChannel.invokeMethod<bool>(RppgConstants.askPermissions) ??
            false;
    return result;
  }

  @override
  configure(int fps, bool isFrontCamera) async {
    Map<String, dynamic> configArguments = {
      'fps': fps,
      'isFrontCamera': isFrontCamera,
    };
    await methodChannel.invokeMethod<String>(
        RppgConstants.configure, configArguments);
    return null;
  }

  @override
  startVideo() async {
    await methodChannel.invokeMethod<String>(RppgConstants.startVideo);
    return null;
  }

  @override
  Future<void> stopVideo() async {
    await methodChannel.invokeMethod<bool>(RppgConstants.stopVideo);
  }

  @override
  Stream<AnalysisData> startAnalysis(String baseUrl, String authToken,
      String fps, String age, String sex, String height, String weight) {
    Map<String, dynamic> arguments = {
      'baseUrl': baseUrl,
      'authToken': authToken,
      'fps': fps,
      'age': age,
      'sex': sex,
      'height': height,
      'weight': weight
    };

    // CRITICAL FIX: Cancel old subscription and create new StreamController
    // This prevents "Stream has already been listened to" error on scan 2+
    debugPrint('🔄 Starting analysis - cleaning up previous stream resources...');

    _eventChannelSubscription?.cancel();
    debugPrint('✅ Previous EventChannel subscription cancelled');

    _streamController?.close();
    debugPrint('✅ Previous StreamController closed');

    _streamController = StreamController<AnalysisData>.broadcast();
    debugPrint('✅ New broadcast StreamController created');

    methodChannel.invokeMethod(RppgConstants.startAnalysis, arguments);
    debugPrint('📡 startAnalysis method invoked on native platform');

    // Create new EventChannel subscription using the getter to get fresh EventChannel
    // The getter returns a new EventChannel instance each time (const removed)
    try {
      _eventChannelSubscription = _streamEventChannel.receiveBroadcastStream().listen((data) {
        try {
          debugPrint('📦 Raw EventChannel data (${data?.toString().length ?? 0} chars): ${data?.toString().substring(0, (data?.toString().length ?? 0).clamp(0, 200))}...');
          AnalysisData analysisDataModel = analysisDataFromJson(data);
          _streamController?.add(analysisDataModel);
        } catch (e, stackTrace) {
          debugPrint('❌ JSON parse error: $e');
          debugPrint('📜 Stack trace: $stackTrace');
          debugPrint('📦 Raw data that failed: $data');
          _streamController?.addError(e);
        }
      }, onError: (error) {
        debugPrint('❌ EventChannel error: $error');
        _streamController?.addError(error);
      }, onDone: () {
        debugPrint('✅ EventChannel stream done - closing StreamController');
        _streamController?.close();
        _eventChannelSubscription = null;
      });
      debugPrint('✅ EventChannel subscription created successfully');
    } catch (e) {
      debugPrint('❌ CRITICAL: Failed to create EventChannel subscription: $e');

      // Specific diagnostic for "Stream already listened to" error
      if (e.toString().contains('Bad state') && e.toString().contains('Stream has already been listened to')) {
        debugPrint('🔴 STREAM REUSE ERROR DETECTED:');
        debugPrint('   The EventChannel is being reused despite the fix.');
        debugPrint('   Possible causes:');
        debugPrint('   1. The "const" keyword was not properly removed (line 20)');
        debugPrint('   2. Native EventChannel was not properly cancelled');
        debugPrint('   3. Race condition: native onCancel() not complete before new listen');
        debugPrint('💡 IMMEDIATE ACTION: Verify line 20 shows: EventChannel(RppgConstants.eventChannelName)');
        debugPrint('   WITHOUT the "const" keyword');
      }

      _streamController?.addError(e);
      rethrow;
    }

    // Return the broadcast stream (no need to convert since we created it as broadcast)
    return _streamController!.stream;
  }

  @override
  stopAnalysis() async {
    debugPrint('🛑 Stopping analysis...');

    await methodChannel.invokeMethod<String>(RppgConstants.stopAnalysis);
    debugPrint('✅ stopAnalysis method invoked on native platform');

    // CRITICAL FIX: Clean up stream resources to prevent memory leaks
    // and allow fresh stream creation for next scan
    debugPrint('🔄 Cleaning up stream resources...');

    await _eventChannelSubscription?.cancel();
    _eventChannelSubscription = null;
    debugPrint('✅ EventChannel subscription cancelled and nullified');

    await _streamController?.close();
    _streamController = null;
    debugPrint('✅ StreamController closed and nullified');

    debugPrint('✅ stopAnalysis complete - all resources cleaned up');
    return null;
  }

  @override
  meshColor() async {
    await methodChannel.invokeMethod<String>(RppgConstants.meshColor);
    return null;
  }

  @override
  cleanMesh() async {
    await methodChannel.invokeMethod<String>(RppgConstants.cleanMesh);
    return null;
  }

  @override
  Future<void> destroyCamera() async {
    await methodChannel.invokeMethod<bool>(RppgConstants.destroyCamera);
  }

  @override
  Future<void> resetForNewScan() async {
    debugPrint('🔄 Calling native resetForNewScan method...');
    await methodChannel.invokeMethod<bool>(RppgConstants.resetForNewScan);
    debugPrint('✅ Native resetForNewScan completed');
  }
}
