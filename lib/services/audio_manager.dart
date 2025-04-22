import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

const String _clickSound = 'audio/click.ogg';
const String _winMatchSound = 'audio/win_match.ogg';
const String _winTournamentSound = 'audio/win_tournament.ogg';
const String _backgroundMusic = 'audio/background_music.ogg';

class AudioManager {
  AudioManager._privateConstructor();
  static final AudioManager instance = AudioManager._privateConstructor();

  final AudioPlayer _backgroundPlayer = AudioPlayer(
    playerId: 'background_player',
  );
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx_player');

  bool _isMusicEnabled = true;
  bool _areSfxEnabled = true;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    await _sfxPlayer.setReleaseMode(
      ReleaseMode.release,
    ); // Liberar recursos tras reproducir SFX
    _isInitialized = true;
    if (kDebugMode) {
      print("AudioManager Initialized");
    }
  }

  Future<void> _play(
    AudioPlayer player,
    String assetPath, {
    double volume = 1.0,
    bool isSfx = false,
  }) async {
    if (!_isInitialized) await init();

    bool shouldPlay = isSfx ? _areSfxEnabled : _isMusicEnabled;
    if (!shouldPlay) return;

    try {
      // Detener si ya está sonando
      if (player.state == PlayerState.playing && isSfx) {
        await player.stop();
      }
      await player.setVolume(volume);
      await player.play(AssetSource(assetPath));
      if (kDebugMode) {
        print("AudioManager: Playing ${isSfx ? 'SFX' : 'Music'} $assetPath");
      }
    } catch (e) {
      if (kDebugMode) {
        print("AudioManager Error playing $assetPath: $e");
      }
    }
  }

  Future<void> playBackgroundMusic({double volume = 0.4}) async {
    if (!_isMusicEnabled) {
      await stopBackgroundMusic();
      return;
    }
    await _play(
      _backgroundPlayer,
      _backgroundMusic,
      volume: volume,
      isSfx: false,
    );
  }

  Future<void> stopBackgroundMusic() async {
    if (!_isInitialized) return; // No intentar detener si no está inicializado
    if (_backgroundPlayer.state != PlayerState.stopped) {
      try {
        await _backgroundPlayer.stop();
        if (kDebugMode) {
          print("AudioManager: Stopping background music");
        }
      } catch (e) {
        if (kDebugMode) {
          print("AudioManager Error stopping music: $e");
        }
      }
    }
  }

  Future<void> playClickSound({double volume = 0.8}) async {
    await _play(_sfxPlayer, _clickSound, volume: volume, isSfx: true);
  }

  Future<void> playWinMatchSound({double volume = 0.8}) async {
    await _play(_sfxPlayer, _winMatchSound, volume: volume, isSfx: true);
  }

  Future<void> playWinTournamentSound({double volume = 1.0}) async {
    await _play(_sfxPlayer, _winTournamentSound, volume: volume, isSfx: true);
  }

  // --- Controles de Habilitación ---
  void enableMusic(bool enabled) {
    _isMusicEnabled = enabled;
    if (!enabled) {
      stopBackgroundMusic();
    } else {}

    if (kDebugMode) {
      print("AudioManager: Music enabled: $enabled");
    }
  }

  void enableSfx(bool enabled) {
    _areSfxEnabled = enabled;

    if (kDebugMode) {
      print("AudioManager: SFX enabled: $enabled");
    }
  }

  // --- Getters para UI
  bool get isMusicEnabled => _isMusicEnabled;
  bool get areSfxEnabled => _areSfxEnabled;

  // --- Limpieza ---
  void dispose() {
    if (!_isInitialized) return;
    _backgroundPlayer.dispose();
    _sfxPlayer.dispose();
    if (kDebugMode) {
      print("AudioManager: Disposed audio players");
    }
  }
}
