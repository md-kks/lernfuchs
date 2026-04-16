import 'package:shared_preferences/shared_preferences.dart';

const baumhausItems = {
  'baumhaus_bank': 'Gemütliche Bank',
  'baumhaus_laterne': 'Leuchtende Laterne',
  'baumhaus_goldener_schwanz': 'Goldener Schwanz für Fino',
  'baumhaus_kristall_blau': 'Blauer Kristall',
};

class StreakService {
  String _day(DateTime date) => date.toIso8601String().substring(0, 10);

  Future<int> get currentStreak async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('daily_streak_count') ?? 0;
    final lastDay = prefs.getString('daily_streak_last_day') ?? '';
    final today = _day(DateTime.now());
    final yesterday = _day(DateTime.now().subtract(const Duration(days: 1)));
    if (lastDay == today || lastDay == yesterday) return count;
    return 0;
  }

  Future<bool> get playedToday async {
    final prefs = await SharedPreferences.getInstance();
    final today = _day(DateTime.now());
    return (prefs.getString('daily_task_last_played') ?? '') == today;
  }

  Future<int> recordTaskCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _day(DateTime.now());
    final lastDay = prefs.getString('daily_streak_last_day') ?? '';
    if (lastDay == today) return prefs.getInt('daily_streak_count') ?? 0;
    final yesterday = _day(DateTime.now().subtract(const Duration(days: 1)));
    final next = lastDay == yesterday ? (prefs.getInt('daily_streak_count') ?? 0) + 1 : 1;
    await prefs.setInt('daily_streak_count', next);
    await prefs.setString('daily_streak_last_day', today);
    await prefs.setString('daily_task_last_played', today);
    return next;
  }

  Future<List<String>> get earnedBaumhausItems async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(prefs.getStringList('baumhaus_items') ?? const []);
  }

  Future<bool> awardBaumhausItem(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = List<String>.from(prefs.getStringList('baumhaus_items') ?? const []);
    if (items.contains(itemId)) return false;
    items.add(itemId);
    await prefs.setStringList('baumhaus_items', items);
    return true;
  }
}
