import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

enum OwlMood {
  waving,
  happy,
  sad,
  celebrating,
  reading,
  sleeping,
}

class ExpressiveOwl extends StatefulWidget {
  final OwlMood mood;
  final double size;
  final bool showBubble;
  final String? bubbleText;

  const ExpressiveOwl({
    super.key,
    this.mood = OwlMood.happy,
    this.size = 80,
    this.showBubble = true,
    this.bubbleText,
  });

  factory ExpressiveOwl.fromUserState({
    required int streakDays,
    required int minutesReadToday,
    required int dailyGoal,
    DateTime? lastReadDate,
    double size = 80,
  }) {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 23 || hour < 5) {
      return ExpressiveOwl(mood: OwlMood.sleeping, size: size, bubbleText: 'Sweet dreams, dear reader. Tomorrow awaits.');
    }
    if (lastReadDate != null && now.difference(lastReadDate).inHours > 24) {
      return ExpressiveOwl(mood: OwlMood.sad, size: size, bubbleText: 'Your bookshelf misses you. Come back and turn a page.');
    }
    if (minutesReadToday >= dailyGoal && dailyGoal > 0) {
      return ExpressiveOwl(mood: OwlMood.celebrating, size: size, bubbleText: "You did it! Today's goal is complete. Proud of you.");
    }
    if (streakDays >= 3) {
      return ExpressiveOwl(mood: OwlMood.happy, size: size, bubbleText: "$streakDays days strong. You're building something beautiful.");
    }
    if (minutesReadToday > 0) {
      return ExpressiveOwl(mood: OwlMood.reading, size: size, bubbleText: 'Almost there — ${dailyGoal - minutesReadToday} more minutes to shine.');
    }
    return ExpressiveOwl(mood: OwlMood.waving, size: size, bubbleText: _greeting());
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Rise and shine, reader. A new chapter awaits.';
    if (hour < 17) return 'Perfect time to get lost in a story.';
    return 'Wind down with a good book tonight.';
  }

  @override
  State<ExpressiveOwl> createState() => _ExpressiveOwlState();
}

