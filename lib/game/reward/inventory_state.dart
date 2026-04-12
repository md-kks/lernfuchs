import 'game_reward.dart';

class InventoryState {
  final Map<String, int> collectibles;
  final List<String> unlockedUpgradeIds;

  const InventoryState({
    this.collectibles = const {},
    this.unlockedUpgradeIds = const [],
  });

  int collectibleAmount(String id) => collectibles[id] ?? 0;

  bool hasUpgrade(String id) => unlockedUpgradeIds.contains(id);

  InventoryState applyReward(GameReward reward) {
    final nextCollectibles = {...collectibles};
    final nextUpgradeIds = {...unlockedUpgradeIds};

    if (reward.amount > 0) {
      nextCollectibles[reward.id] =
          (nextCollectibles[reward.id] ?? 0) + reward.amount;
    }

    final upgradeId = reward.unlockUpgradeId;
    if (upgradeId != null) {
      nextUpgradeIds.add(upgradeId);
    }

    return InventoryState(
      collectibles: nextCollectibles,
      unlockedUpgradeIds: nextUpgradeIds.toList()..sort(),
    );
  }

  Map<String, dynamic> toJson() => {
    'collectibles': collectibles,
    'unlockedUpgradeIds': unlockedUpgradeIds,
  };

  factory InventoryState.fromJson(Map<String, dynamic> json) {
    return InventoryState(
      collectibles: (json['collectibles'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), value as int),
      ),
      unlockedUpgradeIds: (json['unlockedUpgradeIds'] as List? ?? const [])
          .cast<String>(),
    );
  }
}
