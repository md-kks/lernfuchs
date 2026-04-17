import '../../core/models/task_model.dart';

enum WorldQuestInteractionType {
  dragToTarget,
  tapSelect,
  sequenceBuild,
  traceDraw,
  fallback,
}

extension WorldQuestInteractionTypeId on WorldQuestInteractionType {
  String get id => switch (this) {
    WorldQuestInteractionType.dragToTarget => 'drag_to_target',
    WorldQuestInteractionType.tapSelect => 'tap_select',
    WorldQuestInteractionType.sequenceBuild => 'sequence_build',
    WorldQuestInteractionType.traceDraw => 'trace_draw',
    WorldQuestInteractionType.fallback => 'fallback',
  };
}

class WorldTaskSceneItem {
  final String id;
  final String label;
  final dynamic answerValue;
  final String role;

  const WorldTaskSceneItem({
    required this.id,
    required this.label,
    required this.answerValue,
    this.role = 'item',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'answerValue': answerValue,
    'role': role,
  };
}

class WorldTaskSceneTarget {
  final String id;
  final String label;
  final List<dynamic> accepts;
  final String role;

  const WorldTaskSceneTarget({
    required this.id,
    required this.label,
    this.accepts = const [],
    this.role = 'target',
  });

  bool acceptsValue(dynamic value) {
    if (accepts.isEmpty) return true;
    return accepts.any((accepted) => accepted.toString() == value.toString());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'accepts': accepts,
    'role': role,
  };
}

class WorldTaskSceneDefinition {
  final String taskId;
  final String topic;
  final WorldQuestInteractionType interactionType;
  final String sceneRole;
  final String prompt;
  final List<WorldTaskSceneItem> items;
  final List<WorldTaskSceneTarget> targets;
  final dynamic correctAnswer;
  final bool migrated;

  const WorldTaskSceneDefinition({
    required this.taskId,
    required this.topic,
    required this.interactionType,
    required this.sceneRole,
    required this.prompt,
    required this.correctAnswer,
    this.items = const [],
    this.targets = const [],
    this.migrated = true,
  });

  WorldQuestInteractionSpec toInteractionSpec() => WorldQuestInteractionSpec(
    type: interactionType,
    sceneRole: sceneRole,
    prompt: prompt,
    objectLabels: items.map((item) => item.label).toList(growable: false),
    targetLabels: targets.map((target) => target.label).toList(growable: false),
    migrated: migrated,
  );

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'topic': topic,
    'interactionType': interactionType.id,
    'sceneRole': sceneRole,
    'prompt': prompt,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'targets': targets.map((target) => target.toJson()).toList(growable: false),
    'correctAnswer': correctAnswer,
    'migrated': migrated,
  };
}

class WorldTaskSceneController {
  final WorldTaskSceneDefinition definition;

  const WorldTaskSceneController(this.definition);

  dynamic submitDragToTarget({
    required String itemId,
    required String targetId,
  }) {
    final item = _itemById(itemId);
    final target = _targetById(targetId);
    if (item == null || target == null) {
      return null;
    }
    return item.answerValue;
  }

  dynamic submitTap(String itemId) => _itemById(itemId)?.answerValue;

  dynamic submitSequencePlacement({
    required String itemId,
    required String targetId,
  }) {
    final item = _itemById(itemId);
    final target = _targetById(targetId);
    if (item == null || target == null) {
      return null;
    }
    return item.answerValue;
  }

  bool targetAccepts({required String itemId, required String targetId}) {
    final item = _itemById(itemId);
    final target = _targetById(targetId);
    return item != null &&
        target != null &&
        target.acceptsValue(item.answerValue);
  }

  dynamic submitTrace({required double completion}) {
    if (completion < 0.72) return null;
    return definition.correctAnswer;
  }

