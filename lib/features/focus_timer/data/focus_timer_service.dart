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

  /// Tokens per hour rate — should match the backend's `TokensPerHour`
  /// admin setting. The backend uses the same formula when crediting tokens
  /// via the reading-session /progress endpoint. Current backend setting
  /// awards ~2 tokens per minute (120/hr).
  static const int _tokensPerHour = 120;

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _lastSessionSeconds = _seconds;
    // Same formula as the backend: round(tokensPerHour * minutes / 60)
    final minutes = _seconds / 60.0;
    _tokensEarned = ((_tokensPerHour * minutes) / 60.0).round();
    notifyListeners();
  }

  void reset() {
    _seconds = 0;
    _lastSessionSeconds = 0;
    _tokensEarned = 0;
    notifyListeners();
  }
}
