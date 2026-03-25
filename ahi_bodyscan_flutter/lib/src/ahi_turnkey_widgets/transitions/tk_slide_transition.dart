//
//  AHI Slide Transition Widget
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';

enum TkSlideDirection {
  up,
  down,
  left,
  right,
}

class TkSlideTransition extends StatefulWidget {
  const TkSlideTransition({
    super.key,
    required this.child,
    this.direction = TkSlideDirection.up,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.animate = true,
  });

  final Widget child;
  final TkSlideDirection direction;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final bool animate;

  @override
  State<TkSlideTransition> createState() => _TkSlideTransitionState();
}

class _TkSlideTransitionState extends State<TkSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: _getBeginOffset(),
      end: Offset.zero,
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

  Offset _getBeginOffset() {
    switch (widget.direction) {
      case TkSlideDirection.up:
        return const Offset(0, 1);
      case TkSlideDirection.down:
        return const Offset(0, -1);
      case TkSlideDirection.left:
        return const Offset(1, 0);
      case TkSlideDirection.right:
        return const Offset(-1, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return widget.child;
    }

    return SlideTransition(
      position: _slideAnimation,
      child: widget.child,
    );
  }
}

/// Utility function to create staggered slide animations
class TkStaggeredSlideTransitions extends StatelessWidget {
  const TkStaggeredSlideTransitions({
    super.key,
    required this.children,
    this.direction = TkSlideDirection.up,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutCubic,
  });

  final List<Widget> children;
  final TkSlideDirection direction;
  final Duration duration;
  final Duration staggerDelay;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return TkSlideTransition(
          direction: direction,
          duration: duration,
          curve: curve,
          delay: staggerDelay * index,
          child: child,
        );
      }).toList(),
    );
  }
}