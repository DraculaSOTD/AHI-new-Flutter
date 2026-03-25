import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rppg_common/rppg_common.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/lambda_service.dart';
import '../../../services/profile_service.dart';
import '../widgets/rive_hud_overlay.dart';

class FaceScanCameraScreen extends StatefulWidget {
  final bool isPartOfAssessment;

  const FaceScanCameraScreen({
    super.key,
    this.isPartOfAssessment = false,
  });

  @override
  State<FaceScanCameraScreen> createState() => _FaceScanCameraScreenState();
}

class _FaceScanCameraScreenState extends State<FaceScanCameraScreen> {
  final RppgCommon _rppg = RppgCommon();
  final ProfileService _profileService = ProfileService();

  StreamSubscription<AnalysisData>? _analysisSubscription;
  AnalysisData? _latestData;

  int _progress = 0;
  bool _isAnalyzing = false;
  bool _cameraReady = false;
  bool _isMoving = false;
  String _statusMessage = 'Initializing camera...';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _profileService.initialize();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      LoggingService.info('Configuring Vastmindz SDK', tag: 'FaceScanCamera');
      await _rppg.configure(AppConfig.defaultFPS, true);

      LoggingService.info('Starting video capture', tag: 'FaceScanCamera');
      await _rppg.startVideo();

      if (mounted) {
        setState(() {
          _cameraReady = true;
          _statusMessage = 'Centre your face in the oval';
        });
      }

