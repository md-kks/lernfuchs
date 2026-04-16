# Engine — Aufgabengenerierung & Schwierigkeitssteuerung

Dieses Dokument beschreibt alle Klassen im Verzeichnis `lib/core/engine/` sowie die zugehörigen Template-Implementierungen in `lib/core/engine/templates/`.

---

## 1. TaskTemplate

**Datei:** `lib/core/engine/task_template.dart`

Abstrakte Basisklasse für alle Aufgabentypen. Jede konkrete Unterklasse repräsentiert genau einen Aufgabentyp (z.B. `AdditionTemplate`, `VerbTenseTemplate`) und kann algorithmisch beliebig viele Aufgaben desselben Typs erzeugen. Alle Instanzen werden in `TaskGenerator._init` einmalig erstellt und unter dem Schlüssel `"<subject.id>_<grade>_<topic>"` registriert.

### Felder

| Feld            | Typ       | Default | Beschreibung                                                                 |
|-----------------|-----------|---------|------------------------------------------------------------------------------|
| `id`            | `String`  | —       | Eindeutiger Bezeichner, identisch mit `topic`                                |
| `subject`       | `Subject` | —       | Zugehöriges Schulfach (`Subject.math` oder `Subject.german`)                 |
| `grade`         | `int`     | —       | Klassenstufe 1–4                                                             |
| `topic`         | `String`  | —       | Themenbezeichner; URL-Segment in der Navigation (z.B. `"addition_bis_20"`)   |
| `minDifficulty` | `int`     | `1`     | Minimaler unterstützter Schwierigkeitsgrad                                   |
| `maxDifficulty` | `int`     | `5`     | Maximaler unterstützter Schwierigkeitsgrad                                   |

### Abstrakte Methoden

| Signatur                                                        | Beschreibung                                                                                                     |
|-----------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| `TaskModel generate(int difficulty, Random rng)`               | Generiert eine neue algorithmisch zufällige Aufgabe. `difficulty` liegt zwischen `minDifficulty` und `maxDifficulty`; bei gleichem `rng`-Seed sind Aufgaben reproduzierbar. |
| `bool evaluate(TaskModel task, dynamic userAnswer)`            | Bewertet eine Kinderantwort gegen `task.correctAnswer`. Gibt `true` zurück wenn korrekt. Unterklassen implementieren aufgabenspezifische Logik (Groß-/Kleinschreibung, Trimmen, Listenvergleich). |
| `String get displayName`                                        | Menschenlesbarer Name für Fortschrittsanzeige und Auswahl-UI.                                                   |

### Hilfsmethode `makeTask`

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

Erzeugt ein `TaskModel` mit automatisch gesetzten Feldern `subject`, `grade`, `topic` und einer zufälligen `id` (`'${id}_${rng.nextInt(1000000)}'`). Spart Boilerplate in allen Unterklassen.

### Minimales Implementierungsbeispiel

```dart
class MyTemplate extends TaskTemplate {
  const MyTemplate()
      : super(
          id: 'my_topic',
          subject: Subject.math,
          grade: 2,
          topic: 'my_topic',
          minDifficulty: 1,
          maxDifficulty: 3,
        );

  @override
  String get displayName => 'Mein Aufgabentyp';

  @override
  TaskModel generate(int difficulty, Random rng) {
    final value = rng.nextInt(10 * difficulty) + 1;
    return makeTask(
      rng: rng,
      difficulty: difficulty,
      question: 'Was ist $value + $value?',
      correctAnswer: value * 2,
      type: TaskType.freeInput,
      metadata: {'value': value},
    );
  }

  @override
  bool evaluate(TaskModel task, dynamic userAnswer) {
    final answer = int.tryParse(userAnswer.toString());
    return answer != null && answer == task.correctAnswer;
  }
}
```

---

## 2. TaskGenerator

**Datei:** `lib/core/engine/task_generator.dart`

Zentrales Template-Register und Session-Generator. Hält alle `TaskTemplate`-Instanzen in einer Flat-Map mit dem Schlüssel `"<subject.id>_<grade>_<topic>"` (z.B. `"math_2_uhrzeit"`). Die Initialisierung erfolgt lazy beim ersten Zugriff auf eine der öffentlichen Methoden.

**Key-Schema:** `"<subject.id>_<grade>_<topic>"` — Trennzeichen ist `_` (Unterstrich).

Beispiele: `"math_1_zahlen_bis_10"`, `"german_3_zeitformen"`, `"math_2_einmaleins"`

