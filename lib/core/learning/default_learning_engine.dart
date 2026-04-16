import '../engine/curriculum.dart';
import '../engine/elo_difficulty_engine.dart';
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
    final tasks = request.isInterleaved
        ? TaskGenerator.generateInterleavedSession(
            topics: request.interleavedTopics!,
            difficulty: request.difficulty,
            count: request.count,
            seed: request.seed,
          )
        : TaskGenerator.generateSession(
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
    String? profileId,
    Subject? subject,
    int? grade,
    String? topic,
  }) {
    // Falls wir Kontext haben, nutzen wir das echte Elo-Rating aus dem Storage.
    // Da recordResult bereits aufgerufen wurde, ist dies der aktuellste Stand.
    if (profileId != null && subject != null && grade != null && topic != null) {
      final progress = _storage.getProgress(
        profileId: profileId,
        subject: subject.id,
        grade: grade,
        topic: topic,
      );
      return EloDifficultyEngine.recommendDifficulty(progress.eloRating);
    }

    // Fallback für Tests oder unvollständigen Kontext:
    // Wir simulieren die Elo-Entwicklung basierend auf dem aktuellen Schwierigkeits-Level.
    if (recentResults.isEmpty) return currentDifficulty;

    // Wir nutzen ein Fenster von 8 Ergebnissen für die In-Session-Stabilität.
    final windowSize = 8;
    final recent = recentResults.length > windowSize
        ? recentResults.sublist(recentResults.length - windowSize)
        : recentResults;

    double virtualRating =
        EloDifficultyEngine.eloForDifficulty(currentDifficulty);
    for (final result in recent) {
      virtualRating = EloDifficultyEngine.calculateNewRating(
        currentRating: virtualRating,
        taskDifficulty: currentDifficulty,
        success: result == 1,
      );
    }

    return EloDifficultyEngine.recommendDifficulty(virtualRating);
  }

  @override
  int initialDifficulty({required TopicProgress progress, required int grade}) {
    return EloDifficultyEngine.recommendDifficulty(progress.eloRating);
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
    int? difficulty,
  }) {
    return _storage.recordResult(
      profileId: profileId,
      subject: subject.id,
      grade: grade,
      topic: topic,
      correct: correct,
      difficulty: difficulty,
    );
  }
}
