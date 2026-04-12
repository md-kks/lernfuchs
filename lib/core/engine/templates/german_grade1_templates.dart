/// Deutsch-Templates Klasse 1 — phonologische Bewusstsein & Schriftsprache.
///
/// Inhalte:
/// - Buchstaben erkennen (Anlautmethode, A–Z + Umlaute)
/// - Anlaute erkennen (Emoji-Bild → Anfangsbuchstabe)
/// - Silben klatschen (tapRhythm, 1–4 Silben)
/// - Reimwörter (Wortpaar reimt sich? Ja/Nein + Auswahl)
/// - Lückenwörter (versteckter Buchstabe, 4er-Auswahl)
/// - Buchstabensalat / Anagramm (Buchstaben in Reihenfolge bringen)
import 'dart:math';
import '../../models/task_model.dart';
import '../../models/subject.dart';
import '../task_template.dart';

// ── Buchstaben ──────────────────────────────────────────────────

/// Buchstaben nachschreiben / erkennen — Kl.1
/// (Handschrift-Pad kommt in Phase 4; hier: Buchstaben-Auswahl)
class LetterRecognitionTemplate extends TaskTemplate {
  const LetterRecognitionTemplate()
      : super(
          id: 'buchstaben',
          subject: Subject.german,
          grade: 1,
          topic: 'buchstaben',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Buchstaben erkennen';

  static const _letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', 'Ä', 'Ö', 'Ü',
  ];

  static const _exampleWords = {
    'A': 'Apfel', 'B': 'Ball', 'C': 'Computer', 'D': 'Dach',
    'E': 'Ente', 'F': 'Fuchs', 'G': 'Gabel', 'H': 'Hund',
    'I': 'Igel', 'J': 'Jacke', 'K': 'Katze', 'L': 'Löwe',
    'M': 'Maus', 'N': 'Nase', 'O': 'Oma', 'P': 'Pferd',
    'Q': 'Qualle', 'R': 'Rose', 'S': 'Sonne', 'T': 'Tisch',
    'U': 'Uhr', 'V': 'Vogel', 'W': 'Wasser', 'X': 'Xylofon',
    'Y': 'Yak', 'Z': 'Zebra', 'Ä': 'Ärger', 'Ö': 'Öl', 'Ü': 'Übung',
  };

