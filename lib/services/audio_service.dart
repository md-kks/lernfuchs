import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../core/services/storage_service.dart';

class AudioService {
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  double _ambientVolume = 0.35;

  late bool musicEnabled = StorageService.instance.getBoolValue(
    'music_enabled',
    defaultValue: true,
  );
  late bool sfxEnabled = StorageService.instance.getBoolValue(
    'sfx_enabled',
    defaultValue: true,
  );

  void playAmbient(String worldId) {
    if (!sfxEnabled) return;
    final file = 'assets/audio/ambient_$worldId.mp3';
    _ambientVolume = 0.35;
    unawaited(_ambientPlayer.setReleaseMode(ReleaseMode.loop));
    unawaited(_ambientPlayer.setVolume(_ambientVolume));
    unawaited(_ambientPlayer.play(_asset(file)).catchError((_) {}));
  }

  void stopAmbient() {
    unawaited(_ambientPlayer.stop());
  }

  void fadeOutAmbient() {
    const steps = 15;
    var tick = 0;
    final startVolume = _ambientVolume;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      tick++;
      _ambientVolume = startVolume * (1 - tick / steps).clamp(0.0, 1.0);
      unawaited(_ambientPlayer.setVolume(_ambientVolume));
      if (tick >= steps) {
        timer.cancel();
        stopAmbient();
      }
    });
  }

  void playMusic(String trackName) {
    if (!musicEnabled) return;
    unawaited(_musicPlayer.setReleaseMode(ReleaseMode.loop));
    unawaited(_musicPlayer.setVolume(0.25));
    unawaited(
      _musicPlayer
          .play(_asset('assets/audio/music_$trackName.mp3'))
          .catchError((_) {}),
    );
  }

  void stopMusic() {
    unawaited(_musicPlayer.stop());
  }

  void playSfx(String sfxName) {
    if (!sfxEnabled) return;
    unawaited(
      _sfxPlayer
          .play(_asset('assets/audio/sfx_$sfxName.ogg'))
          .catchError((_) {}),
    );
  }

  void setMusicEnabled(bool value) {
    musicEnabled = value;
    unawaited(StorageService.instance.setOnboardingValue('music_enabled', value));
    if (!value) stopMusic();
  }

  void setSfxEnabled(bool value) {
    sfxEnabled = value;
    unawaited(StorageService.instance.setOnboardingValue('sfx_enabled', value));
    if (!value) stopAmbient();
  }

  void dispose() {
    unawaited(_ambientPlayer.dispose());
    unawaited(_musicPlayer.dispose());
    unawaited(_sfxPlayer.dispose());
  }

  AssetSource _asset(String path) {
    return AssetSource(path.startsWith('assets/') ? path.substring(7) : path);
  }
}
