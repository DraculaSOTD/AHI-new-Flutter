import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/lambda_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/vastmindz/vastmindz_face_scan_service.dart';
import '../../health_assessment/models/health_assessment.dart';
import '../../health_assessment/services/health_assessment_orchestrator.dart';
import '../widgets/rive_hud_overlay.dart';

/// Face-scan camera + vitals capture, using the pure-Dart Vastmindz client.
///
/// Replaces the previous `RppgCommon` (native librppg_core.so) implementation,
/// which was excluded from the APK to fix the AHI body-scan OpenCV conflict.
class FaceScanCameraScreen extends StatefulWidget {
  final bool isPartOfAssessment;
  /// Marks special scan variants inside the assessment flow.
  /// `'post_exercise'` is set by the step-test active screen when navigating
  /// here for the cool-down face scan — its captured HR becomes the
  /// post-exercise heart rate, *not* a 4th entry in vitalSigns.measurements.
  final String? scanType;

  const FaceScanCameraScreen({
    super.key,
    this.isPartOfAssessment = false,
    this.scanType,
  });

  @override
  State<FaceScanCameraScreen> createState() => _FaceScanCameraScreenState();
}

class _FaceScanCameraScreenState extends State<FaceScanCameraScreen> {
  final ProfileService _profileService = ProfileService();

  CameraController? _camera;
  VastmindzFaceScanService? _vmz;
  StreamSubscription<double>? _progressSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<Map<String, dynamic>>? _resultSub;
  StreamSubscription<Map<String, dynamic>>? _liveSub;
  StreamSubscription<Object>? _errorSub;
  Timer? _watchdog;

  bool _cameraReady = false;
  bool _streaming = false;
  bool _completed = false;
  double _progress = 0.0;
  String _statusMessage = 'Initializing camera…';
  String _errorMessage = '';
  int _sensorOrientation = 0;
  bool _isFrontCamera = true;

  // Live vitals (sticky — once set they hold until the session ends).
  num? _liveBpm;
  num? _liveRr;
  num? _liveSpo2;
  num? _liveSys;
  num? _liveDia;
  num? _liveRmssd;
  num? _liveSdnn;
  num? _liveIbi;
  String? _liveStress;
  bool _interferenceDetected = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;
  // Silent auto-restart fires when the 45 s watchdog expires with some vitals
  // still missing. Sticky vitals are preserved across these.
  int _autoRestartCount = 0;
  static const int _maxAutoRestarts = 3;
  // 1-based index of which scan we're on inside a 3-scan assessment. Drives
  // the "Scan N of 3" pill + the ValueKey we hand to the Rive HUD so it fully
  // remounts between scans (the .riv file has no reset SMI input).
  int _assessmentScanNumber = 1;
  // True for one frame during _resetCameraSessionForNextScan — we drop the
  // RiveHUDOverlay from the tree entirely so its state machine disposes,
  // then re-mount it on the next frame with truly empty props. Without this,
  // the WS sometimes flushes cached HRV/SI/BP in the same frame as the
  // remount, so the new Rive runtime initializes with halos already lit.
  bool _hudHidden = false;

