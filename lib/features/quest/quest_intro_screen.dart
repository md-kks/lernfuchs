import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../game/world/world_quest_node.dart';
import '../../models/station_dialogue.dart';
import '../../services/fino_evolution_service.dart';
import 'forest_quest_overlay.dart';

class QuestIntroScreen extends ConsumerStatefulWidget {
  final StationDialogue stationDialogue;
  final WorldQuestNode questNode;
  final VoidCallback onComplete;

  const QuestIntroScreen({
    super.key,
    required this.stationDialogue,
    required this.questNode,
    required this.onComplete,
  });

  @override
  ConsumerState<QuestIntroScreen> createState() => _QuestIntroScreenState();
}

class _QuestIntroScreenState extends ConsumerState<QuestIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ticker;
  late final AnimationController _bubbleController;
  Timer? _advanceTimer;
  int _frameIndex = 0;
  bool _canAdvance = false;
  bool _skipped = false;

  double get _bubbleOpacity => _bubbleController.value;
  IntroFrame get _frame => widget.stationDialogue.intro[_frameIndex];

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() => setState(() {}));
    ref.read(audioServiceProvider).playSfx('ova_appear');
    WidgetsBinding.instance.addPostFrameCallback((_) => _showFrame());
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _ticker.dispose();
    _bubbleController.dispose();
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  Future<void> _showFrame() async {
    if (!mounted || _skipped || widget.stationDialogue.intro.isEmpty) return;
    setState(() => _canAdvance = false);
    await _bubbleController.forward(from: 0);
    if (_frame.tts) {
      ref.read(ttsServiceProvider).speak(_frame.text);
    }
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _canAdvance = true);
    });
  }

  Future<void> _advance() async {
    if (_skipped) return;
    if (!_canAdvance) {
      await ref.read(ttsServiceProvider).stop();
      _advanceTimer?.cancel();
      setState(() => _canAdvance = true);
      return;
    }
    await _bubbleController.reverse();
    if (!mounted) return;
    if (_frameIndex >= widget.stationDialogue.intro.length - 1) {
      widget.onComplete();
      return;
    }
    setState(() => _frameIndex++);
    await _showFrame();
  }

  void _skipAll() {
    _skipped = true;
    _advanceTimer?.cancel();
    ref.read(ttsServiceProvider).stop();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      onLongPress: _skipAll,
      child: AnimatedBuilder(
        animation: _ticker,
        builder: (context, _) {
          return CustomPaint(
            painter: _QuestIntroPainter(
              questNode: widget.questNode,
              dialogue: widget.stationDialogue,
              frameIndex: _frameIndex,
              bubbleOpacity: _bubbleOpacity,
              canAdvance: _canAdvance,
              t: _ticker.value,
              finoStyle: ref.read(finoEvolutionProvider).style,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _QuestIntroPainter extends CustomPainter {
  final WorldQuestNode questNode;
  final StationDialogue dialogue;
  final int frameIndex;
  final double bubbleOpacity;
  final bool canAdvance;
  final double t;
  final FinoStyle finoStyle;

  const _QuestIntroPainter({
    required this.questNode,
    required this.dialogue,
    required this.frameIndex,
    required this.bubbleOpacity,
    required this.canAdvance,
    required this.t,
    required this.finoStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    ForestQuestPainter(
      questNode: questNode,
      task: null,
      hintText: '',
      currentAnswer: null,
      syllableCount: 0,
      lastCorrect: null,
      brummTapT: 0,
      feedbackT: 0,
      progressIndex: 0,
      bottomInset: 0,
      tasksCompleted: 0,
      sceneEventT: 0,
      activeSceneEvent: null,
      outroT: 0,
      finoStyle: finoStyle,
    ).paint(canvas, size);

    if (dialogue.intro.isEmpty) return;
    final frame = dialogue.intro[frameIndex];
    final sc = math.min(size.width / 280, size.height / 560);
    final textScale = sc;
    final strip = Rect.fromLTWH(0, size.height * 0.70, size.width, size.height * 0.30);
    canvas.drawRect(strip, Paint()..color = Colors.black.withValues(alpha: 0.55));

    final iconCenter = Offset(42 * sc, strip.top + strip.height * 0.48);
    canvas.saveLayer(strip, Paint()..color = Colors.white.withValues(alpha: bubbleOpacity));
    _drawSpeakerIcon(canvas, frame.speaker, iconCenter, sc, frame.animation);

    final bubble = Rect.fromLTWH(76 * sc, strip.top + 22 * sc, size.width - 88 * sc, strip.height - 42 * sc);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubble, Radius.circular(9 * sc)),
      Paint()..color = const Color(0xFF1E0D00),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubble.deflate(4 * sc), Radius.circular(7 * sc)),
      Paint()..color = const Color(0xFF3E2108),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubble, Radius.circular(9 * sc)),
      Paint()
        ..color = const Color(0xFFFF8F00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * sc,
    );
    _drawText(
      canvas,
      _speakerName(frame.speaker),
      Offset(bubble.left + 12 * sc, bubble.top + 9 * sc),
      bubble.width - 24 * sc,
      const Color(0xFFFF8F00),
      11 * textScale,
      FontWeight.w800,
    );
    _drawText(
      canvas,
      frame.text,
      Offset(bubble.left + 12 * sc, bubble.top + 28 * sc),
      bubble.width - 24 * sc,
      const Color(0xFFE8D5B0),
      12 * textScale,
      FontWeight.w600,
      maxLines: 4,
    );
    if (canAdvance) {
      final pulse = math.sin(t * math.pi * 2) * 0.5 + 0.5;
      _drawText(
        canvas,
        'Tippe zum Weiter  ▶',
        Offset(bubble.right - 108 * sc, bubble.bottom - 20 * sc),
        96 * sc,
        const Color(0xFFFF8F00).withValues(alpha: 0.45 + pulse * 0.55),
        9 * textScale,
        FontWeight.w800,
        align: TextAlign.end,
      );
    }
    canvas.restore();

    final dotY = 26 * sc;
    for (var i = 0; i < dialogue.intro.length; i++) {
      canvas.drawCircle(
        Offset(size.width - (18 + (dialogue.intro.length - 1 - i) * 12) * sc, dotY),
        3.5 * sc,
        Paint()
          ..color = i == frameIndex
              ? const Color(0xFFFF8F00)
              : Colors.white.withValues(alpha: 0.3),
      );
    }
  }

  void _drawSpeakerIcon(Canvas canvas, String speaker, Offset center, double sc, String animation) {
    final breath = math.sin(t * math.pi * 2) * sc;
    final p = center.translate(0, breath);
    if (speaker == 'brumm') {
      canvas.drawOval(Rect.fromCenter(center: p.translate(0, 8 * sc), width: 34 * sc, height: 38 * sc), Paint()..color = const Color(0xFF795548));
      canvas.drawCircle(p.translate(0, -14 * sc), 18 * sc, Paint()..color = const Color(0xFF795548));
      canvas.drawCircle(p.translate(-12 * sc, -28 * sc), 7 * sc, Paint()..color = const Color(0xFF6D4C41));
      canvas.drawCircle(p.translate(12 * sc, -28 * sc), 7 * sc, Paint()..color = const Color(0xFF6D4C41));
    } else if (speaker == 'ova') {
      final flap = animation == 'wing_flap' ? math.sin(t * math.pi * 8) * 5 * sc : 0.0;
      canvas.drawCircle(p, 15 * sc, Paint()..color = const Color(0xFFFF8F00));
      canvas.drawPath(Path()..moveTo(p.dx - 8 * sc, p.dy - 10 * sc)..lineTo(p.dx - 18 * sc, p.dy - 23 * sc - flap)..lineTo(p.dx - 2 * sc, p.dy - 15 * sc)..close(), Paint()..color = const Color(0xFF5D4037));
      canvas.drawPath(Path()..moveTo(p.dx + 8 * sc, p.dy - 10 * sc)..lineTo(p.dx + 18 * sc, p.dy - 23 * sc + flap)..lineTo(p.dx + 2 * sc, p.dy - 15 * sc)..close(), Paint()..color = const Color(0xFF5D4037));
    } else {
      final tilt = animation == 'look_around' ? math.sin(t * math.pi * 2) * 0.15 : 0.0;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(tilt);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, 8 * sc), width: 28 * sc, height: 22 * sc), Paint()..color = const Color(0xFFE64A19));
      canvas.drawCircle(Offset(0, -10 * sc), 13 * sc, Paint()..color = const Color(0xFFEF6C00));
      canvas.restore();
    }
  }

  String _speakerName(String speaker) => switch (speaker) {
        'ova' => 'Ova',
        'brumm' => 'Brumm',
        _ => 'Fino',
      };

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
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight, height: 1.08)),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _QuestIntroPainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex ||
        oldDelegate.bubbleOpacity != bubbleOpacity ||
        oldDelegate.canAdvance != canAdvance ||
        oldDelegate.t != t;
  }
}