      // Auto-start analysis after a short delay to let user position face
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _cameraReady && !_isAnalyzing) {
          _startAnalysis();
        }
      });
    } catch (e) {
      LoggingService.error('Camera initialization failed', error: e, tag: 'FaceScanCamera');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
          _statusMessage = 'Camera error';
        });
      }
    }
  }

  Future<void> _startAnalysis() async {
    final profile = _profileService.selectedProfile;
    if (profile == null) {
      LoggingService.error('No profile selected', tag: 'FaceScanCamera');
      return;
    }

    try {
      setState(() {
        _isAnalyzing = true;
        _statusMessage = 'Analyzing... Hold still';
        _errorMessage = '';
      });

      LoggingService.info('Starting Vastmindz analysis', tag: 'FaceScanCamera');

      final sex = profile.gender.toLowerCase() == 'female' ? '1' : '0';
      final stream = _rppg.startAnalysis(
        AppConfig.vastmindzWebSocketURL,
        AppConfig.vastmindzAuthToken,
        AppConfig.defaultFPS.toString(),
        profile.age.toString(),
        sex,
        profile.heightInCm.round().toString(),
        profile.weightInKg.round().toString(),
      );

      _analysisSubscription = stream.listen(
        _onAnalysisData,
        onError: (error) {
          LoggingService.error('Analysis stream error', error: error, tag: 'FaceScanCamera');
          if (mounted) {
            setState(() {
              _errorMessage = 'Analysis error: $error';
              _statusMessage = 'Error occurred';
            });
          }
        },
        onDone: () {
          LoggingService.info('Analysis stream completed', tag: 'FaceScanCamera');
        },
      );

      // Explicitly disable native overlay — using Flutter Rive HUD instead
      await _rppg.cleanMesh();
    } catch (e) {
      LoggingService.error('Failed to start analysis', error: e, tag: 'FaceScanCamera');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Failed to start analysis: $e';
          _statusMessage = 'Analysis error';
        });
      }
    }
  }

  void _onAnalysisData(AnalysisData data) {
    if (!mounted) return;

    setState(() {
      _latestData = data;
      _progress = data.progressPercentage;
      _isMoving = data.isMovingWarning;

      if (_isMoving) {
        _statusMessage = 'Hold still - movement detected';
      } else if (_progress < 100) {
        _statusMessage = 'Analyzing... $_progress%';
      }
    });

    LoggingService.debug(
      'Analysis data received',
      tag: 'FaceScanCamera',
      context: {
        'progress': _progress,
        'bpm': data.avgBpm,
        'moving': _isMoving,
      },
    );

    if (data.progressPercentage >= 100) {
      _onScanComplete(data);
    }
  }

  Future<void> _onScanComplete(AnalysisData data) async {
    LoggingService.info('Face scan complete', tag: 'FaceScanCamera');

    setState(() {
      _statusMessage = 'Scan complete!';
      _isAnalyzing = false;
    });

    // Stop analysis
    try {
      await _rppg.stopAnalysis();
    } catch (e) {
      LoggingService.warning('Error stopping analysis', tag: 'FaceScanCamera');
    }

    if (!mounted) return;

    // Map AnalysisData to the format expected by FaceScanMeasurement.fromVastmindzResult
    final scanResults = _mapAnalysisDataToResults(data);

    // Get profile data for Lambda submission
    final profile = _profileService.selectedProfile;
    if (profile == null) return;

    final userData = {
      'age': profile.age,
      'gender': profile.gender.toLowerCase(),
      'height': profile.heightInCm,
      'weight': profile.weightInKg,
    };

    try {
      // Submit to Lambda for health assessment scoring
      final result = await LambdaService.submitForHealthAssessment(
        scanResults: scanResults,
        userData: userData,
      );

      if (mounted) {
        context.pushReplacement('/scan/face/results', extra: {
          'results': result,
          'isPartOfAssessment': widget.isPartOfAssessment,
        });
      }
    } catch (e) {
      LoggingService.error('Lambda submission failed', error: e, tag: 'FaceScanCamera');
      // Navigate to results with raw data even if Lambda fails
      if (mounted) {
        final fallbackResult = HealthAssessmentResult.fromScanOnly(
          _mapAnalysisDataToResults(data),
        );

        context.pushReplacement('/scan/face/results', extra: {
          'results': fallbackResult,
          'isPartOfAssessment': widget.isPartOfAssessment,
        });
      }
    }
  }

  Map<String, dynamic> _mapAnalysisDataToResults(AnalysisData data) {
    return {
      'heartRate': data.avgBpm,
      'systolicBP': data.bloodPressure.systolic,
      'diastolicBP': data.bloodPressure.diastolic,
      'respiratoryRate': data.avgRespirationRate,
      'oxygenSaturation': data.avgO2SaturationLevel,
      'heartRateVariability': data.rmssd,
      'sdnn': data.sdnns,
      'stressLevel': _mapStressStatus(data.stressStatus),
      'stressStatus': data.stressStatus,
      'bloodPressureStatus': data.bloodPressureStatus,
      'snr': data.snr,
      'ibi': data.ibi,
    };
  }

  String _mapStressStatus(String status) {
    switch (status.toLowerCase()) {
      case 'low':
      case 'no stress':
        return 'Low';
      case 'mild':
      case 'moderate':
        return 'Moderate';
      case 'high':
      case 'very high':
        return 'High';
      default:
        return status;
    }
  }

  void _cancelScan() {
    LoggingService.info('Face scan cancelled by user', tag: 'FaceScanCamera');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  int _getHaloState() {
    if (!_cameraReady) return 0; // idle
    if (_isMoving) return 3; // warning/error
    if (_progress >= 100) return 4; // complete
    if (_isAnalyzing) return 2; // analyzing
    return 1; // calibrating/ready
  }

  Map<String, bool> _getCompletionStates() {
    if (_latestData == null) return {};
    final d = _latestData!;
    return {
      'bpm_isComplete': d.avgBpm > 0,
      'rr_isComplete': d.avgRespirationRate > 0,
      'spo2_isComplete': d.avgO2SaturationLevel > 0,
      'hrv_isComplete': d.rmssd > 0,
      'si_isComplete': d.stressStatus.isNotEmpty && d.stressStatus != 'null',
      'bp_isComplete': d.bloodPressure.systolic > 0 && d.bloodPressure.diastolic > 0,
    };
  }

  @override
  void dispose() {
    _analysisSubscription?.cancel();
    _cleanup();
    super.dispose();
  }

  Future<void> _cleanup() async {
    try {
      if (_isAnalyzing) await _rppg.stopAnalysis();
    } catch (_) {}
    try {
      await _rppg.cleanMesh();
    } catch (_) {}
    try {
      await _rppg.stopVideo();
    } catch (_) {}
    try {
      await _rppg.destroyCamera();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview (full screen)
          if (_cameraReady)
            const Positioned.fill(
              child: RppgCameraView(),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // HUD overlay with face guide, metrics, progress
          Positioned.fill(
            child: RiveHUDOverlay(
              haloState: _getHaloState(),
              guideText: _statusMessage,
              contextText: _isMoving
                  ? 'Please keep your face still'
                  : (_isAnalyzing
                      ? 'Measuring your vital signs...'
                      : 'Position your face within the oval'),
              bpmValue: _latestData?.avgBpm.toString() ?? '--',
              completionStates: _getCompletionStates(),
              onBackTapped: _cancelScan,
            ),
          ),

          // Progress bar at top
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
                    value: _progress / 100.0,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _progress >= 100
                          ? AppColors.success
                          : AppColors.primaryBlue,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ),
          ),

          // Movement warning overlay
          if (_isMoving)
            Positioned.fill(
              child: Container(
                color: Colors.red.withValues(alpha: 0.15),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Movement detected - hold still',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Error message
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
