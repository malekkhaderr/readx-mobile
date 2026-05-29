import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central sound service for ReadX.
///
/// All sound playback goes through this singleton so:
///   1. There is a single on/off toggle persisted in SharedPreferences.
///   2. Sounds are played with individual [AudioPlayer] instances so
///      overlapping clips (e.g. tab clicks) never block each other.
///   3. Each player is disposed automatically on completion.
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

  /// Call once during app startup (after [SharedPreferences] is ready).
  Future<void> init(SharedPreferences prefs) async {
    _enabled = prefs.getBool(_kPrefKey) ?? true;
  }

  /// Toggle sound on/off and persist the preference.
  Future<void> setEnabled(bool value, SharedPreferences prefs) async {
    _enabled = value;
    await prefs.setBool(_kPrefKey, value);
  }

  // ─── Core player ────────────────────────────────────────────

  /// Plays an asset from `assets/audio/<assetName>`.
  /// Returns immediately; the player is disposed on completion.
  Future<void> play(String assetName, {double volume = 1.0}) async {
    if (!_enabled) return;
    try {
      final player = AudioPlayer();
      await player.setVolume(volume);
      await player.play(AssetSource('audio/$assetName'));
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (_) {
      // Never crash the app over a missing / corrupt sound file.
    }
  }

  // ─── Named convenience methods ───────────────────────────────

  /// 🏆 Triumphant chime when the user reaches a new reader level.
  Future<void> levelUp() => play('level-up.mp3');

  /// 🔔 Soft bell when a focus reading session completes.
  Future<void> sessionComplete() => play('session-complete.mp3');

  /// ✨ Coin sparkle when feather tokens are awarded.
  Future<void> featherEarned() => play('feather-earned.mp3', volume: 0.85);

  /// 📝 Satisfying plop when a quote is saved.
  Future<void> quoteSaved() => play('quote-saved.mp3');

  /// 📖 Soft paper rustle on every page turn in the EPUB reader.
  Future<void> pageTurn() => play('page-turn.mp3', volume: 0.45);

  /// 📚 Gentle creak when opening a book to read.
  Future<void> bookOpen() => play('book-open.mp3', volume: 0.6);

  /// ▶ Soft click/inhale when a focus timer session starts.
  Future<void> timerStart() => play('timer-start.mp3', volume: 0.65);

  /// 🦉 Gentle owl hoot when the AI chat FAB is tapped.
  Future<void> owlHoot() => play('owl-hoot.mp3');

  /// 🔲 Very subtle click on bottom nav tab switch.
  Future<void> tabClick() => play('tab-click.mp3', volume: 0.28);

  /// 🔓 Happy chime on successful login or register.
  Future<void> authSuccess() => play('auth-success.mp3', volume: 0.7);

  /// ❌ Error or invalid action buzz.
  Future<void> error() => play('error.mp3', volume: 0.5);

  /// 💬 New incoming notification ping.
  Future<void> notification() => play('notification.mp3');

  /// 🛒 Reward store purchase sound.
  Future<void> purchase() => play('purchase.mp3');
}
