import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress.dart';
import '../models/settings.dart';

/// Persistenz-Service auf Basis von [SharedPreferences] (JSON-kodiert).
///
/// Die App arbeitet **vollständig offline** — dieser Service ist der einzige
/// Persistenz-Layer. Es gibt keine Netzwerkaufrufe, keine Datenbank,
/// keine Drittanbieter-Analytics.
///
/// ### Schlüssel-Schema in SharedPreferences
/// | Präfix / Schlüssel          | Inhalt                        |
/// |-----------------------------|-------------------------------|
/// | `lf_settings`               | [AppSettings] (JSON)          |
/// | `lf_profiles`               | `List<ChildProfile>` (JSON)   |
/// | `lf_progress_<profileId>-<subject>-<grade>-<topic>` | [TopicProgress] (JSON) |
///
/// ### Singleton-Pattern
/// Muss einmalig via `await StorageService.init()` in `main()` initialisiert
/// werden. Danach überall via [StorageService.instance] erreichbar (ohne await).
class StorageService {
  static const _settingsKey = 'lf_settings';
  static const _progressPrefix = 'lf_progress_';
  static const _profilesKey = 'lf_profiles';

  late SharedPreferences _prefs;
  static StorageService? _instance;

  StorageService._();

  /// Initialisiert den Service und gibt die Singleton-Instanz zurück.
  ///
  /// Muss **vor** `runApp()` aufgerufen werden:
  /// ```dart
  /// await StorageService.init();
  /// runApp(ProviderScope(child: LernFuchsApp()));
  /// ```
  static Future<StorageService> init() async {
    if (_instance != null) return _instance!;
    final svc = StorageService._();
    svc._prefs = await SharedPreferences.getInstance();
    _instance = svc;
    return svc;
  }

  /// Gibt die initialisierte Singleton-Instanz zurück.
  /// Wirft [AssertionError], wenn [init] noch nicht aufgerufen wurde.
  static StorageService get instance {
    assert(_instance != null, 'StorageService.init() must be called first');
    return _instance!;
  }

  // ── Settings ──────────────────────────────────────────────────────────

  /// Liest die aktuellen App-Einstellungen; gibt Standardwerte zurück
  /// wenn noch keine gespeichert sind.
  AppSettings get settings {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Speichert die App-Einstellungen dauerhaft.
  Future<void> saveSettings(AppSettings s) async {
    await _prefs.setString(_settingsKey, jsonEncode(s.toJson()));
  }

  // ── Profile ───────────────────────────────────────────────────────────

  /// Liest alle Kinderprofile; gibt eine leere Liste zurück wenn keine vorhanden.
  List<ChildProfile> get profiles {
    final raw = _prefs.getString(_profilesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ChildProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Speichert die komplette Profil-Liste.
  Future<void> saveProfiles(List<ChildProfile> profiles) async {
    await _prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  /// Gibt ein einzelnes Profil anhand seiner ID zurück, oder `null`.
  ChildProfile? getProfile(String id) {
    return profiles.where((p) => p.id == id).firstOrNull;
  }

  /// Speichert ein einzelnes Profil (fügt es ein oder überschreibt es).
  Future<void> saveProfile(ChildProfile profile) async {
    final list = profiles.where((p) => p.id != profile.id).toList()
      ..add(profile);
    await saveProfiles(list);
  }

  // ── Fortschritt ───────────────────────────────────────────────────────

  /// Liest den Lernfortschritt für ein Thema; gibt ein leeres [TopicProgress]-
  /// Objekt zurück wenn noch keine Daten vorhanden sind.
  TopicProgress getProgress({
    required String profileId,
    required String subject,
    required int grade,
    required String topic,
  }) {
    final key = _progressPrefix + '$profileId-$subject-$grade-$topic';
    final raw = _prefs.getString(key);
    if (raw == null) {
      return TopicProgress(
        profileId: profileId,
        subject: subject,
        grade: grade,
        topic: topic,
        lastPracticed: DateTime.now(),
      );
    }
    return TopicProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Speichert einen [TopicProgress]-Eintrag.
  Future<void> saveProgress(TopicProgress progress) async {
    final key = _progressPrefix + progress.key;
    await _prefs.setString(key, jsonEncode(progress.toJson()));
  }

  /// Liest den aktuellen Fortschritt, trägt das Ergebnis ein und speichert zurück.
  ///
  /// Convenience-Methode für [ExerciseScreen]: kein separates `getProgress` +
  /// `recordResult` + `saveProgress` nötig.
  Future<void> recordResult({
    required String profileId,
    required String subject,
    required int grade,
    required String topic,
    required bool correct,
  }) async {
    final progress = getProgress(
      profileId: profileId,
      subject: subject,
      grade: grade,
      topic: topic,
    );
    progress.recordResult(correct);
    await saveProgress(progress);
  }

  /// Gibt alle gespeicherten Fortschrittseinträge eines Profils zurück.
  ///
  /// Genutzt vom [ProgressScreen] zur Gesamtauswertung.
  List<TopicProgress> allProgressForProfile(String profileId) {
    return _prefs
        .getKeys()
        .where((k) => k.startsWith('${_progressPrefix}$profileId-'))
        .map((k) {
          final raw = _prefs.getString(k);
          if (raw == null) return null;
          return TopicProgress.fromJson(
              jsonDecode(raw) as Map<String, dynamic>);
        })
        .whereType<TopicProgress>()
        .toList();
  }

  bool get placementCompleted =>
      _prefs.getBool('placement_completed') ?? false;

  Future<void> setPlacementCompleted(bool value) async {
    await _prefs.setBool('placement_completed', value);
  }

  bool getBoolValue(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  int getIntValue(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  List<String> getStringListValue(String key, {List<String> defaultValue = const []}) {
    return _prefs.getStringList(key) ?? defaultValue;
  }

  String? getStringValue(String key) {
    return _prefs.getString(key);
  }

  Future<void> setOnboardingValue(String key, Object value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else if (value is Map) {
      await _prefs.setString(key, jsonEncode(value));
    } else {
      throw ArgumentError('Unsupported onboarding value type: $value');
    }
  }
}
