import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/focus_timer_service.dart';

class FocusTimerPage extends StatefulWidget {
  const FocusTimerPage({super.key});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> {
  final _timer = FocusTimerService();

  @override
  void initState() {
    super.initState();
    _timer.addListener(_onTick);
  }

  @override
  void dispose() {
    _timer.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _timer.isRunning;
    final isFinished = !isRunning && _timer.lastSessionSeconds > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
        title: Text('Focus Mode', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(children: [
            const Spacer(flex: 2),
            if (!isFinished) _buildTimer(isRunning),
            if (isFinished) _buildResults(),
            const Spacer(flex: 2),
            _buildButton(isRunning, isFinished),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _buildTimer(bool isRunning) {
    return Column(children: [
      Image.asset(
        isRunning ? 'assets/images/owl_reading.png' : 'assets/images/owl_sleeping.png',
        width: 90, height: 90, fit: BoxFit.contain,
      ),
      const SizedBox(height: 16),
      Text(isRunning ? 'Reading in progress...' : 'Ready to focus?', style: TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
      const SizedBox(height: 28),
      Container(
        width: 180, height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: isRunning ? AppColors.primary.withOpacity(0.4) : AppColors.divider, width: isRunning ? 3 : 1.5),
          boxShadow: isRunning ? [BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 20, spreadRadius: 2)] : null,
        ),
        child: Center(
          child: Text(_timer.formattedTime, style: TextStyle(fontSize: 38, fontWeight: FontWeight.w300, color: AppColors.textDark, letterSpacing: 2, fontFamily: 'monospace')),
        ),
      ),
      if (isRunning) ...[
        const SizedBox(height: 14),
        Text('You can leave this page — timer keeps running', style: TextStyle(fontSize: 11, color: AppColors.successGreen, fontWeight: FontWeight.w600)),
      ],
    ]);
  }

  Widget _buildResults() {
    final mins = _timer.lastSessionSeconds ~/ 60;
    final secs = _timer.lastSessionSeconds % 60;
    final timeStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    return Column(children: [
      Image.asset('assets/images/owl_celebrating.png', width: 100, height: 100, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/owl_happy.png', width: 100, height: 100)),
      const SizedBox(height: 16),
      Text('Session Complete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      const SizedBox(height: 6),
      Text('Great focus! Keep building the habit.', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat(Icons.schedule_rounded, timeStr, 'Duration', AppColors.primary),
          Container(width: 1, height: 40, color: AppColors.divider),
          _stat(Icons.toll_rounded, '+${_timer.tokensEarned}', 'Tokens', AppColors.gold),
        ]),
      ),
      if (_timer.tokensEarned > 0) ...[
        const SizedBox(height: 10),
        Text('You earned ${_timer.tokensEarned} tokens for ${_timer.tokensEarned * 5}+ minutes of focus!', style: TextStyle(fontSize: 11, color: AppColors.successGreen, fontWeight: FontWeight.w600)),
      ],
    ]);
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
    ]);
  }

  Widget _buildButton(bool isRunning, bool isFinished) {
    if (isFinished) {
      return Column(children: [
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: () { _timer.reset(); Navigator.of(context).pop(); },
          child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        )),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () { _timer.reset(); setState(() {}); },
          child: Text('Start another session', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ]);
    }

    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          if (isRunning) { _timer.stop(); } else { _timer.start(); }
        },
        style: ElevatedButton.styleFrom(backgroundColor: isRunning ? AppColors.error : AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text(isRunning ? 'Stop Session' : 'Start Reading', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}
