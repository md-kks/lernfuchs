import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/models/task_model.dart';
import 'package:lernfuchs/game/quest/world_quest_interaction.dart';

void main() {
  const resolver = WorldQuestInteractionResolver();

  test('maps prioritized World Quest topics to scene interaction types', () {
    final scenes = {
      'zahlen_bis_10': resolver.resolveScene(
        TaskModel(
          id: 'count',
          subject: 'math',
          grade: 1,
          topic: 'zahlen_bis_10',
          question: 'Wie viele Punkte siehst du?',
          taskType: TaskType.freeInput.name,
          correctAnswer: 4,
          metadata: const {'dotCount': 4},
        ),
      ),
      'anlaute': resolver.resolveScene(
        TaskModel(
          id: 'sound',
          subject: 'german',
          grade: 1,
          topic: 'anlaute',
          question: 'Mit welchem Laut faengt das Wort an?',
          taskType: TaskType.multipleChoice.name,
          correctAnswer: 'F',
          metadata: const {
            'word': 'Fuchs',
            'choices': ['F', 'A', 'M', 'S'],
          },
        ),
      ),
      'zahlenmauern': resolver.resolveScene(
        TaskModel(
          id: 'wall',
          subject: 'math',
          grade: 1,
          topic: 'zahlenmauern',
          question: 'Welche Zahl fehlt?',
          taskType: TaskType.freeInput.name,
          correctAnswer: 7,
          metadata: const {'hidden': 'mid1'},
        ),
      ),
    };

    expect(scenes['zahlen_bis_10']!.interactionType.id, 'drag_to_target');
    expect(scenes['zahlen_bis_10']!.sceneRole, 'apple_baskets');
    expect(scenes['zahlen_bis_10']!.items, hasLength(4));
    expect(scenes['zahlen_bis_10']!.targets.single.role, 'basket');
    expect(scenes['anlaute']!.interactionType.id, 'drag_to_target');
    expect(scenes['anlaute']!.sceneRole, 'letter_signs');
    expect(scenes['anlaute']!.items.map((item) => item.label), contains('F'));
    expect(scenes['zahlenmauern']!.interactionType.id, 'sequence_build');
    expect(scenes['zahlenmauern']!.sceneRole, 'number_wall');
    expect(scenes['zahlenmauern']!.targets.single.role, 'number_wall_slot');
    expect(scenes.values.every((scene) => scene.migrated), isTrue);
  });

  test('world scene controller resolves drag and sequence answers', () {
    final soundScene = resolver.resolveScene(
      TaskModel(
        id: 'sound',
        subject: 'german',
        grade: 1,
        topic: 'anlaute',
        question: 'Mit welchem Laut faengt das Wort an?',
        taskType: TaskType.multipleChoice.name,
        correctAnswer: 'F',
        metadata: const {
          'word': 'Fuchs',
          'choices': ['F', 'A', 'M', 'S'],
        },
      ),
    );
    final soundController = WorldTaskSceneController(soundScene);

    expect(
      soundController.submitDragToTarget(itemId: 'letter_0', targetId: 'sign'),
      'F',
    );
    expect(
      soundController.submitDragToTarget(itemId: 'letter_1', targetId: 'sign'),
      'A',
    );
    expect(
      soundController.targetAccepts(itemId: 'letter_1', targetId: 'sign'),
      isFalse,
    );

    final wallScene = resolver.resolveScene(
      TaskModel(
        id: 'wall',
        subject: 'math',
        grade: 1,
        topic: 'zahlenmauern',
        question: 'Welche Zahl fehlt?',
        taskType: TaskType.freeInput.name,
        correctAnswer: 7,
        metadata: const {'hidden': 'mid1'},
      ),
    );
    final wallController = WorldTaskSceneController(wallScene);
    final correctStone = wallScene.items.firstWhere(
      (item) => item.answerValue.toString() == '7',
    );

    expect(
      wallController.submitSequencePlacement(
        itemId: correctStone.id,
        targetId: 'mid1',
      ),
      7,
    );
  });

  test('world scene controller supports tap and trace interactions', () {
    const tapScene = WorldTaskSceneDefinition(
      taskId: 'tap',
      topic: 'probe',
      interactionType: WorldQuestInteractionType.tapSelect,
      sceneRole: 'tap_objects',
      prompt: 'Tippe das passende Objekt an.',
      correctAnswer: 'Fuchs',
      items: [
        WorldTaskSceneItem(id: 'fox', label: 'Fuchs', answerValue: 'Fuchs'),
        WorldTaskSceneItem(id: 'tree', label: 'Baum', answerValue: 'Baum'),
      ],
    );
    const traceScene = WorldTaskSceneDefinition(
      taskId: 'trace',
      topic: 'probe',
      interactionType: WorldQuestInteractionType.traceDraw,
      sceneRole: 'trace_rune',
      prompt: 'Fahre die Spur nach.',
      correctAnswer: 'A',
      items: [WorldTaskSceneItem(id: 'trace_a', label: 'A', answerValue: 'A')],
    );

    expect(WorldTaskSceneController(tapScene).submitTap('fox'), 'Fuchs');
    expect(
      WorldTaskSceneController(traceScene).submitTrace(completion: 0.5),
      isNull,
    );
    expect(
      WorldTaskSceneController(traceScene).submitTrace(completion: 0.85),
      'A',
    );
  });

  test('keeps non-migrated task topics on fallback interaction', () {
    final spec = resolver.resolve(
      TaskModel(
        id: 'fallback',
        subject: 'math',
        grade: 1,
        topic: 'addition_bis_10',
        question: '2 + 3 = ?',
        taskType: TaskType.freeInput.name,
        correctAnswer: 5,
      ),
    );

    expect(spec.type, WorldQuestInteractionType.fallback);
    expect(spec.migrated, isFalse);
    expect(
      resolver.supportsWorldQuestTask(specTask('addition_bis_10')),
      isFalse,
    );
    expect(resolver.supportsWorldQuestTask(specTask('reimwoerter')), isFalse);
    expect(resolver.supportsWorldQuestTask(specTask('handschrift')), isFalse);
  });
}

TaskModel specTask(String topic) {
  return TaskModel(
    id: topic,
    subject: 'math',
    grade: 1,
    topic: topic,
    question: 'Probe',
    taskType: TaskType.freeInput.name,
    correctAnswer: 1,
  );
}
