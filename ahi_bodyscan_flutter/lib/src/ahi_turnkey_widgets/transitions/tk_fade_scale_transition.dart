//
//  AHI Fade Scale Transition Widget
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';

class TkFadeScaleTransition extends StatefulWidget {
  const TkFadeScaleTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.beginScale = 0.8,
    this.endScale = 1.0,
    this.animate = true,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final double beginScale;
  final double endScale;
  final bool animate;

  @override
  State<TkFadeScaleTransition> createState() => _TkFadeScaleTransitionState();
}

class _TkFadeScaleTransitionState extends State<TkFadeScaleTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.animate) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Utility function to create staggered fade scale animations
class TkStaggeredFadeScaleTransitions extends StatelessWidget {
  const TkStaggeredFadeScaleTransitions({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutCubic,
    this.beginScale = 0.8,
    this.endScale = 1.0,
  });

  final List<Widget> children;
  final Duration duration;
  final Duration staggerDelay;
  final Curve curve;
  final double beginScale;
  final double endScale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return TkFadeScaleTransition(
          duration: duration,
          curve: curve,
          delay: staggerDelay * index,
          beginScale: beginScale,
          endScale: endScale,
          child: child,
        );
      }).toList(),
    );
  }
}