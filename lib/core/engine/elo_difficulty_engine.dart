import 'dart:math' as math;

/// Elo-basiertes Bewertungssystem für den Lernerfolg.
///
/// Im Gegensatz zur klassischen [DifficultyEngine] betrachtet dieses System
/// den Lernenden und die Aufgabe als Kontrahenten.
///
/// - Ein Erfolg gegen eine schwere Aufgabe bringt viele Punkte.
/// - Ein Misserfolg gegen eine leichte Aufgabe kostet viele Punkte.
class EloDifficultyEngine {
  /// Start-Elo für neue Themen/Nutzer.
  static const double defaultRating = 1000.0;

  /// K-Faktor bestimmt, wie schnell sich das Rating anpasst.
  /// Ein höherer Wert (z.B. 32) sorgt für schnellere Sprünge bei Kindern.
  static const int kFactor = 32;

  /// Mapping von statischen Schwierigkeitsstufen (1-5) auf Elo-Werte.
  static double eloForDifficulty(int difficulty) {
    return switch (difficulty) {
      1 => 800.0,
      2 => 1000.0,
      3 => 1200.0,
      4 => 1400.0,
      5 => 1600.0,
      _ => 1000.0,
    };
  }

  /// Berechnet das neue Rating nach einem Versuch.
  ///
  /// [currentRating] das aktuelle Elo-Rating des Kindes.
  /// [taskDifficulty] die Stufe (1-5) der absolvierten Aufgabe.
  /// [success] true wenn die Aufgabe korrekt gelöst wurde.
  static double calculateNewRating({
    required double currentRating,
    required int taskDifficulty,
    required bool success,
  }) {
    final opponentRating = eloForDifficulty(taskDifficulty);

    // Erwarteter Score (0.0 bis 1.0)
    final expectedScore =
        1.0 / (1.0 + math.pow(10, (opponentRating - currentRating) / 400.0));

    // Tatsächlicher Score
    final actualScore = success ? 1.0 : 0.0;

    // Neues Rating: R' = R + K * (S - E)
    return currentRating + kFactor * (actualScore - expectedScore);
  }

  /// Bestimmt die ideale Schwierigkeitsstufe für das nächste Match.
  ///
  /// Versucht eine Stufe zu finden, bei der die Gewinnchance nah bei 75% liegt
  /// (Zone der proximalen Entwicklung).
  static int recommendDifficulty(double currentRating) {
    if (currentRating < 900) return 1;
    if (currentRating < 1100) return 2;
    if (currentRating < 1300) return 3;
    if (currentRating < 1500) return 4;
    return 5;
  }
}
