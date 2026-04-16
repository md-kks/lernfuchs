import 'package:flutter/material.dart';
import '../../core/learning/learning.dart';
import '../../core/models/subject.dart';
import 'learning_challenge_session.dart';
import 'learning_session_mode.dart';
import 'result_screen.dart';

const _sessionSize = 10;

class ExerciseScreen extends StatelessWidget {
  final int grade;
  final String subjectId;
  final String topic;

  const ExerciseScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    final subject = Subject.values.firstWhere((s) => s.id == subjectId);

    return LearningChallengeSession(
      request: LearningRequest(
        subject: subject,
        grade: grade,
        topic: topic,
        difficulty: 2,
        count: _sessionSize,
      ),
      mode: LearningSessionMode.freePractice,
      onCompleted: (result) => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            grade: result.grade,
            subjectId: result.subjectId,
            topic: result.topic,
            correctCount: result.correctCount,
            totalCount: result.totalCount,
          ),
        ),
      ),
    );
  }
}