> Nicht zu verwechseln mit dem `StorageService`-Fortschritts-Key-Format `lf_progress_<profileId>-<subject>-<grade>-<topic>`, das Bindestriche verwendet und ein anderes System adressiert.

### API

| Signatur                                                                                                                              | Beschreibung                                                                                                                                                                |
|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `static List<TaskModel> generateSession({required Subject subject, required int grade, required String topic, required int difficulty, int count = 10, int? seed})` | Generiert eine Session mit `count` Aufgaben für das angegebene Thema. Wirft `ArgumentError` wenn kein Template gefunden. |
| `static List<TaskTemplate> templatesFor(Subject subject, int grade)`                                                                 | Gibt alle registrierten Templates für ein Fach und eine Klasse zurück. Genutzt von `SubjectOverviewScreen` für die Themenauswahl.                                           |
| `static TaskTemplate? template(Subject subject, int grade, String topic)`                                                            | Gibt ein einzelnes Template zurück. Gibt `null` zurück wenn nicht gefunden. Primär für Unit-Tests.                                                                          |

### Seed-Verhalten

Wenn `seed` in `generateSession` übergeben wird, wird `Random(seed)` erzeugt — alle Aufgaben der Session sind damit deterministisch reproduzierbar. Ohne `seed` wird `Random()` genutzt (nicht-deterministisch). Nützlich für Debugging und Tests.

### Registrierte Templates

#### Mathe Klasse 1

| Template-Klasse              | `topic`-String       | `displayName`               | min–max Diff |
|------------------------------|----------------------|-----------------------------|--------------|
| `CountDotsTemplate`          | `zahlen_bis_10`      | Punkte zählen               | 1–2          |
| `NumberWritingTemplate`      | `zahlen_bis_20`      | Zahlen schreiben            | 1–2          |
| `AdditionTemplate(grade: 1)` | `addition_bis_10`    | Addition                    | 1–3          |
| `SubtractionTemplate(grade: 1)` | `subtraktion_bis_10` | Subtraktion              | 1–3          |
| `ComparisonTemplate`         | `groesser_kleiner`   | Größer / Kleiner / Gleich   | 1–3          |
| `NumberSequenceTemplate`     | `zahlenreihen`       | Zahlenreihe fortsetzen      | 1–3          |
| `NumberWallTemplate(grade: 1)` | `zahlenmauern`     | Zahlenmauer                 | 1–4          |
| `ShapeRecognitionTemplate`   | `formen`             | Formen erkennen             | 1–2          |
| `PatternContinuationTemplate`| `muster`             | Muster fortsetzen           | 1–3          |

#### Mathe Klasse 2

| Template-Klasse              | `topic`-String         | `displayName`               | min–max Diff |
|------------------------------|------------------------|-----------------------------|--------------|
| `AdditionTemplate(grade: 2)` | `addition_bis_100`     | Addition                    | 1–3          |
| `SubtractionTemplate(grade: 2)` | `subtraktion_bis_100` | Subtraktion               | 1–3          |
| `TimesTableTemplate`         | `einmaleins`           | Einmaleins                  | 1–4          |
| `ClockTemplate`              | `uhrzeit`              | Uhrzeit ablesen             | 1–4          |
| `MoneyTemplate`              | `geld`                 | Geld zählen                 | 1–4          |
| `NumberWallTemplate(grade: 2)` | `zahlenmauern`       | Zahlenmauer                 | 1–4          |
| `CalculationChainTemplate`   | `rechenketten`         | Rechenkette                 | 1–4          |
| `WordProblemGrade2Template`  | `textaufgaben`         | Textaufgabe                 | 1–3          |

#### Mathe Klasse 3

| Template-Klasse                      | `topic`-String             | `displayName`               | min–max Diff |
|--------------------------------------|----------------------------|-----------------------------|--------------|
| `WrittenAdditionTemplate`            | `schriftliche_addition`    | Schriftliche Addition       | 2–5          |
| `WrittenSubtractionTemplate`         | `schriftliche_subtraktion` | Schriftliche Subtraktion    | 2–5          |
| `SemiWrittenMultiplicationTemplate`  | `multiplikation`           | Multiplikation              | 2–4          |
| `DivisionWithRemainderTemplate`      | `division_mit_rest`        | Division mit Rest           | 2–5          |
| `UnitConversionTemplate`             | `groessen_umrechnen`       | Größen umrechnen            | 1–4          |
| `GeometryTemplate`                   | `geometrie`                | Umfang & Fläche             | 1–4          |
| `WordProblemGrade3Template`          | `textaufgaben_3`           | Textaufgabe                 | 2–4          |

