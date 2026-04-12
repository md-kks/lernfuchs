import '../engine/curriculum.dart';
import '../engine/difficulty.dart';
import '../engine/evaluator.dart';
import '../engine/task_generator.dart';
import '../models/progress.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';
import 'learning_engine.dart';
import 'learning_request.dart';
import 'learning_session.dart';
import 'task_result.dart';

class DefaultLearningEngine implements LearningEngine {
  final StorageService _storage;

  const DefaultLearningEngine(this._storage);

  @override
  List<String> topicsFor({
    required String federalState,
    required Subject subject,
    required int grade,
  }) {
    final curriculum = Curriculum(federalState);
    return switch (subject) {
      Subject.math => curriculum.mathTopics(grade),
      Subject.german => curriculum.germanTopics(grade),
    };
  }

  @override
  LearningSession createSession(LearningRequest request) {
    final tasks = TaskGenerator.generateSession(
      subject: request.subject,
      grade: request.grade,
      topic: request.topic,
      difficulty: request.difficulty,
      count: request.count,
      seed: request.seed,
    );
    return LearningSession(request: request, tasks: tasks);
  }

  @override
  TaskResult evaluateTask(task, dynamic answer) {
    return TaskResult(
      task: task,
      answer: answer,
      correct: Evaluator.evaluate(task, answer),
    );
  }

  @override
  int nextDifficulty({
    required List<int> recentResults,
    required int currentDifficulty,
  }) {
    return DifficultyEngine.nextDifficulty(
      recentResults: recentResults,
      currentDifficulty: currentDifficulty,
    );
  }

  @override
  int initialDifficulty({required TopicProgress progress, required int grade}) {
    return DifficultyEngine.initialDifficulty(progress.accuracy, grade);
  }

  @override
  TopicProgress progressFor({
    required String profileId,
    required Subject subject,
    required int grade,
    required String topic,
  }) {
    return _storage.getProgress(
      profileId: profileId,
      subject: subject.id,
      grade: grade,
      topic: topic,
    );
  }

  @override
  List<TopicProgress> allProgressForProfile(String profileId) {
    return _storage.allProgressForProfile(profileId);
  }

  @override
  Future<void> recordResult({
    required String profileId,
    required Subject subject,
    required int grade,
    required String topic,
    required bool correct,
  }) {
    return _storage.recordResult(
      profileId: profileId,
      subject: subject.id,
      grade: grade,
      topic: topic,
      correct: correct,
    );
  }
}
