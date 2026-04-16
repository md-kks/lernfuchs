import '../models/progress.dart';
import '../models/subject.dart';
import 'daily_path.dart';
import 'learning_engine.dart';

class DailyPathService {
  final LearningEngine learningEngine;
  final DateTime Function() now;

  const DailyPathService({
    required this.learningEngine,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  DailyPath createPathForProfile({
    required ChildProfile profile,
    required String federalState,
  }) {
    final date = now();
    final dateKey = _dateKey(date);
    final progress = learningEngine.allProgressForProfile(profile.id);
    final candidates = _candidatesFor(
      profile: profile,
      federalState: federalState,
      progress: progress,
    );
    final selected = _selectCandidates(candidates);

    return DailyPath(
      profileId: profile.id,
      dateKey: dateKey,
      steps: [
        for (var index = 0; index < selected.length; index++)
          DailyPathStep(
            id: 'daily_${dateKey}_${selected[index].key}',
            subject: selected[index].subject,
            grade: selected[index].grade,
            topic: selected[index].topic,
            difficulty: _difficultyFor(selected[index], profile.grade),
            reason: _reasonFor(selected[index]),
            seed: _stableSeed('${profile.id}-$dateKey-${selected[index].key}'),
          ),
      ],
    );
  }

  List<DailyPathCandidate> _candidatesFor({
    required ChildProfile profile,
    required String federalState,
    required List<TopicProgress> progress,
  }) {
    final progressByKey = {
      for (final item in progress.where((item) => item.grade == profile.grade))
        '${item.subject}-${item.grade}-${item.topic}': item,
    };
    final candidates = <DailyPathCandidate>[];
    for (final subject in Subject.values) {
      final topics = learningEngine.topicsFor(
        federalState: federalState,
        subject: subject,
        grade: profile.grade,
      );
      for (final topic in topics) {
        candidates.add(
          DailyPathCandidate(
            subject: subject,
            grade: profile.grade,
            topic: topic,
            progress: progressByKey['${subject.id}-${profile.grade}-$topic'],
          ),
        );
      }
    }
    return candidates;
  }

  List<DailyPathCandidate> _selectCandidates(List<DailyPathCandidate> all) {
    final selected = <DailyPathCandidate>[];

    final weak = all.where((candidate) {
      final progress = candidate.progress;
      return progress != null &&
          progress.totalAttempts > 0 &&
          progress.accuracy < 0.75;
    }).toList()..sort(_compareWeakness);
    _addUnique(selected, weak.firstOrNull);

    final recentTopicKeys =
        all.where((candidate) => candidate.progress != null).toList()
          ..sort(_compareRecent);
    final recentKeys = recentTopicKeys
        .take(3)
        .map((candidate) => candidate.key);

    final fresh =
        all
            .where((candidate) => !recentKeys.contains(candidate.key))
            .where((candidate) => candidate.progress == null)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    _addUnique(selected, fresh.firstOrNull);

    _addUnique(selected, recentTopicKeys.firstOrNull);

    for (final fallback in all) {
      if (selected.length >= 3) break;
      _addUnique(selected, fallback);
    }

    return selected.take(3).toList();
  }

  int _difficultyFor(DailyPathCandidate candidate, int grade) {
    final progress = candidate.progress;
    if (progress == null) return 1;
    return learningEngine.initialDifficulty(progress: progress, grade: grade);
  }

  DailyPathReason _reasonFor(DailyPathCandidate candidate) {
    final progress = candidate.progress;
    if (progress != null &&
        progress.totalAttempts > 0 &&
        progress.accuracy < 0.75) {
      return DailyPathReason.weakArea;
    }
    if (progress != null) return DailyPathReason.recentReview;
    return DailyPathReason.freshTopic;
  }

  static int _compareWeakness(DailyPathCandidate a, DailyPathCandidate b) {
    final aProgress = a.progress!;
    final bProgress = b.progress!;
    final accuracy = aProgress.accuracy.compareTo(bProgress.accuracy);
    if (accuracy != 0) return accuracy;
    return bProgress.lastPracticed.compareTo(aProgress.lastPracticed);
  }

  static int _compareRecent(DailyPathCandidate a, DailyPathCandidate b) {
    return b.progress!.lastPracticed.compareTo(a.progress!.lastPracticed);
  }

  static void _addUnique(
    List<DailyPathCandidate> selected,
    DailyPathCandidate? candidate,
  ) {
    if (candidate == null) return;
    if (selected.any((item) => item.key == candidate.key)) return;
    selected.add(candidate);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static int _stableSeed(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
