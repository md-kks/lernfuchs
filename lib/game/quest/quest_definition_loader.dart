import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import 'quest_definition.dart';

class QuestDefinitionLoader {
  const QuestDefinitionLoader({AssetBundle? assetBundle})
    : _assetBundle = assetBundle;

  final AssetBundle? _assetBundle;

  Future<List<QuestDefinition>> loadFromAsset(String assetPath) async {
    final bundle = _assetBundle ?? rootBundle;
    final raw = await bundle.loadString(assetPath);
    final decoded = _decode(raw, assetPath);
    final questList = decoded is Map<String, dynamic>
        ? decoded['quests'] as List? ?? const []
        : decoded as List? ?? const [];

    return questList
        .map(
          (quest) =>
              QuestDefinition.fromJson((quest as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  dynamic _decode(String raw, String assetPath) {
    if (assetPath.endsWith('.yaml') || assetPath.endsWith('.yml')) {
      return _normalizeYaml(loadYaml(raw));
    }
    return jsonDecode(raw);
  }

  dynamic _normalizeYaml(dynamic value) {
    if (value is YamlMap) {
      return value.map(
        (key, child) => MapEntry(key.toString(), _normalizeYaml(child)),
      );
    }
    if (value is YamlList) {
      return value.map(_normalizeYaml).toList();
    }
    return value;
  }
}
