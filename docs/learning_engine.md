# Learning Engine

The learning engine is the central coordination layer between curriculum data, task generation, difficulty adaptation, and progress persistence. It is consumed by exercise widgets, the daily path service, and the quest runtime.

For the daily path specifically (`DailyPathService`, `DailyPathStore`, daily path screen flow), see [`docs/daily_path.md`](daily_path.md).

---

## 1. LearningEngine (Interface)

**File:** `lib/core/learning/learning_engine.dart`  
**Riverpod provider:** `learningEngineProvider` (defined in `lib/core/services/providers.dart`)

```dart
abstract class LearningEngine { … }
```

### Methods

| Method | Full Signature | Description |
|---|---|---|
| `topicsFor` | `List<String> topicsFor({required String federalState, required Subject subject, required int grade})` | Returns all topic keys for the given federal state, subject, and grade from the curriculum. |
| `createSession` | `LearningSession createSession(LearningRequest request)` | Generates a `LearningSession` containing a list of `TaskModel` objects for the given request. |
| `evaluateTask` | `TaskResult evaluateTask(TaskModel task, dynamic answer)` | Checks whether `answer` is correct for `task` and returns a `TaskResult`. |
| `nextDifficulty` | `int nextDifficulty({required List<int> recentResults, required int currentDifficulty, String? profileId, Subject? subject, int? grade, String? topic})` | Computes the next difficulty level based on the updated Elo rating (or a virtual fallback). |
| `initialDifficulty` | `int initialDifficulty({required TopicProgress progress, required int grade})` | Derives a starting difficulty from stored Elo rating using `EloDifficultyEngine`. |
| `progressFor` | `TopicProgress progressFor({required String profileId, required Subject subject, required int grade, required String topic})` | Loads persisted progress for a single topic. |
| `allProgressForProfile` | `List<TopicProgress> allProgressForProfile(String profileId)` | Loads all persisted progress records for a profile. |
| `recordResult` | `Future<void> recordResult({required String profileId, required Subject subject, required int grade, required String topic, required bool correct})` | Persists a single answer result and updates Elo rating. |

---

## 2. DefaultLearningEngine

**File:** `lib/core/learning/default_learning_engine.dart`

```dart
class DefaultLearningEngine implements LearningEngine {
  const DefaultLearningEngine(StorageService storage);
}
```

**Dependency:** `StorageService` (injected via constructor, sourced from `storageServiceProvider`).

### Delegation tree

```
DefaultLearningEngine
├── topicsFor             → Curriculum(federalState).mathTopics / .germanTopics
├── createSession         → TaskGenerator.generateSession(...)
├── evaluateTask          → Evaluator.evaluate(task, answer)
├── nextDifficulty        → EloDifficultyEngine.recommendDifficulty(progress.eloRating)
├── initialDifficulty     → EloDifficultyEngine.recommendDifficulty(progress.eloRating)
├── progressFor           → StorageService.getProgress(...)
├── allProgressForProfile → StorageService.allProgressForProfile(profileId)
└── recordResult          → StorageService.recordResult(...)
```

### Consuming the instance

```dart
final engine = ref.read(learningEngineProvider);
```

The provider is registered as:

```dart
final learningEngineProvider = Provider<LearningEngine>((ref) {
  return DefaultLearningEngine(ref.watch(storageServiceProvider));
});
```

---

## 3. LearningRequest

**File:** `lib/core/learning/learning_request.dart`

```dart
class LearningRequest {
  const LearningRequest({
    required this.subject,
    required this.grade,
    required this.topic,
    required this.difficulty,
    this.count = 10,
    this.seed,
  });
}
```

### Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `subject` | `Subject` | required | The school subject (`Subject.math` or `Subject.german`). |
| `grade` | `int` | required | School grade (1–4). |
| `topic` | `String` | required | Topic key string (e.g. `'addition'`, `'diktat'`). |
| `difficulty` | `int` | required | Starting difficulty level passed to the task generator. |
| `count` | `int` | `10` | Number of tasks to generate in the session. |
| `seed` | `int?` | `null` | Optional RNG seed for reproducible task sequences. |
| `subjectId` | `String` | computed getter | Shorthand for `subject.id`; derived, not stored. |

---

## 4. LearningSession

**File:** `lib/core/learning/learning_session.dart`

```dart
class LearningSession {
  final LearningRequest request;
  final List<TaskModel> tasks;

  bool get isEmpty => tasks.isEmpty;
}
```

### Fields

| Field | Type | Description |
|---|---|---|
| `request` | `LearningRequest` | The request that produced this session. |
| `tasks` | `List<TaskModel>` | Ordered list of generated tasks. |

### `isEmpty` getter

Returns `true` when `tasks` is empty. This occurs when `TaskGenerator` has no template registered for the requested topic, meaning the topic exists in the curriculum but has not yet been implemented in the task generator. `LearningChallengeSession` checks `isEmpty` and shows a "Dieses Thema ist noch in Entwicklung." fallback screen.

---

## 5. LearningSessionMode

**File:** `lib/features/exercise/learning_session_mode.dart`

```dart
enum LearningSessionMode {
  freePractice,
  questSingle,
  questMiniSeries,
  dailyPath,
}
```

### Values

| Value | Description | Behavior after completion |
|---|---|---|
| `freePractice` | Standalone practice started from the subject overview or exercise screen. | `LearningChallengeSession` caller calls `Navigator.pushReplacement` to the `ResultScreen`. |
| `questSingle` | A single-task learning step embedded inside a quest. | Calls the `onCompleted` callback; the quest UI handles navigation. |
| `questMiniSeries` | A short multi-task series inside a quest. | Calls the `onCompleted` callback; the quest UI handles navigation. |
| `dailyPath` | A session driven by the daily learning path. | Calls the `onCompleted` callback; the daily path UI handles navigation. |

