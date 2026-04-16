# Exercise Widgets

Reference for coding agents. All 16 answer widgets live in
`lib/features/exercise/widgets/` and are dispatched by `LearningAnswerWidget`
in `lib/features/exercise/learning_challenge_session.dart`.

---

## 1. Widget Interface

Every answer widget shares the same constructor signature:

```dart
class XxxWidget extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;
  const XxxWidget({super.key, required this.task, required this.onChanged});
}
```

Key conventions:

- `task.metadata` carries all widget-specific payload (choices, dotCount, text, …).
- `onChanged` is called whenever the user selects or enters an answer. The value
  type depends on the widget (see table below).
- **No submit button inside the widget.** The "Prüfen" button is owned by
  `_SessionContent` in `LearningChallengeSession` and is enabled only when
  `pendingAnswer != null`.

---

## 2. Dispatch Logic (`LearningAnswerWidget`)

Source: `lib/features/exercise/learning_challenge_session.dart`, lines 329–406.

```dart
// 1. interactive — topic-keyed before anything else
if (type == TaskType.interactive) {
  if (topic == 'uhrzeit')  return ClockWidget(...);
  if (topic == 'geld')     return MoneyWidget(...);
  if (topic == 'brueche')  return FractionWidget(...);
  return FreeInputWidget(...);          // interactive fallback
}

// 2. freeInput — specialised variants first, generic last
if (type == TaskType.freeInput) {
  if ((topic == 'zahlen_bis_10' || topic == 'zahlen_bis_20')
      && task.metadata.containsKey('dotCount'))
    return DotCountWidget(...);
  if (topic == 'zahlenmauern')
    return NumberWallWidget(...);
  if ((topic == 'schriftliche_addition'   ||
       topic == 'schriftliche_subtraktion' ||
       topic == 'schriftliche_multiplikation' ||
       topic == 'schriftliche_division')
      && task.metadata['showSteps'] == true)
    return WrittenCalculationWidget(...);
  if (topic == 'diktat')
    return DictationWidget(...);
  return FreeInputWidget(...);          // freeInput fallback
}

// 3. multipleChoice / lesetext — checked before the switch
if (type == TaskType.multipleChoice && topic == 'lesetext')
  return ReadingTextWidget(...);

// 4. switch on remaining types
return switch (type) {
  TaskType.multipleChoice =>
    topic == 'diagramme'
        ? BarChartWidget(...)
        : task.metadata.containsKey('visible')
            ? PatternWidget(...)
            : MultipleChoiceWidget(...),
  TaskType.ordering =>
    topic == 'buchstaben_salat'
        ? LetterOrderingWidget(...)
        : OrderingWidget(...),
  TaskType.tapRhythm =>
    topic == 'silben'
        ? SyllableTapWidget(...)
        : task.metadata.containsKey('visible')
            ? PatternWidget(...)
            : FreeInputWidget(...),
  TaskType.handwriting => HandwritingWidget(...),
  _                    => FreeInputWidget(...),  // catch-all
};
```

Dispatch priority summary: **interactive → freeInput → multipleChoice/lesetext → switch(type)**

---

## 3. Widget Table

