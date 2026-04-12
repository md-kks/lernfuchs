import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/providers.dart';
import '../../game/dialogue/hint_definition.dart';
import '../../game/dialogue/hint_definition_loader.dart';
import '../exercise/learning_session_mode.dart';
import '../quest/forest_quest_overlay.dart';
import '../../game/quest/quest_definition.dart';
import '../../game/quest/quest_definition_loader.dart';
import '../../game/quest/quest_runtime.dart';
import '../../game/quest/quest_status_store.dart';
import '../../game/world/lern_fuchs_world_game.dart';
import '../../game/world/world_map_background.dart';
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
  HintLibrary? _hintLibrary;
  bool _loadingQuests = true;
  String? _questFeedback;
  int _challengeAttempt = 0;
  int _highestUnlockedOrder = 0;
  String? _ovaMessageNodeId;
  bool _finoIsMoving = false;

  @override
  void initState() {
    super.initState();
    _game = LernFuchsWorldGame(
      onQuestNodeTapped: (questNode) {
        _handleQuestNodeTapped(questNode);
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
    final prefs = await SharedPreferences.getInstance();
    final profileId = ref.read(appSettingsProvider).activeProfileId;
    final highestUnlockedOrder =
        prefs.getInt('lf_world_highest_unlocked_order_$profileId') ?? 0;
    if (!mounted) return;
    _game.updateUnlockedOrder(highestUnlockedOrder);
    setState(() {
      _questRuntime = runtime;
      _hintLibrary = hintLibrary;
      _highestUnlockedOrder = highestUnlockedOrder;
      _loadingQuests = false;
    });
  }

  void _handleQuestNodeTapped(WorldQuestNode questNode) {
    if (_finoIsMoving) return;
    if (questNode.order != _highestUnlockedOrder) return;
    if (_ovaMessageNodeId == questNode.id) {
      _openQuestOverlay(questNode);
      return;
    }
    _game.showStoryPopup(questNode, () => _openQuestOverlay(questNode));
  }

  Future<void> _openQuestOverlay(WorldQuestNode questNode) async {
    final runtime = _questRuntime;
    final questId = questNode.questId;
    if (runtime == null || questId == null) {
      return;
    }

    await runtime.startQuest(questId);
    final quest = runtime.quests.firstWhere((quest) => quest.id == questId);
    final step = runtime.currentStep(quest.id);
    if (step?.type == QuestStepType.dialogue) {
      final status = await runtime.completeCurrentStep(quest.id);
      _game.updateWorldState(status.worldState);
    }
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

  Future<void> _completeQuestChallenge(LearningChallengeResult result) async {
    final runtime = _questRuntime;
    final quest = _selectedQuest;
    final completedNode = _selectedQuestNode;
    if (runtime == null || quest == null || completedNode == null) return;

    final challenge = runtime.currentStep(quest.id)?.learningChallenge;
    if (result.successful) {
      final status = await runtime.completeCurrentStep(quest.id);
      _game.updateWorldState(status.worldState);
      await _unlockNextNode(completedNode);
    }
    setState(() {
      _questFeedback = result.successful
          ? challenge?.successText
          : challenge?.retryText;
      if (!result.successful) _challengeAttempt++;
      if (result.successful) {
        _selectedQuestNode = null;
        _selectedQuest = null;
      }
    });
  }

  Future<void> _unlockNextNode(WorldQuestNode completedNode) async {
    final nextOrder = (_highestUnlockedOrder + 1).clamp(
      0,
      LernFuchsWorldGame.questNodes.length - 1,
    );
    if (nextOrder == _highestUnlockedOrder) return;
    final nextNode = LernFuchsWorldGame.questNodes.firstWhere(
      (node) => node.order == nextOrder,
    );
    final profileId = ref.read(appSettingsProvider).activeProfileId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lf_world_highest_unlocked_order_$profileId', nextOrder);

    final edgeIndex =
        WorldMapBackground.sequentialEdges[_highestUnlockedOrder.clamp(
          0,
          WorldMapBackground.sequentialEdges.length - 1,
        )];
    setState(() {
      _highestUnlockedOrder = nextOrder;
      _ovaMessageNodeId = nextNode.id;
      _finoIsMoving = true;
    });
    _game.startFinoWalk(edgeIndex, () {
      if (!mounted) return;
      setState(() => _finoIsMoving = false);
    });
    _game.updateUnlockedOrder(nextOrder);
    _game.showOvaBubble(
      completedNode: completedNode,
      nextNode: nextNode,
      edgeIndex: edgeIndex,
    );

    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted || _ovaMessageNodeId != nextNode.id) return;
      setState(() => _ovaMessageNodeId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedQuestNode = _selectedQuestNode;
    final runtime = _questRuntime;
    final hintLibrary = _hintLibrary;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flüsterwald'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
        child: Stack(
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
            if (selectedQuestNode != null &&
                _selectedQuest != null &&
                runtime != null)
              Positioned.fill(
                child: ForestQuestOverlay(
                  key: ValueKey('${_selectedQuest!.id}-$_challengeAttempt'),
                  questNode: selectedQuestNode,
                  quest: _selectedQuest!,
                  runtime: runtime,
                  feedback: _questFeedback,
                  hintSet: () {
                    final step = runtime.currentStep(_selectedQuest!.id);
                    final hintSetId = step?.hintSetId;
                    return hintSetId == null
                        ? null
                        : hintLibrary?.hintSet(hintSetId);
                  }(),
                  bottomInset: padding.bottom,
                  onCompleted: _completeQuestChallenge,
                  onClose: _closeQuestOverlay,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
