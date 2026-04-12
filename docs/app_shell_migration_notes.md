# App Shell Migration Notes

## New Route Tree

- `/home`: new hub entry screen.
- `/home/freies-ueben`: existing class selection and free-practice learning flow.
- `/home/subject/:grade/:subject`: existing subject/topic overview route, kept
  for compatibility.
- `/home/subject/:grade/:subject/exercise/:topic`: existing exercise route,
  kept for compatibility.
- `/home/baumhaus`: placeholder shell route.
- `/home/weltkarte`: hybrid Flutter + Flame world-map route.
- `/home/tagespfad`: placeholder shell route.
- `/home/elternbereich`: placeholder shell route.
- `/parent`: existing parent dashboard, unchanged.

## Next Phase Notes

- Replace placeholder shell routes one at a time behind feature flags.
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
