import '../models/subject.dart';

class LearningRequest {
  final Subject subject;
  final int grade;
  final String topic;
  final int difficulty;
  final int count;
  final int? seed;

  /// Optional: Wenn gesetzt, werden Aufgaben aus verschiedenen Themen gemischt.
  final List<({Subject subject, int grade, String topic})>? interleavedTopics;

  const LearningRequest({
    required this.subject,
    required this.grade,
    required this.topic,
    required this.difficulty,
    this.count = 10,
    this.seed,
    this.interleavedTopics,
  });

  bool get isInterleaved => interleavedTopics != null && interleavedTopics!.isNotEmpty;

  String get subjectId => subject.id;
}
