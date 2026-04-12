import '../models/subject.dart';

class LearningRequest {
  final Subject subject;
  final int grade;
  final String topic;
  final int difficulty;
  final int count;
  final int? seed;

  const LearningRequest({
    required this.subject,
    required this.grade,
    required this.topic,
    required this.difficulty,
    this.count = 10,
    this.seed,
  });

  String get subjectId => subject.id;
}
