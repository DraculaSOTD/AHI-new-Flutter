import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../scanning/launchers/ahi_body_scan_launcher.dart';
import '../../health_assessment/services/health_assessment_orchestrator.dart';
import '../../../core/services/logging_service.dart';
import '../../../services/ahi_scanner/models/scan_results.dart';
import '../../../services/ahi_scanner/models/scan_inputs.dart';
import '../../../services/ahi_scanner/models/scan_enums.dart';

class BodyScanScreen extends StatefulWidget {
  final bool isPartOfAssessment;

  const BodyScanScreen({
    super.key,
    this.isPartOfAssessment = false,
  });

  @override
  State<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends State<BodyScanScreen> {
  // CameraController? _cameraController;
  // List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isScanning = false;
  String _currentPose = 'front';
  double _progress = 0.0;
  Timer? _progressTimer;
  String _statusMessage = 'Position yourself in the frame';
  
  // Placeholder measurements
  final Map<String, double> _measurements = {};

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Camera initialization temporarily disabled due to CameraX conflict with Vastmindz SDK
    // TODO: Implement body scan camera after resolving SDK conflict
    setState(() {
      _isInitialized = true; // Mock initialization for UI
    });
    /*
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
    */
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _statusMessage = 'Capturing front view...';
    });

    // Simulate scan progress
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _progress += 0.01;
        
        if (_progress >= 0.5 && _currentPose == 'front') {
          _currentPose = 'side';
          _statusMessage = 'Turn to your right (side view)';
        } else if (_progress >= 0.8) {
          _statusMessage = 'Processing measurements...';
        }
        
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _completeScan();
        }
      });
    });
  }

  void _completeScan() {
    // Simulate measurements
    setState(() {
      _measurements.addAll({
        'chest': 95.0,
        'waist': 82.0,
        'hip': 98.0,
        'thigh': 58.0,
        'inseam': 82.0,
        'bodyFat': 18.5,
        'muscleMass': 65.0,
      });
      _statusMessage = 'Scan complete!';
    });

    // Navigate to results after delay
    Future.delayed(const Duration(seconds: 2), () {
      _showResults();
    });
  }

  void _showResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultsSheet(),
    );
  }

  Widget _buildResultsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan Results',
                  style: AppTypography.headingMedium,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                children: [
                  // Body measurements
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Body Measurements',
                            style: AppTypography.headingSmall,
                          ),
                          const SizedBox(height: 16),
                          _buildMeasurementRow('Chest', '${_measurements['chest']?.toInt()} cm'),
                          _buildMeasurementRow('Waist', '${_measurements['waist']?.toInt()} cm'),
                          _buildMeasurementRow('Hip', '${_measurements['hip']?.toInt()} cm'),
                          _buildMeasurementRow('Thigh', '${_measurements['thigh']?.toInt()} cm'),
                          _buildMeasurementRow('Inseam', '${_measurements['inseam']?.toInt()} cm'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Body composition
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Body Composition',
                            style: AppTypography.headingSmall,
                          ),
                          const SizedBox(height: 16),
                          _buildMeasurementRow('Body Fat', '${_measurements['bodyFat']}%'),
                          _buildMeasurementRow('Muscle Mass', '${_measurements['muscleMass']?.toInt()} kg'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  widget.isPartOfAssessment
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Save to orchestrator and navigate to summary
                              final orchestrator = context.read<HealthAssessmentOrchestrator>();

                              // Create mock body scan result
                              // TODO: Replace with actual body scan result when AHI SDK is fully integrated
                              final mockInputs = BodyScanInputs.fromUserData(
                                sex: BiologicalSex.male,
                                heightInCm: 170.0,
                                weightInKg: 70.0,
                                ageInYears: 30,
                              );

                              final mockResult = BodyScanResult(
                                scanDate: DateTime.now(),
                                rawJson: {
                                  'cm_adj_chest': _measurements['chest'],
                                  'cm_adj_waist': _measurements['waist'],
                                  'cm_adj_hips': _measurements['hip'],
                                  'cm_adj_thigh': _measurements['thigh'],
                                  'cm_adj_inseam': _measurements['inseam'],
                                  'percent_adj_bodyFat': _measurements['bodyFat'],
                                },
                                inputs: mockInputs,
                              );

                              await orchestrator.saveBodyScan(mockResult);

                              if (!context.mounted) return;

                              Navigator.pop(context);
                              context.go('/health-assessment/summary');
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Continue to Summary'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.go('/home');
                                },
                                child: const Text('Done'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // TODO: Save results
                                  Navigator.pop(context);
                                  context.go('/reports');
                                },
                                child: const Text('Save Results'),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    // _cameraController?.dispose(); // Temporarily disabled
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            // Camera preview temporarily disabled due to SDK conflict
            if (_isInitialized)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Camera Preview\n(Temporarily Disabled)',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            
            // Overlay UI
            if (!_isScanning)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Body outline guide
                      Container(
                        width: 200,
                        height: 400,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primaryBlue,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.accessibility_new,
                          size: 150,
                          color: AppColors.primaryBlue.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        _statusMessage,
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          LoggingService.info(
                            'User tapped Start AHI Body Scan',
                            tag: 'BodyScanScreen',
                            context: {
                              'isPartOfAssessment':
                                  widget.isPartOfAssessment,
                            },
                          );
                          // Launch AHI Body Scan with assessment flag
                          AHIBodyScanLauncher.launch(
                            context,
                            isPartOfAssessment: widget.isPartOfAssessment,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          'Start AHI Body Scan',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Scanning overlay
            if (_isScanning)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated body guide
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 400,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _currentPose == 'front' 
                                  ? AppColors.primaryPurple 
                                  : AppColors.secondaryBlue,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          Icon(
                            _currentPose == 'front' 
                              ? Icons.person_outline 
                              : Icons.person_outline,
                            size: 300,
                            color: AppColors.textWhite.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // Progress bar
                      Container(
                        width: 250,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _statusMessage,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progress * 100).toInt()}% complete',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textWhite.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Top bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textWhite,
                      size: 32,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.accessibility_new,
                          color: AppColors.textWhite,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Body Scan',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}