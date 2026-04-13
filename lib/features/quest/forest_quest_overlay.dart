import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subject.dart';
import '../../core/models/task_model.dart';
import '../../core/services/providers.dart';
import '../../game/dialogue/hint_definition.dart';
import '../../game/quest/quest_definition.dart';
import '../../game/quest/quest_runtime.dart';
import '../../game/world/world_quest_node.dart';
import '../exercise/learning_session_mode.dart';
import '../exercise/widgets/handwriting_widget.dart';

// ── Phrasen für TTS-Feedback ──────────────────────────────────────────────────

const _praisePhrases = [
  'Super gemacht!',
  'Wunderbar!',
  'Genau richtig!',
  'Du bist ein Held!',
  'Brillant, Fino wäre stolz!',
  'Fantastisch!',
];

const _retryPhrases = [
  'Probier es nochmal!',
  'Fast! Versuch es noch einmal.',
  'Keine Sorge, du schaffst das!',
  'Noch ein Versuch!',
];

// ══════════════════════════════════════════════════════════════════════════════

class ForestQuestOverlay extends ConsumerStatefulWidget {
  final WorldQuestNode questNode;
  final QuestDefinition quest;
  final QuestRuntime runtime;
  final HintSetDefinition? hintSet;
  final String? feedback;
  final double bottomInset;
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
    required this.onCompleted,
    required this.onClose,
  });

  @override
  ConsumerState<ForestQuestOverlay> createState() => _ForestQuestOverlayState();
}

