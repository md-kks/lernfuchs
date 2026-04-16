# Documentation Implementation Plan

> **Hinweis zum Status:** Diese Datei ist ein historischer/generierter
> Planungsstand. Sie ist nicht die maßgebliche Quelle für die aktuelle
> Klasse-1-/World-1-Kapitelstruktur. Für die kanonische Kapitel- und
> World-1-Planung gelten insbesondere `docs/world1_vertical_slice.md` sowie die
> aktuellen Hauptkonzeptdokumente zu LernFuchs / World 1 / Klasse 1. Einzelne
> Listen und Bestände in dieser Datei können weiterhin nützlich sein, dürfen
> aber nicht als alleinige Wahrheit für die aktuelle Kapitelstruktur gelesen
> werden.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Alle 6 fehlenden Dokumentationsdateien schreiben, die das Projekt für Coding Agents und neue Entwickler verständlich machen.

**Architecture:** Jede Datei wird aus dem tatsächlichen Quellcode abgeleitet (keine Annahmen). Die Docs sind vollständig standalone — kein Dokument setzt das Lesen eines anderen voraus. Alle Tabellen und Codebeispiele sind maschinenlesbar formatiert.

**Tech Stack:** Markdown, Flutter/Dart (Quellensprache), SharedPreferences, Riverpod, Flame

---

## File Map

| Datei | Aktion | Verantwortung |
|---|---|---|
| `README.md` | Überschreiben | Projekteinstieg, Setup, Struktur |
| `docs/engine.md` | Neu erstellen | TaskTemplate, TaskGenerator, Evaluator, DifficultyEngine, Curriculum |
| `docs/learning_engine.md` | Neu erstellen | LearningEngine-Interface, DefaultLearningEngine, Session-Ablauf, Modi |
| `docs/storage_and_persistence.md` | Neu erstellen | Alle SharedPreferences-Keys, Riverpod-Provider, Lese-/Schreibpfade |
| `docs/exercise_widgets.md` | Neu erstellen | Alle 16 Widgets, Dispatch-Logik, Widget-Interface |
| `docs/feature_flags.md` | Neu erstellen | Alle Flags, Defaults, Erweiterungsanleitung |

---

### Task 1: README.md schreiben

**Files:**
- Modify: `README.md`

- [ ] **Schritt 1: README.md überschreiben**

Inhalt:

```markdown
# LernFuchs

Offline-Lernapp für Grundschulkinder (Klasse 1–4) in Mathe und Deutsch.
Bundesland-spezifischer Lehrplan, adaptiver Schwierigkeitsgrad, Spielwelt (Flutter + Flame).

## Tech-Stack

| Paket | Zweck |
|---|---|
| Flutter 3 | UI-Framework |
| flutter_riverpod ^2.6.1 | State Management |
| go_router ^14.8.1 | Navigation |
| shared_preferences ^2.5.3 | Lokale Persistenz (kein Backend) |
| flutter_tts ^4.2.0 | Text-to-Speech |
| flame ^1.37.0 | Spielwelt-Karte |
| yaml ^3.1.3 | Quest/Dialogue-Assets laden |

## Setup

```bash
flutter pub get
flutter run
```

Kein Backend, keine Umgebungsvariablen, keine API-Keys nötig.

## Projektstruktur

```
lib/
├── app/                    # Router, Theme, FeatureFlags
├── core/
│   ├── engine/             # TaskTemplate, TaskGenerator, Evaluator, DifficultyEngine, Curriculum
│   ├── learning/           # LearningEngine-Interface, DefaultLearningEngine, DailyPath
│   ├── models/             # TaskModel, TopicProgress, ChildProfile, AppSettings, Subject
│   └── services/           # StorageService, TtsService, SoundService, Riverpod-Provider
├── features/
│   ├── exercise/           # LearningChallengeSession, alle Aufgaben-Widgets, ResultScreen
│   ├── home/               # HomeScreen, WorldMapScreen, BaumbausScreen, DailyPathScreen
│   ├── parent/             # ParentDashboardScreen
│   ├── profile/            # ProfileScreen
│   ├── progress/           # ProgressScreen
│   ├── settings/           # SettingsScreen, OnboardingScreen
│   ├── subject_overview/   # SubjectOverviewScreen
│   └── worksheet/          # WorksheetScreen
├── game/
│   ├── dialogue/           # DialogueDefinition, HintDefinition, DialogueOverlay
│   ├── quest/              # QuestDefinition, QuestRuntime, QuestStatusStore
│   ├── reward/             # InventoryState, InventoryStore, BaumbausUpgrade
│   └── world/              # LernFuchsWorldGame (Flame), WorldQuestNode
└── shared/
    ├── constants/          # AppColors, AppTextStyles
    └── widgets/            # StarRating, TaskCard, FeedbackOverlay, ProgressBar, RoundedButton

assets/
├── audio/                  # Feedback-Sounds
├── dialogue/               # Dialogue- und Hint-JSON (z.B. ova_dialogues.json)
├── fonts/                  # Nunito Regular/Bold/ExtraBold
├── images/                 # Grafiken
└── quests/                 # Quest-Definitionen (z.B. sample_quests.json)
```

## Dokumentation

| Dokument | Inhalt |
|---|---|
| [docs/engine.md](docs/engine.md) | TaskTemplate, TaskGenerator, Evaluator, DifficultyEngine, Curriculum |
| [docs/learning_engine.md](docs/learning_engine.md) | LearningEngine, Session-Ablauf, LearningSessionMode |
| [docs/storage_and_persistence.md](docs/storage_and_persistence.md) | SharedPreferences-Keys, Riverpod-Provider, Datenmodelle |
| [docs/exercise_widgets.md](docs/exercise_widgets.md) | Alle Aufgaben-Widgets und Dispatch-Logik |
| [docs/feature_flags.md](docs/feature_flags.md) | Feature Flags und Erweiterungsanleitung |
| [docs/refactor_map.md](docs/refactor_map.md) | Architekturübersicht, Migrationsziel Flutter+Flame |
| [docs/app_shell_migration_notes.md](docs/app_shell_migration_notes.md) | Routenbaum, Flame/Flutter-Grenze |
| [docs/quest_runtime.md](docs/quest_runtime.md) | Quest-Schema, Laufzeitverhalten |
| [docs/dialogue_schema.md](docs/dialogue_schema.md) | Dialogue- und Hint-JSON-Format |
| [docs/meta_progression.md](docs/meta_progression.md) | Inventar, Baumhaus-Upgrades |
| [docs/daily_path.md](docs/daily_path.md) | Tages-Pfad-Logik |
| [docs/world1_vertical_slice.md](docs/world1_vertical_slice.md) | World 1 Playable Slice |
```

