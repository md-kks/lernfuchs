import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../services/audio_service.dart';
import '../../services/accessibility_service.dart';
import '../../services/fino_evolution_service.dart';
import '../../services/season_service.dart';
import 'world_map_background.dart';
import 'world_map_fino.dart';
import 'world_map_node_component.dart';
import 'world_map_story_components.dart';
import 'world_quest_node.dart';

class LernFuchsWorldGame extends FlameGame {
  final ValueChanged<WorldQuestNode> onQuestNodeTapped;
  final AudioService? audioService;
  Map<String, dynamic> _worldState = {};
  final List<WorldMapNodeComponent> _nodeComponents = [];
  WorldMapFinoComponent? _fino;
  _FinoTrailComponent? _trail;
  StoryPopupComponent? _storyPopup;
  OvaMapBubbleComponent? _ovaBubble;
  List<WorldQuestNode> _activeQuestNodes = questNodes;
  double _finoAnimT = 0.0;
  int _finoEdgeIndex = -1;
  VoidCallback? _onFinoArrived;
  SeasonContext? _season;
  FinoStyle _finoStyle = FinoStyle.forStage(0);
  AccessibilitySettings _accessibility = AccessibilitySettings.off;
  double _lastHopSoundT = -1.0;

  LernFuchsWorldGame({required this.onQuestNodeTapped, this.audioService});

  bool get finoIsWalking => _finoEdgeIndex >= 0;

  static final questNodes = [
    WorldQuestNode(
      id: 'waldeingang',
      mapPosition: WorldMapBackground.nodePositions[0],
      state: QuestNodeState.current,
      type: QuestNodeType.start,
      label: 'Waldeingang',
      questId: 'prolog_ovas_ruf',
      storyText: 'Der Flüsterwald liegt vor Fino. Beweise dein erstes Können!',
      order: 0,
      subtitle: 'Prolog im Flüsterwald',
    ),
    WorldQuestNode(
      id: 'lichtung',
      mapPosition: WorldMapBackground.nodePositions[1],
      state: QuestNodeState.lockedFar,
      type: QuestNodeType.clearing,
      label: 'Lichtung',
      questId: 'main_zahlenpfad',
      storyText:
          'Fino findet einen glühenden Wissenskristall. Zähle die Punkte um ihn zu befreien!',
      order: 1,
      subtitle: 'Hauptquest: Zahlen bis 10',
    ),
    WorldQuestNode(
      id: 'alter_baum',
      mapPosition: WorldMapBackground.nodePositions[2],
      state: QuestNodeState.lockedFar,
      type: QuestNodeType.tree,
      label: 'Alter Baum',
      questId: 'main_buchstabenhain',
      storyText:
          'Am Alten Baum leuchten Runen. Entziffere sie und das Wissen gehört dir!',
      order: 2,
      subtitle: 'Hauptquest: Buchstaben',
    ),
    WorldQuestNode(
      id: 'bruecke',
      mapPosition: WorldMapBackground.nodePositions[3],
      state: QuestNodeState.lockedFar,
      type: QuestNodeType.bridge,
      label: 'Brücke',
      questId: 'side_silbenquelle',
      storyText:
          'Das Brückentor ist verschlossen. Das richtige Zauberwort öffnet den Weg!',
      order: 3,
      subtitle: 'Nebenquest: Silben',
    ),
    WorldQuestNode(
      id: 'waldsee',
      mapPosition: WorldMapBackground.nodePositions[4],
      state: QuestNodeState.lockedFar,
      type: QuestNodeType.lake,
      label: 'Waldsee',
      questId: 'side_musterlichtung',
      storyText:
          'Trittsteine tauchen im Waldsee auf. Erkenne das Muster und überquere das Wasser!',
      order: 4,
      subtitle: 'Nebenquest: Muster',
    ),
  ];

  @override
  Color backgroundColor() => const Color(0xFFBFE7D2);

  @override
  Future<void> onLoad() async {
    await add(WorldMapBackground()..priority = 0);
    final nodes = _activeQuestNodes;
    for (int i = 0; i < nodes.length; i++) {
      final component = WorldMapNodeComponent(questNode: nodes[i], nodeIndex: i)
        ..priority = 1;
      _nodeComponents.add(component);
      await add(component);
    }
    _trail = _FinoTrailComponent()..priority = 2;
    await add(_trail!);
    _fino = WorldMapFinoComponent()..priority = 3;
    await add(_fino!);
  }

  void onNodeTapped(WorldQuestNode node) {
    onQuestNodeTapped(node);
  }

