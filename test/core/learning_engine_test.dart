import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/learning/learning.dart';
import 'package:lernfuchs/core/models/subject.dart';
import 'package:lernfuchs/core/models/task_model.dart';
import 'package:lernfuchs/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LearningEngine learning;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    learning = DefaultLearningEngine(storage);
  });

  test('createSession wraps task generation behind LearningSession', () {
    final session = learning.createSession(
      const LearningRequest(
        subject: Subject.math,
        grade: 1,
        topic: 'addition_bis_10',
        difficulty: 2,
        count: 3,
        seed: 7,
      ),
    );

    expect(session.request.subject, Subject.math);
    expect(session.tasks, hasLength(3));
    expect(session.tasks.every((task) => task.subject == 'math'), isTrue);
    expect(session.tasks.every((task) => task.grade == 1), isTrue);
    expect(
      session.tasks.every((task) => task.topic == 'addition_bis_10'),
      isTrue,
    );
  });

  test('evaluateTask returns a TaskResult without exposing Evaluator', () {
    final task = TaskModel(
      id: 'test',
      subject: 'math',
      grade: 1,
      topic: 'addition_bis_10',
      question: '2 + 3 = ?',
      taskType: TaskType.freeInput.name,
      correctAnswer: 5,
    );

    final result = learning.evaluateTask(task, 5);

    expect(result.task, same(task));
    expect(result.answer, 5);
    expect(result.correct, isTrue);
  });

  test('topicsFor wraps curriculum selection', () {
    expect(
      learning.topicsFor(federalState: 'BY', subject: Subject.german, grade: 2),
      contains('artikel'),
    );
  });

  test(
    'recordResult preserves existing progress persistence behavior',
    () async {
      await learning.recordResult(
        profileId: 'learning_test_profile',
        subject: Subject.math,
        grade: 1,
        topic: 'addition_bis_10',
        correct: true,
      );

      final progress = learning.progressFor(
        profileId: 'learning_test_profile',
        subject: Subject.math,
        grade: 1,
        topic: 'addition_bis_10',
      );

      expect(progress.totalAttempts, 1);
      expect(progress.correctAttempts, 1);
      expect(progress.recentResults, [1]);
    },
  );
}
