import 'dart:math' as math;

/// Engagement-orientierte Dynamische Schwierigkeitsanpassung (EDDA).
/// 
/// Überwacht die Interaktionsqualität des Kindes in Echtzeit.
class EddaEngine {
  /// Schwellenwert für Frustrationsgefahr (Engagement-Score 0.0 bis 1.0).
  static const double frustrationThreshold = 0.35;

  /// Dauer der "Sleep Phase" (in Sekunden), in der das System nicht eingreift.
  static const int sleepPhaseDuration = 15;

  /// Berechnet den Engagement-Score basierend auf Latenz und Fehlern.
  /// 
  /// [idleTimeSeconds] Zeit seit der letzten sinnvollen Interaktion.
  /// [errorCount] Anzahl der Fehlversuche bei der aktuellen Aufgabe.
  /// [taskComplexity] Schwierigkeitsgrad der aktuellen Aufgabe (1-5).
  static double calculateEngagementScore({
    required int idleTimeSeconds,
    required int errorCount,
    required int taskComplexity,
  }) {
    // Grundwert 1.0 (volles Engagement)
    double score = 1.0;

    // Abzug für Inaktivität (stärker gewichtet nach der Sleep Phase)
    if (idleTimeSeconds > sleepPhaseDuration) {
      final excessiveIdle = idleTimeSeconds - sleepPhaseDuration;
      score -= (excessiveIdle * 0.05); // -5% pro Sekunde Überzug
    }

    // Abzug für Fehler (skaliert mit Komplexität)
    // Bei hoher Komplexität wiegen Fehler schwerer für den Frustrations-Score
    score -= (errorCount * 0.1 * (taskComplexity / 3.0));

    return math.max(0.0, score);
  }

  /// Prüft, ob eine Intervention (Concealment) nötig ist.
  static bool needsIntervention(double score) {
    return score < frustrationThreshold;
  }
}

/// Zustand des aktuellen Engagements in einer Sitzung.
class EngagementState {
  final double score;
  final bool isInSleepPhase;
  final bool interventionTriggered;

  const EngagementState({
    this.score = 1.0,
    this.isInSleepPhase = true,
    this.interventionTriggered = false,
  });

  EngagementState copyWith({
    double? score,
    bool? isInSleepPhase,
    bool? interventionTriggered,
  }) {
    return EngagementState(
      score: score ?? this.score,
      isInSleepPhase: isInSleepPhase ?? this.isInSleepPhase,
      interventionTriggered: interventionTriggered ?? this.interventionTriggered,
    );
  }
}
