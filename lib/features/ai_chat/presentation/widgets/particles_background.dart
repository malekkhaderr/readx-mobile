import 'dart:math';
import 'package:flutter/material.dart';
import 'chat_theme.dart';

class ParticlesBackground extends StatefulWidget {
  const ParticlesBackground({super.key});
  @override State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(x: _random.nextDouble(), y: _random.nextDouble(), size: 2 + _random.nextDouble() * 4, speed: 0.05 + _random.nextDouble() * 0.2, opacity: 0.03 + _random.nextDouble() * 0.05, phase: _random.nextDouble() * 2 * pi, isAccent: _random.nextBool()));
    }
  }

  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(animation: _controller, builder: (_, __) => CustomPaint(painter: _ParticlesPainter(particles: _particles, progress: _controller.value, isDark: isDark), size: Size.infinite));
  }
}

class _Particle {
  final double x, y, size, speed, opacity, phase;
  final bool isAccent;
  const _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity, required this.phase, required this.isAccent});
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles; final double progress; final bool isDark;
  _ParticlesPainter({required this.particles, required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y + progress * p.speed) % 1.0;
      final x = p.x + sin(progress * 2 * pi + p.phase) * 0.015;
      final color = p.isAccent ? ChatColors.particleViolet : ChatColors.particlePurple;
      final opacity = isDark ? p.opacity : p.opacity * 0.6;
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, Paint()..color = color.withOpacity(opacity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    }
  }

  @override bool shouldRepaint(covariant _ParticlesPainter old) => true;
}
