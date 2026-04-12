import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/learning/learning.dart';
import '../../core/models/subject.dart';
import '../../core/models/task_model.dart';
import '../../core/services/providers.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_text_styles.dart';
import '../../shared/widgets/feedback_overlay.dart';
import '../../shared/widgets/progress_bar.dart';
import '../../shared/widgets/rounded_button.dart';
import 'learning_session_mode.dart';
import 'widgets/bar_chart_widget.dart';
import 'widgets/clock_widget.dart';
import 'widgets/dictation_widget.dart';
import 'widgets/dot_count_widget.dart';
import 'widgets/fraction_widget.dart';
import 'widgets/free_input_widget.dart';
import 'widgets/handwriting_widget.dart';
import 'widgets/letter_ordering_widget.dart';
import 'widgets/money_widget.dart';
import 'widgets/multiple_choice_widget.dart';
import 'widgets/number_wall_widget.dart';
import 'widgets/ordering_widget.dart';
import 'widgets/pattern_widget.dart';
import 'widgets/reading_text_widget.dart';
import 'widgets/syllable_tap_widget.dart';
import 'widgets/written_calculation_widget.dart';

class LearningChallengeSession extends ConsumerStatefulWidget {
  final LearningRequest request;
  final LearningSessionMode mode;
  final bool showScaffold;
  final bool recordProgress;
  final ValueChanged<LearningChallengeResult> onCompleted;
  final VoidCallback? onCancel;

  const LearningChallengeSession({
    super.key,
    required this.request,
    required this.mode,
    required this.onCompleted,
    this.showScaffold = true,
    this.recordProgress = true,
    this.onCancel,
  });

  @override
  ConsumerState<LearningChallengeSession> createState() =>
      _LearningChallengeSessionState();
}

class _LearningChallengeSessionState
    extends ConsumerState<LearningChallengeSession> {
  late List<TaskModel> _tasks;
  int _currentIndex = 0;
  int _correctCount = 0;
  bool? _lastResult;
  dynamic _pendingAnswer;
  bool _showFeedback = false;
  late int _difficulty;
  final List<int> _results = [];

  Subject get _subject => widget.request.subject;

  @override
  void initState() {
    super.initState();
    _difficulty = widget.request.difficulty;
    _loadTasks();
    Future.delayed(const Duration(milliseconds: 400), _speakCurrentQuestion);
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  void _loadTasks() {
    try {
      final session = ref
          .read(learningEngineProvider)
          .createSession(
            LearningRequest(
              subject: widget.request.subject,
              grade: widget.request.grade,
              topic: widget.request.topic,
              difficulty: _difficulty,
              count: widget.request.count,
              seed: widget.request.seed,
            ),
          );
      _tasks = session.tasks;
    } catch (_) {
      _tasks = [];
    }
  }

  TaskModel get _currentTask => _tasks[_currentIndex];

  void _speakCurrentQuestion() {
    if (_tasks.isEmpty) return;
    ref.read(ttsServiceProvider).speak(_currentTask.question);
  }

  void _onAnswerChanged(dynamic answer) {
    setState(() => _pendingAnswer = answer);
  }

  void _submitAnswer() {
    if (_pendingAnswer == null) return;
    final learning = ref.read(learningEngineProvider);
    final result = learning.evaluateTask(_currentTask, _pendingAnswer);
    final correct = result.correct;
    setState(() {
      _lastResult = correct;
      _showFeedback = true;
      if (correct) _correctCount++;
      _results.add(correct ? 1 : 0);
    });

    if (widget.recordProgress) {
      final profileId = ref.read(appSettingsProvider).activeProfileId;
      learning.recordResult(
        profileId: profileId,
        subject: _subject,
        grade: widget.request.grade,
        topic: widget.request.topic,
        correct: correct,
      );
    }

    if (correct) {
      ref
          .read(soundServiceProvider)
          .playCorrect()
          .then((_) {})
          .catchError((_) {});
    } else {
      ref
          .read(soundServiceProvider)
          .playWrong()
          .then((_) {})
          .catchError((_) {});
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _nextTask();
    });
  }

  void _nextTask() {
    if (_currentIndex >= _tasks.length - 1) {
      widget.onCompleted(
        LearningChallengeResult(
          mode: widget.mode,
          grade: widget.request.grade,
          subjectId: widget.request.subject.id,
          topic: widget.request.topic,
          correctCount: _correctCount,
          totalCount: widget.request.count,
        ),
      );
      return;
    }
    _difficulty = ref
        .read(learningEngineProvider)
        .nextDifficulty(
          recentResults: _results,
          currentDifficulty: _difficulty,
        );
    setState(() {
      _currentIndex++;
      _pendingAnswer = null;
      _lastResult = null;
      _showFeedback = false;
    });
    Future.delayed(const Duration(milliseconds: 300), _speakCurrentQuestion);
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      final empty = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Dieses Thema ist noch in Entwicklung.'),
            const SizedBox(height: 16),
            RoundedButton(
              label: 'Zurück',
              onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      if (!widget.showScaffold) return empty;
      return Scaffold(
        appBar: AppBar(title: const Text('Übung')),
        body: empty,
      );
    }

    final content = _SessionContent(
      grade: widget.request.grade,
      task: _currentTask,
      currentIndex: _currentIndex,
      totalCount: widget.request.count,
      lastResult: _lastResult,
      showFeedback: _showFeedback,
      pendingAnswer: _pendingAnswer,
      onAnswerChanged: _onAnswerChanged,
      onSubmitAnswer: _submitAnswer,
      embedded: !widget.showScaffold,
    );

    if (!widget.showScaffold) return content;

    final colors = AppColors.forGrade(widget.request.grade);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        title: Text('Aufgabe ${_currentIndex + 1} von ${widget.request.count}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_correctCount ✓',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: content,
    );
  }
}

