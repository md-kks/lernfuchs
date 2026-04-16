import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/learning/learning.dart';
import 'package:lernfuchs/core/models/subject.dart';
import 'package:lernfuchs/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LearningEngine learning;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    learning = DefaultLearningEngine(storage);
  });

  group('Session Sequence Integration', () {
    const profileId = 'seq_test_profile';
    const topic = 'seq_test_topic';

    test('nextDifficulty sieht garantiert den aktuellen Elo-Stand nach recordResult', () async {
      // 1. Initialer Zustand (Elo 1000 -> Stufe 2)
      final initialNext = learning.nextDifficulty(
        recentResults: [],
        currentDifficulty: 2,
        profileId: profileId,
        subject: Subject.math,
        grade: 2,
        topic: topic,
      );
      expect(initialNext, 2);

      // 2. Wir simulieren eine Serie von 10 richtigen Antworten (wie im Widget-Flow)
      // Jeder Schritt muss recordResult AWAITEN, bevor nextDifficulty gerufen wird.
      final results = <int>[];
      int currentDiff = 2;

      for (int i = 0; i < 10; i++) {
        results.add(1);
        
        // Simuliert LearningChallengeSession._submitAnswer()
        await learning.recordResult(
          profileId: profileId,
          subject: Subject.math,
          grade: 2,
          topic: topic,
          correct: true,
          difficulty: currentDiff,
        );

        // Simuliert LearningChallengeSession._nextTask()
        currentDiff = learning.nextDifficulty(
          recentResults: results,
          currentDifficulty: currentDiff,
          profileId: profileId,
          subject: Subject.math,
          grade: 2,
          topic: topic,
        );
      }

      // Am Ende der 10er Serie muss die Schwierigkeit gestiegen sein, 
      // weil nextDifficulty immer den aktuellsten Elo-Stand aus dem Storage liest.
      expect(currentDiff, greaterThan(2));
      
      final finalProgress = learning.progressFor(
        profileId: profileId,
        subject: Subject.math,
        grade: 2,
        topic: topic,
      );
      expect(finalProgress.eloRating, greaterThan(1100));
    });
  });
}
