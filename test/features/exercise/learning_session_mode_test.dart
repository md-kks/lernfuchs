import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/features/exercise/learning_session_mode.dart';

void main() {
  test('learning challenge exposes all supported session modes', () {
    expect(
      LearningSessionMode.values,
      containsAll([
        LearningSessionMode.freePractice,
        LearningSessionMode.questSingle,
        LearningSessionMode.questMiniSeries,
        LearningSessionMode.dailyPath,
      ]),
    );
  });

  test('challenge result reports success only when all tasks are correct', () {
    const success = LearningChallengeResult(
      mode: LearningSessionMode.questSingle,
      grade: 1,
      subjectId: 'math',
      topic: 'addition_bis_10',
      correctCount: 1,
      totalCount: 1,
    );
    const retry = LearningChallengeResult(
      mode: LearningSessionMode.questSingle,
      grade: 1,
      subjectId: 'math',
      topic: 'addition_bis_10',
      correctCount: 0,
      totalCount: 1,
    );

    expect(success.successful, isTrue);
    expect(retry.successful, isFalse);
  });
}
