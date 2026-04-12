import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'quest_status.dart';

class QuestStatusStore {
  static const _keyPrefix = 'lf_quest_status_';

  const QuestStatusStore();

  Future<Map<String, QuestStatus>> loadForProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$profileId');
    if (raw == null) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (questId, statusJson) => MapEntry(
        questId,
        QuestStatus.fromJson((statusJson as Map).cast<String, dynamic>()),
      ),
    );
  }

  Future<void> saveForProfile(
    String profileId,
    Map<String, QuestStatus> statuses,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = statuses.map(
      (questId, status) => MapEntry(questId, status.toJson()),
    );
    await prefs.setString('$_keyPrefix$profileId', jsonEncode(encoded));
  }
}
