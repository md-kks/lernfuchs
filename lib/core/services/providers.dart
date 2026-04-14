import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import 'tts_service.dart';
import 'sound_service.dart';
import '../../services/audio_service.dart';
import '../../services/accessibility_service.dart';
import '../../services/dialogue_service.dart';
import '../../services/fino_evolution_service.dart';
import '../../services/school_mode_service.dart';
import '../../services/season_service.dart';
import '../learning/learning.dart';
import '../models/settings.dart';
import '../models/progress.dart';
import '../models/subject.dart';

/// Gibt die initialisierte [StorageService]-Instanz als Riverpod-Provider bereit.
///
/// Da [StorageService] ein Singleton ist, liefert dieser Provider immer
/// dieselbe Instanz zurück. Kein `await` nötig — Initialisierung erfolgt
/// einmalig in `main()`.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final learningEngineProvider = Provider<LearningEngine>((ref) {
  return DefaultLearningEngine(ref.watch(storageServiceProvider));
});

final dailyPathServiceProvider = Provider<DailyPathService>((ref) {
  return DailyPathService(learningEngine: ref.watch(learningEngineProvider));
});

/// Gibt die initialisierte [TtsService]-Instanz bereit.
///
/// Muss mit `overrides` in `ProviderScope` nach `TtsService.create()`
/// initialisiert werden (in `main()`). Alle Widgets greifen dann
/// via `ref.read(ttsServiceProvider)` auf dieselbe Instanz zu.
final ttsServiceProvider = Provider<TtsService>((ref) {
  throw UnimplementedError('TtsService must be initialized in main()');
});

/// Gibt die initialisierte [SoundService]-Instanz bereit.
///
/// Hängt von [ttsServiceProvider] ab. Wird ebenfalls in `main()`
/// per `overrides` initialisiert.
final soundServiceProvider = Provider<SoundService>((ref) {
  throw UnimplementedError('SoundService must be initialized in main()');
});

final dialogueServiceProvider = Provider<DialogueService>((ref) {
  return DialogueService();
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

final seasonServiceProvider = Provider<SeasonService>((ref) {
  return SeasonService();
});

final finoEvolutionProvider = Provider<FinoEvolutionService>((ref) {
  return FinoEvolutionService();
});

final accessibilityProvider = Provider<AccessibilityService>((ref) {
  return AccessibilityService();
});

final schoolModeProvider = Provider<SchoolModeService>((ref) {
  return SchoolModeService();
});

// ── App-Einstellungen ──────────────────────────────────────────────────────

/// App-Einstellungen als reaktiver State.
///
/// Schreib-Zugriff über [AppSettingsNotifier]-Methoden, die gleichzeitig
/// die Änderung in [StorageService] persistieren:
/// ```dart
/// ref.read(appSettingsProvider.notifier).toggleSound(false);
/// ```
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
      (ref) => AppSettingsNotifier(ref.watch(storageServiceProvider)),
    );

/// Notifier für [AppSettings] — kapselt alle Schreiboperationen
/// und persistiert automatisch in [StorageService].
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;

  AppSettingsNotifier(this._storage) : super(_storage.settings);

  /// Setzt das Bundesland / Land und speichert die Änderung.
  Future<void> updateFederalState(String code) async {
    state = state.copyWith(federalState: code);
    await _storage.saveSettings(state);
  }

  /// Markiert das Onboarding als abgeschlossen.
  Future<void> setOnboardingDone() async {
    state = state.copyWith(onboardingDone: true);
    await _storage.saveSettings(state);
  }

  /// Aktiviert oder deaktiviert Soundeffekte.
  Future<void> toggleSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await _storage.saveSettings(state);
  }

  /// Aktiviert oder deaktiviert Text-to-Speech.
  Future<void> toggleTts(bool value) async {
    state = state.copyWith(ttsEnabled: value);
    await _storage.saveSettings(state);
  }

  /// Aktiviert oder deaktiviert den Hochkontrast-Modus.
  Future<void> toggleHighContrast(bool value) async {
    state = state.copyWith(highContrast: value);
    await _storage.saveSettings(state);
  }

  /// Aktualisiert den Schriftgrößen-Skalierungsfaktor (1.0 / 1.15 / 1.3).
  Future<void> updateFontSize(double factor) async {
    state = state.copyWith(fontSize: factor);
    await _storage.saveSettings(state);
  }

  /// Setzt einen neuen 4-stelligen Eltern-PIN.
  Future<void> setParentPin(String pin) async {
    state = state.copyWith(parentPin: pin);
    await _storage.saveSettings(state);
  }

  /// Entfernt den Eltern-PIN (kein Schutz mehr).
  Future<void> clearParentPin() async {
    // copyWith kann parentPin nicht auf null setzen (nullable collision),
    // daher explizites Neuerstellen mit parentPin: null.
    state = AppSettings(
      federalState: state.federalState,
      soundEnabled: state.soundEnabled,
      ttsEnabled: state.ttsEnabled,
      fontSize: state.fontSize,
      highContrast: state.highContrast,
      activeProfileId: state.activeProfileId,
      parentPin: null,
      onboardingDone: state.onboardingDone,
    );
    await _storage.saveSettings(state);
  }

  /// Wechselt das aktive Kinderprofil.
  Future<void> switchProfile(String profileId) async {
    state = state.copyWith(activeProfileId: profileId);
    await _storage.saveSettings(state);
  }
}

// ── Profile ───────────────────────────────────────────────────────────────

/// Gibt das aktuell aktive [ChildProfile] zurück — oder `null`, wenn noch
/// kein Profil angelegt wurde.
///
/// Leitet sich aus [appSettingsProvider.activeProfileId] ab und ist
/// automatisch reaktiv: Profilwechsel propagiert in die gesamte UI.
final activeProfileProvider = Provider<ChildProfile?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final storage = ref.watch(storageServiceProvider);
  return storage.getProfile(settings.activeProfileId);
});

/// Gibt alle vorhandenen Kinderprofile zurück.
final allProfilesProvider = Provider<List<ChildProfile>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.profiles;
});

// ── Fortschritt ───────────────────────────────────────────────────────────

/// Lernfortschritt für ein bestimmtes Thema/Fach/Klasse/Profil.
///
/// Parametrisierter Provider:
/// ```dart
/// final progress = ref.watch(topicProgressProvider((
///   profileId: 'abc',
///   subject: 'math',
///   grade: 2,
///   topic: 'uhrzeit',
/// )));
/// ```
final topicProgressProvider =
    Provider.family<
      TopicProgress,
      ({String profileId, String subject, int grade, String topic})
    >((ref, params) {
      final subject = Subject.values.firstWhere((s) => s.id == params.subject);
      final learning = ref.watch(learningEngineProvider);
      return learning.progressFor(
        profileId: params.profileId,
        subject: subject,
        grade: params.grade,
        topic: params.topic,
      );
    });

/// Alle Fortschrittseinträge für das aktive Profil.
final allProgressProvider = Provider<List<TopicProgress>>((ref) {
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return [];
  final learning = ref.watch(learningEngineProvider);
  return learning.allProgressForProfile(profile.id);
});
