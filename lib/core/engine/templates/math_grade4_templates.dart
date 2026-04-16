/// Mathe-Templates Klasse 4.
///
/// Inhalte: Schriftliche Multiplikation/Division, Brüche (ablesen/zuordnen/addieren),
/// Dezimalzahlen, Balkendiagramme (max/summe/differenz), große Zahlen (Runden),
/// mehrschrittige Sachaufgaben.
import 'dart:math';
import '../../models/task_model.dart';
import '../../models/subject.dart';
import '../task_template.dart';

/// Schriftliche Multiplikation (2-stellig × 1-stellig) — Kl.4.
/// Widget: [WrittenCalculationWidget] mit Zeilenweiser Schrittanzeige.
class WrittenMultiplicationTemplate extends TaskTemplate {
  const WrittenMultiplicationTemplate()
      : super(
          id: 'schriftliche_multiplikation',
          subject: Subject.math,
          grade: 4,
          topic: 'schriftliche_multiplikation',
          minDifficulty: 2,
          maxDifficulty: 5,
        );

  @override
  String get displayName => 'Schriftliche Multiplikation';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final int a, b;
    switch (difficulty) {
      case 2:
        a = rng.nextInt(90) + 10;
        b = rng.nextInt(9) + 2;
      case 3:
        a = rng.nextInt(900) + 100;
        b = rng.nextInt(9) + 2;
      case 4:
        a = rng.nextInt(90) + 10;
        b = rng.nextInt(90) + 10;
      default:
        a = rng.nextInt(900) + 100;
        b = rng.nextInt(90) + 10;
    }
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$a × $b = ?',
      correctAnswer: a * b,
      type: TaskType.freeInput,
      metadata: {'a': a, 'b': b, 'op': '×', 'showSteps': true},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Schriftliche Division — Kl.4
class WrittenDivisionTemplate extends TaskTemplate {
  const WrittenDivisionTemplate()
      : super(
          id: 'schriftliche_division',
          subject: Subject.math,
          grade: 4,
          topic: 'schriftliche_division',
          minDifficulty: 2,
          maxDifficulty: 5,
        );