class _SessionContent extends StatelessWidget {
  final int grade;
  final TaskModel task;
  final int currentIndex;
  final int totalCount;
  final bool? lastResult;
  final bool showFeedback;
  final dynamic pendingAnswer;
  final ValueChanged<dynamic> onAnswerChanged;
  final VoidCallback onSubmitAnswer;
  final bool embedded;

  const _SessionContent({
    required this.grade,
    required this.task,
    required this.currentIndex,
    required this.totalCount,
    required this.lastResult,
    required this.showFeedback,
    required this.pendingAnswer,
    required this.onAnswerChanged,
    required this.onSubmitAnswer,
    required this.embedded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.forGrade(grade);
    final progress = (currentIndex + 1) / totalCount;
    final body = SingleChildScrollView(
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.secondary, width: 2),
            ),
            child: Text(
              task.question,
              style: AppTextStyles.taskQuestion,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          LearningAnswerWidget(task: task, onChanged: onAnswerChanged),
          const SizedBox(height: 24),
          if (showFeedback)
            Center(child: FeedbackOverlay(isCorrect: lastResult)),
          if (!showFeedback) ...[
            const SizedBox(height: 8),
            RoundedButton(
              label: 'Prüfen',
              onPressed: pendingAnswer != null ? onSubmitAnswer : null,
              color: colors.primary,
            ),
          ],
        ],
      ),
    );

    if (embedded) return body;

    return Column(
      children: [
        LernFuchsProgressBar(
          value: progress,
          height: 6,
          color: colors.primary,
          backgroundColor: colors.secondary,
          borderRadius: BorderRadius.zero,
        ),
        Expanded(child: body),
      ],
    );
  }
}

class LearningAnswerWidget extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const LearningAnswerWidget({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final type = TaskType.values.byName(task.taskType);
    final topic = task.topic;

    if (type == TaskType.interactive) {
      if (topic == 'uhrzeit') {
        return ClockWidget(task: task, onChanged: onChanged);
      }
      if (topic == 'geld') {
        return MoneyWidget(task: task, onChanged: onChanged);
      }
      if (topic == 'brueche') {
        return FractionWidget(task: task, onChanged: onChanged);
      }
      return FreeInputWidget(task: task, onChanged: onChanged);
    }

    if (type == TaskType.freeInput) {
      if ((topic == 'zahlen_bis_10' || topic == 'zahlen_bis_20') &&
          task.metadata.containsKey('dotCount')) {
        return DotCountWidget(task: task, onChanged: onChanged);
      }
      if (topic == 'zahlenmauern') {
        return NumberWallWidget(task: task, onChanged: onChanged);
      }
      if ((topic == 'schriftliche_addition' ||
              topic == 'schriftliche_subtraktion' ||
              topic == 'schriftliche_multiplikation' ||
              topic == 'schriftliche_division') &&
          task.metadata['showSteps'] == true) {
        return WrittenCalculationWidget(task: task, onChanged: onChanged);
      }
      if (topic == 'diktat') {
        return DictationWidget(task: task, onChanged: onChanged);
      }
      return FreeInputWidget(task: task, onChanged: onChanged);
    }

    if (type == TaskType.multipleChoice && topic == 'lesetext') {
      return ReadingTextWidget(task: task, onChanged: onChanged);
    }

    return switch (type) {
      TaskType.multipleChoice =>
        topic == 'diagramme'
            ? BarChartWidget(task: task, onChanged: onChanged)
            : task.metadata.containsKey('visible')
            ? PatternWidget(task: task, onChanged: onChanged)
            : MultipleChoiceWidget(task: task, onChanged: onChanged),
      TaskType.ordering =>
        topic == 'buchstaben_salat'
            ? LetterOrderingWidget(task: task, onChanged: onChanged)
            : OrderingWidget(task: task, onChanged: onChanged),
      TaskType.tapRhythm =>
        topic == 'silben'
            ? SyllableTapWidget(task: task, onChanged: onChanged)
            : task.metadata.containsKey('visible')
            ? PatternWidget(task: task, onChanged: onChanged)
            : FreeInputWidget(task: task, onChanged: onChanged),
      TaskType.handwriting => HandwritingWidget(
        task: task,
        onChanged: onChanged,
      ),
      _ => FreeInputWidget(task: task, onChanged: onChanged),
    };
  }
}
