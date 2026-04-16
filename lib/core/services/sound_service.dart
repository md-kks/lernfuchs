import 'package:flutter/services.dart';
import 'storage_service.dart';
import 'tts_service.dart';

/// Audio-Feedback-Service für Gamification-Elemente.
///
/// Kombiniert haptisches Feedback ([HapticFeedback]) mit kurzen
/// TTS-Phrasen — benötigt keinerlei Audiodateien und funktioniert
/// vollständig offline.
///
/// ### Feedback-Arten
/// - [playCorrect]: kräftiges haptisches Feedback + "Super!"
/// - [playWrong]: leichtes haptisches Feedback + "Versuch es nochmal!"
/// - [playComplete]: mehrstufiges haptisches Feedback für Sitzungsende
/// - [playTap]: minimales haptisches Feedback für Button-Taps
///
/// Ist Sound in den [AppSettings] deaktiviert ([soundEnabled] == false),
/// werden alle haptischen Feedbacks unterdrückt; TTS-Phrasen werden
/// zusätzlich durch [TtsService.isEnabled] gesteuert.
class SoundService {
  final TtsService _tts;
  bool _enabled;

  SoundService({required TtsService tts, required bool enabled})
      : _tts = tts,
        _enabled = enabled;

  /// Aktiviert oder deaktiviert Sound-Feedback zur Laufzeit.
  void setEnabled(bool value) => _enabled = value;

  /// Spielt Feedback für eine richtige Antwort ab.
  Future<void> playCorrect() async {
    if (_enabled) await HapticFeedback.mediumImpact();
    await _tts.speakFeedback(true);
  }

  /// Spielt Feedback für eine falsche Antwort ab.
  Future<void> playWrong() async {
    if (_enabled) await HapticFeedback.lightImpact();
    await _tts.speakFeedback(false);
  }

  /// Spielt Abschluss-Feedback für das Ende einer Session ab.
  Future<void> playComplete() async {
    if (_enabled) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.mediumImpact();
    }
    await _tts.speak('Toll! Du hast die Übung abgeschlossen!');
  }

  /// Minimales haptisches Feedback für UI-Interaktionen (Taps, Auswahl).
  Future<void> playTap() async {
    if (_enabled) await HapticFeedback.selectionClick();
  }

  /// Erstellt eine [SoundService]-Instanz auf Basis des [TtsService]
  /// und der aktuellen [StorageService]-Einstellungen.
  static SoundService create(TtsService tts) {
    final enabled = StorageService.instance.settings.soundEnabled;
    return SoundService(tts: tts, enabled: enabled);
  }
}
