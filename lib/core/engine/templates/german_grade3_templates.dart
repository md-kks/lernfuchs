/// Deutsch-Templates Klasse 3 — erweiterte Grammatik & Rechtschreibung.
///
/// Inhalte:
/// - Zeitformen: Präsens/Präteritum/Perfekt (12 Verben × 3 Formen)
/// - Wortfamilien: Eindringling erkennen (8 Familien)
/// - Zusammengesetzte Nomen: Teile zusammensetzen oder aufteilen
/// - Satzarten: Aussage/Frage/Aufforderung/Ausruf + Satzzeichen
/// - Diktat: Wort 3 Sekunden anzeigen → verdecken → eingeben ([DictationWidget])
/// - Lernwörter: häufige Funktionswörter mit Lückentext vervollständigen
import 'dart:math';
import '../../models/task_model.dart';
import '../../models/subject.dart';
import '../task_template.dart';

/// Zeitformen (Präsens / Präteritum / Perfekt) — Kl.3.
///
/// Bei Schwierigkeit 1 werden nur Präsens und Präteritum abgefragt.
/// Ab Schwierigkeit 2 kommt Perfekt hinzu. 12 Verben im Pool,
/// inkl. starker Verben (laufen → lief, gehen → ging).
class VerbTenseTemplate extends TaskTemplate {
  const VerbTenseTemplate()
      : super(
          id: 'zeitformen',
          subject: Subject.german,
          grade: 3,
          topic: 'zeitformen',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Zeitformen';

  static const _verbForms = [
    // (infinitiv, präsens_ich, präteritum_ich, perfekt_ich)
    ('spielen', 'spiele', 'spielte', 'habe gespielt'),
    ('lachen', 'lache', 'lachte', 'habe gelacht'),
    ('laufen', 'laufe', 'lief', 'bin gelaufen'),
    ('schreiben', 'schreibe', 'schrieb', 'habe geschrieben'),
    ('lesen', 'lese', 'las', 'habe gelesen'),
    ('essen', 'esse', 'aß', 'habe gegessen'),
    ('kommen', 'komme', 'kam', 'bin gekommen'),
    ('sehen', 'sehe', 'sah', 'habe gesehen'),
    ('gehen', 'gehe', 'ging', 'bin gegangen'),
    ('machen', 'mache', 'machte', 'habe gemacht'),
    ('singen', 'singe', 'sang', 'habe gesungen'),
    ('fahren', 'fahre', 'fuhr', 'bin gefahren'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final verb = _verbForms[rng.nextInt(_verbForms.length)];
    final (infinitiv, praesens, praeteritum, perfekt) = verb;

    // Welche Zeitform abfragen?
    final tenses = difficulty == 1
        ? ['Präsens', 'Präteritum'] // nur 2 für Anfänger
        : ['Präsens', 'Präteritum', 'Perfekt'];
    final targetTense = tenses[rng.nextInt(tenses.length)];

    final String correct;
    final List<String> wrongChoices;

    switch (targetTense) {
      case 'Präsens':
        correct = 'Ich $praesens.';
        wrongChoices = ['Ich $praeteritum.', 'Ich $perfekt.'];
      case 'Präteritum':
        correct = 'Ich $praeteritum.';
        wrongChoices = ['Ich $praesens.', 'Ich $perfekt.'];
      default: // Perfekt
        correct = 'Ich $perfekt.';
        wrongChoices = ['Ich $praesens.', 'Ich $praeteritum.'];
    }

    final choices = [correct, ...wrongChoices]..shuffle(rng);

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Setze "$infinitiv" in die $targetTense (ich).',
      correctAnswer: correct,
      type: TaskType.multipleChoice,
      metadata: {
        'infinitiv': infinitiv,
        'tense': targetTense,
        'choices': choices,
        'praesens': praesens,
        'praeteritum': praeteritum,
        'perfekt': perfekt,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().toLowerCase() ==
      userAnswer.toString().toLowerCase();
}

/// Wortfamilien — Kl.3
class WordFamilyTemplate extends TaskTemplate {
  const WordFamilyTemplate()
      : super(
          id: 'wortfamilien',
          subject: Subject.german,
          grade: 3,
          topic: 'wortfamilien',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Wortfamilien';

  static const _families = [
    ('spiel', ['spielen', 'Spiel', 'Spieler', 'Spielzeug', 'Spielplatz']),
    ('lauf', ['laufen', 'Läufer', 'Lauf', 'hinlaufen', 'Auflauf']),
    ('back', ['backen', 'Bäcker', 'Backform', 'Gebäck', 'aufbacken']),
    ('schreib', ['schreiben', 'Schreiber', 'Schrift', 'Beschreibung', 'vorschreiben']),
    ('mal', ['malen', 'Maler', 'Malerei', 'Gemälde', 'anmalen']),
    ('schlaf', ['schlafen', 'Schlaf', 'Schläfer', 'einschlafen', 'Schlafzimmer']),
    ('sing', ['singen', 'Sänger', 'Gesang', 'Lied', 'vorsingen']),
    ('fahr', ['fahren', 'Fahrt', 'Fahrer', 'abfahren', 'Fahrrad']),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final family = _families[rng.nextInt(_families.length)];
    final (root, members) = family;

    // Aufgabe: Welches Wort gehört NICHT zur Wortfamilie?
    final otherFamily = _families[(_families.indexOf(family) + 1) % _families.length];
    final intruder = otherFamily.$2[rng.nextInt(otherFamily.$2.length)];

    final shown = members.sublist(0, difficulty == 1 ? 3 : 4).toList();
    shown.add(intruder);
    shown.shuffle(rng);

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Welches Wort gehört NICHT zur Wortfamilie "$root"?',
      correctAnswer: intruder,
      type: TaskType.multipleChoice,
      metadata: {
        'root': root,
        'choices': shown,
        'family': members,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

/// Zusammengesetzte Nomen — Kl.3
class CompoundNounTemplate extends TaskTemplate {
  const CompoundNounTemplate()
      : super(
          id: 'zusammengesetzte_nomen',
          subject: Subject.german,
          grade: 3,
          topic: 'zusammengesetzte_nomen',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Zusammengesetzte Nomen';

  static const _compounds = [
    ('Haus', 'Tür', 'Haustür'),
    ('Schul', 'Tasche', 'Schultasche'),
    ('Buch', 'Regal', 'Bücherregal'),
    ('Blumen', 'Topf', 'Blumentopf'),
    ('Fußball', 'Platz', 'Fußballplatz'),
    ('Vogel', 'Nest', 'Vogelnest'),
    ('Bade', 'Zimmer', 'Badezimmer'),
    ('Hand', 'Schuh', 'Handschuh'),
    ('Küchen', 'Tisch', 'Küchentisch'),
    ('Schlaf', 'Zimmer', 'Schlafzimmer'),
    ('Garten', 'Tor', 'Gartentor'),
    ('Apfel', 'Baum', 'Apfelbaum'),
    ('Regen', 'Schirm', 'Regenschirm'),
    ('Sonnen', 'Brille', 'Sonnenbrille'),
    ('Fahr', 'Rad', 'Fahrrad'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final idx = rng.nextInt(_compounds.length);
    final (part1, part2, compound) = _compounds[idx];
    final taskType = rng.nextInt(2);

    if (taskType == 0) {
      // Teile zusammensetzen → Ganzes
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Was ergibt "$part1" + "$part2"?',
        correctAnswer: compound,
        type: TaskType.freeInput,
        metadata: {'part1': part1, 'part2': part2, 'compound': compound},
      );
    } else {
      // Zusammengesetztes Nomen aufteilen → Teile finden
      final otherCompounds = List.from(_compounds)..removeAt(idx);
      otherCompounds.shuffle(rng);
      final wrongChoices = otherCompounds.take(2).map((c) => c.$3).toList();
      final choices = [compound, ...wrongChoices]..shuffle(rng);

      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Welches Wort setzt sich aus "$part1" und "$part2" zusammen?',
        correctAnswer: compound,
        type: TaskType.multipleChoice,
        metadata: {'part1': part1, 'part2': part2, 'choices': choices},
      );
    }
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().toLowerCase() ==
      userAnswer.toString().toLowerCase();
}

/// Satzarten erkennen + Satzzeichen — Kl.3
class SentenceTypeTemplate extends TaskTemplate {
  const SentenceTypeTemplate()
      : super(
          id: 'satzarten',
          subject: Subject.german,
          grade: 3,
          topic: 'satzarten',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Satzarten';

  static const _sentences = [
    // (satz ohne punkt, typ, zeichen)
    ('Die Katze liegt auf dem Sofa', 'Aussagesatz', '.'),
    ('Hast du das gesehen', 'Fragesatz', '?'),
    ('Komm sofort her', 'Aufforderungssatz', '!'),
    ('Wie schön ist dieser Tag', 'Ausrufesatz', '!'),
    ('Wann kommst du nach Hause', 'Fragesatz', '?'),
    ('Bitte hilf mir', 'Aufforderungssatz', '!'),
    ('Der Hund bellt laut', 'Aussagesatz', '.'),
    ('Wie herrlich riecht diese Blume', 'Ausrufesatz', '!'),
    ('Räum bitte dein Zimmer auf', 'Aufforderungssatz', '!'),
    ('Wo wohnst du', 'Fragesatz', '?'),
    ('Das Wetter ist heute sehr schön', 'Aussagesatz', '.'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final (sentence, type, mark) = _sentences[rng.nextInt(_sentences.length)];
    final askForType = difficulty <= 2 ? true : rng.nextBool();

    if (askForType) {
      final types = ['Aussagesatz', 'Fragesatz', 'Aufforderungssatz', 'Ausrufesatz'];
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Was für ein Satz ist das?\n"$sentence"',
        correctAnswer: type,
        type: TaskType.multipleChoice,
        metadata: {
          'sentence': sentence,
          'choices': List<String>.from(types)..shuffle(rng),
          'sentenceType': type,
        },
      );
    } else {
      // Welches Satzzeichen?
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Welches Satzzeichen fehlt?\n"$sentence ___"',
        correctAnswer: mark,
        type: TaskType.multipleChoice,
        metadata: {
          'sentence': sentence,
          'choices': ['.', '?', '!'],
          'sentenceType': type,
        },
      );
    }
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

/// Diktat (vereinfacht: Wort vorgelesen, Kind schreibt) — Kl.3
/// TTS-Integration kommt in Phase 4; hier: Wort eintippen nach Anzeige
class DictationTemplate extends TaskTemplate {
  const DictationTemplate()
      : super(
          id: 'diktat',
          subject: Subject.german,
          grade: 3,
          topic: 'diktat',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Diktat';

  static const _dictationWords = [
    // (wort, Schwierigkeit 1-4)
    ('Haus', 1), ('Baum', 1), ('Hund', 1), ('Katze', 1),
    ('Schule', 2), ('Freund', 2), ('Blume', 2), ('Vogel', 2),
    ('Frühling', 3), ('Schnellzug', 3), ('Wanderung', 3),
    ('Abenteuer', 4), ('Weihnachten', 4), ('Briefkasten', 4),
    ('Schokolade', 3), ('Regenbogen', 3), ('Tischdecke', 3),
    ('Schulranzen', 4), ('Geburtstag', 3), ('Hausaufgaben', 4),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final pool = _dictationWords.where((w) => w.$2 <= difficulty).toList();
    final (word, _) = pool[rng.nextInt(pool.length)];

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Schreibe das Wort richtig auf.\n(Erst lesen, dann tippen!)',
      correctAnswer: word,
      type: TaskType.freeInput,
      metadata: {
        'word': word,
        'hint': word[0].toUpperCase() + '...', // erster Buchstabe als Hilfe
        'showThenHide': true, // Wort kurz anzeigen, dann eingeben
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().toLowerCase() ==
      userAnswer.toString().trim().toLowerCase();
}

/// Lernwörter (Sichtwörter): Lesen → merken → schreiben — Kl.3
class SightWordTemplate extends TaskTemplate {
  const SightWordTemplate()
      : super(
          id: 'lernwoerter',
          subject: Subject.german,
          grade: 3,
          topic: 'lernwoerter',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Lernwörter';

  static const _sightWords = [
    'weil', 'obwohl', 'deshalb', 'trotzdem', 'vielleicht',
    'natürlich', 'überhaupt', 'eigentlich', 'schließlich',
    'außerdem', 'deswegen', 'nämlich', 'allerdings', 'jedenfalls',
    'ungefähr', 'plötzlich', 'inzwischen', 'währenddessen',
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final word = _sightWords[rng.nextInt(_sightWords.length)];

    // Zeige das Wort, dann überdecke es — Kind schreibt aus Gedächtnis
    // Oder: Wort mit Lücken
    final hiddenIdx = rng.nextInt(word.length - 1) + 1;
    final displayed = word.substring(0, hiddenIdx) +
        '_' * (word.length - hiddenIdx).clamp(1, 3) +
        (word.length - hiddenIdx > 3 ? word.substring(hiddenIdx + 3) : '');

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Vervollständige das Lernwort:\n"$displayed"',
      correctAnswer: word,
      type: TaskType.freeInput,
      metadata: {
        'word': word,
        'displayedWord': displayed,
        'fullWord': word,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().toLowerCase().trim() ==
      userAnswer.toString().toLowerCase().trim();
}
