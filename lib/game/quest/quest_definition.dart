import '../../core/models/subject.dart';

enum QuestStepType { dialogue, learningChallenge, worldState, reward }

class QuestDefinition {
  final String id;
  final String title;
  final String description;
  final String worldNodeId;
  final UnlockCondition unlockCondition;
  final List<QuestStepDefinition> steps;

  const QuestDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.worldNodeId,
    required this.unlockCondition,
    required this.steps,
  });

  factory QuestDefinition.fromJson(Map<String, dynamic> json) {
    return QuestDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      worldNodeId: json['worldNodeId'] as String,
      unlockCondition: UnlockCondition.fromJson(
        (json['unlockCondition'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      steps: (json['steps'] as List? ?? const [])
          .map(
            (step) => QuestStepDefinition.fromJson(
              (step as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}

class QuestStepDefinition {
  final String id;
  final QuestStepType type;
  final String title;
  final String text;
  final String? dialogueSceneId;
  final String? hintSetId;
  final LearningChallengeDefinition? learningChallenge;
  final WorldStateChangeDefinition? worldStateChange;
  final QuestRewardDefinition? reward;

  const QuestStepDefinition({
    required this.id,
    required this.type,
    required this.title,
    this.text = '',
    this.dialogueSceneId,
    this.hintSetId,
    this.learningChallenge,
    this.worldStateChange,
    this.reward,
  });

  factory QuestStepDefinition.fromJson(Map<String, dynamic> json) {
    final type = QuestStepType.values.byName(json['type'] as String);
    return QuestStepDefinition(
      id: json['id'] as String,
      type: type,
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      dialogueSceneId: json['dialogueSceneId'] as String?,
      hintSetId: json['hintSetId'] as String?,
      learningChallenge: json['learningChallenge'] == null
          ? null
          : LearningChallengeDefinition.fromJson(
              (json['learningChallenge'] as Map).cast<String, dynamic>(),
            ),
      worldStateChange: json['worldStateChange'] == null
          ? null
          : WorldStateChangeDefinition.fromJson(
              (json['worldStateChange'] as Map).cast<String, dynamic>(),
            ),
      reward: json['reward'] == null
          ? null
          : QuestRewardDefinition.fromJson(
              (json['reward'] as Map).cast<String, dynamic>(),
            ),
    );
  }
}

class LearningChallengeDefinition {
  final Subject subject;
  final int grade;
  final String topic;
  final int difficulty;
  final int count;
  final String successText;
  final String retryText;

  const LearningChallengeDefinition({
    required this.subject,
    required this.grade,
    required this.topic,
    required this.difficulty,
    this.count = 1,
    this.successText = '',
    this.retryText = '',
  });

  factory LearningChallengeDefinition.fromJson(Map<String, dynamic> json) {
    return LearningChallengeDefinition(
      subject: Subject.values.firstWhere((s) => s.id == json['subject']),
      grade: json['grade'] as int,
      topic: json['topic'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
      count: json['count'] as int? ?? 1,
      successText: json['successText'] as String? ?? '',
      retryText: json['retryText'] as String? ?? '',
    );
  }
}

class WorldStateChangeDefinition {
  final Map<String, dynamic> flags;

  const WorldStateChangeDefinition({this.flags = const {}});

  factory WorldStateChangeDefinition.fromJson(Map<String, dynamic> json) {
    return WorldStateChangeDefinition(
      flags: (json['flags'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class QuestRewardDefinition {
  final String id;
  final String title;
  final String type;
  final int amount;
  final String? unlockUpgradeId;

  const QuestRewardDefinition({
    required this.id,
    required this.title,
    required this.type,
    this.amount = 1,
    this.unlockUpgradeId,
  });

  factory QuestRewardDefinition.fromJson(Map<String, dynamic> json) {
    return QuestRewardDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String? ?? 'badge',
      amount: json['amount'] as int? ?? 1,
      unlockUpgradeId: json['unlockUpgradeId'] as String?,
    );
  }
}

class UnlockCondition {
  final List<String> completedQuestIds;
  final Map<String, dynamic> worldFlags;

  const UnlockCondition({
    this.completedQuestIds = const [],
    this.worldFlags = const {},
  });

  factory UnlockCondition.fromJson(Map<String, dynamic> json) {
    return UnlockCondition(
      completedQuestIds: (json['completedQuestIds'] as List? ?? const [])
          .cast<String>(),
      worldFlags:
          (json['worldFlags'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
