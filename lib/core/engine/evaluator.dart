import '../models/task_model.dart';

/// Zentraler Auswertungsservice für einfache Aufgabentypen.
///
/// Komplexe Typen (interaktive Widgets wie Uhr, Geld, Brüche) implementieren
/// die Auswertung in [TaskTemplate.evaluate] selbst, da sie
/// aufgabenspezifische Toleranzen oder Formatnormalisierungen benötigen.
///
/// [evaluate] ist der zentrale Dispatch-Punkt in [ExerciseScreen._submitAnswer].
class Evaluator {
  /// Wertet eine freie Texteingabe aus.
  ///
  /// Unterstützt exakte Integer- und Double-Vergleiche sowie
  /// case-insensitiven, getrimmten String-Vergleich als Fallback.
  /// Double-Vergleich erlaubt eine Toleranz von ±0.001 (Komma-Unschärfe).
  static bool evaluateFreeInput(TaskModel task, dynamic userAnswer) {
    final correct = task.correctAnswer;
    if (correct is int && userAnswer is int) return correct == userAnswer;
    if (correct is double && userAnswer is double) {
      return (correct - userAnswer).abs() < 0.001;
    }
    return correct.toString().trim().toLowerCase() ==
        userAnswer.toString().trim().toLowerCase();
  }

  /// Wertet eine Multiple-Choice-Auswahl aus.
  ///
  /// Vergleicht [userAnswer] direkt mit [TaskModel.correctAnswer] via `==`.
  /// Für aufgaben mit case-sensitiven Antworten (z.B. Artikel "Der"/"die")
  /// überschreiben Templates [TaskTemplate.evaluate] mit eigener Logik.
  static bool evaluateMultipleChoice(TaskModel task, dynamic userAnswer) {
    return task.correctAnswer == userAnswer;
  }

  /// Wertet eine geordnete Wort-/Buchstaben-Liste aus.
  ///
  /// [userAnswer] muss eine [List] sein. Länge und alle Elemente
  /// müssen exakt (als String) übereinstimmen. Wird für
  /// [TaskType.ordering] (Sätze bilden, Buchstabensalat) genutzt.
  static bool evaluateOrdering(TaskModel task, dynamic userAnswer) {
    if (userAnswer is! List) return false;
    final correct = task.correctAnswer as List;
    if (correct.length != userAnswer.length) return false;
    for (int i = 0; i < correct.length; i++) {
      if (correct[i].toString() != userAnswer[i].toString()) return false;
    }
    return true;
  }

  /// Wertet eine Lückentext-Antwort aus (Liste von Einzelantworten).
  ///
  /// Vergleicht positionsweise, case-insensitiv und getrimmt.
  /// Genutzt für [TaskType.gapFill]-Aufgaben (Phase 4+).
  static bool evaluateGapFill(TaskModel task, dynamic userAnswer) {
    if (userAnswer is! List) return false;
    final correct = task.correctAnswer as List;
    if (correct.length != userAnswer.length) return false;
    for (int i = 0; i < correct.length; i++) {
      if (correct[i].toString().trim().toLowerCase() !=
          userAnswer[i].toString().trim().toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  /// Zentraler Dispatch — wählt den passenden Evaluator anhand von [TaskType].
  ///
  /// Aufgerufen in [ExerciseScreen._submitAnswer]. Nicht aufgeführte Typen
  /// (z.B. `interactive`, `tapRhythm`) fallen auf [evaluateFreeInput] zurück,
  /// da deren Templates [TaskTemplate.evaluate] selbst implementieren.
  static bool evaluate(TaskModel task, dynamic userAnswer) {
    final type = TaskType.values.byName(task.taskType);
    return switch (type) {
      TaskType.freeInput => evaluateFreeInput(task, userAnswer),
      TaskType.multipleChoice => evaluateMultipleChoice(task, userAnswer),
      TaskType.ordering => evaluateOrdering(task, userAnswer),
      TaskType.gapFill => evaluateGapFill(task, userAnswer),
      _ => evaluateFreeInput(task, userAnswer),
    };
  }
}
