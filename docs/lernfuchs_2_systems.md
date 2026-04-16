# LernFuchs 2.0 Systems

Diese Datei dokumentiert die Story-, Session-, Meta-Progression-, Accessibility- und Zusatzmodi, die auf dem bestehenden Lernkern aufsetzen.

Wichtig: Die App verwendet weiterhin `shared_preferences` als Persistenzschicht. Einige Produktspezifikationen sprechen von Hive-Keys; im Code sind diese Keys unverändert als SharedPreferences-Keys umgesetzt.

## Grundregeln

- Elo-/Learning-Engine-Logik bleibt in `lib/core/learning` und wird von diesen Systemen nur angefragt oder gewichtet.
- TTS läuft weiter ausschließlich über `TtsService.speak()` und `TtsService.stop()`.
- Audio-SFX/Musik laufen über `AudioService`.
- Charakterzeichnungen werden wiederverwendet oder lokal ergänzt; die bestehenden Basisfunktionen werden nicht als Lernlogik-Abhängigkeit verwendet.
- Quest-Task-JSON bleibt unverändert. Neue Story-/Dialog-Assets liegen separat in `assets/quests`.

## Neue Assets

| Asset | Zweck |
|---|---|
| `assets/quests/quest_dialogues.json` | Intro-, Fortschritts-, Outro- und Feedbacktexte pro Station |
| `assets/quests/daily_task_narratives.json` | 30 datumsstabile Tagesaufgaben-Narrative |
| `assets/quests/expedition_stories.json` | Expeditionsrahmen pro Welt |
| `assets/audio/` | Platzhalter für Ambient, Musik und SFX |
| `assets/fonts/OpenDyslexic-Regular.otf` | Font-Familie für Legasthenie-Modus |
| `assets/fonts/OpenDyslexic-Bold.otf` | Bold-Schnitt für Legasthenie-Modus |

Hinweis: Die OpenDyslexic-Dateien sind aktuell build-sichere Platzhalter aus den vorhandenen Nunito-Fonts. Sie müssen durch die echten OpenDyslexic-OTF-Dateien ersetzt werden, sobald Asset-Download im Entwicklungsumfeld verfügbar ist.

## Services und Provider

| Service | Provider | Datei | Aufgabe |
|---|---|---|---|
| `DialogueService` | `dialogueServiceProvider` | `lib/services/dialogue_service.dart` | Lädt und cached `quest_dialogues.json` |
| `AudioService` | `audioServiceProvider` | `lib/services/audio_service.dart` | Ambient, Musik, SFX |
| `SeasonService` | `seasonServiceProvider` | `lib/services/season_service.dart` | Saison, Tageszeit, Feiertage |
| `StreakService` | Direkt erzeugt | `lib/services/streak_service.dart` | Tagesaufgaben-Streak und Baumhaus-Items |
| `FinoEvolutionService` | `finoEvolutionProvider` | `lib/services/fino_evolution_service.dart` | Fino-Stufe und visuelle Accessoires |
| `AccessibilityService` | `accessibilityProvider` | `lib/services/accessibility_service.dart` | Dyslexia-, Motor- und Calm-Mode |
| `SchoolModeService` | `schoolModeProvider` | `lib/services/school_mode_service.dart` | Schulmodus-Aktivierung und Ablaufdatum |

## World Map

Zentrale Dateien:

- `lib/features/home/world_map_screen.dart`
- `lib/game/world/lern_fuchs_world_game.dart`
- `lib/game/world/world_map_node_component.dart`
- `lib/game/world/world_map_background.dart`
- `lib/game/world/world_map_story_components.dart`

Die Weltkarte rendert fünf Node-Zustände:

| Zustand | Bedeutung |
|---|---|
| `current` | Fino steht hier; Quest kann gestartet werden |
| `completed` | Station abgeschlossen; Kristall-Gem sichtbar |
| `nextAvailable` | frisch freigeschaltet; grüner Glow |
| `lockedNear` | nächste mysteriöse Station mit `???` |
| `lockedFar` | ferne, fast unsichtbare Station |
| `expedition` | Sonderknoten für Wiederholungs-Expeditionen |

