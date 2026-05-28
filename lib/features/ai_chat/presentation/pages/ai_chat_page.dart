import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/ai_chat_remote_datasource.dart';
import '../widgets/chat_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/suggestion_chips.dart';
import '../widgets/particles_background.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isSending = false;
  late final AiChatRemoteDataSource _dataSource;

  late final AnimationController _welcomeController;
  late final Animation<double> _owlDropAnimation;
  late final Animation<double> _owlScaleAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<double> _subtitleFadeAnimation;
  late final Animation<double> _chipsFadeAnimation;

  int? _typingMessageIndex;
  String _typingDisplayText = '';
  Timer? _typewriterTimer;

  late final AnimationController _sendButtonController;
  late final Animation<double> _sendButtonScale;

  static const _storageKey = 'owl_chat_history';

  @override
  void initState() {
    super.initState();
    _dataSource = AiChatRemoteDataSource(dioClient: sl());

    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _owlDropAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _welcomeController, curve: const Interval(0.0, 0.4, curve: Curves.bounceOut)),
    );
    _owlScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: const Interval(0.0, 0.35, curve: Curves.elasticOut)),
    );
    _titleFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _welcomeController, curve: const Interval(0.3, 0.55, curve: Curves.easeOut)),
    );
    _subtitleFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _welcomeController, curve: const Interval(0.45, 0.7, curve: Curves.easeOut)),
    );
    _chipsFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _welcomeController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    _sendButtonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _sendButtonScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );

    _loadHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _welcomeController.dispose();
    _sendButtonController.dispose();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = sl<SharedPreferences>();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final List<dynamic> decoded = json.decode(raw);
      setState(() {
        _messages.addAll(decoded.map((e) => ChatMessage(
              role: e['role'], content: e['content'],
              timestamp: DateTime.parse(e['timestamp']),
            )));
      });
      _scrollToBottom();
    } else {
      _welcomeController.forward();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = sl<SharedPreferences>();
    final payload = _messages.where((m) => !m.isError).map((m) => {
      'role': m.role, 'content': m.content, 'timestamp': m.timestamp.toIso8601String(),
    }).toList();
    await prefs.setString(_storageKey, json.encode(payload));
  }

  Future<void> _clearHistory() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? ChatColors.surfaceDark : ChatColors.surfaceLight,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: ChatColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_sweep_rounded, color: ChatColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Clear Conversation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? ChatColors.textPrimaryDark : ChatColors.textPrimaryLight)),
        ]),
        content: Text('Erase your entire conversation with Owl?\nThis action cannot be undone.',
          style: TextStyle(color: isDark ? ChatColors.textSecondaryDark : ChatColors.textSecondaryLight, fontSize: 14, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: isDark ? ChatColors.textSecondaryDark : ChatColors.textSecondaryLight))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ChatColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('Clear All')),
        ],
      ),
    );
    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      setState(() => _messages.clear());
      final prefs = sl<SharedPreferences>();
      await prefs.remove(_storageKey);
      _welcomeController.reset();
      _welcomeController.forward();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      }
    });
  }

  void _startTypewriter(String fullText, int messageIndex) {
    _typingMessageIndex = messageIndex;
    _typingDisplayText = '';
    int charIndex = 0;
    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (charIndex >= fullText.length) { timer.cancel(); setState(() { _typingMessageIndex = null; }); return; }
      final charsToAdd = min(2, fullText.length - charIndex);
      charIndex += charsToAdd;
      setState(() { _typingDisplayText = fullText.substring(0, charIndex); });
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;
    HapticFeedback.lightImpact();
    _sendButtonController.forward().then((_) => _sendButtonController.reverse());
    _textController.clear();
    final userMsg = ChatMessage(role: 'user', content: trimmed, timestamp: DateTime.now());
    setState(() { _messages.add(userMsg); _isTyping = true; _isSending = true; });
    _scrollToBottom();
    try {
      final history = _messages.where((m) => !m.isError && m != userMsg).toList();
      final reply = await _dataSource.sendMessage(trimmed, history);
      final assistantMsg = ChatMessage(role: 'assistant', content: reply, timestamp: DateTime.now());
      setState(() { _messages.add(assistantMsg); _isTyping = false; _isSending = false; });
      HapticFeedback.selectionClick();
      _startTypewriter(reply, _messages.length - 1);
    } catch (e) {
      setState(() { _messages.add(ChatMessage(role: 'assistant', content: "Connection lost. Please try again.", timestamp: DateTime.now(), isError: true)); _isTyping = false; _isSending = false; });
      HapticFeedback.heavyImpact();
    }
    _saveHistory();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = ChatColors.background(context);
    final sf = ChatColors.surface(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context, isDark, sf),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(colors: [ChatColors.backgroundDark, Color(0xFF12121F)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              : const LinearGradient(colors: [ChatColors.backgroundLight, Color(0xFFEEECF8)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Stack(
          children: [
            const ParticlesBackground(),
            Column(children: [
              Expanded(child: _messages.isEmpty ? _buildWelcome(context, isDark) : _buildMessageList()),
              _buildInputBar(context, isDark),
            ]),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark, Color sf) {
    return AppBar(
      backgroundColor: sf.withOpacity(isDark ? 0.85 : 0.95),
      elevation: 0,
      leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: ChatColors.textPrimary(context), size: 20), onPressed: () => Navigator.of(context).pop()),
      title: Row(children: [
        Hero(
          tag: 'owl_chat_avatar',
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [ChatColors.accent.withOpacity(isDark ? 0.2 : 0.12), ChatColors.glowPurple.withOpacity(isDark ? 0.15 : 0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ChatColors.accent.withOpacity(0.25), width: 1),
            ),
            child: Padding(padding: const EdgeInsets.all(5), child: Image.asset('assets/images/owl.png', fit: BoxFit.contain)),
          ),
        ),
        const SizedBox(width: 11),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Owl', style: TextStyle(color: ChatColors.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          const SizedBox(height: 1),
          Row(children: [
            _OnlineDot(),
            const SizedBox(width: 5),
            Text('AI Reading Assistant', style: TextStyle(color: ChatColors.textMuted(context), fontSize: 11, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ]),
      actions: [
        if (_messages.isNotEmpty) IconButton(icon: Icon(Icons.delete_outline_rounded, color: ChatColors.textMuted(context), size: 21), onPressed: _clearHistory),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildWelcome(BuildContext context, bool isDark) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return AnimatedBuilder(
      animation: _welcomeController,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(children: [
          const SizedBox(height: 24),
          Transform.translate(offset: Offset(0, _owlDropAnimation.value), child: Transform.scale(scale: _owlScaleAnimation.value, child: Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [ChatColors.accent.withOpacity(isDark ? 0.15 : 0.1), ChatColors.glowPurple.withOpacity(0.08), Colors.transparent], radius: 0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: ChatColors.accent.withOpacity(0.2), width: 1.5),
              boxShadow: [BoxShadow(color: ChatColors.accent.withOpacity(isDark ? 0.15 : 0.08), blurRadius: 30, spreadRadius: 2)],
            ),
            child: Padding(padding: const EdgeInsets.all(20), child: Image.asset('assets/images/owl.png', fit: BoxFit.contain)),
          ))),
          const SizedBox(height: 28),
          Opacity(opacity: _titleFadeAnimation.value, child: Transform.translate(offset: Offset(0, 20 * (1 - _titleFadeAnimation.value)), child: Column(children: [
            Text(greeting, style: TextStyle(fontSize: 13, color: ChatColors.accentColor(context), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text('Chat with Owl', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ChatColors.textPrimary(context), letterSpacing: -0.5)),
          ]))),
          const SizedBox(height: 12),
          Opacity(opacity: _subtitleFadeAnimation.value, child: Transform.translate(offset: Offset(0, 12 * (1 - _subtitleFadeAnimation.value)), child: Text(
            'Your intelligent reading companion.\nAsk about books, get curated recommendations,\nor explore literary topics.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: ChatColors.textSecondary(context), height: 1.6),
          ))),
          const SizedBox(height: 36),
          Opacity(opacity: _chipsFadeAnimation.value, child: Transform.translate(offset: Offset(0, 16 * (1 - _chipsFadeAnimation.value)), child: SuggestionChips(onTap: _sendMessage))),
        ]),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) return const TypingIndicator();
        final msg = _messages[index];
        final displayText = (_typingMessageIndex == index) ? _typingDisplayText : msg.content;
        return _AnimatedMessageEntry(child: ChatBubble(message: msg, displayText: displayText, isTypewriting: _typingMessageIndex == index, onRetry: msg.isError ? () => _retryLast() : null, onCopy: msg.isAssistant && _typingMessageIndex != index ? () => _copyText(msg.content) : null));
      },
    );
  }

  void _retryLast() {
    setState(() { _messages.removeWhere((m) => m.isError); });
    ChatMessage? lastUser;
    for (int i = _messages.length - 1; i >= 0; i--) { if (_messages[i].isUser) { lastUser = _messages[i]; break; } }
    if (lastUser != null && lastUser.content.isNotEmpty) { final content = lastUser.content; setState(() => _messages.remove(lastUser)); _sendMessage(content); }
  }

  void _copyText(String text) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [Icon(Icons.check_circle_rounded, color: ChatColors.accentColor(context), size: 18), const SizedBox(width: 8), const Text('Copied to clipboard')]),
      duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: ChatColors.surface(context), margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ));
  }

  Widget _buildInputBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 14, 10, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(color: ChatColors.inputBg(context).withOpacity(0.95), border: Border(top: BorderSide(color: ChatColors.cardBorder(context).withOpacity(0.5)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Container(
          decoration: BoxDecoration(color: ChatColors.inputSurface(context), borderRadius: BorderRadius.circular(22), border: Border.all(color: ChatColors.inputBorder(context))),
          child: TextField(
            controller: _textController, focusNode: _focusNode, maxLines: 5, minLines: 1,
            textInputAction: TextInputAction.send, onSubmitted: (text) => _sendMessage(text),
            style: TextStyle(fontSize: 14.5, color: ChatColors.textPrimary(context)), cursorColor: ChatColors.accent,
            decoration: InputDecoration(hintText: 'Ask Owl anything...', hintStyle: TextStyle(color: ChatColors.textMuted(context), fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
          ),
        )),
        const SizedBox(width: 10),
        ScaleTransition(scale: _sendButtonScale, child: _SendButton(isSending: _isSending, onTap: () => _sendMessage(_textController.text))),
      ]),
    );
  }
}

