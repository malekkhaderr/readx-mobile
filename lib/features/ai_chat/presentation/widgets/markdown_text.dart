import 'package:flutter/material.dart';
import 'chat_theme.dart';

class MarkdownText extends StatelessWidget {
  final String text;
  final bool isError;

  const MarkdownText({super.key, required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final textColor = isError ? ChatColors.error : ChatColors.textPrimary;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14.5,
          height: 1.55,
          color: textColor,
        ),
        children: _parse(text, textColor),
      ),
    );
  }

  List<InlineSpan> _parse(String input, Color baseColor) {
    final spans = <InlineSpan>[];
    final lines = input.split('\n');

    for (int i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));

      final line = lines[i];

      if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: line.substring(4),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: ChatColors.accentLight,
          ),
        ));
        continue;
      }
      if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: line.substring(3),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: ChatColors.accentLight,
          ),
        ));
        continue;
      }

      String processedLine = line;
      if (line.startsWith('- ') || line.startsWith('* ')) {
        processedLine = '  • ${line.substring(2)}';
      }

      spans.addAll(_parseInline(processedLine, baseColor));
    }

    return spans;
  }

  List<InlineSpan> _parseInline(String text, Color baseColor) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ChatColors.accentLight,
          ),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: baseColor.withOpacity(0.85),
          ),
        ));
      } else if (match.group(3) != null) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ChatColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: ChatColors.accent.withOpacity(0.2), width: 0.5),
            ),
            child: Text(
              match.group(3)!,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: ChatColors.accentLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }
}
