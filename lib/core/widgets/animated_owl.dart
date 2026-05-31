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

                // ── Animated eyes ─────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EyeOverlayPainter(
                      blinkProgress: _blinkAnimation.value,
                      eyeOffsetX: _eyeXAnimation.value,
                      eyeOffsetY: _eyeYAnimation.value,
                    ),
                  ),
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
// Covers the static PNG eyes with the face color, then draws
// animated pupils that follow a slow gaze pattern + blink.
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

    // Eye socket centers (matches the owl.png eye positions)
    final leftEyeCenter = Offset(w * 0.345, h * 0.365);
    final rightEyeCenter = Offset(w * 0.655, h * 0.365);
    final eyeRadius = w * 0.095;
    final pupilR = w * 0.050;

    // 1. Cover original PNG eyes with face color
    final facePaint = Paint()..color = const Color(0xFFD4A574);
    canvas.drawCircle(leftEyeCenter, eyeRadius, facePaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius, facePaint);

    // 2. Draw eye whites
    final whitePaint = Paint()..color = const Color(0xFFFFFDF5);
    canvas.drawCircle(leftEyeCenter, eyeRadius * 0.92, whitePaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius * 0.92, whitePaint);

    // 3. Draw moving pupils (clamped within eye bounds)
    final blink = blinkProgress.clamp(0.05, 1.0);
    final maxOffset = eyeRadius * 0.35;
    final clampedX = eyeOffsetX.clamp(-maxOffset, maxOffset);
    final clampedY = eyeOffsetY.clamp(-maxOffset, maxOffset);

    final leftPupil = Offset(leftEyeCenter.dx + clampedX, leftEyeCenter.dy + clampedY);
    final rightPupil = Offset(rightEyeCenter.dx + clampedX, rightEyeCenter.dy + clampedY);

    final pupilPaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawCircle(leftPupil, pupilR * blink, pupilPaint);
    canvas.drawCircle(rightPupil, pupilR * blink, pupilPaint);

    // 4. Shine highlights
    if (blinkProgress > 0.3) {
      final shinePaint = Paint()..color = Colors.white.withOpacity(0.9);
      canvas.drawCircle(
        Offset(leftPupil.dx - pupilR * 0.3, leftPupil.dy - pupilR * 0.3),
        pupilR * 0.3,
        shinePaint,
      );
      canvas.drawCircle(
        Offset(rightPupil.dx - pupilR * 0.3, rightPupil.dy - pupilR * 0.3),
        pupilR * 0.3,
        shinePaint,
      );
    }

    // 5. Eyelids (blink animation)
    if (blinkProgress < 0.90) {
      final lidProgress = 1.0 - blinkProgress;
      final lidPaint = Paint()..color = const Color(0xFFD4A574);

      for (final center in [leftEyeCenter, rightEyeCenter]) {
        // Top eyelid comes down
        final lidRect = Rect.fromLTWH(
          center.dx - eyeRadius,
          center.dy - eyeRadius,
          eyeRadius * 2,
          eyeRadius * 2 * lidProgress,
        );
        canvas.drawArc(lidRect, 0, 3.14159, true, lidPaint);
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