  @override
  TaskModel generate(int difficulty, Random rng) {
    final pool = difficulty == 1
        ? _letters.sublist(0, 10) // A–J
        : difficulty == 2
            ? _letters.sublist(0, 20) // A–T
            : _letters; // alle inkl. Umlaute

    final correct = pool[rng.nextInt(pool.length)];
    final word = _exampleWords[correct] ?? correct;

    // 3 Distraktoren
    final distractors = List<String>.from(pool)
      ..remove(correct)
      ..shuffle(rng);
    final choices = [correct, ...distractors.take(3)]..shuffle(rng);

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Mit welchem Buchstaben fängt "$word" an?',
      correctAnswer: correct,
      type: TaskType.multipleChoice,
      metadata: {
        'letter': correct,
        'word': word,
        'choices': choices,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

// ── Anlaute ──────────────────────────────────────────────────────

/// Anlaute erkennen — Kl.1 (Bild → Anlaut)
class InitialSoundTemplate extends TaskTemplate {
  const InitialSoundTemplate()
      : super(
          id: 'anlaute',
          subject: Subject.german,
          grade: 1,
          topic: 'anlaute',
          minDifficulty: 1,
          maxDifficulty: 2,
        );

  @override
  String get displayName => 'Anlaute erkennen';

  static const _wordPictures = [
    ('🍎', 'Apfel', 'A'),
    ('🐝', 'Biene', 'B'),
    ('🦆', 'Ente', 'E'),
    ('🦊', 'Fuchs', 'F'),
    ('🐸', 'Frosch', 'F'),
    ('🏠', 'Haus', 'H'),
    ('🐴', 'Pferd', 'P'),
    ('🌞', 'Sonne', 'S'),
    ('🐢', 'Schildkröte', 'S'),
    ('🍅', 'Tomate', 'T'),
    ('🐘', 'Elefant', 'E'),
    ('🦁', 'Löwe', 'L'),
    ('🐭', 'Maus', 'M'),
    ('🌙', 'Mond', 'M'),
    ('🌈', 'Regenbogen', 'R'),
    ('🎂', 'Torte', 'T'),
    ('🐦', 'Vogel', 'V'),
    ('🐺', 'Wolf', 'W'),
    ('🎻', 'Geige', 'G'),
    ('🍇', 'Trauben', 'T'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final (emoji, word, correct) = _wordPictures[rng.nextInt(_wordPictures.length)];

    // Distraktoren: andere Anfangsbuchstaben
    final allLetters = {'A','B','C','D','E','F','G','H','I','K','L','M','N','P','R','S','T','V','W'};
    allLetters.remove(correct);
    final distract = allLetters.toList()..shuffle(rng);
    final choices = [correct, distract[0], distract[1], distract[2]]..shuffle(rng);

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Mit welchem Laut fängt das Wort an?\n$emoji',
      correctAnswer: correct,
      type: TaskType.multipleChoice,
      metadata: {
        'emoji': emoji,
        'word': word,
        'choices': choices,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

// ── Silben ──────────────────────────────────────────────────────

/// Silben klatschen / zählen — Kl.1
class SyllableCountTemplate extends TaskTemplate {
  const SyllableCountTemplate()
      : super(
          id: 'silben',
          subject: Subject.german,
          grade: 1,
          topic: 'silben',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Silben klatschen';

  static const _syllableWords = [
    // (word, syllables, count)
    ('Haus', 'Haus', 1),
    ('Maus', 'Maus', 1),
    ('Sonne', 'Son-ne', 2),
    ('Blume', 'Blu-me', 2),
    ('Katze', 'Kat-ze', 2),
    ('Hund', 'Hund', 1),
    ('Tiger', 'Ti-ger', 2),
    ('Elefant', 'E-le-fant', 3),
    ('Apfel', 'Ap-fel', 2),
    ('Schmetterling', 'Schmet-ter-ling', 3),
    ('Erdbeere', 'Erd-bee-re', 3),
    ('Regenbogen', 'Re-gen-bo-gen', 4),
    ('Buch', 'Buch', 1),
    ('Fenster', 'Fens-ter', 2),
    ('Computer', 'Com-pu-ter', 3),
    ('Auto', 'Au-to', 2),
    ('Fahrrad', 'Fahr-rad', 2),
    ('Banane', 'Ba-na-ne', 3),
    ('Schokolade', 'Scho-ko-la-de', 4),
    ('Kuchen', 'Ku-chen', 2),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    // Schwierigkeit bestimmt max. Silbenzahl
    final maxSyllables = difficulty == 1 ? 2 : (difficulty == 2 ? 3 : 4);
    final pool = _syllableWords
        .where((w) => w.$3 <= maxSyllables)
        .toList();
    final (word, split, count) = pool[rng.nextInt(pool.length)];

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Wie viele Silben hat das Wort?\n"$word"',
      correctAnswer: count,
      type: TaskType.tapRhythm,
      metadata: {
        'word': word,
        'syllableSplit': split,
        'syllableCount': count,
        'choices': List.generate(4, (i) => i + 1),
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}

// ── Reimwörter ──────────────────────────────────────────────────

/// Reimwörter erkennen — Kl.1
class RhymeTemplate extends TaskTemplate {
  const RhymeTemplate()
      : super(
          id: 'reimwoerter',
          subject: Subject.german,
          grade: 1,
          topic: 'reimwoerter',
          minDifficulty: 1,
          maxDifficulty: 2,
        );

  @override
  String get displayName => 'Reimwörter';

  static const _rhymePairs = [
    ['Maus', 'Haus', 'Strauß'],
    ['Hund', 'Mund', 'Bund'],
    ['Ball', 'Tall', 'Hall'],
    ['Biene', 'Grüne', 'Kühne'],
    ['Baum', 'Traum', 'Raum'],
    ['Sonne', 'Wonne', 'Tonne'],
    ['Nacht', 'Acht', 'Macht'],
    ['Ring', 'Ding', 'King'],
    ['Rose', 'Hose', 'Dose'],
    ['Katz', 'Satz', 'Platz'],
  ];

  static const _nonRhymes = [
    'Tisch', 'Apfel', 'Vogel', 'Schule', 'Fenster',
    'Garten', 'Brücke', 'Lampe', 'Stunde', 'Wasser',
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final group = _rhymePairs[rng.nextInt(_rhymePairs.length)];
    final word = group[0];

    // Zufällig: entweder Reim wählen oder Nicht-Reim erkennen
    final isRhymeTask = rng.nextBool();

    if (isRhymeTask || difficulty == 1) {
      // Finde das Reimwort aus 3 Optionen
      final correct = group[1 + rng.nextInt(group.length - 1)];
      final nonRhyme = _nonRhymes[rng.nextInt(_nonRhymes.length)];
      final choices = [correct, nonRhyme, group[rng.nextInt(group.length - 1) == 0 ? 2 : 1]]
          .toSet().toList()..shuffle(rng);
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Welches Wort reimt sich auf "$word"?',
        correctAnswer: correct,
        type: TaskType.multipleChoice,
        metadata: {'word': word, 'choices': choices.take(3).toList()},
      );
    } else {
      // Reimt sich das Wortpaar? Ja/Nein
      final doesRhyme = rng.nextBool();
      final second = doesRhyme
          ? group[1]
          : _nonRhymes[rng.nextInt(_nonRhymes.length)];
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Reimen sich "$word" und "$second"?',
        correctAnswer: doesRhyme ? 'Ja' : 'Nein',
        type: TaskType.multipleChoice,
        metadata: {'word1': word, 'word2': second, 'choices': ['Ja', 'Nein']},
      );
    }
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

// ── Lückenwörter (Buchstabe) ─────────────────────────────────────

/// Lückenwörter: fehlender Buchstabe — Kl.1
class MissingLetterTemplate extends TaskTemplate {
  const MissingLetterTemplate()
      : super(
          id: 'lueckenwoerter',
          subject: Subject.german,
          grade: 1,
          topic: 'lueckenwoerter',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Lückenwörter';

  static const _words = [
    'Katze', 'Hunde', 'Vogel', 'Mause', 'Sonne', 'Blume',
    'Tisch', 'Stuhl', 'Fenst', 'Garte', 'Schul', 'Baume',
    'Apfel', 'Birne', 'Traub', 'Kirsc', 'Banan', 'Mango',
    'Haus', 'Auto', 'Ball', 'Buch', 'Ring', 'Zug',
  ];

  static const _fullWords = [
    'Katze', 'Hunde', 'Vogel', 'Mäuse', 'Sonne', 'Blume',
    'Tisch', 'Stuhl', 'Fenster', 'Garten', 'Schule', 'Bäume',
    'Apfel', 'Birne', 'Traube', 'Kirsche', 'Banane', 'Mango',
    'Haus', 'Auto', 'Ball', 'Buch', 'Ring', 'Zug',
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final idx = rng.nextInt(_fullWords.length);
    final word = _fullWords[idx];
    if (word.length < 3) {
      return generate(difficulty, rng); // zu kurz, nochmal
    }

    // Verstecke einen Buchstaben
    final hidePos = difficulty == 1
        ? word.length - 1 // letzter Buchstabe — einfachste
        : rng.nextInt(word.length);

    final hidden = word[hidePos];
    final displayed = word.substring(0, hidePos) +
        '_' +
        (hidePos + 1 < word.length ? word.substring(hidePos + 1) : '');

    // Distraktoren
    final alphabet = 'ABCDEFGHIJKLMNOPRSTUVWÄÖÜ'.split('');
    alphabet.remove(hidden.toUpperCase());
    alphabet.shuffle(rng);
    final choices = [hidden, alphabet[0], alphabet[1], alphabet[2]]
      ..shuffle(rng);

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Welcher Buchstabe fehlt?\n"$displayed"',
      correctAnswer: hidden,
      type: TaskType.multipleChoice,
      metadata: {
        'word': word,
        'displayedWord': displayed,
        'hidePos': hidePos,
        'choices': choices,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().toLowerCase() ==
      userAnswer.toString().toLowerCase();
}

// ── Buchstaben-Salat ─────────────────────────────────────────────

/// Buchstaben-Salat: Buchstaben in richtige Reihenfolge bringen — Kl.1
class AnagramTemplate extends TaskTemplate {
  const AnagramTemplate()
      : super(
          id: 'buchstaben_salat',
          subject: Subject.german,
          grade: 1,
          topic: 'buchstaben_salat',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Buchstaben-Salat';

  static const _wordsByDifficulty = [
    // difficulty 1: 3-4 Buchstaben
    ['Bus', 'Tag', 'Zug', 'Arm', 'Eis', 'Hut', 'Rad', 'See', 'Tor'],
    // difficulty 2: 4-5 Buchstaben
    ['Haus', 'Baum', 'Tier', 'Buch', 'Mond', 'Igel', 'Nase', 'Auto'],
    // difficulty 3: 5-6 Buchstaben
    ['Schule', 'Blume', 'Vogel', 'Tisch', 'Lampe', 'Sonne', 'Katze'],
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final pool = _wordsByDifficulty[(difficulty - 1).clamp(0, 2)];
    final word = pool[rng.nextInt(pool.length)];
    final letters = word.toUpperCase().split('')..shuffle(rng);
    // Sicherstellen, dass es nicht zufällig das richtige Wort ergibt
    while (letters.join() == word.toUpperCase()) {
      letters.shuffle(rng);
    }

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Ordne die Buchstaben zum richtigen Wort!',
      correctAnswer: word,
      type: TaskType.ordering,
      metadata: {
        'word': word,
        'letters': letters,
        'hint': word[0].toUpperCase(), // erster Buchstabe als Tipp
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final correct = task.correctAnswer.toString().toUpperCase();
    String answer;
    if (userAnswer is List) {
      answer = userAnswer.join().toUpperCase();
    } else {
      answer = userAnswer.toString().toUpperCase();
    }
    return correct == answer;
  }
}

// ── Handschrift ──────────────────────────────────────────────────

/// Buchstaben nachschreiben / nachspuren — Kl.1.
///
/// Das Kind zeichnet den angezeigten Buchstaben nach (großes, verblasstes
/// Referenzbild im Hintergrund). Das [HandwritingWidget] meldet `'traced'`
/// sobald genug Fläche überdeckt wurde. Die Auswertung ist damit immer binär:
/// entweder das Kind hat den Buchstaben nachgezogen oder nicht.
///
/// **Schwierigkeit:**
/// - Diff 1: Vokale + einfache Konsonanten (A, E, I, O, U, M, N, L)
/// - Diff 2: Komplexere Buchstaben (B, D, G, H, K, R, S, T, W)
class HandwritingTemplate extends TaskTemplate {
  const HandwritingTemplate()
      : super(
          id: 'handschrift',
          subject: Subject.german,
          grade: 1,
          topic: 'handschrift',
          minDifficulty: 1,
          maxDifficulty: 2,
        );

  @override
  String get displayName => 'Buchstaben schreiben';

  // (buchstabe, beispielwort, schwierigkeit)
  static const _letters = [
    ('A', 'Apfel', 1), ('E', 'Ente', 1), ('I', 'Igel', 1),
    ('O', 'Oma', 1),   ('U', 'Uhr', 1),  ('M', 'Maus', 1),
    ('N', 'Nase', 1),  ('L', 'Löwe', 1),
    ('B', 'Ball', 2),  ('D', 'Dach', 2), ('G', 'Gabel', 2),
    ('H', 'Hund', 2),  ('K', 'Katze', 2),('R', 'Rose', 2),
    ('S', 'Sonne', 2), ('T', 'Tisch', 2),('W', 'Wasser', 2),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final pool = _letters.where((l) => l.$3 <= difficulty).toList();
    final (letter, word, _) = pool[rng.nextInt(pool.length)];

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Schreibe den Buchstaben nach:\n"$letter" wie $word',
      correctAnswer: 'traced',
      type: TaskType.handwriting,
      metadata: {
        'letter': letter,
        'lowercase': letter.toLowerCase(),
        'word': word,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      userAnswer.toString() == 'traced';
}
