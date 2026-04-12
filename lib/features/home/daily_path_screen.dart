import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/learning.dart';
import '../../core/services/providers.dart';
import '../../game/reward/game_reward.dart';
import '../../game/reward/inventory_store.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_text_styles.dart';
import '../exercise/learning_challenge_overlay.dart';
import '../exercise/learning_session_mode.dart';

class DailyPathScreen extends ConsumerStatefulWidget {
  const DailyPathScreen({super.key});

  @override
  ConsumerState<DailyPathScreen> createState() => _DailyPathScreenState();
}

class _DailyPathScreenState extends ConsumerState<DailyPathScreen> {
  final _dailyPathStore = const DailyPathStore();
  final _inventoryStore = const InventoryStore();
  DailyPath? _path;
  DailyPathProgress? _progress;
  DailyPathStep? _activeStep;
  String? _message;
  int _challengeAttempt = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPath);
  }

  Future<void> _loadPath() async {
    final profile = ref.read(activeProfileProvider);
    if (profile == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final settings = ref.read(appSettingsProvider);
    final path = ref
        .read(dailyPathServiceProvider)
        .createPathForProfile(
          profile: profile,
          federalState: settings.federalState,
        );
    final progress = await _dailyPathStore.loadForProfile(
      profileId: path.profileId,
      dateKey: path.dateKey,
    );

    if (!mounted) return;
    setState(() {
      _path = path;
      _progress = progress;
      _loading = false;
    });
  }

  Future<void> _completeChallenge(LearningChallengeResult result) async {
    final path = _path;
    final progress = _progress;
    final step = _activeStep;
    if (path == null || progress == null || step == null) return;

    if (!result.successful) {
      setState(() {
        _message = 'Noch nicht geschafft. Versuch diesen Schritt nochmal.';
        _challengeAttempt++;
      });
      return;
    }

    var nextProgress = progress.completeStep(step.id);
    if (nextProgress.isComplete(path) && !nextProgress.rewardGranted) {
      await _inventoryStore.grantReward(
        profileId: path.profileId,
        reward: const GameReward(
          id: 'sternensamen',
          title: 'Sternensamen',
          type: GameRewardType.collectible,
          amount: 1,
        ),
      );
      nextProgress = nextProgress.copyWith(rewardGranted: true);
    }

    await _dailyPathStore.save(nextProgress);
    if (!mounted) return;
    setState(() {
      _progress = nextProgress;
      _activeStep = null;
      _message = nextProgress.isComplete(path)
          ? 'Tagespfad abgeschlossen. Du hast 1 Sternensamen erhalten.'
          : 'Schritt abgeschlossen.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    final progress = _progress;
    final activeStep = _activeStep;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagespfad'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (path == null || progress == null)
            const Center(child: Text('Lege zuerst ein Profil an.'))
          else
            _DailyPathBody(
              path: path,
              progress: progress,
              message: _message,
              onStartStep: (step) => setState(() {
                _activeStep = step;
                _message = null;
              }),
            ),
          if (activeStep != null)
            LearningChallengeOverlay(
              key: ValueKey('${activeStep.id}-$_challengeAttempt'),
              title: _titleForStep(activeStep),
              request: activeStep.toLearningRequest(),
              mode: LearningSessionMode.dailyPath,
              message: _message,
              onCompleted: _completeChallenge,
              onClose: () => setState(() => _activeStep = null),
            ),
        ],
      ),
    );
  }

  String _titleForStep(DailyPathStep step) {
    return '${step.subject.label}: ${step.topic}';
  }
}

class _DailyPathBody extends StatelessWidget {
  final DailyPath path;
  final DailyPathProgress progress;
  final String? message;
  final ValueChanged<DailyPathStep> onStartStep;

  const _DailyPathBody({
    required this.path,
    required this.progress,
    required this.message,
    required this.onStartStep,
  });

  @override
  Widget build(BuildContext context) {
    final complete = progress.isComplete(path);
    if (path.steps.isEmpty) {
      return const Center(child: Text('Heute gibt es keinen Tagespfad.'));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Heute üben', style: AppTextStyles.headlineLarge),
        const SizedBox(height: 8),
        Text('Kurzer Pfad für Klasse ${path.steps.first.grade}.'),
        if (message != null) ...[const SizedBox(height: 16), Text(message!)],
        const SizedBox(height: 20),
        for (final step in path.steps) ...[
          _DailyPathStepTile(
            step: step,
            completed: progress.isStepCompleted(step.id),
            enabled: !complete,
            onStart: () => onStartStep(step),
          ),
          const SizedBox(height: 12),
        ],
        if (complete)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belohnung: 1 Sternensamen'),
            ),
          ),
      ],
    );
  }
}

class _DailyPathStepTile extends StatelessWidget {
  final DailyPathStep step;
  final bool completed;
  final bool enabled;
  final VoidCallback onStart;

  const _DailyPathStepTile({
    required this.step,
    required this.completed,
    required this.enabled,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle_rounded : Icons.route_rounded,
              color: completed ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${step.subject.label}: ${step.topic}',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(_reasonLabel(step.reason)),
                ],
              ),
            ),
            FilledButton(
              onPressed: completed || !enabled ? null : onStart,
              child: Text(completed ? 'Fertig' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }

  String _reasonLabel(DailyPathReason reason) {
    return switch (reason) {
      DailyPathReason.weakArea => 'Schwerpunkt aus deinen letzten Ergebnissen',
      DailyPathReason.freshTopic => 'Passendes neues Thema',
      DailyPathReason.recentReview => 'Kurze Wiederholung',
    };
  }
}
