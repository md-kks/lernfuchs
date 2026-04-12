# Daily Path

The daily path is an offline-only route of short learning challenges for the
active profile.

## Composition

`DailyPathService` builds a deterministic daily route from existing learning
data:

- grade fit comes from the active `ChildProfile.grade`
- candidate topics come from `LearningEngine.topicsFor`
- weak areas are prior topics with accuracy below `0.75`
- recent topics are selected from `TopicProgress.lastPracticed`
- fresh topics are unpracticed topics that are not among the most recent items

Each step becomes a `LearningRequest` and is launched through the existing
`LearningChallengeOverlay` with `LearningSessionMode.dailyPath`.

## Persistence

`DailyPathStore` persists completion per profile and date under
`lf_daily_path_<profileId>-<yyyy-mm-dd>`.

When all steps are completed, the screen grants one local `sternensamen` through
`InventoryStore`. The reward is guarded by `DailyPathProgress.rewardGranted` so
the same daily path does not grant repeatedly.
