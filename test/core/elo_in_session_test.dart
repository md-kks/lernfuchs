import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/learning/learning.dart';
import 'package:lernfuchs/core/models/subject.dart';
import 'package:lernfuchs/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LearningEngine learning;
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.init();
    learning = DefaultLearningEngine(storage);
  });

  group('DefaultLearningEngine.nextDifficulty — Elo In-Session', () {
    const profileId = 'test_child';
    const subject = Subject.math;
    const grade = 2;
    const topic = 'addition_bis_100';

    test('Bleibt bei Stufe 2 bei gemischten Ergebnissen', () async {
      const t1 = 'topic_mixed';
      // Start-Elo ist 1000 (Stufe 2)
      final results = [1, 0, 1, 1, 0];
      
      for (final res in results) {
        await learning.recordResult(
          profileId: profileId,
          subject: subject,
          grade: grade,
          topic: t1,
          correct: res == 1,
          difficulty: 2,
        );
      }

      final next = learning.nextDifficulty(
        recentResults: results,
        currentDifficulty: 2,
        profileId: profileId,
        subject: subject,
        grade: grade,
        topic: t1,
      );

      expect(next, 2);
    });

    test('Steigt auf Stufe 3 bei starkem Streak (10 richtige)', () async {
      const t2 = 'topic_streak_up';
      final results = List.filled(10, 1);
      
      for (final res in results) {
        await learning.recordResult(
          profileId: profileId,
          subject: subject,
          grade: grade,
          topic: t2,
          correct: true,
          difficulty: 2,
        );
      }

      final next = learning.nextDifficulty(
        recentResults: results,
        currentDifficulty: 2,
        profileId: profileId,
        subject: subject,
        grade: grade,
        topic: t2,
      );

      // Nach 10 Erfolgen ist Elo sicher > 1100
      expect(next, 3);
    });

    test('Sinkt auf Stufe 1 bei schwachem Streak (10 falsche)', () async {
      const t3 = 'topic_streak_down';
      final results = List.filled(10, 0);
      
      for (final res in results) {
        await learning.recordResult(
          profileId: profileId,
          subject: subject,
          grade: grade,
          topic: t3,
          correct: false,
          difficulty: 2,
        );
      }

      final next = learning.nextDifficulty(
        recentResults: results,
        currentDifficulty: 2,
        profileId: profileId,
        subject: subject,
        grade: grade,
        topic: t3,
      );

      // Nach 10 Fehlern ist Elo sicher < 900
      expect(next, 1);
    });

    test('Fallback-Logik ohne Storage-Kontext funktioniert (Fenster 10)', () {
      // Ohne profileId/topic nutzt er den Fallback
      final results = List.filled(10, 1);
      
      final next = learning.nextDifficulty(
        recentResults: results,
        currentDifficulty: 2,
      );

      expect(next, 3);
    });

    test('Fallback-Logik bleibt stabil bei kurzem Fenster', () {
      final results = List.filled(4, 1);
      
      final next = learning.nextDifficulty(
        recentResults: results,
        currentDifficulty: 2,
      );

      // 1000 + 4*16 = 1064 -> Stufe 2
      expect(next, 2);
    });

    test('recentResults leer -> gibt currentDifficulty zurück', () {
      final next = learning.nextDifficulty(
        recentResults: [],
        currentDifficulty: 3,
      );
      expect(next, 3);
    });

    test('Unvollständiger Kontext (z.B. topic fehlt) -> nutzt Fallback', () {
      // Mit Kontext wäre Elo im Storage (z.B. 1600 -> Stufe 5)
      // Ohne Topic-Kontext muss Fallback greifen (z.B. Start 1000 + Streak -> Stufe 3)
      final results = List.filled(8, 1);
      
      final next = learning.nextDifficulty(
        recentResults: results,
        currentDifficulty: 2,
        profileId: profileId,
        subject: subject,
        grade: grade,
        // topic fehlt
      );

      expect(next, 3); // Fallback-Pfad (Virtual Elo)
    });

    test('Maximale Schwierigkeit 5 wird nicht überschritten', () async {
      // Fallback-Pfad
      final highNextFallback = learning.nextDifficulty(
        recentResults: List.filled(50, 1),
        currentDifficulty: 5,
      );
      expect(highNextFallback, 5);

      // Storage-Pfad
      for (var i = 0; i < 50; i++) {
        await learning.recordResult(
          profileId: profileId,
          subject: subject,
          grade: grade,
          topic: topic,
          correct: true,
          difficulty: 5,
        );
      }
      final highNextStorage = learning.nextDifficulty(
        recentResults: List.filled(50, 1),
        currentDifficulty: 5,
        profileId: profileId,
        subject: subject,
        grade: grade,
        topic: topic,
      );
      expect(highNextStorage, 5);
    });

    test('Minimale Schwierigkeit 1 wird nicht unterschritten', () async {
      // Fallback-Pfad
      final lowNextFallback = learning.nextDifficulty(
        recentResults: List.filled(50, 0),
        currentDifficulty: 1,
      );
      expect(lowNextFallback, 1);

      // Storage-Pfad (Reset storage/progress by using new topic)
      const lowTopic = 'subtraktion_bis_10';
      for (var i = 0; i < 50; i++) {
        await learning.recordResult(
          profileId: profileId,
          subject: subject,
          grade: grade,
          topic: lowTopic,
          correct: false,
          difficulty: 1,
        );
      }
      final lowNextStorage = learning.nextDifficulty(
        recentResults: List.filled(50, 0),
        currentDifficulty: 1,
        profileId: profileId,
        subject: subject,
        grade: grade,
        topic: lowTopic,
      );
      expect(lowNextStorage, 1);
    });

    test('Sehr hoher gespeicherter Elo führt zu Stufe 5', () async {
      // Wir manipulieren den Storage indirekt durch viele Erfolge
      for (var i = 0; i < 100; i++) {
        await learning.recordResult(
          profileId: 'super_pro',
          subject: subject,
          grade: grade,
          topic: topic,
          correct: true,
          difficulty: 5,
        );
      }
      
      final next = learning.nextDifficulty(
        recentResults: [1],
        currentDifficulty: 5,
        profileId: 'super_pro',
        subject: subject,
        grade: grade,
        topic: topic,
      );
      expect(next, 5);
    });

    test('Sehr niedriger gespeicherter Elo führt zu Stufe 1', () async {
      for (var i = 0; i < 100; i++) {
        await learning.recordResult(
          profileId: 'beginner',
          subject: subject,
          grade: grade,
          topic: topic,
          correct: false,
          difficulty: 1,
        );
      }
      
      final next = learning.nextDifficulty(
        recentResults: [0],
        currentDifficulty: 1,
        profileId: 'beginner',
        subject: subject,
        grade: grade,
        topic: topic,
      );
      expect(next, 1);
    });
  });
}
