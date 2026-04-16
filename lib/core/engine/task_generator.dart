import 'dart:math';
import '../models/task_model.dart';
import '../models/subject.dart';
import 'task_template.dart';
import 'templates/math_basic_templates.dart';
import 'templates/math_grade1_templates.dart';
import 'templates/math_grade2_templates.dart';
import 'templates/math_grade3_templates.dart';
import 'templates/math_grade4_templates.dart';
import 'templates/german_basic_templates.dart';
import 'templates/german_grade1_templates.dart';
import 'templates/german_grade2_templates.dart';
import 'templates/german_grade3_templates.dart';
import 'templates/german_grade4_templates.dart';

/// Zentrales Template-Register und Session-Generator.
///
/// Hält alle [TaskTemplate]-Instanzen in einer Flat-Map mit dem Schlüssel
/// `"<subject.id>_<grade>_<topic>"` (z.B. `"math_2_uhrzeit"`).
///
/// ### Nutzung
/// ```dart
/// final tasks = TaskGenerator.generateSession(
///   subject: Subject.math,
///   grade: 3,
///   topic: 'schriftliche_addition',
///   difficulty: 2,
///   count: 10,
/// );
/// ```
///
/// ### Erweiterung
/// Ein neues Template hinzufügen:
/// 1. Template-Klasse in einer `templates/`-Datei implementieren.
/// 2. `_register(const MeineTemplate())` in `_init()` eintragen.
/// Das Template ist sofort über [generateSession] verfügbar.
class TaskGenerator {
  TaskGenerator._();

  /// Interne Flat-Map: `"<subject>_<grade>_<topic>"` → [TaskTemplate].
  static final _templates = <String, TaskTemplate>{};
  static bool _initialized = false;

  /// Einmalige Initialisierung — wird lazy beim ersten Zugriff aufgerufen.
  static void _init() {
    if (_initialized) return;
    _initialized = true;

    // ── Mathe Kl.1 ──────────────────────────────────────────────
    _register(const CountDotsTemplate());
    _register(const NumberWritingTemplate());
    _register(const AdditionTemplate(grade: 1));
    _register(const SubtractionTemplate(grade: 1));
    _register(const ComparisonTemplate());
    _register(const NumberSequenceTemplate());
    _register(const ShapeRecognitionTemplate());
    _register(const PatternContinuationTemplate());

    // ── Mathe Kl.2 ──────────────────────────────────────────────
    _register(const AdditionTemplate(grade: 2));
    _register(const SubtractionTemplate(grade: 2));
    _register(const TimesTableTemplate());
    _register(const ClockTemplate());
    _register(const MoneyTemplate());
    _register(const NumberWallTemplate());
    _register(const CalculationChainTemplate());
    _register(const WordProblemGrade2Template());

    // ── Mathe Kl.3 ──────────────────────────────────────────────
    _register(const WrittenAdditionTemplate());
    _register(const WrittenSubtractionTemplate());
    _register(const SemiWrittenMultiplicationTemplate());
    _register(const DivisionWithRemainderTemplate());
    _register(const UnitConversionTemplate());
    _register(const GeometryTemplate());
    _register(const WordProblemGrade3Template());

    // ── Mathe Kl.4 ──────────────────────────────────────────────
    _register(const WrittenMultiplicationTemplate());
    _register(const WrittenDivisionTemplate());
    _register(const FractionTemplate());
    _register(const DecimalNumberTemplate());
    _register(const DiagramReadingTemplate());
    _register(const LargeNumbersTemplate());
    _register(const WordProblemGrade4Template());

    // ── Deutsch Kl.1 ──────────────────────────────────────────
    _register(const LetterRecognitionTemplate());
    _register(const InitialSoundTemplate());
    _register(const SyllableCountTemplate());
    _register(const RhymeTemplate());
    _register(const MissingLetterTemplate());
    _register(const AnagramTemplate());
    _register(const HandwritingTemplate());

    // ── Deutsch Kl.2 ──────────────────────────────────────────
    _register(const ArticleTemplate());
    _register(const PluralTemplate());
    _register(const AlphabetSortTemplate());
    _register(const WordTypeTemplate());
    _register(const IeEiTemplate());
    _register(const SentenceFormationTemplate());
    _register(const ReadingComprehensionTemplate());

    // ── Deutsch Kl.3 ──────────────────────────────────────────
    _register(const VerbTenseTemplate());
    _register(const WordFamilyTemplate());
    _register(const CompoundNounTemplate());
    _register(const SentenceTypeTemplate());
    _register(const DictationTemplate());
    _register(const SightWordTemplate());

    // ── Deutsch Kl.4 ──────────────────────────────────────────
    _register(const DasDassTemplate());
    _register(const CaseTemplate());
    _register(const SentenceElementTemplate());
    _register(const DirectSpeechTemplate());
    _register(const ErrorTextTemplate());
    _register(const CommaPunctuationTemplate());
    _register(const TextTypeTemplate());
  }

  /// Registriert ein Template unter dem Schlüssel `"<subject>_<grade>_<topic>"`.
  static void _register(TaskTemplate t) {
    _templates['${t.subject.id}_${t.grade}_${t.topic}'] = t;
  }

  /// Generiert eine Session mit [count] Aufgaben für das angegebene Thema.
  ///
  /// Wirft [ArgumentError], wenn kein Template für `subject + grade + topic`
  /// registriert ist. Bei identischem [seed] sind alle Aufgaben reproduzierbar
  /// (nützlich für Debugging und Tests).
  static List<TaskModel> generateSession({
    required Subject subject,
    required int grade,
    required String topic,
    required int difficulty,
    int count = 10,
    int? seed,
  }) {
    _init();
    final key = '${subject.id}_${grade}_$topic';
    final template = _templates[key];
    if (template == null) {
      throw ArgumentError('Kein Template für: $key');
    }
    final rng = seed != null ? Random(seed) : Random();
    return List.generate(count, (_) => template.generate(difficulty, rng));
  }

  /// Generiert eine verschachtelte Session (Interleaved Practice) aus verschiedenen Themen.
  ///
  /// Jede Aufgabe wird zufällig aus den verfügbaren [topics] ausgewählt.
  static List<TaskModel> generateInterleavedSession({
    required List<({Subject subject, int grade, String topic})> topics,
    required int difficulty,
    int count = 10,
    int? seed,
  }) {
    _init();
    if (topics.isEmpty) return [];
    final rng = seed != null ? Random(seed) : Random();

    return List.generate(count, (_) {
      final t = topics[rng.nextInt(topics.length)];
      final key = '${t.subject.id}_${t.grade}_${t.topic}';
      final template = _templates[key];
      if (template == null) return null;
      return template.generate(difficulty, rng);
    }).whereType<TaskModel>().toList();
  }

  /// Gibt alle registrierten Templates für ein bestimmtes Fach und eine Klasse zurück.
  ///
  /// Genutzt von [SubjectOverviewScreen] um die Themenauswahl aufzubauen.
  static List<TaskTemplate> templatesFor(Subject subject, int grade) {
    _init();
    return _templates.values
        .where((t) => t.subject == subject && t.grade == grade)
        .toList();
  }

  /// Gibt ein einzelnes Template zurück — primär für Unit-Tests.
  ///
  /// Gibt `null` zurück, wenn kein Template gefunden wird.
  static TaskTemplate? template(Subject subject, int grade, String topic) {
    _init();
    return _templates['${subject.id}_${grade}_$topic'];
  }
}
