import '../../../core/services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/profile_service.dart';

class FaceScanPreparationScreen extends StatefulWidget {
  final bool isPartOfAssessment;

  const FaceScanPreparationScreen({
    super.key,
    this.isPartOfAssessment = false,
  });

  @override
  State<FaceScanPreparationScreen> createState() => _FaceScanPreparationScreenState();
}

class _FaceScanPreparationScreenState extends State<FaceScanPreparationScreen> {
  final ProfileService _profileService = ProfileService();
  bool _cameraPermissionGranted = false;
  bool _requestingPermission = true;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    _profileService.initialize();
    // Request camera permission immediately when screen loads
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    LoggingService.info('Checking camera permission', tag: 'FaceScanPrep');

    setState(() {
      _requestingPermission = true;
      _permissionError = null;
    });

    try {
      // First check current status
      final currentStatus = await Permission.camera.status;
      LoggingService.info('Current camera permission status', tag: 'FaceScanPrep', context: {'status': currentStatus.toString()});

      if (currentStatus.isGranted) {
        LoggingService.success('Camera permission already granted', tag: 'FaceScanPrep');
        setState(() {
          _requestingPermission = false;
          _cameraPermissionGranted = true;
        });
        return;
      }

      // Request permission if not granted
      LoggingService.info('Requesting camera permission', tag: 'FaceScanPrep');
      final status = await Permission.camera.request();
      LoggingService.info('Camera permission request result', tag: 'FaceScanPrep', context: {'status': status.toString()});

      setState(() {
        _requestingPermission = false;
        _cameraPermissionGranted = status.isGranted;

        if (status.isDenied) {
          _permissionError = 'Camera permission denied. Tap Retry to request again.';
          LoggingService.warning('Camera permission denied', tag: 'FaceScanPrep');
        } else if (status.isPermanentlyDenied) {
          _permissionError = 'Camera permission permanently denied. Please enable it in Settings.';
          LoggingService.error('Camera permission permanently denied', tag: 'FaceScanPrep');
        } else if (status.isGranted) {
          LoggingService.success('Camera permission granted', tag: 'FaceScanPrep');
        }
      });
    } catch (e) {
      setState(() {
        _requestingPermission = false;
        _cameraPermissionGranted = false;
        _permissionError = 'Failed to request camera permission: $e';
      });
      LoggingService.error('Camera permission error', error: e, tag: 'FaceScanPrep');
    }
  }

  void _proceedToScan() {
    final selectedProfile = _profileService.selectedProfile;
    if (selectedProfile == null) {
      _showProfileSelectionDialog();
      return;
    }

    context.push('/scan/face/camera', extra: {
      'isPartOfAssessment': widget.isPartOfAssessment,
    });
  }

  void _showProfileSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Profile'),
        content: const Text('Please select a profile before starting the scan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/profile/create');
            },
            child: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Scan Preparation'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Illustration
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                        ),
                        child: const Icon(
                          Icons.face,
                          size: 80,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        'Get Ready for Face Scan',
                        style: AppTypography.headingMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Instructions
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preparation Steps',
                                style: AppTypography.headingSmall,
                              ),
                              const SizedBox(height: 16),
                              _buildInstruction(
                                Icons.light_mode,
                                'Good Lighting',
                                'Ensure your face is well-lit and avoid backlighting',
                              ),
                              _buildInstruction(
                                Icons.face_retouching_natural,
                                'Remove Accessories',
                                'Remove glasses, hats, or anything covering your face',
                              ),
                              _buildInstruction(
                                Icons.phone_android,
                                'Hold Steady',
                                'Keep your device stable at eye level',
                              ),
                              _buildInstruction(
                                Icons.timer,
                                'Stay Still',
                                'Remain still during the 30-second scan',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Selected Profile Info
                      ListenableBuilder(
                        listenable: _profileService,
                        builder: (context, child) {
                          final selectedProfile = _profileService.selectedProfile;
                          return Card(
                            color: selectedProfile != null ? AppColors.success.withValues(alpha: 0.05) : AppColors.warning.withValues(alpha: 0.05),
                            child: Padding(
                              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedProfile != null ? Icons.person : Icons.person_off,
                                    color: selectedProfile != null ? AppColors.success : AppColors.warning,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedProfile != null ? 'Selected Profile' : 'No Profile Selected',
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: selectedProfile != null ? AppColors.success : AppColors.warning,
                                          ),
                                        ),
                                        if (selectedProfile != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${selectedProfile.name} • ${selectedProfile.age} years • ${selectedProfile.gender}',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Please select a profile to continue',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (selectedProfile == null)
                                    TextButton(
                                      onPressed: () => context.push('/'),
                                      child: const Text('Select'),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      // Warning
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
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This scan will measure your vital signs using your camera',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
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
              // Continue button
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: ListenableBuilder(
                  listenable: _profileService,
                  builder: (context, child) {
                    final hasSelectedProfile = _profileService.selectedProfile != null;
                    return SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeightLarge,
                      child: ElevatedButton(
                        onPressed: (_requestingPermission || !_cameraPermissionGranted || !hasSelectedProfile)
                            ? null
                            : _proceedToScan,
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
                                    ? (hasSelectedProfile ? 'Start Face Scan' : 'Select Profile First')
                                    : 'Camera Permission Required',
                                style: const TextStyle(fontSize: 18),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
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
}