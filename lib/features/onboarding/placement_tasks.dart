import '../../core/models/task_model.dart';

class PlacementTaskDefinition {
  final TaskModel task;
  final String competencyId;
  final double difficulty;

  const PlacementTaskDefinition({
    required this.task,
    required this.competencyId,
    required this.difficulty,
  });
}

final placementTasks = <PlacementTaskDefinition>[
  PlacementTaskDefinition(
    competencyId: 'zahlen_bis_10',
    difficulty: 200,
    task: TaskModel(
      id: 'placement_dot_3',
      subject: 'math',
      grade: 1,
      topic: 'zahlen_bis_10',
      question: 'Wie viele Punkte siehst du?',
      taskType: 'freeInput',
      correctAnswer: 3,
      metadata: {'dotCount': 3, 'choices': [2, 3, 4, 5]},
    ),
  ),
  PlacementTaskDefinition(
    competencyId: 'buchstaben',
    difficulty: 400,
    task: TaskModel(
      id: 'placement_apfel',
      subject: 'german',
      grade: 1,
      topic: 'buchstaben',
      question: "Mit welchem Buchstaben fängt 'Apfel' an?",
      taskType: 'multipleChoice',
      correctAnswer: 'A',
      metadata: {'choices': ['M', 'A', 'B', 'T']},
    ),
  ),
  PlacementTaskDefinition(
    competencyId: 'addition_bis_10',
    difficulty: 600,
    task: TaskModel(
      id: 'placement_3_plus_5',
      subject: 'math',
      grade: 1,
      topic: 'addition_bis_10',
      question: '3 + 5 = ?',
      taskType: 'freeInput',
      correctAnswer: 8,
    ),
  ),
  PlacementTaskDefinition(
    competencyId: 'multiplikation_1x1',
    difficulty: 800,
    task: TaskModel(
      id: 'placement_7_mal_4',
      subject: 'math',
      grade: 2,
      topic: 'einmaleins',
      question: '7 × 4 = ?',
      taskType: 'multipleChoice',
      correctAnswer: 28,
      metadata: {'choices': [24, 28, 32, 21]},
    ),
  ),
  PlacementTaskDefinition(
    competencyId: 'silben',
    difficulty: 900,
    task: TaskModel(
      id: 'placement_schmetterling',
      subject: 'german',
      grade: 1,
      topic: 'silben',
      question: "Wie viele Silben hat 'Schmetterling'?",
      taskType: 'tapRhythm',
      correctAnswer: 3,
      metadata: {'word': 'Schmetterling', 'choices': [2, 3, 4, 5]},
    ),
  ),
];

const placementCompetencies = [
  'zahlen_bis_10',
  'buchstaben',
  'addition_bis_10',
  'multiplikation_1x1',
  'silben',
  'zahlen_bis_20',
  'muster',
  'anlaute',
];
