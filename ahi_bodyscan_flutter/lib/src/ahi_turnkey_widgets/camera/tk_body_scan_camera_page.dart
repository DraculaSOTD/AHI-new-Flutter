//
//  AHI Body Scan Camera Page
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/ahi_user_data.dart';
import '../../ahi_turnkey_services/ahi_audio_service.dart';

class TkBodyScanCameraPage extends StatefulWidget {
  const TkBodyScanCameraPage({
    super.key,
    required this.userData,
    required this.onScanComplete,
    required this.onCancel,
  });

  final TkUserData userData;
  final Function(Map<String, dynamic>) onScanComplete;
  final VoidCallback onCancel;

  @override
  State<TkBodyScanCameraPage> createState() => _TkBodyScanCameraPageState();
}

class _TkBodyScanCameraPageState extends State<TkBodyScanCameraPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanLineAnimation;
  
  bool _isScanning = false;
  bool _showCountdown = false;
  int _countdown = 3;
  ScanPhase _currentPhase = ScanPhase.positioning;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _scanLineAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.linear),
    );

    // Start positioning guidance
    _startPositioningGuidance();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _startPositioningGuidance() {
    // Simulate positioning detection after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentPhase == ScanPhase.positioning) {
        setState(() {
          _currentPhase = ScanPhase.ready;
        });
      }
    });
  }

  void _startCountdown() async {
    setState(() {
      _showCountdown = true;
      _countdown = 3;
    });

    for (int i = 3; i > 0; i--) {
      setState(() {
        _countdown = i;
      });
      HapticFeedback.lightImpact();
      AHIAudioService().playCountdownBeep();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (mounted) {
      _startScanning();
    }
  }

  void _startScanning() async {
    setState(() {
      _isScanning = true;
      _showCountdown = false;
      _currentPhase = ScanPhase.frontScan;
    });

    // Front scan phase
    _scanLineController.repeat();
    HapticFeedback.mediumImpact();
    AHIAudioService().playScanStart();
    
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      setState(() {
        _currentPhase = ScanPhase.sideScan;
      });
      
      await Future.delayed(const Duration(seconds: 4));
      
      if (mounted) {
        _scanLineController.stop();
        AHIAudioService().playScanComplete();
        
        // Mock successful scan result
        widget.onScanComplete({
          'success': true,
          'frontImagePath': '/mock/front_image.jpg',
          'sideImagePath': '/mock/side_image.jpg',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview placeholder (in real implementation, this would be the camera feed)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1a1a1a),
                  Color(0xFF000000),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                'Camera Feed\n(Placeholder)',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Scan overlay
          if (_isScanning)
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScanLinePainter(_scanLineAnimation.value),
                  size: Size.infinite,
                );
              },
            ),

          // Body outline guide
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isScanning ? 1.0 : _pulseAnimation.value,
                  child: CustomPaint(
                    painter: BodyOutlinePainter(
                      phase: _currentPhase,
                      isScanning: _isScanning,
                    ),
                    size: const Size(200, 350),
                  ),
                );
              },
            ),
          ),

          // Top overlay with status
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Text(
                        _getPhaseTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onCancel,
                      ),
                    ],
                  ),
                ),

                // Status message
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPhaseMessage(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Countdown overlay
          if (_showCountdown)
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: Text(
                    _countdown.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Bottom instructions and scan button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getBottomInstructions(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    if (_currentPhase == ScanPhase.ready && !_isScanning)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _startCountdown,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Start Scan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPhaseTitle() {
    switch (_currentPhase) {
      case ScanPhase.positioning:
        return 'Position Yourself';
      case ScanPhase.ready:
        return 'Ready to Scan';
      case ScanPhase.frontScan:
        return 'Front Scan';
      case ScanPhase.sideScan:
        return 'Side Scan';
    }
  }

  String _getPhaseMessage() {
    switch (_currentPhase) {
      case ScanPhase.positioning:
        return 'Stand 8 feet away, keep your full body visible';
      case ScanPhase.ready:
        return 'Perfect positioning! Tap Start Scan when ready';
      case ScanPhase.frontScan:
        return 'Hold still - scanning front view';
      case ScanPhase.sideScan:
        return 'Turn to your side - scanning side view';
    }
  }

  String _getBottomInstructions() {
    switch (_currentPhase) {
      case ScanPhase.positioning:
        return 'Move back until your full body fits within the outline';
      case ScanPhase.ready:
        return 'Keep your arms slightly away from your body';
      case ScanPhase.frontScan:
        return 'Stay perfectly still during the scan';
      case ScanPhase.sideScan:
        return 'Turn 90° to your right and hold still';
    }
  }
}

enum ScanPhase {
  positioning,
  ready,
  frontScan,
  sideScan,
}

class BodyOutlinePainter extends CustomPainter {
  const BodyOutlinePainter({
    required this.phase,
    required this.isScanning,
  });

  final ScanPhase phase;
  final bool isScanning;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Determine outline color based on phase
    Color outlineColor;
    switch (phase) {
      case ScanPhase.positioning:
        outlineColor = Colors.orange;
        break;
      case ScanPhase.ready:
        outlineColor = Colors.green;
        break;
      case ScanPhase.frontScan:
      case ScanPhase.sideScan:
        outlineColor = AppColors.primaryPurple;
        break;
    }

    paint.color = outlineColor;

    // Draw simple body outline
    final center = Offset(size.width / 2, size.height / 2);
    final headRadius = size.width * 0.08;
    
    // Head
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.height * 0.35),
      headRadius,
      paint,
    );
    
    // Body outline
    final bodyPath = Path();
    bodyPath.moveTo(center.dx, center.dy - size.height * 0.27); // Neck
    bodyPath.lineTo(center.dx - size.width * 0.15, center.dy - size.height * 0.1); // Left shoulder
    bodyPath.lineTo(center.dx - size.width * 0.2, center.dy + size.height * 0.1); // Left arm
    bodyPath.lineTo(center.dx - size.width * 0.15, center.dy + size.height * 0.2); // Left waist
    bodyPath.lineTo(center.dx - size.width * 0.1, center.dy + size.height * 0.45); // Left leg
    bodyPath.lineTo(center.dx + size.width * 0.1, center.dy + size.height * 0.45); // Right leg
    bodyPath.lineTo(center.dx + size.width * 0.15, center.dy + size.height * 0.2); // Right waist
    bodyPath.lineTo(center.dx + size.width * 0.2, center.dy + size.height * 0.1); // Right arm
    bodyPath.lineTo(center.dx + size.width * 0.15, center.dy - size.height * 0.1); // Right shoulder
    bodyPath.close();
    
    canvas.drawPath(bodyPath, paint);
    
    // Add corner brackets if ready or scanning
    if (phase == ScanPhase.ready || isScanning) {
      _drawCornerBrackets(canvas, size, paint);
    }
  }

  void _drawCornerBrackets(Canvas canvas, Size size, Paint paint) {
    paint.strokeWidth = 4;
    final bracketSize = 20.0;
    final margin = 10.0;
    
    // Top-left
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin + bracketSize, margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, margin + bracketSize),
      paint,
    );
    
    // Top-right
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin - bracketSize, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + bracketSize),
      paint,
    );
    
    // Bottom-left
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + bracketSize, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin, size.height - margin - bracketSize),
      paint,
    );
    
    // Bottom-right
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin - bracketSize, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - bracketSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class ScanLinePainter extends CustomPainter {
  const ScanLinePainter(this.progress);
  
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryPurple
      ..strokeWidth = 3;

    final y = size.height * 0.5 + (progress * size.height * 0.4);
    
    canvas.drawLine(
      Offset(size.width * 0.1, y),
      Offset(size.width * 0.9, y),
      paint,
    );
    
    // Add scan line glow effect
    paint
      ..color = AppColors.primaryPurple.withValues(alpha: 0.3)
      ..strokeWidth = 8;
    
    canvas.drawLine(
      Offset(size.width * 0.1, y),
      Offset(size.width * 0.9, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}