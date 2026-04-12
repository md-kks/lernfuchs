enum LearningSessionMode {
  freePractice,
  questSingle,
  questMiniSeries,
  dailyPath,
}

class LearningChallengeResult {
  final LearningSessionMode mode;
  final int grade;
  final String subjectId;
  final String topic;
  final int correctCount;
  final int totalCount;

  const LearningChallengeResult({
    required this.mode,
    required this.grade,
    required this.subjectId,
    required this.topic,
    required this.correctCount,
    required this.totalCount,
  });

  bool get successful => correctCount == totalCount;
}