  @override
  String get displayName => 'Schriftliche Division';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final maxQuotient = switch (difficulty) { 2 => 20, 3 => 50, 4 => 100, _ => 200 };
    final maxDivisor = difficulty <= 3 ? 9 : 99;
    final divisor = rng.nextInt(maxDivisor - 1) + 2;
    final quotient = rng.nextInt(maxQuotient) + 1;
    final dividend = divisor * quotient;
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$dividend ÷ $divisor = ?',
      correctAnswer: quotient,
      type: TaskType.freeInput,
      metadata: {'dividend': dividend, 'divisor': divisor, 'quotient': quotient},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Brüche — Kl.4
class FractionTemplate extends TaskTemplate {
  const FractionTemplate()
      : super(
          id: 'brueche',
          subject: Subject.math,
          grade: 4,
          topic: 'brueche',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Brüche';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final maxDenom = switch (difficulty) { 1 => 4, 2 => 6, 3 => 8, _ => 12 };
    final denominator = rng.nextInt(maxDenom - 1) + 2;
    final taskType = rng.nextInt(3);

    switch (taskType) {
      case 0: // Nenner ablesen
        final numerator = rng.nextInt(denominator - 1) + 1;
        return makeTask(
          rng: rng,
          difficulty: difficulty,
          question: 'Der Bruch zeigt $numerator/$denominator.\nWie viele Teile sind markiert?',
          correctAnswer: numerator,
          type: TaskType.interactive,
          metadata: {
            'type': 'read',
            'numerator': numerator,
            'denominator': denominator,
          },
        );
      case 1: // Brüche addieren (gleicher Nenner)
        final a = rng.nextInt(denominator ~/ 2) + 1;
        final b = rng.nextInt(denominator - a) + 1;
        final sum = a + b;
        final display = sum >= denominator
            ? '${sum ~/ denominator} ${sum % denominator}/$denominator'
            : '$sum/$denominator';
        return makeTask(
          rng: rng,
          difficulty: difficulty,
          question: '$a/$denominator + $b/$denominator = ?/$denominator',
          correctAnswer: sum % denominator == 0 ? sum ~/ denominator : sum,
          type: TaskType.freeInput,
          metadata: {
            'type': 'add',
            'a': a, 'b': b,
            'denominator': denominator,
            'resultNumerator': sum,
          },
        );
      default: // Bruch erkennen (visuell)
        final numerator = rng.nextInt(denominator - 1) + 1;
        return makeTask(
          rng: rng,
          difficulty: difficulty,
          question: 'Welcher Bruch ist hier dargestellt?',
          correctAnswer: '$numerator/$denominator',
          type: TaskType.interactive,
          metadata: {
            'type': 'identify',
            'numerator': numerator,
            'denominator': denominator,
            'choices': [
              '$numerator/$denominator',
              '${numerator + 1}/$denominator',
              '${(numerator - 1).clamp(1, denominator - 1)}/$denominator',
            ]..shuffle(rng),
          },
        );
    }
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final correct = task.correctAnswer.toString();
    final answer = userAnswer.toString().trim();
    if (correct == answer) return true;
    // Numerischer Vergleich für einfache Fälle
    final correctNum = int.tryParse(correct);
    final answerNum = int.tryParse(answer);
    return correctNum != null && answerNum != null && correctNum == answerNum;
  }
}

/// Dezimalzahlen — Kl.4
class DecimalNumberTemplate extends TaskTemplate {
  const DecimalNumberTemplate()
      : super(
          id: 'dezimalzahlen',
          subject: Subject.math,
          grade: 4,
          topic: 'dezimalzahlen',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Dezimalzahlen';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final taskType = rng.nextInt(3);

    switch (taskType) {
      case 0: // Dezimalzahl einordnen
        final whole = rng.nextInt(10);
        final decimal = rng.nextInt(9) + 1;
        final value = whole + decimal / 10;
        return makeTask(
          rng: rng,
          difficulty: difficulty,
          question: 'Welche Dezimalzahl siehst du am Zahlenstrahl?',
          correctAnswer: value,
          type: TaskType.interactive,
          metadata: {
            'type': 'read',
            'value': value,
            'min': whole.toDouble(),
            'max': (whole + 1).toDouble(),
          },
        );
      case 1: // Dezimalzahl vergleichen
        final a = (rng.nextInt(50) + 1) / 10;
        final b = (rng.nextInt(50) + 1) / 10;
        final correct = a > b ? '>' : (a < b ? '<' : '=');
        return makeTask(
          rng: rng,
          difficulty: difficulty,
          question: '$a ☐ $b',
          correctAnswer: correct,
          type: TaskType.multipleChoice,
          metadata: {'a': a, 'b': b, 'choices': ['>', '<', '=']},
        );
      default: // Dezimalzahl addieren
        final a = (rng.nextInt(20) + 1) / 10;
        final b = (rng.nextInt(20) + 1) / 10;
        final result = ((a + b) * 10).round() / 10;
        return makeTask(
          rng: rng,
          difficulty: difficulty,
          question: '$a + $b = ?',
          correctAnswer: result.toString(),
          type: TaskType.freeInput,
          metadata: {'a': a, 'b': b},
        );
    }
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final correct = task.correctAnswer.toString();
    final answer = userAnswer.toString().trim().replaceAll(',', '.');
    if (correct == answer) return true;
    final correctD = double.tryParse(correct);
    final answerD = double.tryParse(answer);
    return correctD != null && answerD != null &&
        (correctD - answerD).abs() < 0.01;
  }
}

/// Diagramme lesen — Kl.4
class DiagramReadingTemplate extends TaskTemplate {
  const DiagramReadingTemplate()
      : super(
          id: 'diagramme',
          subject: Subject.math,
          grade: 4,
          topic: 'diagramme',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Diagramme lesen';

  static const _scenarios = [
    ('Lieblingssportarten in Klasse 4', ['Fußball', 'Schwimmen', 'Tennis', 'Turnen']),
    ('Lieblingstiere', ['Hund', 'Katze', 'Pferd', 'Vogel']),
    ('Verkehrsmittel', ['Bus', 'Auto', 'Fahrrad', 'Bahn']),
    ('Wochentage (Schönwetter)', ['Mo', 'Di', 'Mi', 'Do', 'Fr']),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final scenario = _scenarios[rng.nextInt(_scenarios.length)];
    final (title, categories) = scenario;

    // Zufällige Werte generieren
    final values = List.generate(
      categories.length,
      (_) => rng.nextInt(difficulty <= 2 ? 15 : 30) + 1,
    );

    // Zufällige Frage
    final qType = rng.nextInt(3);
    final int correctAnswer;
    final String question;

    switch (qType) {
      case 0: // Maximalwert
        correctAnswer = values.reduce((a, b) => a > b ? a : b);
        final maxIdx = values.indexOf(correctAnswer);
        question = 'Welche Kategorie hat den höchsten Wert?\nAntwort: Wie viele?';
        // Eigentlich: Kategorie-Auswahl oder Zahl
        return makeTask(
          rng: rng,
          difficulty: difficulty,
          question: '$title\nWelche Kategorie hat den größten Wert?',
          correctAnswer: categories[maxIdx],
          type: TaskType.multipleChoice,
          metadata: {
            'title': title,
            'categories': categories,
            'values': values,
            'choices': List<String>.from(categories)..shuffle(rng),
            'qType': 'max',
          },
        );
      case 1: // Summe
        correctAnswer = values.reduce((a, b) => a + b);
        return makeTask(
          rng: rng,
          difficulty: difficulty,
          question: '$title\nWie viele Nennungen gibt es insgesamt?',
          correctAnswer: correctAnswer,
          type: TaskType.freeInput,
          metadata: {
            'title': title,
            'categories': categories,
            'values': values,
            'qType': 'sum',
          },
        );
      default: // Differenz
        final maxVal = values.reduce((a, b) => a > b ? a : b);
        final minVal = values.reduce((a, b) => a < b ? a : b);
        correctAnswer = maxVal - minVal;
        return makeTask(
          rng: rng,
          difficulty: difficulty,
          question: '$title\nUm wie viel ist der größte Wert\ngrößer als der kleinste?',
          correctAnswer: correctAnswer,
          type: TaskType.freeInput,
          metadata: {
            'title': title,
            'categories': categories,
            'values': values,
            'qType': 'diff',
          },
        );
    }
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final correct = task.correctAnswer;
    if (correct is int) {
      final answer = int.tryParse(userAnswer.toString());
      return answer != null && answer == correct;
    }
    return correct.toString() == userAnswer.toString();
  }
}

/// Große Zahlen & Runden — Kl.4
class LargeNumbersTemplate extends TaskTemplate {
  const LargeNumbersTemplate()
      : super(
          id: 'grosse_zahlen',
          subject: Subject.math,
          grade: 4,
          topic: 'grosse_zahlen',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Große Zahlen & Runden';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final taskType = rng.nextInt(2);

    if (taskType == 0) {
      // Runden auf Zehner/Hunderter/Tausender
      final roundTo = switch (difficulty) { 1 => 10, 2 => 100, 3 => 1000, _ => 10000 };
      final maxNum = roundTo * (difficulty <= 2 ? 20 : 100);
      final num = rng.nextInt(maxNum) + 1;
      final rounded = ((num + roundTo ~/ 2) ~/ roundTo) * roundTo;

      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Runde $num auf die nächste ${_roundLabel(roundTo)}.',
        correctAnswer: rounded,
        type: TaskType.freeInput,
        metadata: {'number': num, 'roundTo': roundTo},
      );
    } else {
      // Stellenwerte bestimmen
      final digits = difficulty <= 2 ? 4 : 6;
      final maxVal = pow(10, digits).toInt();
      final num = rng.nextInt(maxVal - 1) + 1;
      final placeValues = ['Einer', 'Zehner', 'Hunderter', 'Tausender', 'Zehntausender', 'Hunderttausender'];
      final place = rng.nextInt(digits.clamp(1, 6));
      final digit = (num ~/ pow(10, place).toInt()) % 10;

      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Welche Ziffer steht bei $num an der ${placeValues[place]}-Stelle?',
        correctAnswer: digit,
        type: TaskType.freeInput,
        metadata: {'number': num, 'place': place},
      );
    }
  }