- [ ] **Schritt 2: Prüfen**

Sicherstellen dass alle Dateinamen unter `lib/` korrekt sind (entsprechen dem tatsächlichen Verzeichnis).

- [ ] **Schritt 3: Commit**

```bash
git add README.md
git commit -m "docs: README.md mit Projektbeschreibung, Setup und Struktur"
```

---

### Task 2: docs/engine.md schreiben

**Files:**
- Create: `docs/engine.md`
- Source: `lib/core/engine/task_template.dart`, `lib/core/engine/task_generator.dart`, `lib/core/engine/evaluator.dart`, `lib/core/engine/difficulty.dart`, `lib/core/engine/curriculum.dart`

- [ ] **Schritt 1: docs/engine.md erstellen**

```markdown
# Engine — TaskTemplate, TaskGenerator, Evaluator, DifficultyEngine, Curriculum

Alle Dateien liegen in `lib/core/engine/`.

---

## TaskTemplate

**Datei:** `lib/core/engine/task_template.dart`

Abstrakte Basisklasse für alle Aufgaben-Templates. Jede Unterklasse repräsentiert
einen Aufgabentyp und kann beliebig viele Aufgaben desselben Typs algorithmisch erzeugen.

### Felder

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | `String` | Eindeutiger Bezeichner, identisch mit `topic` |
| `subject` | `Subject` | Zugehöriges Fach (`Subject.math` oder `Subject.german`) |
| `grade` | `int` | Klassenstufe 1–4 |
| `topic` | `String` | Themenbezeichner, z.B. `"addition_bis_20"` — wird als URL-Segment und Registry-Schlüssel verwendet |
| `minDifficulty` | `int` | Minimaler Schwierigkeitsgrad (Standard: 1) |
| `maxDifficulty` | `int` | Maximaler Schwierigkeitsgrad (Standard: 5) |

### Abstrakte Methoden (müssen implementiert werden)

| Methode | Signatur | Beschreibung |
|---|---|---|
| `generate` | `TaskModel generate(int difficulty, Random rng)` | Erzeugt eine neue algorithmisch zufällige Aufgabe |
| `evaluate` | `bool evaluate(TaskModel task, dynamic userAnswer)` | Bewertet eine Kinderantwort; aufgabenspezifische Logik (Groß-/Kleinschreibung, Trimmen) |
| `displayName` | `String get displayName` | Menschenlesbarer Name für Fortschrittsanzeige und Auswahl-UI |

### Hilfsmethode `makeTask`

Alle Unterklassen nutzen `makeTask` anstatt `TaskModel(...)` direkt — stellt sicher, dass
`subject`, `grade` und `topic` immer korrekt gesetzt sind.

```dart
TaskModel makeTask({
  required Random rng,
  required int difficulty,
  required String question,
  required dynamic correctAnswer,
  required TaskType type,
  Map<String, dynamic> metadata = const {},
})
```

### Minimales Template-Beispiel

```dart
class AdditionTemplate extends TaskTemplate {
  const AdditionTemplate({required int grade})
    : super(
        id: 'addition_bis_10',
        subject: Subject.math,
        grade: grade,
        topic: 'addition_bis_10',
      );

