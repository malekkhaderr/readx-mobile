import 'package:flutter/material.dart';
import 'chat_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});
  @override State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scales;
  late final List<Animation<double>> _opacities;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 700)));
    _scales = _controllers.map((c) => TweenSequence<double>([TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50), TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50)]).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    _opacities = _controllers.map((c) => TweenSequence<double>([TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 50), TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 50)]).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < 3; i++) { Future.delayed(Duration(milliseconds: i * 200), () { if (mounted) _controllers[i].repeat(); }); }
  }

  @override void dispose() { for (final c in _controllers) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [ChatColors.accent.withOpacity(isDark ? 0.15 : 0.1), ChatColors.glowPurple.withOpacity(isDark ? 0.1 : 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(11), border: Border.all(color: ChatColors.accent.withOpacity(0.2), width: 0.8)),
          child: Padding(padding: const EdgeInsets.all(5), child: Image.asset('assets/images/owl.png', fit: BoxFit.contain)),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(color: ChatColors.owlBubble(context), borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(20)), border: Border.all(color: ChatColors.owlBubbleBorder(context), width: 0.8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.05), blurRadius: 8, offset: const Offset(0, 3))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Thinking', style: TextStyle(fontSize: 12, color: ChatColors.textMuted(context), fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
            const SizedBox(width: 10),
            ...List.generate(3, (i) => AnimatedBuilder(animation: _controllers[i], builder: (_, child) => Opacity(opacity: _opacities[i].value, child: Transform.scale(scale: _scales[i].value, child: child)), child: Container(width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 2.5), decoration: BoxDecoration(color: ChatColors.accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: ChatColors.accent.withOpacity(0.5), blurRadius: 5)])))),
          ]),
        ),
      ]),
    );
  }
}