class _ExpressiveOwlState extends State<ExpressiveOwl> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late AnimationController _shakeController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _particleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();

    if (widget.mood == OwlMood.celebrating || widget.mood == OwlMood.waving) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ExpressiveOwl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      if (widget.mood == OwlMood.celebrating || widget.mood == OwlMood.waving) {
        _shakeController.repeat(reverse: true);
      } else {
        _shakeController.stop();
        _shakeController.reset();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    _shakeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size + 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speech bubble with typing animation feel
          if (widget.showBubble && widget.bubbleText != null)
            _AnimatedBubble(text: widget.bubbleText!, mood: widget.mood, glowController: _glowController),
          const SizedBox(height: 10),
          // Owl with all effects
          SizedBox(
            width: widget.size + 40,
            height: widget.size + 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Particle effects
                if (widget.mood == OwlMood.celebrating)
                  ..._buildCelebrationParticles(),
                // Mood ring / aura
                _buildAura(),
                // The owl
                AnimatedBuilder(
                  animation: Listenable.merge([_bounceController, _shakeController]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: _getOffset(),
                      child: Transform.rotate(
                        angle: _getRotation(),
                        child: Transform.scale(
                          scale: _getScale(),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Image.asset(_owlAsset(), width: widget.size, height: widget.size, fit: BoxFit.contain),
                ),
                // Mood emojis floating around
                ..._buildFloatingEmojis(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAura() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = _glowController.value;
        return Container(
          width: widget.size * 0.85 + (glow * 8),
          height: widget.size * 0.85 + (glow * 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _moodColor().withOpacity(0.15 + glow * 0.1),
                _moodColor().withOpacity(0.05),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _moodColor().withOpacity(0.15 + glow * 0.1),
                blurRadius: 20 + glow * 10,
                spreadRadius: glow * 4,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCelebrationParticles() {
    return List.generate(8, (i) {
      final angle = (i / 8) * pi * 2;
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, _) {
          final t = (_particleController.value + i / 8) % 1.0;
          final radius = 30 + t * 20;
          final opacity = (1 - t).clamp(0.0, 1.0);
          return Positioned(
            left: (widget.size + 40) / 2 + cos(angle + t * pi * 2) * radius - 4,
            top: (widget.size + 20) / 2 + sin(angle + t * pi * 2) * radius - 4,
            child: Opacity(
              opacity: opacity * 0.8,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: [AppColors.gold, AppColors.primary, AppColors.successGreen, AppColors.warningOrange][i % 4],
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: [AppColors.gold, AppColors.primary, AppColors.successGreen, AppColors.warningOrange][i % 4].withOpacity(0.5), blurRadius: 4)],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  List<Widget> _buildFloatingEmojis() {
    if (widget.mood == OwlMood.sleeping) {
      return [
        _FloatingEmoji(emoji: '💤', controller: _bounceController, offsetX: 25, offsetY: -15, size: 14),
        _FloatingEmoji(emoji: '💤', controller: _bounceController, offsetX: 30, offsetY: -25, size: 10, delay: 0.3),
      ];
    }
    if (widget.mood == OwlMood.sad) {
      return [
        _FloatingEmoji(emoji: '💧', controller: _bounceController, offsetX: -15, offsetY: -10, size: 12),
      ];
    }
    if (widget.mood == OwlMood.celebrating) {
      return [
        _FloatingEmoji(emoji: '⭐', controller: _particleController, offsetX: -25, offsetY: -20, size: 14),
        _FloatingEmoji(emoji: '🎉', controller: _particleController, offsetX: 28, offsetY: -18, size: 12, delay: 0.5),
      ];
    }
    if (widget.mood == OwlMood.reading) {
      return [];
    }
    if (widget.mood == OwlMood.happy) {
      return [
        _FloatingEmoji(emoji: '✨', controller: _bounceController, offsetX: 22, offsetY: -18, size: 12),
      ];
    }
    return [];
  }

  Offset _getOffset() {
    final v = _bounceController.value;
    final s = _shakeController.value;
    switch (widget.mood) {
      case OwlMood.waving:
        return Offset(sin(s * pi * 2) * 4, -v * 6);
      case OwlMood.happy:
        return Offset(0, -v * 7);
      case OwlMood.sad:
        return Offset(0, v * 3);
      case OwlMood.celebrating:
        return Offset(sin(s * pi * 2) * 5, -v * 10);
      case OwlMood.reading:
        return Offset(0, -v * 3);
      case OwlMood.sleeping:
        return Offset(sin(v * pi) * 2, 0);
    }
  }

  double _getRotation() {
    final v = _bounceController.value;
    final s = _shakeController.value;
    switch (widget.mood) {
      case OwlMood.waving:
        return sin(s * pi * 2) * 0.12;
      case OwlMood.celebrating:
        return sin(s * pi * 3) * 0.15;
      case OwlMood.sleeping:
        return sin(v * pi) * 0.04;
      case OwlMood.sad:
        return -0.05;
      default:
        return 0;
    }
  }

  double _getScale() {
    final v = _bounceController.value;
    switch (widget.mood) {
      case OwlMood.celebrating:
        // 888px source has more internal whitespace — scale up to match 500px owls
        return 1.25 + v * 0.1;
      case OwlMood.waving:
        // Same 888px source (owl_happy.png)
        return 1.25 + v * 0.04;
      case OwlMood.happy:
        return 1.0 + v * 0.05;
      case OwlMood.sad:
        return 0.92 + v * 0.03;
      default:
        return 1.0;
    }
  }

  String _owlAsset() {
    switch (widget.mood) {
      case OwlMood.waving:
        return 'assets/images/owl_happy.png';
      case OwlMood.happy:
        return 'assets/images/owl.png';
      case OwlMood.celebrating:
        return 'assets/images/owl_celebrating.png';
      case OwlMood.sad:
        return 'assets/images/owl_sad.png';
      case OwlMood.reading:
        return 'assets/images/owl_reading.png';
      case OwlMood.sleeping:
        return 'assets/images/owl_sleeping.png';
    }
  }

  Color _moodColor() {
    switch (widget.mood) {
      case OwlMood.happy:
      case OwlMood.waving:
        return AppColors.primary;
      case OwlMood.celebrating:
        return AppColors.gold;
      case OwlMood.sad:
        return AppColors.warningOrange;
      case OwlMood.reading:
        return AppColors.successGreen;
      case OwlMood.sleeping:
        return AppColors.textLight;
    }
  }
}

// ── Floating Emoji ──────────────────────────────────────────────
class _FloatingEmoji extends StatelessWidget {
  final String emoji;
  final AnimationController controller;
  final double offsetX, offsetY, size, delay;

  const _FloatingEmoji({
    required this.emoji,
    required this.controller,
    required this.offsetX,
    required this.offsetY,
    required this.size,
    this.delay = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value + delay) % 1.0;
        return Positioned(
          left: (80 + 40) / 2 + offsetX,
          top: (80 + 20) / 2 + offsetY + sin(t * pi * 2) * 5,
          child: Opacity(
            opacity: (0.6 + sin(t * pi * 2) * 0.4).clamp(0.3, 1.0),
            child: Transform.scale(
              scale: 0.8 + sin(t * pi * 2) * 0.2,
              child: Text(emoji, style: TextStyle(fontSize: size)),
            ),
          ),
        );
      },
    );
  }
}

// ── Animated Speech Bubble ──────────────────────────────────────
class _AnimatedBubble extends StatelessWidget {
  final String text;
  final OwlMood mood;
  final AnimationController glowController;

  const _AnimatedBubble({required this.text, required this.mood, required this.glowController});

  Color _borderColor() {
    switch (mood) {
      case OwlMood.celebrating:
        return AppColors.gold;
      case OwlMood.sad:
        return AppColors.warningOrange;
      case OwlMood.reading:
        return AppColors.successGreen;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowController,
      builder: (context, child) {
        final glow = glowController.value;
        return Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor().withOpacity(0.3 + glow * 0.2), width: 1.2),
            boxShadow: [
              BoxShadow(color: _borderColor().withOpacity(0.08 + glow * 0.06), blurRadius: 12 + glow * 6, spreadRadius: glow * 2),
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.4)),
        );
      },
    );
  }

  String _moodEmoji() {
    return '';
  }
}
