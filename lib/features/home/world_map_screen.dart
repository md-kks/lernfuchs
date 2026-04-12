import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../game/dialogue/dialogue_definition.dart';
import '../../game/dialogue/dialogue_definition_loader.dart';
import '../../game/dialogue/dialogue_overlay.dart';
import '../../game/dialogue/hint_definition.dart';
import '../../game/dialogue/hint_definition_loader.dart';
import '../exercise/learning_session_mode.dart';
import '../quest/forest_quest_overlay.dart';
import '../../game/quest/quest_definition.dart';
import '../../game/quest/quest_definition_loader.dart';
import '../../game/quest/quest_runtime.dart';
import '../../game/quest/quest_status.dart';
import '../../game/quest/quest_status_store.dart';
import '../../game/world/lern_fuchs_world_game.dart';
import '../../game/world/world_quest_node.dart';
import '../../shared/constants/app_colors.dart';

class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  late final LernFuchsWorldGame _game;
  WorldQuestNode? _selectedQuestNode;
  QuestRuntime? _questRuntime;
  QuestDefinition? _selectedQuest;
  DialogueLibrary? _dialogueLibrary;
  HintLibrary? _hintLibrary;
  bool _loadingQuests = true;
  String? _questFeedback;
  int _challengeAttempt = 0;

  @override
  void initState() {
    super.initState();
    _game = LernFuchsWorldGame(
      onQuestNodeTapped: (questNode) {
        _openQuestOverlay(questNode);
      },
    );
    _loadQuestRuntime();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadQuestRuntime() async {
    final quests = await const QuestDefinitionLoader().loadFromAsset(
      'assets/quests/sample_quests.json',
    );
    final dialogueLibrary = await const DialogueDefinitionLoader()
        .loadFromAsset('assets/dialogue/ova_dialogues.json');
    final hintLibrary = await const HintDefinitionLoader().loadFromAsset(
      'assets/dialogue/learning_hints.json',
    );
    final runtime = QuestRuntime(
      profileId: ref.read(appSettingsProvider).activeProfileId,
      learningEngine: ref.read(learningEngineProvider),
      statusStore: const QuestStatusStore(),
      quests: quests,
    );
    await runtime.load();
    if (!mounted) return;
    setState(() {
      _questRuntime = runtime;
      _dialogueLibrary = dialogueLibrary;
      _hintLibrary = hintLibrary;
      _loadingQuests = false;
    });
  }

  Future<void> _openQuestOverlay(WorldQuestNode questNode) async {
    final runtime = _questRuntime;
    final questId = questNode.questId;
    if (runtime == null || questId == null) {
      return;
    }

    await runtime.startQuest(questId);
    final quest = runtime.quests.firstWhere((quest) => quest.id == questId);
    setState(() {
      _selectedQuestNode = questNode;
      _selectedQuest = quest;
      _questFeedback = null;
      _challengeAttempt = 0;
    });
  }

  void _closeQuestOverlay() {
    setState(() {
      _selectedQuestNode = null;
      _selectedQuest = null;
      _questFeedback = null;
    });
  }

  Future<void> _advanceQuest() async {
    final runtime = _questRuntime;
    final quest = _selectedQuest;
    if (runtime == null || quest == null) return;

    final status = await runtime.completeCurrentStep(quest.id);
    _game.updateWorldState(status.worldState);
    setState(() {
      _questFeedback = null;
    });
  }

  Future<void> _completeQuestChallenge(LearningChallengeResult result) async {
    final runtime = _questRuntime;
    final quest = _selectedQuest;
    if (runtime == null || quest == null) return;

    final challenge = runtime.currentStep(quest.id)?.learningChallenge;
    if (result.successful) {
      final status = await runtime.completeCurrentStep(quest.id);
      _game.updateWorldState(status.worldState);
    }
    setState(() {
      _questFeedback = result.successful
          ? challenge?.successText
          : challenge?.retryText;
      if (!result.successful) _challengeAttempt++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedQuestNode = _selectedQuestNode;
    final selectedQuest = _selectedQuest;
    final runtime = _questRuntime;
    final dialogueLibrary = _dialogueLibrary;
    final hintLibrary = _hintLibrary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flüsterwald'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GameWidget(game: _game),
          if (_loadingQuests)
            const Positioned(
              left: 16,
              top: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Quests werden geladen...'),
                ),
              ),
            ),
          if (selectedQuestNode != null)
            _QuestOverlay(
              questNode: selectedQuestNode,
              quest: selectedQuest,
              runtime: runtime,
              dialogueLibrary: dialogueLibrary,
              hintLibrary: hintLibrary,
              feedback: _questFeedback,
              challengeAttempt: _challengeAttempt,
              onAdvance: _advanceQuest,
              onChallengeCompleted: _completeQuestChallenge,
              onClose: _closeQuestOverlay,
            ),
        ],
      ),
    );
  }
}

