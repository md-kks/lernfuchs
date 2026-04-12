import '../quest/quest_definition.dart';

enum GameRewardType { collectible, upgradeUnlock }

class GameReward {
  final String id;
  final String title;
  final GameRewardType type;
  final int amount;
  final String? unlockUpgradeId;

  const GameReward({
    required this.id,
    required this.title,
    required this.type,
    this.amount = 1,
    this.unlockUpgradeId,
  });

  factory GameReward.fromQuestReward(QuestRewardDefinition reward) {
    return GameReward(
      id: reward.id,
      title: reward.title,
      type: reward.unlockUpgradeId == null
          ? GameRewardType.collectible
          : GameRewardType.upgradeUnlock,
      amount: reward.amount,
      unlockUpgradeId: reward.unlockUpgradeId,
    );
  }
}
