# World 1 Vertical Slice

World 1 is the first complete playable slice of the hybrid Flutter + Flame app.
It stays intentionally small: one map, five quests, one mentor, and local
profile rewards only.

## Playable Flow

Der vollständige Happy Path ist implementiert und durch Integrationstests abgesichert:
**Weltkarte -> Quest starten -> Lernchallenge -> RewardOverlay -> Rückkehr -> sichtbarer Fortschritt im Baumhaus.**

- Prolog: `prolog_ovas_ruf`
- Baumhaus hub: `/home/baumhaus`, liest Upgrades/Items direkt aus dem `InventoryStore`.
- Flüsterwald map: geöffnet aus dem Dashboard, gesteuert durch `enableGameWorld`.
- Hauptquests:
  - `prolog_ovas_ruf` (schaltet `baumhaus_laterne` frei)
  - `main_zahlenpfad` (schaltet `baumhaus_bank` frei)
  - `main_buchstabenhain` (schaltet `baumhaus_kristall_blau` frei)

Jede Quest nutzt den validierten Flow:
- Lokale Dialogszene via `QuestIntroScreen`
- `ForestQuestOverlay` (Challenge-Länge dynamisch aus Quest-Daten)
- Belohnungsanzeige via `QuestRewardOverlay`
- Idempotente Belohnungsvergabe via `QuestRuntime` an den `InventoryStore`.

## Placeholder Assets

- Flame map background: Handgezeichnete Canvas-Shapes.
- Quest nodes: Interaktive Komponenten mit Status-Visualisierung (locked/current/completed).
- Player character: `WorldMapFinoComponent` mit Laufanimationen und Trail-Effekten.
- Baumhaus: Detaillierte Visualisierung via `BaumhausPainter` mit Unterstützung für diverse Upgrades und Wachstumsstufen.

## Systems Proven

- Flutter remains responsible for hub UI, overlays, rewards, and normal routes.
- Flame remains limited to the interactive world-map layer.
- Quest definitions are local JSON assets.
- Dialogue and hints are local JSON assets.
- Learning challenges reuse existing generator/evaluator/progress recording.
- Quest rewards update profile-local inventory without backend, telemetry, or
  store logic.
