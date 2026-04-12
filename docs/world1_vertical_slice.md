# World 1 Vertical Slice

World 1 is the first complete playable slice of the hybrid Flutter + Flame app.
It stays intentionally small: one map, five quests, one mentor, and local
profile rewards only.

## Playable Flow

- Prolog: `prolog_ovas_ruf`
- Baumhaus hub: `/home/baumhaus`, backed by local `InventoryState`
- Flüsterwald map: `/home/weltkarte`, rendered by `LernFuchsWorldGame`
- Main quests:
  - `prolog_ovas_ruf`
  - `main_zahlenpfad`
  - `main_buchstabenhain`
- Side quests:
  - `side_silbenquelle`
  - `side_musterlichtung`

Each quest uses the existing QuestRuntime step flow:

- local dialogue scene through `DialogueOverlay`
- one `LearningChallengeOverlay` step backed by `LearningEngine`
- world-state flag update for the Flame node
- local inventory reward through `InventoryStore`

## Placeholder Assets

- Flame map background is hand-drawn canvas shapes.
- Quest nodes are simple circles with icon marks.
- Player character is a simple canvas fox placeholder.
- Ova portrait uses the data-driven `portraitFallback` letter instead of an
  image asset.
- Baumhaus uses emoji-style placeholder visuals for the locked and upgraded
  states.

## Systems Proven

- Flutter remains responsible for hub UI, overlays, rewards, and normal routes.
- Flame remains limited to the interactive world-map layer.
- Quest definitions are local JSON assets.
- Dialogue and hints are local JSON assets.
- Learning challenges reuse existing generator/evaluator/progress recording.
- Quest rewards update profile-local inventory without backend, telemetry, or
  store logic.