  WorldTaskSceneItem? _itemById(String id) {
    for (final item in definition.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  WorldTaskSceneTarget? _targetById(String id) {
    for (final target in definition.targets) {
      if (target.id == id) return target;
    }
    return null;
  }
}

class WorldQuestInteractionSpec {
  final WorldQuestInteractionType type;
  final String sceneRole;
  final String prompt;
  final List<String> objectLabels;
  final List<String> targetLabels;
  final bool migrated;

  const WorldQuestInteractionSpec({
    required this.type,
    required this.sceneRole,
    required this.prompt,
    this.objectLabels = const [],
    this.targetLabels = const [],
    this.migrated = true,
  });

  Map<String, dynamic> toJson() => {
    'type': type.id,
    'sceneRole': sceneRole,
    'prompt': prompt,
    'objectLabels': objectLabels,
    'targetLabels': targetLabels,
    'migrated': migrated,
  };
}

class WorldQuestInteractionResolver {
  static const migratedTopics = {'zahlen_bis_10', 'anlaute', 'zahlenmauern'};

  const WorldQuestInteractionResolver();

  WorldQuestInteractionSpec resolve(TaskModel task) =>
      resolveScene(task).toInteractionSpec();

  WorldTaskSceneDefinition resolveScene(TaskModel task) {
    return switch (task.topic) {
      'zahlen_bis_10' => _countingScene(task),
      'anlaute' => _initialSoundScene(task),
      'zahlenmauern' => _numberWallScene(task),
      _ => WorldTaskSceneDefinition(
        taskId: task.id,
        topic: task.topic,
        interactionType: WorldQuestInteractionType.fallback,
        sceneRole: 'worksheet_fallback',
        prompt: task.question,
        correctAnswer: task.correctAnswer,
        migrated: false,
      ),
    };
  }

  bool supportsWorldQuestTask(TaskModel task) => resolveScene(task).migrated;

  WorldTaskSceneDefinition _countingScene(TaskModel task) {
    final count = task.metadata['dotCount'] as int?;
    if (count == null) {
      return WorldTaskSceneDefinition(
        taskId: task.id,
        topic: task.topic,
        interactionType: WorldQuestInteractionType.fallback,
        sceneRole: 'counting_fallback',
        prompt: task.question,
        correctAnswer: task.correctAnswer,
        migrated: false,
      );
    }

    return WorldTaskSceneDefinition(
      taskId: task.id,
      topic: task.topic,
      interactionType: WorldQuestInteractionType.dragToTarget,
      sceneRole: 'apple_baskets',
      prompt: 'Lege die passende Menge in den Korb.',
      items: [
        for (var i = 0; i < count; i++)
          WorldTaskSceneItem(
            id: 'apple_$i',
            label: 'Apfel',
            answerValue: count,
            role: 'apple',
          ),
      ],
      targets: [
        WorldTaskSceneTarget(
          id: 'basket',
          label: task.correctAnswer.toString(),
          accepts: [task.correctAnswer],
          role: 'basket',
        ),
      ],
      correctAnswer: task.correctAnswer,
    );
  }

  WorldTaskSceneDefinition _initialSoundScene(TaskModel task) {
    final choices = _stringList(task.metadata['choices']);
    return WorldTaskSceneDefinition(
      taskId: task.id,
      topic: task.topic,
      interactionType: WorldQuestInteractionType.dragToTarget,
      sceneRole: 'letter_signs',
      prompt: 'Setze den passenden Anfangslaut an das Schild.',
      items: [
        for (var i = 0; i < choices.length; i++)
          WorldTaskSceneItem(
            id: 'letter_$i',
            label: choices[i],
            answerValue: choices[i],
            role: 'letter_stone',
          ),
      ],
      targets: [
        WorldTaskSceneTarget(
          id: 'sign',
          label: task.metadata['word']?.toString() ?? task.question,
          accepts: [task.correctAnswer],
          role: 'word_sign',
        ),
      ],
      correctAnswer: task.correctAnswer,
    );
  }

  WorldTaskSceneDefinition _numberWallScene(TaskModel task) {
    final objectLabels = _nearbyNumbers(
      task.correctAnswer,
    ).map((n) => '$n').toList();
    return WorldTaskSceneDefinition(
      taskId: task.id,
      topic: task.topic,
      interactionType: WorldQuestInteractionType.sequenceBuild,
      sceneRole: 'number_wall',
      prompt: 'Setze den Zahlenstein in die Mauer.',
      items: [
        for (var i = 0; i < objectLabels.length; i++)
          WorldTaskSceneItem(
            id: 'number_stone_$i',
            label: objectLabels[i],
            answerValue: int.tryParse(objectLabels[i]) ?? objectLabels[i],
            role: 'number_stone',
          ),
      ],
      targets: [
        WorldTaskSceneTarget(
          id: task.metadata['hidden']?.toString() ?? 'missing_stone',
          label: '?',
          accepts: [task.correctAnswer],
          role: 'number_wall_slot',
        ),
      ],
      correctAnswer: task.correctAnswer,
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((entry) => entry.toString()).toList(growable: false);
  }

  List<int> _nearbyNumbers(dynamic answer) {
    final correct = int.tryParse(answer.toString());
    if (correct == null) return const [];
    final values = <int>{correct};
    for (var delta = 1; values.length < 4 && delta <= 4; delta++) {
      if (correct - delta >= 0) values.add(correct - delta);
      values.add(correct + delta);
    }
    final result = values.take(4).toList()..sort();
    return result;
  }
}
