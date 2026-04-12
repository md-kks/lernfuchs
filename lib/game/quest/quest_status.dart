enum QuestRunState { available, inProgress, completed }

class QuestStatus {
  final String questId;
  final QuestRunState state;
  final int currentStepIndex;
  final List<String> completedStepIds;
  final List<String> grantedRewardIds;
  final Map<String, dynamic> worldState;

  const QuestStatus({
    required this.questId,
    this.state = QuestRunState.available,
    this.currentStepIndex = 0,
    this.completedStepIds = const [],
    this.grantedRewardIds = const [],
    this.worldState = const {},
  });

  QuestStatus copyWith({
    QuestRunState? state,
    int? currentStepIndex,
    List<String>? completedStepIds,
    List<String>? grantedRewardIds,
    Map<String, dynamic>? worldState,
  }) {
    return QuestStatus(
      questId: questId,
      state: state ?? this.state,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      grantedRewardIds: grantedRewardIds ?? this.grantedRewardIds,
      worldState: worldState ?? this.worldState,
    );
  }

  Map<String, dynamic> toJson() => {
    'questId': questId,
    'state': state.name,
    'currentStepIndex': currentStepIndex,
    'completedStepIds': completedStepIds,
    'grantedRewardIds': grantedRewardIds,
    'worldState': worldState,
  };

  factory QuestStatus.fromJson(Map<String, dynamic> json) {
    return QuestStatus(
      questId: json['questId'] as String,
      state: QuestRunState.values.byName(
        json['state'] as String? ?? QuestRunState.available.name,
      ),
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      completedStepIds: (json['completedStepIds'] as List? ?? const [])
          .cast<String>(),
      grantedRewardIds: (json['grantedRewardIds'] as List? ?? const [])
          .cast<String>(),
      worldState:
          (json['worldState'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
