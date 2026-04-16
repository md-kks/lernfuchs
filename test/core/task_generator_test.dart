import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/engine/task_generator.dart';
import 'package:lernfuchs/core/engine/evaluator.dart';
import 'package:lernfuchs/core/engine/difficulty.dart';
import 'package:lernfuchs/core/engine/templates/math_basic_templates.dart';
import 'package:lernfuchs/core/engine/templates/german_basic_templates.dart';
import 'package:lernfuchs/core/models/subject.dart';
import 'package:lernfuchs/core/models/task_model.dart';

void main() {
  group('AdditionTemplate', () {
    const template = AdditionTemplate(grade: 1);

    test('generiert Aufgaben mit korrekten Ergebnissen', () {
      final rng = Random(42);
      for (int i = 0; i < 50; i++) {
        final task = template.generate(2, rng);
        final a = task.metadata['a'] as int;
        final b = task.metadata['b'] as int;
        expect(task.correctAnswer, equals(a + b));
      }
    });

    test('evaluiert richtige Antwort korrekt', () {
      final task = template.generate(1, Random(1));
      expect(template.evaluate(task, task.correctAnswer), isTrue);
    });

    test('evaluiert falsche Antwort korrekt', () {
      final task = template.generate(1, Random(1));
      expect(template.evaluate(task, (task.correctAnswer as int) + 1), isFalse);
    });

    test('Ergebnis ist nie negativ', () {
      final rng = Random(99);
      for (int i = 0; i < 100; i++) {
        final task = template.generate(3, rng);
        expect(task.correctAnswer as int, greaterThanOrEqualTo(0));
      }
    });

    test('Schwierigkeitsgrad 1 bleibt ≤ 10', () {
      final rng = Random(7);
      for (int i = 0; i < 50; i++) {
        final task = template.generate(1, rng);
        expect(task.correctAnswer as int, lessThanOrEqualTo(10));
      }
    });
  });

  group('SubtractionTemplate', () {
    const template = SubtractionTemplate(grade: 1);

    test('Ergebnis ist nie negativ', () {
      final rng = Random(42);
      for (int i = 0; i < 100; i++) {
        final task = template.generate(2, rng);
        expect(task.correctAnswer as int, greaterThanOrEqualTo(0));
      }
    });

    test('evaluiert korrekt', () {
      final task = template.generate(2, Random(5));
      expect(template.evaluate(task, task.correctAnswer), isTrue);
      expect(template.evaluate(task, -99), isFalse);
    });
  });

  group('ComparisonTemplate', () {
    const template = ComparisonTemplate();

    test('korrekte Symbole für alle Fälle', () {
      // Wir testen mit bekannten Seed-Ergebnissen
      final rng = Random(0);
      for (int i = 0; i < 50; i++) {
        final task = template.generate(1, rng);
        final a = task.metadata['a'] as int;
        final b = task.metadata['b'] as int;
        final expected = a > b ? '>' : (a < b ? '<' : '=');
        expect(task.correctAnswer, equals(expected));
      }
    });
  });

  group('TimesTableTemplate', () {
    const template = TimesTableTemplate();

    test('a × b = correctAnswer', () {
      final rng = Random(42);
      for (int i = 0; i < 50; i++) {
        final task = template.generate(3, rng);
        final a = task.metadata['a'] as int;
        final b = task.metadata['b'] as int;
        expect(task.correctAnswer, equals(a * b));
      }
    });
  });

  group('NumberSequenceTemplate', () {
    const template = NumberSequenceTemplate();

    test('nächstes Element stimmt mit Schritt überein', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = template.generate(2, rng);
        final sequence = (task.metadata['sequence'] as List).cast<int>();
        final step = task.metadata['step'] as int;
        expect(task.correctAnswer, equals(sequence.last + step));
      }
    });
  });

  group('DivisionWithRemainderTemplate', () {
    const template = DivisionWithRemainderTemplate();

    test('dividend = divisor * quotient + rest', () {
      final rng = Random(42);
      for (int i = 0; i < 50; i++) {
        final task = template.generate(3, rng);
        final dividend = task.metadata['dividend'] as int;
        final divisor = task.metadata['divisor'] as int;
        final quotient = task.metadata['quotient'] as int;
        final remainder = task.metadata['remainder'] as int;
        expect(dividend, equals(divisor * quotient + remainder));
        expect(remainder, lessThan(divisor));
      }
    });

    test('richtige Antwort wird akzeptiert', () {
      final task = template.generate(3, Random(1));
      final correct = task.correctAnswer as List;
      expect(template.evaluate(task, correct), isTrue);
    });
  });

  group('ArticleTemplate', () {
    const template = ArticleTemplate();

    test('correctAnswer ist einer von der/die/das', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final task = template.generate(1, rng);
        expect(
          ['der', 'die', 'das'].contains(task.correctAnswer),
          isTrue,
        );
      }
    });
  });

  group('AlphabetSortTemplate', () {
    const template = AlphabetSortTemplate();

    test('korrekte Reihenfolge ist alphabetisch', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final task = template.generate(2, rng);
        final sorted = task.correctAnswer as List;
        final copy = List<String>.from(sorted)..sort();
        expect(sorted, equals(copy));
      }
    });

    test('evaluate: korrekte Liste akzeptiert', () {
      final task = template.generate(1, Random(1));
      expect(template.evaluate(task, task.correctAnswer), isTrue);
    });

    test('evaluate: falsche Reihenfolge abgelehnt', () {
      final task = template.generate(1, Random(1));
      final wrong = (task.correctAnswer as List).reversed.toList();
      expect(template.evaluate(task, wrong), isFalse);
    });
  });

  group('DasDassTemplate', () {
    const template = DasDassTemplate();

    test('correctAnswer ist "Das" oder "dass"', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final task = template.generate(2, rng);
        expect(
          ['Das', 'dass'].contains(task.correctAnswer),
          isTrue,
        );
      }
    });
  });

  group('Evaluator', () {
    test('freeInput: integer Vergleich', () {
      final task = TaskModel(
        id: 'test',
        subject: 'math',
        grade: 1,
        topic: 'addition',
        question: '2 + 3 = ?',
        taskType: TaskType.freeInput.name,
        correctAnswer: 5,
      );
      expect(Evaluator.evaluate(task, 5), isTrue);
      expect(Evaluator.evaluate(task, 4), isFalse);
    });

    test('freeInput: String Vergleich (Groß/Klein ignoriert)', () {
      final task = TaskModel(
        id: 'test',
        subject: 'german',
        grade: 2,
        topic: 'einzahl_mehrzahl',
        question: 'Mehrzahl von Hund?',
        taskType: TaskType.freeInput.name,
        correctAnswer: 'Hunde',
      );
      expect(Evaluator.evaluate(task, 'Hunde'), isTrue);
      expect(Evaluator.evaluate(task, 'hunde'), isTrue);
      expect(Evaluator.evaluate(task, 'Katzen'), isFalse);
    });

    test('ordering: Reihenfolge korrekt bewertet', () {
      final task = TaskModel(
        id: 'test',
        subject: 'german',
        grade: 2,
        topic: 'abc_sortieren',
        question: 'Sortiere!',
        taskType: TaskType.ordering.name,
        correctAnswer: ['Apfel', 'Birne', 'Erdbeere'],
      );
      expect(Evaluator.evaluate(task, ['Apfel', 'Birne', 'Erdbeere']), isTrue);
      expect(Evaluator.evaluate(task, ['Birne', 'Apfel', 'Erdbeere']), isFalse);
    });
  });

  group('DifficultyEngine', () {
    test('erhöht Schwierigkeit bei >90% korrekt', () {
      final results = [1, 1, 1, 1, 1]; // 100%
      expect(
        DifficultyEngine.nextDifficulty(
            recentResults: results, currentDifficulty: 2),
        equals(3),
      );
    });

    test('verringert Schwierigkeit bei <50% korrekt', () {
      final results = [0, 0, 0, 1, 0]; // 20%
      expect(
        DifficultyEngine.nextDifficulty(
            recentResults: results, currentDifficulty: 3),
        equals(2),
      );
    });

    test('behält Schwierigkeit bei mittlerer Erfolgsrate', () {
      final results = [1, 0, 1, 1, 0]; // 60%
      expect(
        DifficultyEngine.nextDifficulty(
            recentResults: results, currentDifficulty: 2),
        equals(2),
      );
    });

    test('unterschreitet nicht Schwierigkeit 1', () {
      final results = [0, 0, 0, 0, 0]; // 0%
      expect(
        DifficultyEngine.nextDifficulty(
            recentResults: results, currentDifficulty: 1),
        equals(1),
      );
    });

    test('überschreitet nicht Schwierigkeit 5', () {
      final results = [1, 1, 1, 1, 1]; // 100%
      expect(
        DifficultyEngine.nextDifficulty(
            recentResults: results, currentDifficulty: 5),
        equals(5),
      );
    });
  });

  group('TaskGenerator', () {
    test('generiert 10 Aufgaben für Addition Kl.1', () {
      final tasks = TaskGenerator.generateSession(
        subject: Subject.math,
        grade: 1,
        topic: 'addition_bis_10',
        difficulty: 2,
        count: 10,
        seed: 42,
      );
      expect(tasks.length, equals(10));
    });

    test('Reproduzierbarkeit mit gleichem Seed', () {
      final tasks1 = TaskGenerator.generateSession(
        subject: Subject.math,
        grade: 1,
        topic: 'addition_bis_10',
        difficulty: 2,
        count: 5,
        seed: 123,
      );
      final tasks2 = TaskGenerator.generateSession(
        subject: Subject.math,
        grade: 1,
        topic: 'addition_bis_10',
        difficulty: 2,
        count: 5,
        seed: 123,
      );
      for (int i = 0; i < tasks1.length; i++) {
        expect(tasks1[i].correctAnswer, equals(tasks2[i].correctAnswer));
      }
    });

    test('wirft Fehler für unbekanntes Thema', () {
      expect(
        () => TaskGenerator.generateSession(
          subject: Subject.math,
          grade: 1,
          topic: 'gibts_nicht',
          difficulty: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