  void updateUnlockedOrder(
    int highestUnlockedOrder, {
    bool revealNextOnly = false,
  }) {
    _activeQuestNodes = questNodes
        .map(
          (node) => node.copyWith(
            state: node.order < highestUnlockedOrder
                ? QuestNodeState.completed
                : node.order == highestUnlockedOrder
                ? revealNextOnly
                      ? QuestNodeState.nextAvailable
                      : QuestNodeState.current
                : node.order == highestUnlockedOrder + 1
                ? QuestNodeState.lockedNear
                : QuestNodeState.lockedFar,
          ),
        )
        .toList();

    for (
      var i = 0;
      i < math.min(_nodeComponents.length, _activeQuestNodes.length);
      i++
    ) {
      _nodeComponents[i].updateQuestNode(_activeQuestNodes[i]);
    }
    if (!finoIsWalking && _fino != null) {
      final clampedOrder =
          (revealNextOnly ? highestUnlockedOrder - 1 : highestUnlockedOrder)
              .clamp(0, questNodes.length - 1)
              .toInt();
      _fino!.moveToMapPoint(
        WorldMapBackground.nodePositionToVector(
          Size(size.x, size.y),
          clampedOrder,
        ),
      );
    }
  }

  WorldQuestNode nodeForOrder(int order) {
    return _activeQuestNodes.firstWhere((node) => node.order == order);
  }

  QuestNodeState stateForOrder(int order) => nodeForOrder(order).state;

  SeasonContext? get season => _season;
  FinoStyle get finoStyle => _finoStyle;
  AccessibilitySettings get accessibility => _accessibility;

  void updateSeason(SeasonContext? season) {
    _season = season;
  }

  void updateFinoStyle(FinoStyle style) {
    _finoStyle = style;
  }

  void updateAccessibility(AccessibilitySettings settings) {
    _accessibility = settings;
  }

  void showStoryPopup(WorldQuestNode node, VoidCallback onQuestStart) {
    _storyPopup?.removeFromParent();
    final popup = StoryPopupComponent(
      node: node,
      nodeIndex: node.order,
      onQuestStart: onQuestStart,
    );
    _storyPopup = popup;
    add(popup);
  }

  void clearStoryPopup() {
    _storyPopup?.removeFromParent();
    _storyPopup = null;
  }

  void showOvaBubble({
    required WorldQuestNode completedNode,
    required WorldQuestNode nextNode,
    required int edgeIndex,
  }) {
    _ovaBubble?.removeFromParent();
    final bubble = OvaMapBubbleComponent(
      completedNode: completedNode,
      nextNode: nextNode,
      edgeIndex: edgeIndex,
    );
    _ovaBubble = bubble;
    add(bubble);
  }

  void startFinoWalk(int edgeIndex, VoidCallback onArrived) {
    if (edgeIndex < 0 || edgeIndex >= WorldMapBackground.edges.length) {
      onArrived();
      return;
    }
    clearStoryPopup();
    _finoEdgeIndex = edgeIndex;
    _finoAnimT = 0.0;
    _onFinoArrived = onArrived;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finoEdgeIndex < 0) return;

    _finoAnimT = (_finoAnimT + dt / 1.8).clamp(0.0, 1.0);
    if (_lastHopSoundT < 0 || _finoAnimT - _lastHopSoundT >= 0.4 / 1.8) {
      audioService?.playSfx('fino_hop');
      _lastHopSoundT = _finoAnimT;
    }
    final eased = Curves.easeInOut.transform(_finoAnimT);
    final screen = Size(size.x, size.y);
    _fino?.moveToMapPoint(
      WorldMapBackground.edgePointToVector(screen, _finoEdgeIndex, eased),
      hopOffset: math.sin(_finoAnimT * math.pi * 8) * 2 * WorldMapBackground.uniformScale(size),
    );

    if (_finoAnimT >= 1.0) {
      _finoEdgeIndex = -1;
      _lastHopSoundT = -1.0;
      final callback = _onFinoArrived;
      _onFinoArrived = null;
      callback?.call();
    }
  }

  void updateWorldState(Map<String, dynamic> worldState) {
    _worldState = {..._worldState, ...worldState};
  }

  void drawFinoTrail(Canvas canvas) {
    if (_finoEdgeIndex < 0) return;
    final screen = Size(size.x, size.y);
    final sc = WorldMapBackground.uniformScale(size);
    for (final trail in const [(0.05, 0.28), (0.10, 0.18), (0.15, 0.10)]) {
      final t = (_finoAnimT - trail.$1).clamp(0.0, 1.0);
      final p = WorldMapBackground.edgePointToVector(screen, _finoEdgeIndex, t);
      canvas.drawCircle(
        Offset(p.x, p.y - 36 * sc),
        3 * sc,
        Paint()..color = Color.fromRGBO(255, 143, 0, trail.$2),
      );
    }
  }
}

class _FinoTrailComponent extends Component
    with HasGameReference<LernFuchsWorldGame> {
  @override
  void render(Canvas canvas) {
    game.drawFinoTrail(canvas);
  }
}
