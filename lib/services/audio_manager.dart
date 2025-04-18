import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

// --- Constantes de Nombres de Archivo (REEMPLAZA CON TUS NOMBRES REALES) ---
const String _clickSound = 'audio/click.ogg'; // <- REEMPLAZA
const String _winMatchSound = 'audio/win_match.ogg'; // <- REEMPLAZA
const String _winTournamentSound = 'audio/win_tournament.ogg'; // <- REEMPLAZA
const String _backgroundMusic = 'audio/background_music.ogg'; // <- REEMPLAZA (opcional)

class AudioManager {
  // Singleton pattern
  AudioManager._privateConstructor();
  static final AudioManager instance = AudioManager._privateConstructor();

  final AudioPlayer _backgroundPlayer = AudioPlayer(playerId: 'background_player');
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx_player');

  bool _isMusicEnabled = true; // Podrías cargar esto desde SharedPreferences
  bool _areSfxEnabled = true;  // Podrías cargar esto desde SharedPreferences

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return; // Evitar inicializar múltiples veces
    // Configuraciones iniciales si son necesarias
    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    await _sfxPlayer.setReleaseMode(ReleaseMode.release); // Liberar recursos tras reproducir SFX
    _isInitialized = true;
     if (kDebugMode) {
      print("AudioManager Initialized");
    }
  }

  Future<void> _play(AudioPlayer player, String assetPath, {double volume = 1.0, bool isSfx = false}) async {
     if (!_isInitialized) await init();

     bool shouldPlay = isSfx ? _areSfxEnabled : _isMusicEnabled;
     if (!shouldPlay) return;

    try {
      // Detener si ya está sonando (especialmente para SFX rápidos que no deben solaparse)
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
       // Considera mostrar un mensaje al usuario o loggear el error
    }
  }

  Future<void> playBackgroundMusic({double volume = 0.4}) async {
     if (!_isMusicEnabled) {
        await stopBackgroundMusic(); // Asegurarse de que esté detenido si se deshabilita
        return;
     }
    await _play(_backgroundPlayer, _backgroundMusic, volume: volume, isSfx: false);
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
    } else {
      // Opcional: reanudar la música si estaba sonando antes
      // playBackgroundMusic();
    }
    // TODO: Guardar preferencia (ej. SharedPreferences)
     if (kDebugMode) {
       print("AudioManager: Music enabled: $enabled");
     }
  }

  void enableSfx(bool enabled) {
    _areSfxEnabled = enabled;
    // TODO: Guardar preferencia
     if (kDebugMode) {
       print("AudioManager: SFX enabled: $enabled");
     }
  }

  // --- Getters para UI (ej. en pantalla de opciones) ---
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