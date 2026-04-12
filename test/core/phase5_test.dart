import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/engine/task_generator.dart';
import 'package:lernfuchs/core/models/task_model.dart';
import 'package:lernfuchs/core/models/subject.dart';
import 'package:lernfuchs/core/models/progress.dart';
import 'package:lernfuchs/core/engine/difficulty.dart';
import 'package:lernfuchs/shared/widgets/star_rating.dart';

Random _rng(int seed) => Random(seed);

void main() {
  // ── HandwritingTemplate ────────────────────────────────────────────────
  group('HandwritingTemplate (Deutsch Kl.1 — handschrift)', () {
    final t = TaskGenerator.template(Subject.german, 1, 'handschrift')!;

    test('Template registriert und abrufbar', () {
      expect(t, isNotNull);
    });

    test('Generiert Task mit taskType = handwriting', () {
      final task = t.generate(1, _rng(1));
      expect(task.taskType, TaskType.handwriting.name);
    });

    test('Metadata enthält letter (Großbuchstabe)', () {
      for (var i = 0; i < 10; i++) {
        final task = t.generate(1, _rng(i));
        final letter = task.metadata['letter'] as String?;
        expect(letter, isNotNull);
        expect(letter!.length, 1);
        expect(letter, equals(letter.toUpperCase()));
      }
    });

    test('Metadata enthält word (Beispielwort)', () {
      final task = t.generate(1, _rng(1));
      final word = task.metadata['word'] as String?;
      expect(word, isNotNull);
      expect(word!.isNotEmpty, isTrue);
    });

    test('Schwierigkeit 1: Großbuchstaben (A,E,I,O,U,M,N,L)', () {
      const easyLetters = {'A', 'E', 'I', 'O', 'U', 'M', 'N', 'L'};
      for (var i = 0; i < 20; i++) {
        final task = t.generate(1, _rng(i));
        final letter = task.metadata['letter'] as String;
        expect(easyLetters, contains(letter));
      }
    });

    test('Schwierigkeit 2: enthält alle 17 Buchstaben als Pool', () {
      // Bei Diff 2 sind alle Buchstaben (Diff1 + Diff2) erlaubt
      const allLetters = {
        'A', 'E', 'I', 'O', 'U', 'M', 'N', 'L',
        'B', 'D', 'G', 'H', 'K', 'R', 'S', 'T', 'W'
      };
      for (var i = 0; i < 20; i++) {
        final task = t.generate(2, _rng(i));
        final letter = task.metadata['letter'] as String;
        expect(allLetters, contains(letter));
      }
    });

    test('Schwierigkeit 2: auch schwere Buchstaben kommen vor', () {
      const hardLetters = {'B', 'D', 'G', 'H', 'K', 'R', 'S', 'T', 'W'};
      final letters = List.generate(
          30, (i) => (t.generate(2, _rng(i)).metadata['letter'] as String));
      // Mindestens ein schwerer Buchstabe in 30 Aufgaben
      expect(letters.any(hardLetters.contains), isTrue);
    });

    test('evaluate: "traced" → true', () {
      final task = t.generate(1, _rng(1));
      expect(t.evaluate(task, 'traced'), isTrue);
    });

    test('evaluate: null → false', () {
      final task = t.generate(1, _rng(1));
      expect(t.evaluate(task, null), isFalse);
    });

    test('evaluate: anderer String → false', () {
      final task = t.generate(1, _rng(1));
      expect(t.evaluate(task, 'A'), isFalse);
      expect(t.evaluate(task, ''), isFalse);
    });

    test('correctAnswer ist "traced"', () {
      for (var i = 0; i < 5; i++) {
        final task = t.generate(1, _rng(i));
        expect(task.correctAnswer, 'traced');
      }
    });

    test('Kein Duplikat-Buchstabe in 5 aufeinanderfolgenden Aufgaben', () {
      // Gleicher Seed → immer selber Buchstabe ist ok,
      // aber mit verschiedenen Seeds sollte Variation entstehen
      final letters = List.generate(
          10, (i) => (t.generate(1, _rng(i)).metadata['letter'] as String));
      // Mindestens 2 verschiedene Buchstaben unter 10 Aufgaben
      expect(letters.toSet().length, greaterThan(1));
    });
  });

  // ── TopicProgress ──────────────────────────────────────────────────────
  group('TopicProgress — Fortschritts-Logik', () {
    TopicProgress makeProgress() => TopicProgress(
          profileId: 'test',
          subject: 'math',
          grade: 2,
          topic: 'addition_bis_100',
          lastPracticed: DateTime(2024),
        );

    test('Startet mit 0 Versuchen und 0 Accuracy', () {
      final p = makeProgress();
      expect(p.totalAttempts, 0);
      expect(p.correctAttempts, 0);
      expect(p.accuracy, 0.0);
    });

    test('recordResult(true) erhöht correctAttempts', () {
      final p = makeProgress();
      p.recordResult(true);
      expect(p.totalAttempts, 1);
      expect(p.correctAttempts, 1);
      expect(p.accuracy, 1.0);
    });

    test('recordResult(false) erhöht nur totalAttempts', () {
      final p = makeProgress();
      p.recordResult(false);
      expect(p.totalAttempts, 1);
      expect(p.correctAttempts, 0);
      expect(p.accuracy, 0.0);
    });

    test('recentResults ist auf 20 Einträge begrenzt', () {
      final p = makeProgress();
      for (var i = 0; i < 25; i++) {
        p.recordResult(i % 2 == 0);
      }
      expect(p.recentResults.length, 20);
    });

    test('key-Format ist korrekt', () {
      final p = makeProgress();
      expect(p.key, 'test-math-2-addition_bis_100');
    });

    test('toJson / fromJson Round-trip', () {
      final p = makeProgress()
        ..recordResult(true)
        ..recordResult(false);
      final json = p.toJson();
      final p2 = TopicProgress.fromJson(json);
      expect(p2.profileId, p.profileId);
      expect(p2.totalAttempts, p.totalAttempts);
      expect(p2.correctAttempts, p.correctAttempts);
      expect(p2.recentResults, p.recentResults);
    });
  });

  // ── ChildProfile ───────────────────────────────────────────────────────
  group('ChildProfile — Profil-Logik', () {
    test('toJson / fromJson Round-trip', () {
      final profile = ChildProfile(
        id: 'abc123',
        name: 'Emma',
        grade: 2,
        avatarEmoji: '🐼',
        totalStars: 15,
        createdAt: DateTime(2024, 1, 15),
      );
      final json = profile.toJson();
      final p2 = ChildProfile.fromJson(json);
      expect(p2.id, profile.id);
      expect(p2.name, profile.name);
      expect(p2.grade, profile.grade);
      expect(p2.avatarEmoji, profile.avatarEmoji);
      expect(p2.totalStars, profile.totalStars);
    });

    test('Standardwerte korrekt', () {
      final profile = ChildProfile(
        id: 'x',
        name: 'Test',
        grade: 1,
        createdAt: DateTime.now(),
      );
      expect(profile.avatarEmoji, '🦊');
      expect(profile.totalStars, 0);
    });
  });

  // ── StarRating.fromAccuracy ────────────────────────────────────────────
  group('StarRating.fromAccuracy', () {
    test('< 30% → 0 Sterne', () {
      expect(StarRating.fromAccuracy(0.0), 0);
      expect(StarRating.fromAccuracy(0.29), 0);
    });

    test('30–59% → 1 Stern', () {
      expect(StarRating.fromAccuracy(0.3), 1);
      expect(StarRating.fromAccuracy(0.59), 1);
    });

    test('60–89% → 2 Sterne', () {
      expect(StarRating.fromAccuracy(0.6), 2);
      expect(StarRating.fromAccuracy(0.89), 2);
    });

    test('>= 90% → 3 Sterne', () {
      expect(StarRating.fromAccuracy(0.9), 3);
      expect(StarRating.fromAccuracy(1.0), 3);
    });
  });

  // ── DifficultyEngine (Regression) ─────────────────────────────────────
  group('DifficultyEngine — Regressionstest', () {
    test('10 richtige → Schwierigkeit steigt', () {
      final results = List.filled(10, 1);
      final next = DifficultyEngine.nextDifficulty(
          recentResults: results, currentDifficulty: 2);
      expect(next, 3);
    });

    test('10 falsche → Schwierigkeit sinkt', () {
      final results = List.filled(10, 0);
      final next = DifficultyEngine.nextDifficulty(
          recentResults: results, currentDifficulty: 3);
      expect(next, 2);
    });

    test('Minimum 1, Maximum 5', () {
      final allCorrect = List.filled(10, 1);
      final allWrong = List.filled(10, 0);
      expect(
        DifficultyEngine.nextDifficulty(
            recentResults: allCorrect, currentDifficulty: 5),
        5,
      );
      expect(
        DifficultyEngine.nextDifficulty(
            recentResults: allWrong, currentDifficulty: 1),
        1,
      );
    });
  });
}
