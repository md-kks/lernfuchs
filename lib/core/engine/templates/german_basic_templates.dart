/// Deutsch-Basistemplates (klassenübergreifend, vorwiegend Kl.2+).
///
/// Inhalte: Artikel (der/die/das), Einzahl/Mehrzahl, ABC-Sortierung,
/// Wortarten (Nomen/Verb/Adjektiv), das/dass-Unterscheidung.
import 'dart:math';
import '../../models/task_model.dart';
import '../../models/subject.dart';
import '../task_template.dart';

const _nouns = [
  ('der', 'Hund'), ('die', 'Katze'), ('das', 'Haus'), ('der', 'Baum'),
  ('die', 'Blume'), ('das', 'Kind'), ('der', 'Ball'), ('die', 'Schule'),
  ('das', 'Buch'), ('der', 'Tisch'), ('die', 'Tür'), ('das', 'Auto'),
  ('der', 'Vogel'), ('die', 'Sonne'), ('das', 'Wasser'), ('der', 'Apfel'),
  ('die', 'Maus'), ('das', 'Pferd'), ('der', 'Mond'), ('die', 'Straße'),
];

const _plurals = [
  ('Hund', 'Hunde'), ('Katze', 'Katzen'), ('Baum', 'Bäume'),
  ('Blume', 'Blumen'), ('Kind', 'Kinder'), ('Ball', 'Bälle'),
  ('Buch', 'Bücher'), ('Tisch', 'Tische'), ('Vogel', 'Vögel'),
  ('Apfel', 'Äpfel'), ('Haus', 'Häuser'), ('Maus', 'Mäuse'),
];

/// Artikel zuordnen — Klasse 2
class ArticleTemplate extends TaskTemplate {
  const ArticleTemplate()
      : super(
          id: 'artikel',
          subject: Subject.german,
          grade: 2,
          topic: 'artikel',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Artikel zuordnen (der/die/das)';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final (article, noun) = _nouns[rng.nextInt(_nouns.length)];
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '___ $noun',
      correctAnswer: article,
      type: TaskType.multipleChoice,
      metadata: {
        'noun': noun,
        'choices': ['der', 'die', 'das'],
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

/// Einzahl/Mehrzahl — Klasse 2
class PluralTemplate extends TaskTemplate {
  const PluralTemplate()
      : super(
          id: 'einzahl_mehrzahl',
          subject: Subject.german,
          grade: 2,
          topic: 'einzahl_mehrzahl',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Einzahl / Mehrzahl';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final (singular, plural) = _plurals[rng.nextInt(_plurals.length)];
    final askForPlural = rng.nextBool();
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: askForPlural
          ? 'Was ist die Mehrzahl von "$singular"?'
          : 'Was ist die Einzahl von "$plural"?',
      correctAnswer: askForPlural ? plural : singular,
      type: TaskType.freeInput,
      metadata: {
        'singular': singular,
        'plural': plural,
        'askForPlural': askForPlural,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().trim().toLowerCase() ==
      userAnswer.toString().trim().toLowerCase();
}

/// ABC sortieren — Klasse 2
class AlphabetSortTemplate extends TaskTemplate {
  const AlphabetSortTemplate()
      : super(
          id: 'abc_sortieren',
          subject: Subject.german,
          grade: 2,
          topic: 'abc_sortieren',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'ABC sortieren';

  static const _wordSets = [
    ['Apfel', 'Birne', 'Erdbeere', 'Mango'],
    ['Hund', 'Katze', 'Maus', 'Vogel'],
    ['Auto', 'Bus', 'Schiff', 'Zug'],
    ['Buch', 'Heft', 'Stift', 'Tafel'],
    ['Blume', 'Gras', 'Rose', 'Tulpe'],
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final wordSet = List<String>.from(
      _wordSets[rng.nextInt(_wordSets.length)],
    );
    final sorted = List<String>.from(wordSet)..sort();
    wordSet.shuffle(rng);
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Bringe die Wörter in alphabetische Reihenfolge!',
      correctAnswer: sorted,
      type: TaskType.ordering,
      metadata: {'words': wordSet},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    if (userAnswer is! List) return false;
    final correct = task.correctAnswer as List;
    if (correct.length != userAnswer.length) return false;
    for (int i = 0; i < correct.length; i++) {
      if (correct[i] != userAnswer[i]) return false;
    }
    return true;
  }
}

/// das/dass — Klasse 4
class DasDassTemplate extends TaskTemplate {
  const DasDassTemplate()
      : super(
          id: 'das_dass',
          subject: Subject.german,
          grade: 4,
          topic: 'das_dass',
          minDifficulty: 2,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'das oder dass?';

  static const _sentences = [
    ('___ Haus ist groß.', 'Das'),
    ('Ich glaube, ___ er kommt.', 'dass'),
    ('___ ist mein Hund.', 'Das'),
    ('Sie hofft, ___ es klappt.', 'dass'),
    ('___ Kind spielt im Garten.', 'Das'),
    ('Er weiß, ___ die Antwort richtig ist.', 'dass'),
    ('___ Buch liegt auf dem Tisch.', 'Das'),
    ('Wir freuen uns, ___ du da bist.', 'dass'),
    ('___ Wetter ist heute schön.', 'Das'),
    ('Sie sagt, ___ sie morgen kommt.', 'dass'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final (sentence, correct) = _sentences[rng.nextInt(_sentences.length)];
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: sentence,
      correctAnswer: correct,
      type: TaskType.multipleChoice,
      metadata: {'choices': ['Das', 'dass']},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().toLowerCase() ==
      userAnswer.toString().toLowerCase();
}

/// Wortarten sortieren — Klasse 2/3
class WordTypeTemplate extends TaskTemplate {
  const WordTypeTemplate()
      : super(
          id: 'wortarten',
          subject: Subject.german,
          grade: 2,
          topic: 'wortarten',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Wortarten bestimmen';

  static const _words = [
    ('Hund', 'Nomen'), ('rennen', 'Verb'), ('blau', 'Adjektiv'),
    ('Sonne', 'Nomen'), ('singen', 'Verb'), ('groß', 'Adjektiv'),
    ('Baum', 'Nomen'), ('lachen', 'Verb'), ('klein', 'Adjektiv'),
    ('Schule', 'Nomen'), ('schreiben', 'Verb'), ('schnell', 'Adjektiv'),
    ('Auto', 'Nomen'), ('spielen', 'Verb'), ('warm', 'Adjektiv'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final (word, wordType) = _words[rng.nextInt(_words.length)];
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Welche Wortart ist "$word"?',
      correctAnswer: wordType,
      type: TaskType.multipleChoice,
      metadata: {'word': word, 'choices': ['Nomen', 'Verb', 'Adjektiv']},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}
