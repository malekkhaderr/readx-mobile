import 'dart:async';
import 'package:flutter/foundation.dart';

class FocusTimerService extends ChangeNotifier {
  static final FocusTimerService _instance = FocusTimerService._();
  factory FocusTimerService() => _instance;
  FocusTimerService._();

  Timer? _timer;
  DateTime? _startedAt;
  int _seconds = 0;
  bool _isRunning = false;
  int _lastSessionSeconds = 0;
  int _tokensEarned = 0;

  bool get isRunning => _isRunning;
  int get seconds => _seconds;
  int get minutes => _seconds ~/ 60;
  int get lastSessionSeconds => _lastSessionSeconds;
  int get tokensEarned => _tokensEarned;

  String get formattedTime {
    final h = _seconds ~/ 3600;
    final m = (_seconds % 3600) ~/ 60;
    final s = _seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _seconds = 0;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _seconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _lastSessionSeconds = _seconds;
    // Award 1 token per 5 minutes of focused reading
    _tokensEarned = _seconds ~/ 300;
    notifyListeners();
  }

  void reset() {
    _seconds = 0;
    _lastSessionSeconds = 0;
    _tokensEarned = 0;
    notifyListeners();
  }
}