#### Mathe Klasse 4

| Template-Klasse                | `topic`-String                   | `displayName`                  | min–max Diff |
|--------------------------------|----------------------------------|--------------------------------|--------------|
| `WrittenMultiplicationTemplate`| `schriftliche_multiplikation`    | Schriftliche Multiplikation    | 2–5          |
| `WrittenDivisionTemplate`      | `schriftliche_division`          | Schriftliche Division          | 2–5          |
| `FractionTemplate`             | `brueche`                        | Brüche                         | 1–4          |
| `DecimalNumberTemplate`        | `dezimalzahlen`                  | Dezimalzahlen                  | 1–4          |
| `DiagramReadingTemplate`       | `diagramme`                      | Diagramme lesen                | 1–3          |
| `LargeNumbersTemplate`         | `grosse_zahlen`                  | Große Zahlen & Runden          | 1–4          |
| `WordProblemGrade4Template`    | `sachaufgaben_4`                 | Sachaufgabe                    | 3–5          |

#### Deutsch Klasse 1

| Template-Klasse              | `topic`-String       | `displayName`               | min–max Diff |
|------------------------------|----------------------|-----------------------------|--------------|
| `LetterRecognitionTemplate`  | `buchstaben`         | Buchstaben erkennen         | 1–3          |
| `InitialSoundTemplate`       | `anlaute`            | Anlaute erkennen            | 1–2          |
| `SyllableCountTemplate`      | `silben`             | Silben klatschen            | 1–3          |
| `RhymeTemplate`              | `reimwoerter`        | Reimwörter                  | 1–2          |
| `MissingLetterTemplate`      | `lueckenwoerter`     | Lückenwörter                | 1–3          |
| `AnagramTemplate`            | `buchstaben_salat`   | Buchstaben-Salat            | 1–3          |
| `HandwritingTemplate`        | `handschrift`        | Buchstaben schreiben        | 1–2          |

#### Deutsch Klasse 2

| Template-Klasse                | `topic`-String           | `displayName`                    | min–max Diff |
|--------------------------------|--------------------------|----------------------------------|--------------|
| `ArticleTemplate`              | `artikel`                | Artikel zuordnen (der/die/das)   | 1–3          |
| `PluralTemplate`               | `einzahl_mehrzahl`       | Einzahl / Mehrzahl               | 1–3          |
| `AlphabetSortTemplate`         | `abc_sortieren`          | ABC sortieren                    | 1–3          |
| `WordTypeTemplate`             | `wortarten`              | Wortarten bestimmen              | 1–4          |
| `IeEiTemplate`                 | `rechtschreibung_ie_ei`  | ie oder ei?                      | 1–3          |
| `SentenceFormationTemplate`    | `saetze_bilden`          | Sätze bilden                     | 1–3          |
| `ReadingComprehensionTemplate` | `lesetext`               | Lesetext & Fragen                | 1–3          |

#### Deutsch Klasse 3

| Template-Klasse          | `topic`-String              | `displayName`                  | min–max Diff |
|--------------------------|-----------------------------|--------------------------------|--------------|
| `VerbTenseTemplate`      | `zeitformen`                | Zeitformen                     | 1–4          |
| `WordFamilyTemplate`     | `wortfamilien`              | Wortfamilien                   | 1–3          |
| `CompoundNounTemplate`   | `zusammengesetzte_nomen`    | Zusammengesetzte Nomen         | 1–3          |
| `SentenceTypeTemplate`   | `satzarten`                 | Satzarten                      | 1–3          |
| `DictationTemplate`      | `diktat`                    | Diktat                         | 1–4          |
| `SightWordTemplate`      | `lernwoerter`               | Lernwörter                     | 1–3          |

#### Deutsch Klasse 4

| Template-Klasse              | `topic`-String       | `displayName`                  | min–max Diff |
|------------------------------|----------------------|--------------------------------|--------------|
| `DasDassTemplate`            | `das_dass`           | das oder dass?                 | 2–4          |
| `CaseTemplate`               | `vier_faelle`        | Die vier Fälle                 | 1–4          |
| `SentenceElementTemplate`    | `satzglieder`        | Satzglieder bestimmen          | 2–4          |
| `DirectSpeechTemplate`       | `woertliche_rede`    | Wörtliche Rede                 | 2–4          |
| `ErrorTextTemplate`          | `fehlertext`         | Fehlertext korrigieren         | 2–4          |
| `CommaPunctuationTemplate`   | `kommasetzung`       | Kommasetzung                   | 2–4          |
| `TextTypeTemplate`           | `textarten`          | Bericht & Erzählung            | 2–4          |

