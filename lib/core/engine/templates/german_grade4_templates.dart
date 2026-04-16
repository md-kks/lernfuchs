/// Deutsch-Templates Klasse 4 — Grammatik & Textarbeit.
///
/// Inhalte:
/// - Vier Fälle (Kasus): Nominativ/Genitiv/Dativ/Akkusativ bestimmen oder Artikel einsetzen
/// - Satzglieder: Subjekt/Prädikat/Objekt in einem Satz identifizieren
/// - Wörtliche Rede: Satzzeichen und Anführungszeichen korrekt setzen
/// - Fehlertext: falsch geschriebenes Wort finden und korrigieren
/// - Kommasetzung: Komma in Aufzählungen und Nebensätzen
/// - Textarten: Bericht vs. Erzählung unterscheiden anhand von Merkmalen
import 'dart:math';
import '../../models/task_model.dart';
import '../../models/subject.dart';
import '../task_template.dart';

/// Die vier Fälle (Kasus) — Kl.4.
///
/// Zwei Modi je nach Schwierigkeit:
/// - Diff ≤ 2: Kasus-Namen bestimmen (Nominativ/Genitiv/Dativ/Akkusativ)
/// - Diff ≥ 3: Richtigen Artikel in Lückensatz einsetzen
class CaseTemplate extends TaskTemplate {
  const CaseTemplate()
      : super(
          id: 'vier_faelle',
          subject: Subject.german,
          grade: 4,
          topic: 'vier_faelle',
          minDifficulty: 1,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Die vier Fälle';

  static const _nounForms = [
    // (nominativ, genitiv, dativ, akkusativ, article)
    ('der Hund', 'des Hundes', 'dem Hund', 'den Hund', 'der'),
    ('die Katze', 'der Katze', 'der Katze', 'die Katze', 'die'),
    ('das Kind', 'des Kindes', 'dem Kind', 'das Kind', 'das'),
    ('der Mann', 'des Mannes', 'dem Mann', 'den Mann', 'der'),
    ('die Frau', 'der Frau', 'der Frau', 'die Frau', 'die'),
    ('der Vogel', 'des Vogels', 'dem Vogel', 'den Vogel', 'der'),
    ('die Blume', 'der Blume', 'der Blume', 'die Blume', 'die'),
    ('das Buch', 'des Buches', 'dem Buch', 'das Buch', 'das'),
  ];

  static const _caseSentences = [
    // (satz mit Lücke, kasus, antwort)
    ('____ Hund bellt laut.', 'Nominativ', 'Der'),
    ('Das Spielzeug ____ Kindes liegt auf dem Boden.', 'Genitiv', 'des'),
    ('Ich gebe ____ Hund einen Knochen.', 'Dativ', 'dem'),
    ('Wir sehen ____ Vogel auf dem Baum.', 'Akkusativ', 'den'),
    ('____ Frau liest ein Buch.', 'Nominativ', 'Die'),
    ('Das Heft ____ Schülerin liegt auf dem Tisch.', 'Genitiv', 'der'),
    ('Er hilft ____ alten Mann.', 'Dativ', 'dem'),
    ('Das Kind malt ____ Blume.', 'Akkusativ', 'die'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    if (difficulty <= 2) {
      // Kasus-Name bestimmen
      final noun = _nounForms[rng.nextInt(_nounForms.length)];
      final (nom, gen, dat, akk, _) = noun;
      final forms = [nom, gen, dat, akk];
      final caseNames = ['Nominativ', 'Genitiv', 'Dativ', 'Akkusativ'];
      final idx = rng.nextInt(4);
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'In welchem Fall steht:\n"${forms[idx]}"?',
        correctAnswer: caseNames[idx],
        type: TaskType.multipleChoice,
        metadata: {
          'form': forms[idx],
          'choices': List<String>.from(caseNames)..shuffle(rng),
        },
      );
    } else {
      // Lückentext: richtigen Artikel einsetzen
      final sent = _caseSentences[rng.nextInt(_caseSentences.length)];
      final (sentence, kasus, correct) = sent;
      // Distraktoren: andere Artikel
      final allArticles = ['der', 'die', 'das', 'dem', 'den', 'des',
          'Der', 'Die', 'Das'];
      allArticles.remove(correct);
      allArticles.shuffle(rng);
      final choices = [correct, allArticles[0], allArticles[1]]..shuffle(rng);

      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Setze den richtigen Artikel ein ($kasus):\n"$sentence"',
        correctAnswer: correct,
        type: TaskType.multipleChoice,
        metadata: {
          'sentence': sentence,
          'kasus': kasus,
          'choices': choices,
        },
      );
    }
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().toLowerCase() ==
      userAnswer.toString().toLowerCase();
}

/// Subjekt / Prädikat / Objekt — Kl.4
class SentenceElementTemplate extends TaskTemplate {
  const SentenceElementTemplate()
      : super(
          id: 'satzglieder',
          subject: Subject.german,
          grade: 4,
          topic: 'satzglieder',
          minDifficulty: 2,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Satzglieder bestimmen';

  // (satz, subjekt, prädikat, objekt)
  static const _sentences = [
    ('Der Hund bellt die Katze an.', 'Der Hund', 'bellt an', 'die Katze'),
    ('Das Kind liest ein Buch.', 'Das Kind', 'liest', 'ein Buch'),
    ('Die Lehrerin erklärt die Aufgabe.', 'Die Lehrerin', 'erklärt', 'die Aufgabe'),
    ('Mein Bruder kauft ein Fahrrad.', 'Mein Bruder', 'kauft', 'ein Fahrrad'),
    ('Die Mutter backt einen Kuchen.', 'Die Mutter', 'backt', 'einen Kuchen'),
    ('Der Schüler vergisst sein Heft.', 'Der Schüler', 'vergisst', 'sein Heft'),
    ('Das Mädchen singt ein Lied.', 'Das Mädchen', 'singt', 'ein Lied'),
    ('Der Vater fährt das Auto.', 'Der Vater', 'fährt', 'das Auto'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final sent = _sentences[rng.nextInt(_sentences.length)];
    final (sentence, subj, pred, obj) = sent;

    // Welches Satzglied abfragen?
    final elements = ['Subjekt', 'Prädikat', 'Objekt'];
    final askFor = elements[rng.nextInt(elements.length)];
    final String correct;
    final List<String> wrong;

    switch (askFor) {
      case 'Subjekt':
        correct = subj;
        wrong = [pred, obj];
      case 'Prädikat':
        correct = pred;
        wrong = [subj, obj];
      default:
        correct = obj;
        wrong = [subj, pred];
    }

    final choices = [correct, ...wrong]..shuffle(rng);

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Was ist das $askFor in diesem Satz?\n"$sentence"',
      correctAnswer: correct,
      type: TaskType.multipleChoice,
      metadata: {
        'sentence': sentence,
        'askFor': askFor,
        'choices': choices,
        'subjekt': subj,
        'praedikat': pred,
        'objekt': obj,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().toLowerCase() ==
      userAnswer.toString().toLowerCase();
}

/// Wörtliche Rede — Satzzeichen setzen — Kl.4
class DirectSpeechTemplate extends TaskTemplate {
  const DirectSpeechTemplate()
      : super(
          id: 'woertliche_rede',
          subject: Subject.german,
          grade: 4,
          topic: 'woertliche_rede',
          minDifficulty: 2,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Wörtliche Rede';

  // (satz mit Lücken für Satzzeichen, korrekte Version)
  static const _sentences = [
    (
      'Mama rief ___ Komm sofort nach Hause ___ .',
      '„Komm sofort nach Hause!"',
      'Mama rief: „Komm sofort nach Hause!"',
    ),
    (
      'Tom fragte ___ Darf ich mitspielen ___ ?',
      '„Darf ich mitspielen?"',
      'Tom fragte: „Darf ich mitspielen?"',
    ),
    (
      'Sie antwortete ___ Natürlich, gerne ___ .',
      '„Natürlich, gerne!"',
      'Sie antwortete: „Natürlich, gerne!"',
    ),
    (
      'Der Lehrer sagte ___ Öffnet eure Bücher ___ .',
      '„Öffnet eure Bücher!"',
      'Der Lehrer sagte: „Öffnet eure Bücher!"',
    ),
    (
      'Lisa rief ___ Warte auf mich ___ !',
      '„Warte auf mich!"',
      'Lisa rief: „Warte auf mich!"',
    ),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final sent = _sentences[rng.nextInt(_sentences.length)];
    final (withGaps, speech, correct) = sent;

    if (difficulty <= 2) {
      // Nur die Anführungszeichen bestimmen
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Welche Satzzeichen fehlen?\n"$withGaps"',
        correctAnswer: speech,
        type: TaskType.multipleChoice,
        metadata: {
          'sentence': withGaps,
          'choices': [
            speech,
            speech.replaceAll('„', '"').replaceAll('"', '"'),
            '(' + speech + ')',
          ]..shuffle(rng),
        },
      );
    } else {
      // Ganzen Satz richtig erkennen
      final wrong1 = correct.replaceAll(':', '');
      final wrong2 = correct.replaceAll('„', '').replaceAll('"', '');
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Welcher Satz hat die richtigen Satzzeichen?',
        correctAnswer: correct,
        type: TaskType.multipleChoice,
        metadata: {
          'choices': [correct, wrong1, wrong2]..shuffle(rng),
        },
      );
    }
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString() == userAnswer.toString();
}

/// Fehlertext korrigieren — Kl.4
class ErrorTextTemplate extends TaskTemplate {
  const ErrorTextTemplate()
      : super(
          id: 'fehlertext',
          subject: Subject.german,
          grade: 4,
          topic: 'fehlertext',
          minDifficulty: 2,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Fehlertext korrigieren';

  static const _errorTexts = [
    // (fehlerhaftes Wort, korrektes Wort, Kontext-Satz mit Fehler)
    ('das', 'dass', 'Ich glaube, das er kommt.'),
    ('Hundt', 'Hund', 'Der Hundt bellt laut.'),
    ('schreiben', 'Schreiben', 'Das schreiben fällt mir schwer.'),
    ('ihr', 'Ihr', 'ihr habt gewonnen!'),
    ('Fahrrad', 'Fahrrad', 'Das Fahr-rad steht draußen.'),
    ('wen', 'wenn', 'Wen du magst, kannst du kommen.'),
    ('seit', 'seid', 'Seit ihr fertig?'),
    ('wieder', 'wider', 'Das spricht wider meinen Willen.'),
    ('wahr', 'war', 'Das Wetter wahr schön.'),
    ('lern', 'Lern', 'lern fleißig für die Schule!'),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final (wrong, correct, sentence) = _errorTexts[rng.nextInt(_errorTexts.length)];

    // Distraktoren
    final otherCorrect = _errorTexts
        .where((e) => e.$2 != correct)
        .map((e) => e.$2)
        .take(2)
        .toList();
    final choices = [correct, ...otherCorrect]..shuffle(rng);

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Finde den Fehler und korrigiere ihn!\n"$sentence"',
      correctAnswer: correct,
      type: TaskType.multipleChoice,
      metadata: {
        'sentence': sentence,
        'errorWord': wrong,
        'correctWord': correct,
        'choices': choices,
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer.toString().toLowerCase() ==
      userAnswer.toString().toLowerCase();
}

/// Kommasetzung — Kl.4
class CommaPunctuationTemplate extends TaskTemplate {
  const CommaPunctuationTemplate()
      : super(
          id: 'kommasetzung',
          subject: Subject.german,
          grade: 4,
          topic: 'kommasetzung',
          minDifficulty: 2,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Kommasetzung';

  static const _commaExercises = [
    // (satz mit ___ für Komma-Position, correctAnswer, hint)
    (
      'Ich mag Äpfel___ Birnen und Bananen.',
      ',',
      'Aufzählung',
    ),
    (
      'Obwohl es regnet___ gehen wir spazieren.',
      ',',
      'Nebensatz',
    ),
    (
      'Er läuft___ springt und singt.',
      ',',
      'Aufzählung',
    ),
    (
      'Weil ich müde bin___ gehe ich schlafen.',
      ',',
      'Nebensatz',
    ),
    (
      'Das Buch___ das ich lese___ ist spannend.',
      ',',
      'Relativsatz',
    ),
    (
      'Sie kauft Brot___ Butter und Milch.',
      ',',
      'Aufzählung',
    ),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final ex = _commaExercises[rng.nextInt(_commaExercises.length)];
    final (sentence, correct, hint) = ex;

    // Zähle Lücken
    final gaps = '___'.allMatches(sentence).length;
    final displayed = sentence.replaceAll('___', ' ___ ');

    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Gehört hier ein Komma? ($hint)\n"$displayed"',
      correctAnswer: correct == ',' ? 'Ja, Komma' : 'Kein Komma',
      type: TaskType.multipleChoice,
      metadata: {
        'sentence': sentence,
        'gaps': gaps,
        'hint': hint,
        'choices': ['Ja, Komma', 'Kein Komma'],
      },
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}

/// Bericht vs. Erzählung — Kl.4
class TextTypeTemplate extends TaskTemplate {
  const TextTypeTemplate()
      : super(
          id: 'textarten',
          subject: Subject.german,
          grade: 4,
          topic: 'textarten',
          minDifficulty: 2,
          maxDifficulty: 4,
        );

  @override
  String get displayName => 'Bericht & Erzählung';

  static const _textExamples = [
    // (textausschnitt, typ, merkmale)
    (
      'Am Montag, den 5. März, fand in der Turnhalle der Schule ein Fußballturnier statt. Es nahmen sechs Mannschaften teil. Die Klasse 4a gewann das Finale 3:1 gegen die Klasse 4b.',
      'Bericht',
      'sachlich, Datum, W-Fragen',
    ),
    (
      'Es war ein stürmischer Herbsttag, als Lena plötzlich ein seltsames Geräusch hörte. Neugierig schlich sie zur Scheune und öffnete vorsichtig die knarrende Tür…',
      'Erzählung',
      'spannend, direkte Rede, Gefühle',
    ),
    (
      'Gestern Nachmittag gegen 15 Uhr brach im Supermarkt in der Hauptstraße ein Feuer aus. Die Feuerwehr war innerhalb von zehn Minuten vor Ort. Verletzt wurde niemand.',
      'Bericht',
      'sachlich, Uhrzeit, Ort',
    ),
    (
      '"Endlich!", rief Max und rannte auf die Schaukel zu. Der Wind pfiff ihm ums Ohr und er schloss glücklich die Augen.',
      'Erzählung',
      'direkte Rede, Gefühle, lebendig',
    ),
  ];

  @override
  TaskModel generate(int difficulty, Random rng) {
    final example = _textExamples[rng.nextInt(_textExamples.length)];
    final (text, typ, merkmale) = example;

    if (difficulty <= 2) {
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Lies den Text. Ist das ein Bericht oder eine Erzählung?',
        correctAnswer: typ,
        type: TaskType.multipleChoice,
        metadata: {
          'text': text,
          'choices': ['Bericht', 'Erzählung'],
          'merkmale': merkmale,
        },
      );
    } else {
      // Welches Merkmal passt?
      final allFeatures = _textExamples.map((e) => e.$3).toList();
      allFeatures.remove(merkmale);
      allFeatures.shuffle(rng);
      final choices = [merkmale, allFeatures[0], allFeatures[1]]..shuffle(rng);
      return makeTask(
        rng: rng,
        difficulty: difficulty,
        question: 'Welche Merkmale hat dieser $typ?\n"${text.substring(0, text.length.clamp(0, 80))}…"',
        correctAnswer: merkmale,
        type: TaskType.multipleChoice,
        metadata: {
          'text': text,
          'typ': typ,
          'choices': choices,
        },
      );
    }
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      task.correctAnswer == userAnswer;
}
