import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/game/reward/game_reward.dart';
import 'package:lernfuchs/game/reward/inventory_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'inventory persists collectibles and unlocked upgrades per profile',
    () async {
      SharedPreferences.setMockInitialValues({});
      const store = InventoryStore();

      await store.grantReward(
        profileId: 'profile_1',
        reward: const GameReward(
          id: 'sternensamen',
          title: 'Sternensamen',
          type: GameRewardType.upgradeUnlock,
          amount: 3,
          unlockUpgradeId: 'leaf_canopy',
        ),
      );

      final profileOne = await store.loadForProfile('profile_1');
      final profileTwo = await store.loadForProfile('profile_2');

      expect(profileOne.collectibleAmount('sternensamen'), 3);
      expect(profileOne.hasUpgrade('leaf_canopy'), isTrue);
      expect(profileTwo.collectibleAmount('sternensamen'), 0);
      expect(profileTwo.hasUpgrade('leaf_canopy'), isFalse);
    },
  );
}