### Neues Template hinzufügen (3 Schritte)

1. Template-Klasse in einer Datei unter `lib/core/engine/templates/` implementieren (von `TaskTemplate` erben, alle drei abstrakten Members implementieren).
2. Den Import der neuen Datei in `lib/core/engine/task_generator.dart` eintragen.
3. `_register(const MeineTemplate())` in der Methode `_init()` von `TaskGenerator` eintragen.

Das Template ist nach Schritt 3 sofort über `generateSession`, `templatesFor` und `template` verfügbar.

---

## 3. Evaluator

**Datei:** `lib/core/engine/evaluator.dart`

Zentraler Auswertungsservice für einfache Aufgabentypen. Der Dispatch-Einstiegspunkt ist `Evaluator.evaluate`, der in `ExerciseScreen._submitAnswer` aufgerufen wird.

### Dispatch-Tabelle

| `TaskType`        | Dispatcht zu               | Verhalten                                                                                                                        |
|-------------------|----------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| `freeInput`       | `evaluateFreeInput`        | Exakter `int`-Vergleich wenn beide `int`; Double-Vergleich mit Toleranz ±0.001 wenn beide `double`; sonst String-Vergleich case-insensitiv + getrimmt. |
| `multipleChoice`  | `evaluateMultipleChoice`   | Direkter `==`-Vergleich von `userAnswer` mit `task.correctAnswer`.                                                              |
| `ordering`        | `evaluateOrdering`         | `userAnswer` muss `List` sein; Länge und alle Elemente müssen als String exakt (case-sensitiv) übereinstimmen.                  |
| `gapFill`         | `evaluateGapFill`          | `userAnswer` muss `List` sein; positionsweiser Vergleich case-insensitiv und getrimmt.                                          |
| alle anderen `_`  | `evaluateFreeInput`        | Fallback (case-insensitiv + getrimmt).                                                                                          |

### Wann Templates selbst evaluieren

Templates, die `TaskType.interactive` oder `TaskType.tapRhythm` verwenden (z.B. `ClockTemplate`, `MoneyTemplate`, `FractionTemplate`, `SyllableCountTemplate`), implementieren `TaskTemplate.evaluate` selbst. In der aktuellen Implementierung ruft `DefaultLearningEngine.evaluateTask` jedoch ausschließlich `Evaluator.evaluate` auf — diese Typen landen damit im `_`-Zweig (Fallback auf `evaluateFreeInput`). Die Widgets dieser Typen liefern ihre Antworten in einem Format, das der String-Vergleich in `evaluateFreeInput` korrekt auflöst.

---

## 4. Schwierigkeitssteuerung (Difficulty & Elo)

Die Steuerung der Aufgabenschwierigkeit im Standardpfad erfolgt über Elo:
`DefaultLearningEngine.initialDifficulty` nutzt das gespeicherte Elo-Rating als
Einstieg, `DefaultLearningEngine.nextDifficulty` liest nach gespeicherten
Antworten den aktuellen Elo-Stand für die In-Session-Anpassung.

### Initialschwierigkeit (Einstieg)

Die Einstiegsstufe für ein Thema wird beim Session-Start in `DefaultLearningEngine.initialDifficulty` festgelegt. Sie basiert auf dem aktuellen Elo-Rating des Kindes für das spezifische Thema:

```dart
// DefaultLearningEngine
@override
int initialDifficulty({required TopicProgress progress, required int grade}) {
  return EloDifficultyEngine.recommendDifficulty(progress.eloRating);
}
```

Die `EloDifficultyEngine` (in `lib/core/engine/elo_difficulty_engine.dart`) empfiehlt eine Schwierigkeit (1–5) basierend auf dem Elo-Wert. Das alte Modell (basierend auf `accuracy` und `grade`) wird nicht mehr verwendet.

### In-Session-Anpassung (nextDifficulty)

Die `DefaultLearningEngine` nutzt das Elo-Rating für die dynamische Anpassung während einer Session. Da `recordResult` nach jeder Antwort aufgerufen wird, kann `nextDifficulty` den aktuellsten Elo-Stand aus dem Storage abrufen und die passende Schwierigkeit empfehlen:

```dart
@override
int nextDifficulty({
  required List<int> recentResults,
  required int currentDifficulty,
  String? profileId,
  Subject? subject,
  int? grade,
  String? topic,
}) {
  if (profileId != null && topic != null /* ... */) {
    final progress = _storage.getProgress(...);
    return EloDifficultyEngine.recommendDifficulty(progress.eloRating);
  }
  // Fallback: Virtuelle Elo-Fortschreibung
  return _calculateVirtualDifficulty(...);
}
```

Die Anpassung ist somit vollständig konsistent zum Elo-System: Ein Kind, dessen Rating durch eine Serie richtiger Antworten über eine Schwelle (z.B. 1100) steigt, erhält für die nächste Aufgabe automatisch eine höhere Schwierigkeitsstufe.

---

## 5. DifficultyEngine (Algorithmus-Referenz)

**Datei:** `lib/core/engine/difficulty.dart`

Enthält die (derzeit nicht aktiv in Sessions genutzte) Logik für adaptive Schwierigkeitsanpassung. 

**Datei:** `lib/core/engine/curriculum.dart`

Steuert welche Themen in welcher Reihenfolge erscheinen und welche Varianten gelehrt werden (z.B. Schreibschrift vs. Druckschrift). Wird mit einem Bundesland-Code instanziiert: `Curriculum('BY')`.

### Alle 18 Bundesländer/Länder (`kFederalStates`)

| Kürzel | Name                     |
|--------|--------------------------|
| `BY`   | Bayern                   |
| `BW`   | Baden-Württemberg        |
| `NW`   | Nordrhein-Westfalen      |
| `NI`   | Niedersachsen            |
| `HE`   | Hessen                   |
| `SN`   | Sachsen                  |
| `ST`   | Sachsen-Anhalt           |
| `TH`   | Thüringen                |
| `BB`   | Brandenburg              |
| `MV`   | Mecklenburg-Vorpommern   |
| `SH`   | Schleswig-Holstein       |
| `HH`   | Hamburg                  |
| `BE`   | Berlin                   |
| `HB`   | Bremen                   |
| `SL`   | Saarland                 |
| `RP`   | Rheinland-Pfalz          |
| `AT`   | Österreich               |
| `CH`   | Schweiz                  |

### Bundesland-spezifische Varianten

| Property            | Typ    | Wert `true`/erhöht für          | Wert `false`/standard für alle anderen |
|---------------------|--------|---------------------------------|-----------------------------------------|
| `teachesCursiveEarly` | `bool` | `BY`, `BW`, `RP` — lehren Schreibschrift (SAS) früher | alle anderen Bundesländer |
| `timestablesGrade`  | `int`  | `SH`, `MV` → `3` (Einmaleins ab Kl.3) | alle anderen → `2` (Einmaleins ab Kl.2) |

### Themenreihenfolge Mathe

| Klasse | Themen (in Reihenfolge)                                                                                                                           |
|--------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| 1      | `zahlen_bis_10`, `zahlen_bis_20`, `addition_bis_10`, `subtraktion_bis_10`, `groesser_kleiner`, `zahlenmauern`, `formen`, `zahlenreihen`, `muster` |
| 2      | `addition_bis_100`, `subtraktion_bis_100`, `einmaleins`, `uhrzeit`, `geld`, `zahlenmauern`, `rechenketten`, `textaufgaben`                       |
| 3      | `schriftliche_addition`, `schriftliche_subtraktion`, `multiplikation`, `division_mit_rest`, `groessen_umrechnen`, `geometrie`, `textaufgaben_3`  |
| 4      | `schriftliche_multiplikation`, `schriftliche_division`, `brueche`, `dezimalzahlen`, `diagramme`, `grosse_zahlen`, `sachaufgaben_4`               |

### Themenreihenfolge Deutsch

| Klasse | Themen (in Reihenfolge)                                                                                                                                      |
|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1      | `buchstaben`, `anlaute`, `silben`, `woerter_lesen`, `reimwoerter`, `lueckenwoerter`, `buchstaben_salat`, `handschrift`                                       |
| 2      | `artikel`, `wortarten`, `einzahl_mehrzahl`, `rechtschreibung_ie_ei`, `abc_sortieren`, `saetze_bilden`, `lesetext`                                            |
| 3      | `zeitformen`, `wortfamilien`, `zusammengesetzte_nomen`, `satzarten`, `diktat`, `lernwoerter`                                                                 |
| 4      | `vier_faelle`, `satzglieder`, `das_dass`, `woertliche_rede`, `fehlertext`, `kommasetzung`, `textarten`                                                       |