  @override
  String get displayName => 'Addition bis 10';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final a = rng.nextInt(5) + 1;
    final b = rng.nextInt(5) + 1;
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: '$a + $b = ?',
      correctAnswer: a + b,
      type: TaskType.freeInput,
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) =>
      Evaluator.evaluateFreeInput(task, userAnswer);
}
```

---

## TaskGenerator

**Datei:** `lib/core/engine/task_generator.dart`

Zentrales Template-Register und Session-Generator. Hält alle `TaskTemplate`-Instanzen
in einer Flat-Map mit dem Schlüssel `"<subject.id>_<grade>_<topic>"`.

### API

| Methode | Signatur | Beschreibung |
|---|---|---|
| `generateSession` | `List<TaskModel> generateSession({required Subject subject, required int grade, required String topic, required int difficulty, int count = 10, int? seed})` | Generiert eine Session. Wirft `ArgumentError` wenn kein Template gefunden. |
| `templatesFor` | `List<TaskTemplate> templatesFor(Subject subject, int grade)` | Alle Templates für Fach+Klasse — genutzt von `SubjectOverviewScreen` |
| `template` | `TaskTemplate? template(Subject subject, int grade, String topic)` | Einzelnes Template — primär für Unit-Tests |

**Key-Schema:** `"${subject.id}_${grade}_${topic}"` — z.B. `"math_2_uhrzeit"`, `"german_3_zeitformen"`

**Seed:** Bei gleichem `seed` sind alle Aufgaben einer Session reproduzierbar (Debugging, Worksheets).

### Registrierte Templates

#### Mathe Klasse 1
| Topic-Key | Template-Klasse |
|---|---|
| `math_1_zahlen_bis_10` | `CountDotsTemplate`, `NumberWritingTemplate` |
| `math_1_zahlen_bis_20` | `CountDotsTemplate`, `NumberWritingTemplate` |
| `math_1_addition_bis_10` | `AdditionTemplate(grade: 1)` |
| `math_1_subtraktion_bis_10` | `SubtractionTemplate(grade: 1)` |
| `math_1_groesser_kleiner` | `ComparisonTemplate` |
| `math_1_zahlenreihen` | `NumberSequenceTemplate` |
| `math_1_zahlenmauern` | `NumberWallTemplate(grade: 1)` |
| `math_1_formen` | `ShapeRecognitionTemplate` |
| `math_1_muster` | `PatternContinuationTemplate` |

#### Mathe Klasse 2
| Topic-Key | Template-Klasse |
|---|---|
| `math_2_addition_bis_100` | `AdditionTemplate(grade: 2)` |
| `math_2_subtraktion_bis_100` | `SubtractionTemplate(grade: 2)` |
| `math_2_einmaleins` | `TimesTableTemplate` |
| `math_2_uhrzeit` | `ClockTemplate` |
| `math_2_geld` | `MoneyTemplate` |
| `math_2_zahlenmauern` | `NumberWallTemplate(grade: 2)` |
| `math_2_rechenketten` | `CalculationChainTemplate` |
| `math_2_textaufgaben` | `WordProblemGrade2Template` |

#### Mathe Klasse 3
| Topic-Key | Template-Klasse |
|---|---|
| `math_3_schriftliche_addition` | `WrittenAdditionTemplate` |
| `math_3_schriftliche_subtraktion` | `WrittenSubtractionTemplate` |
| `math_3_multiplikation` | `SemiWrittenMultiplicationTemplate` |
| `math_3_division_mit_rest` | `DivisionWithRemainderTemplate` |
| `math_3_groessen_umrechnen` | `UnitConversionTemplate` |
| `math_3_geometrie` | `GeometryTemplate` |
| `math_3_textaufgaben_3` | `WordProblemGrade3Template` |

#### Mathe Klasse 4
| Topic-Key | Template-Klasse |
|---|---|
| `math_4_schriftliche_multiplikation` | `WrittenMultiplicationTemplate` |
| `math_4_schriftliche_division` | `WrittenDivisionTemplate` |
| `math_4_brueche` | `FractionTemplate` |
| `math_4_dezimalzahlen` | `DecimalNumberTemplate` |
| `math_4_diagramme` | `DiagramReadingTemplate` |
| `math_4_grosse_zahlen` | `LargeNumbersTemplate` |
| `math_4_sachaufgaben_4` | `WordProblemGrade4Template` |

#### Deutsch Klasse 1
| Topic-Key | Template-Klasse |
|---|---|
| `german_1_buchstaben` | `LetterRecognitionTemplate` |
| `german_1_anlaute` | `InitialSoundTemplate` |
| `german_1_silben` | `SyllableCountTemplate` |
| `german_1_reimwoerter` | `RhymeTemplate` |
| `german_1_lueckenwoerter` | `MissingLetterTemplate` |
| `german_1_buchstaben_salat` | `AnagramTemplate` |
| `german_1_handschrift` | `HandwritingTemplate` |

#### Deutsch Klasse 2
| Topic-Key | Template-Klasse |
|---|---|
| `german_2_artikel` | `ArticleTemplate` |
| `german_2_einzahl_mehrzahl` | `PluralTemplate` |
| `german_2_abc_sortieren` | `AlphabetSortTemplate` |
| `german_2_wortarten` | `WordTypeTemplate` |
| `german_2_rechtschreibung_ie_ei` | `IeEiTemplate` |
| `german_2_saetze_bilden` | `SentenceFormationTemplate` |
| `german_2_lesetext` | `ReadingComprehensionTemplate` |

#### Deutsch Klasse 3
| Topic-Key | Template-Klasse |
|---|---|
| `german_3_zeitformen` | `VerbTenseTemplate` |
| `german_3_wortfamilien` | `WordFamilyTemplate` |
| `german_3_zusammengesetzte_nomen` | `CompoundNounTemplate` |
| `german_3_satzarten` | `SentenceTypeTemplate` |
| `german_3_diktat` | `DictationTemplate` |
| `german_3_lernwoerter` | `SightWordTemplate` |

#### Deutsch Klasse 4
| Topic-Key | Template-Klasse |
|---|---|
| `german_4_das_dass` | `DasDassTemplate` |
| `german_4_vier_faelle` | `CaseTemplate` |
| `german_4_satzglieder` | `SentenceElementTemplate` |
| `german_4_woertliche_rede` | `DirectSpeechTemplate` |
| `german_4_fehlertext` | `ErrorTextTemplate` |
| `german_4_kommasetzung` | `CommaPunctuationTemplate` |
| `german_4_textarten` | `TextTypeTemplate` |

### Neues Template hinzufügen

1. Template-Klasse in `lib/core/engine/templates/<subject>_grade<N>_templates.dart` implementieren (extends `TaskTemplate`).
2. `_register(const MeineTemplate())` in `TaskGenerator._init()` eintragen.
3. Fertig — sofort über `generateSession` verfügbar.

---

## Evaluator

**Datei:** `lib/core/engine/evaluator.dart`

Zentraler Auswertungsservice. Dispatch-Punkt ist `Evaluator.evaluate(task, answer)`,
aufgerufen in `LearningChallengeSession._submitAnswer`.

### Dispatch-Tabelle

| TaskType | Methode | Verhalten |
|---|---|---|
| `freeInput` | `evaluateFreeInput` | int-Vergleich, Double ±0.001-Toleranz, sonst case-insensitiv getrimmt |
| `multipleChoice` | `evaluateMultipleChoice` | Direkter `==`-Vergleich mit `correctAnswer` |
| `ordering` | `evaluateOrdering` | Listenvergleich: Länge + alle Elemente positionsweise als String |
| `gapFill` | `evaluateGapFill` | Listenvergleich: positionsweise, case-insensitiv, getrimmt |
| alle anderen | `evaluateFreeInput` (Fallback) | Templates mit `interactive`/`tapRhythm` implementieren `TaskTemplate.evaluate` selbst |

**Wichtig:** Templates für `interactive` (Clock, Money, Fraction) und `tapRhythm` (Syllable)
überschreiben `TaskTemplate.evaluate` mit eigener Logik und nutzen `Evaluator` nicht direkt.

---

## DifficultyEngine

**Datei:** `lib/core/engine/difficulty.dart`

Adaptiver Schwierigkeitsregler. Ziel: Trefferquote zwischen 50 % und 90 %
("Zone der proximalen Entwicklung").

### Algorithmus `nextDifficulty`

- Fenster: letzte 5 Ergebnisse aus `recentResults` (`1` = richtig, `0` = falsch)
- Trefferquote ≥ 90 % → Stufe +1 (Kind unterfordert)
- Trefferquote < 50 % → Stufe -1 (Kind überfordert)
- Sonst → unverändert
- Grenzen: immer zwischen 1 und 5

```dart
int nextDifficulty({
  required List<int> recentResults,  // letzte Ergebnisse der Session
  required int currentDifficulty,    // aktuelle Stufe
})
```

### Einstiegs-Schwierigkeit `initialDifficulty`

Berechnet aus historischer Genauigkeit (`TopicProgress.accuracy`) und Klassenstufe:

| accuracy | Stufe |
|---|---|
| 0.0 (keine Historie) | `(grade - 1).clamp(1, 3)` |
| > 0.9 | 5 |
| > 0.7 | 3 |
| > 0.5 | 2 |
| ≤ 0.5 | 1 |

---

## Curriculum

**Datei:** `lib/core/engine/curriculum.dart`

Bundesland-spezifisches Lehrplan-Mapping. Steuert Themen-Reihenfolge und Varianten.

### Unterstützte Bundesländer / Länder

`kFederalStates` enthält alle 18 Einträge als `(kürzel, name)`:

BY, BW, NW, NI, HE, SN, ST, TH, BB, MV, SH, HH, BE, HB, SL, RP, AT (Österreich), CH (Schweiz)

### Bundesland-spezifische Varianten

| Eigenschaft | Bundesländer | Wert |
|---|---|---|
| `teachesCursiveEarly` | BY, BW, RP | `true` — Schreibschrift früher |
| `timestablesGrade` | SH, MV | 3 — Einmaleins ab Kl.3 statt Kl.2 |
| alle anderen | alle anderen | `false` / 2 |

### Themen-Reihenfolge

Die Reihenfolge bestimmt die Anzeigereihenfolge in `SubjectOverviewScreen`.

#### Mathe

| Klasse | Topics (in Reihenfolge) |
|---|---|
| 1 | zahlen_bis_10, zahlen_bis_20, addition_bis_10, subtraktion_bis_10, groesser_kleiner, zahlenmauern, formen, zahlenreihen, muster |
| 2 | addition_bis_100, subtraktion_bis_100, einmaleins, uhrzeit, geld, zahlenmauern, rechenketten, textaufgaben |
| 3 | schriftliche_addition, schriftliche_subtraktion, multiplikation, division_mit_rest, groessen_umrechnen, geometrie, textaufgaben_3 |
| 4 | schriftliche_multiplikation, schriftliche_division, brueche, dezimalzahlen, diagramme, grosse_zahlen, sachaufgaben_4 |

#### Deutsch

| Klasse | Topics (in Reihenfolge) |
|---|---|
| 1 | buchstaben, anlaute, silben, woerter_lesen, reimwoerter, lueckenwoerter, buchstaben_salat, handschrift |
| 2 | artikel, wortarten, einzahl_mehrzahl, rechtschreibung_ie_ei, abc_sortieren, saetze_bilden, lesetext |
| 3 | zeitformen, wortfamilien, zusammengesetzte_nomen, satzarten, diktat, lernwoerter |
| 4 | vier_faelle, satzglieder, das_dass, woertliche_rede, fehlertext, kommasetzung, textarten |
```

