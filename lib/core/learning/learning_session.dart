import '../models/task_model.dart';
import 'learning_request.dart';

class LearningSession {
  final LearningRequest request;
  final List<TaskModel> tasks;

  const LearningSession({required this.request, required this.tasks});

  bool get isEmpty => tasks.isEmpty;
}
