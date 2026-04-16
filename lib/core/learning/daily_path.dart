import '../models/progress.dart';
import '../models/subject.dart';
import 'learning_request.dart';

class DailyPath {
  final String profileId;
  final String dateKey;
  final List<DailyPathStep> steps;

  const DailyPath({
    required this.profileId,
    required this.dateKey,
    required this.steps,
  });

  bool get isEmpty => steps.isEmpty;
}

class DailyPathStep {
  final String id;
  final Subject subject;
  final int grade;
  final String topic;
  final int difficulty;
  final DailyPathReason reason;
  final int seed;

  const DailyPathStep({
    required this.id,
    required this.subject,
    required this.grade,
    required this.topic,
    required this.difficulty,
    required this.reason,
    required this.seed,
  });

  LearningRequest toLearningRequest({int count = 1}) {
    return LearningRequest(
      subject: subject,
      grade: grade,
      topic: topic,
      difficulty: difficulty,
      count: count,
      seed: seed,
    );
  }
}

enum DailyPathReason { weakArea, freshTopic, recentReview }

class DailyPathProgress {
  final String profileId;
  final String dateKey;
  final List<String> completedStepIds;
  final bool rewardGranted;

  const DailyPathProgress({
    required this.profileId,
    required this.dateKey,
    this.completedStepIds = const [],
    this.rewardGranted = false,
  });

  bool isStepCompleted(String stepId) => completedStepIds.contains(stepId);

  bool isComplete(DailyPath path) {
    return path.steps.isNotEmpty &&
        path.steps.every((step) => completedStepIds.contains(step.id));
  }

  DailyPathProgress completeStep(String stepId) {
    final nextCompleted = {...completedStepIds, stepId}.toList()..sort();
    return copyWith(completedStepIds: nextCompleted);
  }

  DailyPathProgress copyWith({
    List<String>? completedStepIds,
    bool? rewardGranted,
  }) {
    return DailyPathProgress(
      profileId: profileId,
      dateKey: dateKey,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      rewardGranted: rewardGranted ?? this.rewardGranted,
    );
  }

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'dateKey': dateKey,
    'completedStepIds': completedStepIds,
    'rewardGranted': rewardGranted,
  };

  factory DailyPathProgress.fromJson(Map<String, dynamic> json) {
    return DailyPathProgress(
      profileId: json['profileId'] as String,
      dateKey: json['dateKey'] as String,
      completedStepIds: (json['completedStepIds'] as List? ?? const [])
          .cast<String>(),
      rewardGranted: json['rewardGranted'] as bool? ?? false,
    );
  }
}

class DailyPathCandidate {
  final Subject subject;
  final int grade;
  final String topic;
  final TopicProgress? progress;

  const DailyPathCandidate({
    required this.subject,
    required this.grade,
    required this.topic,
    this.progress,
  });

  String get key => '${subject.id}-$grade-$topic';
}
