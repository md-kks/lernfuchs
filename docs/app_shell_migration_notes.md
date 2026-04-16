# App Shell Migration Notes

## New Route Tree

- `/home`: central hub entry screen (Dashboard). All sessions start here.
- `/home/freies-ueben`: existing class selection and free-practice learning flow.
- `/home/subject/:grade/:subject`: existing subject/topic overview route, kept
  for compatibility.
- `/home/subject/:grade/:subject/exercise/:topic`: existing exercise route,
  kept for compatibility.
- `/home/baumhaus`: hub screen for meta-progression, integrated with `InventoryStore`.
- `/home/tagespfad`: placeholder shell route.
- `/home/elternbereich`: placeholder shell route.
- `/onboarding/child`: optionales Abenteuer-Intro, manuell aus dem HomeScreen erreichbar.
- `/onboarding/placement`: optionaler Einstufungstest, manuell aus dem HomeScreen erreichbar.
- `/onboarding/parent`: optionale Eltern-PIN-Einrichtung, manuell erreichbar.
- `/parent`: existing parent dashboard, unchanged.

## Navigation Notes

- The app always lands on `/home` (HomeScreen). There is no global redirect
  back to onboarding, parent PIN setup, or placement.
- The world map is opened via an explicit user action from the Dashboard. The
  HomeScreen adventure entry is clickable for the current testable world-map
  flow and is not marked as coming soon.
- Quests are started from the world map, launching `ForestQuestOverlay` and `QuestRewardOverlay` within the same route context.
- Keep `/home/subject/...` deep links working until a dedicated migration plan
  moves exercise entry points into a game-world route.
- Keep profile selection state backed by `AppSettings.activeProfileId`; this is
  now the hub-level last-used profile.
- Decide whether `/home/elternbereich` should become a wrapper around the
  existing `/parent` dashboard or stay a separate future shell surface.

## Flame / Flutter Boundary

- Flame owns only the world-map canvas in `LernFuchsWorldGame`: placeholder map
  background, player marker, and tappable quest node hit targets.
- Flutter owns app shell, routing, app bar, profile state, overlays, and any
  future learning/session UI.
- Quest node taps cross the boundary through a `ValueChanged<WorldQuestNode>`
  callback. The current hook opens a Flutter placeholder overlay.
- Future learning integration should translate a selected `WorldQuestNode` into
  a `LearningRequest` or route action outside the Flame component tree.
