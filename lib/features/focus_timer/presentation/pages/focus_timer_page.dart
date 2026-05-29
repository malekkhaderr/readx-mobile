import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/focus_timer_service.dart';

final _focusTips = [
  'Turn off notifications. Your books deserve your full attention.',
  'Reading 20 minutes a day adds up to 30+ books a year.',
  'Deep reading rewires your brain for better focus.',
  'The best readers are the most patient ones.',
  'Every page you turn is a step toward wisdom.',
  'Let the world wait. This moment belongs to your book.',
  'Consistency beats intensity. Show up every day.',
  'Your future self will thank you for reading today.',
];

class FocusTimerPage extends StatefulWidget {
  const FocusTimerPage({super.key});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> with SingleTickerProviderStateMixin {
  final _timer = FocusTimerService();
  late AnimationController _pulseCtrl;
  late String _tip;

  @override
  void initState() {
    super.initState();
    _timer.addListener(_onTick);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _tip = _focusTips[Random().nextInt(_focusTips.length)];
  }

  @override
  void dispose() {
    _timer.removeListener(_onTick);
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onTick() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final isRunning = _timer.isRunning;
    final isFinished = !isRunning && _timer.lastSessionSeconds > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: AppColors.textDark)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const Spacer(flex: 1),
            if (!isFinished) _buildMain(isRunning),
            if (isFinished) _buildResults(),
            const Spacer(flex: 2),
            _buildButton(isRunning, isFinished),
            const SizedBox(height: 36),
          ]),
        ),
      ),
    );
  }

  Widget _buildMain(bool isRunning) {
    return Column(children: [
      // Owl — big, outside the circle
      Image.asset(
        isRunning ? 'assets/images/owl_reading.png' : 'assets/images/owl_sleeping.png',
        width: 120, height: 120, fit: BoxFit.contain,
      ),
      const SizedBox(height: 14),
      // Owl speech bubble
      Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text(
          isRunning ? _tip : 'Ready when you are. Tap start and lose yourself in a book.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, height: 1.4),
        ),
      ),
      const SizedBox(height: 28),
      // Timer — clean circle, just the time
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          final p = _pulseCtrl.value;
          return Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                color: isRunning ? AppColors.primary.withOpacity(0.35 + p * 0.15) : AppColors.divider,
                width: isRunning ? 4 : 1.5,
              ),
              boxShadow: isRunning ? [
                BoxShadow(color: AppColors.primary.withOpacity(0.08 + p * 0.06), blurRadius: 20 + p * 8, spreadRadius: p * 3),
              ] : null,
            ),
            child: Center(
              child: Text(
                _timer.formattedTime,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w200, color: AppColors.textDark, letterSpacing: 2, fontFamily: 'monospace'),
              ),
            ),
          );
        },
      ),
      if (isRunning) ...[
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.successGreen.withOpacity(0.4), blurRadius: 4)])),
          const SizedBox(width: 8),
          Text('Session active — timer runs in background', style: TextStyle(fontSize: 11, color: AppColors.successGreen, fontWeight: FontWeight.w600)),
        ]),
      ],
    ]);
  }

  Widget _buildResults() {
    final mins = _timer.lastSessionSeconds ~/ 60;
    final secs = _timer.lastSessionSeconds % 60;
    final timeStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    return Column(children: [
      Image.asset('assets/images/owl_celebrating.png', width: 110, height: 110, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/owl_happy.png', width: 110, height: 110)),
      const SizedBox(height: 14),
      // Speech
      Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider, width: 0.8)),
        child: Text('Amazing focus! Every minute of reading makes you sharper.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontStyle: FontStyle.italic, height: 1.4)),
      ),
      const SizedBox(height: 24),
      Text('Session Complete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      const SizedBox(height: 20),
      // Stats row
      Row(children: [
        _statCard(Icons.schedule_rounded, timeStr, 'Duration', AppColors.primary),
        const SizedBox(width: 12),
        _featherCard(),
      ]),
      if (_timer.tokensEarned > 0) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(color: AppColors.successGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Text('+ ${_timer.tokensEarned} feathers earned', style: TextStyle(fontSize: 12, color: AppColors.successGreen, fontWeight: FontWeight.w700)),
        ),
      ],
    ]);
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.15)), boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
      ]),
    ));
  }

  Widget _featherCard() {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.gold.withOpacity(0.2)), boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(children: [
        Image.asset('assets/images/purple_feather.png', width: 22, height: 22),
        const SizedBox(height: 8),
        Text('+${_timer.tokensEarned}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text('Feathers', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
      ]),
    ));
  }

  Widget _buildButton(bool isRunning, bool isFinished) {
    if (isFinished) {
      return Column(children: [
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
          onPressed: () { _timer.reset(); Navigator.of(context).pop(); },
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        )),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () { _timer.reset(); _tip = _focusTips[Random().nextInt(_focusTips.length)]; setState(() {}); },
          child: Text('Start another session', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ]);
    }

    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          if (isRunning) { _timer.stop(); } else { _timer.start(); _tip = _focusTips[Random().nextInt(_focusTips.length)]; }
          setState(() {});
        },
        style: ElevatedButton.styleFrom(backgroundColor: isRunning ? AppColors.error : AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        icon: Icon(isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 22),
        label: Text(isRunning ? 'End Session' : 'Start Reading', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}
