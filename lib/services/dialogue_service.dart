import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../models/station_dialogue.dart';

class DialogueService {
  final math.Random _random = math.Random();
  Map<String, StationDialogue>? _cache;

  Future<void> load() async {
    if (_cache != null) return;
    final raw = await rootBundle.loadString('assets/quests/quest_dialogues.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final stations = (json['stations'] as List? ?? const [])
        .map((item) => StationDialogue.fromJson((item as Map).cast<String, dynamic>()));
    _cache = {for (final station in stations) station.stationId: station};
  }

  Future<StationDialogue?> getDialogue(String stationId) async {
    await load();
    return _cache?[stationId];
  }

  Future<String> randomCorrectPhrase(String stationId) async {
    final dialogue = await getDialogue(stationId);
    final phrases = dialogue?.correctPhrases ?? const [];
    if (phrases.isEmpty) return 'Richtig!';
    return phrases[_random.nextInt(phrases.length)];
  }

  Future<String> randomWrongPhrase(String stationId) async {
    final dialogue = await getDialogue(stationId);
    final phrases = dialogue?.wrongAnswerPhrases ?? const [];
    if (phrases.isEmpty) return 'Versuch es nochmal!';
    return phrases[_random.nextInt(phrases.length)];
  }
}
