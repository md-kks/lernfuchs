import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'daily_path.dart';

class DailyPathStore {
  static const _keyPrefix = 'lf_daily_path_';

  const DailyPathStore();

  Future<DailyPathProgress> loadForProfile({
    required String profileId,
    required String dateKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$profileId-$dateKey');
    if (raw == null) {
      return DailyPathProgress(profileId: profileId, dateKey: dateKey);
    }
    return DailyPathProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(DailyPathProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix${progress.profileId}-${progress.dateKey}',
      jsonEncode(progress.toJson()),
    );
  }
}
