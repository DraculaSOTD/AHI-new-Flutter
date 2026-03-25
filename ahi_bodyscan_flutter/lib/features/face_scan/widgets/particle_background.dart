import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated particle background for face scan camera
class ParticleBackground extends StatefulWidget {
  final Color particleColor;
  final Color backgroundColor;
  final int particleCount;
  
  const ParticleBackground({
    super.key,
    this.particleColor = const Color.fromRGBO(106, 0, 255, 1),
    this.backgroundColor = Colors.black,
    this.particleCount = 50,
  });
  
  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late List<Particle> particles;
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    
    particles = List.generate(
      widget.particleCount,
      (index) => Particle.random(),
    );
    
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    _controller.addListener(() {
      setState(() {
        for (var particle in particles) {
          particle.update();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: CustomPaint(
        painter: ParticlePainter(
          particles: particles,
          particleColor: widget.particleColor,
        ),
        child: Container(),
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double z;
  double vx;
  double vy;
  double vz;
  double radius;
  double opacity;
  
  Particle({
    required this.x,
    required this.y,
    required this.z,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.radius,
    required this.opacity,
  });
  
  factory Particle.random() {
    final random = math.Random();
    return Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      z: random.nextDouble(),
      vx: (random.nextDouble() - 0.5) * 0.002,
      vy: (random.nextDouble() - 0.5) * 0.002,
      vz: (random.nextDouble() - 0.5) * 0.001,
      radius: random.nextDouble() * 2 + 1,
      opacity: random.nextDouble() * 0.5 + 0.2,
    );
  }
  
  void update() {
    x += vx;
    y += vy;
    z += vz;
    
    // Wrap around edges
    if (x < 0) x = 1;
    if (x > 1) x = 0;
    if (y < 0) y = 1;
    if (y > 1) y = 0;
    if (z < 0) z = 1;
    if (z > 1) z = 0;
    
    // Pulse opacity
    opacity = (math.sin(DateTime.now().millisecondsSinceEpoch * 0.001 + x * 10) + 1) * 0.25 + 0.2;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color particleColor;
  
  ParticlePainter({
    required this.particles,
    required this.particleColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Draw connections between nearby particles
    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    for (int i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      
      // Draw particle
      final particleX = p1.x * size.width;
      final particleY = p1.y * size.height;
      final adjustedRadius = p1.radius * (1 + p1.z); // Size based on depth
      final adjustedOpacity = p1.opacity * (0.5 + p1.z * 0.5); // Opacity based on depth
      
      paint.color = particleColor.withValues(alpha: adjustedOpacity);
      canvas.drawCircle(
        Offset(particleX, particleY),
        adjustedRadius,
        paint,
      );
      
      // Draw connections to nearby particles
      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final dx = (p1.x - p2.x) * size.width;
        final dy = (p1.y - p2.y) * size.height;
        final distance = math.sqrt(dx * dx + dy * dy);
        
        if (distance < 100) {
          final opacity = (1 - distance / 100) * 0.2;
          connectionPaint.color = particleColor.withValues(alpha: opacity);
          
          canvas.drawLine(
            Offset(p1.x * size.width, p1.y * size.height),
            Offset(p2.x * size.width, p2.y * size.height),
            connectionPaint,
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}