class _AnimatedMessageEntry extends StatefulWidget {
  final Widget child;
  const _AnimatedMessageEntry({required this.child});
  @override
  State<_AnimatedMessageEntry> createState() => _AnimatedMessageEntryState();
}

class _AnimatedMessageEntryState extends State<_AnimatedMessageEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400)); _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)); _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)); _controller.forward(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child));
}

class _OnlineDot extends StatefulWidget { @override State<_OnlineDot> createState() => _OnlineDotState(); }
class _OnlineDotState extends State<_OnlineDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, __) => Container(width: 7, height: 7, decoration: BoxDecoration(color: ChatColors.online, shape: BoxShape.circle, boxShadow: [BoxShadow(color: ChatColors.online.withOpacity(0.5 * _c.value), blurRadius: 4 + (4 * _c.value))])));
}

class _SendButton extends StatefulWidget {
  final bool isSending; final VoidCallback onTap;
  const _SendButton({required this.isSending, required this.onTap});
  @override State<_SendButton> createState() => _SendButtonState();
}
class _SendButtonState extends State<_SendButton> with SingleTickerProviderStateMixin {
  late final AnimationController _r;
  @override void initState() { super.initState(); _r = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000)); }
  @override void didUpdateWidget(covariant _SendButton old) { super.didUpdateWidget(old); if (widget.isSending && !old.isSending) _r.repeat(); else if (!widget.isSending && old.isSending) { _r.stop(); _r.reset(); } }
  @override void dispose() { _r.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return GestureDetector(onTap: widget.isSending ? null : widget.onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 250), width: 46, height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: widget.isSending ? [ChatColors.accent.withOpacity(0.3), ChatColors.accentDim.withOpacity(0.3)] : [ChatColors.userGradientStart, ChatColors.userGradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: widget.isSending ? [] : [BoxShadow(color: ChatColors.glowPurple.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Center(child: widget.isSending ? RotationTransition(turns: _r, child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20)) : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 21)),
    ));
  }
}
