# Documentation Design — LernFuchs

**Datum:** 2026-04-12
**Ziel:** Alle fehlenden Docs für das LernFuchs-Projekt erstellen.
**Zielgruppe:** Coding Agents (primär) + neue Entwickler (sekundär).
**Stil:** Präzise, keine vagen Beschreibungen, maschinenlesbare Tabellen, klare Struktur.
**Ansatz:** Parallel (alle Source-Dateien zuerst lesen, dann alle Docs in einem Schritt schreiben).

---

## Dokument 1: `README.md` (Überschreiben)

**Datei:** `/README.md`
**Zweck:** Projekteinstieg — was ist LernFuchs, wie richtet man es ein, Projektstruktur.

**Inhalt:**
- Kurzbeschreibung: Flutter-Lernapp für Grundschulkinder (Mathe & Deutsch, Klasse 1–4, Bundesland-Lehrplan)
- Tech-Stack: Flutter 3, Riverpod, go_router, Flame, flutter_tts, shared_preferences
- Setup: `flutter pub get`, `flutter run`
- Projektstruktur-Tabelle: `lib/core/`, `lib/features/`, `lib/game/`, `lib/shared/`, `lib/app/`, `assets/`
- Docs-Verzeichnis-Übersicht mit Links zu allen `docs/*.md`

---

## Dokument 2: `docs/engine.md` (Neu)

**Datei:** `/docs/engine.md`
**Zweck:** Vollständige Referenz für `lib/core/engine/`.

**Inhalt:**
- `TaskTemplate` — abstraktes Interface: Felder (`id`, `subject`, `grade`, `topic`, `minDifficulty`, `maxDifficulty`), abstrakte Methoden (`generate`, `evaluate`, `displayName`), Hilfsmethode `makeTask`
- `TaskGenerator` — Singleton-Registry, Key-Schema `"<subject.id>_<grade>_<topic>"`, alle registrierten Templates als vollständige Liste (nach Fach+Klasse gruppiert), API (`generateSession`, `templatesFor`, `template`), Erweiterungsanleitung (3 Schritte)
- `Evaluator` — Dispatch-Tabelle: welcher TaskType → welche Methode, Toleranzen (`±0.001` für Double, case-insensitive Strings), wann Templates selbst evaluieren
- `DifficultyEngine` — Algorithmus (Fenster 5, Schwellen 50%/90%, Grenzen 1–5), `initialDifficulty`-Formel, `nextDifficulty`-API
- `Curriculum` — alle 16 Bundesländer + AT + CH (kFederalStates), bundeslandspezifische Varianten (Kursivschrift, Einmaleins), vollständige Themen-Listen für Mathe/Deutsch Kl.1–4

---

## Dokument 3: `docs/learning_engine.md` (Neu)

**Datei:** `/docs/learning_engine.md`
**Zweck:** Vollständige Referenz für `lib/core/learning/`.

**Inhalt:**
- `LearningEngine` — Interface-Methoden-Tabelle mit Signaturen und Kurzbeschreibung
- `DefaultLearningEngine` — konkrete Implementierung, Abhängigkeiten (StorageService)
- `LearningRequest` — alle Felder mit Typ und Default
- `LearningSession` — Felder, `isEmpty`-Guard
- `LearningSessionMode` — alle 4 Modi, Verhalten pro Modus (freePractice → ResultScreen, questSingle/questMiniSeries/dailyPath → Callback)
- `LearningChallengeSession` (Widget) — Parameter, Session-Ablauf (initState → loadTasks → TTS → submitAnswer → nextTask → onCompleted), Fortschritts-Recording-Flag
- `LearningChallengeResult` — Felder, `successful`-Getter
- Zusammenspiel mit QuestRuntime: wer ruft was wann auf

---

## Dokument 4: `docs/storage_and_persistence.md` (Neu)

**Datei:** `/docs/storage_and_persistence.md`
**Zweck:** Zentrales Nachschlagewerk für alle Persistenzschichten.

**Inhalt:**
- Übersicht: vollständig offline, SharedPreferences als einziger Layer
- Vollständige Key-Tabelle aller SharedPreferences-Keys (inkl. game/quest/inventory Keys aus den anderen Stores):
  - `lf_settings` → AppSettings JSON
  - `lf_profiles` → List<ChildProfile> JSON
  - `lf_progress_<profileId>-<subject>-<grade>-<topic>` → TopicProgress JSON
  - `lf_quest_status_<profileId>` → QuestStatus JSON
  - `lf_inventory_<profileId>` → InventoryState JSON
  - `lf_daily_path_<profileId>-<yyyy-mm-dd>` → DailyPathProgress JSON
- JSON-Schemas für alle Typen: AppSettings, ChildProfile, TopicProgress
- `StorageService` API — Singleton-Init, alle Methoden
- Riverpod-Provider-Tabelle: Provider-Name → Typ → Beschreibung → Schreibmethode
- Schreib-/Lesepfade: wer schreibt, wer liest

---

## Dokument 5: `docs/exercise_widgets.md` (Neu)

**Datei:** `/docs/exercise_widgets.md`
**Zweck:** Vollständige Übersicht aller Aufgaben-Widgets und Widget-Dispatch-Logik.

**Inhalt:**
- Widget-Dispatch-Tabelle: TaskType + Topic/Metadata-Bedingung → Widget-Klasse → Antwortformat
- Vollständige Widget-Liste (14 Widgets) mit Dateiort und Zweck:
  - FreeInputWidget, MultipleChoiceWidget, OrderingWidget, LetterOrderingWidget
  - PatternWidget, BarChartWidget, ReadingTextWidget, SyllableTapWidget
  - DotCountWidget, NumberWallWidget, WrittenCalculationWidget
  - ClockWidget (interactive/uhrzeit), MoneyWidget (interactive/geld), FractionWidget (interactive/brueche)
  - DictationWidget, HandwritingWidget
- `LearningAnswerWidget` — zentraler Dispatch-Punkt, exakte Dispatch-Logik aus dem Code
- Widget-Interface: alle Widgets nehmen `task` + `onChanged`, kein Absenden-Button im Widget
- Phase-4-Widgets (nicht implementiert): dragDrop, matching → HandwritingWidget ist Placeholder

---

## Dokument 6: `docs/feature_flags.md` (Neu)

**Datei:** `/docs/feature_flags.md`
**Zweck:** Übersicht aller Feature Flags und ihrer Auswirkungen.

**Inhalt:**
- `FeatureFlags.enableGameWorld` — Default `false`, Datei `lib/app/feature_flags.dart`
- Status: noch nicht in Verhaltenslogik verdrahtet (Placeholder für zukünftige Nutzung)
- Wo es geprüft werden soll (gemäß refactor_map.md)
- Anleitung: wie man ein neues Flag hinzufügt

---

## Nicht abgedeckt (bewusst ausgelassen)

- Code-Kommentare / Inline-Docstrings — bereits gut im Code vorhanden
- Template-Implementierungsdetails einzelner Templates (zu granular, aus Code ablesbar)
- Asset-Inhalte (dialogue/quest JSON-Beispiele bereits in `docs/dialogue_schema.md` und `docs/quest_runtime.md`)
