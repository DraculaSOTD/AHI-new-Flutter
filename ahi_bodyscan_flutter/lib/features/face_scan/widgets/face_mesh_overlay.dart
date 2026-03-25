import 'package:flutter/material.dart';

class FaceMeshOverlay extends StatefulWidget {
  final bool isDetecting;
  final bool isAligned;
  final int meshOpacity; // 0-100
  final List<List<double>>? landmarks; // Optional landmarks data
  
  const FaceMeshOverlay({
    super.key,
    this.isDetecting = false,
    this.isAligned = false,
    this.meshOpacity = 60,
    this.landmarks,
  });

  @override
  State<FaceMeshOverlay> createState() => _FaceMeshOverlayState();
}

class _FaceMeshOverlayState extends State<FaceMeshOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: FaceMeshPainter(
              isDetecting: widget.isDetecting,
              isAligned: widget.isAligned,
              meshOpacity: widget.meshOpacity / 100.0,
              scale: widget.isDetecting ? _pulseAnimation.value : 1.0,
              landmarks: widget.landmarks,
            ),
          );
        },
      ),
    );
  }
}

class FaceMeshPainter extends CustomPainter {
  final bool isDetecting;
  final bool isAligned;
  final double meshOpacity;
  final double scale;
  final List<List<double>>? landmarks;

  FaceMeshPainter({
    required this.isDetecting,
    required this.isAligned,
    required this.meshOpacity,
    required this.scale,
    this.landmarks,
  });
  
  // 68-point face landmark connections (matching React app)
  static const List<List<int>> landmarkConnections = [
    // Jaw line (0-16)
    [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8],
    [8, 9], [9, 10], [10, 11], [11, 12], [12, 13], [13, 14], [14, 15], [15, 16],
    
    // Right eyebrow (17-21)
    [17, 18], [18, 19], [19, 20], [20, 21],
    
    // Left eyebrow (22-26)
    [22, 23], [23, 24], [24, 25], [25, 26],
    
    // Nose bridge (27-30)
    [27, 28], [28, 29], [29, 30],
    
    // Nose bottom (31-35)
    [31, 32], [32, 33], [33, 34], [34, 35], [35, 31],
    
    // Right eye (36-41)
    [36, 37], [37, 38], [38, 39], [39, 40], [40, 41], [41, 36],
    
    // Left eye (42-47)
    [42, 43], [43, 44], [44, 45], [45, 46], [46, 47], [47, 42],
    
    // Outer lips (48-59)
    [48, 49], [49, 50], [50, 51], [51, 52], [52, 53], [53, 54],
    [54, 55], [55, 56], [56, 57], [57, 58], [58, 59], [59, 48],
    
    // Inner lips (60-67)
    [60, 61], [61, 62], [62, 63], [63, 64], [64, 65], [65, 66], [66, 67], [67, 60],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Only draw landmarks if available from SDK - no oval guide
    if (landmarks != null && landmarks!.isNotEmpty) {
      _drawSDKLandmarks(canvas, size);
    } 
    // Draw face oval guide only when no landmarks available
    else {
      final center = Offset(size.width / 2, size.height * 0.35);
      final ovalWidth = size.width * 0.7;
      final ovalHeight = ovalWidth * 1.3;
      _drawFaceOval(canvas, center, ovalWidth, ovalHeight);
    }
    
    // Always draw corner guides for framing
    _drawCornerGuides(canvas, size);
  }
  
  void _drawSDKLandmarks(Canvas canvas, Size size) {
    // Convert landmarks to Offset points
    final points = <Offset>[];
    for (final landmark in landmarks!) {
      if (landmark.length >= 2) {
        // Landmarks are in normalized coordinates (0-1) or pixel coordinates
        // Assuming pixel coordinates matching video dimensions
        points.add(Offset(landmark[0], landmark[1]));
      }
    }
    
    if (points.isEmpty) return;
    
    // Draw connections with green color matching React app
    final linePaint = Paint()
      ..color = const Color(0xFF00FF00).withValues(alpha: meshOpacity * 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Draw landmark connections
    for (final connection in landmarkConnections) {
      if (connection[0] < points.length && connection[1] < points.length) {
        canvas.drawLine(
          points[connection[0]], 
          points[connection[1]], 
          linePaint,
        );
      }
    }
    
    // Draw landmark points
    final dotPaint = Paint()
      ..color = const Color(0xFF00FF00).withValues(alpha: meshOpacity)
      ..style = PaintingStyle.fill;
    
    for (final point in points) {
      canvas.drawCircle(point, 3.0, dotPaint);
    }
  }

  void _drawFaceOval(Canvas canvas, Offset center, double width, double height) {
    // Simple white oval guide when no face is detected
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Rect.fromCenter(
      center: center,
      width: width * scale,
      height: height * scale,
    );
    
    canvas.drawOval(rect, paint);
  }


  void _drawCornerGuides(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: meshOpacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const cornerSize = 30.0;
    const margin = 20.0;
    
    // Top-left corner
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin + cornerSize, margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, margin + cornerSize),
      paint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(size.width - margin - cornerSize, margin),
      Offset(size.width - margin, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + cornerSize),
      paint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(margin, size.height - margin - cornerSize),
      Offset(margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + cornerSize, size.height - margin),
      paint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - margin - cornerSize, size.height - margin),
      Offset(size.width - margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin - cornerSize),
      Offset(size.width - margin, size.height - margin),
      paint,
    );
  }

  @override
  bool shouldRepaint(FaceMeshPainter oldDelegate) {
    return oldDelegate.isDetecting != isDetecting ||
           oldDelegate.isAligned != isAligned ||
           oldDelegate.meshOpacity != meshOpacity ||
           oldDelegate.scale != scale;
  }
}