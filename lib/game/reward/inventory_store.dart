import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_reward.dart';
import 'inventory_state.dart';

class InventoryStore {
  static const _keyPrefix = 'lf_inventory_';

  const InventoryStore();

  Future<InventoryState> loadForProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$profileId');
    if (raw == null) return const InventoryState();
    return InventoryState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveForProfile(
    String profileId,
    InventoryState inventory,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$profileId',
      jsonEncode(inventory.toJson()),
    );
  }

  Future<InventoryState> grantReward({
    required String profileId,
    required GameReward reward,
  }) async {
    final inventory = await loadForProfile(profileId);
    final next = inventory.applyReward(reward);
    await saveForProfile(profileId, next);
    return next;
  }
}
