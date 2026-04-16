/// Mathe-Templates Klasse 2 sowie einzelne geteilte Vertiefungsformate.
///
/// Inhalte: Uhrzeit (analog, 4 Schwierigkeitsstufen), Geld (Münzen in Cent),
/// Zahlenmauern (Kl.1/2), Rechenketten, Textaufgaben.
import 'dart:math';
import '../../models/task_model.dart';
import '../../models/subject.dart';
import '../task_template.dart';

/// Analoge Uhr ablesen / einstellen — Kl.2.
///
/// 4 Schwierigkeitsstufen: volle Stunden → halbe → viertel → 5-Minuten-Schritte.
/// Widget: [ClockWidget] mit CustomPaint-Uhr.
/// Antwortformat: `"HH:MM"` (z.B. `"08:30"`).
class ClockTemplate extends TaskTemplate {
  const ClockTemplate()
      : super(
          id: 'uhrzeit',
          subject: Subject.math,
          grade: 2,
          topic: 'uhrzeit',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Uhrzeit ablesen';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final int hour;
    final int minute;

    switch (difficulty) {
      case 1:
        hour = rng.nextInt(12) + 1;
        minute = 0; // Nur volle Stunden
      case 2:
        hour = rng.nextInt(12) + 1;
        minute = [0, 30][rng.nextInt(2)]; // Halb
      case 3:
        hour = rng.nextInt(12) + 1;
        minute = [0, 15, 30, 45][rng.nextInt(4)]; // Viertelstunden
      default:
        hour = rng.nextInt(12) + 1;
        minute = rng.nextInt(12) * 5; // 5-Minuten-Schritte
    }

    final hourStr = hour.toString().padLeft(2, '0');
    final minStr = minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

    // Aufgabenart abwechseln: Uhr ablesen oder Zeit einstellen
    final readClock = rng.nextBool();

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: readClock
          ? 'Welche Uhrzeit zeigt die Uhr?'
          : 'Stelle die Uhr auf $timeStr Uhr.',
      correctAnswer: timeStr,
      type: readClock ? TaskType.freeInput : TaskType.interactive,
      metadata: {
        'hour': hour,
        'minute': minute,
        'timeString': timeStr,
        'readClock': readClock,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final correct = task.correctAnswer.toString();
    final answer = userAnswer.toString().trim();
    // Akzeptiere "8:00", "08:00", "8:0", "8 Uhr"
    final normalizedAnswer = answer
        .replaceAll(' Uhr', '')
        .replaceAll(' uhr', '')
        .trim();
    final parts = normalizedAnswer.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    final correctParts = correct.split(':');
    return h == int.parse(correctParts[0]) && m == int.parse(correctParts[1]);
  }
}

/// Geld zählen — Kl.2
class MoneyTemplate extends TaskTemplate {
  const MoneyTemplate()
      : super(
          id: 'geld',
          subject: Subject.math,
          grade: 2,
          topic: 'geld',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Geld zählen';

  // Münzen in Cent
  static const _coins = [1, 2, 5, 10, 20, 50, 100, 200]; // Cent

  @override
  TaskModel generate(int difficulty, Random rng) {
    final maxCoins = difficulty <= 2 ? 4 : 6;
    final maxValue = switch (difficulty) {
      1 => 50,  // bis 50 Cent
      2 => 100, // bis 1 Euro
      3 => 200, // bis 2 Euro
      _ => 500, // bis 5 Euro
    };

    final availableCoins = difficulty <= 2
        ? _coins.sublist(0, 5) // nur 1c, 2c, 5c, 10c, 20c
        : _coins;

    final List<int> chosenCoins = [];
    int total = 0;
    for (int i = 0; i < maxCoins; i++) {
      final coin = availableCoins[rng.nextInt(availableCoins.length)];
      if (total + coin <= maxValue) {
        chosenCoins.add(coin);
        total += coin;
      }
    }
    if (chosenCoins.isEmpty) {
      chosenCoins.add(10);
      total = 10;
    }

    final euros = total ~/ 100;
    final cents = total % 100;
    final displayAnswer = euros > 0
        ? '${euros.toString()},${cents.toString().padLeft(2, '0')} €'
        : '${cents} Cent';

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Wie viel Geld ist das?',
      correctAnswer: total, // in Cent
      type: TaskType.interactive,
      metadata: {
        'coins': chosenCoins,
        'totalCent': total,
        'displayAnswer': displayAnswer,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final correct = task.correctAnswer as int;
    if (userAnswer is int) return userAnswer == correct;
    final parsed = int.tryParse(userAnswer.toString());
    return parsed != null && parsed == correct;
  }
}

/// Zahlenmauern — Kl.1/2
/// In einer Zahlenmauer ist jede Zahl die Summe der beiden darunter.
class NumberWallTemplate extends TaskTemplate {
  const NumberWallTemplate({int grade = 2})
      : super(
          id: 'zahlenmauern',
          subject: Subject.math,
          grade: grade,
          topic: 'zahlenmauern',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Zahlenmauer';

  @override
  TaskModel generate(int difficulty, Random rng) {
    // 3-stöckige Mauer: 4 Basissteine → 3 → 2 → 1 Stein
    // Basis: a, b, c, d
    // Reihe 2: a+b, b+c, c+d
    // Reihe 3: a+b+b+c, b+c+c+d = (a+2b+c), (b+2c+d)
    // Spitze: a+2b+2c+b+2c+d = a+3b+3c+d (Passt für 4 Steine)
    final max = switch (difficulty) { 1 => 5, 2 => 10, 3 => 15, _ => 20 };
    final a = rng.nextInt(max) + 1;
    final b = rng.nextInt(max) + 1;
    final c = rng.nextInt(max) + 1;

    // 3-stöckig: Basis a, b, c → Mitte: a+b, b+c → Spitze: a+2b+c
    final mid1 = a + b;
    final mid2 = b + c;
    final top = mid1 + mid2;

    // Eine zufällige Zelle verstecken (außer der Spitze immer sichtbar)
    final hiddenSlot = rng.nextInt(5); // 0=a, 1=b, 2=c, 3=mid1, 4=mid2

    final cells = [a, b, c, mid1, mid2, top];
    final labels = ['a', 'b', 'c', 'mid1', 'mid2', 'top'];
    final hidden = labels[hiddenSlot];
    final correctAnswer = cells[hiddenSlot];

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Welche Zahl fehlt in der Zahlenmauer?',
      correctAnswer: correctAnswer,
      type: TaskType.freeInput,
      metadata: {
        'a': a, 'b': b, 'c': c,
        'mid1': mid1, 'mid2': mid2, 'top': top,
        'hidden': hidden,
        'rows': 3,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Rechenketten — Kl.2
class CalculationChainTemplate extends TaskTemplate {
  const CalculationChainTemplate()
      : super(
          id: 'rechenketten',
          subject: Subject.math,
          grade: 2,
          topic: 'rechenketten',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Rechenkette';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final maxNum = switch (difficulty) { 1 => 10, 2 => 20, 3 => 50, _ => 100 };
    final steps = difficulty <= 2 ? 2 : 3;

    final ops = ['+', '-'];
    int current = rng.nextInt(maxNum ~/ 2) + 1;
    final start = current;
    final chain = <Map<String, dynamic>>[];

    for (int i = 0; i < steps; i++) {
      String op = ops[rng.nextInt(ops.length)];
      // Subtraktion nur erlauben wenn current >= 2
      if (op == '-' && current <= 1) op = '+';
      int operand;
      if (op == '+') {
        final maxAdd = (maxNum - current).clamp(1, maxNum);
        operand = rng.nextInt(maxAdd) + 1;
        current += operand;
      } else {
        operand = rng.nextInt(current) + 1; // current >= 2 garantiert
        current -= operand;
      }
      chain.add({'op': op, 'operand': operand, 'result': current});
    }

    // Zufälligen Zwischenschritt verstecken
    final hideStep = rng.nextInt(steps);
    final correctAnswer = chain[hideStep]['result'] as int;

    final questionParts = <String>['$start'];
    for (int i = 0; i < steps; i++) {
      final step = chain[i];
      questionParts.add('${step['op']}${step['operand']}');
      questionParts.add(i == hideStep ? '= ?' : '= ${step['result']}');
    }

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: questionParts.join(' '),
      correctAnswer: correctAnswer,
      type: TaskType.freeInput,
      metadata: {
        'start': start,
        'chain': chain,
        'hideStep': hideStep,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Textaufgaben — Kl.2
class WordProblemGrade2Template extends TaskTemplate {
  const WordProblemGrade2Template()
      : super(
          id: 'textaufgaben',
          subject: Subject.math,
          grade: 2,
          topic: 'textaufgaben',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Textaufgabe';

  static const _contexts = [
    (
      template: 'Emma hat {a} Äpfel. Sie bekommt {b} Äpfel dazu. Wie viele Äpfel hat sie jetzt?',
      op: '+',
    ),
    (
      template: 'In der Bücherei gibt es {a} Bücher. {b} Bücher werden ausgeliehen. Wie viele sind noch da?',
      op: '-',
    ),
    (
      template: 'Auf dem Parkplatz stehen {a} Autos. Dann kommen {b} Autos dazu. Wie viele Autos stehen jetzt da?',
      op: '+',
    ),
    (
      template: 'Tom hat {a} Murmeln. Er schenkt {b} Murmeln weg. Wie viele Murmeln hat er noch?',
      op: '-',
    ),
    (
      template: 'Im Zoo gibt es {a} Affen und {b} Löwen. Wie viele Tiere sind das zusammen?',
      op: '+',
    ),
    (
      template: 'In der Klasse sitzen {a} Kinder. {b} Kinder fehlen heute. Wie viele Kinder sind da?',
      op: '-',
    ),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final maxNum = switch (difficulty) { 1 => 10, 2 => 20, _ => 50 };
    final ctx = _contexts[rng.nextInt(_contexts.length)];

    final int a, b, result;
    if (ctx.op == '+') {
      a = rng.nextInt(maxNum ~/ 2) + 1;
      b = rng.nextInt(maxNum - a) + 1;
      result = a + b;
    } else {
      a = rng.nextInt(maxNum - 1) + 2;
      b = rng.nextInt(a - 1) + 1;
      result = a - b;
    }

    final question = ctx.template
        .replaceAll('{a}', a.toString())
        .replaceAll('{b}', b.toString());

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: question,
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
