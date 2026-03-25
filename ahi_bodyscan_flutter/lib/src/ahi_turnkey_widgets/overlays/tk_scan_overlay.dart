//
//  AHI Scan Overlay Widget
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum TkScanOverlayType {
  body,
  face,
  finger,
}

class TkScanOverlay extends StatefulWidget {
  const TkScanOverlay({
    super.key,
    required this.type,
    this.isScanning = false,
    this.progress = 0.0,
    this.message,
    this.showGuide = true,
  });

  final TkScanOverlayType type;
  final bool isScanning;
  final double progress;
  final String? message;
  final bool showGuide;

  @override
  State<TkScanOverlay> createState() => _TkScanOverlayState();
}

class _TkScanOverlayState extends State<TkScanOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    if (widget.isScanning) {
      _scanController.repeat();
    }
  }

  @override
  void didUpdateWidget(TkScanOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isScanning && !oldWidget.isScanning) {
      _scanController.repeat();
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _scanController.stop();
      _scanController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main overlay shape
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isScanning ? 1.0 : _pulseAnimation.value,
                child: _buildOverlayShape(),
              );
            },
          ),
        ),

        // Scanning line animation
        if (widget.isScanning)
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ScanLinePainter(
                  progress: _scanAnimation.value,
                  type: widget.type,
                ),
                size: Size.infinite,
              );
            },
          ),

        // Progress indicator
        if (widget.progress > 0)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: widget.progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getOverlayColor(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(widget.progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Message
        if (widget.message != null)
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.message!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // Corner guides
        if (widget.showGuide && widget.type == TkScanOverlayType.body)
          _buildCornerGuides(),
      ],
    );
  }

  Widget _buildOverlayShape() {
    switch (widget.type) {
      case TkScanOverlayType.body:
        return _buildBodyOverlay();
      case TkScanOverlayType.face:
        return _buildFaceOverlay();
      case TkScanOverlayType.finger:
        return _buildFingerOverlay();
    }
  }

  Widget _buildBodyOverlay() {
    return CustomPaint(
      painter: BodyOutlinePainter(
        color: _getOverlayColor(),
        isScanning: widget.isScanning,
      ),
      size: const Size(200, 350),
    );
  }

  Widget _buildFaceOverlay() {
    return Container(
      width: 250,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _getOverlayColor(),
          width: 3,
        ),
      ),
    );
  }

  Widget _buildFingerOverlay() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _getOverlayColor(),
          width: 3,
        ),
      ),
      child: Icon(
        Icons.fingerprint,
        size: 80,
        color: _getOverlayColor(),
      ),
    );
  }

  Widget _buildCornerGuides() {
    return Positioned.fill(
      child: CustomPaint(
        painter: CornerGuidesPainter(
          color: _getOverlayColor(),
        ),
      ),
    );
  }

  Color _getOverlayColor() {
    if (widget.isScanning) {
      return AppColors.success;
    }
    
    switch (widget.type) {
      case TkScanOverlayType.body:
        return AppColors.primaryBlue;
      case TkScanOverlayType.face:
        return AppColors.primaryPurple;
      case TkScanOverlayType.finger:
        return AppColors.accentTeal;
    }
  }
}

class BodyOutlinePainter extends CustomPainter {
  const BodyOutlinePainter({
    required this.color,
    required this.isScanning,
  });

  final Color color;
  final bool isScanning;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color;

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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class ScanLinePainter extends CustomPainter {
  const ScanLinePainter({
    required this.progress,
    required this.type,
  });
  
  final double progress;
  final TkScanOverlayType type;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 3;

    final y = size.height * 0.2 + (progress * size.height * 0.6);
    
    canvas.drawLine(
      Offset(size.width * 0.2, y),
      Offset(size.width * 0.8, y),
      paint,
    );
    
    // Add glow effect
    paint
      ..color = AppColors.success.withValues(alpha: 0.3)
      ..strokeWidth = 8;
    
    canvas.drawLine(
      Offset(size.width * 0.2, y),
      Offset(size.width * 0.8, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CornerGuidesPainter extends CustomPainter {
  const CornerGuidesPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = color;

    final bracketSize = 30.0;
    final margin = 40.0;
    
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
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}