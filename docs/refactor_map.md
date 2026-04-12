# Refactor Map

This map documents the current Flutter learning app shape and the intended
staging areas for a later hybrid Flutter + Flame migration. It is preparatory
only: existing routes, screens, storage, and learning behavior remain unchanged.

## Current Screens

- `lib/features/settings/onboarding_screen.dart`: first-run setup, federal-state
  selection, default child profile creation, and onboarding completion.
- `lib/features/home/home_screen.dart`: home hub with grade selection and entry
  points for profile, settings, progress, and parent dashboard.
- `lib/features/subject_overview/subject_overview_screen.dart`: subject and
  topic selection for a grade, driven by the current federal-state curriculum.
- `lib/features/exercise/exercise_screen.dart`: 10-task learning session,
  answer widget dispatch, evaluation, progress recording, TTS, and sound
  feedback.
- `lib/features/exercise/result_screen.dart`: session result summary, star
  calculation, and profile star award.
- `lib/features/progress/progress_screen.dart`: learner-facing progress summary
  for the active profile.
- `lib/features/profile/profile_screen.dart`: child profile CRUD and active
  profile switching.
- `lib/features/settings/settings_screen.dart`: federal-state, sound, TTS,
  accessibility, parent PIN, and static app-info settings.
- `lib/features/parent/parent_dashboard_screen.dart`: parent-facing progress
  dashboard over stored profile progress.
- `lib/features/worksheet/worksheet_screen.dart`: printable worksheet view using
  deterministic task generation.

Routes are currently centralized in `lib/app/router.dart` with go_router. The
initial route remains `/home`, with onboarding enforced by the existing
`StorageService.instance.settings.onboardingDone` redirect.

## Current Data Flow

- `main.dart` initializes `StorageService`, creates `TtsService` and
  `SoundService`, then injects service overrides through `ProviderScope`.
- `lib/core/services/providers.dart` exposes Riverpod providers for storage,
  TTS, sound, app settings, active profile, all profiles, per-topic progress,
  and all progress for the active profile.
- `StorageService` persists all data locally through SharedPreferences:
  app settings, child profiles, and per-profile topic progress.
- `Curriculum` maps the selected federal state, grade, and subject into topic
  lists for the subject overview.
- `TaskGenerator` owns the current template registry and generates exercise or
  worksheet tasks from `TaskTemplate` implementations.
- `Evaluator` checks submitted answers against the generated `TaskModel`.
- `DifficultyEngine` updates session difficulty from recent exercise results.
- `ExerciseScreen` is the write path for topic progress via
  `StorageService.recordResult`.
- `ResultScreen` is the write path for profile star totals via
  `StorageService.saveProfile`.
- `ProgressScreen`, `SubjectOverviewScreen`, and `ParentDashboardScreen` are
  read paths over the Riverpod providers and `StorageService`.

## Intended Target Areas

- `lib/core/learning/`: future home for framework-independent learning domain
  contracts such as task sessions, evaluation orchestration, progress use cases,
  difficulty policy, and curriculum adapters. Existing `lib/core/engine/*`
  code should move here only in later behavior-preserving steps.
- `lib/game/`: future Flame integration boundary. Flutter routes should remain
  stable while the game world is introduced behind feature flags.
- `lib/game/world/`: future Flame world, camera, systems, and scene composition.
- `lib/game/quest/`: future quest/session mapping from learning topics into game
  objectives.
- `lib/game/dialogue/`: future character dialogue, prompts, and narrative UI
  coordination.
- `lib/game/reward/`: future reward presentation, stars, collectibles, and
  progression bridge.
- `lib/game/data/`: future game-side static data and adapters that translate
  existing learning data into game content.
- `lib/app/feature_flags.dart`: central switch point for staged rollout.
  `FeatureFlags.enableGameWorld` is currently `false` and is not wired into
  behavior yet.

## Migration Notes

- Keep the existing Flutter screens as the source of truth until equivalent
  Flame flows are introduced and tested behind `FeatureFlags.enableGameWorld`.
- Introduce adapters before moving logic: route existing `TaskGenerator`,
  `Evaluator`, `DifficultyEngine`, and progress persistence through stable
  interfaces in `core/learning`.
- Keep persistence keys unchanged during the migration to avoid losing existing
  learner profiles and progress.
- Add Flame dependencies only when the first game-world screen is implemented.
  This preparation step intentionally does not add new dependencies.
