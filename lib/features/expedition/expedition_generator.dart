import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpeditionIntroFrame {
  final String speaker;
  final String animation;
  final String text;

  const ExpeditionIntroFrame({
    required this.speaker,
    required this.animation,
    required this.text,
  });
}

class ExpeditionConfig {
  final String worldId;
  final String storyId;
  final String title;
  final List<ExpeditionIntroFrame> storyIntro;
  final String storyOutro;
  final List<String> stationIds;

  const ExpeditionConfig({
    required this.worldId,
    required this.storyId,
    required this.title,
    required this.storyIntro,
    required this.storyOutro,
    required this.stationIds,
  });
}

class ExpeditionGenerator {
  final math.Random _random;

  ExpeditionGenerator({math.Random? random}) : _random = random ?? math.Random();

  Future<bool> shouldTriggerExpedition(String worldId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayed = prefs.getString('expedition_${worldId}_last_played');
    if (lastPlayed == null || lastPlayed.isEmpty) return true;
    final parsed = DateTime.tryParse(lastPlayed);
    if (parsed == null) return true;
    return DateTime.now().difference(parsed).inDays >= 14;
  }

  Future<ExpeditionConfig?> generate(String worldId) async {
    final raw = await rootBundle.loadString('assets/quests/expedition_stories.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final world = (json['expeditions'] as List)
        .map((item) => (item as Map).cast<String, dynamic>())
        .firstWhere((item) => item['worldId'] == worldId, orElse: () => const {});
    if (world.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final playedKey = 'expedition_${worldId}_stories_played';
    var played = List<String>.from(prefs.getStringList(playedKey) ?? const []);
    final stories = (world['stories'] as List).map((item) => (item as Map).cast<String, dynamic>()).toList();
    if (played.length >= stories.length) {
      played = [];
      await prefs.setStringList(playedKey, played);
    }
    final story = stories.firstWhere(
      (item) => !played.contains(item['storyId']),
      orElse: () => stories.first,
    );
    final eligible = (story['eligibleStations'] as List).cast<String>();
    final stations = eligible.toList()..shuffle(_random);

    return ExpeditionConfig(
      worldId: worldId,
      storyId: story['storyId'] as String,
      title: story['title'] as String,
      storyIntro: (story['intro'] as List)
          .map(
            (item) {
              final map = (item as Map).cast<String, dynamic>();
              return ExpeditionIntroFrame(
                speaker: map['speaker'] as String,
                animation: map['animation'] as String? ?? 'idle',
                text: map['text'] as String,
              );
            },
          )
          .toList(),
      storyOutro: story['outro'] as String,
      stationIds: stations.take(3).toList(),
    );
  }

  Future<void> recordExpeditionPlayed(String worldId, String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final playedKey = 'expedition_${worldId}_stories_played';
    final played = List<String>.from(prefs.getStringList(playedKey) ?? const []);
    if (!played.contains(storyId)) played.add(storyId);
    await prefs.setStringList(playedKey, played);
    await prefs.setString('expedition_${worldId}_last_played', today);
  }
}
