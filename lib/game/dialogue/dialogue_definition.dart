class DialogueLibrary {
  final Map<String, DialogueCharacter> characters;
  final Map<String, DialogueScene> scenes;

  const DialogueLibrary({required this.characters, required this.scenes});

  factory DialogueLibrary.fromJson(Map<String, dynamic> json) {
    final characters = (json['characters'] as List? ?? const [])
        .map(
          (character) => DialogueCharacter.fromJson(
            (character as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
    final scenes = (json['scenes'] as List? ?? const [])
        .map(
          (scene) =>
              DialogueScene.fromJson((scene as Map).cast<String, dynamic>()),
        )
        .toList();

    return DialogueLibrary(
      characters: {for (final character in characters) character.id: character},
      scenes: {for (final scene in scenes) scene.id: scene},
    );
  }

  DialogueCharacter? character(String id) => characters[id];

  DialogueScene? scene(String id) => scenes[id];
}

class DialogueCharacter {
  final String id;
  final String name;
  final String portraitAsset;
  final String portraitFallback;

  const DialogueCharacter({
    required this.id,
    required this.name,
    this.portraitAsset = '',
    this.portraitFallback = '',
  });

  factory DialogueCharacter.fromJson(Map<String, dynamic> json) {
    return DialogueCharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      portraitAsset: json['portraitAsset'] as String? ?? '',
      portraitFallback: json['portraitFallback'] as String? ?? '',
    );
  }
}

class DialogueScene {
  final String id;
  final String title;
  final List<DialogueLine> lines;

  const DialogueScene({
    required this.id,
    required this.title,
    required this.lines,
  });

  factory DialogueScene.fromJson(Map<String, dynamic> json) {
    return DialogueScene(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      lines: (json['lines'] as List? ?? const [])
          .map(
            (line) =>
                DialogueLine.fromJson((line as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}

class DialogueLine {
  final String speakerId;
  final String text;

  const DialogueLine({required this.speakerId, required this.text});

  factory DialogueLine.fromJson(Map<String, dynamic> json) {
    return DialogueLine(
      speakerId: json['speakerId'] as String,
      text: json['text'] as String,
    );
  }
}