- [ ] **Schritt 2: Commit**

```bash
git add docs/engine.md
git commit -m "docs: engine.md — TaskTemplate, TaskGenerator, Evaluator, DifficultyEngine, Curriculum"
```

---

### Task 3: docs/learning_engine.md schreiben

**Files:**
- Create: `docs/learning_engine.md`
- Source: `lib/core/learning/learning_engine.dart`, `lib/core/learning/default_learning_engine.dart`, `lib/core/learning/learning_request.dart`, `lib/core/learning/learning_session.dart`, `lib/features/exercise/learning_session_mode.dart`, `lib/features/exercise/learning_challenge_session.dart`

- [ ] **Schritt 1: docs/learning_engine.md erstellen**

```markdown
# Learning Engine

Alle Dateien in `lib/core/learning/` (Interfaces, Implementierung) und
`lib/features/exercise/` (Session-Widget, Modi).

---

## LearningEngine (Interface)

**Datei:** `lib/core/learning/learning_engine.dart`

Abstrakte Schnittstelle für die gesamte Lernlogik. Die konkrete Implementierung
ist `DefaultLearningEngine`. Riverpod-Provider: `learningEngineProvider`.

### Methoden

| Methode | Signatur | Beschreibung |
|---|---|---|
| `topicsFor` | `List<String> topicsFor({required String federalState, required Subject subject, required int grade})` | Geordnete Themenliste für Fach+Klasse+Bundesland via `Curriculum` |
| `createSession` | `LearningSession createSession(LearningRequest request)` | Generiert Aufgaben via `TaskGenerator` |
| `evaluateTask` | `TaskResult evaluateTask(TaskModel task, dynamic answer)` | Wertet Antwort aus via `Evaluator` |
| `nextDifficulty` | `int nextDifficulty({required List<int> recentResults, required int currentDifficulty})` | Adaptiver Schwierigkeitsgrad via `DifficultyEngine` |
| `initialDifficulty` | `int initialDifficulty({required TopicProgress progress, required int grade})` | Einstiegs-Schwierigkeit via `DifficultyEngine` |
| `progressFor` | `TopicProgress progressFor({required String profileId, required Subject subject, required int grade, required String topic})` | Liest Fortschritt aus `StorageService` |
| `allProgressForProfile` | `List<TopicProgress> allProgressForProfile(String profileId)` | Alle Fortschrittseinträge eines Profils |
| `recordResult` | `Future<void> recordResult({required String profileId, required Subject subject, required int grade, required String topic, required bool correct})` | Schreibt Ergebnis in `StorageService` |

---

## DefaultLearningEngine

**Datei:** `lib/core/learning/default_learning_engine.dart`

Konkrete Implementierung von `LearningEngine`. Delegiert an Engine-Klassen und `StorageService`.

```
DefaultLearningEngine
  ├── topicsFor       → Curriculum
  ├── createSession   → TaskGenerator
  ├── evaluateTask    → Evaluator
  ├── nextDifficulty  → DifficultyEngine
  ├── initialDifficulty → DifficultyEngine
  ├── progressFor     → StorageService
  ├── allProgressForProfile → StorageService
  └── recordResult    → StorageService
