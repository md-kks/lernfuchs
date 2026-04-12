import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';

/// Text-to-Speech Service für LernFuchs.
///
/// Liest Aufgaben, Wörter und Feedback-Phrasen laut vor — besonders nützlich
/// für Kinder in Kl.1, die noch nicht sicher lesen können.
///
/// ### Nutzung
/// ```dart
/// final tts = ref.read(ttsServiceProvider);
/// await tts.speak('Wie viele Punkte siehst du?');
/// await tts.stop(); // beim Verlassen des Screens
/// ```
///
/// ### Konfiguration
/// - Sprache: `de-DE`
/// - Sprechgeschwindigkeit: 0.45 (langsamer als Standard — kindgerecht)
/// - Tonhöhe: 1.1 (leicht höher — freundlicher Klang)
///
/// Ist TTS in den [AppSettings] deaktiviert ([ttsEnabled] == false),
/// werden alle Speak-Aufrufe still ignoriert.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _enabled;

  TtsService({required bool enabled}) : _enabled = enabled;

  /// Initialisiert die TTS-Engine (muss einmalig vor dem ersten Sprechen aufgerufen werden).
  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.1);
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  /// Aktiviert oder deaktiviert TTS zur Laufzeit (z.B. via Einstellungen-Toggle).
  void setEnabled(bool value) => _enabled = value;

  /// Gibt `true` zurück wenn TTS aktiviert und initialisiert ist.
  bool get isEnabled => _enabled && _initialized;

  /// Spricht den übergebenen [text] laut vor.
  ///
  /// Bricht einen laufenden Vorlesevorgang zuerst ab (kein Überlappen).
  /// Tut nichts wenn TTS deaktiviert ist.
  Future<void> speak(String text) async {
    if (!_enabled) return;
    if (!_initialized) await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Spricht eine kurze Feedback-Phrase basierend auf [correct].
  ///
  /// Richtig: zufällige Lobantwort ("Super!", "Sehr gut!", "Prima!").
  /// Falsch: ermutigende Phrase ("Nicht ganz — versuch nochmal!", "Fast!").
  Future<void> speakFeedback(bool correct) async {
    if (!_enabled) return;
    final phrases = correct
        ? ['Super!', 'Sehr gut!', 'Prima!', 'Toll gemacht!', 'Richtig!']
        : ['Nicht ganz!', 'Versuch es nochmal!', 'Fast!', 'Leider falsch!'];
    final phrase = phrases[DateTime.now().millisecond % phrases.length];
    await speak(phrase);
  }

  /// Stoppt den aktuell laufenden Vorlesevorgang sofort.
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Gibt Ressourcen frei (aufrufen wenn der Service nicht mehr benötigt wird).
  Future<void> dispose() async {
    await _tts.stop();
  }

  /// Erstellt und initialisiert eine [TtsService]-Instanz.
  ///
  /// Liest [StorageService.instance.settings.ttsEnabled] um den initialen
  /// Aktivierungszustand zu setzen.
  static Future<TtsService> create() async {
    final enabled = StorageService.instance.settings.ttsEnabled;
    final svc = TtsService(enabled: enabled);
    await svc.init();
    return svc;
  }
}
