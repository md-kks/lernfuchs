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
- Reward-Schritte aktualisieren sowohl den Quest-Status als auch das
  profil-lokale `InventoryState`. Die Vergabe ist idempotent abgesichert:
  Belohnungen werden nur gewährt, wenn ihre ID noch nicht in
  `QuestStatus.grantedRewardIds` enthalten ist.
- Quests im Vertical Slice vergeben `sternensamen` und schalten Baumhaus-Upgrades
  wie die `baumhaus_laterne` frei.
- Flutter rendert Quest-Overlays und UI-Formulare. Flame emittiert lediglich
  Quest-Node-Tap-Callbacks von der Weltkarte.

## Challenge Overlay Modes

- `LearningSessionMode.freePractice` behält den existierenden Übungs-Route- und
  Ergebnisscreen-Flow bei.
- `LearningSessionMode.questSingle` läuft innerhalb von `ForestQuestOverlay`
  und meldet den Abschluss über einen Callback, anstatt zum alten
  Ergebnisscreen zu navigieren. Die Anzahl der Aufgaben wird dynamisch aus der
  Quest-Definition (`count`) gelesen.
- `LearningSessionMode.questMiniSeries` und `LearningSessionMode.dailyPath` sind
  für zukünftige Flows vorbereitet.
- Ein Quest-Erfolg führt zu `QuestRuntime.completeCurrentStep`. Diese Methode
  gibt einen Record `({QuestStatus status, List<QuestRewardDefinition> rewards})`
  zurück, was der UI ermöglicht, Belohnungen (z.B. im `QuestRewardOverlay`)
  anzuzeigen.
- Der resultierende `worldState` wird via `LernFuchsWorldGame.updateWorldState`
  zurück in die Flame-Weltkarte gegeben.

## Next Integration Hooks

- Map `WorldQuestNode.questId` values to more quest definitions as content grows.
- Use `QuestStatus.worldState` to alter Flame node visuals after completion.
- Add mini-series and daily-path orchestration on top of
  `LearningChallengeSession` once those flows have concrete product behavior.
- World 1 currently wires eight productive `WorldQuestNode.questId` links for
  the Flüsterwald slice: four Kapitel-1 quests and four Kapitel-2 quests.
  Kapitel 3 is planned in `docs/world1_vertical_slice.md` but not yet a
  productive quest slice.
