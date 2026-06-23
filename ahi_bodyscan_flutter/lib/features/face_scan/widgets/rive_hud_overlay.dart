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
  // Per-vital text-run values for the Rive HUD tiles. Null shows '--'.
  final String? rrValue;
  final String? spo2Value;
  final String? hrvValue;
  final String? siValue;
  final String? bpValue;
  final Map<String, bool> completionStates;
  final VoidCallback? onBackTapped;

  const RiveHUDOverlay({
    super.key,
    required this.haloState,
    required this.guideText,
    required this.contextText,
    this.bpmValue = '--',
    this.rrValue,
    this.spo2Value,
    this.hrvValue,
    this.siValue,
    this.bpValue,
    this.completionStates = const {},
    this.onBackTapped,
  });
  
  @override
  State<RiveHUDOverlay> createState() => _RiveHUDOverlayState();
}

class _RiveHUDOverlayState extends State<RiveHUDOverlay> {
  StateMachineController? _controller;
  Artboard? _artboard;
  bool _ranInitialTextRunProbe = false;
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
    _artboard = artboard;

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
      _updateTextRuns();
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
    _updateTextRuns();
  }

  void _updateTextRuns() {
    final ab = _artboard;
    if (ab == null) return;
    void set(String name, String value) {
      try {
        ab.component<TextValueRun>(name)?.text = value;
      } catch (_) {}
    }

    // BPM in the Rive scene appears under at least two names — `bpmText` for the
    // per-tile display and `bpmTop` for the big number above the face oval. Set
    // every plausible variant; whichever the scene actually uses wins, the rest
    // no-op silently.
    set('bpmTop',   widget.bpmValue);
    set('bpmText',  widget.bpmValue);
    set('bpmValue', widget.bpmValue);
    set('BPMvar',   widget.bpmValue);

    set('rrTop',    widget.rrValue   ?? '--');
    set('rrText',   widget.rrValue   ?? '--');

    set('sp02Top',  widget.spo2Value ?? '--');
    set('sp02Text', widget.spo2Value ?? '--');

    set('hrvTop',   widget.hrvValue  ?? '--');
    set('hrvText',  widget.hrvValue  ?? '--');

    set('siTop',    widget.siValue   ?? '--');
    set('siText',   widget.siValue   ?? '--');

    set('bpTop',    widget.bpValue   ?? '--');
    set('bpText',   widget.bpValue   ?? '--');

    if (!_ranInitialTextRunProbe) {
      _ranInitialTextRunProbe = true;
      const candidates = [
        'bpmTop','bpmText','bpmValue','BPMvar',
        'rrTop','rrText',
        'sp02Top','sp02Text',
        'hrvTop','hrvText',
        'siTop','siText',
        'bpTop','bpText',
      ];
      for (final n in candidates) {
        final found = ab.component<TextValueRun>(n) != null;
        LoggingService.debug('Rive run probe: $n -> $found',
            tag: 'RiveHUD');
      }
    }
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

      ],
    );
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}