### World-1-Kapitelplanung und Implementierungsstatus

Die Kapitelplanung ist fachliche Produktplanung fuer Klasse 1. Die
Curriculum-Liste oben zeigt nur Topics, die im aktuellen Themenkatalog
adressierbar sind. Weitere Methoden sind Konzept-/Planungsstand, bis ein
Template, eine UI-Darstellung und passende Aufgaben-/Wortdaten vorliegen.

| Kapitel | Fachliche Themen | Aktueller technischer Status |
|---------|------------------|------------------------------|
| Kapitel 1 – frühe Grundlagen | `buchstaben`, `anlaute`, `zahlen_bis_10`, `silben`, `zahlen_bis_20` | alle als Klasse-1-Topics/Templates angelegt; die produktive Quest-Slice nutzt noch nicht jeden Zielbaustein einzeln |
| Kapitel 2 – erste Vertiefung | `addition_bis_10`, `subtraktion_bis_10`, `zahlenmauern`, `reimwoerter`, `lueckenwoerter`, Lautsynthese, Sichtwortschatz/Blitzlesen, erste lauttreue Woerter | die genannten Topic-Strings sind bis auf Lautsynthese/Blitzlesen/lauttreue Woerter angelegt; `zahlenmauern` ist fuer Klasse 1 registriert und wird in Klasse 2 weitergefuehrt |
| Kapitel 3 – Transfer und Struktur | `formen`, `zahlenreihen`, `muster`, `handschrift`, `buchstaben_salat`, Raumorientierung/Lagebeziehungen, Zahlenstrahl/Nachbarzahlen, Buchstabenverbindungen, Satzgrenzen/Satzschlusszeichen, kleine Schreibimpulse | die Topic-Strings `formen`, `zahlenreihen`, `muster`, `handschrift`, `buchstaben_salat` sind angelegt; die weiteren Methoden sind noch Konzept-/Planungsstand |

## 7. Handschrift-Erkennung & ML-Pipeline

Die Erkennung handgeschriebener Buchstaben erfolgt in einer mehrstufigen Pipeline, um sowohl offline-Fähigkeit als auch hohe Robustheit gegen "Gekritzel" zu gewährleisten.

### Vorverarbeitung (Preprocessing)
**Datei:** `lib/core/services/tflite_service.dart`

Bevor eine Analyse stattfindet, werden die vom Kind gezeichneten Striche (`List<List<Offset>>`) in einen normalisierten 28x28 Graustufen-Tensor (`Float32List`) umgewandelt:
1. **Rasterung:** Die Koordinaten werden auf ein 28x28 Gitter gemappt.
2. **Interpolation:** Zwischen aufeinanderfolgenden Punkten eines Strichs werden Linien gezogen, um Lücken im Raster zu schließen.
3. **Normalisierung:** Die Pixelwerte liegen zwischen 0.0 (Hintergrund) und 1.0 (Strich).

### Formprüfung via Target-Grids (Heuristik)
**Datei:** `lib/features/exercise/widgets/handwriting_widget.dart`

Für Vokale (A, E, I, O, U) wird eine geometrische Formprüfung durchgeführt, die ohne ein schweres ML-Modell auskommt:
- **Hit-Rate:** Es wird geprüft, ob die Striche des Kindes vordefinierte Zielpunkte (5x5 Matrix) des Buchstabens passieren. Ein Erfolg erfordert eine Trefferquote von ≥ 60%.
- **Scribble-Schutz (Miss-Penalty):** Um zu verhindern, dass die Aufgabe durch bloßes Ausmalen der Fläche gelöst wird, werden Pixel außerhalb der Idealform als Fehler gezählt. Übersteigt die Anzahl der Fehler einen Schwellenwert (40 Pixel), wird die Eingabe abgelehnt.

### Zukünftige ML-Inferenz
Der `TFLiteService` ist darauf vorbereitet, den 28x28 Tensor an ein On-Device Modell (`.tflite`) zu übergeben, um auch komplexe Konsonanten und freie Schreibstile zu erkennen. Ein entsprechender Trainings-Workflow für neue Modelle befindet sich im Ordner `ml_training/`.
