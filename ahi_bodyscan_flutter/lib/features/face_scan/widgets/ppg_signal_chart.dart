import 'package:flutter/material.dart';

/// PPG (Photoplethysmography) Signal Chart for displaying heart rate signal
/// Lightweight canvas-based implementation matching React app
class PPGSignalChart extends StatelessWidget {
  final List<double> signal;
  final bool visible;
  final Color color;
  final double lineWidth;
  final int maxSamples;

  const PPGSignalChart({
    super.key,
    required this.signal,
    this.visible = true,
    this.color = Colors.white,
    this.lineWidth = 1.0,
    this.maxSamples = 75,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible || signal.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 120,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: CustomPaint(
        painter: PPGSignalPainter(
          signal: signal,
          color: color,
          lineWidth: lineWidth,
          maxSamples: maxSamples,
        ),
      ),
    );
  }
}

class PPGSignalPainter extends CustomPainter {
  final List<double> signal;
  final Color color;
  final double lineWidth;
  final int maxSamples;

  PPGSignalPainter({
    required this.signal,
    required this.color,
    required this.lineWidth,
    required this.maxSamples,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (signal.isEmpty) return;

    // Limit the number of entries in the signal
    final displaySignal = signal.length > maxSamples
        ? signal.sublist(signal.length - maxSamples)
        : signal;

    if (displaySignal.length < 2) return;

    // Find min and max for normalization
    double maxSignal = displaySignal.reduce((a, b) => a > b ? a : b);
    double minSignal = displaySignal.reduce((a, b) => a < b ? a : b);
    final range = maxSignal - minSignal;
    if (range == 0) return;

    // Scale the x-axis to fit within the canvas width
    final xScale = size.width / (displaySignal.length - 1);

    // Create paint object
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Create path for the signal
    final path = Path();
    
    for (int i = 0; i < displaySignal.length; i++) {
      // Normalize the signal to the range of the canvas height
      final normalizedY = ((displaySignal[i] - minSignal) / range) * size.height;
      // Invert Y axis (canvas Y=0 is at top)
      final y = size.height - normalizedY;
      final x = i * xScale;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw the signal
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PPGSignalPainter oldDelegate) {
    return oldDelegate.signal != signal ||
           oldDelegate.color != color ||
           oldDelegate.lineWidth != lineWidth;
  }
}