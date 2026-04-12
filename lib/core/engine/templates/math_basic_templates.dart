/// Klassenstufen-übergreifende Mathe-Basistemplates (Kl.1–4).
///
/// Enthält Templates, die durch einen `grade`-Parameter für mehrere Klassen
/// parametrisierbar sind (Addition, Subtraktion), sowie klassenübergreifende
/// Typen (Vergleiche, Einmaleins, Zahlenreihen, Division mit Rest).
import 'dart:math';
import '../../models/task_model.dart';
import '../../models/subject.dart';
import '../task_template.dart';

/// Addition — Kl.1 (bis 10/20) und Kl.2 (bis 100).
///
/// Die Obergrenze skaliert mit [difficulty] (Stufe 1: bis 5, Stufe 5: bis 100).
/// Das Topic-Feld passt sich automatisch an die Klassenstufe an.
class AdditionTemplate extends TaskTemplate {
  const AdditionTemplate({required super.grade})
      : super(
          id: 'addition_g$grade',
          subject: Subject.math,
          topic: grade <= 2 ? 'addition_bis_${grade == 1 ? 10 : 100}' : 'schriftliche_addition',
          minDifficulty: 1,
          maxDifficulty: grade <= 2 ? 3 : 5,
        );

  @override
  String get displayName => 'Addition';

  int _maxNum(int difficulty) => switch (difficulty) {
        1 => 5,
        2 => 10,
        3 => 20,
        4 => 50,
        _ => 100,
      };

  @override
  TaskModel generate(int difficulty, Random rng) {
    final max = _maxNum(difficulty);
    final a = rng.nextInt(max);
    final b = rng.nextInt(max - a);
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$a + $b = ?',
      correctAnswer: a + b,
      type: TaskType.freeInput,
      metadata: {'a': a, 'b': b, 'operator': '+'},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Subtraktion — Kl.1 (bis 10/20) und Kl.2 (bis 100).
/// Ergebnis ist stets ≥ 0 (kein Überschreiten in negative Zahlen).
class SubtractionTemplate extends TaskTemplate {
  const SubtractionTemplate({required super.grade})
      : super(
          id: 'subtraction_g$grade',
          subject: Subject.math,
          topic: grade <= 2 ? 'subtraktion_bis_${grade == 1 ? 10 : 100}' : 'schriftliche_subtraktion',
          minDifficulty: 1,
          maxDifficulty: grade <= 2 ? 3 : 5,
        );

  @override
  String get displayName => 'Subtraktion';

  int _maxNum(int difficulty) => switch (difficulty) {
        1 => 5,
        2 => 10,
        3 => 20,
        4 => 50,
        _ => 100,
      };

  @override
  TaskModel generate(int difficulty, Random rng) {
    final max = _maxNum(difficulty);
    final a = rng.nextInt(max) + 1;
    final b = rng.nextInt(a); // b ≤ a, kein negatives Ergebnis
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$a - $b = ?',
      correctAnswer: a - b,
      type: TaskType.freeInput,
      metadata: {'a': a, 'b': b, 'operator': '-'},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Größer/Kleiner/Gleich — Klasse 1
class ComparisonTemplate extends TaskTemplate {
  const ComparisonTemplate()
      : super(
          id: 'comparison_g1',
          subject: Subject.math,
          grade: 1,
          topic: 'groesser_kleiner',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Größer / Kleiner / Gleich';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final max = difficulty == 1 ? 10 : (difficulty == 2 ? 20 : 100);
    final a = rng.nextInt(max);
    final b = rng.nextInt(max);
    final correct = a > b ? '>' : (a < b ? '<' : '=');
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$a ☐ $b',
      correctAnswer: correct,
      type: TaskType.multipleChoice,
      metadata: {'a': a, 'b': b, 'choices': ['>', '<', '=']},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

/// Einmaleins — Klasse 2
class TimesTableTemplate extends TaskTemplate {
  final int? fixedMultiplier; // null = alle Reihen

  const TimesTableTemplate({this.fixedMultiplier})
      : super(
          id: 'timestable',
          subject: Subject.math,
          grade: 2,
          topic: 'einmaleins',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Einmaleins';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final maxRow = switch (difficulty) { 1 => 5, 2 => 7, 3 => 9, _ => 10 };
    final a = fixedMultiplier ?? (rng.nextInt(maxRow) + 1);
    final b = rng.nextInt(maxRow) + 1;
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$a × $b = ?',
      correctAnswer: a * b,
      type: TaskType.freeInput,
      metadata: {'a': a, 'b': b},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Zahlenreihen fortsetzen — Klasse 1
class NumberSequenceTemplate extends TaskTemplate {
  const NumberSequenceTemplate()
      : super(
          id: 'number_sequence',
          subject: Subject.math,
          grade: 1,
          topic: 'zahlenreihen',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Zahlenreihe fortsetzen';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final steps = [1, 2, 5, 10][rng.nextInt(difficulty == 1 ? 2 : (difficulty == 2 ? 3 : 4))];
    final start = rng.nextInt(20) * steps;
    final count = 4 + rng.nextInt(2);
    final sequence = List.generate(count, (i) => start + i * steps);
    final nextVal = start + count * steps;
    final display = '${sequence.join(', ')}, ?';
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$display',
      correctAnswer: nextVal,
      type: TaskType.freeInput,
      metadata: {'sequence': sequence, 'step': steps},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Division mit Rest — Klasse 3
class DivisionWithRemainderTemplate extends TaskTemplate {
  const DivisionWithRemainderTemplate()
      : super(
          id: 'division_with_remainder',
          subject: Subject.math,
          grade: 3,
          topic: 'division_mit_rest',
          minDifficulty: 2,
          maxDifficulty: 5,
        );

  @override
  String get displayName => 'Division mit Rest';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final maxDivisor = difficulty <= 3 ? 5 : 9;
    final divisor = rng.nextInt(maxDivisor - 1) + 2;
    final quotient = rng.nextInt(difficulty <= 2 ? 5 : 10) + 1;
    final remainder = rng.nextInt(divisor);
    final dividend = divisor * quotient + remainder;
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$dividend ÷ $divisor = ? Rest ?',
      correctAnswer: [quotient, remainder],
      type: TaskType.freeInput,
      metadata: {
        'dividend': dividend,
        'divisor': divisor,
        'quotient': quotient,
        'remainder': remainder,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    if (userAnswer is! List || userAnswer.length < 2) return false;
    final correct = task.correctAnswer as List;
    return int.tryParse(userAnswer[0].toString()) == correct[0] &&
        int.tryParse(userAnswer[1].toString()) == correct[1];
  }
}
