import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subject.dart';
import '../../core/models/task_model.dart';
import '../../core/services/providers.dart';
import '../../game/dialogue/hint_definition.dart';
import '../../game/quest/quest_definition.dart';
import '../../game/quest/quest_runtime.dart';
import '../../game/world/world_quest_node.dart';
import '../exercise/learning_session_mode.dart';

class ForestQuestOverlay extends ConsumerStatefulWidget {
  final WorldQuestNode questNode;
  final QuestDefinition quest;
  final QuestRuntime runtime;
  final HintSetDefinition? hintSet;
  final String? feedback;
  final ValueChanged<LearningChallengeResult> onCompleted;
  final VoidCallback onClose;

  const ForestQuestOverlay({
    super.key,
    required this.questNode,
    required this.quest,
    required this.runtime,
    this.hintSet,
    this.feedback,
    required this.onCompleted,
    required this.onClose,
  });

  @override
  ConsumerState<ForestQuestOverlay> createState() => _ForestQuestOverlayState();
}

class _ForestQuestOverlayState extends ConsumerState<ForestQuestOverlay> {
  late final List<TaskModel> _tasks;
  int _currentIndex = 0;
  int _correctCount = 0;
  dynamic _currentAnswer;
  int _syllableCount = 0;
  bool? _lastCorrect;

  TaskModel? get _currentTask =>
      _tasks.isEmpty || _currentIndex >= _tasks.length
      ? null
      : _tasks[_currentIndex];

