import 'package:flutter/material.dart';

enum QuestNodeState { current, completed, available, locked }

enum QuestNodeType { start, clearing, tree, bridge, lake }

class WorldQuestNode {
  final String id;
  final Offset mapPosition;
  final QuestNodeState state;
  final QuestNodeType type;
  final String label;
  final String? questId;
  final String storyText;
  final int order;
  final String subtitle;

  const WorldQuestNode({
    required this.id,
    required this.mapPosition,
    required this.state,
    required this.type,
    required this.label,
    this.questId,
    this.storyText = '',
    required this.order,
    this.subtitle = '',
  });

  String get title => label;

  WorldQuestNode copyWith({
    QuestNodeState? state,
    String? questId,
    String? storyText,
    int? order,
  }) {
    return WorldQuestNode(
      id: id,
      mapPosition: mapPosition,
      state: state ?? this.state,
      type: type,
      label: label,
      questId: questId ?? this.questId,
      storyText: storyText ?? this.storyText,
      order: order ?? this.order,
      subtitle: subtitle,
    );
  }
}
