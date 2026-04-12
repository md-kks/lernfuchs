# Storage and Persistence

## 1. Overview

LernFuchs is fully offline — there is no backend, no network calls, and no third-party analytics. The single persistence layer is [`shared_preferences`](https://pub.dev/packages/shared_preferences), with all complex data structures encoded as JSON strings.

**Migration rule:** SharedPreferences keys are part of the on-device data contract. Renaming a key is a breaking change that will silently discard existing user data. Never change a key without a migration path.

---

## 2. SharedPreferences — Complete Key Table

| Key | Type | Managed by | Content |
|-----|------|------------|---------|
| `lf_settings` | `String` (JSON) | `StorageService` | `AppSettings` object |
| `lf_profiles` | `String` (JSON) | `StorageService` | `List<ChildProfile>` array |
| `lf_progress_<profileId>-<subject>-<grade>-<topic>` | `String` (JSON) | `StorageService` | `TopicProgress` object |
| `lf_quest_status_<profileId>` | `String` (JSON) | `QuestStatusStore` | `Map<questId, QuestStatus>` object |
| `lf_inventory_<profileId>` | `String` (JSON) | `InventoryStore` | `InventoryState` object |
| `lf_daily_path_<profileId>-<yyyy-mm-dd>` | `String` (JSON) | `DailyPathStore` | `DailyPathProgress` object |

---

## 3. StorageService API

**File:** `lib/core/services/storage_service.dart`

Covers the three `StorageService`-managed keys (`lf_settings`, `lf_profiles`, `lf_progress_*`). The other keys (`lf_quest_status_*`, `lf_inventory_*`, `lf_daily_path_*`) are managed by their own dedicated stores — see the "Managed by" column in Section 2.

`StorageService` is a singleton. It must be initialised once before `runApp()`:

```dart
await StorageService.init();
runApp(ProviderScope(child: LernFuchsApp()));
```

After init, the instance is available synchronously anywhere via `StorageService.instance`. Calling `instance` before `init()` throws an `AssertionError`.

### Methods

| Method | Description |
|--------|-------------|
| `static Future<StorageService> init()` | Initialises the singleton; no-op if already initialised. |
| `static StorageService get instance` | Returns the singleton; throws `AssertionError` if not yet initialised. |
| `AppSettings get settings` | Reads and deserialises `lf_settings`; returns `AppSettings()` defaults if absent. |
| `Future<void> saveSettings(AppSettings s)` | Serialises and persists `AppSettings` to `lf_settings`. |
| `List<ChildProfile> get profiles` | Reads and deserialises `lf_profiles`; returns `[]` if absent. |
| `Future<void> saveProfiles(List<ChildProfile> profiles)` | Overwrites the entire profile list in `lf_profiles`. |
| `ChildProfile? getProfile(String id)` | Returns the first profile matching `id`, or `null`. |
| `Future<void> saveProfile(ChildProfile profile)` | Upserts a single profile into the list (replaces by `id`). |
| `TopicProgress getProgress({profileId, subject, grade, topic})` | Reads a `TopicProgress` entry; returns a zeroed entry if absent. |
| `Future<void> saveProgress(TopicProgress progress)` | Persists a `TopicProgress` entry under its composite key. |
| `Future<void> recordResult({profileId, subject, grade, topic, correct})` | Convenience: reads, calls `recordResult(correct)`, then saves. |
| `List<TopicProgress> allProgressForProfile(String profileId)` | Returns all progress entries whose key starts with `lf_progress_<profileId>-`. |

---

## 4. Data Models (JSON Schemas)

### AppSettings

Stored under key `lf_settings`.

```json
{
  "federalState": "BY",
  "soundEnabled": true,
  "ttsEnabled": true,
  "fontSize": 1.0,
  "highContrast": false,
  "activeProfileId": "default",
  "parentPin": null,
  "onboardingDone": false
}
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `federalState` | `String` | `"BY"` | Bundesland code; controls curriculum order. |
| `soundEnabled` | `bool` | `true` | Enables/disables feedback sound effects. |
| `ttsEnabled` | `bool` | `true` | Enables/disables text-to-speech readout. |
| `fontSize` | `double` | `1.0` | Scale factor; valid values: `1.0`, `1.15`, `1.3`. |
| `highContrast` | `bool` | `false` | Accessibility high-contrast mode. |
| `activeProfileId` | `String` | `"default"` | `id` of the currently selected `ChildProfile`. |
| `parentPin` | `String?` | `null` | 4-digit PIN; `null` means the parent area is unprotected. |
| `onboardingDone` | `bool` | `false` | `true` once onboarding flow has been completed. |

---

### ChildProfile

Stored as elements of the JSON array under key `lf_profiles`.

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Emma",
  "grade": 2,
  "avatarEmoji": "🦊",
  "totalStars": 42,
  "createdAt": "2025-09-01T08:00:00.000Z"
}
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `id` | `String` | — | UUID; must be unique across all profiles on the device. |
| `name` | `String` | — | Display name of the child. |
| `grade` | `int` | — | School grade, 1–4. |
| `avatarEmoji` | `String` | `"🦊"` | Single emoji used as avatar; fox is the app mascot. |
| `totalStars` | `int` | `0` | Cumulative stars earned across all topics and sessions. |
| `createdAt` | `String` | — | ISO-8601 timestamp of profile creation. |

---

### TopicProgress

Stored under key `lf_progress_<profileId>-<subject>-<grade>-<topic>`.

```json
{
  "profileId": "550e8400-e29b-41d4-a716-446655440000",
  "subject": "math",
  "grade": 2,
  "topic": "uhrzeit",
  "totalAttempts": 30,
  "correctAttempts": 24,
  "lastPracticed": "2026-04-10T14:32:00.000Z",
  "recentResults": [1, 0, 1, 1, 1, 0, 1, 1, 1, 1]
}
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `profileId` | `String` | — | References the owning `ChildProfile.id`. |
| `subject` | `String` | — | Subject identifier, e.g. `"math"` or `"german"`. |
| `grade` | `int` | — | School grade, 1–4. |
| `topic` | `String` | — | Topic identifier, e.g. `"uhrzeit"` or `"zeitformen"`. |
| `totalAttempts` | `int` | `0` | Total number of answered exercises. |
| `correctAttempts` | `int` | `0` | Number of correctly answered exercises. |
| `lastPracticed` | `String` | — | ISO-8601 timestamp of the last practice session. |
| `recentResults` | `List<int>` | `[]` | Sliding window of last 20 results: `1` = correct, `0` = wrong. |

**Computed getters (not stored in JSON):**

- `accuracy` → `double`: `correctAttempts / totalAttempts`; returns `0.0` when `totalAttempts == 0`.
- `key` → `String`: composite SharedPreferences key in format `"<profileId>-<subject>-<grade>-<topic>"`. This value is appended to the `lf_progress_` prefix when reading/writing.

---

### QuestStatus

Stored as values inside the map under key `lf_quest_status_<profileId>`. The outer JSON object maps `questId → QuestStatus`.

```json
{
  "quest_world1_main": {
    "questId": "quest_world1_main",
    "state": "inProgress",
    "currentStepIndex": 2,
    "completedStepIds": ["step_intro", "step_collect"],
    "grantedRewardIds": ["reward_acorn_x3"],
    "worldState": {}
  }
}
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `questId` | `String` | — | Matches the quest definition ID. |
| `state` | `String` (enum) | `"available"` | One of `"available"`, `"inProgress"`, `"completed"`. |
| `currentStepIndex` | `int` | `0` | Index into the quest's step list. |
| `completedStepIds` | `List<String>` | `[]` | Step IDs that have been finished. |
| `grantedRewardIds` | `List<String>` | `[]` | Reward IDs that have already been granted (prevents double-granting). |
| `worldState` | `Map<String, dynamic>` | `{}` | Arbitrary quest-specific runtime state. |

---

### InventoryState

Stored under key `lf_inventory_<profileId>`.

```json
{
  "collectibles": {
    "acorn": 15,
    "mushroom": 3
  },
  "unlockedUpgradeIds": ["treehouse_level1"]
}
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `collectibles` | `Map<String, int>` | `{}` | Maps collectible ID to quantity. |
| `unlockedUpgradeIds` | `List<String>` | `[]` | Sorted list of unlocked upgrade IDs. |

---

### DailyPathProgress

Stored under key `lf_daily_path_<profileId>-<yyyy-mm-dd>`.

```json
{
  "profileId": "550e8400-e29b-41d4-a716-446655440000",
  "dateKey": "2026-04-12",
  "completedStepIds": ["step_math_1", "step_german_1"],
  "rewardGranted": false
}
```

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `profileId` | `String` | — | References the owning `ChildProfile.id`. |
| `dateKey` | `String` | — | Date in `yyyy-mm-dd` format; part of the storage key. |
| `completedStepIds` | `List<String>` | `[]` | Sorted list of `DailyPathStep.id` values that are done. |
| `rewardGranted` | `bool` | `false` | `true` once the daily completion reward has been issued. |

---

## 5. Riverpod Provider Table

All providers are defined in `lib/core/services/providers.dart`.

| Provider | Type | Description | Write method |
|----------|------|-------------|--------------|
| `storageServiceProvider` | `Provider<StorageService>` | Exposes the `StorageService` singleton. No `await` needed; init happens in `main()`. | — (singleton, no write) |
| `learningEngineProvider` | `Provider<LearningEngine>` | `DefaultLearningEngine` wired to `storageServiceProvider`. | — |
| `dailyPathServiceProvider` | `Provider<DailyPathService>` | `DailyPathService` wired to `learningEngineProvider`. | — |
| `ttsServiceProvider` | `Provider<TtsService>` | `TtsService` instance; **must** be provided via `ProviderScope` overrides in `main()`. | — |
| `soundServiceProvider` | `Provider<SoundService>` | `SoundService` instance; **must** be provided via `ProviderScope` overrides in `main()`. | — |
| `appSettingsProvider` | `StateNotifierProvider<AppSettingsNotifier, AppSettings>` | Reactive `AppSettings` state. | `ref.read(appSettingsProvider.notifier).<method>()` |
| `activeProfileProvider` | `Provider<ChildProfile?>` | Currently active `ChildProfile` derived from `appSettingsProvider.activeProfileId`. Returns `null` if no profile exists. | `ref.read(appSettingsProvider.notifier).switchProfile(id)` |
| `allProfilesProvider` | `Provider<List<ChildProfile>>` | All `ChildProfile` records from storage. | `StorageService.instance.saveProfile(p)` |
| `topicProgressProvider` | `Provider.family<TopicProgress, ({profileId, subject, grade, topic})>` | Progress for a single topic. Parametrised by a named-record tuple. | `StorageService.instance.recordResult(...)` |
| `allProgressProvider` | `Provider<List<TopicProgress>>` | All progress entries for the active profile. Returns `[]` if no profile is active. | `StorageService.instance.recordResult(...)` |

---

## 6. AppSettingsNotifier Methods

`AppSettingsNotifier` is the only sanctioned write path for `AppSettings`. Every method updates the in-memory Riverpod state and persists via `StorageService.saveSettings`.

| Method | Description |
|--------|-------------|
| `updateFederalState(String code)` | Sets the Bundesland/state code (e.g. `"BY"`, `"NW"`). |
| `setOnboardingDone()` | Marks `onboardingDone = true`; called at the end of the onboarding flow. |
| `toggleSound(bool value)` | Enables or disables feedback sound effects. |
| `toggleTts(bool value)` | Enables or disables text-to-speech. |
| `toggleHighContrast(bool value)` | Enables or disables accessibility high-contrast mode. |
| `updateFontSize(double factor)` | Sets the font scale factor (`1.0` / `1.15` / `1.3`). |
| `setParentPin(String pin)` | Sets a 4-digit parent PIN. |
| `clearParentPin()` | Removes the parent PIN by reconstructing `AppSettings` with `parentPin: null` (bypasses `copyWith` nullable limitation). |
| `switchProfile(String profileId)` | Switches the active child profile by updating `activeProfileId`. |

---

## 7. Write / Read Paths

| Writer | Data written | Readers |
|--------|-------------|---------|
| `LearningChallengeSession` | `TopicProgress` (via `StorageService.recordResult`) | `ProgressScreen`, `SubjectOverviewScreen`, `ParentDashboardScreen` |
| `ResultScreen` | `ChildProfile.totalStars` (via `StorageService.saveProfile`) | `HomeScreen`, `ProfileScreen` |
| `OnboardingScreen` | `AppSettings` (via `AppSettingsNotifier`) | Everywhere via `appSettingsProvider` |
| `SettingsScreen` | `AppSettings` (via `AppSettingsNotifier`) | Everywhere via `appSettingsProvider` |
| `ProfileScreen` | `ChildProfile` (via `StorageService.saveProfile`) | `HomeScreen`, `ParentDashboardScreen` |
| `QuestRuntime` | `QuestStatus` (via `QuestStatusStore.saveForProfile`) | `LernFuchsWorldGame`, `QuestRuntime` |
| `QuestRuntime` | `InventoryState` (via `InventoryStore.grantReward`) | `BaumbausScreen` |
| `DailyPathScreen` | `DailyPathProgress` (via `DailyPathStore.save`) | `DailyPathScreen` |
