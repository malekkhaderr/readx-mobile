import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central sound service for ReadX.
///
/// All sound playback goes through this singleton so:
///   1. There is a single on/off toggle persisted in SharedPreferences.
///   2. Sounds are pre-loaded into memory at init for instant playback.
///   3. Each play call creates a disposable AudioPlayer so overlapping
///      clips (e.g. rapid tab clicks) never block each other.
///
/// Usage:
///   sl<SoundService>().levelUp();
///   sl<SoundService>().quoteSaved();
class SoundService {
  SoundService._();
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  static const _kPrefKey = 'sound_effects_enabled';

  bool _enabled = true;
  bool get isEnabled => _enabled;

  /// Pre-loaded audio bytes keyed by filename. Loading from rootBundle
  /// at init time guarantees the bytes are available instantly when
  /// play() is called, bypassing platform-specific AssetSource issues.
  final Map<String, Uint8List> _cache = {};

  /// All audio asset filenames the app uses.
  /// Most are WAV (PCM 16-bit); quote-saved is actual MP3.
  static const _assets = [
    'tab-click.wav',
    'level-up.wav',
    'session-complete.wav',
    'feather-earned.wav',
    'quote-saved.mp3',
    'page-turn.wav',
    'book-open.wav',
    'timer-start.wav',
    'auth-success.wav',
    'error.wav',
    'notification.wav',
    'purchase.wav',
    'owl-hoot.wav',
  ];

  /// Call once during app startup (after [SharedPreferences] is ready).
  /// Pre-loads all audio files from the asset bundle into memory.
  Future<void> init(SharedPreferences prefs) async {
    _enabled = prefs.getBool(_kPrefKey) ?? true;

    // Pre-load all audio files into byte buffers. If any file is missing
    // or corrupt we just skip it — the app still works, just silent.
    for (final name in _assets) {
      try {
        final data = await rootBundle.load('assets/audio/$name');
        _cache[name] = data.buffer.asUint8List();
      } catch (e) {
        debugPrint('SoundService: could not pre-load $name — $e');
      }
    }
    debugPrint('SoundService: pre-loaded ${_cache.length}/${_assets.length} audio files');
  }

  /// Toggle sound on/off and persist the preference.
  Future<void> setEnabled(bool value, SharedPreferences prefs) async {
    _enabled = value;
    await prefs.setBool(_kPrefKey, value);
  }

  // ─── Core player ────────────────────────────────────────────

  /// Plays an audio clip by filename using AssetSource (relies on Flutter's
  /// asset bundling). MediaPlayer mode is used since it supports all source
  /// types on Android without restriction.
  Future<void> play(String assetName, {double volume = 1.0}) async {
    if (!_enabled) return;

    // Verify the file was pre-loaded (i.e. exists in the bundle)
    if (!_cache.containsKey(assetName)) {
      debugPrint('SoundService: $assetName not in cache, skipping');
      return;
    }

    try {
      final player = AudioPlayer();
      player.setAudioContext(AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          audioMode: AndroidAudioMode.normal,
          usageType: AndroidUsageType.media,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.none,
        ),
      ));
      await player.setVolume(volume);
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.play(AssetSource('audio/$assetName'));
      player.onPlayerComplete.listen((_) => player.dispose());
      // Auto-dispose after 10s in case onPlayerComplete never fires
      Future.delayed(const Duration(seconds: 10), () {
        try { player.dispose(); } catch (_) {}
      });
    } catch (e) {
      debugPrint('SoundService: failed to play $assetName — $e');
    }
  }

  // ─── Named convenience methods ───────────────────────────────

  Future<void> levelUp() => play('level-up.wav');
  Future<void> sessionComplete() => play('session-complete.wav');
  Future<void> featherEarned() => play('feather-earned.wav', volume: 0.85);
  Future<void> quoteSaved() => play('quote-saved.mp3');
  Future<void> pageTurn() => play('page-turn.wav', volume: 0.3);
  Future<void> bookOpen() => play('book-open.wav', volume: 0.6);
  Future<void> timerStart() => play('timer-start.wav', volume: 0.65);
  Future<void> owlHoot() => play('owl-hoot.wav', volume: 0.4);
  Future<void> tabClick() => play('tab-click.wav', volume: 0.28);
  Future<void> authSuccess() => play('auth-success.wav', volume: 0.7);
  Future<void> error() => play('error.wav', volume: 0.5);
  Future<void> notification() => play('notification.wav');
  Future<void> purchase() => play('purchase.wav');
}
