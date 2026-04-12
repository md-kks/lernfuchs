import 'package:flutter/material.dart';

enum QuestNodeState { current, completed, available, locked }

enum QuestNodeType { start, clearing, tree, bridge, lake }

class WorldQuestNode {
  final String id;
  final Offset mapPosition;
  final QuestNodeState state;
  final QuestNodeType type;
  final String label;

  const WorldQuestNode({
    required this.id,
    required this.mapPosition,
    required this.state,
    required this.type,
    required this.label,
  });

  String? get questId => null;
  String get title => label;
  String get subtitle => '';
}
