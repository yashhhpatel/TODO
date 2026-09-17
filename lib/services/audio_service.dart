import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

/// Named SFX. Files (if present) live under assets/audio/<name>.mp3.
enum Sfx { select, correct, wrong, coin, hint, levelComplete, achievement, tap }

/// Centralized audio. All playback is wrapped so that missing asset files (the
/// project ships without bundled audio yet) never crash gameplay — sound simply
/// becomes a no-op until real, licensed assets are added and declared.
class AudioService {
  AudioService(this._settings);
  final SettingsService _settings;

  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx');
  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'music');
  bool _musicStarted = false;

  static const Map<Sfx, String> _files = {
    Sfx.select: 'audio/select.wav',
    Sfx.correct: 'audio/correct.wav',
    Sfx.wrong: 'audio/wrong.wav',
    Sfx.coin: 'audio/coin.wav',
    Sfx.hint: 'audio/hint.wav',
    Sfx.levelComplete: 'audio/level_complete.wav',
    Sfx.achievement: 'audio/achievement.wav',
    Sfx.tap: 'audio/tap.wav',
  };

  Future<void> play(Sfx sfx) async {
    if (!_settings.sound) return;
    final path = _files[sfx];
    if (path == null) return;
    try {
      // play() restarts from the current source, giving snappy repeated SFX.
      await _sfxPlayer.play(AssetSource(path));
    } catch (e) {
      if (kDebugMode) debugPrint('SFX unavailable ($path): $e');
    }
  }

  Future<void> startMusic() async {
    if (!_settings.music || _musicStarted) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource('audio/music.wav'), volume: 0.4);
      _musicStarted = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Music unavailable: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
    _musicStarted = false;
  }

  /// Re-sync music with the current setting (call after toggling).
  Future<void> syncMusic() async {
    if (_settings.music) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}
