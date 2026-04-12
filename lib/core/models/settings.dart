/// Globale App-Einstellungen, persistent in SharedPreferences gespeichert.
///
/// Alle Felder haben Standardwerte, sodass die App ohne vorherige Konfiguration
/// sofort nutzbar ist.
///
/// Unveränderlichkeit: Änderungen immer via [copyWith] erzeugen und
/// über [AppSettingsNotifier] (Riverpod) persistieren.
class AppSettings {
  /// Kürzel des Bundeslandes / Landes, steuert Lehrplan-Reihenfolge.
  /// Standard: `'BY'` (Bayern). Alle Werte: [kFederalStates].
  String federalState;

  /// Ob Soundeffekte (Feedback-Töne) aktiv sind.
  bool soundEnabled;

  /// Ob Text-to-Speech (Vorlesen von Aufgaben) aktiv ist.
  /// Wird in Phase 4 implementiert; das Flag ist bereits persistiert.
  bool ttsEnabled;

  /// Skalierungsfaktor für die Schriftgröße (1.0 = normal, 1.3 = groß).
  double fontSize;

  /// Ob der Hochkontrast-Modus aktiv ist (Barrierefreiheit).
  bool highContrast;

  /// ID des aktuell aktiven [ChildProfile].
  String activeProfileId;

  /// Optionaler 4-stelliger Eltern-PIN für die Elternbereich-Sperre.
  /// `null` bedeutet: kein PIN gesetzt, Elternbereich ungeschützt.
  String? parentPin;

  /// Ob das Onboarding (erstmaliger Setup-Dialog) abgeschlossen wurde.
  bool onboardingDone;

  AppSettings({
    this.federalState = 'BY',
    this.soundEnabled = true,
    this.ttsEnabled = true,
    this.fontSize = 1.0,
    this.highContrast = false,
    this.activeProfileId = 'default',
    this.parentPin,
    this.onboardingDone = false,
  });

  Map<String, dynamic> toJson() => {
        'federalState': federalState,
        'soundEnabled': soundEnabled,
        'ttsEnabled': ttsEnabled,
        'fontSize': fontSize,
        'highContrast': highContrast,
        'activeProfileId': activeProfileId,
        'parentPin': parentPin,
        'onboardingDone': onboardingDone,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        federalState: json['federalState'] as String? ?? 'BY',
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        ttsEnabled: json['ttsEnabled'] as bool? ?? true,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 1.0,
        highContrast: json['highContrast'] as bool? ?? false,
        activeProfileId: json['activeProfileId'] as String? ?? 'default',
        parentPin: json['parentPin'] as String?,
        onboardingDone: json['onboardingDone'] as bool? ?? false,
      );

  /// Erzeugt eine Kopie mit einzeln überschriebenen Feldern.
  /// Nicht übergebene Parameter behalten ihren aktuellen Wert.
  AppSettings copyWith({
    String? federalState,
    bool? soundEnabled,
    bool? ttsEnabled,
    double? fontSize,
    bool? highContrast,
    String? activeProfileId,
    String? parentPin,
    bool? onboardingDone,
  }) =>
      AppSettings(
        federalState: federalState ?? this.federalState,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        ttsEnabled: ttsEnabled ?? this.ttsEnabled,
        fontSize: fontSize ?? this.fontSize,
        highContrast: highContrast ?? this.highContrast,
        activeProfileId: activeProfileId ?? this.activeProfileId,
        parentPin: parentPin ?? this.parentPin,
        onboardingDone: onboardingDone ?? this.onboardingDone,
      );
}
