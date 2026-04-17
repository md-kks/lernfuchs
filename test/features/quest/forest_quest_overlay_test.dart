import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/models/task_model.dart';
import 'package:lernfuchs/features/quest/forest_quest_overlay.dart';

void main() {
  test('zahlen_bis_20 word answers use tappable text choices', () {
    final task = TaskModel(
      id: 'word-answer',
      subject: 'math',
      grade: 1,
      topic: 'zahlen_bis_20',
      question: 'Schreibe das Wort fuer die Zahl: 7',
      taskType: TaskType.freeInput.name,
      correctAnswer: 'sieben',
      metadata: const {'number': 7, 'word': 'sieben', 'showWord': false},
    );

    final choices = forestQuestNumberTextChoices(task);

    expect(forestQuestNumberTaskUsesTextChoices(task), isTrue);
    expect(choices, contains('sieben'));
    expect(choices, hasLength(4));
  });

  test('zahlen_bis_20 numeric answers keep number stone input', () {
    final task = TaskModel(
      id: 'numeric-answer',
      subject: 'math',
      grade: 1,
      topic: 'zahlen_bis_20',
      question: 'Welche Zahl ist sieben?',
      taskType: TaskType.freeInput.name,
      correctAnswer: 7,
      metadata: const {'number': 7, 'word': 'sieben', 'showWord': true},
    );

    expect(forestQuestNumberTaskUsesTextChoices(task), isFalse);
  });
}