  @override
  void initState() {
    super.initState();
    // Screen keep-awake is handled app-wide in main.dart, so there's no
    // per-screen wakelock to manage here.
    _profileService.initialize();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _isFrontCamera = front.lensDirection == CameraLensDirection.front;
      _sensorOrientation = front.sensorOrientation;

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        // NV21 is what ML Kit on Android expects natively and what our NV21
        // ROI-averaging path in VastmindzFaceScanService is built for.
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      setState(() {
        _cameraReady = true;
        _statusMessage = 'Centre your face in the oval';
      });

      // Give the user 2 s to position before we start measuring.
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await _startMeasurement();
    } catch (e, st) {
      LoggingService.error('Camera bootstrap failed',
          error: e, stackTrace: st, tag: 'FaceScanCamera');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialise camera: $e';
          _statusMessage = 'Camera error';
        });
      }
    }
  }

  Future<void> _startMeasurement() async {
    final profile = _profileService.selectedProfile;
    if (profile == null) {
      setState(() {
        _errorMessage = 'No profile selected.';
        _statusMessage = 'Profile required';
      });
      return;
    }

    final sex = profile.gender.toLowerCase() == 'female' ? 'female' : 'male';
    _vmz = VastmindzFaceScanService(
      wsUrlBase: AppConfig.vastmindzWebSocketURL,
      authToken: AppConfig.vastmindzAuthToken,
      sex: sex,
      ageYears: profile.age,
      heightCm: profile.heightInCm.round(),
      weightKg: profile.weightInKg.round(),
    );

    _progressSub = _vmz!.progress.listen((_) {
      // No-op. End-of-session is owned by (a) auto-finish in _onLiveData when
      // all 6 vitals are sticky, and (b) the 45 s watchdog. The server's
      // `progressPercent` can overshoot past 100 on RECALIBRATING events and
      // would otherwise trigger a premature finish here.
    });
    _statusSub = _vmz!.status.listen((s) {
      if (!mounted) return;
      setState(() => _statusMessage = s);
    });
    _resultSub = _vmz!.result.listen(_onResult);
    _liveSub = _vmz!.liveData.listen(_onLiveData);
    _errorSub = _vmz!.errors.listen((e) {
      LoggingService.warning('Vastmindz service error',
          tag: 'FaceScanCamera', context: {'error': e.toString()});
    });

    await _vmz!.start();

    setState(() {
      _streaming = true;
      _statusMessage = 'Hold still…';
    });

    await _camera!.startImageStream((CameraImage image) {
      _vmz?.processCameraFrame(
        image,
        cameraSensorOrientation: _sensorOrientation,
        isFrontCamera: _isFrontCamera,
      );
    });

    // Watchdog: after each 45 s window without all 6 vitals captured, silently
    // restart the WebSocket session (preserving sticky vitals) — up to
    // _maxAutoRestarts times — so the connection effectively stays open until
    // every vital has landed. Only after exhausting those attempts do we fall
    // through to _finishFromStickyState (which shows the incomplete dialog).
    _watchdog = Timer(const Duration(seconds: 45), () {
      if (_completed) return;
      // SpO2 is intentionally excluded — see the note in _onLiveData. Don't
      // burn auto-restarts on a vital the server has already refused to
      // estimate from this signal.
      final missingAny = _liveBpm == null ||
          _liveRr == null ||
          _liveSys == null ||
          _liveDia == null ||
          _liveRmssd == null ||
          _liveStress == null;
      if (missingAny && _autoRestartCount < _maxAutoRestarts) {
        LoggingService.warning(
            '45s window expired with vitals missing; auto-continuing',
            tag: 'FaceScanCamera');
        _continueSession();
      } else {
        LoggingService.warning(
            'Session watchdog fired (45s); finishing from sticky state',
            tag: 'FaceScanCamera');
        _finishFromStickyState();
      }
    });
  }

  Future<void> _finishFromStickyState() async {
    if (_completed) return;
    _completed = true;
    _watchdog?.cancel();
    if (mounted) {
      setState(() {
        _statusMessage = 'Scan complete';
        _progress = 1.0;
        // Drop any banner that may have latched from a late statusCode message.
        _interferenceDetected = false;
      });
    }
    await _stopStream();
    if (!mounted) return;

    // If any vital is still null, offer a retry instead of submitting a
    // half-empty record. Capped at _maxRetries to keep things bounded.
    final missing = <String>[
      if (_liveBpm == null) 'Heart rate',
      if (_liveRr == null) 'Respiratory rate',
      if (_liveSpo2 == null) 'Oxygen (SpO₂)',
      if (_liveSys == null || _liveDia == null) 'Blood pressure',
      if (_liveRmssd == null) 'Heart-rate variability',
      if (_liveStress == null) 'Stress index',
    ];

    if (missing.isNotEmpty && _retryCount < _maxRetries) {
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Scan incomplete'),
          content: Text(
            "We couldn't get a clean reading for:\n• ${missing.join('\n• ')}\n\n"
            "Hold the phone steady at face height in a well-lit spot and try again, "
            "or continue with the ${6 - missing.length} reading(s) we did capture.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Continue anyway'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (retry == true) {
        await _retryScan();
        return;
      }
    }

    // Assemble whatever we managed to capture. HealthAssessmentResult declares
    // these fields as `int`, so we must round before handing them off — the
    // Vastmindz server sends doubles for HRV (rmssd / sdnn / ibi).
    final scanResults = <String, dynamic>{
      'heartRate':            _liveBpm?.round()   ?? 0,
      'systolicBP':           _liveSys?.round()   ?? 0,
      'diastolicBP':          _liveDia?.round()   ?? 0,
      'respiratoryRate':      _liveRr?.round()    ?? 0,
      'oxygenSaturation':     _liveSpo2?.round()  ?? 0,
      'heartRateVariability': _liveRmssd?.round() ?? 0,
      // SDNN and IBI flow through as their natural double precision.
      'sdnn':                 _liveSdnn ?? 0,
      'ibi':                  _liveIbi ?? 0,
      'stressLevel':          _liveStress ?? 'Unknown',
      'stressStatus':         _liveStress ?? '',
    };

    // Assessment mode: save measurement to the orchestrator, then route to the
    // next step. Single Lambda submission is deferred until the summary screen
    // (so we don't show partial results between scans).
    if (widget.isPartOfAssessment) {
      // Any throw inside this block (a model-field type drift, a SharedPrefs
      // hiccup, etc.) used to kill the await chain and strand the user on the
      // success overlay. Catch it, log it loudly, and bail to home so the
      // failure is visible and recoverable.
      try {
        final orchestrator = context.read<HealthAssessmentOrchestrator>();
        final measurement =
            FaceScanMeasurement.fromVastmindzResult(scanResults);
        // Post-exercise face scan (step-test cool-down) goes to fitnessTest
        // instead of polluting the resting-vitals average.
        if (widget.scanType == 'post_exercise') {
          await orchestrator.savePostExerciseFaceScan(measurement);
          if (!mounted) return;
          context.go('/health-assessment/summary');
          return;
        }
        await orchestrator.saveFaceScanMeasurement(measurement);
        if (!mounted) return;
        _routeForCurrentStep(orchestrator.currentStep);
      } catch (e, st) {
        LoggingService.error(
          'Failed to save face scan measurement — bailing to home so the '
          "user isn't stranded on the success overlay.",
          error: e,
          tag: 'FaceScanCamera',
          context: {
            'stack': st.toString().split('\n').take(5).join('\n'),
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Something went wrong saving this scan. Please restart the assessment.',
              ),
            ),
          );
          context.go('/home');
        }
      }
      return;
    }

    // Standalone scan path — no Lambda call. The Lambda submission only
    // happens once at the end of a full Health Assessment (summary screen).
    // The results page renders vitals-only when lambdaSuccess is false.
    if (!mounted) return;
    final vitalsOnly = HealthAssessmentResult.fromScanOnly(scanResults);
    context.pushReplacement('/scan/face/results', extra: {
      'results': vitalsOnly,
      'isPartOfAssessment': widget.isPartOfAssessment,
    });
  }

  void _routeForCurrentStep(AssessmentStep _) {
    // Decide the next screen from observable assessment state, NOT from the
    // orchestrator's `_currentStep` pointer. The intermediate screens
    // (anxiety / depression / fitness-screening / step-test*) hardcode their
    // own `context.push(...)`, which makes `_currentStep` drift out of sync
    // with the visible screen — relying on it for routing strands the user.
    final orchestrator = context.read<HealthAssessmentOrchestrator>();
    final a = orchestrator.currentAssessment;
    if (a == null) {
      // saveFaceScanMeasurement silently no-ops when the assessment is null,
      // which is what caused the user-visible "stuck on scan 1" bug. Fail
      // loudly here so we never silently loop the in-place reset forever.
      LoggingService.error(
        'Assessment is null on face-scan finish — startNewAssessment was '
        'never called. Bailing to home to avoid an infinite reset loop.',
        tag: 'FaceScanCamera',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Assessment state was lost — please restart it from the Scan tab.',
            ),
          ),
        );
        context.go('/home');
      }
      return;
    }
    final faceScanCount = a.vitalSigns?.measurements.length ?? 0;
    final hasBodyScan = a.bodyScanResult != null;
    final hasStepTest = a.fitnessTest?.postExerciseHeartRate != null;
    LoggingService.info(
      'Assessment routing decision',
      tag: 'FaceScanCamera',
      context: {
        'faceScanCount': faceScanCount,
        'hasBodyScan': hasBodyScan,
        'hasStepTest': hasStepTest,
      },
    );

    if (faceScanCount < 3) {
      // Don't navigate — go_router collapses pushReplacement to the same path
      // with structurally-equal extras, leaving the screen frozen on the
      // "Scan complete" overlay. Reset in place instead.
      LoggingService.info(
        'Starting next assessment face scan in place',
        tag: 'FaceScanCamera',
        context: {'completed': faceScanCount, 'total': 3},
      );
      _resetCameraSessionForNextScan(
        statusMessage: 'Scan ${faceScanCount + 1} of 3 — get ready…',
      );
      return;
    } else if (!hasBodyScan) {
      context.go('/scan/body/preparation',
          extra: {'isPartOfAssessment': true});
    } else if (!hasStepTest) {
      // Fitness screening was removed from the flow — step test runs
      // unconditionally after the body scan.
      context.go('/health-assessment/step-test-prep');
    } else {
      context.go('/health-assessment/summary');
    }
  }

  void _onLiveData(Map<String, dynamic> msg) {
    if (!mounted) return;
    // The service emits a normalized delta map with only valid fields.
    // We merge each field into sticky state — a fresh non-null reading
    // overwrites the previous value; missing/null fields leave it untouched.
    setState(() {
      if (msg['bpm'] is num) _liveBpm = msg['bpm'] as num;
      if (msg['rr'] is num) _liveRr = msg['rr'] as num;
      if (msg['spo2'] is num) _liveSpo2 = msg['spo2'] as num;
      if (msg['systolic'] is num) _liveSys = msg['systolic'] as num;
      if (msg['diastolic'] is num) _liveDia = msg['diastolic'] as num;
      if (msg['rmssd'] is num) _liveRmssd = msg['rmssd'] as num;
      if (msg['sdnn'] is num) _liveSdnn = msg['sdnn'] as num;
      if (msg['ibi'] is num) _liveIbi = msg['ibi'] as num;
      if (msg['stressLabel'] is String) {
        _liveStress = msg['stressLabel'] as String;
      }
      // Late statusCode messages can arrive after the all-vitals-captured
      // branch has already fired _finishFromStickyState. Don't re-arm the
      // banner once we're done — it'd just sit on top of the success overlay.
      if (!_completed && msg['statusCode'] is String) {
        final code = msg['statusCode'] as String;
        _interferenceDetected =
            code.contains('NOISE') || code.contains('INTERFERENCE');
      }

      // Drive the progress bar + status text off the count of captured vitals
      // (BP counts as one tile — needs both systolic and diastolic).
      final vitalsCount = (_liveBpm != null ? 1 : 0) +
          (_liveRr != null ? 1 : 0) +
          (_liveSpo2 != null ? 1 : 0) +
          ((_liveSys != null && _liveDia != null) ? 1 : 0) +
          (_liveRmssd != null ? 1 : 0) +
          (_liveStress != null ? 1 : 0);
      _progress = vitalsCount / 6.0;
      if (!_completed) {
        _statusMessage = vitalsCount == 0
            ? 'Looking for your pulse…'
            : 'Captured $vitalsCount of 6 vitals';
      }
    });

    // Auto-finish the session the moment the *core* vitals have a valid
    // sticky reading. SpO2 is treated as best-effort: rPPG SpO2 estimation
    // is very sensitive to lighting / SNR and the Vastmindz server returns
    // `oxygen: 0` (sentinel for "couldn't estimate") in marginal conditions.
    // We don't want to spin to the watchdog and keep restarting the WS just
    // for SpO2 when everything else is in — across the 3-scan assessment, at
    // least one scan typically lands SpO2 anyway.
    final coreComplete = _liveBpm != null &&
        _liveRr != null &&
        _liveSys != null &&
        _liveDia != null &&
        _liveRmssd != null &&
        _liveStress != null;
    if (coreComplete && !_completed) {
      LoggingService.info(
        _liveSpo2 != null
            ? 'All vitals captured — finishing early'
            : 'Core vitals captured — finishing without SpO2 (server returned no reading)',
        tag: 'FaceScanCamera',
      );
      _finishFromStickyState();
    }
  }

  Future<void> _onResult(Map<String, dynamic> raw) async {
    if (_completed) return;
    _completed = true;
    _watchdog?.cancel();
    if (mounted) {
      setState(() {
        _statusMessage = 'Scan complete';
        _progress = 1.0;
      });
    }
    await _stopStream();

    if (!mounted) return;

    final scanResults = _mapVastmindzResultToResults(raw);
    // No Lambda call from the standalone path — see comment in
    // _finishFromStickyState. Show vitals-only on the results screen.
    final vitalsOnly = HealthAssessmentResult.fromScanOnly(scanResults);
    if (!mounted) return;
    context.pushReplacement('/scan/face/results', extra: {
      'results': vitalsOnly,
      'isPartOfAssessment': widget.isPartOfAssessment,
    });
  }

  Map<String, dynamic> _mapVastmindzResultToResults(Map<String, dynamic> r) {
    return {
      'heartRate': _toNum(r['bpm_ent_restingHeartRate']) ?? 0,
      'systolicBP': _toNum(r['mmHg_ent_systolicBP']) ?? 0,
      'diastolicBP': _toNum(r['mmHg_ent_diastolicBP']) ?? 0,
      'respiratoryRate': _toNum(r['int_raw_rr']) ?? 0,
      'oxygenSaturation': _toNum(r['int_raw_oxygen']) ?? 0,
      'heartRateVariability': _toNum(r['flt_raw_rmssd']) ?? 0,
      'sdnn': _toNum(r['flt_raw_sdnn']) ?? 0,
      'stressLevel': _mapStressIndex(_toNum(r['flt_raw_stressIndex'])),
      'stressIndex': _toNum(r['flt_raw_stressIndex']) ?? 0,
      'ibi': _toNum(r['flt_raw_ibi']) ?? 0,
      'sessionId': r['session_id']?.toString() ?? '',
    };
  }

  Future<void> _retryScan() async {
    _retryCount += 1;
    LoggingService.info('Retrying face scan (#$_retryCount)',
        tag: 'FaceScanCamera');
    await _resetCameraSessionForNextScan(statusMessage: 'Restarting…');
  }

  /// Tear down the per-scan resources (WS, face detector, stream subs, watchdog)
  /// and clear sticky vitals so the next scan starts clean. The camera
  /// controller itself is left running — `_startMeasurement` re-attaches a
  /// fresh image-stream callback.
  ///
  /// Used by both `_retryScan` (user-driven retry) and the assessment-flow
  /// "next of 3 scans" transition. We keep these paths sharing the same
  /// teardown so they can't drift.
  Future<void> _resetCameraSessionForNextScan({
    required String statusMessage,
  }) async {
    _autoRestartCount = 0;
    _assessmentScanNumber += 1;

    // Phase 1 — hide the Rive HUD synchronously and clear sticky vitals in
    // the same setState so the next build renders without it. The HUD won't
    // be reattached until phase 2, after teardown completes.
    if (mounted) {
      setState(() {
        _hudHidden = true;
        _completed = false;
        _progress = 0.0;
        _statusMessage = statusMessage;
        _interferenceDetected = false;
        _liveBpm = null;
        _liveRr = null;
        _liveSpo2 = null;
        _liveSys = null;
        _liveDia = null;
        _liveRmssd = null;
        _liveSdnn = null;
        _liveIbi = null;
        _liveStress = null;
      });
    }

    await _progressSub?.cancel();
    await _statusSub?.cancel();
    await _resultSub?.cancel();
    await _liveSub?.cancel();
    await _errorSub?.cancel();
    await _vmz?.dispose();
    _vmz = null;
    _watchdog?.cancel();

    // Phase 2 — wait one frame so Flutter has actually disposed the
    // RiveHUDOverlay (and its underlying Rive state machine), then mount it
    // fresh. _live* are still null, so it initializes with halos dark.
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;
    setState(() {
      _hudHidden = false;
    });

    await _startMeasurement();
  }

  /// Silently re-open the WebSocket / face detector / image-stream loop *while
  /// preserving sticky vitals*. Called when the 45 s watchdog expires with
  /// some vitals still missing. The point is to keep trying until everything
  /// is captured, not to throw away what we've already got.
  Future<void> _continueSession() async {
    _autoRestartCount += 1;
    LoggingService.info(
        'Auto-continuing face scan (#$_autoRestartCount of $_maxAutoRestarts)',
        tag: 'FaceScanCamera');

    // Tear down WS + face detector + subscriptions; keep the camera.
    await _progressSub?.cancel();
    await _statusSub?.cancel();
    await _resultSub?.cancel();
    await _liveSub?.cancel();
    await _errorSub?.cancel();
    await _vmz?.dispose();
    _vmz = null;
    _watchdog?.cancel();

    // Reset only per-session flags. Sticky vitals (_liveBpm, _liveRr, …) stay.
    if (mounted) {
      setState(() {
        _completed = false;
        _interferenceDetected = false;
        _statusMessage = 'Holding on — restarting…';
      });
    }

    await _startMeasurement();
  }

  num? _toNum(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  String _mapStressIndex(num? si) {
    if (si == null) return 'Unknown';
    if (si < 30) return 'Low';
    if (si < 70) return 'Moderate';
    return 'High';
  }

  Future<void> _stopStream() async {
    try {
      if (_camera?.value.isStreamingImages ?? false) {
        await _camera!.stopImageStream();
      }
    } catch (_) {}
    _streaming = false;
  }

  void _cancelScan() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  int _getHaloState() {
    if (!_cameraReady) return 0;
    if (_progress >= 1.0) return 4;
    if (_streaming) return 2;
    return 1;
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _progressSub?.cancel();
    _statusSub?.cancel();
    _resultSub?.cancel();
    _liveSub?.cancel();
    _errorSub?.cancel();
    _vmz?.dispose();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_cameraReady && _camera != null && _camera!.value.previewSize != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  // Camera previewSize is in sensor orientation (landscape on
                  // Android phones), so swap width/height for portrait.
                  width: _camera!.value.previewSize!.height,
                  height: _camera!.value.previewSize!.width,
                  child: CameraPreview(_camera!),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          if (!_hudHidden)
          Positioned.fill(
            // Force a full remount on each new assessment scan so the Rive
            // state machine resets — its completion halos only animate
            // off→on, and there's no reset SMI input to flip them back.
            // Combined with the _hudHidden / two-phase reset in
            // _resetCameraSessionForNextScan to defeat the same-frame
            // remount-with-cached-data race.
            child: RiveHUDOverlay(
              key: ValueKey('rive-hud-scan-$_assessmentScanNumber'),
              haloState: _getHaloState(),
              guideText: _statusMessage,
              contextText: _streaming
                  ? 'Measuring your vital signs…'
                  : 'Position your face within the oval',
              bpmValue: _liveBpm == null
                  ? '--'
                  : _liveBpm!.toStringAsFixed(0),
              rrValue: _liveRr == null ? null : _liveRr!.toStringAsFixed(0),
              spo2Value:
                  _liveSpo2 == null ? null : _liveSpo2!.toStringAsFixed(0),
              hrvValue:
                  _liveRmssd == null ? null : _liveRmssd!.toStringAsFixed(0),
              siValue: _liveStress,
              bpValue: (_liveSys == null || _liveDia == null)
                  ? null
                  : '${_liveSys!.toStringAsFixed(0)}/${_liveDia!.toStringAsFixed(0)}',
              completionStates: {
                'bpm_isComplete': _liveBpm != null,
                'rr_isComplete': _liveRr != null,
                'spo2_isComplete': _liveSpo2 != null,
                'hrv_isComplete': _liveRmssd != null,
                'si_isComplete':
                    _liveStress != null && _liveStress!.isNotEmpty,
                'bp_isComplete': _liveSys != null && _liveDia != null,
              },
              onBackTapped: _cancelScan,
            ),
          ),

          if (widget.isPartOfAssessment &&
              widget.scanType != 'post_exercise')
            Positioned(
              top: 0,
              left: 16,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Scan $_assessmentScanNumber of 3',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _progress >= 1.0
                          ? AppColors.success
                          : AppColors.primaryBlue,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ),
          ),

          if (_interferenceDetected)
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hold still and stay well-lit — interference detected',
                            style: AppTypography.bodySmall
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_errorMessage.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
