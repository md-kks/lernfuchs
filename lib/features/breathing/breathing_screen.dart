import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../services/fino_evolution_service.dart';

class BreathingScreen extends ConsumerStatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const BreathingScreen({
    super.key,
    required this.onResume,
    required this.onQuit,
  });

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showResponse = false;
  int _lastPhase = -1;
  int _completedCycles = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )
      ..addListener(_tick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completedCycles++;
          if (_completedCycles >= 4) {
            _showPanel();
          } else {
            _controller.forward(from: 0);
          }
        }
      })
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPhase(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  void _tick() {
    final phase = _phaseFor(_controller.value);
    if (phase != _lastPhase) {
      _lastPhase = phase;
      _speakPhase(phase);
    }
    setState(() {});
  }

  int _phaseFor(double t) {
    if (t < 4 / 12) return 0;
    if (t < 6 / 12) return 1;
    return 2;
  }

  void _speakPhase(int phase) {
    if (_showResponse || !mounted) return;
    final text = switch (phase) {
      0 => 'Einatmen...',
      1 => 'Halten...',
      _ => 'Ausatmen...',
    };
    ref.read(ttsServiceProvider).speak(text);
  }

  void _showPanel() {
    if (_showResponse) return;
    _controller.stop();
    setState(() => _showResponse = true);
  }

  Future<void> _resume() async {
    await ref.read(ttsServiceProvider).speak('Toll! Ich bin bei dir!');
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onResume();
  }

  Future<void> _quit() async {
    await ref
        .read(ttsServiceProvider)
        .speak('Das ist in Ordnung. Fino wartet auf dich!');
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onQuit();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showResponse ? null : _showPanel,
          child: Stack(
            children: [
              CustomPaint(
                painter: _BreathingPainter(
                  t: _controller.value,
                  cyclesCompleted: _completedCycles,
                  showResponse: _showResponse,
                  finoStyle: ref.read(finoEvolutionProvider).style,
                ),
                child: const SizedBox.expand(),
              ),
              if (_showResponse)
                Align(
                  alignment: const Alignment(0, 0.72),
                  child: _BreathingResponsePanel(
                    onResume: _resume,
                    onQuit: _quit,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathingResponsePanel extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const _BreathingResponsePanel({
    required this.onResume,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3E2108),
        border: Border.all(color: const Color(0xFFFF8F00), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Wie fühlst du dich? Bereit für einen neuen Versuch?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE8D5B0),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CirclePauseButton(
                color: Color(0xFF2E7D32),
                text: 'Ja,\nweiter!',
                onTap: onResume,
              ),
              _CirclePauseButton(
                color: Color(0xFF5D3D28),
                text: 'Heute\nPause',
                onTap: onQuit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CirclePauseButton extends StatelessWidget {
  final Color color;
  final String text;
  final VoidCallback onTap;

  const _CirclePauseButton({
    required this.color,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Ink(
        width: 96,
        height: 96,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE8F5E9),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingPainter extends CustomPainter {
  final double t;
  final int cyclesCompleted;
  final bool showResponse;
  final FinoStyle finoStyle;

  const _BreathingPainter({
    required this.t,
    required this.cyclesCompleted,
    required this.showResponse,
    required this.finoStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sc = math.min(size.width / 280, size.height / 560);
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1F0D));
    final starPaint = Paint()..color = const Color(0x99FFFFE6);
    for (var i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset((i * 47 % 280) * sc, (22 + i * 31 % 210) * sc),
        1.5 * sc,
        starPaint,
      );
    }
    final treePaint = Paint()..color = const Color(0xFF091409);
    for (final x in [0.0, 34.0, 240.0, 276.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x * sc, size.height * 0.82)
          ..lineTo((x + 34) * sc, size.height * 0.82)
          ..lineTo((x + 17) * sc, size.height * 0.28)
          ..close(),
        treePaint,
      );
    }

    final center = Offset(size.width / 2, size.height * 0.36);
    final phaseT = t < 4 / 12
        ? t / (4 / 12)
        : t < 6 / 12
        ? 1.0
        : 1.0 - ((t - 6 / 12) / (6 / 12)).clamp(0.0, 1.0);
    final radius = (60 + 30 * Curves.easeInOut.transform(phaseT)) * sc;
    final color = t < 4 / 12
        ? const Color(0xFF4A90D9)
        : t < 6 / 12
        ? const Color(0xFF6BA3BE)
        : const Color(0xFF3A8040);
    canvas.drawCircle(center, 60 * sc, Paint()..color = const Color(0xFF1B3A1B));
    canvas.drawCircle(
      center,
      radius + 15 * sc,
      Paint()..color = const Color(0x264A90D9),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * sc,
    );

    final breatheY = math.sin(phaseT * math.pi) * -3 * sc;
    _drawFino(canvas, size.width / 2 - 34 * sc, size.height * 0.66 + breatheY, 1.0 * sc);
    _drawOva(canvas, size.width / 2 + 38 * sc, size.height * 0.66 - breatheY * 0.5, 0.95 * sc);

    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width / 2 + (i - 1.5) * 18 * sc, size.height - 34 * sc),
        5 * sc,
        Paint()
          ..color = i < cyclesCompleted
              ? const Color(0xFFFF8F00)
              : const Color(0x55FFFFFF),
      );
    }
  }

  void _drawFino(Canvas canvas, double cx, double cy, double sc) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 15 * sc, cy + 12 * sc), width: 30 * sc, height: 16 * sc),
      Paint()..color = const Color(0xFFFFFDE7),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 10 * sc), width: 34 * sc, height: 42 * sc),
      Paint()..color = const Color(0xFFEF6C00),
    );
    canvas.drawCircle(Offset(cx, cy - 12 * sc), 19 * sc, Paint()..color = const Color(0xFFFF8F00));
    canvas.drawPath(
      Path()
        ..moveTo(cx - 14 * sc, cy - 24 * sc)
        ..lineTo(cx - 5 * sc, cy - 46 * sc)
        ..lineTo(cx, cy - 21 * sc)
        ..close(),
      Paint()..color = const Color(0xFFEF6C00),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 14 * sc, cy - 24 * sc)
        ..lineTo(cx + 5 * sc, cy - 46 * sc)
        ..lineTo(cx, cy - 21 * sc)
        ..close(),
      Paint()..color = const Color(0xFFEF6C00),
    );
    canvas.drawCircle(Offset(cx - 7 * sc, cy - 15 * sc), 2.5 * sc, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(cx + 7 * sc, cy - 15 * sc), 2.5 * sc, Paint()..color = Colors.black);
    if (finoStyle.hasEyeGlow) {
      canvas.drawCircle(Offset(cx - 7 * sc, cy - 15 * sc), 4 * sc, Paint()..color = finoStyle.eyeGlowColor);
      canvas.drawCircle(Offset(cx + 7 * sc, cy - 15 * sc), 4 * sc, Paint()..color = finoStyle.eyeGlowColor);
    }
  }

  void _drawOva(Canvas canvas, double cx, double cy, double sc) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 34 * sc, height: 42 * sc),
      Paint()..color = const Color(0xFF8BC34A),
    );
    canvas.drawCircle(Offset(cx, cy - 22 * sc), 17 * sc, Paint()..color = const Color(0xFFA5D66D));
    canvas.drawCircle(Offset(cx - 6 * sc, cy - 24 * sc), 2 * sc, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(cx + 6 * sc, cy - 24 * sc), 2 * sc, Paint()..color = Colors.black);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 23 * sc, cy - 4 * sc), width: 18 * sc, height: 32 * sc),
      Paint()..color = const Color(0x665A8A40),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 23 * sc, cy - 4 * sc), width: 18 * sc, height: 32 * sc),
      Paint()..color = const Color(0x665A8A40),
    );
  }

  @override
  bool shouldRepaint(covariant _BreathingPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.cyclesCompleted != cyclesCompleted ||
      oldDelegate.showResponse != showResponse ||
      oldDelegate.finoStyle != finoStyle;
}
