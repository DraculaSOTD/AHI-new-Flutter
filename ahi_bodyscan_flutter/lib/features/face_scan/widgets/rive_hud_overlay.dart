import '../../../core/services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Rive-powered HUD Overlay widget matching React app
class RiveHUDOverlay extends StatefulWidget {
  final int haloState; // 0-4 for different states
  final String guideText;
  final String contextText;
  final String bpmValue;
  final Map<String, bool> completionStates;
  final VoidCallback? onBackTapped;
  
  const RiveHUDOverlay({
    super.key,
    required this.haloState,
    required this.guideText,
    required this.contextText,
    this.bpmValue = '--',
    this.completionStates = const {},
    this.onBackTapped,
  });
  
  @override
  State<RiveHUDOverlay> createState() => _RiveHUDOverlayState();
}

class _RiveHUDOverlayState extends State<RiveHUDOverlay> {
  StateMachineController? _controller;
  SMINumber? _haloStateInput;
  SMIBool? _isCalibratedInput;
  SMIBool? _bpmCompleteInput;
  SMIBool? _rrCompleteInput;
  SMIBool? _spo2CompleteInput;
  SMIBool? _hrvCompleteInput;
  SMIBool? _siCompleteInput;
  SMIBool? _bpCompleteInput;
  
  void _onRiveInit(Artboard artboard) {
    LoggingService.info('Initializing artboard', tag: 'RiveHUD');
    
    // Get the state machine controller
    final controller = StateMachineController.fromArtboard(
      artboard,
      'SM', // State machine name from the Rive file
    );
    
    if (controller != null) {
      LoggingService.success('State machine controller found', tag: 'RiveHUD');
      artboard.addController(controller);
      _controller = controller;
      
      // Find all the inputs
      _haloStateInput = controller.findInput<double>('haloState') as SMINumber?;
      _isCalibratedInput = controller.findInput<bool>('isCalibrated') as SMIBool?;
      _bpmCompleteInput = controller.findInput<bool>('bpm_isComplete') as SMIBool?;
      _rrCompleteInput = controller.findInput<bool>('rr_isComplete') as SMIBool?;
      _spo2CompleteInput = controller.findInput<bool>('spo2_isComplete') as SMIBool?;
      _hrvCompleteInput = controller.findInput<bool>('hrv_isComplete') as SMIBool?;
      _siCompleteInput = controller.findInput<bool>('si_isComplete') as SMIBool?;
      _bpCompleteInput = controller.findInput<bool>('bp_isComplete') as SMIBool?;
      
      // Debug log which inputs were found
      LoggingService.debug('Rive HUD inputs found', tag: 'RiveHUD', context: {
        'haloState': _haloStateInput != null,
        'isCalibrated': _isCalibratedInput != null,
        'bpm_isComplete': _bpmCompleteInput != null,
        'rr_isComplete': _rrCompleteInput != null,
        'spo2_isComplete': _spo2CompleteInput != null,
        'hrv_isComplete': _hrvCompleteInput != null,
        'si_isComplete': _siCompleteInput != null,
        'bp_isComplete': _bpCompleteInput != null,
      });
      
      // Set initial values
      _updateRiveInputs();
    } else {
      LoggingService.error('State machine controller not found', tag: 'RiveHUD');
    }
  }
  
  @override
  void didUpdateWidget(RiveHUDOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // DIAGNOSTIC: Log widget updates
    if (widget.haloState != oldWidget.haloState ||
        widget.guideText != oldWidget.guideText ||
        widget.bpmValue != oldWidget.bpmValue) {
      LoggingService.info('Rive HUD Widget Updated', tag: 'RiveHUD', context: {
        'haloState': '${oldWidget.haloState} → ${widget.haloState}',
        'guideText': widget.guideText,
        'bpmValue': widget.bpmValue,
      });
    }

    _updateRiveInputs();
  }

  void _updateRiveInputs() {
    if (_controller == null) {
      LoggingService.warning('Rive controller is NULL, cannot update inputs', tag: 'RiveHUD');
      return;
    }
    
    // Update halo state
    if (_haloStateInput != null) {
      _haloStateInput!.value = widget.haloState.toDouble();
      LoggingService.debug('Set haloState', tag: 'RiveHUD', context: {'haloState': widget.haloState});
    }
    
    // Update calibration state
    if (_isCalibratedInput != null) {
      final isCalibrated = widget.haloState == 1 || widget.haloState == 2;
      _isCalibratedInput!.value = isCalibrated;
      LoggingService.debug('Set isCalibrated', tag: 'RiveHUD', context: {'isCalibrated': isCalibrated});
    }
    
    // Update completion states
    if (_bpmCompleteInput != null) {
      _bpmCompleteInput!.value = widget.completionStates['bpm_isComplete'] ?? false;
    }
    if (_rrCompleteInput != null) {
      _rrCompleteInput!.value = widget.completionStates['rr_isComplete'] ?? false;
    }
    if (_spo2CompleteInput != null) {
      _spo2CompleteInput!.value = widget.completionStates['spo2_isComplete'] ?? false;
    }
    if (_hrvCompleteInput != null) {
      _hrvCompleteInput!.value = widget.completionStates['hrv_isComplete'] ?? false;
    }
    if (_siCompleteInput != null) {
      _siCompleteInput!.value = widget.completionStates['si_isComplete'] ?? false;
    }
    if (_bpCompleteInput != null) {
      _bpCompleteInput!.value = widget.completionStates['bp_isComplete'] ?? false;
    }
    
    // Debug log completion states
    if (widget.completionStates.isNotEmpty) {
      LoggingService.debug('Updated completion states', tag: 'RiveHUD', context: widget.completionStates);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Rive animation layer using RiveAnimation.asset
        // Using BoxFit.cover to scale by height on portrait screens
        Positioned.fill(
          child: RiveAnimation.asset(
            'assets/rive/hud.riv',
            stateMachines: const ['SM'],
            fit: BoxFit.cover,  // Changed to cover to fill height
            alignment: Alignment.center,
            onInit: _onRiveInit,
          ),
          // Alternative if cover crops too much:
          // child: Transform.scale(
          //   scale: 1.5, // Adjust this value as needed
          //   child: RiveAnimation.asset(
          //     'assets/rive/hud.riv',
          //     stateMachines: const ['SM'],
          //     fit: BoxFit.contain,
          //     alignment: Alignment.center,
          //     onInit: _onRiveInit,
          //   ),
          // ),
        ),
        
        // Back button
        if (widget.onBackTapped != null)
          Positioned(
            top: 50,
            left: 20,
            child: SafeArea(
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  onTap: widget.onBackTapped,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Text overlay for guide text (since Rive text update isn't available in Flutter)
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.guideText,
                    style: AppTypography.headingSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.contextText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom metrics panel
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMetric(
                    icon: Icons.favorite,
                    value: widget.bpmValue,
                    unit: 'BPM',
                    color: Colors.red,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.divider,
                  ),
                  _buildMetric(
                    icon: Icons.timer,
                    value: '${_getProgress()}',
                    unit: '%',
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                unit,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getProgress() {
    final total = widget.completionStates.length;
    if (total == 0) return 0;
    final completed = widget.completionStates.values
        .where((isComplete) => isComplete)
        .length;
    return ((completed / total) * 100).round();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}