```

Wird über `learningEngineProvider` (Riverpod) in Widgets konsumiert:
```dart
final learning = ref.read(learningEngineProvider);
```

---

## LearningRequest

**Datei:** `lib/core/learning/learning_request.dart`

Eingabeparameter für eine Lernsession.

| Feld | Typ | Default | Beschreibung |
|---|---|---|---|
| `subject` | `Subject` | — | Fach (`Subject.math` oder `Subject.german`) |
| `grade` | `int` | — | Klassenstufe 1–4 |
| `topic` | `String` | — | Topic-Key, z.B. `"addition_bis_10"` |
| `difficulty` | `int` | — | Startschwierigkeit 1–5 |
| `count` | `int` | `10` | Anzahl Aufgaben pro Session |
| `seed` | `int?` | `null` | RNG-Seed; bei gleichem Seed reproduzierbare Aufgaben |
| `subjectId` | `String` | (computed) | `subject.id` — Convenience-Getter |

---

## LearningSession

**Datei:** `lib/core/learning/learning_session.dart`

Ergebnis von `LearningEngine.createSession`. Unveränderlich.

| Feld | Typ | Beschreibung |
|---|---|---|
| `request` | `LearningRequest` | Die ursprüngliche Anfrage |
| `tasks` | `List<TaskModel>` | Generierte Aufgaben |
| `isEmpty` | `bool` | `true` wenn keine Aufgaben vorhanden (kein Template für dieses Topic) |

---

## LearningSessionMode

**Datei:** `lib/features/exercise/learning_session_mode.dart`

Steuert Verhalten nach Abschluss einer Session.

| Wert | Beschreibung | Navigation nach Abschluss |
|---|---|---|
| `freePractice` | Freies Üben (Standard-Übungsroute) | Navigiert zu `ResultScreen` via `Navigator.pushReplacement` |
| `questSingle` | Eine Quest-Einzelaufgabe | Ruft `onCompleted`-Callback auf — kein Route-Wechsel |
| `questMiniSeries` | Quest-Miniserie (mehrere Aufgaben) | Ruft `onCompleted`-Callback auf — kein Route-Wechsel |
| `dailyPath` | Tages-Pfad-Schritt | Ruft `onCompleted`-Callback auf — kein Route-Wechsel |

---

## LearningChallengeSession (Widget)

**Datei:** `lib/features/exercise/learning_challenge_session.dart`

`ConsumerStatefulWidget`, das eine vollständige Lern-Session rendert.
Verwendet für alle Modi — freies Üben, Quest-Aufgaben und Tages-Pfad.

### Parameter

| Parameter | Typ | Default | Beschreibung |
|---|---|---|---|
| `request` | `LearningRequest` | — | Session-Parameter |
| `mode` | `LearningSessionMode` | — | Bestimmt Navigation nach Abschluss |
| `onCompleted` | `ValueChanged<LearningChallengeResult>` | — | Callback mit Ergebnis |
| `showScaffold` | `bool` | `true` | `false` für Einbettung in Overlay (Quest/DailyPath) |
| `recordProgress` | `bool` | `true` | `false` um Fortschrittsaufzeichnung zu deaktivieren |
| `onCancel` | `VoidCallback?` | `null` | Optionaler Abbrechen-Handler |

### Session-Ablauf

```
initState()
  └─ _loadTasks()           → LearningEngine.createSession()
  └─ (400ms delay) _speakCurrentQuestion() → TtsService.speak()

Aufgabe anzeigen
  └─ LearningAnswerWidget   → Widget-Dispatch nach TaskType/topic
  └─ onAnswerChanged()      → _pendingAnswer setzen

"Prüfen" Button
  └─ _submitAnswer()
      ├─ LearningEngine.evaluateTask()
      ├─ recordProgress=true → LearningEngine.recordResult()
      ├─ SoundService.playCorrect() / playWrong()
      └─ (1200ms delay) _nextTask()

_nextTask()
  ├─ letzte Aufgabe → onCompleted(LearningChallengeResult)
  └─ sonst → LearningEngine.nextDifficulty(), nächste Aufgabe
```

### LearningChallengeResult

| Feld | Typ | Beschreibung |
|---|---|---|
| `mode` | `LearningSessionMode` | Modus der Session |
| `grade` | `int` | Klassenstufe |
| `subjectId` | `String` | Fach-ID |
| `topic` | `String` | Topic-Key |
| `correctCount` | `int` | Anzahl korrekter Antworten |
| `totalCount` | `int` | Gesamtanzahl Aufgaben |
| `successful` | `bool` | `correctCount == totalCount` |

---

## Zusammenspiel mit QuestRuntime

`QuestRuntime` erstellt `LearningRequest`-Objekte aus Quest-Step-Definitionen
und übergibt sie an `LearningChallengeSession` mit `mode: LearningSessionMode.questSingle`.
Nach Abschluss ruft der `onCompleted`-Callback `QuestRuntime.completeCurrentStep()` auf.
`LearningChallengeSession` kennt `QuestRuntime` nicht — Kopplung nur über Callback.
```

- [ ] **Schritt 2: Commit**

```bash
git add docs/learning_engine.md
git commit -m "docs: learning_engine.md — Interface, DefaultImpl, Session-Ablauf, Modi"
```

---

### Task 4: docs/storage_and_persistence.md schreiben

**Files:**
- Create: `docs/storage_and_persistence.md`
- Source: `lib/core/services/storage_service.dart`, `lib/core/services/providers.dart`, `lib/core/models/settings.dart`, `lib/core/models/progress.dart`, `lib/game/quest/quest_status_store.dart`, `lib/game/reward/inventory_store.dart`, `lib/core/learning/daily_path_store.dart`

- [ ] **Schritt 1: docs/storage_and_persistence.md erstellen**