Story-Popups und Ova-Bubbles werden als Flame-Komponenten auf dem Canvas gezeichnet. Sie sprechen Storytexte über `TtsService.speak()`.

Die Weltkarte erhält zur Laufzeit:

- `SeasonContext` über `LernFuchsWorldGame.updateSeason()`
- `FinoStyle` über `updateFinoStyle()`
- `AccessibilitySettings` über `updateAccessibility()`

## Quest Overlay

Zentrale Datei: `lib/features/quest/forest_quest_overlay.dart`.

Das Overlay ist für die Quest-Sitzung zuständig:

- 6 Aufgaben pro Kampagnenstation
- Aufgaben werden interleaved
- Meilensteine bei Aufgabe 2, 4 und 6
- Outro-Animation vor Rückkehr zur Karte
- Safe-Area-Handling über `bottomInset`
- Antwort-Elemente sind in die Szene integriert
- TTS-Reihenfolge nach Intro: Hint, Frage, Zielwort
- Feedback-Sätze kommen aus `StationDialogue`

Accessibility-Effekte:

- Dyslexia: Canvas-Text nutzt `OpenDyslexic` und zusätzliche Laufweite.
- Motor: Antwortsteine, Buttons und relevante Tap-Flächen werden vergrößert.
- Calm: reduzierte Bewegungen, reduzierte Feedback-Animationen und keine Gate-Vibration.

School-Mode-Effekt:

- Beim nächsten Task wird aktiv nach einem Topic gesucht, das in `school_mode_competencies` liegt.
- Wenn kein passender Task in der Session vorhanden ist, bleibt die normale Interleaving-Reihenfolge erhalten.

## Quest Intro Screen

Datei: `lib/features/quest/quest_intro_screen.dart`.

Der Screen spielt Dialogframes aus `quest_dialogues.json` ab:

- Vollbild-Canvas
- Hintergrund passend zur Station
- Sprecher-Icon und Holz-Sprechblase
- Tap = nächster Frame
- Long-Press = Cutscene überspringen
- TTS pro Frame über `TtsService.speak()`

## Daily Tasks

Dateien:

- `lib/features/daily/daily_task_screen.dart`
- `lib/features/daily/daily_task_generator.dart`
- `assets/quests/daily_task_narratives.json`

Tagesaufgaben bestehen aus:

1. Intro-Canvas mit datumsstabilem Narrativ
2. Drei Aufgaben
3. Abschluss-Canvas mit Streak und optionalem Baumhaus-Item

Der Generator bewertet Kompetenzen nach Schwäche und Vernachlässigung. Wenn Schulmodus aktiv ist, werden aktive Schulkompetenzen mit Faktor `2.5` gewichtet.

## Expeditions

Dateien:

- `lib/features/expedition/expedition_screen.dart`
- `lib/features/expedition/expedition_generator.dart`
- `assets/quests/expedition_stories.json`

Expeditionen erscheinen nach Weltabschluss und Cooldown als Campfire-Knoten auf der Weltkarte. Eine Expedition umfasst:

- Expeditionsintro
- 3 Stationen
- 4 Aufgaben je Station
- Abschlussbild
- Persistenz der gespielten Story
- Baumhaus-Belohnung `baumhaus_kristall_blau` für die erste Expedition

## Home Screen

Datei: `lib/features/home/home_screen.dart`.

Der HomeScreen ist der verpflichtende Einstieg der App:

- zentrale Hauptmenü-Fläche mit `Freies Lernen`, `Abenteuer`, `Tagesaufgabe` und `Baumhaus`
- Abenteuer-Kachel bleibt bei deaktivierter Weltkarte sichtbar und markiert `Bald verfügbar`
- `Mehr`-Menü mit Abenteuer-Intro, Einstufung und Elternbereich
- Expeditionshinweis
- Streak-Anzeige

Wenn `game_fully_completed == true`, wird ein permanenter Abschlusszustand angezeigt:

