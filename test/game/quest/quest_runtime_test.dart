import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/engine/task_generator.dart';
import 'package:lernfuchs/core/learning/learning.dart';
import 'package:lernfuchs/core/models/progress.dart';
import 'package:lernfuchs/core/models/subject.dart';
import 'package:lernfuchs/core/models/task_model.dart';
import 'package:lernfuchs/game/quest/quest_definition_loader.dart';
import 'package:lernfuchs/game/quest/quest_runtime.dart';
import 'package:lernfuchs/game/quest/quest_status.dart';
import 'package:lernfuchs/game/quest/quest_status_store.dart';
import 'package:lernfuchs/game/reward/inventory_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads quest definitions from local json asset content', () async {
    final loader = QuestDefinitionLoader(
      assetBundle: _StringAssetBundle({'quests.json': _sampleQuestContent}),
    );

    final quests = await loader.loadFromAsset('quests.json');

    expect(quests, hasLength(1));
    expect(quests.single.id, 'zahlenwald_start');
    expect(quests.single.steps, hasLength(4));
  });

  test('loads the World 1 vertical slice quest asset', () async {
    final quests = await const QuestDefinitionLoader().loadFromAsset(
      'assets/quests/sample_quests.json',
    );

    expect(quests, hasLength(5));
    expect(quests.map((quest) => quest.id), [
      'prolog_ovas_ruf',
      'main_zahlenpfad',
      'main_buchstabenhain',
      'side_silbenquelle',
      'side_musterlichtung',
    ]);
    expect(
      quests
          .expand((quest) => quest.steps)
          .where((step) => step.type.name == 'learningChallenge'),
      hasLength(5),
    );
    for (final step in quests.expand((quest) => quest.steps)) {
      final challenge = step.learningChallenge;
      if (challenge == null) continue;
      final session = TaskGenerator.generateSession(
        subject: challenge.subject,
        grade: challenge.grade,
        topic: challenge.topic,
        difficulty: challenge.difficulty,
        count: challenge.count,
      );
      expect(session, hasLength(challenge.count));
    }
  });

  test('loads quest definitions from local yaml asset content', () async {
    final loader = QuestDefinitionLoader(
      assetBundle: _StringAssetBundle({
        'quests.yaml': '''
quests:
  - id: yaml_quest
    title: YAML Quest
    description: Local YAML quest
    worldNodeId: yaml_node
    steps:
      - id: intro
        type: dialogue
        text: Hallo
''',
      }),
    );

    final quests = await loader.loadFromAsset('quests.yaml');

    expect(quests.single.id, 'yaml_quest');
    expect(quests.single.steps.single.text, 'Hallo');
  });

  test('runtime completes sample quest through LearningEngine', () async {
    SharedPreferences.setMockInitialValues({});
    final loader = QuestDefinitionLoader(
      assetBundle: _StringAssetBundle({'quests.json': _sampleQuestContent}),
    );
    final quests = await loader.loadFromAsset('quests.json');
    final learningEngine = _FakeLearningEngine();
    final runtime = QuestRuntime(
      profileId: 'profile_1',
      learningEngine: learningEngine,
      statusStore: const QuestStatusStore(),
      quests: quests,
    );
    await runtime.load();
    await runtime.startQuest('zahlenwald_start');

    expect(runtime.currentStep('zahlenwald_start')?.id, 'intro');

    await runtime.completeCurrentStep('zahlenwald_start');
    final task = runtime.createLearningTask('zahlenwald_start');
    final result = await runtime.submitLearningAnswer(
      questId: 'zahlenwald_start',
      task: task,
      answer: '5',
    );
    // submitLearningAnswer calls completeCurrentStep internally if correct.
    final status = runtime.statusFor('zahlenwald_start');

    expect(result.correct, isTrue);
    expect(status.state, QuestRunState.completed);
    expect(status.worldState['zahlenwald_clearing_open'], isTrue);
    expect(status.grantedRewardIds, contains('sternensamen'));
    expect(learningEngine.recordedResults, [true]);

    // Check rewards from a manual call to confirm the record return works
    await runtime.startQuest('zahlenwald_start_2'); // if it existed
    // For this test, we already completed it above.

    final inventory = await const InventoryStore().loadForProfile('profile_1');
    expect(inventory.collectibleAmount('sternensamen'), 3);
    expect(inventory.hasUpgrade('leaf_canopy'), isTrue);
  });
}

const _sampleQuestContent = '''
{
  "quests": [
    {
      "id": "zahlenwald_start",
      "title": "Der Zahlenwald",
      "description": "Eine Probequest.",
      "worldNodeId": "zahlenwald",
      "steps": [
        {
          "id": "intro",
          "type": "dialogue",
          "text": "Hallo"
        },
        {
          "id": "challenge",
          "type": "learningChallenge",
          "text": "Loese eine Aufgabe.",
          "learningChallenge": {
            "subject": "math",
            "grade": 1,
            "topic": "addition_bis_10",
            "difficulty": 1,
            "count": 1
          }
        },
        {
          "id": "open_clearing",
          "type": "worldState",
          "worldStateChange": {
            "flags": {
              "zahlenwald_clearing_open": true
            }
          }
        },
        {
          "id": "reward",
          "type": "reward",
          "reward": {
            "id": "sternensamen",
            "title": "Sternensamen",
            "type": "collectible",
            "amount": 3,
            "unlockUpgradeId": "leaf_canopy"
          }
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

class _FakeLearningEngine implements LearningEngine {
  final recordedResults = <bool>[];

  @override
  LearningSession createSession(LearningRequest request) {
    return LearningSession(
      request: request,
      tasks: [
        TaskModel(
          id: 'task_1',
          subject: request.subject.id,
          grade: request.grade,
          topic: request.topic,
          question: '2 + 3 = ?',
          taskType: TaskType.freeInput.name,
          correctAnswer: 5,
          difficulty: request.difficulty,
        ),
      ],
    );
  }

  @override
  TaskResult evaluateTask(TaskModel task, answer) {
    return TaskResult(task: task, answer: answer, correct: answer == '5');
  }

  @override
  Future<void> recordResult({
    required String profileId,
    required Subject subject,
    required int grade,
    required String topic,
    required bool correct,
    int? difficulty,
  }) async {
    recordedResults.add(correct);
  }

  @override
  List<TopicProgress> allProgressForProfile(String profileId) => [];

  @override
  int initialDifficulty({
    required TopicProgress progress,
    required int grade,
  }) => 1;

  @override
  int nextDifficulty({
    required List<int> recentResults,
    required int currentDifficulty,
    String? profileId,
    Subject? subject,
    int? grade,
    String? topic,
  }) => currentDifficulty;

  @override
  TopicProgress progressFor({
    required String profileId,
    required Subject subject,
    required int grade,
    required String topic,
  }) {
    return TopicProgress(
      profileId: profileId,
      subject: subject.id,
      grade: grade,
      topic: topic,
      lastPracticed: DateTime(2026),
    );
  }

  @override
  List<String> topicsFor({
    required String federalState,
    required Subject subject,
    required int grade,
  }) => [];
}
