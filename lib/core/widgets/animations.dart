import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
// FadeSlideIn — animates a widget in with fade + upward slide
// Use for staggered list/section entrance effects.
// ─────────────────────────────────────────────────────────

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 30,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ScaleOnTap — wraps any tappable to give a satisfying press
// scale animation. Press → scale 0.96, release → bounce back.
// ─────────────────────────────────────────────────────────

class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleAmount;
  final Duration duration;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleAmount = 0.96,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: widget.scaleAmount,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.forward(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) =>
            Transform.scale(scale: _controller.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ShakeWidget — call .shake() on the controller to trigger
// a horizontal shake animation. Used to flag errors.
// ─────────────────────────────────────────────────────────

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final ShakeController controller;

  const ShakeWidget({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class ShakeController extends ChangeNotifier {
  void shake() => notifyListeners();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    widget.controller.addListener(_onShake);
  }

  void _onShake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onShake);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        final progress = _animation.value;
        final dx =
            math.sin(progress * math.pi * 4) * (1 - progress) * 12;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────
// AnimatedStars — animates rating stars filling in one by one
// ─────────────────────────────────────────────────────────

class AnimatedStars extends StatefulWidget {
  final double rating; // 0.0 .. 5.0
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final Duration duration;

  const AnimatedStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.filledColor = const Color(0xFFFFD700),
    this.emptyColor = const Color(0xFFE0E0E0),
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<AnimatedStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.duration);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(AnimatedStars old) {
    super.didUpdateWidget(old);
    if (old.rating != widget.rating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final progress = _controller.value;
        final animatedRating = widget.rating * progress;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final star = i + 1;
            IconData icon;
            Color color;
            double scale = 1.0;

            if (animatedRating >= star) {
              icon = Icons.star_rounded;
              color = widget.filledColor;
              // Pop scale when the star fills
              final fillProgress =
                  ((animatedRating - i).clamp(0.0, 1.0));
              scale = 1.0 + (fillProgress < 0.3 ? fillProgress : 0) * 0.6;
            } else if (animatedRating >= star - 0.5) {
              icon = Icons.star_half_rounded;
              color = widget.filledColor;
            } else {
              icon = Icons.star_outline_rounded;
              color = widget.emptyColor;
            }

            return Transform.scale(
              scale: scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(icon, size: widget.size, color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// AnimatedCheck — checkmark that draws itself with animation
// ─────────────────────────────────────────────────────────

class AnimatedCheck extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedCheck({
    super.key,
    this.size = 18,
    this.color = const Color(0xFF4CAF50),
  });

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _CheckPainter(
            progress: _controller.value,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Offset(size.width * 0.22, size.height * 0.52);
    final p2 = Offset(size.width * 0.42, size.height * 0.72);
    final p3 = Offset(size.width * 0.78, size.height * 0.32);

    final path = Path();
    if (progress <= 0.5) {
      final t = progress * 2; // 0..1 for first segment
      final cur = Offset.lerp(p1, p2, t)!;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(cur.dx, cur.dy);
    } else {
      final t = (progress - 0.5) * 2;
      final cur = Offset.lerp(p2, p3, t)!;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(cur.dx, cur.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────
// ConfettiBurst — overlays particle explosion
// Call .play() on the controller to trigger
// ─────────────────────────────────────────────────────────

class ConfettiController extends ChangeNotifier {
  void play() => notifyListeners();
}

class ConfettiBurst extends StatefulWidget {
  final ConfettiController controller;
  final int particleCount;
  final Duration duration;
  final List<Color> colors;

  const ConfettiBurst({
    super.key,
    required this.controller,
    this.particleCount = 40,
    this.duration = const Duration(milliseconds: 1800),
    this.colors = const [
      Color(0xFF6C5CE7),
      Color(0xFFFFD700),
      Color(0xFFFF6B35),
      Color(0xFF4CAF50),
      Color(0xFF00B8D4),
      Color(0xFFFF6B6B),
    ],
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_Particle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    widget.controller.addListener(_onPlay);
  }

  void _onPlay() {
    _spawnParticles();
    _controller.forward(from: 0);
  }

  void _spawnParticles() {
    _particles = List.generate(widget.particleCount, (i) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 200 + _random.nextDouble() * 300;
      return _Particle(
        startX: 0,
        startY: 0,
        velocityX: math.cos(angle) * speed,
        velocityY: math.sin(angle) * speed - 200,
        color: widget.colors[_random.nextInt(widget.colors.length)],
        size: 6 + _random.nextDouble() * 6,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
      );
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlay);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          if (_controller.value == 0 && _particles.isEmpty) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;

  _Particle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35;

    for (final p in particles) {
      final t = progress;
      final dx = p.velocityX * t;
      final dy = p.velocityY * t + (500 * t * t); // gravity
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      final paint = Paint()..color = p.color.withOpacity(opacity);
      final rot = p.rotation + p.rotationSpeed * t;

      canvas.save();
      canvas.translate(cx + dx, cy + dy);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          Radius.circular(p.size * 0.15),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────
// PulseGlow — gentle breathing scale animation for hero items
// ─────────────────────────────────────────────────────────

class PulseGlow extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseGlow({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.minScale = 1.0,
    this.maxScale = 1.04,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: widget.minScale, end: widget.maxScale)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
