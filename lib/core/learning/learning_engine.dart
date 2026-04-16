import '../models/progress.dart';
import '../models/subject.dart';
import '../models/task_model.dart';
import 'learning_request.dart';
import 'learning_session.dart';
import 'task_result.dart';

abstract class LearningEngine {
  List<String> topicsFor({
    required String federalState,
    required Subject subject,
    required int grade,
  });

  LearningSession createSession(LearningRequest request);

  TaskResult evaluateTask(TaskModel task, dynamic answer);

  int nextDifficulty({
    required List<int> recentResults,
    required int currentDifficulty,
    String? profileId,
    Subject? subject,
    int? grade,
    String? topic,
  });

  int initialDifficulty({required TopicProgress progress, required int grade});

  TopicProgress progressFor({
    required String profileId,
    required Subject subject,
    required int grade,
    required String topic,
  });

  List<TopicProgress> allProgressForProfile(String profileId);

  Future<void> recordResult({
    required String profileId,
    required Subject subject,
    required int grade,
    required String topic,
    required bool correct,
    int? difficulty,
  });
}
