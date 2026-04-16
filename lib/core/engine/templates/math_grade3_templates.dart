/// Mathe-Templates Klasse 3.
///
/// Inhalte: Schriftliche Addition/Subtraktion (mit Übertrag), halbschriftliche
/// Multiplikation, Division mit Rest, Größen umrechnen (8 Einheiten),
/// Geometrie (Umfang/Fläche Quadrat+Rechteck), Textaufgaben.
import 'dart:math';
import '../../models/task_model.dart';
import '../../models/subject.dart';
import '../task_template.dart';

/// Schriftliche Addition mit Übertrag — Kl.3.
///
/// Erzeugt zwei 3–4-stellige Summanden; die Schrittanzeige
/// ([metadata]`['showSteps']` = true) triggert das [WrittenCalculationWidget].
class WrittenAdditionTemplate extends TaskTemplate {
  const WrittenAdditionTemplate()
      : super(
          id: 'written_addition',
          subject: Subject.math,
          grade: 3,
          topic: 'schriftliche_addition',
          minDifficulty: 2,
          maxDifficulty: 5,
        );

  @override
  String get displayName => 'Schriftliche Addition';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final digits = difficulty <= 3 ? 3 : 4;
    final max = (10 as int) * digits == 3 ? 999 : 9999;
    // Korrekte Berechnung: max basierend auf digits
    final maxVal = digits == 3 ? 999 : 9999;
    final a = rng.nextInt(maxVal ~/ 2) + maxVal ~/ 4;
    final b = rng.nextInt(maxVal - a) + 1;
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$a + $b = ?',
      correctAnswer: a + b,
      type: TaskType.freeInput,
      metadata: {
        'a': a, 'b': b, 'op': '+',
        'digits': digits, 'showSteps': true,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Schriftliche Subtraktion — Kl.3
class WrittenSubtractionTemplate extends TaskTemplate {
  const WrittenSubtractionTemplate()
      : super(
          id: 'written_subtraction',
          subject: Subject.math,
          grade: 3,
          topic: 'schriftliche_subtraktion',
          minDifficulty: 2,
          maxDifficulty: 5,
        );

  @override
  String get displayName => 'Schriftliche Subtraktion';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final maxVal = difficulty <= 3 ? 999 : 9999;
    final a = rng.nextInt(maxVal ~/ 2) + maxVal ~/ 2;
    final b = rng.nextInt(a) + 1;
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$a - $b = ?',
      correctAnswer: a - b,
      type: TaskType.freeInput,
      metadata: {
        'a': a, 'b': b, 'op': '-',
        'showSteps': true,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Halbschriftliche Multiplikation — Kl.3
class SemiWrittenMultiplicationTemplate extends TaskTemplate {
  const SemiWrittenMultiplicationTemplate()
      : super(
          id: 'multiplikation',
          subject: Subject.math,
          grade: 3,
          topic: 'multiplikation',
          minDifficulty: 2,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Multiplikation';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final int a, b;
    switch (difficulty) {
      case 2:
        a = rng.nextInt(9) + 2;
        b = rng.nextInt(10) + 1;
      case 3:
        a = rng.nextInt(9) + 2;
        b = rng.nextInt(20) + 10;
      default:
        a = rng.nextInt(9) + 2;
        b = rng.nextInt(90) + 10;
    }
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

/// Größen umrechnen — Kl.3
class UnitConversionTemplate extends TaskTemplate {
  const UnitConversionTemplate()
      : super(
          id: 'groessen_umrechnen',
          subject: Subject.math,
          grade: 3,
          topic: 'groessen_umrechnen',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Größen umrechnen';

  static const _conversions = [
    // (from, to, factor, category)
    ('km', 'm', 1000, 'Länge'),
    ('m', 'cm', 100, 'Länge'),
    ('cm', 'mm', 10, 'Länge'),
    ('kg', 'g', 1000, 'Gewicht'),
    ('t', 'kg', 1000, 'Gewicht'),
    ('h', 'min', 60, 'Zeit'),
    ('min', 's', 60, 'Zeit'),
    ('l', 'ml', 1000, 'Volumen'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final conv = _conversions[rng.nextInt(_conversions.length)];
    final (from, to, factor, category) = conv;

    // Richtung: vorwärts (×factor) oder rückwärts (÷factor)
    final forward = difficulty <= 2 ? true : rng.nextBool();

    final int value, result;
    if (forward) {
      value = rng.nextInt(difficulty <= 2 ? 10 : 50) + 1;
      result = value * factor;
    } else {
      result = rng.nextInt(difficulty <= 3 ? 10 : 50) + 1;
      value = result * factor;
    }

    final question = forward
        ? '$value $from = ? $to'
        : '$value $from = ? $to';
    final displayQuestion = forward
        ? '$value $from = _____ $to'
        : '$value $from = _____ $to';

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: forward ? '$value $from = _____ $to' : '$value $from = _____ $to',
      correctAnswer: forward ? result : result,
      type: TaskType.freeInput,
      metadata: {
        'from': from, 'to': to, 'factor': factor,
        'category': category, 'forward': forward,
        'inputValue': value,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Geometrie: Umfang und Fläche — Kl.3
class GeometryTemplate extends TaskTemplate {
  const GeometryTemplate()
      : super(
          id: 'geometrie',
          subject: Subject.math,
          grade: 3,
          topic: 'geometrie',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Umfang & Fläche';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final maxSide = difficulty <= 2 ? 10 : 20;
    // Aufgabenart: Rechteck oder Quadrat
    final isSquare = difficulty == 1 ? true : rng.nextBool();
    final askPerimeter = rng.nextBool();

    if (isSquare) {
      final side = rng.nextInt(maxSide) + 1;
      final perimeter = 4 * side;
      final area = side * side;
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: askPerimeter
            ? 'Quadrat mit Seite $side cm.\nWie groß ist der Umfang?'
            : 'Quadrat mit Seite $side cm.\nWie groß ist die Fläche?',
        correctAnswer: askPerimeter ? perimeter : area,
        type: TaskType.freeInput,
        metadata: {
          'shape': 'square', 'side': side,
          'perimeter': perimeter, 'area': area,
          'askPerimeter': askPerimeter,
          'unit': askPerimeter ? 'cm' : 'cm²',
        },
      );
    } else {
      final w = rng.nextInt(maxSide) + 1;
      final h = rng.nextInt(maxSide) + 1;
      final perimeter = 2 * (w + h);
      final area = w * h;
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: askPerimeter
            ? 'Rechteck: $w cm × $h cm.\nWie groß ist der Umfang?'
            : 'Rechteck: $w cm × $h cm.\nWie groß ist die Fläche?',
        correctAnswer: askPerimeter ? perimeter : area,
        type: TaskType.freeInput,
        metadata: {
          'shape': 'rectangle', 'width': w, 'height': h,
          'perimeter': perimeter, 'area': area,
          'askPerimeter': askPerimeter,
          'unit': askPerimeter ? 'cm' : 'cm²',
        },
      );
    }
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Textaufgaben Kl.3
class WordProblemGrade3Template extends TaskTemplate {
  const WordProblemGrade3Template()
      : super(
          id: 'textaufgaben_3',
          subject: Subject.math,
          grade: 3,
          topic: 'textaufgaben_3',
          minDifficulty: 2,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Textaufgabe';

  static const _contexts = [
    (
      template: 'Ein Zug fährt {a} km pro Stunde. Wie weit fährt er in {b} Stunden?',
      op: '*',
    ),
    (
      template: '{a} Kinder teilen sich {b} Bonbons gleichmäßig auf. Wie viele Bonbons bekommt jedes Kind?',
      op: '/',
    ),
    (
      template: 'Eine Schachtel Pralinen kostet {a} €. Wie viel kosten {b} Schachteln?',
      op: '*',
    ),
    (
      template: '{a} Bücher werden gleichmäßig auf {b} Regale verteilt. Wie viele Bücher kommen in jedes Regal?',
      op: '/',
    ),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final ctx = _contexts[rng.nextInt(_contexts.length)];
    final int a, b, result;

    if (ctx.op == '*') {
      a = rng.nextInt(difficulty <= 2 ? 10 : 50) + 2;
      b = rng.nextInt(9) + 2;
      result = a * b;
    } else {
      b = rng.nextInt(8) + 2; // Divisor
      result = rng.nextInt(difficulty <= 2 ? 10 : 20) + 1;
      a = b * result; // Kein Rest
    }

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: ctx.template
          .replaceAll('{a}', a.toString())
          .replaceAll('{b}', b.toString()),
      correctAnswer: result,
      type: TaskType.freeInput,
      metadata: {'a': a, 'b': b, 'op': ctx.op},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}