```markdown
# Storage und Persistenz

Die App arbeitet **vollständig offline**. Kein Backend, keine Datenbank, keine Analytics.
Einziger Persistenz-Layer: `SharedPreferences` (JSON-kodiert), verwaltet durch `StorageService`.

---

## SharedPreferences — Vollständige Key-Übersicht

| Key | Typ | Verwaltet von | Inhalt |
|---|---|---|---|
| `lf_settings` | `String` (JSON) | `StorageService` | `AppSettings` |
| `lf_profiles` | `String` (JSON) | `StorageService` | `List<ChildProfile>` |
| `lf_progress_<profileId>-<subject>-<grade>-<topic>` | `String` (JSON) | `StorageService` | `TopicProgress` |
| `lf_quest_status_<profileId>` | `String` (JSON) | `QuestStatusStore` | `QuestStatus` (Map: questId → Status) |
| `lf_inventory_<profileId>` | `String` (JSON) | `InventoryStore` | `InventoryState` |
| `lf_daily_path_<profileId>-<yyyy-mm-dd>` | `String` (JSON) | `DailyPathStore` | `DailyPathProgress` |

**Wichtig:** Keys dürfen bei der Migration nicht geändert werden — sonst gehen bestehende Profile verloren.

---

## StorageService

**Datei:** `lib/core/services/storage_service.dart`

Singleton. Muss einmalig via `await StorageService.init()` in `main()` initialisiert werden,
bevor `runApp()` aufgerufen wird. Danach überall via `StorageService.instance` erreichbar.

```dart
// main.dart
await StorageService.init();
runApp(ProviderScope(child: LernFuchsApp()));
```

### API

| Methode | Beschreibung |
|---|---|
| `static Future<StorageService> init()` | Initialisiert Singleton, gibt Instanz zurück |
| `static StorageService get instance` | Gibt initialisierte Instanz zurück (wirft AssertionError wenn nicht initialisiert) |
| `AppSettings get settings` | Liest AppSettings; gibt Standardwerte zurück wenn noch keine gespeichert |
| `Future<void> saveSettings(AppSettings s)` | Speichert AppSettings |
| `List<ChildProfile> get profiles` | Liest alle Profile; gibt `[]` zurück wenn keine vorhanden |
| `Future<void> saveProfiles(List<ChildProfile> profiles)` | Speichert komplette Profil-Liste |
| `ChildProfile? getProfile(String id)` | Einzelnes Profil nach ID, oder `null` |
| `Future<void> saveProfile(ChildProfile profile)` | Speichert ein Profil (insert oder update) |
| `TopicProgress getProgress({profileId, subject, grade, topic})` | Lernfortschritt für ein Thema; gibt leeres Objekt zurück wenn noch keine Daten |
| `Future<void> saveProgress(TopicProgress progress)` | Speichert TopicProgress-Eintrag |
| `Future<void> recordResult({profileId, subject, grade, topic, correct})` | Convenience: lesen + Ergebnis eintragen + speichern |
| `List<TopicProgress> allProgressForProfile(String profileId)` | Alle Fortschrittseinträge eines Profils (für ProgressScreen/ParentDashboard) |

---

## Datenmodelle (JSON-Schemas)

### AppSettings

```json
{
  "federalState": "BY",
  "soundEnabled": true,
  "ttsEnabled": true,
  "fontSize": 1.0,
  "highContrast": false,
  "activeProfileId": "default",
  "parentPin": null,
  "onboardingDone": false
}
```

| Feld | Typ | Default | Beschreibung |
|---|---|---|---|
| `federalState` | `String` | `"BY"` | Bundesland-Kürzel, steuert Curriculum |
| `soundEnabled` | `bool` | `true` | Feedback-Sounds aktiv |
| `ttsEnabled` | `bool` | `true` | Text-to-Speech aktiv |
| `fontSize` | `double` | `1.0` | Skalierung: 1.0 / 1.15 / 1.3 |
| `highContrast` | `bool` | `false` | Hochkontrast-Modus (Barrierefreiheit) |
| `activeProfileId` | `String` | `"default"` | ID des aktiven Kinderprofils |
| `parentPin` | `String?` | `null` | 4-stelliger PIN; `null` = kein Schutz |
| `onboardingDone` | `bool` | `false` | Onboarding-Abschluss-Flag |

### ChildProfile

```json
{
  "id": "abc-123",
  "name": "Emma",
  "grade": 2,
  "avatarEmoji": "🦊",
  "totalStars": 42,
  "createdAt": "2025-09-01T10:00:00.000Z"
}
```

| Feld | Typ | Default | Beschreibung |
|---|---|---|---|
| `id` | `String` | — | UUID |
| `name` | `String` | — | Anzeigename |
| `grade` | `int` | — | Klassenstufe 1–4 |
| `avatarEmoji` | `String` | `"🦊"` | Emoji-Avatar |
| `totalStars` | `int` | `0` | Kumulierte Gesamtpunktzahl |
| `createdAt` | `String` | — | ISO-8601 Zeitstempel |

### TopicProgress

```json
{
  "profileId": "abc-123",
  "subject": "math",
  "grade": 2,
  "topic": "addition_bis_100",
  "totalAttempts": 30,
  "correctAttempts": 24,
  "lastPracticed": "2026-04-10T14:00:00.000Z",
  "recentResults": [1, 1, 0, 1, 1]
}
```

| Feld | Typ | Beschreibung |
|---|---|---|
| `profileId` | `String` | Zugehöriges Profil |
| `subject` | `String` | `"math"` oder `"german"` |
| `grade` | `int` | Klassenstufe 1–4 |
| `topic` | `String` | Topic-Key |
| `totalAttempts` | `int` | Gesamtanzahl beantworteter Aufgaben |
| `correctAttempts` | `int` | Anzahl korrekter Antworten |
| `lastPracticed` | `String` | ISO-8601 Zeitstempel der letzten Session |
| `recentResults` | `List<int>` | Letzte 20 Ergebnisse (`1`=richtig, `0`=falsch) — für DifficultyEngine |

`accuracy` = `correctAttempts / totalAttempts` (0.0 wenn `totalAttempts == 0`)

---

## Riverpod-Provider

**Datei:** `lib/core/services/providers.dart`

| Provider | Typ | Beschreibung | Schreibmethode |
|---|---|---|---|
| `storageServiceProvider` | `Provider<StorageService>` | StorageService-Singleton | — (read-only) |
| `learningEngineProvider` | `Provider<LearningEngine>` | DefaultLearningEngine-Instanz | — (read-only) |
| `dailyPathServiceProvider` | `Provider<DailyPathService>` | DailyPathService-Instanz | — (read-only) |
| `ttsServiceProvider` | `Provider<TtsService>` | TTS-Instanz (override in main) | — (read-only) |
| `soundServiceProvider` | `Provider<SoundService>` | Sound-Instanz (override in main) | — (read-only) |
| `appSettingsProvider` | `StateNotifierProvider<AppSettingsNotifier, AppSettings>` | Reaktive AppSettings | `ref.read(appSettingsProvider.notifier).toggleSound(false)` |
| `activeProfileProvider` | `Provider<ChildProfile?>` | Aktuell aktives Profil | via `appSettingsProvider.notifier.switchProfile(id)` |
| `allProfilesProvider` | `Provider<List<ChildProfile>>` | Alle Profile | via `StorageService.saveProfile` |
| `topicProgressProvider` | `Provider.family<TopicProgress, ({profileId, subject, grade, topic})>` | Fortschritt für ein Thema | via `LearningEngine.recordResult` |
| `allProgressProvider` | `Provider<List<TopicProgress>>` | Alle Fortschritte des aktiven Profils | via `LearningEngine.recordResult` |

### AppSettingsNotifier-Methoden

| Methode | Beschreibung |
|---|---|
| `updateFederalState(String code)` | Bundesland setzen |
| `setOnboardingDone()` | Onboarding abschließen |
| `toggleSound(bool value)` | Sounds ein/aus |
| `toggleTts(bool value)` | TTS ein/aus |
| `toggleHighContrast(bool value)` | Hochkontrast ein/aus |
| `updateFontSize(double factor)` | Schriftgröße setzen (1.0 / 1.15 / 1.3) |
| `setParentPin(String pin)` | Eltern-PIN setzen |
| `clearParentPin()` | Eltern-PIN entfernen |
| `switchProfile(String profileId)` | Aktives Profil wechseln |

---

## Schreib-/Lesepfade

| Wer schreibt | Was | Wer liest |
|---|---|---|
| `ExerciseScreen` / `LearningChallengeSession` | `TopicProgress` via `LearningEngine.recordResult` | `ProgressScreen`, `SubjectOverviewScreen`, `ParentDashboardScreen` |
| `ResultScreen` | `ChildProfile.totalStars` via `StorageService.saveProfile` | `HomeScreen`, `ProfileScreen` |
| `OnboardingScreen` | `AppSettings` (federalState, onboardingDone, erstes Profil) | überall via `appSettingsProvider` |
| `SettingsScreen` | `AppSettings` via `AppSettingsNotifier` | überall via `appSettingsProvider` |
| `ProfileScreen` | `ChildProfile` via `StorageService.saveProfile` | `HomeScreen`, `ParentDashboardScreen` |
| `QuestRuntime` | `QuestStatus` via `QuestStatusStore` | `LernFuchsWorldGame`, `QuestRuntime` |
| `QuestRuntime` | `InventoryState` via `InventoryStore` | `BaumbausScreen` |
| `DailyPathScreen` | `DailyPathProgress` via `DailyPathStore` | `DailyPathScreen` |
```

