import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat_theme.dart';

class SuggestionChips extends StatelessWidget {
  final void Function(String text) onTap;
  const SuggestionChips({super.key, required this.onTap});

  static const _suggestions = [
    _Suggestion(icon: Icons.auto_awesome_rounded, text: 'Recommend a science fiction book', subtitle: 'Personalized picks', color: Color(0xFFB8A9FF)),
    _Suggestion(icon: Icons.menu_book_rounded, text: 'How can I read more consistently?', subtitle: 'Build better habits', color: Color(0xFF50E3A0)),
    _Suggestion(icon: Icons.lightbulb_outline_rounded, text: 'Explain the difference between plot and theme', subtitle: 'Literary concepts', color: Color(0xFF8CB4FF)),
    _Suggestion(icon: Icons.map_rounded, text: 'Give me a reading path for fantasy', subtitle: 'Curated journey', color: Color(0xFFA78BFA)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 14), child: Row(children: [
        Icon(Icons.tips_and_updates_rounded, size: 15, color: ChatColors.accentColor(context).withOpacity(0.8)),
        const SizedBox(width: 7),
        Text('Try asking...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ChatColors.textSecondary(context), letterSpacing: 0.5)),
      ])),
      ...List.generate(_suggestions.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _SuggestionCard(suggestion: _suggestions[i], onTap: () => onTap(_suggestions[i].text)))),
    ]);
  }
}

class _SuggestionCard extends StatefulWidget {
  final _Suggestion suggestion; final VoidCallback onTap;
  const _SuggestionCard({required this.suggestion, required this.onTap});
  @override State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) { setState(() => _p = false); HapticFeedback.lightImpact(); widget.onTap(); },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(scale: _p ? 0.97 : 1.0, duration: const Duration(milliseconds: 100), child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _p ? s.color.withOpacity(isDark ? 0.08 : 0.06) : ChatColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _p ? s.color.withOpacity(0.35) : ChatColors.cardBorder(context), width: 0.8),
          boxShadow: [BoxShadow(color: _p ? s.color.withOpacity(0.08) : Colors.black.withOpacity(isDark ? 0.12 : 0.04), blurRadius: _p ? 12 : 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: s.color.withOpacity(isDark ? 0.12 : 0.08), borderRadius: BorderRadius.circular(11), border: Border.all(color: s.color.withOpacity(0.15), width: 0.5)), child: Icon(s.icon, size: 18, color: s.color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.text, style: TextStyle(fontSize: 13, color: ChatColors.textPrimary(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(s.subtitle, style: TextStyle(fontSize: 11, color: s.color.withOpacity(0.7), fontWeight: FontWeight.w500)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _p ? s.color : ChatColors.textMuted(context)),
        ]),
      )),
    );
  }
}

class _Suggestion {
  final IconData icon; final String text; final String subtitle; final Color color;
  const _Suggestion({required this.icon, required this.text, required this.subtitle, required this.color});
}
