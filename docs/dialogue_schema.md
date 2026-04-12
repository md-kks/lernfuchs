# Dialogue And Hints

## Dialogue Schema

Dialogue content is local-only and loaded from `assets/dialogue/*.json` or
`*.yaml`. A dialogue library contains reusable characters and scenes.

```json
{
  "schemaVersion": 1,
  "characters": [
    {
      "id": "ova",
      "name": "Ova",
      "portraitAsset": "",
      "portraitFallback": "O"
    }
  ],
  "scenes": [
    {
      "id": "zahlenwald_intro",
      "title": "Hallo im Zahlenwald",
      "lines": [
        {
          "speakerId": "ova",
          "text": "Hallo, ich bin Ova."
        }
      ]
    }
  ]
}
```

Quest dialogue steps reference scenes with `dialogueSceneId`. The old `text`
field still works as a compatibility fallback.

## Hint Schema

Challenge hints are separate from quests so the same mentor and hint set can be
reused in free practice, quest challenges, mini-series, or daily paths.

```json
{
  "schemaVersion": 1,
  "hintSets": [
    {
      "id": "addition_bis_10_ova",
      "mentorCharacterId": "ova",
      "levels": [
        {
          "level": 1,
          "title": "Erster Tipp",
          "text": "Starte mit der groesseren Zahl."
        }
      ]
    }
  ]
}
```

Quest learning challenge steps reference hint sets with `hintSetId`. The
current Flutter `LearningChallengeOverlay` reveals the next hint level when the
learner asks for help; Flame remains limited to the world-map layer.
