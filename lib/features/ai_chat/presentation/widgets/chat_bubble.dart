import 'package:flutter/material.dart';
import '../../data/datasources/ai_chat_remote_datasource.dart';
import 'chat_theme.dart';
import 'markdown_text.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String displayText;
  final bool isTypewriting;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;

  const ChatBubble({
    super.key,
    required this.message,
    required this.displayText,
    this.isTypewriting = false,
    this.onRetry,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _owlAvatar(),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [
                              ChatColors.userGradientStart,
                              ChatColors.userGradientEnd
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser
                        ? null
                        : message.isError
                            ? ChatColors.errorBg
                            : ChatColors.owlBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: message.isError
                                ? ChatColors.error.withOpacity(0.2)
                                : ChatColors.owlBubbleBorder,
                            width: 0.8,
                          ),
                    boxShadow: [
                      if (isUser)
                        BoxShadow(
                          color: ChatColors.userGradientStart.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUser)
                        Text(
                          displayText,
                          style: const TextStyle(
                            color: ChatColors.textOnUser,
                            fontSize: 14.5,
                            height: 1.45,
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: MarkdownText(
                                text: displayText,
                                isError: message.isError,
                              ),
                            ),
                            if (isTypewriting) ...[
                              const SizedBox(width: 2),
                              _TypewriterCursor(),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: const TextStyle(
                          fontSize: 10,
                          color: ChatColors.textMuted,
                        ),
                      ),
                      if (onRetry != null) ...[
                        const SizedBox(width: 10),
                        _ActionChip(
                          icon: Icons.refresh_rounded,
                          label: 'Retry',
                          color: ChatColors.error,
                          onTap: onRetry!,
                        ),
                      ],
                      if (onCopy != null) ...[
                        const SizedBox(width: 10),
                        _ActionChip(
                          icon: Icons.copy_rounded,
                          label: 'Copy',
                          color: ChatColors.textSecondary,
                          onTap: onCopy!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _owlAvatar() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ChatColors.accent.withOpacity(0.15),
            ChatColors.glowPurple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(11),
        border:
            Border.all(color: ChatColors.accent.withOpacity(0.2), width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Image.asset('assets/images/owl.png', fit: BoxFit.contain),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Blinking cursor ───────────────────────────────────────────

class _TypewriterCursor extends StatefulWidget {
  @override
  State<_TypewriterCursor> createState() => _TypewriterCursorState();
}

class _TypewriterCursorState extends State<_TypewriterCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
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
      builder: (context, _) => Opacity(
        opacity: _controller.value,
        child: Container(
          width: 2,
          height: 16,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: ChatColors.accent,
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: ChatColors.accent.withOpacity(0.5),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action chip ───────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
