import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'world_map_background.dart';
import 'world_map_fino.dart';
import 'world_map_node_component.dart';
import 'world_quest_node.dart';

class LernFuchsWorldGame extends FlameGame {
  final ValueChanged<WorldQuestNode> onQuestNodeTapped;
  Map<String, dynamic> _worldState = {};

  LernFuchsWorldGame({required this.onQuestNodeTapped});

  static final questNodes = [
    WorldQuestNode(
      id: 'waldeingang',
      mapPosition: WorldMapBackground.nodePositions[0],
      state: QuestNodeState.current,
      type: QuestNodeType.start,
      label: 'Waldeingang',
      questId: 'prolog_ovas_ruf',
      subtitle: 'Prolog im Flüsterwald',
    ),
    WorldQuestNode(
      id: 'lichtung',
      mapPosition: WorldMapBackground.nodePositions[1],
      state: QuestNodeState.completed,
      type: QuestNodeType.clearing,
      label: 'Lichtung',
      questId: 'main_zahlenpfad',
      subtitle: 'Hauptquest: Zahlen bis 10',
    ),
    WorldQuestNode(
      id: 'alter_baum',
      mapPosition: WorldMapBackground.nodePositions[2],
      state: QuestNodeState.available,
      type: QuestNodeType.tree,
      label: 'Alter Baum',
      questId: 'main_buchstabenhain',
      subtitle: 'Hauptquest: Buchstaben',
    ),
    WorldQuestNode(
      id: 'bruecke',
      mapPosition: WorldMapBackground.nodePositions[3],
      state: QuestNodeState.available,
      type: QuestNodeType.bridge,
      label: 'Brücke',
      questId: 'side_silbenquelle',
      subtitle: 'Nebenquest: Silben',
    ),
    WorldQuestNode(
      id: 'waldsee',
      mapPosition: WorldMapBackground.nodePositions[4],
      state: QuestNodeState.locked,
      type: QuestNodeType.lake,
      label: 'Waldsee',
      questId: 'side_musterlichtung',
      subtitle: 'Nebenquest: Muster',
    ),
  ];

  @override
  Color backgroundColor() => const Color(0xFFBFE7D2);

  @override
  Future<void> onLoad() async {
    await add(WorldMapBackground()..priority = 0);
    final nodes = questNodes;
    for (int i = 0; i < nodes.length; i++) {
      await add(
        WorldMapNodeComponent(questNode: nodes[i], nodeIndex: i)..priority = 1,
      );
    }
    await add(WorldMapFinoComponent()..priority = 2);
  }

  void onNodeTapped(WorldQuestNode node) {
    // TODO: open quest overlay
    onQuestNodeTapped(node);
  }

  void updateWorldState(Map<String, dynamic> worldState) {
    _worldState = {..._worldState, ...worldState};
  }
}
