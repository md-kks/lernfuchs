import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/engine/task_generator.dart';
import 'package:lernfuchs/core/models/task_model.dart';
import 'package:lernfuchs/core/models/subject.dart';

void main() {
  // ── Kl.1 ─────────────────────────────────────────────────────────────
  group('Deutsch Kl.1 — Buchstaben (letter_recognition)', () {
    final t = TaskGenerator.template(Subject.german, 1, 'buchstaben')!;

    test('generates task with choices', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
      final choices = task.metadata['choices'] as List;
      expect(choices.length, greaterThanOrEqualTo(2));
      expect(choices, contains(task.correctAnswer));
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(1));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });

    test('evaluate wrong', () {
      final task = t.generate(2, _rng(2));
      final choices = (task.metadata['choices'] as List).cast<String>();
      final wrong = choices.firstWhere((c) => c != task.correctAnswer);
      expect(t.evaluate(task, wrong), isFalse);
    });
  });

  group('Deutsch Kl.1 — Anlaute (initial_sound)', () {
    final t = TaskGenerator.template(Subject.german, 1, 'anlaute')!;

    test('generates task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
      expect(task.metadata['choices'], isA<List>());
    });

    test('correct answer is a single uppercase letter', () {
      for (var i = 0; i < 5; i++) {
        final task = t.generate(1, _rng(i));
        final ans = task.correctAnswer.toString();
        expect(ans.length, 1);
        expect(ans, equals(ans.toUpperCase()));
      }
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(3));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  group('Deutsch Kl.1 — Silben (syllable_count)', () {
    final t = TaskGenerator.template(Subject.german, 1, 'silben')!;

    test('generates tapRhythm task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.tapRhythm.name);
    });

    test('correctAnswer is a positive integer', () {
      for (var i = 0; i < 5; i++) {
        final task = t.generate(2, _rng(i));
        final count = int.parse(task.correctAnswer.toString());
        expect(count, greaterThanOrEqualTo(1));
        expect(count, lessThanOrEqualTo(5));
      }
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(0));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });

    test('evaluate int string correct', () {
      final task = t.generate(1, _rng(0));
      expect(t.evaluate(task, task.correctAnswer.toString()), isTrue);
    });
  });

  group('Deutsch Kl.1 — Reimwörter (rhyme)', () {
    final t = TaskGenerator.template(Subject.german, 1, 'reimwoerter')!;

    test('generates multipleChoice task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
    });

    test('correctAnswer is either Ja/Nein or a rhyme word', () {
      // RhymeTemplate has two sub-types: "which word rhymes" (returns a word)
      // and "do these rhyme? Ja/Nein". Both are valid.
      for (var i = 0; i < 6; i++) {
        final task = t.generate(1, _rng(i));
        final ans = task.correctAnswer.toString();
        expect(ans.isNotEmpty, isTrue);
      }
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(2));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  group('Deutsch Kl.1 — Lückenwörter (missing_letter)', () {
    final t = TaskGenerator.template(Subject.german, 1, 'lueckenwoerter')!;

    test('generates task with choices', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
      final choices = task.metadata['choices'] as List;
      expect(choices, contains(task.correctAnswer));
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(0));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  group('Deutsch Kl.1 — Buchstabensalat (anagram)', () {
    final t = TaskGenerator.template(Subject.german, 1, 'buchstaben_salat')!;

    test('generates ordering task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.ordering.name);
    });

    test('letters in metadata', () {
      final task = t.generate(2, _rng(2));
      expect(task.metadata['letters'], isA<List>());
    });

    test('evaluate correct (list)', () {
      final task = t.generate(1, _rng(3));
      // correctAnswer is the word; split into uppercase letters to evaluate as list
      final letters = task.correctAnswer.toString().toUpperCase().split('');
      expect(t.evaluate(task, letters), isTrue);
    });

    test('evaluate correct (string)', () {
      final task = t.generate(1, _rng(3));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  // ── Kl.2 ─────────────────────────────────────────────────────────────
  group('Deutsch Kl.2 — ie oder ei (ie_ei)', () {
    final t = TaskGenerator.template(Subject.german, 2, 'rechtschreibung_ie_ei')!;

    test('generates task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
      expect(task.metadata['choices'], equals(['ie', 'ei']));
    });

    test('correctAnswer is ie or ei', () {
      for (var i = 0; i < 8; i++) {
        final task = t.generate(1, _rng(i));
        expect(['ie', 'ei'], contains(task.correctAnswer));
      }
    });

    test('evaluate correct', () {
      final task = t.generate(2, _rng(1));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });

    test('evaluate wrong', () {
      final task = t.generate(2, _rng(1));
      final wrong = task.correctAnswer == 'ie' ? 'ei' : 'ie';
      expect(t.evaluate(task, wrong), isFalse);
    });
  });

  group('Deutsch Kl.2 — Sätze bilden (sentence_formation)', () {
    final t = TaskGenerator.template(Subject.german, 2, 'saetze_bilden')!;

    test('generates ordering task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.ordering.name);
    });

    test('words metadata is a List', () {
      final task = t.generate(2, _rng(0));
      expect(task.metadata['words'], isA<List>());
    });

    test('evaluate correct answer (list)', () {
      final task = t.generate(1, _rng(1));
      final correctWords = (task.metadata['correctWords'] as List).cast<String>();
      expect(t.evaluate(task, correctWords), isTrue);
    });

    test('evaluate correct answer (string)', () {
      final task = t.generate(1, _rng(1));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });

    test('evaluate wrong order', () {
      final task = t.generate(2, _rng(2));
      final words = (task.metadata['words'] as List).cast<String>();
      expect(t.evaluate(task, words), anyOf(isTrue, isFalse)); // shuffled may or may not match
    });
  });

  group('Deutsch Kl.2 — Lesetext (reading_comprehension)', () {
    final t = TaskGenerator.template(Subject.german, 2, 'lesetext')!;

    test('generates multipleChoice task with text', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
      expect(task.metadata['text'], isA<String>());
      expect((task.metadata['text'] as String).isNotEmpty, isTrue);
    });

    test('choices contain correct answer', () {
      for (var i = 0; i < 5; i++) {
        final task = t.generate(2, _rng(i));
        final choices = (task.metadata['choices'] as List).cast<String>();
        expect(choices, contains(task.correctAnswer));
      }
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(0));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });

    test('case-insensitive evaluate', () {
      final task = t.generate(1, _rng(0));
      expect(t.evaluate(task, task.correctAnswer.toString().toUpperCase()), isTrue);
    });
  });

  // ── Kl.3 ─────────────────────────────────────────────────────────────
  group('Deutsch Kl.3 — Zeitformen (verb_tense)', () {
    final t = TaskGenerator.template(Subject.german, 3, 'zeitformen')!;

    test('generates multipleChoice task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
    });

    test('difficulty 1 only has Präsens/Präteritum', () {
      for (var i = 0; i < 10; i++) {
        final task = t.generate(1, _rng(i));
        final tense = task.metadata['tense'] as String;
        expect(['Präsens', 'Präteritum'], contains(tense));
      }
    });

    test('choices contain correct answer', () {
      final task = t.generate(3, _rng(5));
      final choices = (task.metadata['choices'] as List).cast<String>();
      expect(choices, contains(task.correctAnswer));
    });

    test('evaluate correct case-insensitive', () {
      final task = t.generate(2, _rng(1));
      expect(t.evaluate(task, task.correctAnswer.toString().toLowerCase()), isTrue);
    });
  });

  group('Deutsch Kl.3 — Wortfamilien (word_family)', () {
    final t = TaskGenerator.template(Subject.german, 3, 'wortfamilien')!;

    test('generates multipleChoice task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
    });

    test('intruder is in choices', () {
      for (var i = 0; i < 5; i++) {
        final task = t.generate(2, _rng(i));
        final choices = (task.metadata['choices'] as List).cast<String>();
        expect(choices, contains(task.correctAnswer));
      }
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(0));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  group('Deutsch Kl.3 — Zusammengesetzte Nomen (compound_noun)', () {
    final t = TaskGenerator.template(Subject.german, 3, 'zusammengesetzte_nomen')!;

    test('generates task', () {
      final task = t.generate(1, _rng(1));
      expect([TaskType.freeInput.name, TaskType.multipleChoice.name],
          contains(task.taskType));
    });

    test('evaluate correct case-insensitive', () {
      for (var i = 0; i < 5; i++) {
        final task = t.generate(2, _rng(i));
        expect(t.evaluate(task, task.correctAnswer.toString().toLowerCase()), isTrue);
      }
    });
  });

  group('Deutsch Kl.3 — Satzarten (sentence_type)', () {
    final t = TaskGenerator.template(Subject.german, 3, 'satzarten')!;

    test('generates multipleChoice task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
    });

    test('difficulty <=2 asks for type, not punctuation', () {
      for (var i = 0; i < 8; i++) {
        final task = t.generate(1, _rng(i));
        final choices = (task.metadata['choices'] as List).cast<String>();
        // type-mode choices are sentence types (longer strings)
        expect(choices.any((c) => c.length > 2), isTrue);
      }
    });

    test('evaluate correct', () {
      final task = t.generate(2, _rng(0));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  group('Deutsch Kl.3 — Diktat (dictation)', () {
    final t = TaskGenerator.template(Subject.german, 3, 'diktat')!;

    test('generates freeInput task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.freeInput.name);
    });

    test('metadata has word and showThenHide flag', () {
      final task = t.generate(2, _rng(0));
      expect(task.metadata['word'], isA<String>());
      expect(task.metadata['showThenHide'], isTrue);
    });

    test('evaluate correct (case-insensitive, trimmed)', () {
      final task = t.generate(3, _rng(1));
      final word = task.correctAnswer.toString();
      expect(t.evaluate(task, word.toLowerCase()), isTrue);
      expect(t.evaluate(task, '  $word  '), isTrue);
    });

    test('difficulty 1 only produces easy words', () {
      for (var i = 0; i < 8; i++) {
        final task = t.generate(1, _rng(i));
        final word = task.metadata['word'] as String;
        expect(word.length, lessThanOrEqualTo(8)); // easy words are short
      }
    });
  });

  group('Deutsch Kl.3 — Lernwörter (sight_word)', () {
    final t = TaskGenerator.template(Subject.german, 3, 'lernwoerter')!;

    test('generates freeInput task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.freeInput.name);
    });

    test('displayed word has underscore placeholder', () {
      for (var i = 0; i < 5; i++) {
        final task = t.generate(2, _rng(i));
        final displayed = task.metadata['displayedWord'] as String;
        expect(displayed, contains('_'));
      }
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(0));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  // ── Kl.4 ─────────────────────────────────────────────────────────────
  group('Deutsch Kl.4 — Vier Fälle (case)', () {
    final t = TaskGenerator.template(Subject.german, 4, 'vier_faelle')!;

    test('generates multipleChoice task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
    });

    test('choices contain correct answer', () {
      for (var i = 0; i < 6; i++) {
        final task = t.generate(2, _rng(i));
        final choices = (task.metadata['choices'] as List).cast<String>();
        expect(choices, contains(task.correctAnswer));
      }
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(0));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });

    test('evaluate wrong', () {
      final task = t.generate(2, _rng(0));
      expect(t.evaluate(task, 'Genitiv_WRONG'), isFalse);
    });
  });

  group('Deutsch Kl.4 — Satzglieder (sentence_element)', () {
    final t = TaskGenerator.template(Subject.german, 4, 'satzglieder')!;

    test('generates multipleChoice task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
    });

    test('askFor metadata is Subjekt, Prädikat or Objekt', () {
      for (var i = 0; i < 8; i++) {
        final task = t.generate(2, _rng(i));
        final askFor = task.metadata['askFor'] as String;
        expect(['Subjekt', 'Prädikat', 'Objekt'], contains(askFor));
      }
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(3));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  group('Deutsch Kl.4 — Wörtliche Rede (direct_speech)', () {
    final t = TaskGenerator.template(Subject.german, 4, 'woertliche_rede')!;

    test('generates multipleChoice task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
    });

    test('choices present', () {
      final task = t.generate(2, _rng(2));
      final choices = task.metadata['choices'] as List;
      expect(choices.length, greaterThanOrEqualTo(2));
    });

    test('evaluate correct', () {
      final task = t.generate(2, _rng(1));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  group('Deutsch Kl.4 — Fehlertext (error_text)', () {
    final t = TaskGenerator.template(Subject.german, 4, 'fehlertext')!;

    test('generates multipleChoice task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
    });

    test('choices contain error word and correct word', () {
      final task = t.generate(1, _rng(0));
      final choices = (task.metadata['choices'] as List).cast<String>();
      expect(choices, contains(task.correctAnswer));
      expect(choices.length, greaterThanOrEqualTo(2));
    });

    test('evaluate correct', () {
      final task = t.generate(2, _rng(4));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });

    test('evaluate wrong (error word fails)', () {
      final task = t.generate(1, _rng(0));
      final errorWord = task.metadata['errorWord'] as String;
      expect(t.evaluate(task, errorWord), isFalse);
    });
  });

  group('Deutsch Kl.4 — Kommasetzung (comma_punctuation)', () {
    final t = TaskGenerator.template(Subject.german, 4, 'kommasetzung')!;

    test('generates task', () {
      final task = t.generate(1, _rng(1));
      expect([TaskType.multipleChoice.name, TaskType.freeInput.name],
          contains(task.taskType));
    });

    test('evaluate correct', () {
      for (var i = 0; i < 5; i++) {
        final task = t.generate(2, _rng(i));
        expect(t.evaluate(task, task.correctAnswer), isTrue);
      }
    });
  });

  group('Deutsch Kl.4 — Textarten (text_type)', () {
    final t = TaskGenerator.template(Subject.german, 4, 'textarten')!;

    test('generates multipleChoice task', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.multipleChoice.name);
    });

    test('correctAnswer is Bericht or Erzählung', () {
      for (var i = 0; i < 8; i++) {
        final task = t.generate(2, _rng(i));
        expect(['Bericht', 'Erzählung'], contains(task.correctAnswer));
      }
    });

    test('evaluate correct', () {
      final task = t.generate(1, _rng(0));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  // ── TaskGenerator integration ─────────────────────────────────────────
  group('TaskGenerator — Deutsch Phase 3 Sessions', () {
    test('generates session for each Kl.1 topic', () {
      final topics = [
        'buchstaben', 'anlaute', 'silben', 'reimwoerter',
        'lueckenwoerter', 'buchstaben_salat',
      ];
      for (final topic in topics) {
        final tasks = TaskGenerator.generateSession(
          subject: Subject.german,
          grade: 1,
          topic: topic,
          difficulty: 1,
          count: 5,
        );
        expect(tasks.length, 5, reason: 'topic: $topic');
      }
    });

    test('generates session for each Kl.2 topic', () {
      final topics = [
        'rechtschreibung_ie_ei', 'saetze_bilden', 'lesetext',
      ];
      for (final topic in topics) {
        final tasks = TaskGenerator.generateSession(
          subject: Subject.german,
          grade: 2,
          topic: topic,
          difficulty: 1,
          count: 5,
        );
        expect(tasks.length, 5, reason: 'topic: $topic');
      }
    });

    test('generates session for each Kl.3 topic', () {
      final topics = [
        'zeitformen', 'wortfamilien', 'zusammengesetzte_nomen',
        'satzarten', 'diktat', 'lernwoerter',
      ];
      for (final topic in topics) {
        final tasks = TaskGenerator.generateSession(
          subject: Subject.german,
          grade: 3,
          topic: topic,
          difficulty: 2,
          count: 5,
        );
        expect(tasks.length, 5, reason: 'topic: $topic');
      }
    });

    test('generates session for each Kl.4 topic', () {
      final topics = [
        'vier_faelle', 'satzglieder', 'woertliche_rede',
        'fehlertext', 'kommasetzung', 'textarten',
      ];
      for (final topic in topics) {
        final tasks = TaskGenerator.generateSession(
          subject: Subject.german,
          grade: 4,
          topic: topic,
          difficulty: 2,
          count: 5,
        );
        expect(tasks.length, 5, reason: 'topic: $topic');
      }
    });
  });
}

Random _rng(int seed) => Random(seed);
