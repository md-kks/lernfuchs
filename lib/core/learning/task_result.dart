import '../models/task_model.dart';

class TaskResult {
  final TaskModel task;
  final dynamic answer;
  final bool correct;

  const TaskResult({
    required this.task,
    required this.answer,
    required this.correct,
  });
}
