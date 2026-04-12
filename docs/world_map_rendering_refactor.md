# World Map Rendering Refactor

## Summary

The world map rendering was split into dedicated Flame components and the quest
node model was simplified around render state and node type.

## Changed Files

- `lib/game/world/world_quest_node.dart`
  - Added `QuestNodeState` with `current`, `completed`, `available`, and
    `locked`.
  - Added `QuestNodeType` with `start`, `clearing`, `tree`, `bridge`, and
    `lake`.
  - Replaced the node data shape with `id`, `mapPosition`, `state`, `type`, and
    `label`.
  - Kept compatibility getters for existing callers: `questId`, `title`, and
    `subtitle`.

- `lib/game/world/world_map_background.dart`
  - Added `WorldMapBackground`, a Flame component that renders the map
    background with Canvas primitives.
  - Added the shared fractional node positions, edges, and path control points.
  - Added background patches, trees, clearing, paths, mushrooms, flowers, and
    edge framing trees using the requested 400x660 reference coordinate system.

- `lib/game/world/world_map_node_component.dart`
  - Added `WorldMapNodeComponent`, a tappable node component with priority 1.
  - Renders platform rings, state-dependent colors, icons, and label pills.
  - Calls `gameRef.onNodeTapped(questNode)` on tap for unlocked nodes.

- `lib/game/world/world_map_fino.dart`
  - Added `WorldMapFinoComponent`, a priority 2 component that draws Fino the
    fox with Canvas primitives.
  - Positions Fino above the first node using the same scaled reference system.

- `lib/game/world/lern_fuchs_world_game.dart`
  - Replaced the previous inline private map/background/node/player rendering
    with the new world map components.
  - Added the five requested nodes: Waldeingang, Lichtung, Alter Baum, Bruecke,
    and Waldsee.
  - Added `onNodeTapped(WorldQuestNode node)` as the tap hook for the quest
    overlay.

## Verification Notes

- Dart/Flutter formatting and analysis could not be run in this environment
  because no `dart` or `flutter` executable is available on PATH.
- The current working directory is an unpacked project folder, not a Git
  checkout; no `.git` directory is present.
