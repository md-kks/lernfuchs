import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';
import 'placement_tasks.dart';

class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _answerController = TextEditingController();
  final Map<String, double> _testedCompetencies = {};
  int _taskIndex = 0;
  int _answeredCount = 0;
  int _wrongStreak = 0;
  double? _lastCorrectDifficulty;
  bool _busy = false;
  bool _completed = false;
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(
            'Ich möchte sehen was du schon kannst, damit Fino genau die richtigen Abenteuer für dich findet!',
          );
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(dynamic rawAnswer) async {
    if (_busy || _completed) return;
    setState(() => _busy = true);

    final definition = placementTasks[_taskIndex];
    final task = definition.task;
    final parsed = task.correctAnswer is int
        ? int.tryParse(rawAnswer.toString())
        : rawAnswer.toString();
    final result = ref.read(learningEngineProvider).evaluateTask(task, parsed);
    _testedCompetencies[definition.competencyId] = definition.difficulty;
    _answeredCount++;

    if (result.correct) {
      _wrongStreak = 0;
      _lastCorrectDifficulty = definition.difficulty;
      await ref.read(ttsServiceProvider).speak('Super!');
    } else {
      _wrongStreak++;
      await ref.read(ttsServiceProvider).speak('Nicht schlimm!');
    }

    if (!mounted) return;
    final shouldStop =
        _wrongStreak >= 2 || _taskIndex >= placementTasks.length - 1;
    if (shouldStop) {
      await _finishPlacement();
      return;
    }
    setState(() {
      _taskIndex++;
      _busy = false;
      _answerController.clear();
    });
  }

  Future<void> _finishPlacement() async {
    final baseElo = _lastCorrectDifficulty ?? 400.0;
    final results = <String, double>{};
    for (final competencyId in placementCompetencies) {
      results[competencyId] =
          _testedCompetencies[competencyId] ?? (baseElo * 0.9);
    }

    final storage = ref.read(storageServiceProvider);
    for (final entry in results.entries) {
      await storage.setOnboardingValue('child_elo_${entry.key}', entry.value);
    }
    await storage.setOnboardingValue('placement_elo_results', results);
    await storage.setPlacementCompleted(true);
    await ref.read(appSettingsProvider.notifier).setOnboardingDone();

    final text = _answeredCount <= 2
        ? 'Toll! Wir fangen am Anfang an - da macht das Lernen am meisten Spaß!'
        : _answeredCount < placementTasks.length
            ? 'Wunderbar! Ich weiß jetzt genau was Fino für dich bereit hält!'
            : 'Beeindruckend! Du bist schon sehr weit gekommen!';
    if (!mounted) return;
    setState(() {
      _completed = true;
      _busy = false;
      _resultText = text;
    });
    await ref.read(ttsServiceProvider).speak(text);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final definition = placementTasks[_taskIndex];
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              CustomPaint(
                painter: _PlacementPainter(t: _controller.value),
                child: const SizedBox.expand(),
              ),
              SafeArea(
                child: _completed
                    ? _CompletionBody(text: _resultText ?? '')
                    : _TaskBody(
                        definition: definition,
                        index: _taskIndex,
                        answerController: _answerController,
                        busy: _busy,
                        onSubmit: _submit,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskBody extends StatelessWidget {
  final PlacementTaskDefinition definition;
  final int index;
  final TextEditingController answerController;
  final bool busy;
  final ValueChanged<dynamic> onSubmit;

  const _TaskBody({
    required this.definition,
    required this.index,
    required this.answerController,
    required this.busy,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final task = definition.task;
    final choices = (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [];
    final dotCount = task.metadata['dotCount'] as int?;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Fino trifft dich zum ersten Mal',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFFF8F00),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Aufgabe ${index + 1}',
            style: const TextStyle(color: Color(0xFFE8D5B0)),
          ),
          const Spacer(),
          Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF3E2108),
              border: Border.all(color: const Color(0xFFFF8F00), width: 1.5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotCount != null) _DotGrid(count: dotCount),
                if (dotCount != null) const SizedBox(height: 14),
                Text(
                  task.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE8D5B0),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 20),
                if (choices.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: choices
                        .map(
                          (choice) => _AnswerStone(
                            text: choice.toString(),
                            enabled: !busy,
                            onTap: () => onSubmit(choice),
                          ),
                        )
                        .toList(),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: answerController,
                          enabled: !busy,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 22),
                          decoration: const InputDecoration(
                            filled: true,
                            hintText: 'Antwort',
                          ),
                          onSubmitted: onSubmit,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _AnswerStone(
                        text: 'OK',
                        enabled: !busy,
                        onTap: () => onSubmit(answerController.text),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _CompletionBody extends StatelessWidget {
  final String text;

  const _CompletionBody({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF3E2108),
          border: Border.all(color: const Color(0xFFFF8F00), width: 1.5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Fino ist bereit!',
              style: TextStyle(
                color: Color(0xFFFF8F00),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE8D5B0),
                fontSize: 16,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  final int count;

  const _DotGrid({required this.count});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(
        count,
        (_) => Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD700),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _AnswerStone extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onTap;

  const _AnswerStone({
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Ink(
          width: text.length > 2 ? 76 : 58,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF5D4037),
            border: Border.all(color: const Color(0xFF3E2108), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacementPainter extends CustomPainter {
  final double t;

  const _PlacementPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6FAE70), Color(0xFF2D4A2D)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;
    paint.color = const Color(0xFF1A2E1A);
    for (var i = 0; i < 8; i++) {
      final x = size.width * (i / 7);
      final path = Path()
        ..moveTo(x - 44, size.height * 0.74)
        ..lineTo(x, size.height * (0.38 + (i % 2) * 0.05))
        ..lineTo(x + 44, size.height * 0.74)
        ..close();
      canvas.drawPath(path, paint);
    }
    paint.color = const Color(0xFF1E1200);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.74, size.width, size.height * 0.26),
      paint,
    );
    _drawFino(
      canvas,
      Offset(size.width * 0.28, size.height * 0.71 + math.sin(t * math.pi * 2) * 2),
      0.95,
    );
    _drawOva(canvas, Offset(size.width * 0.76, size.height * 0.23), 0.95);
  }

  void _drawFino(Canvas canvas, Offset c, double scale) {
    final paint = Paint()..color = const Color(0xFFEF6C00);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 38 * scale, height: 50 * scale),
      paint,
    );
    paint.color = const Color(0xFFFFB74D);
    canvas.drawCircle(c.translate(0, -27 * scale), 18 * scale, paint);
    paint.color = const Color(0xFF3E2108);
    canvas.drawCircle(c.translate(-6 * scale, -29 * scale), 2 * scale, paint);
    canvas.drawCircle(c.translate(6 * scale, -29 * scale), 2 * scale, paint);
  }

  void _drawOva(Canvas canvas, Offset c, double scale) {
    final paint = Paint()..color = const Color(0xFFFFB74D);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 30 * scale, height: 38 * scale),
      paint,
    );
    paint.color = const Color(0xFFFFE0B2);
    canvas.drawCircle(c.translate(0, -9 * scale), 14 * scale, paint);
    paint.color = const Color(0xFFFFCC80);
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-18 * scale, math.sin(t * math.pi * 8) * 2),
        width: 17 * scale,
        height: 27 * scale,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(18 * scale, -math.sin(t * math.pi * 8) * 2),
        width: 17 * scale,
        height: 27 * scale,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PlacementPainter oldDelegate) =>
      oldDelegate.t != t;
}
