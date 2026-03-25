import '../../../core/services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../health_assessment/services/health_assessment_orchestrator.dart';
import '../../scanning/launchers/ahi_body_scan_launcher.dart';

class BodyScanPreparationScreen extends StatefulWidget {
  final bool isPartOfAssessment;

  const BodyScanPreparationScreen({
    super.key,
    this.isPartOfAssessment = false,
  });

  @override
  State<BodyScanPreparationScreen> createState() => _BodyScanPreparationScreenState();
}

class _BodyScanPreparationScreenState extends State<BodyScanPreparationScreen> {
  bool _cameraPermissionGranted = false;
  bool _requestingPermission = true;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    // Request camera permission immediately when screen loads
    _requestCameraPermission();

    // Advance orchestrator to bodyScan step when entering this screen in assessment mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orchestrator = context.read<HealthAssessmentOrchestrator>();
      if (widget.isPartOfAssessment && orchestrator.hasActiveAssessment) {
        LoggingService.info('Body scan prep - advancing orchestrator to bodyScan step', tag: 'BodyScanPrep');
        // Manually advance to bodyScan step since we prevented auto-advance after scan 3
        orchestrator.advanceToBodyScan();
      }
    });
  }

  Future<void> _requestCameraPermission() async {
    LoggingService.info('Checking camera permission', tag: 'BodyScanPrep');

    setState(() {
      _requestingPermission = true;
      _permissionError = null;
    });

    try {
      // First check current status
      final currentStatus = await Permission.camera.status;
      LoggingService.info('Current camera permission status', tag: 'BodyScanPrep', context: {'status': currentStatus.toString()});

      if (currentStatus.isGranted) {
        LoggingService.success('Camera permission already granted', tag: 'BodyScanPrep');
        setState(() {
          _requestingPermission = false;
          _cameraPermissionGranted = true;
        });
        return;
      }

      // Request permission if not granted
      LoggingService.info('Requesting camera permission', tag: 'BodyScanPrep');
      final status = await Permission.camera.request();
      LoggingService.info('Camera permission request result', tag: 'BodyScanPrep', context: {'status': status.toString()});

      setState(() {
        _requestingPermission = false;
        _cameraPermissionGranted = status.isGranted;

        if (status.isDenied) {
          _permissionError = 'Camera permission denied. Tap Retry to request again.';
          LoggingService.warning('Camera permission denied', tag: 'BodyScanPrep');
        } else if (status.isPermanentlyDenied) {
          _permissionError = 'Camera permission permanently denied. Please enable it in Settings.';
          LoggingService.error('Camera permission permanently denied', tag: 'BodyScanPrep');
        } else if (status.isGranted) {
          LoggingService.success('Camera permission granted', tag: 'BodyScanPrep');
        }
      });
    } catch (e) {
      setState(() {
        _requestingPermission = false;
        _cameraPermissionGranted = false;
        _permissionError = 'Failed to request camera permission: $e';
      });
      LoggingService.error('Camera permission error', error: e, tag: 'BodyScanPrep');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're in assessment mode by looking at orchestrator
    final orchestrator = context.watch<HealthAssessmentOrchestrator>();
    final inAssessment = widget.isPartOfAssessment || orchestrator.hasActiveAssessment;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Scan Preparation'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Instructions card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preparation Instructions',
                              style: AppTypography.headingSmall,
                            ),
                            const SizedBox(height: 16),
                            _buildInstruction(
                              '1',
                              'Wear tight-fitting clothing',
                              'Wear form-fitting clothes like athletic wear or underwear for accurate measurements.',
                            ),
                            _buildInstruction(
                              '2',
                              'Find a well-lit space',
                              'Stand in a room with good lighting and plain background.',
                            ),
                            _buildInstruction(
                              '3',
                              'Position your device',
                              'Place your phone 3-4 feet away at waist height.',
                            ),
                            _buildInstruction(
                              '4',
                              'Stand naturally',
                              'Stand with feet shoulder-width apart and arms slightly away from your body.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Visual guides
                    Text(
                      'Required Poses',
                      style: AppTypography.headingSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPoseCard(
                            'Front View',
                            Icons.person_outline,
                            'Face the camera directly',
                            AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPoseCard(
                            'Side View',
                            Icons.person_outline,
                            'Turn 90° to your right',
                            AppColors.secondaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Requirements checklist
                    Card(
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.warning.withValues(alpha: 0.05),
                              AppColors.warning.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.checklist,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Requirements',
                                  style: AppTypography.headingSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildRequirement('Full body visible in frame'),
                            _buildRequirement('Good lighting (no shadows)'),
                            _buildRequirement('Plain background'),
                            _buildRequirement('Phone at correct distance'),
                            _buildRequirement('Stable phone position'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Important note
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Privacy Note',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Images are processed locally on your device and are not stored or transmitted.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
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
            ),
            // Permission error message
            if (_permissionError != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _permissionError!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    if (_permissionError!.contains('permanently'))
                      TextButton(
                        onPressed: () => openAppSettings(),
                        child: const Text('Settings'),
                      )
                    else
                      TextButton(
                        onPressed: _requestCameraPermission,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            // Bottom button
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLarge,
                child: ElevatedButton(
                  onPressed: (_requestingPermission || !_cameraPermissionGranted)
                      ? null
                      : () => AHIBodyScanLauncher.launch(
                            context,
                            isPartOfAssessment: inAssessment,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    disabledBackgroundColor: AppColors.primaryPurple.withValues(alpha: 0.5),
                  ),
                  child: _requestingPermission
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _cameraPermissionGranted
                              ? 'Start Body Scan'
                              : 'Camera Permission Required',
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoseCard(
    String title,
    IconData icon,
    String description,
    Color color,
  ) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Icon(
                icon,
                size: 60,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}