  String _roundLabel(int roundTo) => switch (roundTo) {
        10 => 'Zehnerstelle',
        100 => 'Hunderterstelle',
        1000 => 'Tausenderstelle',
        _ => '${roundTo}er-Stelle',
      };

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Sachaufgaben Kl.4
class WordProblemGrade4Template extends TaskTemplate {
  const WordProblemGrade4Template()
      : super(
          id: 'sachaufgaben_4',
          subject: Subject.math,
          grade: 4,
          topic: 'sachaufgaben_4',
          minDifficulty: 3,
          maxDifficulty: 5,
        );

  @override
  String get displayName => 'Sachaufgabe';

  static const _templates = [
    (
      text: 'Ein Reisebus hat {seats} Sitze. Bei der Abfahrt sind {occupied} Sitze besetzt. An der nächsten Station steigen {more} Personen zu. Wie viele Sitze sind jetzt noch frei?',
      vars: ['seats', 'occupied', 'more'],
      solve: 'seats - occupied - more',
    ),
    (
      text: 'Eine Bäckerei bäckt täglich {loaves} Brote. Am Montag werden {sold} Brote verkauft. Am Dienstag werden doppelt so viele verkauft. Wie viele Brote sind nach Dienstag noch übrig?',
      vars: ['loaves', 'sold'],
      solve: 'loaves - sold - 2*sold',
    ),
    (
      text: 'Eine Schule hat {classes} Klassen mit je {students} Schülern. Davon nehmen {sport} Schüler am Sport-AG teil. Wie viele Schüler machen kein Sport-AG?',
      vars: ['classes', 'students', 'sport'],
      solve: 'classes*students - sport',
    ),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final tmpl = _templates[rng.nextInt(_templates.length)];

    // Einfache Zufallswerte für alle Templates
    final seats = (rng.nextInt(20) + 3) * 5; // Vielfache von 5
    final occupied = rng.nextInt(seats ~/ 2) + 5;
    final more = rng.nextInt(seats - occupied) + 1;
    final loaves = (rng.nextInt(10) + 5) * 10;
    final sold = rng.nextInt(loaves ~/ 4) + 5;
    final classes = rng.nextInt(8) + 2;
    final students = rng.nextInt(10) + 15;
    final sport = rng.nextInt((classes * students) ~/ 3) + 5;

    final vals = {
      'seats': seats, 'occupied': occupied, 'more': more,
      'loaves': loaves, 'sold': sold,
      'classes': classes, 'students': students, 'sport': sport,
    };

    // Ergebnis berechnen (vereinfacht: je nach Template-Index)
    int result;
    final templateIdx = _templates.indexOf(tmpl);
    switch (templateIdx) {
      case 0:
        result = seats - occupied - more;
      case 1:
        result = loaves - sold - 2 * sold;
      default:
        result = classes * students - sport;
    }

    if (result < 0) result = result.abs(); // Sicherheitsnetz

    String question = tmpl.text;
    vals.forEach((key, val) {
      question = question.replaceAll('{$key}', val.toString());
    });

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: question,
      correctAnswer: result,
      type: TaskType.freeInput,
      metadata: vals.map((k, v) => MapEntry(k, v)),
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}