  @override
  void initState() {
    super.initState();
    final request = widget.runtime.createLearningRequest(widget.quest.id);
    _tasks = widget.runtime.learningEngine.createSession(request).tasks;
    Future.delayed(const Duration(milliseconds: 300), _speakCurrentQuestion);
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  void _speakCurrentQuestion() {
    final task = _currentTask;
    if (task == null) return;
    ref.read(ttsServiceProvider).speak(task.question);
  }

  void _handleTap(Offset position, Size size) {
    final layout = _ForestQuestLayout(size);
    if ((position - layout.backCenter).distance <= layout.backRadius) {
      widget.onClose();
      return;
    }

    final task = _currentTask;
    if (task == null) return;

    if (layout.orbRect.contains(position) &&
        _exerciseKind(task) == _ForestExerciseKind.syllable) {
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
          if (_exerciseKind(task) == _ForestExerciseKind.syllable) {
            _syllableCount = entry.key;
          }
          _lastCorrect = null;
        });
        return;
      }
    }

    for (final entry in layout.answerStones(_answerChoices(task)).entries) {
      if (entry.value.contains(position)) {
        setState(() {
          _currentAnswer = entry.key;
          _lastCorrect = null;
        });
        return;
      }
    }

    if (layout.confirmRect.contains(position)) {
      _checkAndSubmit();
    }
  }

  Future<void> _checkAndSubmit() async {
    final task = _currentTask;
    if (task == null || _currentAnswer == null) return;

    final learning = ref.read(learningEngineProvider);
    final result = learning.evaluateTask(task, _currentAnswer);
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
    } else {
      ref.read(soundServiceProvider).playWrong().catchError((_) {});
    }

    if (!mounted) return;
    setState(() {
      _lastCorrect = result.correct;
      if (result.correct) _correctCount++;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (_currentIndex >= _tasks.length - 1 || !result.correct) {
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
      if (result.correct) widget.onClose();
      return;
    }

    setState(() {
      _currentIndex++;
      _currentAnswer = null;
      _syllableCount = 0;
      _lastCorrect = null;
    });
    _speakCurrentQuestion();
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

  @override
  Widget build(BuildContext context) {
    final task = _currentTask;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
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
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _ForestExerciseKind { syllable, dotCount, multipleChoice, pattern, number }

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

class _ForestQuestLayout {
  final Size size;

  const _ForestQuestLayout(this.size);

  double get scaleX => size.width / 280;
  double get scaleY => size.height / 560;
  double get scale => math.min(scaleX, scaleY);
  double sx(double value) => value * scaleX;
  double sy(double value) => value * scaleY;

  Offset get backCenter => Offset(sx(24), sy(24));
  double get backRadius => 16 * scale;
  Rect get hintRect => Rect.fromLTWH(sx(18), sy(296), sx(244), sy(62));
  Rect get tabletRect => Rect.fromLTWH(sx(24), sy(370), sx(232), sy(74));
  Rect get orbRect =>
      Rect.fromCircle(center: Offset(sx(140), sy(472)), radius: 32 * scale);
  Rect get resetRect => Rect.fromLTWH(sx(98), sy(512), sx(84), sy(20));
  double get numberStoneRadius => 18 * scale;
  Rect get confirmRect =>
      Rect.fromLTWH(sx(48), size.height - sy(58), sx(184), sy(42));

  Map<int, Offset> numberStones(List<int> choices) {
    final start = 140 - ((choices.length - 1) * 26);
    return {
      for (var i = 0; i < choices.length; i++)
        choices[i]: Offset(sx(start + i * 52), sy(520)),
    };
  }

  Map<dynamic, Rect> answerStones(List<dynamic> choices) {
    final result = <dynamic, Rect>{};
    final width = sx(102);
    final height = sy(36);
    for (var i = 0; i < choices.take(4).length; i++) {
      final col = i % 2;
      final row = i ~/ 2;
      result[choices[i]] = Rect.fromLTWH(
        sx(35 + col * 114),
        sy(458 + row * 44),
        width,
        height,
      );
    }
    return result;
  }
}

class ForestQuestPainter extends CustomPainter {
  final WorldQuestNode questNode;
  final TaskModel? task;
  final String hintText;
  final dynamic currentAnswer;
  final int syllableCount;
  final bool? lastCorrect;
  final int progressIndex;

  ForestQuestPainter({
    required this.questNode,
    required this.task,
    required this.hintText,
    required this.currentAnswer,
    required this.syllableCount,
    required this.lastCorrect,
    required this.progressIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawScene(canvas, size);
    _drawTransition(canvas, size);
    _drawForestFloor(canvas, size);
    _drawOvaPlank(canvas, size);
    _drawTaskTablet(canvas, size);
    _drawExerciseArea(canvas, size);
    _drawConfirmButton(canvas, size);
    _drawNavigation(canvas, size);
  }

  void _drawScene(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF9DC49F),
    );
    final l = _ForestQuestLayout(size);
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
    for (var i = 0; i < 6; i++) {
      final p = Offset(l.sx(124 + (i % 3) * 16), l.sy(162 + (i ~/ 3) * 10));
      canvas.drawCircle(
        p,
        l.scale * 7,
        Paint()..color = const Color(0x55FFD700),
      );
      canvas.drawCircle(
        p,
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
    _drawFino(canvas, l.sx(96), l.sy(230), l.scale);
    _drawOva(canvas, l.sx(188), l.sy(66), l.scale * 0.72);
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
    _drawBrumm(canvas, l.sx(218), l.sy(238), l.scale);
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
    for (var i = 0; i < 4; i++) {
      final p = Offset(l.sx(82 + i * 42), l.sy(194 + (i.isEven ? -8 : 8)));
      canvas.drawOval(
        Rect.fromCenter(
          center: p.translate(0, l.sy(4)),
          width: l.sx(32),
          height: l.sy(18),
        ),
        Paint()..color = const Color(0x55000000),
      );
      canvas.drawOval(
        Rect.fromCenter(center: p, width: l.sx(30), height: l.sy(16)),
        Paint()..color = const Color(0xFF8D6E63),
      );
      _drawSymbol(
        canvas,
        l,
        ['dot', 'triangle', 'square', 'circle'][i],
        p,
        l.scale * 0.8,
        const Color(0xFFFFD700),
      );
    }
    _drawFino(canvas, l.sx(58), l.sy(230), l.scale);
  }

  void _drawTransition(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size);
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

  void _drawForestFloor(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size);
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
    final l = _ForestQuestLayout(size);
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
    final l = _ForestQuestLayout(size);
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
        Offset(inner.left + l.sx(10), inner.top + l.sy(42)),
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
      case _ForestExerciseKind.number:
        _drawNumberExercise(canvas, size, task);
    }
  }

  void _drawSyllableExercise(Canvas canvas, Size size, TaskModel task) {
    final l = _ForestQuestLayout(size);
    final c = l.orbRect.center;
    canvas.drawCircle(
      c,
      l.scale * 46,
      Paint()..color = const Color(0x1AE64A19),
    );
    canvas.drawCircle(
      c,
      l.scale * 38,
      Paint()..color = const Color(0x33E64A19),
    );
    canvas.drawCircle(
      c,
      l.scale * 32,
      Paint()..color = const Color(0xFFE64A19),
    );
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
    final l = _ForestQuestLayout(size);
    final center = Offset(l.sx(140), l.sy(468));
    canvas.drawCircle(
      center,
      l.scale * 34,
      Paint()..color = const Color(0xFF4A2E00),
    );
    canvas.drawCircle(
      center,
      l.scale * 28,
      Paint()..color = const Color(0xFF5D4037),
    );
    final count = task.metadata['dotCount'] as int? ?? 0;
    final cols = math.min(5, math.max(1, count));
    for (var i = 0; i < count; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      final p =
          center +
          Offset(l.sx((col - (cols - 1) / 2) * 10), l.sy((row - 0.5) * 10));
      canvas.drawCircle(
        p,
        l.scale * 5,
        Paint()..color = const Color(0x4DFFD700),
      );
      canvas.drawCircle(
        p,
        l.scale * 2.7,
        Paint()..color = const Color(0xFFFFC107),
      );
    }
    _drawNumberStones(canvas, size, _numberChoices(task));
  }

  void _drawNumberExercise(Canvas canvas, Size size, TaskModel task) {
    _drawNumberStones(canvas, size, _numberChoices(task));
  }

  void _drawNumberStones(Canvas canvas, Size size, List<int> choices) {
    final l = _ForestQuestLayout(size);
    for (final entry in l.numberStones(choices).entries) {
      final selected = currentAnswer?.toString() == entry.key.toString();
      if (selected) {
        canvas.drawCircle(
          entry.value,
          l.scale * 24,
          Paint()..color = const Color(0x44FF8F00),
        );
      }
      canvas.drawCircle(
        entry.value,
        l.scale * 18,
        Paint()..color = const Color(0xFF2D1500),
      );
      canvas.drawCircle(
        entry.value,
        l.scale * 14,
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
    _drawAnswerStones(
      canvas,
      size,
      (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [],
    );
  }

  void _drawPatternExercise(Canvas canvas, Size size, TaskModel task) {
    final l = _ForestQuestLayout(size);
    final visible =
        (task.metadata['visible'] as List?)?.cast<String>() ?? const [];
    final start = 140 - visible.length * 20;
    for (var i = 0; i < visible.length; i++) {
      _drawSymbol(
        canvas,
        l,
        visible[i],
        Offset(l.sx(start + i * 40), l.sy(460)),
        l.scale,
        const Color(0xFFFFD700),
      );
    }
    final missing = Offset(l.sx(start + visible.length * 40), l.sy(460));
    canvas.drawCircle(
      missing,
      l.scale * 13,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = l.scale * 2,
    );
    _drawAnswerStones(
      canvas,
      size,
      (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [],
      symbols: true,
    );
  }

  void _drawAnswerStones(
    Canvas canvas,
    Size size,
    List<dynamic> choices, {
    bool symbols = false,
  }) {
    final l = _ForestQuestLayout(size);
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

  void _drawConfirmButton(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size);
    final r = l.confirmRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(8 * l.scale)),
      Paint()..color = const Color(0x2E4CAF50),
    );
    final mid = r.deflate(l.sx(4));
    canvas.drawRRect(
      RRect.fromRectAndRadius(mid, Radius.circular(7 * l.scale)),
      Paint()..color = const Color(0xFF1B5E20),
    );
    final inner = mid.deflate(l.sx(4));
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(6 * l.scale)),
      Paint()..color = const Color(0xFF2E7D32),
    );
    _drawText(
      canvas,
      '✓  Prüfen',
      Offset(inner.left, inner.top + l.sy(11)),
      inner.width,
      const Color(0xFFE8F5E9),
      14 * l.scale,
      FontWeight.w800,
      align: TextAlign.center,
    );
  }

  void _drawNavigation(Canvas canvas, Size size) {
    final l = _ForestQuestLayout(size);
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
    if (value.contains('triangle') ||
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

  void _drawFino(Canvas canvas, double cx, double cy, double scale) {
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
    _drawRotatedOval(
      canvas,
      Offset(25 * scale, 14 * scale),
      6 * scale,
      4 * scale,
      0.3,
      const Color(0xFFFFFDE7),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 5 * scale),
        width: 26 * scale,
        height: 20 * scale,
      ),
      Paint()..color = const Color(0xFFE64A19),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 7 * scale),
        width: 14 * scale,
        height: 14 * scale,
      ),
      Paint()..color = const Color(0xFFFFFDE7),
    );
    canvas.drawCircle(
      Offset(0, -8 * scale),
      12 * scale,
      Paint()..color = const Color(0xFFEF6C00),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -6 * scale),
        width: 14 * scale,
        height: 16 * scale,
      ),
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
        center: Offset(0, -4 * scale),
        width: 5 * scale,
        height: 4 * scale,
      ),
      eyePaint,
    );
    canvas.restore();
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
  bool shouldRepaint(covariant ForestQuestPainter oldDelegate) {
    return oldDelegate.currentAnswer != currentAnswer ||
        oldDelegate.syllableCount != syllableCount ||
        oldDelegate.task != task ||
        oldDelegate.hintText != hintText ||
        oldDelegate.lastCorrect != lastCorrect ||
        oldDelegate.questNode.id != questNode.id ||
        oldDelegate.progressIndex != progressIndex;
  }
}
