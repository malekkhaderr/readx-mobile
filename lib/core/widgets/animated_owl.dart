import 'package:flutter/material.dart';

class AnimatedOwl extends StatefulWidget {
  final double size;
  final bool isCoveringEyes;

  const AnimatedOwl({super.key, this.size = 140, this.isCoveringEyes = false});

  @override
  State<AnimatedOwl> createState() => _AnimatedOwlState();
}

class _AnimatedOwlState extends State<AnimatedOwl>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _blinkController;
  late AnimationController _wingController;
  late AnimationController _eyeXController;
  late AnimationController _eyeYController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _wingAnimation;
  late Animation<double> _eyeXAnimation;
  late Animation<double> _eyeYAnimation;

  @override
  void initState() {
    super.initState();

    // ── Bounce ────────────────────────────────────────
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // ── Blink ─────────────────────────────────────────
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.05).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // ── Eye X Movement ────────────────────────────────
    _eyeXController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _eyeXAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _eyeXController, curve: Curves.easeInOut),
    );

    // ── Eye Y Movement ────────────────────────────────
    _eyeYController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat(reverse: true);

    _eyeYAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _eyeYController, curve: Curves.easeInOut),
    );

    // ── Wing Cover ────────────────────────────────────
    _wingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _wingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wingController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBlinking();
    });
  }

  void _startBlinking() async {
    while (mounted) {
      await Future.delayed(
        Duration(
          milliseconds:
              2500 + (1500 * (DateTime.now().millisecond / 1000)).toInt(),
        ),
      );
      if (!mounted) break;
      await _blinkController.forward();
      await Future.delayed(const Duration(milliseconds: 70));
      if (!mounted) break;
      await _blinkController.reverse();

      // أحياناً بيبلنك مرتين
      if (DateTime.now().millisecond % 5 == 0) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) break;
        await _blinkController.forward();
        await Future.delayed(const Duration(milliseconds: 70));
        if (!mounted) break;
        await _blinkController.reverse();
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedOwl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCoveringEyes != oldWidget.isCoveringEyes) {
      if (widget.isCoveringEyes) {
        _wingController.forward();
      } else {
        _wingController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _blinkController.dispose();
    _wingController.dispose();
    _eyeXController.dispose();
    _eyeYController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _bounceAnimation,
        _blinkAnimation,
        _wingAnimation,
        _eyeXAnimation,
        _eyeYAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              children: [
                // ── Base PNG ───────────────────────────
                Image.asset(
                  'assets/images/owl.png',
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                ),

                // ── Wings cover eyes when password field focused ──
                if (_wingAnimation.value > 0)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WingCoverPainter(
                        progress: _wingAnimation.value.clamp(0.0, 1.0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Eye Overlay Painter ──────────────────────────────────
class _EyeOverlayPainter extends CustomPainter {
  final double blinkProgress;
  final double eyeOffsetX;
  final double eyeOffsetY;

  _EyeOverlayPainter({
    required this.blinkProgress,
    required this.eyeOffsetX,
    required this.eyeOffsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leftCenter = Offset(w * 0.345 + eyeOffsetX, h * 0.365 + eyeOffsetY);
    final rightCenter = Offset(w * 0.655 + eyeOffsetX, h * 0.365 + eyeOffsetY);
    final pupilR = w * 0.070;
    final blink = blinkProgress.clamp(0.05, 1.0);

    // ── Pupils ────────────────────────────────────────
    canvas.drawCircle(
      leftCenter,
      pupilR * blink,
      Paint()..color = const Color(0xFF0A0A0A),
    );
    canvas.drawCircle(
      rightCenter,
      pupilR * blink,
      Paint()..color = const Color(0xFF0A0A0A),
    );

    // ── Shine ─────────────────────────────────────────
    if (blinkProgress > 0.25) {
      final s = Paint()..color = Colors.white;

      canvas.drawCircle(
        Offset(leftCenter.dx - pupilR * 0.30, leftCenter.dy - pupilR * 0.30),
        pupilR * 0.28,
        s,
      );
      canvas.drawCircle(
        Offset(rightCenter.dx - pupilR * 0.30, rightCenter.dy - pupilR * 0.30),
        pupilR * 0.28,
        s,
      );
      canvas.drawCircle(
        Offset(leftCenter.dx + pupilR * 0.20, leftCenter.dy + pupilR * 0.18),
        pupilR * 0.12,
        s,
      );
      canvas.drawCircle(
        Offset(rightCenter.dx + pupilR * 0.20, rightCenter.dy + pupilR * 0.18),
        pupilR * 0.12,
        s,
      );
    }

    // ── Eyelid ────────────────────────────────────────
    if (blinkProgress < 0.90) {
      final lidH = (1.0 - blinkProgress) * pupilR * 2.6;

      for (final center in [leftCenter, rightCenter]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - pupilR + lidH / 2),
            width: pupilR * 2.8,
            height: lidH,
          ),
          Paint()..color = const Color(0xFF5B3A8A),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - pupilR + lidH * 0.85),
            width: pupilR * 2.8,
            height: pupilR * 0.2,
          ),
          Paint()..color = const Color(0xFF7B4DB0),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EyeOverlayPainter old) =>
      old.blinkProgress != blinkProgress ||
      old.eyeOffsetX != eyeOffsetX ||
      old.eyeOffsetY != eyeOffsetY;
}

// ── Wing Cover Painter ───────────────────────────────────
class _WingCoverPainter extends CustomPainter {
  final double progress;

  _WingCoverPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final lift = progress * h * 0.22;

    final darkWing = Paint()
      ..color = const Color(0xFF2D1550)
      ..style = PaintingStyle.fill;

    final detailWing = Paint()
      ..color = const Color(0xFF4A3080)
      ..style = PaintingStyle.fill;

    final featherStroke = Paint()
      ..color = const Color(0xFF1A0D38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.011
      ..strokeCap = StrokeCap.round;

    // ── Left wing ─────────────────────────────────────
    canvas.save();
    canvas.translate(0, -lift);

    final leftWing = Path()
      ..moveTo(cx - w * 0.16, h * 0.48)
      ..quadraticBezierTo(cx - w * 0.10, h * 0.44, cx - w * 0.08, h * 0.50)
      ..quadraticBezierTo(cx - w * 0.06, h * 0.56, cx - w * 0.16, h * 0.58)
      ..quadraticBezierTo(cx - w * 0.30, h * 0.62, cx - w * 0.46, h * 0.72)
      ..quadraticBezierTo(cx - w * 0.54, h * 0.76, cx - w * 0.50, h * 0.86)
      ..quadraticBezierTo(cx - w * 0.36, h * 0.92, cx - w * 0.22, h * 0.88)
      ..quadraticBezierTo(cx - w * 0.10, h * 0.82, cx - w * 0.10, h * 0.68)
      ..quadraticBezierTo(cx - w * 0.10, h * 0.58, cx - w * 0.16, h * 0.48)
      ..close();

    canvas.drawPath(leftWing, darkWing);

    final leftDetail = Path()
      ..moveTo(cx - w * 0.14, h * 0.52)
      ..quadraticBezierTo(cx - w * 0.28, h * 0.58, cx - w * 0.42, h * 0.70)
      ..quadraticBezierTo(cx - w * 0.48, h * 0.76, cx - w * 0.44, h * 0.84)
      ..quadraticBezierTo(cx - w * 0.32, h * 0.88, cx - w * 0.22, h * 0.84)
      ..quadraticBezierTo(cx - w * 0.12, h * 0.78, cx - w * 0.12, h * 0.64)
      ..close();

    canvas.drawPath(leftDetail, detailWing);

    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(cx - w * (0.14 + i * 0.06), h * (0.52 + i * 0.08)),
        Offset(cx - w * (0.22 + i * 0.08), h * (0.56 + i * 0.09)),
        featherStroke,
      );
    }

    canvas.restore();

    // ── Right wing ────────────────────────────────────
    canvas.save();
    canvas.translate(0, -lift);

    final rightWing = Path()
      ..moveTo(cx + w * 0.16, h * 0.48)
      ..quadraticBezierTo(cx + w * 0.10, h * 0.44, cx + w * 0.08, h * 0.50)
      ..quadraticBezierTo(cx + w * 0.06, h * 0.56, cx + w * 0.16, h * 0.58)
      ..quadraticBezierTo(cx + w * 0.30, h * 0.62, cx + w * 0.46, h * 0.72)
      ..quadraticBezierTo(cx + w * 0.54, h * 0.76, cx + w * 0.50, h * 0.86)
      ..quadraticBezierTo(cx + w * 0.36, h * 0.92, cx + w * 0.22, h * 0.88)
      ..quadraticBezierTo(cx + w * 0.10, h * 0.82, cx + w * 0.10, h * 0.68)
      ..quadraticBezierTo(cx + w * 0.10, h * 0.58, cx + w * 0.16, h * 0.48)
      ..close();

    canvas.drawPath(rightWing, darkWing);

    final rightDetail = Path()
      ..moveTo(cx + w * 0.14, h * 0.52)
      ..quadraticBezierTo(cx + w * 0.28, h * 0.58, cx + w * 0.42, h * 0.70)
      ..quadraticBezierTo(cx + w * 0.48, h * 0.76, cx + w * 0.44, h * 0.84)
      ..quadraticBezierTo(cx + w * 0.32, h * 0.88, cx + w * 0.22, h * 0.84)
      ..quadraticBezierTo(cx + w * 0.12, h * 0.78, cx + w * 0.12, h * 0.64)
      ..close();

    canvas.drawPath(rightDetail, detailWing);

    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(cx + w * (0.14 + i * 0.06), h * (0.52 + i * 0.08)),
        Offset(cx + w * (0.22 + i * 0.08), h * (0.56 + i * 0.09)),
        featherStroke,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WingCoverPainter old) => old.progress != progress;
}
