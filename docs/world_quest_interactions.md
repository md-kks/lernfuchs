# World Quest Interactions

World-Quests sollen Aufgaben primaer als Handlung in der Szene darstellen.
Flutter bleibt fuer App-Rahmen, Navigation, Elternbereich, Einstellungen und
allgemeine Overlays zustaendig. Die Weltkarte, Quest-Szenen und interaktiven
Lernhandlungen gehoeren in die Flame-/World-Schicht.

## Boundary

Jede Aufgabe bleibt fachlich ein `TaskModel` aus der Learning Engine:

- Topic, Schwierigkeit, korrekte Loesung und Bewertung kommen aus der Learning
  Engine.
- Lernfortschritt, Elo und Rewards werden weiterhin ueber die bestehenden
  Engine- und QuestRuntime-Pfade geschrieben.
- Die World-Schicht erhaelt daraus eine `WorldTaskSceneDefinition`, die Items,
  Zielzonen, Interaktionstyp, Prompt und die Rueckgabe an die Learning Engine
  beschreibt. `WorldQuestInteractionSpec` bleibt als schmaler Kompatibilitaets-
  View fuer bestehende Stellen erhalten.
- Flutter ist weiterhin App-Rahmen und Overlay-Schicht. Quest-Szenen und
  interaktive Lernhandlungen wandern schrittweise in die Flame-/World-Schicht;
  bestehende Flutter-Painter duerfen nur als Migrationsbruecke dienen.

## Interaction Types

Die Basisschicht kennt vier Typen:

| Typ | Bedeutung |
|---|---|
| `drag_to_target` | Objekte, Zeichen oder Buchstaben werden in Zielzonen gelegt. |
| `tap_select` | Das Kind tippt ein passendes Objekt direkt in der Szene an. |
| `sequence_build` | Steine, Tafeln oder Reihen werden in eine Struktur eingesetzt. |
| `trace_draw` | Zahlen, Buchstaben oder Formen werden direkt nachgefahren. |

Nicht migrierte Topics bekommen `fallback`. Dieser Pfad darf fuer freie
Uebungen, Uebergangsphasen und noch nicht migrierte Aufgabentypen weiter das
klassische Flutter-Aufgabenmuster bzw. die bestehenden
`ForestQuestOverlay`-Fallbacks verwenden.

Produktiv ueber `WorldQuestInteractionResolver` und `ForestQuestOverlay`
verdrahtet sind derzeit `drag_to_target` und `sequence_build`. `tap_select` und
`trace_draw` sind in Modell/Controller vorbereitet, aber noch nicht fuer ein
konkretes Topic produktiv migriert.

## Priorisierte Topics

| Topic | Szenenrolle | Interaktion |
|---|---|---|
| `zahlen_bis_10` | `apple_baskets` | `drag_to_target` |
| `anlaute` | `letter_signs` | `drag_to_target` |
| `zahlenmauern` | `number_wall` | `sequence_build` |
| `reimwoerter` | geplant: `rhyme_objects` | geplant: `tap_select` |
| `handschrift` | geplant: `trace_rune` | geplant: `trace_draw` |

Die Zuordnung liegt in
`lib/game/quest/world_quest_interaction.dart`. Das bestehende
`ForestQuestOverlay` nutzt diese Zuordnung bereits als Migrationsbruecke fuer
direkte Szeneninteraktion:

- `zahlen_bis_10`: Aepfel werden in einen Korb gezogen. Die Szene zaehlt die
  platzierten Aepfel und reicht die Menge an die Learning Engine zur Bewertung.
- `anlaute`: Buchstabensteine werden auf ein Wort-/Bildschild gezogen.
- `zahlenmauern`: Zahlensteine werden in den fehlenden Mauer-Slot gezogen.

`WorldTaskSceneController` kann Drag-, Tap-, Sequence- und Trace-Aktionen auf
fachliche Antworten abbilden. Produktiv genutzt werden aktuell Drag und
Sequence fuer die drei oben genannten Topics. Nicht migrierte Topics behalten
das klassische Exercise-/Answer-Widget-System bzw. bestehende
Quest-Overlay-Fallbacks.
