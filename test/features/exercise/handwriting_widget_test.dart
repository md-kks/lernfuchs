import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/models/task_model.dart';
import 'package:lernfuchs/features/exercise/widgets/handwriting_widget.dart';

void main() {
  testWidgets('HandwritingWidget displays letter and guidelines', (WidgetTester tester) async {
    final task = TaskModel(
      id: 'h1',
      subject: 'german',
      grade: 1,
      topic: 'handschrift',
      question: 'Schreibe A',
      correctAnswer: 'traced',
      taskType: TaskType.handwriting.name,
      metadata: {'letter': 'A', 'word': 'Apfel'},
      difficulty: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HandwritingWidget(
              task: task,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('Fahre mit dem Finger den Buchstaben nach!'), findsOneWidget);
  });

  testWidgets('HandwritingWidget clear button works', (WidgetTester tester) async {
    final task = TaskModel(
      id: 'h1',
      subject: 'german',
      grade: 1,
      topic: 'handschrift',
      question: 'Schreibe A',
      correctAnswer: 'traced',
      taskType: TaskType.handwriting.name,
      metadata: {'letter': 'A', 'word': 'Apfel'},
      difficulty: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HandwritingWidget(
              task: task,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    // Initial state: clear button disabled
    final clearButton = find.byType(TextButton);
    expect(tester.widget<TextButton>(clearButton).enabled, isFalse);

    // Simulate a stroke
    final gesture = await tester.startGesture(const Offset(100, 100));
    await gesture.moveBy(const Offset(10, 10));
    await gesture.up();
    await tester.pump();

    // Now button should be enabled
    expect(tester.widget<TextButton>(clearButton).enabled, isTrue);

    // Tap clear
    await tester.tap(clearButton);
    await tester.pump();

    // Button should be disabled again
    expect(tester.widget<TextButton>(clearButton).enabled, isFalse);
  });
}
