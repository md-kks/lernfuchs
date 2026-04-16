import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subject.dart';
import '../../core/models/task_model.dart';
import '../../core/learning/learning_request.dart';
import '../../core/services/providers.dart';
import '../../game/dialogue/hint_definition.dart';
import '../../game/quest/quest_definition.dart';
import '../../game/quest/quest_runtime.dart';
import '../../game/world/world_quest_node.dart';
import '../../models/station_dialogue.dart';
import '../../services/fino_evolution_service.dart';
import '../../services/season_service.dart';
import '../breathing/breathing_screen.dart';
import '../exercise/learning_session_mode.dart';
import '../exercise/widgets/handwriting_widget.dart';

class ForestQuestOverlay extends ConsumerStatefulWidget {
  final WorldQuestNode questNode;
  final QuestDefinition quest;
  final QuestRuntime runtime;
  final HintSetDefinition? hintSet;
  final String? feedback;
  final double bottomInset;
  final StationDialogue? stationDialogue;
  final ValueChanged<LearningChallengeResult> onCompleted;
  final VoidCallback onClose;

  const ForestQuestOverlay({
    super.key,
    required this.questNode,
    required this.quest,
    required this.runtime,
    this.hintSet,
    this.feedback,
    this.bottomInset = 0,
    this.stationDialogue,
    required this.onCompleted,
    required this.onClose,
  });

  @override
  ConsumerState<ForestQuestOverlay> createState() => _ForestQuestOverlayState();
}

