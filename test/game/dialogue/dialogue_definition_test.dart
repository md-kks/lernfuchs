import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/game/dialogue/dialogue_definition_loader.dart';
import 'package:lernfuchs/game/dialogue/hint_definition_loader.dart';

void main() {
  test('loads local dialogue library with Ova character and scene', () async {
    final loader = DialogueDefinitionLoader(
      assetBundle: _StringAssetBundle({'dialogue.json': _dialogueContent}),
    );

    final library = await loader.loadFromAsset('dialogue.json');

    expect(library.character('ova')?.name, 'Ova');
    expect(library.character('ova')?.portraitFallback, 'O');
    expect(library.scene('zahlenwald_intro')?.lines, hasLength(2));
    expect(library.scene('zahlenwald_intro')?.lines.first.speakerId, 'ova');
  });

  test('loads local hint sets with escalating Ova help levels', () async {
    final loader = HintDefinitionLoader(
      assetBundle: _StringAssetBundle({'hints.json': _hintContent}),
    );

    final library = await loader.loadFromAsset('hints.json');
    final hintSet = library.hintSet('addition_bis_10_ova');

    expect(hintSet?.mentorCharacterId, 'ova');
    expect(hintSet?.hintForLevel(1)?.title, 'Erster Tipp');
    expect(hintSet?.hintForLevel(99)?.level, 2);
  });
}

const _dialogueContent = '''
{
  "characters": [
    {
      "id": "ova",
      "name": "Ova",
      "portraitFallback": "O"
    }
  ],
  "scenes": [
    {
      "id": "zahlenwald_intro",
      "title": "Hallo",
      "lines": [
        {
          "speakerId": "ova",
          "text": "Willkommen."
        },
        {
          "speakerId": "ova",
          "text": "Ich helfe dir."
        }
      ]
    }
  ]
}
''';

const _hintContent = '''
{
  "hintSets": [
    {
      "id": "addition_bis_10_ova",
      "mentorCharacterId": "ova",
      "levels": [
        {
          "level": 1,
          "title": "Erster Tipp",
          "text": "Starte mit der groesseren Zahl."
        },
        {
          "level": 2,
          "title": "Zweiter Tipp",
          "text": "Zaehle weiter."
        }
      ]
    }
  ]
}
''';

class _StringAssetBundle extends CachingAssetBundle {
  final Map<String, String> assets;

  _StringAssetBundle(this.assets);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = assets[key];
    if (value == null) throw StateError('Missing test asset: $key');
    return value;
  }

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError();
  }
}
