/// Aufgabentypen — bestimmen, welches Widget in [ExerciseScreen] gerendert wird
/// und wie [Evaluator] die Antwort bewertet.
///
/// | Typ             | Widget                    | Antwortformat               |
/// |-----------------|---------------------------|-----------------------------|
/// | freeInput       | FreeInputWidget           | String / int / double       |
/// | multipleChoice  | MultipleChoiceWidget      | beliebiger Wert aus choices |
/// | ordering        | OrderingWidget            | List<String>                |
/// | tapRhythm       | SyllableTapWidget         | int (Anzahl Silben)         |
/// | gapFill         | FreeInputWidget           | List<String>                |
/// | interactive     | Clock-/Money-/FractionWidget | aufgabenspezifisch       |
/// | dragDrop        | (Phase 4)                 | —                           |
/// | handwriting     | (Phase 4)                 | —                           |
/// | matching        | (Phase 4)                 | —                           |
enum TaskType {
  freeInput,
  multipleChoice,
  dragDrop,
  handwriting,
  tapRhythm,
  ordering,
  gapFill,
  matching,
  interactive,
}

/// Eine einzelne generierte Aufgabe.
///
/// Wird von [TaskTemplate.makeTask] erzeugt und ist danach unveränderlich.
/// Alle aufgabenspezifischen Zusatzdaten (Auswahlmöglichkeiten, Bilder-Emojis,
/// Rechenschritte usw.) liegen in [metadata].
///
/// ### Persistenz
/// [TaskModel] wird **nicht** dauerhaft gespeichert — nur der Lernfortschritt
/// ([TopicProgress]) landet in SharedPreferences. Die Aufgaben werden bei
/// jeder Session neu algorithmisch generiert (reproduzierbar via [seed]).
class TaskModel {
  /// Eindeutiger Bezeichner innerhalb einer Session (zufällig generiert).
  final String id;

  /// Fach-ID, identisch mit [Subject.id] (`"math"` oder `"german"`).
  final String subject;

  /// Klassenstufe 1–4.
  final int grade;

  /// Themenbezeichner, z.B. `"addition_bis_20"` oder `"zeitformen"`.
  /// Muss mit dem [TaskTemplate.topic] des erzeugenden Templates übereinstimmen.
  final String topic;

  /// Aufgabentext, der dem Kind angezeigt wird.
  final String question;

  /// Name des [TaskType]-Enum-Wertes (gespeichert als String für JSON-Kompatibilität).
  final String taskType;

  /// Die korrekte Antwort — Typ hängt von [taskType] ab:
  /// - `freeInput`: String oder int
  /// - `multipleChoice`: Wert aus [metadata]`['choices']`
  /// - `ordering`: String (Wörter durch Leerzeichen getrennt) oder List
  /// - `tapRhythm`: int (Silbenzahl)
  final dynamic correctAnswer;

  /// Aufgabenspezifische Zusatzdaten.
  ///
  /// Typische Schlüssel je Typ:
  /// - `choices`: List<String> — Auswahloptionen für Multiple-Choice
  /// - `word`, `displayedWord`: für Diktat/Lückenwörter
  /// - `text`: Lesetext für ReadingComprehension
  /// - `dotCount`: Punkte-Anzahl für CountDots
  /// - `showSteps`: bool — zeigt schriftliche Rechenschritte an
  /// - `showThenHide`: bool — Wort kurz anzeigen, dann verdecken (Diktat)
  final Map<String, dynamic> metadata;

  /// Schwierigkeitsgrad 1–5, übergeben vom [DifficultyEngine].
  final int difficulty;

  /// Optionaler Zufallsseed — bei gleichem Seed reproduzierbare Aufgabe.
  final int? seed;

  TaskModel({
    required this.id,
    required this.subject,
    required this.grade,
    required this.topic,
    required this.question,
    required this.taskType,
    required this.correctAnswer,
    this.metadata = const {},
    this.difficulty = 1,
    this.seed,
  });

  /// Serialisiert die Aufgabe als JSON-Map (für Debugging / Logging).
  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'grade': grade,
        'topic': topic,
        'question': question,
        'taskType': taskType,
        'correctAnswer': correctAnswer,
        'metadata': metadata,
        'difficulty': difficulty,
        'seed': seed,
      };
}
