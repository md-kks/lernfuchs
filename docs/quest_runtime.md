# Quest Runtime

## Data Schema

Quest content is loaded from local JSON or YAML assets. The top-level file can
contain either a list of quests or an object with a `quests` list.

```json
{
  "schemaVersion": 1,
  "quests": [
    {
      "id": "zahlenwald_start",
      "title": "Der Zahlenwald",
      "description": "Short local-only quest description.",
      "worldNodeId": "zahlenwald",
      "unlockCondition": {
        "completedQuestIds": [],
        "worldFlags": {}
      },
      "steps": [
        {
          "id": "intro",
          "type": "dialogue",
          "title": "Hallo im Zahlenwald",
          "text": "Dialogue text shown by Flutter."
        },
        {
          "id": "challenge",
          "type": "learningChallenge",
          "title": "Erste Mathe-Spur",
          "text": "Solve one task.",
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
            "amount": 1
          }
        }
      ]
    }
  ]
}
```

## Runtime Boundary

- `QuestDefinitionLoader` loads local JSON/YAML assets only.
- `QuestRuntime` owns quest step progression, local quest status, world flags,
  and reward grants.
- `QuestStatusStore` persists quest state per profile in local
  SharedPreferences under `lf_quest_status_<profileId>`.
- Dialogue steps can reference local dialogue scenes with `dialogueSceneId`.
  Flutter renders those scenes with `DialogueOverlay`.
- Learning challenge steps call the existing `LearningEngine` to generate,
  evaluate, and record tasks. Quest code does not duplicate learning logic.
- Learning challenge steps can reference local escalating hints with
  `hintSetId`. `LearningChallengeOverlay` renders those hints through Flutter.
- Reward steps update both quest status and the profile-local `InventoryState`.
  The sample quest grants `sternensamen` and unlocks the Baumhaus
  `leaf_canopy` visual upgrade.
- Flutter renders quest overlays and form UI. Flame only emits quest-node tap
  callbacks from the world map.

## Challenge Overlay Modes

- `LearningSessionMode.freePractice` keeps the existing exercise route and
  result-screen flow intact.
- `LearningSessionMode.questSingle` runs inside `LearningChallengeOverlay` and
  reports completion through a callback instead of navigating to the old result
  screen.
- `LearningSessionMode.questMiniSeries` and `LearningSessionMode.dailyPath` are
  available for the next staged flows without changing the current routes.
- Quest success advances `QuestRuntime.completeCurrentStep`, persists quest
  status locally, and pushes the resulting world-state flags back into the Flame
  world map through `LernFuchsWorldGame.updateWorldState`.

## Next Integration Hooks

- Map `WorldQuestNode.questId` values to more quest definitions as content grows.
- Use `QuestStatus.worldState` to alter Flame node visuals after completion.
- Add mini-series and daily-path orchestration on top of
  `LearningChallengeSession` once those flows have concrete product behavior.
- World 1 currently uses five `WorldQuestNode.questId` links for the
  Flüsterwald vertical slice.
