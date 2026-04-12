/// Deutsch-Templates Klasse 2 — Rechtschreibung & erste Grammatik.
///
/// Inhalte:
/// - ie/ei-Unterscheidung (Lückenwort + 2-Wege-Auswahl)
/// - Sätze bilden (Wörter in richtige Reihenfolge, [OrderingWidget])
/// - Lesetext & Verständnisfragen (3 Texte × 3 Fragen, [ReadingTextWidget])
import 'dart:math';
import '../../models/task_model.dart';
import '../../models/subject.dart';
import '../task_template.dart';

/// ie oder ei? — Kl.2.
///
/// Versteckt die zwei Buchstaben im Wort und gibt dem Kind die Wahl
/// zwischen `"ie"` und `"ei"`. Pool: 17 ie-Wörter + 16 ei-Wörter.
class IeEiTemplate extends TaskTemplate {
  const IeEiTemplate()
      : super(
          id: 'rechtschreibung_ie_ei',
          subject: Subject.german,
          grade: 2,
          topic: 'rechtschreibung_ie_ei',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'ie oder ei?';

  static const _ieWords = [
    'Biene', 'Tier', 'Liebe', 'Brief', 'Spiel', 'Knie',
    'Dieb', 'Ried', 'Wiese', 'Miete', 'Sieb', 'Fieber',
    'Riese', 'Lied', 'Wiel', 'fliegen', 'sieden',
  ];

  static const _eiWords = [
    'Eimer', 'Klein', 'Stein', 'Leiter', 'Seite', 'Reihe',
    'Weiß', 'Eis', 'Brei', 'Meile', 'Geige', 'Fleisch',
    'Reise', 'Zeige', 'Bleistift', 'Weizen',
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final useIe = rng.nextBool();
    final pool = useIe ? _ieWords : _eiWords;
    final word = pool[rng.nextInt(pool.length)];
    final correct = useIe ? 'ie' : 'ei';
    final idx = word.toLowerCase().indexOf(correct);

    String displayed;
    if (idx >= 0) {
      displayed = word.substring(0, idx) + '___' + word.substring(idx + 2);
    } else {
      displayed = word; // Fallback — sollte nicht vorkommen
    }

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'ie oder ei?\n"$displayed"',
      correctAnswer: correct,
      type: TaskType.multipleChoice,
      metadata: {
        'word': word,
        'displayedWord': displayed,
        'choices': ['ie', 'ei'],
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

/// Sätze bilden (Wörter in Reihenfolge) — Kl.2
class SentenceFormationTemplate extends TaskTemplate {
  const SentenceFormationTemplate()
      : super(
          id: 'saetze_bilden',
          subject: Subject.german,
          grade: 2,
          topic: 'saetze_bilden',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Sätze bilden';

  static const _sentences = [
    (['Der', 'Hund', 'bellt', 'laut.'], 'Der Hund bellt laut.'),
    (['Die', 'Katze', 'schläft', 'auf', 'dem', 'Sofa.'], 'Die Katze schläft auf dem Sofa.'),
    (['Das', 'Kind', 'spielt', 'im', 'Garten.'], 'Das Kind spielt im Garten.'),
    (['Wir', 'essen', 'heute', 'Pizza.'], 'Wir essen heute Pizza.'),
    (['Die', 'Sonne', 'scheint', 'hell.'], 'Die Sonne scheint hell.'),
    (['Tom', 'liest', 'ein', 'Buch.'], 'Tom liest ein Buch.'),
    (['Der', 'Vogel', 'singt', 'schön.'], 'Der Vogel singt schön.'),
    (['Anna', 'malt', 'ein', 'Bild.'], 'Anna malt ein Bild.'),
    (['Das', 'Auto', 'fährt', 'schnell.'], 'Das Auto fährt schnell.'),
    (['Wir', 'gehen', 'morgen', 'ins', 'Kino.'], 'Wir gehen morgen ins Kino.'),
    (['Die', 'Blumen', 'blühen', 'im', 'Frühling.'], 'Die Blumen blühen im Frühling.'),
    (['Mia', 'schwimmt', 'gerne', 'im', 'See.'], 'Mia schwimmt gerne im See.'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    // Filter nach Satzlänge
    final pool = _sentences.where((s) {
      final wordCount = s.$1.length;
      if (difficulty == 1) return wordCount <= 4;
      if (difficulty == 2) return wordCount <= 5;
      return true;
    }).toList();

    final (words, correct) = pool[rng.nextInt(pool.length)];
    final shuffled = List<String>.from(words)..shuffle(rng);

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Bringe die Wörter in die richtige Reihenfolge!',
      correctAnswer: correct,
      type: TaskType.ordering,
      metadata: {
        'words': shuffled,
        'correctWords': words,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final correct = task.correctAnswer.toString().toLowerCase().trim();
    String answer;
    if (userAnswer is List) {
      answer = userAnswer.join(' ').toLowerCase().trim();
    } else {
      answer = userAnswer.toString().toLowerCase().trim();
    }
    return correct == answer;
  }
}

/// Lesetext + Verständnisfragen — Kl.2
class ReadingComprehensionTemplate extends TaskTemplate {
  const ReadingComprehensionTemplate()
      : super(
          id: 'lesetext',
          subject: Subject.german,
          grade: 2,
          topic: 'lesetext',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Lesetext & Fragen';

  static const _texts = [
    (
      text: 'Tim hat einen Hund. Er heißt Bello. Bello ist braun und hat lange Ohren. Jeden Tag gehen Tim und Bello in den Park. Dort spielen sie Ball.',
      questions: [
        ('Wie heißt der Hund?', 'Bello', ['Bello', 'Rex', 'Bruno', 'Max']),
        ('Welche Farbe hat Bello?', 'braun', ['braun', 'schwarz', 'weiß', 'grau']),
        ('Wohin gehen Tim und Bello?', 'in den Park', ['in den Park', 'in die Schule', 'zum Supermarkt', 'in den Wald']),
      ],
    ),
    (
      text: 'Lisa liebt Erdbeeren. Im Sommer pflückt sie Erdbeeren im Garten. Ihre Oma macht daraus Marmelade. Die Marmelade schmeckt sehr lecker.',
      questions: [
        ('Was liebt Lisa?', 'Erdbeeren', ['Erdbeeren', 'Kirschen', 'Äpfel', 'Bananen']),
        ('Wann pflückt Lisa Erdbeeren?', 'Im Sommer', ['Im Sommer', 'Im Winter', 'Im Herbst', 'Im Frühling']),
        ('Was macht die Oma mit den Erdbeeren?', 'Marmelade', ['Marmelade', 'Saft', 'Kuchen', 'Suppe']),
      ],
    ),
    (
      text: 'Max und Emma bauen eine Schneeburg. Sie brauchen viele Schneebälle. Die Burg ist sehr groß. Am Ende sind beide ganz nass und kalt.',
      questions: [
        ('Was bauen Max und Emma?', 'eine Schneeburg', ['eine Schneeburg', 'ein Haus', 'ein Schloss', 'einen Schneemann']),
        ('Was brauchen sie?', 'viele Schneebälle', ['viele Schneebälle', 'Schaufeln', 'Steine', 'Holz']),
        ('Wie sind sie am Ende?', 'nass und kalt', ['nass und kalt', 'warm und trocken', 'müde und hungrig', 'froh und munter']),
      ],
    ),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final textData = _texts[rng.nextInt(_texts.length)];
    final qIdx = rng.nextInt(textData.questions.length);
    final (question, correct, choices) = textData.questions[qIdx];

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: question,
      correctAnswer: correct,
      type: TaskType.multipleChoice,
      metadata: {
        'text': textData.text,
        'choices': List<String>.from(choices)..shuffle(rng),
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().toLowerCase() ==
      userAnswer.toString().toLowerCase();
}
