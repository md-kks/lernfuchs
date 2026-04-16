# LernFuchs

Offline-Lernapp für Grundschulkinder (Klasse 1–4) in Mathe und Deutsch.
Bundesland-spezifischer Lehrplan, adaptiver Schwierigkeitsgrad, Spielwelt (Flutter + Flame).

## Tech-Stack

| Paket | Zweck |
|---|---|
| Flutter 3 | UI-Framework |
| flutter_riverpod ^2.6.1 | State Management |
| go_router ^14.8.1 | Navigation |
| shared_preferences ^2.5.3 | Lokale Persistenz (kein Backend) |
| flutter_tts ^4.2.0 | Text-to-Speech |
| flame ^1.37.0 | Spielwelt-Karte |
| yaml ^3.1.3 | Quest/Dialogue-Assets laden |

## Setup

```bash
flutter pub get
flutter run
```

Kein Backend, keine Umgebungsvariablen, keine API-Keys nötig.

## Projektstruktur

```
lib/
├── app/                    # Router, Theme, FeatureFlags
├── core/
│   ├── engine/             # TaskTemplate, TaskGenerator, Evaluator, DifficultyEngine, Curriculum
│   ├── learning/           # LearningEngine-Interface, DefaultLearningEngine, DailyPath
│   ├── models/             # TaskModel, TopicProgress, ChildProfile, AppSettings, Subject
│   └── services/           # StorageService, TtsService, SoundService, Riverpod-Provider
├── features/
│   ├── exercise/           # LearningChallengeSession, alle Aufgaben-Widgets, ResultScreen
│   ├── home/               # HomeScreen, WorldMapScreen, BaumbausScreen, DailyPathScreen
│   ├── parent/             # ParentDashboardScreen
│   ├── profile/            # ProfileScreen
│   ├── progress/           # ProgressScreen
│   ├── settings/           # SettingsScreen, OnboardingScreen
│   ├── subject_overview/   # SubjectOverviewScreen
│   └── worksheet/          # WorksheetScreen
├── game/
│   ├── dialogue/           # DialogueDefinition, HintDefinition, DialogueOverlay
│   ├── quest/              # QuestDefinition, QuestRuntime, QuestStatusStore
│   ├── reward/             # InventoryState, InventoryStore, BaumhausUpgrade
│   └── world/              # LernFuchsWorldGame (Flame), WorldQuestNode
└── shared/
    ├── constants/          # AppColors, AppTextStyles
    └── widgets/            # StarRating, TaskCard, FeedbackOverlay, ProgressBar, RoundedButton

assets/
├── audio/                  # Feedback-Sounds
├── dialogue/               # Dialogue- und Hint-JSON (z.B. ova_dialogues.json)
├── fonts/                  # Nunito Regular/Bold/ExtraBold
├── images/                 # Grafiken
└── quests/                 # Quest-Definitionen (z.B. sample_quests.json)
```

## Dokumentation

Kanonischer Einstieg für Agentenarbeit:
`docs/lernfuchs_2_systems.md` beschreibt den aktuellen Startfluss und die
App-Systeme, `docs/world1_vertical_slice.md` den implementierten und geplanten
World-1-Rahmen, `docs/quest_runtime.md`/`docs/meta_progression.md` Quest- und
Reward-Laufzeitverhalten. Historische oder generierte Planungsdokumente sind
in der jeweiligen Datei als nicht-kanonisch markiert.

| Dokument | Inhalt |
|---|---|
| [docs/engine.md](docs/engine.md) | TaskTemplate, TaskGenerator, Evaluator, DifficultyEngine, Curriculum |
| [docs/learning_engine.md](docs/learning_engine.md) | LearningEngine, Session-Ablauf, LearningSessionMode |
| [docs/storage_and_persistence.md](docs/storage_and_persistence.md) | SharedPreferences-Keys, Riverpod-Provider, Datenmodelle |
| [docs/exercise_widgets.md](docs/exercise_widgets.md) | Alle Aufgaben-Widgets und Dispatch-Logik |
| [docs/feature_flags.md](docs/feature_flags.md) | Feature Flags und Erweiterungsanleitung |
| [docs/refactor_map.md](docs/refactor_map.md) | Architekturübersicht, Migrationsziel Flutter+Flame |
| [docs/app_shell_migration_notes.md](docs/app_shell_migration_notes.md) | Routenbaum, Flame/Flutter-Grenze |
| [docs/quest_runtime.md](docs/quest_runtime.md) | Quest-Schema, Laufzeitverhalten |
| [docs/dialogue_schema.md](docs/dialogue_schema.md) | Dialogue- und Hint-JSON-Format |
| [docs/meta_progression.md](docs/meta_progression.md) | Inventar, Baumhaus-Upgrades |
| [docs/daily_path.md](docs/daily_path.md) | Tages-Pfad-Logik |
| [docs/world1_vertical_slice.md](docs/world1_vertical_slice.md) | World 1 Playable Slice |
| [docs/story_canon.md](docs/story_canon.md) | Story-Kanon, Charaktere und narrative Leitlinien |
| [docs/ml_training_workflow.md](docs/ml_training_workflow.md) | ML Training Workflow (Handschrifterkennung) |
| [docs/lernfuchs_2_systems.md](docs/lernfuchs_2_systems.md) | LernFuchs 2.0 Story-, Daily-, Expedition-, Accessibility-, School-, Baumhaus- und Finale-Systeme |
