import 'dart:math';
import '../models/task_model.dart';
import '../models/subject.dart';

/// Basisklasse für alle Aufgaben-Templates.
///
/// Jede konkrete Unterklasse repräsentiert **einen Aufgabentyp** (z.B.
/// `AdditionTemplate`, `VerbTenseTemplate`) und kann beliebig viele
/// algorithmisch verschiedene Aufgaben desselben Typs erzeugen.
///
/// ### Registrierung
/// Alle Templates werden in [TaskGenerator._init] einmalig instanziiert und
/// unter dem Schlüssel `"<subject.id>_<grade>_<topic>"` registriert.
///
/// ### Implementierungspflicht
/// Unterklassen müssen zwingend implementieren:
/// - [generate] — neue Aufgabe auf Basis von Schwierigkeitsgrad + RNG
/// - [evaluate] — prüft eine Kinderantwort gegen [TaskModel.correctAnswer]
/// - [displayName] — lesbarer Name für UI / Fortschrittsanzeige
abstract class TaskTemplate {
  /// Eindeutiger Bezeichner, identisch mit [topic].
  final String id;

  /// Zugehöriges Schulfach.
  final Subject subject;

  /// Klassenstufe 1–4.
  final int grade;

  /// Themenbezeichner, der auch als URL-Segment in der Navigation genutzt wird.
  /// Beispiele: `"addition_bis_20"`, `"zeitformen"`, `"diktat"`.
  final String topic;

  /// Minimaler unterstützter Schwierigkeitsgrad (Standard: 1).
  final int minDifficulty;

  /// Maximaler unterstützter Schwierigkeitsgrad (Standard: 5).
  final int maxDifficulty;

  const TaskTemplate({
    required this.id,
    required this.subject,
    required this.grade,
    required this.topic,
    this.minDifficulty = 1,
    this.maxDifficulty = 5,
  });

  /// Generiert eine neue, algorithmisch zufällige Aufgabe.
  ///
  /// [difficulty] liegt typischerweise zwischen [minDifficulty] und
  /// [maxDifficulty] und wird vom [DifficultyEngine] berechnet.
  /// [rng] ist der zentrale Zufallsgenerator der Session — bei gleichem
  /// Seed sind alle Aufgaben einer Session reproduzierbar.
  TaskModel generate(int difficulty, Random rng);

  /// Bewertet eine Kinderantwort gegen [TaskModel.correctAnswer].
  ///
  /// Gibt `true` zurück, wenn die Antwort als korrekt gilt.
  /// Unterklassen implementieren hier aufgabenspezifische Logik
  /// (z.B. Groß-/Kleinschreibung ignorieren, Trimmen, Listenvergleich).
  bool evaluate(TaskModel task, dynamic userAnswer);

  /// Menschenlesbarer Name für Fortschrittsanzeige und Auswahl-UI.
  String get displayName;

  /// Gibt an, ob [difficulty] von diesem Template unterstützt wird.
  bool supportsDifficulty(int difficulty) =>
      difficulty >= minDifficulty && difficulty <= maxDifficulty;

  /// Erzeugt eine einmalige zufällige Task-ID.
  String _generateId(Random rng) => '${id}_${rng.nextInt(1000000)}';

  /// Hilfsmethode: Baut ein [TaskModel] mit allen Pflichtfeldern.
  ///
  /// Spart Boilerplate in allen Unterklassen — stellt sicher, dass
  /// [subject], [grade] und [topic] immer korrekt gesetzt sind.
  TaskModel makeTask({
    required Random rng,
    required int difficulty,
    required String question,
    required dynamic correctAnswer,
    required TaskType type,
    Map<String, dynamic> metadata = const {},
  }) {
    return TaskModel(
      id: _generateId(rng),
      subject: subject.id,
      grade: grade,
      topic: topic,
      question: question,
      taskType: type.name,
      correctAnswer: correctAnswer,
      metadata: metadata,
      difficulty: difficulty,
    );
  }
}
