/// Adaptiver Schwierigkeitsregler für Lerneinheiten.
///
/// Analysiert die letzten Ergebnisse eines Kindes und passt den
/// Schwierigkeitsgrad dynamisch an — Ziel ist eine Trefferquote
/// zwischen 50 % und 90 % ("Zone der proximalen Entwicklung").
///
/// ### Algorithmus
/// Fenster: letzte 5 Ergebnisse (Gewichtung: neuere stärker relevant).
/// - Trefferquote ≥ 90 % → Stufe um 1 erhöhen (Kind ist unterfordert)
/// - Trefferquote < 50 % → Stufe um 1 verringern (Kind ist überfordert)
/// - Sonst → Stufe beibehalten
///
/// Grenzen: immer zwischen [_minDifficulty] und [_maxDifficulty] (1–5).
class DifficultyEngine {
  static const int _minDifficulty = 1;
  static const int _maxDifficulty = 5;

  /// Berechnet den Schwierigkeitsgrad für die nächste Aufgabe.
  ///
  /// [recentResults] enthält `1` für richtig und `0` für falsch.
  /// Es werden nur die letzten 5 Einträge berücksichtigt.
  /// Gibt [currentDifficulty] unverändert zurück, wenn die Liste leer ist.
  static int nextDifficulty({
    required List<int> recentResults,
    required int currentDifficulty,
  }) {
    if (recentResults.isEmpty) return currentDifficulty;

    final recent = recentResults.length > 5
        ? recentResults.sublist(recentResults.length - 5)
        : recentResults;

    final correctRate = recent.reduce((a, b) => a + b) / recent.length;

    if (correctRate >= 0.9 && currentDifficulty < _maxDifficulty) {
      return currentDifficulty + 1;
    } else if (correctRate < 0.5 && currentDifficulty > _minDifficulty) {
      return currentDifficulty - 1;
    }

    return currentDifficulty;
  }

  /// Berechnet den Einstiegs-Schwierigkeitsgrad beim Session-Start.
  ///
  /// Basiert auf der historischen Trefferquote [accuracy] (0.0–1.0) aus
  /// [TopicProgress.accuracy] und der [grade] des Kindes.
  /// Ein Kind ohne Vorgeschichte ([accuracy] == 0) startet auf Stufe
  /// `grade - 1` — also etwas unter dem Maximum für die Klasse.
  static int initialDifficulty(double accuracy, int grade) {
    if (accuracy == 0) return (grade - 1).clamp(1, 3);
    if (accuracy > 0.9) return _maxDifficulty.clamp(1, 5);
    if (accuracy > 0.7) return 3;
    if (accuracy > 0.5) return 2;
    return 1;
  }
}