class _ForestQuestOverlayState extends ConsumerState<ForestQuestOverlay>
    with TickerProviderStateMixin {
  // ── Quest-Zustand ──────────────────────────────────────────────────────────
  late final List<TaskModel> _tasks;
  int _currentIndex = 0;
  int _correctCount = 0;
  dynamic _currentAnswer;
  int _syllableCount = 0;
  bool? _lastCorrect;
  bool _submitting = false;

  // ── Ticker ─────────────────────────────────────────────────────────────────
  late final Ticker _ticker;
  Duration? _prevElapsed;

  // ── Animationswerte ────────────────────────────────────────────────────────
  double _breathT = 0.0;

  bool _finoJumping = false;
  double _finoJumpElapsedMs = 0.0;

  bool _brummCelebrating = false;
  double _brummCelebElapsedMs = 0.0;

  bool _ovaFlapping = false;
  double _ovaWingElapsedMs = 0.0;

  bool _gateOpening = false;
  double _gateElapsedMs = 0.0;
  double _gateOpenProgress = 0.0;

  // ── TTS ────────────────────────────────────────────────────────────────────
  final Set<String> _spokenKeys = {};
  final _rng = math.Random();

  // ── Helpers ────────────────────────────────────────────────────────────────

  TaskModel? get _currentTask =>
      _tasks.isEmpty || _currentIndex >= _tasks.length
          ? null
          : _tasks[_currentIndex];

  // ══════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    final request = widget.runtime.createLearningRequest(widget.quest.id);
    _tasks = widget.runtime.learningEngine.createSession(request).tasks;
    _ticker = createTicker(_onTick)..start();
    Future.delayed(const Duration(milliseconds: 300), _startTtsSequence);
  }

  @override
  void dispose() {
    _ticker.dispose();
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  // ── Ticker-Callback ────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final deltaMs = _prevElapsed == null
        ? 0.0
        : (elapsed - _prevElapsed!).inMilliseconds.toDouble();
    _prevElapsed = elapsed;

    setState(() {
      _breathT += deltaMs / 1200.0;

      if (_finoJumping) {
        _finoJumpElapsedMs += deltaMs;
        if (_finoJumpElapsedMs >= 700) {
          _finoJumping = false;
          _finoJumpElapsedMs = 0.0;
        }
      }

      if (_brummCelebrating) {
        _brummCelebElapsedMs += deltaMs;
        if (_brummCelebElapsedMs >= 1400) {
          _brummCelebrating = false;
          _brummCelebElapsedMs = 0.0;
        }
      }

      if (_ovaFlapping) {
        _ovaWingElapsedMs += deltaMs;
        if (_ovaWingElapsedMs >= 500) {
          _ovaFlapping = false;
          _ovaWingElapsedMs = 0.0;
        }
      }

      if (_gateOpening) {
        _gateElapsedMs += deltaMs;
        _gateOpenProgress = (_gateElapsedMs / 800.0).clamp(0.0, 1.0);
        if (_gateElapsedMs >= 800) _gateOpening = false;
      }
    });
  }

  // ── TTS-Sequenz ────────────────────────────────────────────────────────────

  Future<void> _startTtsSequence() async {
    if (!mounted) return;
    final tts = ref.read(ttsServiceProvider);
    if (!tts.isEnabled) return;

    // 1. Erzähltext
    final storyText = widget.questNode.storyText;
    if (storyText.isNotEmpty) {
      final key = 'story:${widget.questNode.id}';
      if (!_spokenKeys.contains(key)) {
        _spokenKeys.add(key);
        await tts.speak(storyText);
        await Future.delayed(const Duration(milliseconds: 3000));
      }
    }
    if (!mounted) return;

    // 2. Erster Hinweis
    final hint = widget.hintSet?.levels.isNotEmpty == true
        ? widget.hintSet!.levels.first.text
        : null;
    if (hint != null && hint.isNotEmpty) {
      final key = 'hint0:${widget.questNode.id}';
      if (!_spokenKeys.contains(key)) {
        _spokenKeys.add(key);
        await tts.speak(hint);
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    }
    if (!mounted) return;

    // 3. Frage
    final task = _currentTask;
    if (task != null) {
      final key = 'q:${task.id}';
      if (!_spokenKeys.contains(key)) {
        _spokenKeys.add(key);
        await tts.speak(task.question);
        await Future.delayed(const Duration(milliseconds: 2000));
      }
      if (!mounted) return;

      // 4. Zielwort (langsam)
      final word = task.metadata['word'] as String? ??
          task.metadata['displayedWord'] as String? ??
          '';
      if (word.isNotEmpty) {
        final key = 'word:${task.id}';
        if (!_spokenKeys.contains(key)) {
          _spokenKeys.add(key);
          await tts.setSpeechRate(0.35);
          await tts.speak(word);
          await tts.setSpeechRate(0.45);
        }
      }
    }
  }

  Future<void> _speakFeedback(bool correct) async {
    if (!mounted) return;
    final tts = ref.read(ttsServiceProvider);
    if (!tts.isEnabled) return;
    final phrases = correct ? _praisePhrases : _retryPhrases;
    await tts.speak(phrases[_rng.nextInt(phrases.length)]);
  }

  // ── Animationen ───────────────────────────────────────────────────────────

  void _startCorrectAnimations() {
    final nodeId = widget.questNode.id;
    setState(() {
      _finoJumping = true;
      _finoJumpElapsedMs = 0.0;
      if (nodeId == 'lichtung' || nodeId == 'bruecke') {
        _brummCelebrating = true;
        _brummCelebElapsedMs = 0.0;
      }
      if (nodeId == 'bruecke') {
        _gateOpening = true;
        _gateElapsedMs = 0.0;
      }
    });
  }

  // ── Eingabe-Handling ──────────────────────────────────────────────────────

  void _handleTap(Offset position, Size size) {
    final layout = _ForestQuestLayout(size, widget.bottomInset);
    if ((position - layout.backCenter).distance <= layout.backRadius) {
      widget.onClose();
      return;
    }
    if (_submitting) return;

    final task = _currentTask;
    if (task == null) return;
    final kind = _exerciseKind(task);

    if (layout.orbRect != Rect.zero &&
        layout.orbRect.contains(position) &&
        kind == _ForestExerciseKind.syllable) {
      setState(() {
        _syllableCount++;
        _currentAnswer = _syllableCount;
        _lastCorrect = null;
      });
      return;
    }

    if (layout.resetRect.contains(position)) {
      setState(() {
        _syllableCount = 0;
        _currentAnswer = null;
        _lastCorrect = null;
      });
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

    for (final entry in layout.answerStones(_answerChoices(task)).entries) {
      if (entry.value.contains(position)) {
        setState(() {
          _currentAnswer = entry.key;
          _lastCorrect = null;
        });
        _checkAndSubmit(entry.key);
        return;
      }
    }

    if (kind == _ForestExerciseKind.handwriting &&
        layout.handwritingConfirmRect.contains(position)) {
      _checkAndSubmit(_currentAnswer);
    }
  }

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
      ref.read(soundServiceProvider).playCorrect().catchError((_) {});
      _startCorrectAnimations();
    } else {
      ref.read(soundServiceProvider).playWrong().catchError((_) {});
    }

    _speakFeedback(result.correct);

    if (!mounted) return;
    setState(() {
      _lastCorrect = result.correct;
      if (result.correct) _correctCount++;
    });

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

    if (_currentIndex >= _tasks.length - 1) {
      widget.onCompleted(
        LearningChallengeResult(
          mode: LearningSessionMode.questSingle,
          grade: task.grade,
          subjectId: task.subject,
          topic: task.topic,
          correctCount: _correctCount,
          totalCount: _tasks.length,
        ),
      );
      return;
    }

    setState(() {
      _currentIndex++;
      _currentAnswer = null;
      _syllableCount = 0;
      _lastCorrect = null;
      _submitting = false;
      _spokenKeys.remove('q:${_tasks[_currentIndex].id}');
    });
    Future.delayed(
        const Duration(milliseconds: 300), _startTtsSequence);
  }

  List<dynamic> _answerChoices(TaskModel task) {
    if (_exerciseKind(task) == _ForestExerciseKind.pattern) {
      return (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [];
    }
    if (_exerciseKind(task) == _ForestExerciseKind.multipleChoice) {
      return (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [];
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

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final task = _currentTask;
    final tts = ref.read(ttsServiceProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final layout = _ForestQuestLayout(size, widget.bottomInset);
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
                  progressIndex: _currentIndex,
                  bottomInset: widget.bottomInset,
                  breathT: _breathT,
                  finoJumpElapsedMs: _finoJumping ? _finoJumpElapsedMs : 0.0,
                  brummCelebElapsedMs:
                      _brummCelebrating ? _brummCelebElapsedMs : 0.0,
                  ovaWingElapsedMs: _ovaFlapping ? _ovaWingElapsedMs : 0.0,
                  gateOpenProgress: _gateOpenProgress,
                  ttsIsSpeaking: tts.isSpeaking,
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

// ══════════════════════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════════════════
// Layout — alle Positionen dynamisch berechnet
// ══════════════════════════════════════════════════════════════════════════════

class _ForestQuestLayout {
  final Size size;
  final double bottomInset;

  const _ForestQuestLayout(this.size, [this.bottomInset = 0]);

  double get scaleX => size.width / 280;
  double get scaleY => size.height / 560;
  double get scale => math.min(scaleX, scaleY);

  double sx(double value) => value * scaleX;
  double sy(double value) => value * scaleY;

  // ── Dynamisches Floor-Layout ──────────────────────────────────────────────

  double get floorTop => size.height * 0.52;
  double get floorHeight => size.height - floorTop - bottomInset - 12;

  double get _ovaPlankH {
    if (floorHeight < 60 * scale) return 32 * scale;
    return 44 * scale;
  }

  double get _tabletH => 54 * scale;

  bool get _showInstruction {
    final usedWith =
        _ovaPlankH + 8 * scale + _tabletH + 8 * scale + 18 * scale + 8 * scale;
    return (floorHeight - usedWith) >= 80 * scale;
  }

  double get _instructionH => _showInstruction ? 18 * scale : 0;

  double get exerciseH {
    final used =
        _ovaPlankH + 8 * scale + _tabletH + 8 * scale + _instructionH + 8 * scale;
    return math.max(0, floorHeight - used);
  }

  double get exerciseTop =>
      floorTop +
      6 * scale +
      _ovaPlankH +
      8 * scale +
      _tabletH +
      8 * scale +
      _instructionH +
      8 * scale;

  // ── Positionierte Rechtecke ───────────────────────────────────────────────

  Rect get hintRect {
    final y = floorTop + 6 * scale;
    return Rect.fromLTWH(sx(18), y, sx(244), _ovaPlankH);
  }

  Rect get tabletRect {
    final y = floorTop + 6 * scale + _ovaPlankH + 8 * scale;
    return Rect.fromLTWH(sx(24), y, sx(232), _tabletH);
  }

  /// Orb nur sichtbar wenn genug Platz; sonst Rect.zero.
  Rect get orbRect {
    if (exerciseH < 160 * scale) return Rect.zero;
    final cy = exerciseTop + 32 * scale + 8 * scale;
    return Rect.fromCircle(center: Offset(sx(140), cy), radius: 32 * scale);
  }

  Rect get resetRect {
    final stoneY = _stonesY;
    return Rect.fromLTWH(
        sx(98), stoneY + numberStoneRadius + 4 * scale, sx(84), sy(20));
  }

  double get numberStoneRadius {
    if (exerciseH >= 160 * scale) return 20 * scale;
    return math.min(20 * scale, (size.width - 60 * scale) / 8);
  }

  double get _stonesY {
    if (exerciseH >= 160 * scale && orbRect != Rect.zero) {
      return orbRect.center.dy + orbRect.height / 2 + 8 * scale + numberStoneRadius;
    }
    return exerciseTop + 8 * scale + numberStoneRadius;
  }

  double get bottomLimit => size.height - bottomInset - 8;

  Rect get handwritingWidgetRect => Rect.fromLTWH(
        sx(38),
        exerciseTop,
        sx(204),
        math.max(sy(64), bottomLimit - exerciseTop - sy(38)),
      );

  Rect get handwritingConfirmRect =>
      Rect.fromLTWH(sx(70), bottomLimit - sy(34), sx(140), sy(26));

  Offset get backCenter => Offset(sx(24), sy(24));
  double get backRadius => 16 * scale;

  // ── Tippziel-Maps ─────────────────────────────────────────────────────────

  Map<int, Offset> numberStones(List<int> choices) {
    final y = math.min(_stonesY, bottomLimit - numberStoneRadius - 4 * scale);
    final spacing = (size.width - 28 * scale) / choices.length;
    return {
      for (var i = 0; i < choices.length; i++)
        choices[i]: Offset(14 * scale + spacing * i + spacing / 2, y),
    };
  }

  Map<dynamic, Rect> answerStones(List<dynamic> choices) {
    final result = <dynamic, Rect>{};
    final numOptions = choices.take(4).length;
    if (numOptions == 0) return result;

    final use2x2 = exerciseH >= 180 * scale && numOptions == 4;
    final rectW = size.width - 28 * scale;
    final minRectH = 36 * scale;

    if (use2x2) {
      final colW = (rectW - 8 * scale) / 2;
      final rowH = ((exerciseH - 8 * scale) / 2).clamp(minRectH, 44 * scale);
      for (var i = 0; i < numOptions; i++) {
        final col = i % 2;
        final row = i ~/ 2;
        result[choices[i]] = Rect.fromLTWH(
          14 * scale + col * (colW + 8 * scale),
          exerciseTop + row * (rowH + 8 * scale),
          colW,
          rowH,
        );
      }
    } else {
      final rawH = (exerciseH - (numOptions - 1) * 6 * scale) / numOptions;
      final rectH = rawH.clamp(minRectH, 44 * scale);
      final totalH = rectH * numOptions + (numOptions - 1) * 6 * scale;
      var ry = exerciseTop + (exerciseH - totalH) / 2;
      for (var i = 0; i < numOptions; i++) {
        result[choices[i]] = Rect.fromLTWH(14 * scale, ry, rectW, rectH);
        ry += rectH + 6 * scale;
      }
    }
    return result;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Painter
// ══════════════════════════════════════════════════════════════════════════════

class ForestQuestPainter extends CustomPainter {
  final WorldQuestNode questNode;
  final TaskModel? task;
  final String hintText;
  final dynamic currentAnswer;
  final int syllableCount;
  final bool? lastCorrect;
  final int progressIndex;
  final double bottomInset;

  // ── Animationswerte ────────────────────────────────────────────────────────
  final double breathT;
  final double finoJumpElapsedMs; // 0 = ruhig
  final double brummCelebElapsedMs; // 0 = ruhig
  final double ovaWingElapsedMs; // 0 = ruhig
  final double gateOpenProgress; // 0..1
  final bool ttsIsSpeaking;

  ForestQuestPainter({
    required this.questNode,
    required this.task,
    required this.hintText,
    required this.currentAnswer,
    required this.syllableCount,
    required this.lastCorrect,
    required this.progressIndex,
    this.bottomInset = 0,
    this.breathT = 0,
    this.finoJumpElapsedMs = 0,
    this.brummCelebElapsedMs = 0,
    this.ovaWingElapsedMs = 0,
    this.gateOpenProgress = 0,
    this.ttsIsSpeaking = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawScene(canvas, size);
    _drawTransition(canvas, size);
    _drawForestFloor(canvas, size);
    _drawOvaPlank(canvas, size);
    _drawTaskTablet(canvas, size);
    _drawExerciseArea(canvas, size);
    _drawNavigation(canvas, size);
  }

  // ── Atemversatz ────────────────────────────────────────────────────────────

  double _breathOffset(double scale) =>
      math.sin(breathT * 2 * math.pi) * 1.5 * scale;

  // ── Fino-Sprungversatz ─────────────────────────────────────────────────────

  double _finoJumpOffset(double scale) {
    if (finoJumpElapsedMs <= 0) return 0;
    final t = (finoJumpElapsedMs / 700.0).clamp(0.0, 1.0);
    const upFrac = 0.3 / 0.7;
    if (t < upFrac) {
      final p = t / upFrac;
      return -12 * scale * (1 - math.pow(1 - p, 2).toDouble());
    } else {
      final p = (t - upFrac) / (1 - upFrac);
      return -12 * scale * (1 - p * p);
    }
  }

  // ── Brumm-Jubelfortschritt ─────────────────────────────────────────────────

  double _brummCelebProgress() =>
      (brummCelebElapsedMs / 1400.0).clamp(0.0, 1.0);

  // ── Ova-Flügelfortschritt ──────────────────────────────────────────────────

  double _ovaWingProgress() => (ovaWingElapsedMs / 500.0).clamp(0.0, 1.0);

  // ══════════════════════════════════════════════════════════════════════════
  // SZENE
  // ══════════════════════════════════════════════════════════════════════════

  void _drawScene(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF9DC49F),
    );
    final l = _ForestQuestLayout(size, bottomInset);
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
        Rect.fromLTWH(l.sx(92), l.sy(91), l.sx(32), l.sy(12)), moss);
    canvas.drawOval(
        Rect.fromLTWH(l.sx(154), l.sy(103), l.sx(28), l.sy(10)), moss);
    final bo = _breathOffset(l.scale);
    _drawFino(canvas, l.sx(112), l.sy(204) + bo + _finoJumpOffset(l.scale), l.scale * 1.05);
    _drawOva(canvas, l.sx(143), l.sy(88) + bo, l.scale * 0.75, wingProgress: _ovaWingProgress());
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
    for (var i = 0; i < 6; i++) {
      final p = Offset(l.sx(124 + (i % 3) * 16), l.sy(162 + (i ~/ 3) * 10));
      canvas.drawCircle(p, l.scale * 7, Paint()..color = const Color(0x55FFD700));
      canvas.drawCircle(p, l.scale * 3.5, Paint()..color = const Color(0xFFFFC107));
    }
    final bo = _breathOffset(l.scale);
    _drawFino(canvas, l.sx(80), l.sy(214) + bo + _finoJumpOffset(l.scale), l.scale);
    _drawBrumm(canvas, l.sx(205), l.sy(210) + bo, l.scale,
        celebProgress: _brummCelebProgress());
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
    final bo = _breathOffset(l.scale);
    _drawFino(canvas, l.sx(96), l.sy(230) + bo + _finoJumpOffset(l.scale), l.scale);
    _drawOva(canvas, l.sx(188), l.sy(66) + bo, l.scale * 0.72, wingProgress: _ovaWingProgress());
  }

  void _drawRune(Canvas canvas, _ForestQuestLayout l, Offset p, String rune) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = l.scale * 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(p, l.scale * 10, Paint()..color = const Color(0x4DFFD700));
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
            ..quadraticBezierTo(p.dx + l.sx(8), p.dy + l.sy(5), p.dx - l.sx(4), p.dy)
            ..quadraticBezierTo(p.dx + l.sx(8), p.dy - l.sy(5), p.dx - l.sx(6), p.dy - l.sy(8)));
    canvas.drawPath(path, paint);
  }

  void _drawBridgeScene(Canvas canvas, _ForestQuestLayout l) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(l.sx(140), l.sy(190)), width: l.sx(340), height: l.sy(70)),
      Paint()..color = const Color(0xFF1565C0),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(l.sx(140), l.sy(190)), width: l.sx(310), height: l.sy(52)),
      Paint()..color = const Color(0xFF1E88E5),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(l.sx(140), l.sy(190)), width: l.sx(250), height: l.sy(32)),
      Paint()..color = const Color(0xFF42A5F5),
    );
    for (var i = 0; i < 6; i++) {
      canvas.drawRect(
        Rect.fromLTWH(l.sx(64 + i * 26), l.sy(170), l.sx(22), l.sy(52)),
        Paint()..color = i.isEven ? const Color(0xFF8D6E63) : const Color(0xFF795548),
      );
      canvas.drawLine(
        Offset(l.sx(45 + i * 36), l.sy(184)),
        Offset(l.sx(75 + i * 36), l.sy(184)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = l.scale,
      );
    }
    final rail = Paint()..color = const Color(0xFF4E342E)..strokeWidth = l.scale * 3;
    canvas.drawLine(Offset(l.sx(54), l.sy(166)), Offset(l.sx(226), l.sy(166)), rail);
    canvas.drawLine(Offset(l.sx(54), l.sy(224)), Offset(l.sx(226), l.sy(224)), rail);
    for (var x = 58.0; x <= 226; x += 30) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(l.sx(x), l.sy(195)), width: l.sx(6), height: l.sy(68)),
        Paint()..color = const Color(0xFF5D4037),
      );
    }

    // Tor (mit Öffnungsanimation)
    final gx = l.sx(140);
    final gy = l.sy(195);
    final gw = l.sx(22);
    final gh = l.sy(60);

    // Linke Torrhälfte — dreht um linke Kante
    canvas.save();
    canvas.translate(gx - gw, gy - gh);
    canvas.rotate(-70 * math.pi / 180 * gateOpenProgress);
    canvas.drawRect(Rect.fromLTWH(0, 0, gw, gh), Paint()..color = const Color(0xFF3E2723));
    canvas.drawRect(
      Rect.fromLTWH(l.sx(3), l.sy(4), l.sx(16), l.sy(52)),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.restore();

    // Rechte Torrhälfte — dreht um rechte Kante
    canvas.save();
    canvas.translate(gx + gw, gy - gh);
    canvas.rotate(70 * math.pi / 180 * gateOpenProgress);
    canvas.drawRect(Rect.fromLTWH(-gw, 0, gw, gh), Paint()..color = const Color(0xFF3E2723));
    canvas.drawRect(
      Rect.fromLTWH(-gw + l.sx(3), l.sy(4), l.sx(16), l.sy(52)),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.restore();

    // Goldener Glanz bei Öffnung
    if (gateOpenProgress > 0) {
      final glowRadius = 28 * l.scale * gateOpenProgress;
      canvas.drawCircle(
        Offset(gx, gy - gh / 2),
        glowRadius,
        Paint()..color = const Color(0x59FFD700),
      );
    }

    // Tor-Bogen (immer)
    canvas.drawArc(
      Rect.fromLTWH(gx - gw, gy - gh - l.sy(12), gw * 2, l.sy(24)),
      math.pi, math.pi, false,
      Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.stroke
        ..strokeWidth = l.scale * 3,
    );

    final bo = _breathOffset(l.scale);
    _drawFino(canvas, l.sx(70), l.sy(238) + bo + _finoJumpOffset(l.scale), l.scale);
    _drawBrumm(canvas, l.sx(218), l.sy(238) + bo, l.scale,
        celebProgress: _brummCelebProgress());
  }

  void _drawLakeScene(Canvas canvas, _ForestQuestLayout l) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(l.sx(146), l.sy(188)), width: l.sx(190), height: l.sy(86)),
      Paint()..color = const Color(0xFF1565C0),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(l.sx(146), l.sy(188)), width: l.sx(150), height: l.sy(58)),
      Paint()..color = const Color(0xFF1E88E5),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(l.sx(150), l.sy(190)), width: l.sx(22), height: l.sy(70)),
      Paint()..color = const Color(0x6642A5F5),
    );
    canvas.drawOval(
      Rect.fromLTWH(l.sx(40), l.sy(160), l.sx(220), l.sy(52)),
      Paint()..color = const Color(0x14200DC8),
    );
    for (var i = 0; i < 4; i++) {
      final p = Offset(l.sx(82 + i * 42), l.sy(194 + (i.isEven ? -8 : 8)));
      canvas.drawOval(
        Rect.fromCenter(center: p.translate(0, l.sy(4)), width: l.sx(32), height: l.sy(18)),
        Paint()..color = const Color(0x55000000),
      );
      canvas.drawOval(
        Rect.fromCenter(center: p, width: l.sx(30), height: l.sy(16)),
        Paint()..color = const Color(0xFF8D6E63),
      );
      _drawSymbol(canvas, l, ['dot', 'triangle', 'square', 'circle'][i], p,
          l.scale * 0.8, const Color(0xFFFFD700));
    }
    final bo = _breathOffset(l.scale);
    _drawFino(canvas, l.sx(58), l.sy(230) + bo + _finoJumpOffset(l.scale), l.scale);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BODENÜBERGANG
  // ══════════════════════════════════════════════════════════════════════════

  void _drawTransition(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset);
    final y = size.height * 0.5;
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

  // ══════════════════════════════════════════════════════════════════════════
  // WALDBODEN
  // ══════════════════════════════════════════════════════════════════════════

  void _drawForestFloor(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.52, size.width, size.height),
      Paint()..color = const Color(0xFF2D1500),
    );
    final grain = Paint()
      ..color = const Color(0x06FFAA3C)
      ..strokeWidth = 1;
    for (var y = size.height * 0.55; y < size.height; y += 20 * l.scale) {
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
        ..quadraticBezierTo(l.sx(46), l.sy(432), l.sx(92), l.sy(468))
        ..quadraticBezierTo(l.sx(62), l.sy(484), l.sx(34), l.sy(520)),
      root,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, l.sy(488))
        ..quadraticBezierTo(l.sx(230), l.sy(438), l.sx(188), l.sy(478))
        ..quadraticBezierTo(l.sx(224), l.sy(496), l.sx(252), l.sy(530)),
      root,
    );
    _drawMushroom(canvas, l, Offset(l.sx(22), l.sy(540)));
    _drawMushroom(canvas, l, Offset(l.sx(252), l.sy(532)));
  }

  void _drawMushroom(Canvas canvas, _ForestQuestLayout l, Offset p) {
    canvas.drawRect(
      Rect.fromCenter(center: p.translate(0, l.sy(8)), width: l.sx(8), height: l.sy(16)),
      Paint()..color = const Color(0xFFE8D5B0),
    );
    canvas.drawArc(
      Rect.fromCenter(center: p, width: l.sx(24), height: l.sy(18)),
      math.pi, math.pi, true,
      Paint()..color = const Color(0xFFE64A19),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OVA-PLANKE
  // ══════════════════════════════════════════════════════════════════════════

  void _drawOvaPlank(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset);
    final r = l.hintRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(7 * l.scale)),
      Paint()..color = const Color(0xFF3E2108),
    );
    canvas.drawRect(
      Rect.fromLTWH(r.left, r.top, l.sx(3), r.height),
      Paint()..color = const Color(0xFFFF8F00),
    );
    final ovaIconCx = r.left + l.sx(24);
    final ovaIconCy = r.top + l.sy(34);
    _drawOva(canvas, ovaIconCx, ovaIconCy, l.scale * 0.48,
        wingProgress: _ovaWingProgress());

    // TTS-Pulsring um Ova-Icon
    if (ttsIsSpeaking) {
      final pulseR = 11 * l.scale * 0.48 + math.sin(breathT * 2 * math.pi) * 2 * l.scale * 0.48;
      canvas.drawCircle(
        Offset(ovaIconCx, ovaIconCy),
        pulseR,
        Paint()
          ..color = const Color(0x99FF8F00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

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

  // ══════════════════════════════════════════════════════════════════════════
  // AUFGABEN-TAFEL
  // ══════════════════════════════════════════════════════════════════════════

  void _drawTaskTablet(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset);
    final outer = l.tabletRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, Radius.circular(8 * l.scale)),
      Paint()..color = const Color(0xFF4A2E00),
    );
    final mid = outer.deflate(l.sx(5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(mid, Radius.circular(7 * l.scale)),
      Paint()..color = const Color(0xFF5D4037),
    );
    final inner = mid.deflate(l.sx(5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(6 * l.scale)),
      Paint()..color = const Color(0xFF6D4C41),
    );
    final crack = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = l.scale;
    canvas.drawPath(
      Path()
        ..moveTo(inner.left + l.sx(20), inner.top + l.sy(18))
        ..quadraticBezierTo(
          inner.left + l.sx(58),
          inner.top + l.sy(12),
          inner.left + l.sx(96),
          inner.top + l.sy(22),
        ),
      crack,
    );
    final question = task?.question ?? 'Diese Station ist noch still.';
    final lines = question.split('\n');
    _drawText(
      canvas,
      lines.first,
      Offset(inner.left + l.sx(10), inner.top + l.sy(12)),
      inner.width - l.sx(20),
      const Color(0xFFE8D5A8),
      11 * l.scale,
      FontWeight.w700,
      align: TextAlign.center,
      maxLines: 2,
    );
    if (lines.length > 1) {
      _drawText(
        canvas,
        lines.skip(1).join(' '),
        Offset(inner.left + l.sx(10), inner.top + l.sy(40)),
        inner.width - l.sx(20),
        const Color(0xFFFF8F00),
        20 * l.scale,
        FontWeight.w800,
        align: TextAlign.center,
        maxLines: 1,
      );
    } else if (task?.metadata['word'] != null) {
      _drawText(
        canvas,
        task!.metadata['word'].toString(),
        Offset(inner.left + l.sx(10), inner.top + l.sy(40)),
        inner.width - l.sx(20),
        const Color(0xFFFF8F00),
        20 * l.scale,
        FontWeight.w800,
        align: TextAlign.center,
        maxLines: 1,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ÜBUNGSBEREICH
  // ══════════════════════════════════════════════════════════════════════════

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
    final l = _ForestQuestLayout(size, bottomInset);
    final orb = l.orbRect;
    if (orb != Rect.zero) {
      final c = orb.center;
      canvas.drawCircle(c, l.scale * 46, Paint()..color = const Color(0x1AE64A19));
      canvas.drawCircle(c, l.scale * 38, Paint()..color = const Color(0x33E64A19));
      canvas.drawCircle(c, l.scale * 32, Paint()..color = const Color(0xFFE64A19));
      canvas.drawCircle(
        c.translate(-l.sx(10), -l.sy(12)),
        l.scale * 8,
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
      _drawText(
        canvas,
        '$syllableCount',
        Offset(c.dx - l.sx(26), c.dy - l.sy(18)),
        l.sx(52),
        Colors.white,
        24 * l.scale,
        FontWeight.w800,
        align: TextAlign.center,
      );
      _drawText(
        canvas,
        'klatschen',
        Offset(c.dx - l.sx(32), c.dy + l.sy(13)),
        l.sx(64),
        Colors.white.withValues(alpha: 0.7),
        8 * l.scale,
        FontWeight.w600,
        align: TextAlign.center,
      );
    } else {
      // Orb ausgeblendet — Silbenzahl im Tablet (kleines Label)
      // Kein extra Zeichnen nötig — syllableCount erscheint via _drawTaskTablet word
    }

    _drawText(
      canvas,
      '↺ Zurücksetzen',
      l.resetRect.topLeft,
      l.resetRect.width,
      const Color(0xFF6A4828),
      9 * l.scale,
      FontWeight.w700,
      align: TextAlign.center,
    );
    _drawNumberStones(canvas, size, _numberChoices(task));
  }

  void _drawDotCountExercise(Canvas canvas, Size size, TaskModel task) {
    final l = _ForestQuestLayout(size, bottomInset);
    final center = Offset(l.sx(140), l.exerciseTop + l.exerciseH * 0.35);
    canvas.drawCircle(center, l.scale * 34, Paint()..color = const Color(0xFF4A2E00));
    canvas.drawCircle(center, l.scale * 28, Paint()..color = const Color(0xFF5D4037));
    final count = task.metadata['dotCount'] as int? ?? 0;
    final cols = math.min(5, math.max(1, count));
    for (var i = 0; i < count; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      final p = center +
          Offset(l.sx((col - (cols - 1) / 2) * 10), l.sy((row - 0.5) * 10));
      canvas.drawCircle(p, l.scale * 5, Paint()..color = const Color(0x4DFFD700));
      canvas.drawCircle(p, l.scale * 2.7, Paint()..color = const Color(0xFFFFC107));
    }
    _drawNumberStones(canvas, size, _numberChoices(task));
  }

  void _drawNumberExercise(Canvas canvas, Size size, TaskModel task) {
    _drawNumberStones(canvas, size, _numberChoices(task));
  }

  void _drawNumberStones(Canvas canvas, Size size, List<int> choices) {
    final l = _ForestQuestLayout(size, bottomInset);
    for (final entry in l.numberStones(choices).entries) {
      final selected = currentAnswer?.toString() == entry.key.toString();
      if (selected) {
        canvas.drawCircle(entry.value, l.scale * 24, Paint()..color = const Color(0x44FF8F00));
      }
      canvas.drawCircle(entry.value, l.scale * 20, Paint()..color = const Color(0xFF2D1500)); // Issue 3: 18→20
      canvas.drawCircle(
        entry.value,
        l.scale * 16,
        Paint()..color = selected ? const Color(0xFFFF8F00) : const Color(0xFF4A2E00),
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
    _drawAnswerStones(
      canvas,
      size,
      (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [],
    );
  }

  void _drawPatternExercise(Canvas canvas, Size size, TaskModel task) {
    final l = _ForestQuestLayout(size, bottomInset);
    final exH = l.exerciseH;
    final symbolSize = exH < 140 * l.scale ? 18 * l.scale : 22 * l.scale; // Issue 3
    final visible = (task.metadata['visible'] as List?)?.cast<String>() ?? const [];
    final start = 140 - visible.length * 20;
    final patternY = l.exerciseTop + symbolSize / 2 + 6 * l.scale;
    for (var i = 0; i < visible.length; i++) {
      _drawSymbol(canvas, l, visible[i],
          Offset(l.sx(start + i * 40), patternY), l.scale, const Color(0xFFFFD700));
    }
    final missing = Offset(l.sx(start + visible.length * 40), patternY);
    // Gestrichelter Platzhalter (Issue 3)
    final phRect = Rect.fromCenter(center: missing, width: symbolSize, height: symbolSize);
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = l.scale * 1.5;
    _drawDashedRRect(canvas, RRect.fromRectAndRadius(phRect, Radius.circular(4 * l.scale)), dashPaint);
    _drawAnswerStones(
      canvas,
      size,
      (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [],
      symbols: true,
    );
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double dist = 0;
      bool draw = true;
      while (dist < m.length) {
        final len = draw ? 4.0 : 3.0;
        if (draw) {
          canvas.drawPath(m.extractPath(dist, (dist + len).clamp(0, m.length)), paint);
        }
        dist += len;
        draw = !draw;
      }
    }
  }

  void _drawAnswerStones(
    Canvas canvas,
    Size size,
    List<dynamic> choices, {
    bool symbols = false,
  }) {
    final l = _ForestQuestLayout(size, bottomInset);
    for (final entry in l.answerStones(choices).entries) {
      final selected = currentAnswer == entry.key;
      Color inner = selected ? const Color(0xFF6D3B17) : const Color(0xFF5D4037);
      Color text = selected ? const Color(0xFFFFD700) : const Color(0xFFE8D5A8);
      if (lastCorrect != null && selected) {
        inner = lastCorrect! ? const Color(0xFF1B4D1B) : const Color(0xFF4A1010);
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
        _drawSymbol(canvas, l, entry.key.toString(), innerRect.center, l.scale * 0.7, text);
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
    final l = _ForestQuestLayout(size, bottomInset);
    final frame = l.handwritingWidgetRect.inflate(l.sx(6));
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, Radius.circular(8 * l.scale)),
      Paint()..color = const Color(0xFF1E0D00),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame.deflate(l.sx(4)), Radius.circular(6 * l.scale)),
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
      RRect.fromRectAndRadius(r.deflate(3 * l.scale), Radius.circular(5 * l.scale)),
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

  // ══════════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ══════════════════════════════════════════════════════════════════════════

  void _drawNavigation(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size, bottomInset);
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
              width: 20 * l.scale, // Issue 3: elongated rect
              height: l.sy(8),
            ),
            Radius.circular(4 * l.scale),
          ),
          Paint()..color = const Color(0xFFFF8F00),
        );
      } else {
        canvas.drawCircle(
          Offset(x, y),
          4 * l.scale, // Issue 3: dot radius
          Paint()
            ..color = i < progressIndex
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.3),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CHARAKTERE
  // ══════════════════════════════════════════════════════════════════════════

  void _drawFino(Canvas canvas, double cx, double cy, double scale) {
    canvas.save();
    canvas.translate(cx, cy);
    _drawRotatedOval(
      canvas,
      Offset(16 * scale, 10 * scale),
      15 * scale, 8 * scale, 0.3,
      const Color(0xFFD84315),
    );
    _drawRotatedOval(
      canvas,
      Offset(25 * scale, 14 * scale),
      6 * scale, 4 * scale, 0.3,
      const Color(0xFFFFFDE7),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 5 * scale), width: 26 * scale, height: 20 * scale),
      Paint()..color = const Color(0xFFE64A19),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 7 * scale), width: 14 * scale, height: 14 * scale),
      Paint()..color = const Color(0xFFFFFDE7),
    );
    canvas.drawCircle(Offset(0, -8 * scale), 12 * scale, Paint()..color = const Color(0xFFEF6C00));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -6 * scale), width: 14 * scale, height: 16 * scale),
      Paint()..color = const Color(0xFFFFFDE7),
    );
    for (final sign in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(sign * 10 * scale, -16 * scale)
          ..lineTo(sign * 17 * scale, -28 * scale)
          ..lineTo(sign * 3 * scale, -21 * scale)
          ..close(),
        Paint()..color = const Color(0xFFEF6C00),
      );
      canvas.drawPath(
        Path()
          ..moveTo(sign * 10 * scale, -18 * scale)
          ..lineTo(sign * 14 * scale, -25 * scale)
          ..lineTo(sign * 5 * scale, -21 * scale)
          ..close(),
        Paint()..color = const Color(0xFFFF8F00),
      );
    }
    final eyePaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(-4 * scale, -9 * scale), 2.5 * scale, eyePaint);
    canvas.drawCircle(Offset(4 * scale, -9 * scale), 2.5 * scale, eyePaint);
    canvas.drawCircle(Offset(-3 * scale, -10 * scale), scale, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(5 * scale, -10 * scale), scale, Paint()..color = Colors.white);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -4 * scale), width: 5 * scale, height: 4 * scale),
      eyePaint,
    );
    canvas.restore();
  }

  void _drawBrumm(Canvas canvas, double cx, double cy, double scale,
      {double celebProgress = 0}) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 8 * scale), width: 36 * scale, height: 44 * scale),
      Paint()..color = const Color(0xFF795548),
    );
    canvas.drawCircle(Offset(cx, cy - 18 * scale), 20 * scale, Paint()..color = const Color(0xFF795548));
    canvas.drawCircle(Offset(cx - 14 * scale, cy - 34 * scale), 8 * scale, Paint()..color = const Color(0xFF6D4C41));
    canvas.drawCircle(Offset(cx + 14 * scale, cy - 34 * scale), 8 * scale, Paint()..color = const Color(0xFF6D4C41));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 12 * scale), width: 22 * scale, height: 14 * scale),
      Paint()..color = const Color(0xFFA1887F),
    );
    final eye = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(cx - 7 * scale, cy - 21 * scale), 2.4 * scale, eye);
    canvas.drawCircle(Offset(cx + 7 * scale, cy - 21 * scale), 2.4 * scale, eye);
    canvas.drawCircle(Offset(cx - 6 * scale, cy - 22 * scale), 0.8 * scale, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 8 * scale, cy - 22 * scale), 0.8 * scale, Paint()..color = Colors.white);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 12 * scale), width: 7 * scale, height: 5 * scale),
      Paint()..color = const Color(0xFF3E2108),
    );

    // Arme (animiert bei Jubel)
    final armPaint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    double armAngle = 0.0;
    if (celebProgress > 0) {
      const raiseFrac = 0.4 / 1.4;
      const holdFrac = 1.0 / 1.4;
      if (celebProgress < raiseFrac) {
        armAngle = (celebProgress / raiseFrac) * (math.pi / 4);
      } else if (celebProgress < holdFrac) {
        armAngle = math.pi / 4;
      } else {
        final p = (celebProgress - holdFrac) / (1 - holdFrac);
        armAngle = (1 - p) * (math.pi / 4);
      }
    }
    // Linker Arm
    final lsx = cx - 18 * scale;
    final lsy = cy - 5 * scale;
    canvas.drawLine(
      Offset(lsx, lsy),
      Offset(lsx - math.cos(math.pi / 6 + armAngle) * 14 * scale,
          lsy - math.sin(math.pi / 6 + armAngle) * 14 * scale),
      armPaint,
    );
    // Rechter Arm
    final rsx = cx + 18 * scale;
    final rsy = cy - 5 * scale;
    canvas.drawLine(
      Offset(rsx, rsy),
      Offset(rsx + math.cos(math.pi / 6 + armAngle) * 14 * scale,
          rsy - math.sin(math.pi / 6 + armAngle) * 14 * scale),
      armPaint,
    );

    // Sterne bei Jubel
    if (celebProgress > 0) {
      final starScaleFactor = (celebProgress < 0.4 / 1.4)
          ? (celebProgress / (0.4 / 1.4)).clamp(0.0, 1.0)
          : 1.0 - ((celebProgress - 0.4 / 1.4) / (1 - 0.4 / 1.4)).clamp(0.0, 0.3);
      final starPaint = Paint()..color = const Color(0xFFFFD700);
      for (final pos in [
        Offset(cx - 22 * scale, cy - 45 * scale),
        Offset(cx + 22 * scale, cy - 45 * scale),
        Offset(cx - 28 * scale, cy - 28 * scale),
        Offset(cx + 28 * scale, cy - 28 * scale),
      ]) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.scale(starScaleFactor, starScaleFactor);
        _drawStar(canvas, Offset.zero, 6 * scale, starPaint);
        canvas.restore();
      }
    }
  }

  void _drawOva(Canvas canvas, double cx, double cy, double scale,
      {double wingProgress = 0}) {
    // Flügel (animiert)
    if (wingProgress > 0) {
      final wingAngle = math.sin(wingProgress * math.pi) * (-35 * math.pi / 180);
      final outerPaint = Paint()..color = const Color(0xFFFF8F00);
      final innerPaint = Paint()..color = const Color(0xFFFFB300);
      // Linker Flügel
      canvas.save();
      canvas.translate(cx - 9 * scale, cy);
      canvas.rotate(wingAngle);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(-10 * scale, -2 * scale)
          ..lineTo(-12 * scale, -8 * scale)
          ..lineTo(-4 * scale, -6 * scale)
          ..close(),
        outerPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-2 * scale, -1 * scale)
          ..lineTo(-8 * scale, -3 * scale)
          ..lineTo(-9 * scale, -6 * scale)
          ..lineTo(-3 * scale, -4 * scale)
          ..close(),
        innerPaint,
      );
      canvas.restore();
      // Rechter Flügel
      canvas.save();
      canvas.translate(cx + 9 * scale, cy);
      canvas.rotate(-wingAngle);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(10 * scale, -2 * scale)
          ..lineTo(12 * scale, -8 * scale)
          ..lineTo(4 * scale, -6 * scale)
          ..close(),
        outerPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(2 * scale, -1 * scale)
          ..lineTo(8 * scale, -3 * scale)
          ..lineTo(9 * scale, -6 * scale)
          ..lineTo(3 * scale, -4 * scale)
          ..close(),
        innerPaint,
      );
      canvas.restore();
    }

    canvas.drawCircle(Offset(cx, cy), 14 * scale, Paint()..color = const Color(0xFFFF8F00));
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
    canvas.drawCircle(Offset(cx - 4 * scale, cy - 3 * scale), 0.8 * scale, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 6 * scale, cy - 3 * scale), 0.8 * scale, Paint()..color = Colors.white);
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy + 2 * scale)
        ..lineTo(cx - 4 * scale, cy + 7 * scale)
        ..lineTo(cx + 4 * scale, cy + 7 * scale)
        ..close(),
      Paint()..color = const Color(0xFFFF8F00),
    );
  }

  // ── Stern-Form ─────────────────────────────────────────────────────────────

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final r = i.isEven ? radius : radius * 0.4;
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SONSTIGES
  // ══════════════════════════════════════════════════════════════════════════

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
    if (value.contains('triangle') || value.contains('🔺') || value == 'dreieck') {
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - 12 * sc)
          ..lineTo(center.dx - 12 * sc, center.dy + 10 * sc)
          ..lineTo(center.dx + 12 * sc, center.dy + 10 * sc)
          ..close(),
        paint,
      );
    } else if (value.contains('square') || value.contains('🟥') || value == 'quadrat') {
      canvas.drawRect(Rect.fromCenter(center: center, width: 22 * sc, height: 22 * sc), paint);
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
  // Always repaint — Ticker drives continuous animation.
  bool shouldRepaint(covariant ForestQuestPainter _) => true;
}
