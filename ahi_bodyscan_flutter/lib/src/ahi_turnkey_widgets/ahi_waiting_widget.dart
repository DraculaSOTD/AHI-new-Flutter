//
//  AHI Waiting Widget - Advanced Animation Component
//
//  Copyright (c) AHI. All rights reserved.
//

import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TkWaitingWidget extends StatefulWidget {
  const TkWaitingWidget({
    super.key, 
    this.numberOfCircles = 42,
    this.size = 250,
    this.showTitle = true,
  });
  final int numberOfCircles;
  final double size;
  final bool showTitle;

  @override
  State<TkWaitingWidget> createState() => _TkWaitingWidgetState();
}

class _TkWaitingWidgetState extends State<TkWaitingWidget>
    with TickerProviderStateMixin {
  final Random random = Random();
  final List<AnimationController> _scaleControllers = <AnimationController>[];
  final List<Animation<double>> _radiusAnimations = <Animation<double>>[];
  final List<AnimationController> _rotationControllers =
      <AnimationController>[];
  late AnimationController _opacityController;

  final List<int> _paddingValues = <int>[];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.numberOfCircles; i++) {
      _scaleControllers.add(AnimationController(
        duration: Duration(milliseconds: random.nextInt(500) + 1500),
        vsync: this,
      ));
      if (i % 4 == 0) {
        _rotationControllers.add(AnimationController(
          duration: Duration(seconds: random.nextInt(50) + 20),
          vsync: this,
        )..repeat(reverse: true));
      } else {
        _rotationControllers.add(AnimationController(
          duration: Duration(seconds: random.nextInt(20) + 20),
          vsync: this,
        )..repeat());
      }
      _radiusAnimations.add(Tween<double>(begin: 1, end: 1.07).animate(
        CurvedAnimation(parent: _scaleControllers[i], curve: Curves.easeInOut),
      )..addListener(() {
          setState(() {});
        }));

      _scaleControllers[i].repeat(reverse: true);
      _paddingValues.add(random.nextInt(150) + 16);
    }
    _opacityController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    for (final AnimationController element in _scaleControllers) {
      element.dispose();
    }
    for (final AnimationController element in _rotationControllers) {
      element.dispose();
    }
    _opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size + (widget.showTitle ? 60 : 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final List<Widget> circles = <Widget>[];
                for (int i = 0; i < widget.numberOfCircles; i++) {
                  final Widget widget = Transform.rotate(
                    angle: (pi / 4) * i, // 45 degrees in radians
                    child: Opacity(
                      opacity: i < this.widget.numberOfCircles / 2
                          ? _opacityController.value
                          : 1,
                      child: RotationTransition(
                        turns: _rotationControllers[i],
                        child: CustomPaint(
                          size: Size(constraints.maxWidth - _paddingValues[i],
                              constraints.maxWidth - _paddingValues[i]),
                          painter: WavyCirclePainter(
                            radiusAnimation: _radiusAnimations[i].value,
                            color: i % 3 == 0
                                ? AppColors.primaryPurple
                                : i % 3 == 1
                                    ? AppColors.primaryBlue
                                    : AppColors.accentTeal,
                          ),
                        ),
                      ),
                    ),
                  );
                  circles.add(widget);
                }
                return Stack(
                  alignment: Alignment.center,
                  children: circles,
                );
              },
            ),
          ),
          if (widget.showTitle) ...[
            const SizedBox(height: 20),
            const Text(
              'Processing...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WavyCirclePainter extends CustomPainter {
  WavyCirclePainter({
    required this.radiusAnimation,
    this.color = Colors.blueAccent,
    this.opacity = 0.6,
  });
  final double radiusAnimation;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Path path = Path();

    final double halfWidth = (size.width) / 2;
    int counter = 0;
    const int numberOfPoints = 24;
    final double radius = halfWidth / (1.11 * radiusAnimation);
    final double outerCurveRadius = size.width / (2.08 * radiusAnimation);
    final double innerCurveRadius = size.width / (2.42 / radiusAnimation);
    const double max = 2 * pi;
    final double degreesPerStep = _degToRad(360 / numberOfPoints) as double;
    final double halfDegreesPerStep = degreesPerStep / 2;

    for (double step = 0; step < max + 1; step += degreesPerStep) {
      if (counter == 0) {
        path.moveTo(
          halfWidth + radius * cos(step + halfDegreesPerStep),
          halfWidth + radius * sin(step + halfDegreesPerStep),
        );
      }
      if (counter.isEven) {
        path.quadraticBezierTo(
          halfWidth + outerCurveRadius * cos(step),
          halfWidth + outerCurveRadius * sin(step),
          halfWidth + radius * cos(step + halfDegreesPerStep),
          halfWidth + radius * sin(step + halfDegreesPerStep),
        );
      } else {
        path.quadraticBezierTo(
          halfWidth + innerCurveRadius * cos(step),
          halfWidth + innerCurveRadius * sin(step),
          halfWidth + radius * cos(step + halfDegreesPerStep),
          halfWidth + radius * sin(step + halfDegreesPerStep),
        );
      }
      counter++;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  num _degToRad(num deg) => deg * (pi / 180.0);
}