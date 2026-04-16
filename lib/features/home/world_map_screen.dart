import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/providers.dart';
import '../../game/dialogue/hint_definition.dart';
import '../../game/dialogue/hint_definition_loader.dart';
import '../exercise/learning_session_mode.dart';
import '../quest/forest_quest_overlay.dart';
import '../quest/finale_cutscene_screen.dart';
import '../quest/quest_intro_screen.dart';
import '../quest/quest_reward_overlay.dart';
import '../expedition/expedition_generator.dart';
import '../expedition/expedition_screen.dart';
import '../../game/quest/quest_definition.dart';
import '../../game/quest/quest_definition_loader.dart';
import '../../game/quest/quest_runtime.dart';
import '../../game/quest/quest_status_store.dart';
import '../../game/world/lern_fuchs_world_game.dart';
import '../../game/world/world_map_background.dart';
import '../../game/world/world_quest_node.dart';
import '../../models/station_dialogue.dart';
import '../baumhaus/baumhaus_painter.dart';
import '../../services/audio_service.dart';
import '../../services/fino_evolution_service.dart';
import '../../shared/constants/app_colors.dart';

class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  late final LernFuchsWorldGame _game;
  late final AudioService _audio;
  WorldQuestNode? _selectedQuestNode;
  QuestRuntime? _questRuntime;
  QuestDefinition? _selectedQuest;
  WorldQuestNode? _introQuestNode;
  StationDialogue? _introDialogue;
  StationDialogue? _selectedDialogue;
  HintLibrary? _hintLibrary;
  bool _loadingQuests = true;
  String? _questFeedback;
  int _challengeAttempt = 0;
  int _highestUnlockedOrder = 0;
  String? _ovaMessageNodeId;
  bool _finoIsMoving = false;
  bool _expeditionAvailable = false;
  bool _expeditionRestored = false;
  int? _baumhausOverlayStage;
  bool _baumhausFinoAdvanced = false;
  List<QuestRewardDefinition> _pendingRewards = [];

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioServiceProvider);
    _game = LernFuchsWorldGame(
      audioService: _audio,
      onQuestNodeTapped: (questNode) {
        _handleQuestNodeTapped(questNode);
      },
    );
    _audio.playAmbient('fluesterwald');
    _audio.playMusic('main_theme');
    _loadQuestRuntime();
    _loadExpeditionState();
  }

  @override
  void dispose() {
    _audio.stopAmbient();
    _audio.stopMusic();
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

  Future<void> _loadExpeditionState() async {
    final available = await ExpeditionGenerator().shouldTriggerExpedition('fluesterwald');
    if (!mounted) return;
    setState(() {
      _expeditionAvailable = available;
      _expeditionRestored = !available;
    });
  }

  void _handleQuestNodeTapped(WorldQuestNode questNode) {
    if (_finoIsMoving) return;
    if (questNode.order != _highestUnlockedOrder) return;
    if (_ovaMessageNodeId == questNode.id) {
      _startQuestFlow(questNode);
      return;
    }
    ref.read(ttsServiceProvider).speak(questNode.storyText);
    _game.showStoryPopup(questNode, () => _startQuestFlow(questNode));
  }

  Future<void> _startQuestFlow(WorldQuestNode questNode) async {
    final dialogue = await ref
        .read(dialogueServiceProvider)
        .getDialogue(questNode.id);
    if (!mounted) return;
    if (dialogue == null) {
      await _openQuestOverlay(questNode, null);
      return;
    }
    setState(() {
      _introQuestNode = questNode;
      _introDialogue = dialogue;
    });
  }

  Future<void> _openQuestOverlay(
    WorldQuestNode questNode, [
    StationDialogue? dialogue,
  ]) async {
    final runtime = _questRuntime;
    final questId = questNode.questId;
    if (runtime == null || questId == null) {
      return;
    }

    await runtime.startQuest(questId);
    final quest = runtime.quests.firstWhere((quest) => quest.id == questId);
    final step = runtime.currentStep(quest.id);
    if (step?.type == QuestStepType.dialogue) {
      final completion = await runtime.completeCurrentStep(quest.id);
      _game.updateWorldState(completion.status.worldState);
    }
    setState(() {
      _selectedQuestNode = questNode;
      _selectedQuest = quest;
      _selectedDialogue = dialogue;
      _questFeedback = null;
      _challengeAttempt = 0;
      _introQuestNode = null;
      _introDialogue = null;
    });
  }

  void _closeQuestOverlay() {
    setState(() {
      _selectedQuestNode = null;
      _selectedQuest = null;
      _selectedDialogue = null;
      _questFeedback = null;
    });
  }

  Future<void> _completeQuestChallenge(LearningChallengeResult result) async {
    final runtime = _questRuntime;
    final quest = _selectedQuest;
    final completedNode = _selectedQuestNode;
    if (runtime == null || quest == null || completedNode == null) return;

    final challenge = runtime.currentStep(quest.id)?.learningChallenge;
    List<QuestRewardDefinition> rewards = [];

    if (result.successful) {
      final completion = await runtime.completeCurrentStep(quest.id);
      rewards = completion.rewards;
      _game.updateWorldState(completion.status.worldState);
      await _unlockNextNode(completedNode);
      if (completedNode.order == LernFuchsWorldGame.questNodes.length - 1) {
        await _completeWorldIfNeeded();
      }
    }
    setState(() {
      _questFeedback = result.successful
          ? challenge?.successText
          : challenge?.retryText;
      if (!result.successful) _challengeAttempt++;
      if (result.successful) {
        _selectedQuestNode = null;
        _selectedQuest = null;
        _selectedDialogue = null;
        _pendingRewards = rewards;
      }
    });
  }

  Future<void> _unlockNextNode(WorldQuestNode completedNode) async {
    final nextOrder = (_highestUnlockedOrder + 1).clamp(
      0,
      LernFuchsWorldGame.questNodes.length - 1,
    ).toInt();
    if (nextOrder == _highestUnlockedOrder) return;
    final nextNode = LernFuchsWorldGame.questNodes.firstWhere(
      (node) => node.order == nextOrder,
    );
    final profileId = ref.read(appSettingsProvider).activeProfileId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lf_world_highest_unlocked_order_$profileId', nextOrder);
    ref.read(audioServiceProvider).playSfx('node_unlock');

    final edgeIndex =
        WorldMapBackground.sequentialEdges[_highestUnlockedOrder
            .clamp(0, WorldMapBackground.sequentialEdges.length - 1)
            .toInt()];
    setState(() {
      _highestUnlockedOrder = nextOrder;
      _ovaMessageNodeId = nextNode.id;
      _finoIsMoving = true;
    });
    _game.updateUnlockedOrder(nextOrder, revealNextOnly: true);
    _game.showOvaBubble(
      completedNode: completedNode,
      nextNode: nextNode,
      edgeIndex: edgeIndex,
    );
    ref
        .read(ttsServiceProvider)
        .speak('Gut gemacht! ${nextNode.label} öffnet sich!');

    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _game.startFinoWalk(edgeIndex, () {
        if (!mounted) return;
        _game.updateUnlockedOrder(nextOrder);
        setState(() => _finoIsMoving = false);
        _game.showStoryPopup(nextNode, () => _startQuestFlow(nextNode));
        ref.read(soundServiceProvider).playCorrect().catchError((_) {});
      });
    });
    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted || _ovaMessageNodeId != nextNode.id) return;
      setState(() => _ovaMessageNodeId = null);
    });
  }

  Future<void> _completeWorldIfNeeded() async {
    final storage = ref.read(storageServiceProvider);
    final completedKey = 'world_1_completed_at';
    final wasAlreadyCompleted = storage.getStringValue(completedKey) != null;
    if (!wasAlreadyCompleted) {
      await storage.setOnboardingValue(
        completedKey,
        DateTime.now().toIso8601String(),
      );
    }
    final advanced = await ref.read(finoEvolutionProvider).checkAndAdvance();
    final currentBaumhaus = storage.getIntValue('baumhaus_stage', defaultValue: 0);
    final nextBaumhaus = wasAlreadyCompleted
        ? currentBaumhaus
        : currentBaumhaus >= 4
        ? 4
        : currentBaumhaus + 1;
    if (nextBaumhaus > currentBaumhaus) {
      await storage.setOnboardingValue('baumhaus_stage', nextBaumhaus);
    }
    if (!mounted || wasAlreadyCompleted && !advanced && nextBaumhaus == currentBaumhaus) {
      await _scheduleFinaleIfReady();
      return;
    }
    _showBaumhausAdvanceOverlay(nextBaumhaus, advanced);
    Future<void>.delayed(const Duration(milliseconds: 5200), () {
      if (mounted) _scheduleFinaleIfReady();
    });
  }

  Future<void> _scheduleFinaleIfReady() async {
    final storage = ref.read(storageServiceProvider);
    if (storage.getBoolValue('game_fully_completed', defaultValue: false)) {
      return;
    }
    final allWorldsCompleted = [1, 2, 3, 4].every(
      (world) => storage.getStringValue('world_${world}_completed_at') != null,
    );
    if (!allWorldsCompleted || !mounted) return;
    await storage.setOnboardingValue('game_fully_completed', true);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FinaleCutsceneScreen(
          onComplete: () {
            Navigator.of(context).pop();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  void _showBaumhausAdvanceOverlay(int stage, bool finoAdvanced) {
    setState(() {
      _baumhausOverlayStage = stage;
      _baumhausFinoAdvanced = finoAdvanced;
    });
    ref.read(ttsServiceProvider).speak('Das Große Buch hat eine neue Seite!');
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _baumhausOverlayStage == stage) {
        ref.read(ttsServiceProvider).speak('Dein Baumhaus ist gewachsen!');
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 3600), () {
      if (mounted && _baumhausOverlayStage == stage) {
        ref.read(ttsServiceProvider).speak('Fino wird stärker - genau wie du!');
      }
    });
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (mounted && _baumhausOverlayStage == stage) {
        setState(() => _baumhausOverlayStage = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedQuestNode = _selectedQuestNode;
    final introQuestNode = _introQuestNode;
    final introDialogue = _introDialogue;
    final overlayStage = _baumhausOverlayStage;
    final runtime = _questRuntime;
    final hintLibrary = _hintLibrary;
    final padding = MediaQuery.of(context).padding;
    final bottomInset = padding.bottom;
    final season = ref.read(seasonServiceProvider).context;
    _game.updateSeason(season);
    _game.updateFinoStyle(ref.read(finoEvolutionProvider).style);
    _game.updateAccessibility(ref.read(accessibilityProvider).settings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flüsterwald'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Stack(
          children: [
            GameWidget(game: _game),
            if (_expeditionAvailable || _expeditionRestored)
              Align(
                alignment: const Alignment(0, 0.02),
                child: _ExpeditionMapNode(
                  restored: _expeditionRestored,
                  onTap: _expeditionRestored
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExpeditionScreen(
                                worldId: 'fluesterwald',
                              ),
                            ),
                          ).then((_) => _loadExpeditionState());
                        },
                ),
              ),
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
                  bottomInset: bottomInset,
                  stationDialogue: _selectedDialogue,
                  onCompleted: _completeQuestChallenge,
                  onClose: _closeQuestOverlay,
                ),
              ),
            if (introQuestNode != null && introDialogue != null)
              Positioned.fill(
                child: QuestIntroScreen(
                  questNode: introQuestNode,
                  stationDialogue: introDialogue,
                  onComplete: () => _openQuestOverlay(
                    introQuestNode,
                    introDialogue,
                  ),
                ),
              ),
            if (overlayStage != null)
              Positioned.fill(
                child: BaumhausAdvanceOverlay(
                  stage: overlayStage,
                  finoAdvanced: _baumhausFinoAdvanced,
                  onDismiss: () => setState(() => _baumhausOverlayStage = null),
                ),
              ),
            if (_pendingRewards.isNotEmpty)
              Positioned.fill(
                child: QuestRewardOverlay(
                  rewards: _pendingRewards,
                  onDismiss: () => setState(() => _pendingRewards = []),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}

class BaumhausAdvanceOverlay extends StatefulWidget {
  final int stage;
  final bool finoAdvanced;
  final VoidCallback onDismiss;

  const BaumhausAdvanceOverlay({
    super.key,
    required this.stage,
    required this.finoAdvanced,
    required this.onDismiss,
  });

  @override
  State<BaumhausAdvanceOverlay> createState() => _BaumhausAdvanceOverlayState();
}

class _BaumhausAdvanceOverlayState extends State<BaumhausAdvanceOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BaumhausAdvancePainter(
              t: _controller.value,
              stage: widget.stage,
              finoAdvanced: widget.finoAdvanced,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _BaumhausAdvancePainter extends CustomPainter {
  final double t;
  final int stage;
  final bool finoAdvanced;

  const _BaumhausAdvancePainter({
    required this.t,
    required this.stage,
    required this.finoAdvanced,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xD9000000));
    final zoomT = t < 0.3 ? t / 0.3 : 1.0;
    final revealT = t < 0.3 ? 0.0 : ((t - 0.3) / 0.4).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(0, (1 - zoomT) * size.height * 0.12);
    canvas.scale(0.92 + zoomT * 0.08);
    BaumhausPainter(
      baumhausStage: stage,
      items: const [],
      finoStyle: FinoStyle.forStage(stage),
      breathT: t,
      revealT: revealT,
    ).paint(canvas, size);
    canvas.restore();

    if (t >= 0.3 && t < 0.7) {
      final sc = math.min(size.width / 360, size.height / 720);
      for (var i = 0; i < 28; i++) {
        final angle = i * math.pi * 2 / 28;
        final radius = 16 * sc + revealT * 160 * sc;
        final center = Offset(size.width / 2, size.height * 0.42);
        canvas.drawCircle(
          center.translate(math.cos(angle) * radius, math.sin(angle) * radius),
          2.2 * sc,
          Paint()..color = const Color(0xFFFFD700).withOpacity(1 - revealT),
        );
      }
    }
    if (t >= 0.7 && finoAdvanced) {
      final sc = math.min(size.width / 360, size.height / 720);
      final pulse = math.sin(t * math.pi * 12).abs();
      canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.57),
        (36 + pulse * 10) * sc,
        Paint()
          ..color = const Color(0x66FFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * sc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BaumhausAdvancePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.stage != stage ||
      oldDelegate.finoAdvanced != finoAdvanced;
}

class _ExpeditionMapNode extends StatefulWidget {
  final bool restored;
  final VoidCallback? onTap;

  const _ExpeditionMapNode({required this.restored, this.onTap});

  @override
  State<_ExpeditionMapNode> createState() => _ExpeditionMapNodeState();
}

class _ExpeditionMapNodeState extends State<_ExpeditionMapNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: const Size(150, 116),
          painter: _ExpeditionNodePainter(
            t: _controller.value,
            restored: widget.restored,
          ),
        ),
      ),
    );
  }
}