- Ova-Abschlussbotschaft
- goldene Sparkle-Überlagerung
- Kartenbutton-Text `Erinnerungen`

## Onboarding und Placement

Dateien:

- `lib/features/onboarding/parent_onboarding_screen.dart`
- `lib/features/onboarding/child_onboarding_screen.dart`
- `lib/features/onboarding/placement_screen.dart`
- `lib/features/onboarding/placement_tasks.dart`

Startup-Routing:

1. App-Start landet immer auf `/home`.
2. `/onboarding/child` bleibt als optionales Abenteuer-Intro erreichbar.
3. `/onboarding/placement` bleibt als optionaler Einstufungstest erreichbar.
4. `/onboarding/parent` bleibt als optionale Eltern-PIN-Einrichtung erreichbar.

Placement initialisiert Kompetenzwerte in SharedPreferences unter `child_elo_<competencyId>` und speichert zusätzlich `placement_elo_results`.

## Audio

Datei: `lib/services/audio_service.dart`.

`AudioService` nutzt drei Player:

- `_ambientPlayer` für Welt-Ambient-Loops
- `_musicPlayer` für Musik-Loops
- `_sfxPlayer` für One-Shot-SFX

Integration:

- Weltkarte: Ambient + Main Theme
- Quest: Quest-Musik, Correct/Wrong-SFX, Crystal/Gate/Outro
- Intro: Ova-Appear-SFX
- Daily Completion: Streak-SFX
- Map Unlock/Walk: Node-Unlock und Fino-Hop

Die Audio-Dateien sind aktuell stille Platzhalter.

## Seasonal Visuals

Datei: `lib/services/season_service.dart`, Rendering in `world_map_background.dart` und Quest-Paintern.

`SeasonService.context` gibt `null` zurück, wenn `seasonal_enabled == false`.

Unterstützt:

- Frühling: Blüten und Schmetterlinge
- Herbst: Blätter
- Winter: Schnee und kühlere Stimmung
- Abend/Nacht: Dimmung und Fireflies
- Weihnachten, Halloween, Geburtstag, Neujahr

## Fino Evolution

Datei: `lib/services/fino_evolution_service.dart`.

Die Stufe ergibt sich aus abgeschlossenen Welten:

| Stufe | Effekt |
|---|---|
| 0 | Startzustand |
| 1 | Kristall-Anhänger |
| 2 | Mehr Kristalle |
| 3 | Augen-Glow |
| 4 | goldene Schwanzspitze und Buch |

`WorldMapScreen._completeWorldIfNeeded()` ruft `checkAndAdvance()` nach Weltabschluss auf.

## Baumhaus

Dateien:

- `lib/features/baumhaus/baumhaus_screen.dart`
- `lib/features/baumhaus/baumhaus_painter.dart`

Das Baumhaus zeigt:

- Baumhaus-Stufe `0..4`
- aktuelle Fino-Evolution
- verdiente Items aus `baumhaus_items`

Aktuelle Items:

| Item-ID | Name |
|---|---|
| `baumhaus_bank` | Gemütliche Bank |
| `baumhaus_laterne` | Leuchtende Laterne |
| `baumhaus_goldener_schwanz` | Goldener Schwanz für Fino |
| `baumhaus_kristall_blau` | Blauer Kristall |

## Breathing Pause

Datei: `lib/features/breathing/breathing_screen.dart`.

Start:

- kleines Leaf-Icon im Quest Overlay unten links
- nur sichtbar, wenn gerade aktiv auf Eingabe gewartet wird

Ablauf:

- 4 Atemzyklen zu je 12 Sekunden
- Einatmen, Halten, Ausatmen
- Tap überspringt zur Antwortauswahl
- `Ja, weiter!` kehrt zur Quest zurück
- `Heute Pause` beendet die Quest und kehrt zur Karte zurück

TTS nutzt die vorhandenen `speak()`-Aufrufe. Rate/Pitch werden nicht verändert, weil `TtsService` diese API aktuell nicht öffentlich anbietet.

## School Mode

Dateien:

- `lib/services/school_mode_service.dart`
- `lib/data/school_topics.dart`
- `lib/features/parent/parent_dashboard_screen.dart`

Der Elternbereich zeigt Themen nach Klassenstufe. Bis zu drei Topics können aktiviert werden. Die Aktivierung läuft 14 Tage.

Speicher:

- `school_mode_competencies`
- `school_mode_expires`

Effekt:

- DailyTaskGenerator multipliziert Scores aktiver Kompetenzen mit `2.5`.
- ForestQuestOverlay bevorzugt in der Session vorhandene aktive Schulkompetenzen.
- Andere Aufgaben bleiben möglich.

## Accessibility Modes

Dateien:

- `lib/services/accessibility_service.dart`
- `forest_quest_overlay.dart`
- `world_map_node_component.dart`
- `world_map_story_components.dart`
- `parent_dashboard_screen.dart`

Persistenz:

- `dyslexia_mode`
- `motor_mode`
- `calm_mode`

Effekte:

- Dyslexia: `OpenDyslexic`, mehr Letter-Spacing
- Motor: größere Antwort- und Node-Tap-Ziele
- Calm: weniger Animation, halbe Glow-Opacity, keine Ova-Bubble-Flaps

## Grand Finale

Datei: `lib/features/quest/finale_cutscene_screen.dart`.

Trigger:

- `WorldMapScreen._scheduleFinaleIfReady()`
- alle `world_<n>_completed_at` Keys für 1 bis 4 müssen gesetzt sein
- `game_fully_completed` darf noch nicht `true` sein

Ablauf:

1. Welt-4-Abschluss
2. Das Große Buch erwacht
3. Nebelschatten löst sich auf
4. Alle Charaktere vereint
5. Ende und Ausblick

Nach Abschluss navigiert der Flow zurück zum HomeScreen. Dort wird der finale Home-Zustand angezeigt.

## Persistenz-Keys

Neue Keys, die nicht Teil der ursprünglichen AppSettings-JSON-Struktur sind:

| Key | Typ | Zweck |
|---|---|---|
| `placement_completed` | bool | Placement abgeschlossen |
| `placement_elo_results` | JSON Map | initialisierte Kompetenzwerte |
| `parent_pin` | String | PIN aus Parent-Onboarding |
| `child_birthdate` | String | optionales Datum `YYYY-MM-DD` |
| `daily_task_last_played` | String | Tagesaufgabe erledigt am |
| `daily_streak_count` | int | aktueller Streak |
| `daily_streak_last_day` | String | letzter Streak-Tag |
| `baumhaus_items` | List<String> | freigeschaltete Baumhaus-Items |
| `baumhaus_stage` | int | Baumhaus-Ausbaustufe |
| `fino_evolution_stage` | int | Fino-Entwicklungsstufe |
| `music_enabled` | bool | Musik an/aus |
| `sfx_enabled` | bool | SFX an/aus |
| `seasonal_enabled` | bool | saisonale Dekorationen |
| `dyslexia_mode` | bool | Legasthenie-Schrift |
| `motor_mode` | bool | größere Tipp-Ziele |
| `calm_mode` | bool | weniger Animation |
| `school_mode_competencies` | List<String> | aktive Schulmodus-Kompetenzen |
| `school_mode_expires` | String | Ablaufdatum Schulmodus |
| `game_fully_completed` | bool | Kampagne vollständig abgeschlossen |
| `world_<n>_completed_at` | String | Weltabschlusszeit |
| `child_elo_<competencyId>` | double | Placement-Startwert pro Kompetenz |

## Aktuelle Einschränkungen

- Flutter/Dart-Tooling war in der aktuellen Shell nicht verfügbar; Format/Analyze konnten dort nicht ausgeführt werden.
- OpenDyslexic-Fonts sind Platzhalter und sollten durch echte OpenDyslexic-Assets ersetzt werden.
- Audio-Dateien sind stille Platzhalter.
- Finale-Trigger für Welten 2 bis 4 wird erst praktisch erreicht, wenn diese Welten vollständig in den Content integriert sind.