- [ ] **Schritt 2: Commit**

```bash
git add docs/storage_and_persistence.md
git commit -m "docs: storage_and_persistence.md — Keys, Schemas, Provider, Schreibpfade"
```

---

### Task 5: docs/exercise_widgets.md schreiben

**Files:**
- Create: `docs/exercise_widgets.md`
- Source: `lib/features/exercise/learning_challenge_session.dart` (LearningAnswerWidget), `lib/core/models/task_model.dart` (TaskType)

- [ ] **Schritt 1: docs/exercise_widgets.md erstellen**

```markdown
# Exercise Widgets

Alle Aufgaben-Widgets liegen in `lib/features/exercise/widgets/`.
Der zentrale Dispatch-Punkt ist `LearningAnswerWidget` in
`lib/features/exercise/learning_challenge_session.dart`.

---

## Widget-Interface

Jedes Widget hat dieselbe Schnittstelle:

```dart
class XxxWidget extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const XxxWidget({super.key, required this.task, required this.onChanged});
}
```

- `task` enthält Frage, Typ, korrekte Antwort und aufgabenspezifische Daten in `task.metadata`
- `onChanged` wird aufgerufen wenn der Nutzer eine Antwort auswählt oder eingibt
- **Kein Absenden-Button** im Widget — der "Prüfen"-Button liegt in `LearningChallengeSession`

---

## Dispatch-Logik (`LearningAnswerWidget`)

Die Dispatch-Reihenfolge ist: zuerst `interactive` nach Topic, dann `freeInput` nach Topic/Metadata,
dann `multipleChoice` nach Topic, dann nach `TaskType`.

```
TaskType.interactive
  topic == "uhrzeit"     → ClockWidget
  topic == "geld"        → MoneyWidget
  topic == "brueche"     → FractionWidget
  sonst                  → FreeInputWidget (Fallback)

TaskType.freeInput
  topic == "zahlen_bis_10" oder "zahlen_bis_20"
    + metadata["dotCount"] vorhanden         → DotCountWidget
  topic == "zahlenmauern"                    → NumberWallWidget
  topic == "schriftliche_addition" / "schriftliche_subtraktion" /
  "schriftliche_multiplikation" / "schriftliche_division"
    + metadata["showSteps"] == true          → WrittenCalculationWidget
  topic == "diktat"                          → DictationWidget
  sonst                                      → FreeInputWidget

TaskType.multipleChoice
  topic == "lesetext"                        → ReadingTextWidget
  topic == "diagramme"                       → BarChartWidget
  metadata["visible"] vorhanden              → PatternWidget
  sonst                                      → MultipleChoiceWidget

TaskType.ordering
  topic == "buchstaben_salat"                → LetterOrderingWidget
  sonst                                      → OrderingWidget

TaskType.tapRhythm
  topic == "silben"                          → SyllableTapWidget
  metadata["visible"] vorhanden              → PatternWidget
  sonst                                      → FreeInputWidget

TaskType.handwriting                         → HandwritingWidget

