class HintLibrary {
  final Map<String, HintSetDefinition> hintSets;

  const HintLibrary({required this.hintSets});

  factory HintLibrary.fromJson(Map<String, dynamic> json) {
    final sets = (json['hintSets'] as List? ?? const [])
        .map(
          (hintSet) => HintSetDefinition.fromJson(
            (hintSet as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
    return HintLibrary(hintSets: {for (final set in sets) set.id: set});
  }

  HintSetDefinition? hintSet(String id) => hintSets[id];
}

class HintSetDefinition {
  final String id;
  final String mentorCharacterId;
  final List<HintLevelDefinition> levels;

  const HintSetDefinition({
    required this.id,
    required this.mentorCharacterId,
    required this.levels,
  });

  factory HintSetDefinition.fromJson(Map<String, dynamic> json) {
    return HintSetDefinition(
      id: json['id'] as String,
      mentorCharacterId: json['mentorCharacterId'] as String,
      levels: (json['levels'] as List? ?? const [])
          .map(
            (level) => HintLevelDefinition.fromJson(
              (level as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }

  HintLevelDefinition? hintForLevel(int level) {
    if (levels.isEmpty) return null;
    final index = level.clamp(1, levels.length).toInt() - 1;
    return levels[index];
  }
}

class HintLevelDefinition {
  final int level;
  final String title;
  final String text;

  const HintLevelDefinition({
    required this.level,
    required this.title,
    required this.text,
  });

  factory HintLevelDefinition.fromJson(Map<String, dynamic> json) {
    return HintLevelDefinition(
      level: json['level'] as int,
      title: json['title'] as String,
      text: json['text'] as String,
    );
  }
}
