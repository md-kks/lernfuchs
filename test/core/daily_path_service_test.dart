import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/learning/learning.dart';
import 'package:lernfuchs/core/models/progress.dart';
import 'package:lernfuchs/core/models/subject.dart';
import 'package:lernfuchs/core/models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('daily path prefers weak area, fresh topic, and recent review', () {
    final engine = _FakeLearningEngine(
      progress: [
        TopicProgress(
          profileId: 'profile_1',
          subject: Subject.math.id,
          grade: 2,
          topic: 'addition_bis_100',
          totalAttempts: 4,
          correctAttempts: 2,
          lastPracticed: DateTime(2026, 4, 11),
        ),
        TopicProgress(
          profileId: 'profile_1',
          subject: Subject.math.id,
          grade: 2,
          topic: 'subtraktion_bis_100',
          totalAttempts: 5,
          correctAttempts: 5,
          lastPracticed: DateTime(2026, 4, 12),
        ),
      ],
    );
    final service = DailyPathService(
      learningEngine: engine,
      now: () => DateTime(2026, 4, 12),
    );

    final path = service.createPathForProfile(
      profile: ChildProfile(
        id: 'profile_1',
        name: 'Mina',
        grade: 2,
        createdAt: DateTime(2026),
      ),
      federalState: 'BY',
    );

    expect(path.dateKey, '2026-04-12');
    expect(path.steps.map((step) => step.topic), [
      'addition_bis_100',
      'satzarten',
      'subtraktion_bis_100',
    ]);
    expect(path.steps.map((step) => step.reason), [
      DailyPathReason.weakArea,
      DailyPathReason.freshTopic,
      DailyPathReason.recentReview,
    ]);
    expect(path.steps.every((step) => step.grade == 2), isTrue);
  });

  test(
    'daily path progress persists completed steps and reward state',
    () async {
      SharedPreferences.setMockInitialValues({});
      const store = DailyPathStore();

      const progress = DailyPathProgress(
        profileId: 'profile_1',
        dateKey: '2026-04-12',
        completedStepIds: ['step_1'],
        rewardGranted: true,
      );

      await store.save(progress);
      final loaded = await store.loadForProfile(
        profileId: 'profile_1',
        dateKey: '2026-04-12',
      );

      expect(loaded.completedStepIds, ['step_1']);
      expect(loaded.rewardGranted, isTrue);
    },
  );
}

class _FakeLearningEngine implements LearningEngine {
  final List<TopicProgress> progress;

  const _FakeLearningEngine({required this.progress});

  @override
  List<TopicProgress> allProgressForProfile(String profileId) {
    return progress.where((item) => item.profileId == profileId).toList();
  }

  @override
  int initialDifficulty({required TopicProgress progress, required int grade}) {
    return progress.accuracy < 0.75 ? 1 : 2;
  }

  @override
  List<String> topicsFor({
    required String federalState,
    required Subject subject,
    required int grade,
  }) {
    return switch (subject) {
      Subject.math => ['addition_bis_100', 'subtraktion_bis_100'],
      Subject.german => ['satzarten'],
    };
  }

  @override
  LearningSession createSession(LearningRequest request) {
    throw UnimplementedError();
  }

  @override
  TaskResult evaluateTask(TaskModel task, answer) {
    throw UnimplementedError();
  }

  @override
  int nextDifficulty({
    required List<int> recentResults,
    required int currentDifficulty,
  }) {
    return currentDifficulty;
  }

  @override
  TopicProgress progressFor({
    required String profileId,
    required Subject subject,
    required int grade,
    required String topic,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordResult({
    required String profileId,
    required Subject subject,
    required int grade,
    required String topic,
    required bool correct,
    int? difficulty,
  }) {
    throw UnimplementedError();
  }
}