class _ForestQuestOverlayState extends ConsumerState<ForestQuestOverlay>
    with TickerProviderStateMixin {
  late final List<TaskModel> _tasks;
  late final AnimationController _brummTapController;
  late final AnimationController _feedbackController;
  late final AnimationController _sceneEventController;
  late final AnimationController _outroController;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _tasksCompleted = 0;
  int _sessionTaskCount = 6;
  dynamic _currentAnswer;
  int _syllableCount = 0;
  bool? _lastCorrect;
  bool _submitting = false;
  bool _inputEnabled = true;
  String? _activeSceneEvent;

  TaskModel? get _currentTask =>
      _tasks.isEmpty || _currentIndex >= _tasks.length
      ? null
      : _tasks[_currentIndex];

  @override
  void initState() {
    super.initState();
    _brummTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() => setState(() {}));
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() => setState(() {}));
    _sceneEventController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() => setState(() {}));
    _outroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addListener(() => setState(() {}));
    final request = widget.runtime.createLearningRequest(widget.quest.id);
    _sessionTaskCount = request.count;
    _tasks = widget.runtime.learningEngine
        .createSession(
          LearningRequest(
            subject: request.subject,
            grade: request.grade,
            topic: request.topic,
            difficulty: request.difficulty,
            count: _sessionTaskCount,
            seed: request.seed,
          ),
        )
        .tasks;
    ref.read(audioServiceProvider).playMusic('quest');
    Future.delayed(const Duration(milliseconds: 300), _speakCurrentQuestion);
  }

  @override
  void dispose() {
    _brummTapController.dispose();
    _feedbackController.dispose();
    _sceneEventController.dispose();
    _outroController.dispose();
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  Future<void> _speakCurrentQuestion() async {
    final task = _currentTask;
    if (task == null) return;
    final tts = ref.read(ttsServiceProvider);
    final utterances = <String>[
      _hintText(task),
      task.question,
      if (task.metadata['word'] != null) task.metadata['word'].toString(),
    ].where((text) => text.trim().isNotEmpty).toList();
    for (final text in utterances) {
      if (!mounted) return;
      await tts.speak(text);
      await Future<void>.delayed(_speechGapFor(text));
    }
  }

  Duration _speechGapFor(String text) {
    final ms = (text.length * 55).clamp(650, 2600).toInt();
    return Duration(milliseconds: ms);
  }

  void _handleTap(Offset position, Size size) {
    final accessibility = ref.read(accessibilityProvider).settings;
    final layout = _ForestQuestLayout(
      size,
      widget.bottomInset,
      _hintText(_currentTask),
      accessibility.motorMode,
    );
    if ((position - layout.backCenter).distance <= layout.backRadius) {
      widget.onClose();
      return;
    }
    if (_canPause && layout.pauseLeafRect.contains(position)) {
      _openBreathingPause();
      return;
    }
    if (_submitting || !_inputEnabled) return;

    final task = _currentTask;
    if (task == null) return;
    final kind = _exerciseKind(task);

    if (layout.brummTapRect.contains(position) &&
        kind == _ForestExerciseKind.syllable) {
      setState(() {
        _syllableCount++;
        _currentAnswer = _syllableCount;
        _lastCorrect = null;
      });
      _brummTapController.forward(from: 0);
      return;
    }

    for (final entry in layout.numberStones(_numberChoices(task)).entries) {
      if ((position - entry.value).distance <= layout.numberStoneRadius) {
        setState(() {
          _currentAnswer = entry.key;
          if (kind == _ForestExerciseKind.syllable) {
            _syllableCount = entry.key;
          }
          _lastCorrect = null;
        });
        _checkAndSubmit(entry.key);
        return;
      }
    }

    final answerRects = kind == _ForestExerciseKind.multipleChoice
        ? layout.runeStones(_answerChoices(task))
        : kind == _ForestExerciseKind.pattern
        ? layout.patternTiles(_answerChoices(task))
        : layout.answerStones(_answerChoices(task));
    for (final entry in answerRects.entries) {
      if (entry.value.contains(position)) {
        if (kind == _ForestExerciseKind.pattern &&
            currentAnswerMatches(entry.key) &&
            layout.patternConfirmRect.contains(position) == false) {
          _checkAndSubmit(entry.key);
          return;
        }
        setState(() {
          _currentAnswer = entry.key;
          _lastCorrect = null;
        });
        if (kind != _ForestExerciseKind.pattern) {
          _checkAndSubmit(entry.key);
        }
        return;
      }
    }

    if (kind == _ForestExerciseKind.pattern &&
        _currentAnswer != null &&
        layout.patternConfirmRect.contains(position)) {
      _checkAndSubmit(_currentAnswer);
      return;
    }

    if (kind == _ForestExerciseKind.handwriting &&
        layout.handwritingConfirmRect.contains(position)) {
      _checkAndSubmit(_currentAnswer);
    }
  }

  bool currentAnswerMatches(dynamic value) =>
      _currentAnswer?.toString() == value.toString();

  Future<void> _checkAndSubmit([dynamic answer]) async {
    final task = _currentTask;
    final submittedAnswer = answer ?? _currentAnswer;
    if (task == null || submittedAnswer == null) return;
    _submitting = true;

    final learning = ref.read(learningEngineProvider);
    final result = learning.evaluateTask(task, submittedAnswer);
    await learning.recordResult(
      profileId: ref.read(appSettingsProvider).activeProfileId,
      subject: Subject.values.firstWhere(
        (subject) => subject.id == task.subject,
      ),
      grade: task.grade,
      topic: task.topic,
      correct: result.correct,
    );

    if (result.correct) {
      ref.read(audioServiceProvider).playSfx('correct');
      ref.read(soundServiceProvider).playCorrect().catchError((_) {});
      _speakDialoguePhrase(correct: true);
    } else {
      ref.read(audioServiceProvider).playSfx('wrong');
      ref.read(soundServiceProvider).playWrong().catchError((_) {});
      _speakDialoguePhrase(correct: false);
    }

    if (!mounted) return;
    setState(() {
      _lastCorrect = result.correct;
      if (result.correct) {
        _correctCount++;
        _tasksCompleted++;
      }
    });
    _feedbackController.forward(from: 0);

    if (result.correct) _activateMilestoneIfNeeded();

    await Future.delayed(Duration(milliseconds: result.correct ? 1200 : 800));
    if (!mounted) return;

    if (!result.correct) {
      setState(() {
        _currentAnswer = null;
        _syllableCount = 0;
        _lastCorrect = null;
        _submitting = false;
      });
      return;
    }

    if (_tasksCompleted >= _sessionTaskCount) {
      _startOutro(task);
      return;
    }

    setState(() {
      _currentIndex = _interleavedNextTaskIndex();
      _currentAnswer = null;
      _syllableCount = 0;
      _lastCorrect = null;
      _submitting = false;
    });
    _speakCurrentQuestion();
  }

  int _interleavedNextTaskIndex() {
    if (_tasks.isEmpty) return 0;
    final school = ref.read(schoolModeProvider);
    final active = school.activeCompetencies;
    if (active.isNotEmpty) {
      for (var step = 1; step <= _tasks.length; step++) {
        final candidate = (_currentIndex + step) % _tasks.length;
        if (active.contains(_tasks[candidate].topic)) return candidate;
      }
    }
    return (_currentIndex + 1) % _tasks.length;
  }

  bool get _canPause =>
      _inputEnabled && !_submitting && _lastCorrect == null && _currentTask != null;

  Future<void> _openBreathingPause() async {
    setState(() => _inputEnabled = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => BreathingScreen(
          onResume: () {
            if (mounted) setState(() => _inputEnabled = true);
          },
          onQuit: widget.onClose,
        ),
      ),
    );
    if (mounted && _currentTask != null && !_submitting) {
      setState(() => _inputEnabled = true);
    }
  }

  void _activateMilestoneIfNeeded() {
    final milestone = widget.stationDialogue?.milestoneForTask(_tasksCompleted);
    if (milestone == null) return;
    setState(() => _activeSceneEvent = milestone.sceneEvent);
    if (milestone.sceneEvent == 'gate_open') {
      ref.read(audioServiceProvider).playSfx('gate_open');
    }
    _sceneEventController.forward(from: 0);
    final text = milestone.ovaText;
    if (text != null && text.isNotEmpty) {
      ref.read(ttsServiceProvider).speak(text);
    }
  }

  Future<void> _speakDialoguePhrase({required bool correct}) async {
    final dialogue = widget.stationDialogue;
    if (dialogue == null) return;
    final phrases = correct ? dialogue.correctPhrases : dialogue.wrongAnswerPhrases;
    if (phrases.isEmpty) return;
    final index = DateTime.now().millisecond % phrases.length;
    await ref.read(ttsServiceProvider).speak(phrases[index]);
  }

  Future<void> _startOutro(TaskModel task) async {
    setState(() {
      _inputEnabled = false;
      _submitting = true;
      _activeSceneEvent = widget.stationDialogue?.milestoneForTask(6)?.sceneEvent;
    });
    ref.read(audioServiceProvider).playMusic('outro');
    ref.read(audioServiceProvider).playSfx('crystal_collect');
    if (_activeSceneEvent == 'gate_open') {
      ref.read(audioServiceProvider).playSfx('gate_open');
    }
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted) ref.read(audioServiceProvider).stopMusic();
    });
    _sceneEventController.forward(from: 0);
    final outroText = widget.stationDialogue?.outro.ovaText;
    if (outroText != null && outroText.isNotEmpty) {
      await ref.read(ttsServiceProvider).speak(outroText);
    }
    await _outroController.forward(from: 0);
    if (!mounted) return;
    widget.onCompleted(
      LearningChallengeResult(
        mode: LearningSessionMode.questSingle,
        grade: task.grade,
        subjectId: task.subject,
        topic: task.topic,
        correctCount: _correctCount,
        totalCount: _sessionTaskCount,
      ),
    );
  }

  List<dynamic> _answerChoices(TaskModel task) {
    if (_exerciseKind(task) == _ForestExerciseKind.pattern) {
      return (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [];
    }
    if (_exerciseKind(task) == _ForestExerciseKind.multipleChoice) {
      return _limitedChoiceOptions(task);
    }
    return const [];
  }

  String _hintText(TaskModel? task) {
    if (widget.feedback != null) return widget.feedback!;
    final hint = widget.hintSet?.levels.isEmpty == false
        ? widget.hintSet!.levels.first.text
        : null;
    if (hint != null) return hint;
    return task == null
        ? 'Ova wartet auf die nächste Spur.'
        : 'Schau genau hin und probiere es in Ruhe.';
  }

  @override
  Widget build(BuildContext context) {
    final task = _currentTask;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final accessibility = ref.read(accessibilityProvider).settings;
        final layout = _ForestQuestLayout(
          size,
          widget.bottomInset,
          _hintText(task),
          accessibility.motorMode,
        );
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _handleTap(details.localPosition, size),
              child: CustomPaint(
                size: size,
                painter: ForestQuestPainter(
                  questNode: widget.questNode,
                  task: task,
                  hintText: _hintText(task),
                  currentAnswer: _currentAnswer,
                  syllableCount: _syllableCount,
                  lastCorrect: _lastCorrect,
                  brummTapT: _brummTapController.value,
                  feedbackT: _feedbackController.value,
                  tasksCompleted: _tasksCompleted,
                  sceneEventT: _sceneEventController.value,
                  activeSceneEvent: _activeSceneEvent,
                  outroT: _outroController.value,
                  progressIndex: _currentIndex,
                  bottomInset: widget.bottomInset,
                  season: ref.read(seasonServiceProvider).context,
                  finoStyle: ref.read(finoEvolutionProvider).style,
                  dyslexiaMode: accessibility.dyslexiaMode,
                  motorMode: accessibility.motorMode,
                  calmMode: accessibility.calmMode,
                  showPauseLeaf: _canPause,
                ),
              ),
            ),
            if (task != null &&
                _exerciseKind(task) == _ForestExerciseKind.handwriting)
              Positioned.fromRect(
                rect: layout.handwritingWidgetRect,
                child: HandwritingWidget(
                  task: task,
                  onChanged: (answer) =>
                      setState(() => _currentAnswer = answer),
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _ForestExerciseKind {
  syllable,
  dotCount,
  multipleChoice,
  pattern,
  handwriting,
  number,
}

_ForestExerciseKind _exerciseKind(TaskModel task) {
  final type = TaskType.values.byName(task.taskType);
  if (type == TaskType.tapRhythm && task.topic == 'silben') {
    return _ForestExerciseKind.syllable;
  }
  if (task.metadata.containsKey('dotCount')) {
    return _ForestExerciseKind.dotCount;
  }
  if (task.metadata.containsKey('visible')) {
    return _ForestExerciseKind.pattern;
  }
  if (type == TaskType.multipleChoice) {
    return _ForestExerciseKind.multipleChoice;
  }
  if (type == TaskType.handwriting) {
    return _ForestExerciseKind.handwriting;
  }
  return _ForestExerciseKind.number;
}

List<int> _numberChoices(TaskModel task) {
  final metadataChoices = (task.metadata['choices'] as List?)
      ?.map((choice) => int.tryParse(choice.toString()))
      .whereType<int>()
      .toList();
  if (metadataChoices != null && metadataChoices.isNotEmpty) {
    return metadataChoices.take(4).toList();
  }
  final correct = int.tryParse(task.correctAnswer.toString());
  if (correct == null) return const [1, 2, 3, 4];
  final values = <int>{correct};
  for (var delta = 1; values.length < 4 && delta <= 4; delta++) {
    if (correct - delta >= 0) values.add(correct - delta);
    values.add(correct + delta);
  }
  final sorted = values.take(4).toList()..sort();
  return sorted;
}

List<dynamic> _limitedChoiceOptions(TaskModel task) {
  final choices = ((task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [])
      .toList();
  if (choices.length <= 4) return choices;
  final selected = <dynamic>[];
  for (final choice in choices) {
    if (choice == task.correctAnswer) continue;
    selected.add(choice);
    if (selected.length == 3) break;
  }
  if (!selected.contains(task.correctAnswer)) selected.add(task.correctAnswer);
  selected.sort((a, b) {
    final ah = '${task.id}:$a'.hashCode;
    final bh = '${task.id}:$b'.hashCode;
    return ah.compareTo(bh);
  });
  return selected.take(4).toList();
}

class _ForestQuestLayout {
  final Size size;
  final double bottomInset;
  final String hintText;
  final bool motorMode;

  const _ForestQuestLayout(
    this.size, [
    this.bottomInset = 0,
    this.hintText = '',
    this.motorMode = false,
  ]);

  double get scaleX => size.width / 280;
  double get scaleY => size.height / 560;
  double get scale => math.min(scaleX, scaleY);
  double get tapScale => motorMode ? 1.4 : 1.0;
  double get buttonScale => motorMode ? 1.25 : 1.0;
  double sx(double value) => value * scaleX;
  double sy(double value) => value * scaleY;

  Offset get backCenter => Offset(sx(24), sy(24));
  double get backRadius => 16 * scale;
  bool get shortHint => hintText.length <= 52 && !hintText.contains('\n');
  double get safeBottom => size.height - bottomInset - 8;
  double get floorHeight {
    final maxRatio = shortHint ? 0.28 : 0.35;
    return math.max(80 * scale, size.height * maxRatio);
  }

  double get floorTop => safeBottom - floorHeight;
  double get sceneBottom => floorTop;
  double get sceneHeight => sceneBottom;
  double sceneY(double ratio) => sceneHeight * ratio;
  Rect get hintRect {
    final height = 48 * scale;
    final top = math.min(floorTop + 10 * scale, safeBottom - height);
    return Rect.fromLTWH(sx(12), top, size.width - sx(24), height);
  }

  Rect get questionSignRect => Rect.fromLTWH(
    sx(160),
    sceneY(0.38),
    math.max(72 * scale, math.min(sx(108), size.width - sx(172))),
    44 * scale,
  );

  Rect get brummTapRect => Rect.fromCenter(
    center: Offset(sx(218), sceneY(0.62)),
    width: 68 * scale,
    height: 86 * scale,
  );

  double get numberStoneRadius => 18 * scale * tapScale;
  Rect get pauseLeafRect => Rect.fromCenter(
    center: Offset(16 * scale, safeBottom - 22 * scale),
    width: 28 * scale * tapScale,
    height: 28 * scale * tapScale,
  );
  Rect get handwritingWidgetRect => Rect.fromLTWH(
    sx(18),
    sy(54),
    size.width - sx(36),
    math.max(110 * scale, sceneBottom - sy(100)),
  );
  Rect get handwritingConfirmRect =>
      Rect.fromLTWH(
        sx(70),
        safeBottom - 8 * scale - sy(34) * buttonScale,
        sx(140),
        sy(26) * buttonScale,
      );
  Rect get patternConfirmRect => Rect.fromCenter(
    center: Offset(sx(240), sceneY(0.88)),
    width: 34 * scale * buttonScale,
    height: 30 * scale * buttonScale,
  );

  Map<int, Offset> numberStones(List<int> choices) {
    final gap = motorMode ? 62.0 : 52.0;
    final start = 140 - ((choices.length - 1) * gap / 2);
    final y = sceneY(0.88);
    return {
      for (var i = 0; i < choices.length; i++)
        choices[i]: Offset(sx(start + i * gap), y),
    };
  }

  Map<dynamic, Rect> answerStones(List<dynamic> choices) {
    final result = <dynamic, Rect>{};
    final width = sx(motorMode ? 112 : 102);
    final height = math.max(34 * scale * buttonScale, sy(36) * buttonScale);
    for (var i = 0; i < choices.take(4).length; i++) {
      final col = i % 2;
      final row = i ~/ 2;
      result[choices[i]] = Rect.fromLTWH(
        sx(35 + col * 114),
        sceneY(0.74 + row * 0.13),
        width,
        height,
      );
    }
    return result;
  }

  Map<dynamic, Rect> runeStones(List<dynamic> choices) {
    final result = <dynamic, Rect>{};
    final stone = (motorMode ? 58 : 52) * scale;
    final gapX = (motorMode ? 22 : 18) * scale;
    final gapY = (motorMode ? 22 : 10) * scale;
    final totalWidth = stone * 2 + gapX;
    final left = (size.width - totalWidth) / 2;
    final top = sceneY(0.72);
    for (var i = 0; i < choices.take(4).length; i++) {
      final col = i % 2;
      final row = i ~/ 2;
      result[choices[i]] = Rect.fromLTWH(
        left + col * (stone + gapX),
        top + row * (stone + gapY),
        stone,
        stone,
      );
    }
    return result;
  }

  Map<dynamic, Rect> patternTiles(List<dynamic> choices) {
    final visibleChoices = choices.take(4).toList();
    final gap = (motorMode ? 22 : 6) * scale;
    final width = math.min(
      (motorMode ? 54 : 44) * scale,
      (size.width - sx(28) - gap * (visibleChoices.length - 1)) /
          math.max(1, visibleChoices.length),
    );
    final height = (motorMode ? 54 : 44) * scale;
    final total = width * visibleChoices.length + gap * (visibleChoices.length - 1);
    final left = (size.width - total) / 2;
    final top = sceneY(0.80);
    return {
      for (var i = 0; i < visibleChoices.length; i++)
        visibleChoices[i]: Rect.fromLTWH(left + i * (width + gap), top, width, height),
    };
  }
}

class ForestQuestPainter extends CustomPainter {
  final WorldQuestNode questNode;
  final TaskModel? task;
  final String hintText;
  final dynamic currentAnswer;
  final int syllableCount;
  final bool? lastCorrect;
  final double brummTapT;
  final double feedbackT;
  final int tasksCompleted;
  final double sceneEventT;
  final String? activeSceneEvent;
  final double outroT;
  final int progressIndex;
  final double bottomInset;
  final SeasonContext? season;
  final FinoStyle? finoStyle;
  final bool dyslexiaMode;
  final bool motorMode;
  final bool calmMode;
  final bool showPauseLeaf;

  ForestQuestPainter({
    required this.questNode,
    required this.task,
    required this.hintText,
    required this.currentAnswer,
    required this.syllableCount,
    required this.lastCorrect,
    required this.brummTapT,
    required this.feedbackT,
    this.tasksCompleted = 0,
    this.sceneEventT = 0,
    this.activeSceneEvent,
    this.outroT = 0,
    required this.progressIndex,
    this.bottomInset = 0,
    this.season,
    this.finoStyle,
    this.dyslexiaMode = false,
    this.motorMode = false,
    this.calmMode = false,
    this.showPauseLeaf = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawScene(canvas, size);
    _drawTransition(canvas, size);
    _drawForestFloor(canvas, size);
    _drawOvaPlank(canvas, size);
    _drawExerciseArea(canvas, size);
    _drawNavigation(canvas, size);
  }

  void _drawScene(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF9DC49F),
    );
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    _drawSunRays(canvas, l);
    _drawBackTrees(canvas, l);
    _drawGround(canvas, l);
    switch (questNode.id) {
      case 'lichtung':
        _drawClearingScene(canvas, l);
      case 'alter_baum':
        _drawAncientTreeScene(canvas, l);
      case 'bruecke':
        _drawBridgeScene(canvas, l);
      case 'waldsee':
        _drawLakeScene(canvas, l);
      case 'waldeingang':
      default:
        _drawArchScene(canvas, l);
    }
    _drawSeasonalQuestExtras(canvas, l);
    _drawSceneEvent(canvas, l);
    if (outroT > 0) _drawOutro(canvas, l);
  }

  void _drawSeasonalQuestExtras(Canvas canvas, _ForestQuestLayout l) {
    final context = season;
    if (context == null) return;
    if (context.season == Season.winter) {
      final paint = Paint()
        ..color = const Color(0xB3FFFFFF)
        ..strokeWidth = l.scale
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final p = Offset(l.sx(32 + i * 31), l.sceneY(0.10 + (i % 4) * 0.12));
        canvas.drawLine(p.translate(-4 * l.scale, 0), p.translate(4 * l.scale, 0), paint);
        canvas.drawLine(p.translate(0, -4 * l.scale), p.translate(0, 4 * l.scale), paint);
      }
    }
    if (context.isEvening || context.isNight) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, l.size.width, l.sceneBottom),
        Paint()..color = const Color(0x1F001428),
      );
      for (var i = 0; i < 6; i++) {
        canvas.drawCircle(
          Offset(l.sx(38 + i * 38), l.sceneY(0.20 + (i % 3) * 0.17)),
          2 * l.scale,
          Paint()..color = const Color(0xB3FFFF64),
        );
      }
    }
    if (context.specialDay == SpecialDay.birthday) {
      _drawText(
        canvas,
        'Alles Gute zum Geburtstag!',
        Offset(l.sx(70), l.sceneY(0.14)),
        l.sx(150),
        const Color(0xFFFFD700),
        10 * l.scale,
        FontWeight.w800,
        align: TextAlign.center,
      );
    }
  }

  void _drawSceneEvent(Canvas canvas, _ForestQuestLayout l) {
    final event = activeSceneEvent ?? _eventForCompletedTasks();
    if (event == null) return;
    final t = calmMode ? 1.0 : sceneEventT.clamp(0.0, 1.0);
    switch (event) {
      case 'sunrays_brighten':
        _drawBrightRays(canvas, l, t);
      case 'archway_glow':
      case 'archway_open':
        _drawArchGlow(canvas, l, event == 'archway_open' ? 1.0 : t);
      case 'crystal_flicker':
      case 'crystal_half_glow':
      case 'crystal_full_glow':
        _drawCrystalGlow(canvas, l, event, t);
      case 'rune_glow_1':
      case 'rune_glow_2':
      case 'runes_all_glow':
        _drawTreeRuneGlow(canvas, l, event, t);
      case 'gate_vibrate':
      case 'gate_half_open':
      case 'gate_open':
        _drawGateGlow(canvas, l, event, t);
      case 'stone_appear_1':
      case 'stone_appear_2':
      case 'all_stones':
        _drawLakeStoneEvent(canvas, l, event, t);
    }
  }

  String? _eventForCompletedTasks() {
    if (tasksCompleted >= 6) {
      return switch (questNode.id) {
        'waldeingang' => 'archway_open',
        'lichtung' => 'crystal_full_glow',
        'alter_baum' => 'runes_all_glow',
        'bruecke' => 'gate_open',
        'waldsee' => 'all_stones',
        _ => null,
      };
    }
    if (tasksCompleted >= 4) {
      return switch (questNode.id) {
        'waldeingang' => 'archway_glow',
        'lichtung' => 'crystal_half_glow',
        'alter_baum' => 'rune_glow_2',
        'bruecke' => 'gate_half_open',
        'waldsee' => 'stone_appear_2',
        _ => null,
      };
    }
    if (tasksCompleted >= 2) {
      return switch (questNode.id) {
        'waldeingang' => 'sunrays_brighten',
        'lichtung' => 'crystal_flicker',
        'alter_baum' => 'rune_glow_1',
        'bruecke' => 'gate_vibrate',
        'waldsee' => 'stone_appear_1',
        _ => null,
      };
    }
    return null;
  }

  void _drawBrightRays(Canvas canvas, _ForestQuestLayout l, double t) {
    final paint = Paint()..color = Color.fromRGBO(255, 215, 0, 0.12 + t * 0.16);
    final origin = Offset(l.sx(270), l.sy(30));
    for (var i = 0; i < 5; i++) {
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy)
          ..lineTo(l.sx(42 + i * 42), l.sy(235))
          ..lineTo(l.sx(62 + i * 42), l.sy(235))
          ..close(),
        paint,
      );
    }
  }

  void _drawArchGlow(Canvas canvas, _ForestQuestLayout l, double t) {
    final center = Offset(l.sx(140), l.sy(160));
    canvas.drawCircle(center, 30 * l.scale * t, Paint()..color = Color.fromRGBO(255, 215, 0, 0.3 * t));
    canvas.drawPath(
      Path()
        ..moveTo(l.sx(119), l.sy(210))
        ..quadraticBezierTo(l.sx(140), l.sy(132), l.sx(161), l.sy(210))
        ..close(),
      Paint()..color = Color.fromRGBO(255, 215, 0, 0.20 * t),
    );
  }

  void _drawCrystalGlow(Canvas canvas, _ForestQuestLayout l, String event, double t) {
    final center = Offset(l.sx(140), l.sy(150));
    final pulse = event == 'crystal_flicker' && !calmMode
        ? (math.sin(sceneEventT * math.pi * 8).abs())
        : 1.0;
    final radius = (event == 'crystal_full_glow' ? 34 : 20) * l.scale * t;
    canvas.drawCircle(center, radius, Paint()..color = Color.fromRGBO(41, 182, 246, 0.32 * pulse));
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - 16 * l.scale)
        ..lineTo(center.dx + 10 * l.scale, center.dy)
        ..lineTo(center.dx, center.dy + 16 * l.scale)
        ..lineTo(center.dx - 10 * l.scale, center.dy)
        ..close(),
      Paint()..color = const Color(0xFF29B6F6).withValues(alpha: 0.55 + 0.45 * t),
    );
  }

  void _drawTreeRuneGlow(Canvas canvas, _ForestQuestLayout l, String event, double t) {
    final count = event == 'rune_glow_1' ? 1 : event == 'rune_glow_2' ? 3 : 5;
    for (var i = 0; i < count; i++) {
      final p = Offset(l.sx(128 + (i % 2) * 22), l.sy(140 + i * 18));
      canvas.drawCircle(p, 13 * l.scale, Paint()..color = Color.fromRGBO(255, 215, 0, 0.35 * t));
    }
  }

  void _drawGateGlow(Canvas canvas, _ForestQuestLayout l, String event, double t) {
    final shake = event == 'gate_vibrate' && !calmMode
        ? math.sin(sceneEventT * math.pi * 12) * 2 * l.scale
        : 0.0;
    final center = Offset(l.sx(140) + shake, l.sy(188));
    final alpha = event == 'gate_open' ? 0.32 : 0.18;
    canvas.drawCircle(center, 36 * l.scale * t, Paint()..color = Color.fromRGBO(255, 215, 0, alpha * t));
  }

  void _drawLakeStoneEvent(Canvas canvas, _ForestQuestLayout l, String event, double t) {
    final count = event == 'stone_appear_1' ? 1 : event == 'stone_appear_2' ? 3 : 4;
    for (var i = 0; i < count; i++) {
      final p = Offset(l.sx(82 + i * 42), l.sy(194 + (i.isEven ? -8 : 8)) + (1 - t) * 18 * l.scale);
      canvas.drawOval(Rect.fromCenter(center: p, width: l.sx(30), height: l.sy(16)), Paint()..color = const Color(0xFF8D6E63));
      canvas.drawOval(Rect.fromCenter(center: p, width: l.sx(34), height: l.sy(20)), Paint()..color = Color.fromRGBO(255, 215, 0, 0.12 * t));
    }
  }

  void _drawOutro(Canvas canvas, _ForestQuestLayout l) {
    final t = calmMode ? 1.0 : outroT.clamp(0.0, 1.0);
    final start = Offset(l.sx(140), l.sy(160));
    final end = Offset(l.sx(84), l.sy(214));
    final control = Offset((start.dx + end.dx) / 2, math.min(start.dy, end.dy) - 40 * l.scale);
    final mt = 1 - t;
    final p = Offset(
      mt * mt * start.dx + 2 * mt * t * control.dx + t * t * end.dx,
      mt * mt * start.dy + 2 * mt * t * control.dy + t * t * end.dy,
    );
    final crystalScale = (1 - t).clamp(0.0, 1.0) * l.scale;
    canvas.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - 12 * crystalScale)
        ..lineTo(p.dx + 8 * crystalScale, p.dy)
        ..lineTo(p.dx, p.dy + 12 * crystalScale)
        ..lineTo(p.dx - 8 * crystalScale, p.dy)
        ..close(),
      Paint()..color = const Color(0xFF29B6F6),
    );
    if (t > 0.55) {
      final flashT = math.sin((t - 0.55) / 0.45 * math.pi);
      canvas.drawCircle(end, 18 * l.scale * flashT, Paint()..color = Colors.white.withValues(alpha: 0.45 * flashT));
    }
  }

  void _drawBackTrees(Canvas canvas, _ForestQuestLayout l) {
    var index = 0;
    for (final x in const [30.0, 70.0, 220.0, 258.0]) {
      _drawTree(canvas, l, x, 112, index.isEven ? 0.8 : 1.0);
      index++;
    }
    for (final x in const [15.0, 104.0, 190.0, 238.0]) {
      _drawTree(canvas, l, x, 162, 1.15);
    }
  }

  void _drawTree(
    Canvas canvas,
    _ForestQuestLayout l,
    double x,
    double y,
    double sc,
  ) {
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(l.sx(x), l.sy(y)),
        width: l.sx(10 * sc),
        height: l.sy(58 * sc),
      ),
      Paint()..color = const Color(0xFF3E2108),
    );
    final colors = [
      const Color(0xFF1C3D22),
      const Color(0xFF2D5C2E),
      const Color(0xFF3A8040),
    ];
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(l.sx(x + (i - 1) * 8 * sc), l.sy(y - 42 - i * 6 * sc)),
        l.scale * 22 * sc,
        Paint()..color = colors[i],
      );
    }
  }

  void _drawGround(Canvas canvas, _ForestQuestLayout l) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(l.sx(120), l.sy(240)),
        width: l.sx(360),
        height: l.sy(90),
      ),
      Paint()..color = const Color(0xFF3D6B2E),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(l.sx(170), l.sy(250)),
        width: l.sx(340),
        height: l.sy(80),
      ),
      Paint()..color = const Color(0xFF4E8038),
    );
  }

  void _drawSunRays(Canvas canvas, _ForestQuestLayout l) {
    final paint = Paint()
      ..color = const Color(0x26FFD700)
      ..style = PaintingStyle.fill;
    final origin = Offset(l.sx(270), l.sy(30));
    for (var i = 0; i < 5; i++) {
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(l.sx(42 + i * 42), l.sy(235))
        ..lineTo(l.sx(62 + i * 42), l.sy(235))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawArchScene(Canvas canvas, _ForestQuestLayout l) {
    final moss = Paint()..color = const Color(0xFF3A8040);
    canvas.drawRect(
      Rect.fromLTWH(l.sx(96), l.sy(116), l.sx(26), l.sy(96)),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawRect(
      Rect.fromLTWH(l.sx(158), l.sy(116), l.sx(26), l.sy(96)),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawRect(
      Rect.fromLTWH(l.sx(88), l.sy(96), l.sx(104), l.sy(26)),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawOval(
      Rect.fromLTWH(l.sx(92), l.sy(91), l.sx(32), l.sy(12)),
      moss,
    );
    canvas.drawOval(
      Rect.fromLTWH(l.sx(154), l.sy(103), l.sx(28), l.sy(10)),
      moss,
    );
    _drawFino(canvas, l.sx(112), l.sy(204), l.scale * 1.05);
    _drawOva(canvas, l.sx(143), l.sy(88), l.scale * 0.75);
  }

  void _drawClearingScene(Canvas canvas, _ForestQuestLayout l) {
    canvas.drawRect(
      Rect.fromLTWH(l.sx(112), l.sy(170), l.sx(56), l.sy(46)),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawOval(
      Rect.fromLTWH(l.sx(106), l.sy(154), l.sx(68), l.sy(28)),
      Paint()..color = const Color(0xFF4E342E),
    );
    final count = task?.metadata['dotCount'] as int? ?? 6;
    final cols = math.min(5, math.max(1, count));
    for (var i = 0; i < count; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      final dot = Offset(
        l.sx(140 + (col - (cols - 1) / 2) * 12),
        l.sy(162 + (row - 0.5) * 10),
      );
      canvas.drawCircle(
        dot,
        l.scale * 7,
        Paint()..color = const Color(0x55FFD700),
      );
      canvas.drawCircle(
        dot,
        l.scale * 3.5,
        Paint()..color = const Color(0xFFFFC107),
      );
    }
    _drawFino(canvas, l.sx(80), l.sy(214), l.scale);
    _drawBrumm(canvas, l.sx(205), l.sy(210), l.scale);
  }

  void _drawAncientTreeScene(Canvas canvas, _ForestQuestLayout l) {
    canvas.drawRect(
      Rect.fromLTWH(l.sx(118), l.sy(88), l.sx(48), l.sy(154)),
      Paint()..color = const Color(0xFF3E2108),
    );
    for (final c in [
      (116.0, 78.0, 50.0, const Color(0xFF1C3D22)),
      (160.0, 72.0, 56.0, const Color(0xFF2D5C2E)),
      (132.0, 38.0, 48.0, const Color(0xFF3A8040)),
      (188.0, 54.0, 40.0, const Color(0xFF1C3D22)),
      (86.0, 58.0, 42.0, const Color(0xFF2D5C2E)),
      (145.0, 112.0, 45.0, const Color(0xFF3A8040)),
    ]) {
      canvas.drawCircle(
        Offset(l.sx(c.$1), l.sy(c.$2)),
        l.scale * c.$3,
        Paint()..color = c.$4,
      );
    }
    _drawRune(canvas, l, Offset(l.sx(135), l.sy(142)), 'A');
    _drawRune(canvas, l, Offset(l.sx(148), l.sy(176)), 'B');
    final finoShake = lastCorrect == false && !calmMode
        ? math.sin(feedbackT * math.pi * 6) * 4 * l.scale
        : 0.0;
    final ovaFlap = lastCorrect == true && !calmMode
        ? -math.sin(feedbackT * math.pi * 6).abs() * 4 * l.scale
        : 0.0;
    _drawFino(canvas, l.sx(96) + finoShake, l.sy(230), l.scale);
    _drawOva(canvas, l.sx(188), l.sy(66) + ovaFlap, l.scale * 0.72);
  }

  void _drawRune(Canvas canvas, _ForestQuestLayout l, Offset p, String rune) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = l.scale * 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      p,
      l.scale * 10,
      Paint()..color = const Color(0x4DFFD700),
    );
    final path = rune == 'A'
        ? (Path()
            ..moveTo(p.dx - l.sx(7), p.dy + l.sy(7))
            ..lineTo(p.dx, p.dy - l.sy(8))
            ..lineTo(p.dx + l.sx(7), p.dy + l.sy(7))
            ..moveTo(p.dx - l.sx(4), p.dy + l.sy(1))
            ..lineTo(p.dx + l.sx(4), p.dy + l.sy(1)))
        : (Path()
            ..moveTo(p.dx - l.sx(6), p.dy - l.sy(8))
            ..lineTo(p.dx - l.sx(6), p.dy + l.sy(8))
            ..quadraticBezierTo(
              p.dx + l.sx(8),
              p.dy + l.sy(5),
              p.dx - l.sx(4),
              p.dy,
            )
            ..quadraticBezierTo(
              p.dx + l.sx(8),
              p.dy - l.sy(5),
              p.dx - l.sx(6),
              p.dy - l.sy(8),
            ));
    canvas.drawPath(path, paint);
  }

  void _drawBridgeScene(Canvas canvas, _ForestQuestLayout l) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(l.sx(140), l.sy(190)),
        width: l.sx(340),
        height: l.sy(70),
      ),
      Paint()..color = const Color(0xFF1565C0),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(l.sx(140), l.sy(190)),
        width: l.sx(310),
        height: l.sy(52),
      ),
      Paint()..color = const Color(0xFF1E88E5),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(l.sx(140), l.sy(190)),
        width: l.sx(250),
        height: l.sy(32),
      ),
      Paint()..color = const Color(0xFF42A5F5),
    );
    for (var i = 0; i < 6; i++) {
      canvas.drawRect(
        Rect.fromLTWH(l.sx(64 + i * 26), l.sy(170), l.sx(22), l.sy(52)),
        Paint()
          ..color = i.isEven
              ? const Color(0xFF8D6E63)
              : const Color(0xFF795548),
      );
      canvas.drawLine(
        Offset(l.sx(45 + i * 36), l.sy(184)),
        Offset(l.sx(75 + i * 36), l.sy(184)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = l.scale,
      );
    }
    final rail = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = l.scale * 3;
    canvas.drawLine(
      Offset(l.sx(54), l.sy(166)),
      Offset(l.sx(226), l.sy(166)),
      rail,
    );
    canvas.drawLine(
      Offset(l.sx(54), l.sy(224)),
      Offset(l.sx(226), l.sy(224)),
      rail,
    );
    for (var x = 58.0; x <= 226; x += 30) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(l.sx(x), l.sy(195)),
          width: l.sx(6),
          height: l.sy(68),
        ),
        Paint()..color = const Color(0xFF5D4037),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(l.sx(118), l.sy(156), l.sx(44), l.sy(66)),
      Paint()..color = const Color(0xFF3E2723),
    );
    canvas.drawRect(
      Rect.fromLTWH(l.sx(124), l.sy(164), l.sx(32), l.sy(52)),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawArc(
      Rect.fromLTWH(l.sx(130), l.sy(174), l.sx(20), l.sy(24)),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.stroke
        ..strokeWidth = l.scale * 3,
    );
    canvas.drawRect(
      Rect.fromLTWH(l.sx(130), l.sy(190), l.sx(20), l.sy(18)),
      Paint()..color = const Color(0xFFFFB300),
    );
    canvas.drawCircle(
      Offset(l.sx(140), l.sy(198)),
      l.scale * 3,
      Paint()..color = const Color(0xFFFF8F00),
    );
    canvas.drawRect(
      Rect.fromLTWH(l.sx(138), l.sy(198), l.sx(4), l.sy(8)),
      Paint()..color = const Color(0xFFFF8F00),
    );
    _drawFino(canvas, l.sx(70), l.sy(238), l.scale);
  }

  void _drawLakeScene(Canvas canvas, _ForestQuestLayout l) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(l.sx(146), l.sy(188)),
        width: l.sx(190),
        height: l.sy(86),
      ),
      Paint()..color = const Color(0xFF1565C0),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(l.sx(146), l.sy(188)),
        width: l.sx(150),
        height: l.sy(58),
      ),
      Paint()..color = const Color(0xFF1E88E5),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(l.sx(150), l.sy(190)),
        width: l.sx(22),
        height: l.sy(70),
      ),
      Paint()..color = const Color(0x6642A5F5),
    );
    canvas.drawOval(
      Rect.fromLTWH(l.sx(40), l.sy(160), l.sx(220), l.sy(52)),
      Paint()..color = const Color(0x14200DC8),
    );
    _drawFino(canvas, l.sx(58), l.sy(230), l.scale);
  }

  void _drawTransition(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    final y = l.floorTop;
    for (final layer in [
      (0.0, const Color(0xFF4E8038)),
      (10.0, const Color(0xFF3D6B2E)),
    ]) {
      final path = Path()..moveTo(0, y + layer.$1);
      for (var x = 0.0; x <= size.width; x += 8) {
        path.lineTo(x, y + layer.$1 + math.sin(x / 18) * 4 * l.scale);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = layer.$2);
    }
  }

  void _drawForestFloor(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    canvas.drawRect(
      Rect.fromLTWH(0, l.floorTop, size.width, l.safeBottom - l.floorTop),
      Paint()..color = const Color(0xFF2D1500),
    );
    final grain = Paint()
      ..color = const Color(0x06FFAA3C)
      ..strokeWidth = 1;
    for (var y = l.floorTop + 18 * l.scale; y < l.safeBottom; y += 20 * l.scale) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + math.sin(y / 30) * 2),
        grain,
      );
    }
    final root = Paint()
      ..color = const Color(0xFF1A0A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * l.scale;
    canvas.drawPath(
      Path()
        ..moveTo(0, l.sy(470))
        ..quadraticBezierTo(l.sx(46), l.floorTop + 22 * l.scale, l.sx(92), l.floorTop + 54 * l.scale)
        ..quadraticBezierTo(l.sx(62), l.floorTop + 68 * l.scale, l.sx(34), l.safeBottom - 8 * l.scale),
      root,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, l.floorTop + 62 * l.scale)
        ..quadraticBezierTo(l.sx(230), l.floorTop + 26 * l.scale, l.sx(188), l.floorTop + 58 * l.scale)
        ..quadraticBezierTo(l.sx(224), l.floorTop + 74 * l.scale, l.sx(252), l.safeBottom - 12 * l.scale),
      root,
    );
    _drawMushroom(canvas, l, Offset(l.sx(22), l.safeBottom - 12 * l.scale));
    _drawMushroom(canvas, l, Offset(l.sx(252), l.safeBottom - 20 * l.scale));
  }

  void _drawMushroom(Canvas canvas, _ForestQuestLayout l, Offset p) {
    canvas.drawRect(
      Rect.fromCenter(
        center: p.translate(0, l.sy(8)),
        width: l.sx(8),
        height: l.sy(16),
      ),
      Paint()..color = const Color(0xFFE8D5B0),
    );
    canvas.drawArc(
      Rect.fromCenter(center: p, width: l.sx(24), height: l.sy(18)),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFFE64A19),
    );
  }

  void _drawOvaPlank(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    final r = l.hintRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(7 * l.scale)),
      Paint()..color = const Color(0xFF3E2108),
    );
    canvas.drawRect(
      Rect.fromLTWH(r.left, r.top, l.sx(3), r.height),
      Paint()..color = const Color(0xFFFF8F00),
    );
    _drawOva(canvas, r.left + l.sx(24), r.top + l.sy(34), l.scale * 0.48);
    _drawText(
      canvas,
      'Ova flüstert:',
      Offset(r.left + l.sx(48), r.top + l.sy(12)),
      l.sx(180),
      const Color(0xFFFF8F00),
      9 * l.scale,
      FontWeight.w700,
    );
    _drawText(
      canvas,
      hintText,
      Offset(r.left + l.sx(48), r.top + l.sy(28)),
      l.sx(176),
      const Color(0xFFE8D5B0),
      10 * l.scale,
      FontWeight.w500,
      maxLines: 2,
    );
  }

  void _drawTaskTablet(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    final outer = l.questionSignRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, Radius.circular(8 * l.scale)),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, Radius.circular(8 * l.scale)),
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * l.scale,
    );
    final question = task?.question ?? 'Diese Station ist noch still.';
    final lines = question.split('\n');
    _drawText(
      canvas,
      lines.first,
      Offset(outer.left + l.sx(7), outer.top + 7 * l.scale),
      outer.width - l.sx(14),
      const Color(0xFFE8D5A8),
      12 * l.scale,
      FontWeight.w700,
      align: TextAlign.center,
      maxLines: 2,
    );
    if (lines.length > 1) {
      _drawText(
        canvas,
        lines.skip(1).join(' '),
        Offset(outer.left + l.sx(7), outer.top + 25 * l.scale),
        outer.width - l.sx(14),
        const Color(0xFFFF8F00),
        14 * l.scale,
        FontWeight.w800,
        align: TextAlign.center,
        maxLines: 1,
      );
    } else if (task?.metadata['word'] != null) {
      _drawText(
        canvas,
        task!.metadata['word'].toString(),
        Offset(outer.left + l.sx(7), outer.top + 25 * l.scale),
        outer.width - l.sx(14),
        const Color(0xFFFF8F00),
        14 * l.scale,
        FontWeight.w800,
        align: TextAlign.center,
        maxLines: 1,
      );
    }
  }

  void _drawExerciseArea(Canvas canvas, Size size) {
    final task = this.task;
    if (task == null) return;
    switch (_exerciseKind(task)) {
      case _ForestExerciseKind.syllable:
        _drawSyllableExercise(canvas, size, task);
      case _ForestExerciseKind.dotCount:
        _drawDotCountExercise(canvas, size, task);
      case _ForestExerciseKind.multipleChoice:
        _drawChoiceExercise(canvas, size, task);
      case _ForestExerciseKind.pattern:
        _drawPatternExercise(canvas, size, task);
      case _ForestExerciseKind.handwriting:
        _drawHandwritingExercise(canvas, size);
      case _ForestExerciseKind.number:
        _drawNumberExercise(canvas, size, task);
    }
  }

  void _drawSyllableExercise(Canvas canvas, Size size, TaskModel task) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    _drawText(
      canvas,
      'Tippe Brumm für jede Silbe',
      Offset(l.sx(76), l.sceneY(0.69)),
      l.sx(130),
      Colors.white.withValues(alpha: 0.84),
      10 * l.scale,
      FontWeight.w700,
      align: TextAlign.center,
    );
    final brummCenter = l.brummTapRect.center.translate(
      0,
      -math.sin(brummTapT * math.pi) * (calmMode ? 1.6 : 8) * l.scale,
    );
    _drawBrumm(canvas, brummCenter.dx, brummCenter.dy + 20 * l.scale, l.scale);
    final badge = Rect.fromCenter(
      center: brummCenter.translate(0, -44 * l.scale),
      width: 42 * l.scale,
      height: 26 * l.scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badge, Radius.circular(9 * l.scale)),
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );
    _drawText(
      canvas,
      '$syllableCount',
      Offset(badge.left, badge.top + 4 * l.scale),
      badge.width,
      Colors.white,
      18 * l.scale,
      FontWeight.w800,
      align: TextAlign.center,
    );
    _drawNumberStones(canvas, size, _numberChoices(task));
  }

  void _drawDotCountExercise(Canvas canvas, Size size, TaskModel task) {
    _drawTaskTablet(canvas, size);
    _drawNumberStones(canvas, size, _numberChoices(task));
  }

  void _drawNumberExercise(Canvas canvas, Size size, TaskModel task) {
    _drawNumberStones(canvas, size, _numberChoices(task));
  }

  void _drawNumberStones(Canvas canvas, Size size, List<int> choices) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    for (final entry in l.numberStones(choices).entries) {
      final selected = currentAnswer?.toString() == entry.key.toString();
      if (selected) {
        canvas.drawCircle(
          entry.value,
          l.numberStoneRadius + l.scale * 6,
          Paint()..color = const Color(0x44FF8F00),
        );
      }
      canvas.drawCircle(
        entry.value,
        l.numberStoneRadius,
        Paint()..color = const Color(0xFF2D1500),
      );
      canvas.drawCircle(
        entry.value,
        math.max(l.scale * 14, l.numberStoneRadius - 4 * l.scale),
        Paint()
          ..color = selected
              ? const Color(0xFFFF8F00)
              : const Color(0xFF4A2E00),
      );
      _drawText(
        canvas,
        '${entry.key}',
        Offset(entry.value.dx - l.sx(14), entry.value.dy - l.sy(9)),
        l.sx(28),
        selected ? const Color(0xFFFFF9C4) : const Color(0xFF7A5A40),
        13 * l.scale,
        FontWeight.w800,
        align: TextAlign.center,
      );
    }
  }

  void _drawChoiceExercise(Canvas canvas, Size size, TaskModel task) {
    _drawRuneStones(canvas, size, _limitedChoiceOptions(task));
  }

  void _drawPatternExercise(Canvas canvas, Size size, TaskModel task) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    final visible =
        (task.metadata['visible'] as List?)?.cast<String>() ?? const [];
    final pattern = List<String>.generate(4, (index) {
      if (index < 3 && index < visible.length) return visible[index];
      return index == 3 ? currentAnswer?.toString() ?? '?' : '';
    });
    final lakeY = l.sceneY(0.48);
    for (var i = 0; i < 4; i++) {
      final p = Offset(l.sx(76 + i * 43), lakeY + (i.isEven ? -7 : 7) * l.scale);
      canvas.drawOval(
        Rect.fromCenter(
          center: p.translate(0, 4 * l.scale),
          width: 34 * l.scale,
          height: 18 * l.scale,
        ),
        Paint()..color = const Color(0x55000000),
      );
      if (i == 3 && currentAnswer == null) {
        _drawDashedOval(canvas, Rect.fromCenter(center: p, width: 34 * l.scale, height: 18 * l.scale), l.scale);
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: p, width: 34 * l.scale, height: 18 * l.scale),
          Paint()..color = const Color(0xFF8D6E63),
        );
      }
      _drawSymbol(
        canvas,
        l,
        pattern[i],
        p,
        l.scale * 0.78,
        const Color(0xFFFFD700),
      );
    }
    _drawPatternTiles(
      canvas,
      size,
      (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [],
    );
    if (currentAnswer != null) _drawPatternConfirm(canvas, l);
  }

  void _drawRuneStones(Canvas canvas, Size size, List<dynamic> choices) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    for (final entry in l.runeStones(choices).entries) {
      final selected = currentAnswer?.toString() == entry.key.toString();
      final isWrong = lastCorrect == false && selected;
      final isCorrect = lastCorrect == true && selected;
      if (selected) {
        final glow = isWrong
            ? const Color(0x99B40000)
            : Color.fromRGBO(255, 215, 0, isCorrect ? 0.55 : 0.35);
        canvas.drawOval(entry.value.inflate(7 * l.scale), Paint()..color = glow);
      }
      canvas.drawOval(entry.value, Paint()..color = const Color(0xFF3E2108));
      canvas.drawOval(
        entry.value.deflate(5 * l.scale),
        Paint()..color = const Color(0xFF5D4037),
      );
      _drawText(
        canvas,
        entry.key.toString(),
        Offset(entry.value.left, entry.value.top + 14 * l.scale),
        entry.value.width,
        const Color(0xFFFFD700),
        20 * l.scale,
        FontWeight.w800,
        align: TextAlign.center,
      );
    }
  }

  void _drawPatternTiles(Canvas canvas, Size size, List<dynamic> choices) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    for (final entry in l.patternTiles(choices).entries) {
      final selected = currentAnswer?.toString() == entry.key.toString();
      canvas.drawRRect(
        RRect.fromRectAndRadius(entry.value, Radius.circular(8 * l.scale)),
        Paint()..color = selected ? const Color(0xFFFF8F00) : const Color(0xFF3E2108),
      );
      final inner = entry.value.deflate(4 * l.scale);
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, Radius.circular(6 * l.scale)),
        Paint()..color = const Color(0xFF5D4037),
      );
      _drawSymbol(
        canvas,
        l,
        entry.key.toString(),
        inner.center,
        l.scale * 0.78,
        const Color(0xFFFFD700),
      );
    }
  }

  void _drawPatternConfirm(Canvas canvas, _ForestQuestLayout l) {
    final r = l.patternConfirmRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(8 * l.scale)),
      Paint()..color = const Color(0xFF1B5E20),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.deflate(3 * l.scale), Radius.circular(6 * l.scale)),
      Paint()..color = const Color(0xFF2E7D32),
    );
    _drawText(
      canvas,
      '✓',
      Offset(r.left, r.top + 3 * l.scale),
      r.width,
      const Color(0xFFE8F5E9),
      18 * l.scale,
      FontWeight.w900,
      align: TextAlign.center,
    );
  }

  void _drawDashedOval(Canvas canvas, Rect rect, double sc) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * sc;
    for (var a = 0.0; a < math.pi * 2; a += math.pi / 5) {
      canvas.drawArc(rect, a, math.pi / 10, false, paint);
    }
  }

  void _drawAnswerStones(
    Canvas canvas,
    Size size,
    List<dynamic> choices, {
    bool symbols = false,
  }) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    for (final entry in l.answerStones(choices).entries) {
      final selected = currentAnswer == entry.key;
      Color inner = selected
          ? const Color(0xFF6D3B17)
          : const Color(0xFF5D4037);
      Color text = selected ? const Color(0xFFFFD700) : const Color(0xFFE8D5A8);
      if (lastCorrect != null && selected) {
        inner = lastCorrect!
            ? const Color(0xFF1B4D1B)
            : const Color(0xFF4A1010);
        text = lastCorrect! ? const Color(0xFFA5D6A7) : const Color(0xFFFF5252);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(entry.value, Radius.circular(8 * l.scale)),
        Paint()..color = const Color(0xFF3E2108),
      );
      final innerRect = entry.value.deflate(l.sx(4));
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(6 * l.scale)),
        Paint()..color = inner,
      );
      if (symbols) {
        _drawSymbol(
          canvas,
          l,
          entry.key.toString(),
          innerRect.center,
          l.scale * 0.7,
          text,
        );
      } else {
        _drawText(
          canvas,
          entry.key.toString(),
          Offset(innerRect.left + l.sx(5), innerRect.top + l.sy(9)),
          innerRect.width - l.sx(10),
          text,
          12 * l.scale,
          FontWeight.w800,
          align: TextAlign.center,
          maxLines: 1,
        );
      }
    }
  }

  void _drawHandwritingExercise(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    final frame = l.handwritingWidgetRect.inflate(l.sx(6));
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, Radius.circular(8 * l.scale)),
      Paint()..color = const Color(0xFF1E0D00),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frame.deflate(l.sx(4)),
        Radius.circular(6 * l.scale),
      ),
      Paint()
        ..color = const Color(0xFF3E2108)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * l.scale,
    );
    final r = l.handwritingConfirmRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(7 * l.scale)),
      Paint()..color = const Color(0xFF1B5E20),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        r.deflate(3 * l.scale),
        Radius.circular(5 * l.scale),
      ),
      Paint()..color = const Color(0xFF2E7D32),
    );
    _drawText(
      canvas,
      '✓ Bestätigen',
      Offset(r.left, r.top + l.sy(6)),
      r.width,
      const Color(0xFFE8F5E9),
      13 * l.scale,
      FontWeight.w800,
      align: TextAlign.center,
    );
  }

  void _drawNavigation(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset, hintText, motorMode);
    canvas.drawCircle(
      l.backCenter,
      l.backRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );
    _drawText(
      canvas,
      '←',
      Offset(l.backCenter.dx - l.sx(8), l.backCenter.dy - l.sy(12)),
      l.sx(16),
      Colors.white,
      20 * l.scale,
      FontWeight.w800,
      align: TextAlign.center,
    );
    final y = l.sy(24);
    for (var i = 0; i < 5; i++) {
      final x = l.sx(98 + i * 20);
      if (i == progressIndex) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, y),
              width: l.sx(22),
              height: l.sy(8),
            ),
            Radius.circular(4 * l.scale),
          ),
          Paint()..color = const Color(0xFFFF8F00),
        );
      } else {
        canvas.drawCircle(
          Offset(x, y),
          l.scale * 4,
          Paint()
            ..color = i < progressIndex
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.3),
        );
      }
    }
    if (showPauseLeaf) {
      final leaf = l.pauseLeafRect;
      final center = leaf.center;
      final path = Path()
        ..moveTo(center.dx - 9 * l.scale, center.dy + 6 * l.scale)
        ..quadraticBezierTo(
          center.dx - 8 * l.scale,
          center.dy - 12 * l.scale,
          center.dx + 10 * l.scale,
          center.dy - 9 * l.scale,
        )
        ..quadraticBezierTo(
          center.dx + 12 * l.scale,
          center.dy + 8 * l.scale,
          center.dx - 9 * l.scale,
          center.dy + 6 * l.scale,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = const Color(0xB35A8A5A),
      );
      canvas.drawLine(
        center.translate(-7 * l.scale, 5 * l.scale),
        center.translate(8 * l.scale, -7 * l.scale),
        Paint()
          ..color = const Color(0xCC1B5E20)
          ..strokeWidth = 1.2 * l.scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawSymbol(
    Canvas canvas,
    _ForestQuestLayout l,
    String raw,
    Offset center,
    double sc,
    Color color,
  ) {
    final value = raw.toLowerCase();
    final paint = Paint()..color = color;
    if (value == '?') {
      _drawText(
        canvas,
        '?',
        Offset(center.dx - 10 * sc, center.dy - 14 * sc),
        20 * sc,
        color,
        22 * sc,
        FontWeight.w900,
        align: TextAlign.center,
      );
    } else if (value.contains('triangle') ||
        value.contains('🔺') ||
        value == 'dreieck') {
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - 12 * sc)
          ..lineTo(center.dx - 12 * sc, center.dy + 10 * sc)
          ..lineTo(center.dx + 12 * sc, center.dy + 10 * sc)
          ..close(),
        paint,
      );
    } else if (value.contains('square') ||
        value.contains('🟥') ||
        value == 'quadrat') {
      canvas.drawRect(
        Rect.fromCenter(center: center, width: 22 * sc, height: 22 * sc),
        paint,
      );
    } else if (value.contains('dot') || value == 'punkt') {
      canvas.drawCircle(center, 5 * sc, paint);
    } else {
      canvas.drawCircle(
        center,
        12 * sc,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * sc,
      );
    }
  }

  void _drawFino(Canvas canvas, double cx, double cy, double scale, {FinoStyle? style}) {
    final effectiveStyle = style ?? finoStyle ?? FinoStyle.forStage(0);
    final bodyScale = scale * effectiveStyle.bodyScaleModifier;
    canvas.save();
    canvas.translate(cx, cy);
    _drawRotatedOval(
      canvas,
      Offset(16 * scale, 10 * scale),
      15 * scale,
      8 * scale,
      0.3,
      const Color(0xFFD84315),
    );
    if (effectiveStyle.hasGoldenTailTip) {
      canvas.drawCircle(
        Offset(25 * scale, 14 * scale),
        5 * scale,
        Paint()..color = const Color(0x66FFD700),
      );
    }
    _drawRotatedOval(
      canvas,
      Offset(25 * scale, 14 * scale),
      6 * scale,
      4 * scale,
      0.3,
      effectiveStyle.hasGoldenTailTip
          ? const Color(0xFFFFD700)
          : const Color(0xFFFFFDE7),
    );
    if (effectiveStyle.hasBook) {
      canvas.drawCircle(
        Offset(-5 * scale, 4 * scale),
        12 * scale,
        Paint()..color = const Color(0x26FFD700),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(-9 * scale, 2 * scale),
            width: 8 * scale,
            height: 10 * scale,
          ),
          Radius.circular(2 * scale),
        ),
        Paint()..color = const Color(0xFF3E2108),
      );
      canvas.drawRect(
        Rect.fromLTWH(-6 * scale, -3 * scale, 1.5 * scale, 10 * scale),
        Paint()..color = const Color(0xFFFFD700),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 5 * bodyScale),
        width: 26 * bodyScale,
        height: 20 * bodyScale,
      ),
      Paint()..color = const Color(0xFFE64A19),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 7 * bodyScale),
        width: 14 * bodyScale,
        height: 14 * bodyScale,
      ),
      Paint()..color = const Color(0xFFFFFDE7),
    );
    canvas.drawCircle(
      Offset(0, -8 * bodyScale),
      12 * bodyScale,
      Paint()..color = const Color(0xFFEF6C00),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -6 * bodyScale),
        width: 14 * bodyScale,
        height: 16 * bodyScale,
      ),
      Paint()..color = const Color(0xFFFFFDE7),
    );
    canvas.save();
    canvas.rotate(effectiveStyle.earAngleModifier);
    for (final sign in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(sign * 10 * bodyScale, -16 * bodyScale)
          ..lineTo(sign * 17 * bodyScale, -28 * bodyScale)
          ..lineTo(sign * 3 * bodyScale, -21 * bodyScale)
          ..close(),
        Paint()..color = const Color(0xFFEF6C00),
      );
      canvas.drawPath(
        Path()
          ..moveTo(sign * 10 * bodyScale, -18 * bodyScale)
          ..lineTo(sign * 14 * bodyScale, -25 * bodyScale)
          ..lineTo(sign * 5 * bodyScale, -21 * bodyScale)
          ..close(),
        Paint()..color = const Color(0xFFFF8F00),
      );
    }
    canvas.restore();
    final eyePaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(-4 * bodyScale, -9 * bodyScale), 2.5 * bodyScale, eyePaint);
    canvas.drawCircle(Offset(4 * bodyScale, -9 * bodyScale), 2.5 * bodyScale, eyePaint);
    canvas.drawCircle(
      Offset(-3 * scale, -10 * scale),
      scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(5 * scale, -10 * scale),
      scale,
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -4 * bodyScale),
        width: 5 * bodyScale,
        height: 4 * bodyScale,
      ),
      eyePaint,
    );
    if (effectiveStyle.hasEyeGlow) {
      canvas.drawCircle(
        Offset(-4 * bodyScale, -9 * bodyScale),
        3.5 * bodyScale,
        Paint()..color = effectiveStyle.eyeGlowColor,
      );
      canvas.drawCircle(
        Offset(4 * bodyScale, -9 * bodyScale),
        3.5 * bodyScale,
        Paint()..color = effectiveStyle.eyeGlowColor,
      );
    }
    if (effectiveStyle.hasNecklace) {
      _drawFinoNecklace(canvas, scale, effectiveStyle);
    }
    if (season?.specialDay == SpecialDay.halloween) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, 3 * scale),
          width: 31 * scale,
          height: 48 * scale,
        ),
        Paint()..color = Colors.white.withOpacity(0.72),
      );
      canvas.drawCircle(Offset(-5 * scale, -7 * scale), 2 * scale, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(5 * scale, -7 * scale), 2 * scale, Paint()..color = Colors.black);
    }
    canvas.restore();
  }

  void _drawFinoNecklace(Canvas canvas, double scale, FinoStyle style) {
    final cord = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;
    final rect = Rect.fromCenter(
      center: Offset(0, 3 * scale),
      width: 22 * scale,
      height: 16 * scale,
    );
    canvas.drawArc(rect, 0.05 * math.pi, 0.9 * math.pi, false, cord);
    final count = style.necklaceCount.clamp(1, 3);
    for (var i = 0; i < count; i++) {
      final p = Offset((i - (count - 1) / 2) * 6 * scale, 10 * scale);
      canvas.drawCircle(p, 4 * scale, Paint()..color = const Color(0x4D29B6F6));
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - 2.5 * scale)
          ..lineTo(p.dx + 2.5 * scale, p.dy)
          ..lineTo(p.dx, p.dy + 2.5 * scale)
          ..lineTo(p.dx - 2.5 * scale, p.dy)
          ..close(),
        Paint()..color = const Color(0xFF29B6F6),
      );
    }
  }

  void _drawBrumm(Canvas canvas, double cx, double cy, double scale) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 8 * scale),
        width: 36 * scale,
        height: 44 * scale,
      ),
      Paint()..color = const Color(0xFF795548),
    );
    canvas.drawCircle(
      Offset(cx, cy - 18 * scale),
      20 * scale,
      Paint()..color = const Color(0xFF795548),
    );
    canvas.drawCircle(
      Offset(cx - 14 * scale, cy - 34 * scale),
      8 * scale,
      Paint()..color = const Color(0xFF6D4C41),
    );
    canvas.drawCircle(
      Offset(cx + 14 * scale, cy - 34 * scale),
      8 * scale,
      Paint()..color = const Color(0xFF6D4C41),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 12 * scale),
        width: 22 * scale,
        height: 14 * scale,
      ),
      Paint()..color = const Color(0xFFA1887F),
    );
    final eye = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(
      Offset(cx - 7 * scale, cy - 21 * scale),
      2.4 * scale,
      eye,
    );
    canvas.drawCircle(
      Offset(cx + 7 * scale, cy - 21 * scale),
      2.4 * scale,
      eye,
    );
    canvas.drawCircle(
      Offset(cx - 6 * scale, cy - 22 * scale),
      0.8 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx + 8 * scale, cy - 22 * scale),
      0.8 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 12 * scale),
        width: 7 * scale,
        height: 5 * scale,
      ),
      Paint()..color = const Color(0xFF3E2108),
    );
    if (season?.specialDay == SpecialDay.christmas) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - 12 * scale, cy - 38 * scale)
          ..lineTo(cx + 12 * scale, cy - 38 * scale)
          ..lineTo(cx + 2 * scale, cy - 58 * scale)
          ..close(),
        Paint()..color = const Color(0xFFD50000),
      );
      canvas.drawCircle(
        Offset(cx + 4 * scale, cy - 58 * scale),
        4 * scale,
        Paint()..color = Colors.white,
      );
      canvas.drawLine(
        Offset(cx - 12 * scale, cy - 38 * scale),
        Offset(cx + 12 * scale, cy - 38 * scale),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawOva(Canvas canvas, double cx, double cy, double scale) {
    canvas.drawCircle(
      Offset(cx, cy),
      14 * scale,
      Paint()..color = const Color(0xFFFF8F00),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx - 9 * scale, cy - 11 * scale)
        ..lineTo(cx - 17 * scale, cy - 24 * scale)
        ..lineTo(cx - 2 * scale, cy - 16 * scale)
        ..close(),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 9 * scale, cy - 11 * scale)
        ..lineTo(cx + 17 * scale, cy - 24 * scale)
        ..lineTo(cx + 2 * scale, cy - 16 * scale)
        ..close(),
      Paint()..color = const Color(0xFF5D4037),
    );
    final eye = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(cx - 5 * scale, cy - 2 * scale), 2.4 * scale, eye);
    canvas.drawCircle(Offset(cx + 5 * scale, cy - 2 * scale), 2.4 * scale, eye);
    canvas.drawCircle(
      Offset(cx - 4 * scale, cy - 3 * scale),
      0.8 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx + 6 * scale, cy - 3 * scale),
      0.8 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy + 2 * scale)
        ..lineTo(cx - 4 * scale, cy + 7 * scale)
        ..lineTo(cx + 4 * scale, cy + 7 * scale)
        ..close(),
      Paint()..color = const Color(0xFFFF8F00),
    );
    if (season?.specialDay == SpecialDay.birthday) {
      canvas.drawRect(
        Rect.fromLTWH(cx + 15 * scale, cy - 12 * scale, 3 * scale, 14 * scale),
        Paint()..color = const Color(0xFFFFD54F),
      );
      canvas.drawPath(
        Path()
          ..moveTo(cx + 16.5 * scale, cy - 20 * scale)
          ..quadraticBezierTo(cx + 22 * scale, cy - 14 * scale, cx + 16.5 * scale, cy - 10 * scale)
          ..quadraticBezierTo(cx + 11 * scale, cy - 14 * scale, cx + 16.5 * scale, cy - 20 * scale),
        Paint()..color = const Color(0xFFFF8F00),
      );
    }
  }

  void _drawRotatedOval(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
    double rotation,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      Paint()..color = color,
    );
    canvas.restore();
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double width,
    Color color,
    double fontSize,
    FontWeight weight, {
    TextAlign align = TextAlign.start,
    int maxLines = 1,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          height: 1.05,
          fontFamily: dyslexiaMode ? 'OpenDyslexic' : null,
          letterSpacing: dyslexiaMode ? fontSize * 0.08 : null,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant ForestQuestPainter oldDelegate) {
    return oldDelegate.currentAnswer != currentAnswer ||
        oldDelegate.syllableCount != syllableCount ||
        oldDelegate.task != task ||
        oldDelegate.hintText != hintText ||
        oldDelegate.lastCorrect != lastCorrect ||
        oldDelegate.brummTapT != brummTapT ||
        oldDelegate.feedbackT != feedbackT ||
        oldDelegate.tasksCompleted != tasksCompleted ||
        oldDelegate.sceneEventT != sceneEventT ||
        oldDelegate.activeSceneEvent != activeSceneEvent ||
        oldDelegate.outroT != outroT ||
        oldDelegate.questNode.id != questNode.id ||
        oldDelegate.progressIndex != progressIndex ||
        oldDelegate.bottomInset != bottomInset;
  }
}
