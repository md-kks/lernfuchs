import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/game/reward/game_reward.dart';
import 'package:lernfuchs/game/reward/inventory_state.dart';
import 'package:lernfuchs/game/reward/inventory_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('InventoryState applies collectibles and upgrades correctly', () {
    var state = const InventoryState();
    
    state = state.applyReward(const GameReward(
      id: 'coin',
      title: 'Coin',
      type: GameRewardType.collectible,
      amount: 5,
    ));
    
    expect(state.collectibleAmount('coin'), 5);
    
    state = state.applyReward(const GameReward(
      id: 'upgrade_1',
      title: 'Upgrade',
      type: GameRewardType.upgradeUnlock,
      unlockUpgradeId: 'baumhaus_bank',
    ));
    
    expect(state.hasUpgrade('baumhaus_bank'), isTrue);
    expect(state.unlockedUpgradeIds, contains('baumhaus_bank'));
  });

  test('InventoryStore persists state across loads', () async {
    SharedPreferences.setMockInitialValues({});
    const store = InventoryStore();
    const profileId = 'test_p';
    
    await store.grantReward(
      profileId: profileId,
      reward: const GameReward(
        id: 'gem',
        title: 'Gem',
        type: GameRewardType.collectible,
        amount: 1,
      ),
    );
    
    final state = await store.loadForProfile(profileId);
    expect(state.collectibleAmount('gem'), 1);
  });
}
