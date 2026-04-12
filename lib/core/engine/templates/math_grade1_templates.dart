/// Mathe-Templates Klasse 1.
///
/// Inhalte: Punkte zählen (Mengenbegriff), Zahlen schreiben (0–20),
/// Formen erkennen (6 Grundformen), Muster fortsetzen (Emoji-Sequenzen).
import 'dart:math';
import '../../models/task_model.dart';
import '../../models/subject.dart';
import '../task_template.dart';

/// Punkte zählen und Zahl eingeben — Kl.1.
///
/// Zeigt eine zufällige Punktmenge (1–10 bei Diff.1, bis 20 bei Diff.2)
/// mit animiertem [DotCountWidget]. Das Kind tippt die Anzahl ein.
class CountDotsTemplate extends TaskTemplate {
  const CountDotsTemplate()
      : super(
          id: 'count_dots',
          subject: Subject.math,
          grade: 1,
          topic: 'zahlen_bis_10',
          minDifficulty: 1,
          maxDifficulty: 2,
        );

  @override
  String get displayName => 'Punkte zählen';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final max = difficulty == 1 ? 10 : 20;
    final count = rng.nextInt(max) + 1;
    // dots: Liste von (row, col)-Positionen für das Widget
    final rows = (count / 5).ceil();
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Wie viele Punkte siehst du?',
      correctAnswer: count,
      type: TaskType.freeInput,
      metadata: {
        'dotCount': count,
        'rows': rows,
        'cols': 5,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

/// Formen erkennen — Kl.1
class ShapeRecognitionTemplate extends TaskTemplate {
  const ShapeRecognitionTemplate()
      : super(
          id: 'shape_recognition',
          subject: Subject.math,
          grade: 1,
          topic: 'formen',
          minDifficulty: 1,
          maxDifficulty: 2,
        );

  @override
  String get displayName => 'Formen erkennen';

  static const _shapes = [
    ('Kreis', 'circle', '⭕'),
    ('Dreieck', 'triangle', '🔺'),
    ('Quadrat', 'square', '🟥'),
    ('Rechteck', 'rectangle', '▬'),
    ('Raute', 'diamond', '🔷'),
    ('Stern', 'star', '⭐'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final shapeIdx = rng.nextInt(_shapes.length);
    final (name, shapeId, emoji) = _shapes[shapeIdx];

    // Distraktoren: 3 andere Formen
    final distractors = List<int>.generate(_shapes.length, (i) => i)
      ..remove(shapeIdx)
      ..shuffle(rng);
    final choices = [name, _shapes[distractors[0]].$1,
        _shapes[distractors[1]].$1, _shapes[distractors[2]].$1]
      ..shuffle(rng);

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Was für eine Form ist das?\n$emoji',
      correctAnswer: name,
      type: TaskType.multipleChoice,
      metadata: {
        'shapeId': shapeId,
        'emoji': emoji,
        'choices': choices,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

/// Muster fortsetzen — Kl.1
class PatternContinuationTemplate extends TaskTemplate {
  const PatternContinuationTemplate()
      : super(
          id: 'pattern_continuation',
          subject: Subject.math,
          grade: 1,
          topic: 'muster',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Muster fortsetzen';

  static const _patternSets = [
    ['🔴', '🔵', '🔴', '🔵', '🔴'],
    ['⭐', '🌙', '⭐', '🌙', '⭐'],
    ['🔺', '🟥', '🔺', '🟥', '🔺'],
    ['🍎', '🍊', '🍋', '🍎', '🍊'],
    ['🐱', '🐶', '🐱', '🐶', '🐱'],
    ['🔵', '🔵', '🔴', '🔵', '🔵'],
    ['1', '2', '3', '1', '2'],
    ['A', 'B', 'C', 'A', 'B'],
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final patternSet = _patternSets[rng.nextInt(_patternSets.length)];
    final period = difficulty == 1 ? 2 : (difficulty == 2 ? 3 : 4);
    final clampedPeriod = period.clamp(2, patternSet.length);

    // Erstelle Muster: 4–6 sichtbare Elemente + 1 verstecktes
    final base = patternSet.sublist(0, clampedPeriod);
    final showCount = 4 + rng.nextInt(2);
    final visible = List<String>.generate(showCount, (i) => base[i % base.length]);
    final next = base[showCount % base.length];

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Was kommt als nächstes?',
      correctAnswer: next,
      type: TaskType.multipleChoice,
      metadata: {
        'visible': visible,
        'choices': base.toSet().toList()..shuffle(rng),
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

/// Zahlen schreiben / Zahlverständnis — Kl.1
class NumberWritingTemplate extends TaskTemplate {
  const NumberWritingTemplate()
      : super(
          id: 'number_writing',
          subject: Subject.math,
          grade: 1,
          topic: 'zahlen_bis_20',
          minDifficulty: 1,
          maxDifficulty: 2,
        );

  @override
  String get displayName => 'Zahlen schreiben';

  static const _numberWords = {
    0: 'null', 1: 'eins', 2: 'zwei', 3: 'drei', 4: 'vier',
    5: 'fünf', 6: 'sechs', 7: 'sieben', 8: 'acht', 9: 'neun',
    10: 'zehn', 11: 'elf', 12: 'zwölf', 13: 'dreizehn',
    14: 'vierzehn', 15: 'fünfzehn', 16: 'sechzehn',
    17: 'siebzehn', 18: 'achtzehn', 19: 'neunzehn', 20: 'zwanzig',
  };

  @override
  TaskModel generate(int difficulty, Random rng) {
    final max = difficulty == 1 ? 10 : 20;
    final number = rng.nextInt(max + 1);
    final word = _numberWords[number]!;

    // Abwechselnd: Zahl → Wort oder Wort → Zahl
    final showWord = rng.nextBool();
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: showWord
          ? 'Schreibe die Zahl für: "$word"'
          : 'Schreibe das Wort für die Zahl: $number',
      correctAnswer: showWord ? number : word,
      type: TaskType.freeInput,
      metadata: {
        'number': number,
        'word': word,
        'showWord': showWord,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    if (task.correctAnswer is int) {
      final answer = int.tryParse(userAnswer.toString());
      return answer != null && answer == task.correctAnswer;
    }
    return task.correctAnswer.toString().trim().toLowerCase() ==
        userAnswer.toString().trim().toLowerCase();
  }
}
