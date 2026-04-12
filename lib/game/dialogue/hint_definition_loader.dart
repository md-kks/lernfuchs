import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import 'hint_definition.dart';

class HintDefinitionLoader {
  const HintDefinitionLoader({AssetBundle? assetBundle})
    : _assetBundle = assetBundle;

  final AssetBundle? _assetBundle;

  Future<HintLibrary> loadFromAsset(String assetPath) async {
    final bundle = _assetBundle ?? rootBundle;
    final raw = await bundle.loadString(assetPath);
    return HintLibrary.fromJson(
      (_decode(raw, assetPath) as Map).cast<String, dynamic>(),
    );
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
