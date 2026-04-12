import 'package:flutter/material.dart';

class WorldQuestNode {
  final String id;
  final String? questId;
  final String title;
  final String subtitle;
  final Offset mapPosition;

  const WorldQuestNode({
    required this.id,
    this.questId,
    required this.title,
    required this.subtitle,
    required this.mapPosition,
  });
}
