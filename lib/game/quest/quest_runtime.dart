import '../../core/learning/learning.dart';
import '../../core/models/subject.dart';
import '../../core/models/task_model.dart';
import '../reward/game_reward.dart';
import '../reward/inventory_store.dart';
import 'quest_definition.dart';
import 'quest_status.dart';
import 'quest_status_store.dart';

class QuestRuntime {
  final String profileId;
  final LearningEngine learningEngine;
  final QuestStatusStore statusStore;
  final InventoryStore inventoryStore;
  final Map<String, QuestDefinition> _questsById;

  Map<String, QuestStatus> _statuses = {};

  QuestRuntime({
    required this.profileId,
    required this.learningEngine,
    required this.statusStore,
    this.inventoryStore = const InventoryStore(),
    required List<QuestDefinition> quests,
  }) : _questsById = {for (final quest in quests) quest.id: quest};

  List<QuestDefinition> get quests => _questsById.values.toList();

  Future<void> load() async {
    _statuses = await statusStore.loadForProfile(profileId);
  }

  QuestStatus statusFor(String questId) {
    return _statuses[questId] ?? QuestStatus(questId: questId);
  }

  QuestStepDefinition? currentStep(String questId) {
    final quest = _quest(questId);
    final status = statusFor(questId);
    if (status.currentStepIndex >= quest.steps.length) return null;
    return quest.steps[status.currentStepIndex];
  }

  Future<QuestStatus> startQuest(String questId) async {
    final status = statusFor(questId);
    if (status.state == QuestRunState.completed) return status;
    final next = status.copyWith(state: QuestRunState.inProgress);
    await _saveStatus(next);
    return next;
  }

  TaskModel createLearningTask(String questId) {
    final step = currentStep(questId);
    final challenge = step?.learningChallenge;
    if (step == null ||
        step.type != QuestStepType.learningChallenge ||
        challenge == null) {
      throw StateError('Current quest step is not a learning challenge.');
    }

    final session = learningEngine.createSession(
      LearningRequest(
        subject: challenge.subject,
        grade: challenge.grade,
        topic: challenge.topic,
        difficulty: challenge.difficulty,
        count: challenge.count,
      ),
    );
    return session.tasks.first;
  }

  LearningRequest createLearningRequest(String questId) {
    final step = currentStep(questId);
    final challenge = step?.learningChallenge;
    if (step == null ||
        step.type != QuestStepType.learningChallenge ||
        challenge == null) {
      throw StateError('Current quest step is not a learning challenge.');
    }

    List<({Subject subject, int grade, String topic})>? interleaved;
    if (challenge.interleavedTopics != null) {
      interleaved = challenge.interleavedTopics!.map((t) {
        final parts = t.split(':');
        final subject = Subject.values.firstWhere((s) => s.id == parts[0]);
        return (subject: subject, grade: challenge.grade, topic: parts[1]);
      }).toList();
    }

    return LearningRequest(
      subject: challenge.subject,
      grade: challenge.grade,
      topic: challenge.topic,
      difficulty: challenge.difficulty,
      count: challenge.count,
      interleavedTopics: interleaved,
    );
  }

  Future<TaskResult> submitLearningAnswer({
    required String questId,
    required TaskModel task,
    required dynamic answer,
  }) async {
    final challenge = currentStep(questId)?.learningChallenge;
    final result = learningEngine.evaluateTask(task, answer);
    await learningEngine.recordResult(
      profileId: profileId,
      subject: Subject.values.firstWhere(
        (subject) => subject.id == task.subject,
      ),
      grade: task.grade,
      topic: task.topic,
      correct: result.correct,
      difficulty: challenge?.difficulty,
    );
    if (result.correct) {
      await completeCurrentStep(questId);
    }
    return result;
  }

  Future<({QuestStatus status, List<QuestRewardDefinition> rewards})> completeCurrentStep(String questId) async {
    final quest = _quest(questId);
    final status = statusFor(questId);
    final step = currentStep(questId);
    if (step == null) return (status: status, rewards: <QuestRewardDefinition>[]);

    final rewardsToGrant = <QuestRewardDefinition>[];
    var next = _applyStep(status, step, rewardsToGrant);
    while (next.currentStepIndex < quest.steps.length) {
      final candidate = quest.steps[next.currentStepIndex];
      if (candidate.type != QuestStepType.worldState &&
          candidate.type != QuestStepType.reward) {
        break;
      }
      next = _applyStep(next, candidate, rewardsToGrant);
    }

    if (next.currentStepIndex >= quest.steps.length) {
      next = next.copyWith(state: QuestRunState.completed);
    }

    await _saveStatus(next);
    await _grantRewards(rewardsToGrant);
    return (status: next, rewards: rewardsToGrant);
  }

  QuestStatus _applyStep(
    QuestStatus status,
    QuestStepDefinition step,
    List<QuestRewardDefinition> rewardsToGrant,
  ) {
    final completedStepIds = {...status.completedStepIds, step.id}.toList();
    final grantedRewardIds = {...status.grantedRewardIds}.toList();
    final worldState = {...status.worldState};

    if (step.type == QuestStepType.worldState) {
      worldState.addAll(step.worldStateChange?.flags ?? const {});
    }
    final reward = step.reward;
    if (step.type == QuestStepType.reward &&
        reward != null &&
        !grantedRewardIds.contains(reward.id)) {
      grantedRewardIds.add(reward.id);
      rewardsToGrant.add(reward);
    }

    return status.copyWith(
      currentStepIndex: status.currentStepIndex + 1,
      completedStepIds: completedStepIds,
      grantedRewardIds: grantedRewardIds,
      worldState: worldState,
    );
  }

  Future<void> _saveStatus(QuestStatus status) async {
    _statuses = {..._statuses, status.questId: status};
    await statusStore.saveForProfile(profileId, _statuses);
  }

  Future<void> _grantRewards(List<QuestRewardDefinition> rewards) async {
    for (final reward in rewards) {
      await inventoryStore.grantReward(
        profileId: profileId,
        reward: GameReward.fromQuestReward(reward),
      );
    }
  }

  QuestDefinition _quest(String questId) {
    final quest = _questsById[questId];
    if (quest == null) throw StateError('Unknown quest: $questId');
    return quest;
  }
}
