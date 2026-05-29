import 'dart:async';
import 'package:flutter/material.dart';

class BookOpenAnimation {
  static Future<void> open({
    required BuildContext context,
    required String? coverImageUrl,
  }) async {
    final completer = Completer<void>();
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SimpleBookTransition(
        coverImageUrl: coverImageUrl,
        onDone: () {
          entry.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    overlay.insert(entry);
    return completer.future;
  }
}

class _SimpleBookTransition extends StatefulWidget {
  final String? coverImageUrl;
  final VoidCallback onDone;
  const _SimpleBookTransition({required this.coverImageUrl, required this.onDone});

  @override
  State<_SimpleBookTransition> createState() => _SimpleBookTransitionState();
}

class _SimpleBookTransitionState extends State<_SimpleBookTransition> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _coverFadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // Cover scales up and fades out, white takes over
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)));
    _coverFadeAnim = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 0.9, curve: Curves.easeOut)));

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Material(
        color: Colors.black.withOpacity(0.9 * (1 - _fadeAnim.value)),
        child: Stack(alignment: Alignment.center, children: [
          // Book cover zooms up and fades
          Opacity(
            opacity: _coverFadeAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                width: 180, height: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.coverImageUrl != null && widget.coverImageUrl!.startsWith('http')
                      ? Image.network(widget.coverImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
                      : _fallback(),
                ),
              ),
            ),
          ),
          // White fade in
          Container(color: Colors.white.withOpacity(_fadeAnim.value)),
        ]),
      ),
    );
  }

  Widget _fallback() => Container(color: const Color(0xFF2D1B4E), child: const Center(child: Icon(Icons.menu_book_rounded, size: 44, color: Colors.white30)));
}