class _QuestOverlay extends StatelessWidget {
  final WorldQuestNode questNode;
  final QuestDefinition? quest;
  final QuestRuntime? runtime;
  final DialogueLibrary? dialogueLibrary;
  final HintLibrary? hintLibrary;
  final String? feedback;
  final int challengeAttempt;
  final VoidCallback onAdvance;
  final ValueChanged<LearningChallengeResult> onChallengeCompleted;
  final VoidCallback onClose;

  const _QuestOverlay({
    required this.questNode,
    required this.quest,
    required this.runtime,
    required this.dialogueLibrary,
    required this.hintLibrary,
    required this.feedback,
    required this.challengeAttempt,
    required this.onAdvance,
    required this.onChallengeCompleted,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final quest = this.quest;
    final runtime = this.runtime;
    final status = quest == null || runtime == null
        ? null
        : runtime.statusFor(quest.id);
    final step = quest == null || runtime == null
        ? null
        : runtime.currentStep(quest.id);

    if (quest != null &&
        runtime != null &&
        step?.type == QuestStepType.learningChallenge) {
      final hintSetId = step?.hintSetId;
      return ForestQuestOverlay(
        key: ValueKey('${quest.id}-$challengeAttempt'),
        questNode: questNode,
        quest: quest,
        runtime: runtime,
        feedback: feedback,
        hintSet: hintSetId == null ? null : hintLibrary?.hintSet(hintSetId),
        onCompleted: onChallengeCompleted,
        onClose: onClose,
      );
    }

    final activeDialogueLibrary = dialogueLibrary;
    if (step?.type == QuestStepType.dialogue &&
        step?.dialogueSceneId != null &&
        activeDialogueLibrary != null) {
      final scene = activeDialogueLibrary.scene(step!.dialogueSceneId!);
      if (scene != null) {
        return DialogueOverlay(
          library: activeDialogueLibrary,
          scene: scene,
          onFinished: onAdvance,
          onClose: onClose,
        );
      }
    }

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withAlpha(80),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest?.title ?? questNode.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (quest == null || runtime == null) ...[
                    Text(questNode.subtitle),
                  ] else ...[
                    _QuestStepBody(
                      status: status!,
                      step: step,
                      feedback: feedback,
                      onAdvance: onAdvance,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: onClose,
                      child: const Text('Schließen'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestStepBody extends StatelessWidget {
  final QuestStatus status;
  final QuestStepDefinition? step;
  final String? feedback;
  final VoidCallback onAdvance;

  const _QuestStepBody({
    required this.status,
    required this.step,
    required this.feedback,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    if (status.state == QuestRunState.completed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quest abgeschlossen.'),
          if (feedback != null) ...[const SizedBox(height: 8), Text(feedback!)],
          const SizedBox(height: 8),
          Text('Belohnungen: ${status.grantedRewardIds.join(', ')}'),
          Text('Weltstatus: ${status.worldState}'),
        ],
      );
    }

    final step = this.step;
    if (step == null) return const Text('Keine Quest-Schritte verfügbar.');

    if (step.type == QuestStepType.dialogue) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.text),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAdvance, child: const Text('Weiter')),
        ],
      );
    }

    return const Text('Quest-Schritt wird automatisch verarbeitet.');
  }
}