alle anderen                                 → FreeInputWidget
```

---

## Vollständige Widget-Tabelle

| Widget-Datei | TaskType | Topic / Bedingung | Antwortformat | Implementiert |
|---|---|---|---|---|
| `free_input_widget.dart` | `freeInput` | Standard-Fallback | `String` / `int` / `double` | Ja |
| `multiple_choice_widget.dart` | `multipleChoice` | Standard | Wert aus `metadata["choices"]` | Ja |
| `ordering_widget.dart` | `ordering` | Sätze/Wörter ordnen | `List<String>` | Ja |
| `letter_ordering_widget.dart` | `ordering` | `buchstaben_salat` | `List<String>` | Ja |
| `pattern_widget.dart` | `multipleChoice` / `tapRhythm` | `metadata["visible"]` vorhanden | Wert aus choices | Ja |
| `bar_chart_widget.dart` | `multipleChoice` | `diagramme` | Wert aus choices | Ja |
| `reading_text_widget.dart` | `multipleChoice` | `lesetext` | Wert aus choices | Ja |
| `syllable_tap_widget.dart` | `tapRhythm` | `silben` | `int` (Anzahl Taps) | Ja |
| `dot_count_widget.dart` | `freeInput` | `zahlen_bis_10`/`zahlen_bis_20` + `metadata["dotCount"]` | `int` | Ja |
| `number_wall_widget.dart` | `freeInput` | `zahlenmauern` | `Map<String, int>` (Wandfelder) | Ja |
| `written_calculation_widget.dart` | `freeInput` | schriftl. Rechnen + `metadata["showSteps"]=true` | `int` | Ja |
| `dictation_widget.dart` | `freeInput` | `diktat` | `String` | Ja |
| `clock_widget.dart` | `interactive` | `uhrzeit` | `String` (HH:MM) | Ja |
| `money_widget.dart` | `interactive` | `geld` | `double` (Eurobetrag) | Ja |
| `fraction_widget.dart` | `interactive` | `brueche` | `String` (z.B. `"1/2"`) | Ja |
| `handwriting_widget.dart` | `handwriting` | — | `String` (Placeholder) | Phase 4 |

---

## TaskType-Enum

**Datei:** `lib/core/models/task_model.dart`

| Wert | Widget | Status |
|---|---|---|
| `freeInput` | FreeInputWidget (+ Spezialisierungen) | Implementiert |
| `multipleChoice` | MultipleChoiceWidget (+ Spezialisierungen) | Implementiert |
| `ordering` | OrderingWidget / LetterOrderingWidget | Implementiert |
| `tapRhythm` | SyllableTapWidget / PatternWidget | Implementiert |
| `interactive` | ClockWidget / MoneyWidget / FractionWidget | Implementiert |
| `gapFill` | FreeInputWidget | Implementiert (Phase 4) |
| `handwriting` | HandwritingWidget | Phase 4 (Placeholder) |
| `dragDrop` | — | Phase 4 (nicht implementiert) |
| `matching` | — | Phase 4 (nicht implementiert) |

---

## TaskModel.metadata — Typische Schlüssel

| Schlüssel | Typ | Genutzt von | Bedeutung |
|---|---|---|---|
| `choices` | `List<String>` | MultipleChoiceWidget, BarChartWidget, PatternWidget | Auswahloptionen |
| `dotCount` | `int` | DotCountWidget | Anzahl anzuzeigender Punkte |
| `text` | `String` | ReadingTextWidget | Lesetext |
| `word` | `String` | DictationWidget | Zu schreibendes Wort |
| `displayedWord` | `String` | DictationWidget | Kurz angezeigtes Wort vor Verdeckung |
| `showThenHide` | `bool` | DictationWidget | Wort kurz zeigen, dann verdecken |
| `showSteps` | `bool` | WrittenCalculationWidget | Schriftliche Rechenschritte anzeigen |
| `visible` | `List` | PatternWidget | Sichtbare Muster-Elemente |
```

- [ ] **Schritt 2: Commit**

```bash
git add docs/exercise_widgets.md
git commit -m "docs: exercise_widgets.md — alle Widgets, Dispatch-Logik, TaskType-Tabelle"
```

---

### Task 6: docs/feature_flags.md schreiben

**Files:**
- Create: `docs/feature_flags.md`
- Source: `lib/app/feature_flags.dart`

- [ ] **Schritt 1: docs/feature_flags.md erstellen**

```markdown
# Feature Flags

**Datei:** `lib/app/feature_flags.dart`

Zentraler Schalter für schrittweise Feature-Einführung.
Alle Flags sind `static const bool` — zur Compile-Zeit aufgelöst, kein Runtime-Overhead.

---

## Aktuelle Flags

| Flag | Typ | Default | Status | Beschreibung |
|---|---|---|---|---|
| `FeatureFlags.enableGameWorld` | `bool` | `false` | Noch nicht verdrahtet | Schaltet die Flame-Spielwelt ein. Aktuell `false` und noch nicht in Verhaltenslogik eingebunden — Placeholder für den Flutter+Flame-Migrationspfad (siehe `docs/refactor_map.md`) |

---

## Geplante Verwendung

Gemäß `docs/refactor_map.md` soll `enableGameWorld` künftig die Spielwelt-Route aktivieren:

```dart
// Beispiel — noch nicht implementiert
if (FeatureFlags.enableGameWorld) {
  // Flame-Route zeigen
} else {
  // Placeholder-Screen zeigen
}
```

---

## Neues Flag hinzufügen

1. Konstante in `lib/app/feature_flags.dart` eintragen:

```dart
class FeatureFlags {
  const FeatureFlags._();

  static const bool enableGameWorld = false;
  static const bool enableDailyPath = false; // neu
}
```

2. Flag an den relevanten Stellen im Code prüfen.
3. Dieses Dokument aktualisieren.

**Kein Dynamic-Config-System** — bewusste Entscheidung. Alle Flags sind compile-time.
Für produktionsreife Feature-Flags (A/B-Tests, Remote-Config) müsste ein externer
Dienst integriert werden — das ist nicht geplant.
```

- [ ] **Schritt 2: Commit**

```bash
git add docs/feature_flags.md
git commit -m "docs: feature_flags.md — aktuelle Flags, Erweiterungsanleitung"
```

---

## Self-Review

**Spec-Abdeckung:**
- [x] README.md → Task 1
- [x] docs/engine.md → Task 2 (TaskTemplate, TaskGenerator mit vollständiger Template-Liste, Evaluator, DifficultyEngine, Curriculum)
- [x] docs/learning_engine.md → Task 3 (Interface, DefaultImpl, Request, Session, Modi, Widget-Ablauf, QuestRuntime-Zusammenspiel)
- [x] docs/storage_and_persistence.md → Task 4 (alle 6 Key-Typen, Schemas, Provider-Tabelle, Schreibpfade)
- [x] docs/exercise_widgets.md → Task 5 (alle 16 Widgets, vollständige Dispatch-Logik, TaskType-Enum, metadata-Schlüssel)
- [x] docs/feature_flags.md → Task 6

**Placeholder-Scan:** Keine TBDs, keine "fill in details" gefunden.

**Typ-Konsistenz:** Alle Methodensignaturen direkt aus dem Source abgeleitet. Key-Schema `lf_progress_<profileId>-<subject>-<grade>-<topic>` stimmt mit `StorageService` überein.