---

## 6. LearningChallengeSession (Widget)

**File:** `lib/features/exercise/learning_challenge_session.dart`

`LearningChallengeSession` is a `ConsumerStatefulWidget` that drives a complete interactive task sequence from start to result. It reads `learningEngineProvider` directly, so it requires a `ProviderScope` ancestor.

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `request` | `LearningRequest` | required | Defines the subject, grade, topic, difficulty, and task count for the session. |
| `mode` | `LearningSessionMode` | required | Controls post-completion routing behavior. |
| `onCompleted` | `ValueChanged<LearningChallengeResult>` | required | Callback invoked when the last task is answered. |
| `showScaffold` | `bool` | `true` | When `false`, the widget renders without a `Scaffold`/`AppBar` (for embedding in overlays or quest UIs). |
| `recordProgress` | `bool` | `true` | When `true`, calls `LearningEngine.recordResult()` after each answered task. |
| `onCancel` | `VoidCallback?` | `null` | Optional callback for the cancel/back action. Falls back to `Navigator.pop` if not provided. |

### Session flow

```
1. initState
   └── _loadTasks()
       └── learningEngineProvider.createSession(request)
           → _tasks populated (may be empty → fallback screen)
   └── Future.delayed(400 ms) → TtsService.speak(currentTask.question)

2. LearningAnswerWidget renders currentTask
   └── User interacts → onAnswerChanged() sets _pendingAnswer

3. User taps "Prüfen" → _submitAnswer()
   ├── learningEngineProvider.evaluateTask(currentTask, _pendingAnswer)
   ├── recordProgress == true
   │   └── learningEngineProvider.recordResult(...)
   ├── correct == true  → SoundService.playCorrect()
   └── correct == false → SoundService.playWrong()
   └── FeedbackOverlay shown

4. Future.delayed(1200 ms) → _nextTask()
   ├── Last task reached
   │   └── onCompleted(LearningChallengeResult) ← session ends
   └── More tasks remain
       ├── learningEngineProvider.nextDifficulty(recentResults, currentDifficulty)
       ├── _currentIndex++
       └── Future.delayed(300 ms) → TtsService.speak(nextTask.question)
```

---

## 7. LearningChallengeResult

**File:** `lib/features/exercise/learning_session_mode.dart`

```dart
class LearningChallengeResult { … }
```

Passed to the `onCompleted` callback at the end of every session.

### Fields

| Field | Type | Description |
|---|---|---|
| `mode` | `LearningSessionMode` | The mode the session was run in. |
| `grade` | `int` | School grade taken from the originating request. |
| `subjectId` | `String` | Subject identifier string (e.g. `'math'`, `'german'`). |
| `topic` | `String` | Topic key string from the originating request. |
| `correctCount` | `int` | Number of tasks answered correctly. |
| `totalCount` | `int` | Total number of tasks in the session. |
| `successful` | `bool` | Computed getter: `correctCount == totalCount`. |

---

## 8. Zusammenspiel mit QuestRuntime

**File:** `lib/game/quest/quest_runtime.dart`

### Who creates LearningRequest

`QuestRuntime.createLearningRequest(questId)` builds a `LearningRequest` from the current `QuestStepDefinition.learningChallenge` fields (`subject`, `grade`, `topic`, `difficulty`, `count`). The caller (quest UI) receives this request and passes it to `LearningChallengeSession`.

```dart
// QuestRuntime
LearningRequest createLearningRequest(String questId) {
  final challenge = currentStep(questId)!.learningChallenge!;
  return LearningRequest(
    subject: challenge.subject,
    grade: challenge.grade,
    topic: challenge.topic,
    difficulty: challenge.difficulty,
    count: challenge.count,
  );
}
```

### How LearningChallengeSession is invoked from quest context

When embedding a learning challenge in the quest overlay (`LearningChallengeOverlay`), the widget is instantiated with:

```dart
LearningChallengeSession(
  request: request,            // from QuestRuntime.createLearningRequest()
  mode: LearningSessionMode.questSingle,   // or questMiniSeries
  showScaffold: false,         // embedded inside the overlay card
  recordProgress: true,        // progress is still persisted
  onCompleted: onCompleted,    // quest UI callback
  onCancel: onClose,
)
```

### Callback decoupling

`LearningChallengeSession` has no import of or reference to `QuestRuntime`. It only calls `onCompleted(LearningChallengeResult)`. The quest UI layer (e.g. the world map screen or a quest step widget) owns the `QuestRuntime` instance and decides what to do with the result — for example calling `QuestRuntime.completeCurrentStep()`. This keeps the exercise widget reusable across free practice, quests, and the daily path without any feature-layer dependencies.

---

## 6. Session-Sequenzierung & Datenkonsistenz

Um sicherzustellen, dass die Schwierigkeitsanpassung auf dem aktuellsten Elo-Stand basiert, folgt der Antwortprozess in `LearningChallengeSession` einer strikten asynchronen Sequenz:
1. **Antwort-Evaluation:** Synchrone Prüfung via `LearningEngine.evaluateTask`.
2. **Asynchrones Speichern:** Aufruf von `LearningEngine.recordResult` (aktualisiert das Elo-Rating im Storage) wird via `await` abgewartet.
3. **Schwierigkeitsanpassung:** Erst nach Abschluss des Speichervorgangs wird `LearningEngine.nextDifficulty` gerufen. Dadurch liest die Engine garantiert den neuen Elo-Stand aus dem Storage.