| Widget-Datei | TaskType | Topic / Bedingung | Antwortformat | Implementiert |
|---|---|---|---|---|
| `free_input_widget.dart` | `freeInput` | Standard-Fallback (auch interactive- und tapRhythm-Fallback) | `String` / `int` / `double` | Ja |
| `multiple_choice_widget.dart` | `multipleChoice` | Standard (kein `visible`-Key, kein `diagramme`, kein `lesetext`) | Wert aus `choices` | Ja |
| `ordering_widget.dart` | `ordering` | Sätze / Wörter ordnen (topic ≠ `buchstaben_salat`) | `List<String>` | Ja |
| `letter_ordering_widget.dart` | `ordering` | topic == `buchstaben_salat` | `List<String>` | Ja |
| `pattern_widget.dart` | `multipleChoice` oder `tapRhythm` | `metadata.containsKey('visible')` | Wert aus `choices` | Ja |
| `bar_chart_widget.dart` | `multipleChoice` | topic == `diagramme` | Wert aus `choices` | Ja |
| `reading_text_widget.dart` | `multipleChoice` | topic == `lesetext` | Wert aus `choices` | Ja |
| `syllable_tap_widget.dart` | `tapRhythm` | topic == `silben` | `int` (Anzahl Taps) | Ja |
| `dot_count_widget.dart` | `freeInput` | topic == `zahlen_bis_10` oder `zahlen_bis_20` **und** `metadata.containsKey('dotCount')` | `int` | Ja |
| `number_wall_widget.dart` | `freeInput` | topic == `zahlenmauern` | `Map` oder aufgabenspezifisch | Ja |
| `written_calculation_widget.dart` | `freeInput` | topic in `schriftliche_{addition,subtraktion,multiplikation,division}` **und** `metadata['showSteps'] == true` | `int` | Ja |
| `dictation_widget.dart` | `freeInput` | topic == `diktat` | `String` | Ja |
| `clock_widget.dart` | `interactive` | topic == `uhrzeit` | `String` (Format `HH:MM`) | Ja |
| `money_widget.dart` | `interactive` | topic == `geld` | `double` (Eurobetrag) | Ja |
| `fraction_widget.dart` | `interactive` | topic == `brueche` | `String` (z.B. `"1/2"`) | Ja |
| `handwriting_widget.dart` | `handwriting` | — (Phase 4 Placeholder) | — | Nein (Phase 4) |

---

## 4. TaskType Enum

Source: `lib/core/models/task_model.dart`, lines 15–25.

| Wert | Primäres Widget | Status |
|---|---|---|
| `freeInput` | `FreeInputWidget` (+ Varianten) | Implementiert |
| `multipleChoice` | `MultipleChoiceWidget` (+ Varianten) | Implementiert |
| `ordering` | `OrderingWidget` / `LetterOrderingWidget` | Implementiert |
| `tapRhythm` | `SyllableTapWidget` / `PatternWidget` | Implementiert |
| `interactive` | `ClockWidget` / `MoneyWidget` / `FractionWidget` | Implementiert |
| `gapFill` | `FreeInputWidget` (Catch-all) | Implementiert (via Fallback) |
| `handwriting` | `HandwritingWidget` | Phase 4 |
| `dragDrop` | — | Phase 4 |
| `matching` | — | Phase 4 |

---

## 5. TaskModel.metadata — Typische Schlüssel

Source: `lib/core/models/task_model.dart`, lines 63–73.

| Schlüssel | Typ | Genutzt von | Bedeutung |
|---|---|---|---|
| `choices` | `List<String>` | `MultipleChoiceWidget`, `BarChartWidget`, `ReadingTextWidget`, `PatternWidget` | Auswahloptionen für Multiple-Choice-Aufgaben |
| `dotCount` | `int` | `DotCountWidget` | Anzahl der darzustellenden Punkte; löst DotCount-Dispatch aus |
| `text` | `String` | `ReadingTextWidget` | Lesetext für Leseverständnis-Aufgaben |
| `word` | `String` | `DictationWidget` | Das zu diktierende Wort (intern, nicht angezeigt) |
| `displayedWord` | `String` | `DictationWidget` | Das sichtbar angezeigte Wort (bei `showThenHide`) |
| `showThenHide` | `bool` | `DictationWidget` | Wort kurz anzeigen, dann verdecken |
| `showSteps` | `bool` | `WrittenCalculationWidget` | Schriftliche Rechenschritte einblenden; löst WrittenCalculation-Dispatch aus |
| `visible` | `dynamic` | `PatternWidget` | Vorhanden → PatternWidget statt MultipleChoice/FreeInput für multipleChoice- und tapRhythm-Tasks |
