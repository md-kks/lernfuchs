import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../core/learning/learning.dart';
import '../../core/models/subject.dart';
import '../../services/school_mode_service.dart';

class DailyTaskConfig {
  final String narrativeId;
  final String narrativeText;
  final String narrativeSpeaker;
  final List<LearningRequest> requests;
  final List<String> competencyIds;

  const DailyTaskConfig({
    required this.narrativeId,
    required this.narrativeText,
    required this.narrativeSpeaker,
    required this.requests,
    required this.competencyIds,
  });
}

class DailyTaskGenerator {
  final LearningEngine learningEngine;
  final String profileId;
  final SchoolModeService? schoolModeService;

  const DailyTaskGenerator({
    required this.learningEngine,
    required this.profileId,
    this.schoolModeService,
  });

  Future<DailyTaskConfig> generate(String worldId) async {
    final date = DateTime.now();
    final dateInt = int.parse(
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}',
    );
    final narratives = await _loadNarratives();
    final narrative = narratives[dateInt % narratives.length];
    final competencies = _competencyPool();
    final schoolCompetencies = schoolModeService?.activeCompetencies ?? const [];
    final scored = competencies.map((request) {
      final progress = learningEngine.progressFor(
        profileId: profileId,
        subject: request.subject,
        grade: request.grade,
        topic: request.topic,
      );
      final eloProxy = math.max(1.0, 1.0 + progress.accuracy * 100);
      final days = DateTime.now().difference(progress.lastPracticed).inDays;
      var score = (1.0 / eloProxy) * 0.6 + (days / 30.0).clamp(0, 1) * 0.4;
      if (schoolCompetencies.contains(request.topic)) {
        score *= 2.5;
      }
      return (request: request, score: score, success: progress.accuracy);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final selected = <LearningRequest>[];
    for (final item in scored) {
      if (selected.any((r) => r.topic == item.request.topic)) continue;
      selected.add(item.request);
      if (selected.length == 2) break;
    }
    final successPool = scored.toList()
      ..sort((a, b) => b.success.compareTo(a.success));
    for (final item in successPool) {
      if (selected.any((r) => r.topic == item.request.topic)) continue;
      selected.add(item.request);
      break;
    }
    while (selected.length < 3) {
      selected.add(competencies[(dateInt + selected.length) % competencies.length]);
    }

    return DailyTaskConfig(
      narrativeId: narrative['id'] as String,
      narrativeText: narrative['text'] as String,
      narrativeSpeaker: narrative['speaker'] as String,
      requests: selected.take(3).toList(),
      competencyIds: selected.take(3).map((request) => request.topic).toList(),
    );
  }

  List<LearningRequest> _competencyPool() {
    return const [
      LearningRequest(subject: Subject.math, grade: 1, topic: 'addition_bis_10', difficulty: 1, count: 1),
      LearningRequest(subject: Subject.math, grade: 1, topic: 'subtraktion_bis_10', difficulty: 1, count: 1),
      LearningRequest(subject: Subject.math, grade: 1, topic: 'zahlen_bis_20', difficulty: 1, count: 1),
      LearningRequest(subject: Subject.german, grade: 1, topic: 'buchstaben', difficulty: 1, count: 1),
      LearningRequest(subject: Subject.german, grade: 1, topic: 'silben', difficulty: 1, count: 1),
      LearningRequest(subject: Subject.german, grade: 1, topic: 'anlaute', difficulty: 1, count: 1),
    ];
  }

  Future<List<Map<String, dynamic>>> _loadNarratives() async {
    final raw = await rootBundle.loadString('assets/quests/daily_task_narratives.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['narratives'] as List).map((item) => (item as Map).cast<String, dynamic>()).toList();
  }
}