class _ExpeditionNodePainter extends CustomPainter {
  final double t;
  final bool restored;

  const _ExpeditionNodePainter({required this.t, required this.restored});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    if (restored) {
      final path = Path()
        ..moveTo(center.dx, center.dy - 32)
        ..lineTo(center.dx + 17, center.dy - 8)
        ..lineTo(center.dx, center.dy + 24)
        ..lineTo(center.dx - 17, center.dy - 8)
        ..close();
      canvas.drawCircle(center.translate(0, -4), 34, Paint()..color = const Color(0x3329B6F6));
      canvas.drawPath(path, Paint()..color = const Color(0xFF29B6F6));
      return;
    }
    final pulse = math.sin(t * math.pi * 2) * 0.5 + 0.5;
    canvas.drawCircle(center, 30 + pulse * 5, Paint()..color = Color.fromRGBO(255, 143, 0, 0.2));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (final rotation in [-0.45, 0.45, 0.0]) {
      canvas.save();
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, 18), width: 44, height: 10),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.restore();
    }
    final flicker = 1 + math.sin(t * math.pi * 8) * 0.08;
    canvas.scale(flicker);
    canvas.drawPath(
      Path()
        ..moveTo(0, -28)
        ..quadraticBezierTo(22, -5, 0, 18)
        ..quadraticBezierTo(-22, -5, 0, -28),
      Paint()..color = const Color(0xFFFF6F00),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -15)
        ..quadraticBezierTo(12, 0, 0, 12)
        ..quadraticBezierTo(-12, 0, 0, -15),
      Paint()..color = const Color(0xFFFFC107),
    );
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, -44), width: 46, height: 24),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFC8A96E),
    );
    _drawText(
      canvas,
      'Neue Expedition!',
      Offset(0, 4),
      size.width,
      const Color(0xFFFF8F00).withValues(alpha: 0.6 + pulse * 0.4),
      12,
      FontWeight.w800,
      align: TextAlign.center,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double width,
    Color color,
    double fontSize,
    FontWeight weight, {
    TextAlign align = TextAlign.start,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ExpeditionNodePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.restored != restored;
}
