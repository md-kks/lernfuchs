import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../services/fino_evolution_service.dart';

class FinaleCutsceneScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const FinaleCutsceneScreen({super.key, required this.onComplete});

  @override
  ConsumerState<FinaleCutsceneScreen> createState() =>
      _FinaleCutsceneScreenState();
}

class _FinaleCutsceneScreenState extends ConsumerState<FinaleCutsceneScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Set<int> _spokenScenes = <int>{};
  bool _showContinue = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )
      ..addListener(_tick)
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakForScene(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  void _tick() {
    final seconds = _controller.value * 35;
    final scene = _sceneFor(seconds);
    if (!_spokenScenes.contains(scene)) _speakForScene(scene);
    if (seconds >= 32 && !_showContinue) {
      setState(() => _showContinue = true);
    } else {
      setState(() {});
    }
  }

  int _sceneFor(double seconds) {
    if (seconds < 5) return 0;
    if (seconds < 12) return 1;
    if (seconds < 20) return 2;
    if (seconds < 27) return 3;
    return 4;
  }

  void _speakForScene(int scene) {
    _spokenScenes.add(scene);
    final tts = ref.read(ttsServiceProvider);
    switch (scene) {
      case 0:
        tts.speak('Du hast es geschafft! Das letzte Rätsel ist gelöst.');
      case 1:
        tts.speak('Das Große Buch des Waldes ist wieder vollständig!');
      case 2:
        tts.speak('Der Nebelschatten ist verschwunden - für immer!');
      case 3:
        tts.speak('Fino ist jetzt der Hüter des Wissens. Genau wie du.');
        Future<void>.delayed(const Duration(seconds: 3), () {
          if (mounted && _sceneFor(_controller.value * 35) == 3) {
            tts.speak(
              'Du hast unglaubliche Ausdauer bewiesen. Dieses Abenteuer wirst du nie vergessen.',
            );
          }
        });
      case 4:
        tts.speak('Das Buch ist vollständig. Aber das Wissen lebt in dir.');
    }
  }

  void _complete() {
    ref.read(ttsServiceProvider).stop();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            CustomPaint(
              painter: _FinalePainter(
                seconds: _controller.value * 35,
                finoStyle: FinoStyle.forStage(4),
              ),
              child: const SizedBox.expand(),
            ),
            if (_showContinue)
              Align(
                alignment: const Alignment(0, 0.82),
                child: GestureDetector(
                  onTap: _complete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8F5E9)),
                    ),
                    child: const Text(
                      '▶  Weiter',
                      style: TextStyle(
                        color: Color(0xFFE8F5E9),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FinalePainter extends CustomPainter {
  final double seconds;
  final FinoStyle finoStyle;

  const _FinalePainter({required this.seconds, required this.finoStyle});

  @override
  void paint(Canvas canvas, Size size) {
    final sc = math.min(size.width / 280, size.height / 560);
    final scene = seconds < 5
        ? 0
        : seconds < 12
        ? 1
        : seconds < 20
        ? 2
        : seconds < 27
        ? 3
        : 4;
    switch (scene) {
      case 0:
        _drawStarlitDesert(canvas, size, sc, seconds / 5);
      case 1:
        _drawBookAwakens(canvas, size, sc, (seconds - 5) / 7);
      case 2:
        _drawShadowDissolves(canvas, size, sc, (seconds - 12) / 8);
      case 3:
        _drawAllTogether(canvas, size, sc, (seconds - 20) / 7);
      default:
        _drawEnding(canvas, size, sc, (seconds - 27) / 8);
    }
  }

  void _drawStarlitDesert(Canvas canvas, Size size, double sc, double t) {
    _drawGradient(canvas, size, const Color(0xFF1A1A2E), const Color(0xFFD6B66C));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.62), width: 220 * sc, height: 70 * sc),
      Paint()..color = const Color(0xFFB8860B),
    );
    for (var i = 0; i < 24; i++) {
      final p = Offset(size.width / 2 + math.cos(i) * 70 * sc * t, size.height * 0.38 + math.sin(i * 2) * 45 * sc * t);
      canvas.drawCircle(p, 2 * sc, Paint()..color = const Color(0xFFFFD700).withValues(alpha: 1 - t * 0.3));
    }
    _drawFino(canvas, size.width / 2, size.height * 0.56, 1.2 * sc, finoStyle);
  }

  void _drawBookAwakens(Canvas canvas, Size size, double sc, double t) {
    _drawGradient(canvas, size, const Color(0xFF31553A), const Color(0xFF9DC49F));
    final center = Offset(size.width / 2, size.height * 0.45);
    final colors = const [
      Color(0xFF4E8038),
      Color(0xFF29B6F6),
      Color(0xFFF0F8FF),
      Color(0xFFD6A63A),
    ];
    final starts = [
      Offset(20 * sc, size.height - 60 * sc),
      Offset(size.width - 20 * sc, size.height - 60 * sc),
      Offset(25 * sc, 40 * sc),
      Offset(size.width - 25 * sc, 40 * sc),
    ];
    for (var i = 0; i < 4; i++) {
      final p = Offset.lerp(starts[i], center, Curves.easeInOut.transform(t.clamp(0, 1)))!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 38 * sc, height: 52 * sc), Radius.circular(4 * sc)),
        Paint()..color = colors[i],
      );
    }
    if (t > 0.78) _drawGreatBook(canvas, center, 1.4 * sc, glow: true);
  }

  void _drawShadowDissolves(Canvas canvas, Size size, double sc, double t) {
    _drawGradient(canvas, size, const Color(0xFF111827), const Color(0xFF31553A));
    final center = Offset(size.width / 2, size.height * 0.48);
    _drawGreatBook(canvas, center, 1.5 * sc, glow: true);
    final shadowScale = (1 - ((t - 0.35) / 0.35).clamp(0, 1)).clamp(0.0, 1.0);
    canvas.drawPath(
      Path()
        ..moveTo(size.width / 2 - 54 * sc * shadowScale, size.height * 0.24)
        ..cubicTo(size.width / 2 - 20 * sc, size.height * 0.14, size.width / 2 + 24 * sc, size.height * 0.14, size.width / 2 + 58 * sc * shadowScale, size.height * 0.25)
        ..cubicTo(size.width / 2 + 30 * sc, size.height * 0.36, size.width / 2 - 30 * sc, size.height * 0.36, size.width / 2 - 54 * sc * shadowScale, size.height * 0.24),
      Paint()..color = const Color(0xFF1A1A2E).withValues(alpha: shadowScale),
    );
    for (var i = 0; i < 30; i++) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset((12 + i * 19 % 250) * sc, (70 + (i * 31 + t * 220) % 390) * sc),
          width: 2 * sc,
          height: 6 * sc,
        ),
        Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.7),
      );
    }
  }

  void _drawAllTogether(Canvas canvas, Size size, double sc, double t) {
    _drawGradient(canvas, size, const Color(0xFFFFD180), const Color(0xFF9DC49F));
    for (var i = 0; i < 8; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset((20 + i * 31) * sc, (70 + i * 19) * sc), width: 8 * sc, height: 4 * sc),
        Paint()..color = const Color(0xFFFFB6C1),
      );
    }
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(Offset((25 + i * 30) * sc, (100 + i * 17) * sc), 2 * sc, Paint()..color = const Color(0xAAFFFF64));
    }
    _drawBaumhausHint(canvas, size, sc);
    _drawBrumm(canvas, size.width * 0.28, size.height * 0.66, 1.15 * sc);
    _drawFino(canvas, size.width * 0.50, size.height * 0.65, 1.35 * sc, finoStyle);
    _drawOva(canvas, size.width * 0.73, size.height * 0.64, 1.0 * sc);
    _drawGreatBook(canvas, Offset(size.width / 2, size.height * 0.30), 1.1 * sc, glow: true);
  }

  void _drawEnding(Canvas canvas, Size size, double sc, double t) {
    _drawGradient(canvas, size, const Color(0xFF31553A), const Color(0xFF1A1A2E));
    final center = Offset(size.width / 2, size.height * 0.35);
    _drawGreatBook(canvas, center, 1.45 * sc, glow: t < 0.45);
    for (var i = 0; i < 4; i++) {
      final rect = Rect.fromCenter(center: center.translate((i - 1.5) * 24 * sc, 18 * sc), width: 18 * sc, height: 12 * sc);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(4 * sc)), Paint()..color = const Color(0x553E2108));
    }
    _drawFino(canvas, size.width / 2, size.height * 0.72, 1.0 * sc, finoStyle);
  }

  void _drawGradient(Canvas canvas, Size size, Color top, Color bottom) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawGreatBook(Canvas canvas, Offset c, double sc, {required bool glow}) {
    if (glow) {
      canvas.drawCircle(c, 42 * sc, Paint()..color = const Color(0x26FFD700));
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 56 * sc, height: 42 * sc), Radius.circular(5 * sc)),
      Paint()..color = const Color(0xFF3E2108),
    );
    canvas.drawLine(c.translate(0, -20 * sc), c.translate(0, 20 * sc), Paint()..color = const Color(0xFFFFD700)..strokeWidth = 2 * sc);
  }

  void _drawBaumhausHint(Canvas canvas, Size size, double sc) {
    canvas.drawRect(Rect.fromLTWH(size.width * 0.42, size.height * 0.17, 44 * sc, 110 * sc), Paint()..color = const Color(0xFF3E2108));
    canvas.drawPath(
      Path()
        ..moveTo(size.width / 2, size.height * 0.12)
        ..lineTo(size.width / 2 + 16 * sc, size.height * 0.05)
        ..lineTo(size.width / 2 + 32 * sc, size.height * 0.12)
        ..lineTo(size.width / 2 + 16 * sc, size.height * 0.20)
        ..close(),
      Paint()..color = const Color(0xFF29B6F6),
    );
  }

  void _drawFino(Canvas canvas, double cx, double cy, double sc, FinoStyle style) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 20 * sc, cy + 10 * sc), width: 36 * sc, height: 17 * sc), Paint()..color = style.hasGoldenTailTip ? const Color(0xFFFFD700) : const Color(0xFFFFFDE7));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 10 * sc), width: 34 * sc, height: 42 * sc), Paint()..color = const Color(0xFFEF6C00));
    canvas.drawCircle(Offset(cx, cy - 13 * sc), 20 * sc, Paint()..color = const Color(0xFFFF8F00));
    canvas.drawCircle(Offset(cx - 7 * sc, cy - 15 * sc), 2.5 * sc, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(cx + 7 * sc, cy - 15 * sc), 2.5 * sc, Paint()..color = Colors.black);
    if (style.hasEyeGlow) {
      canvas.drawCircle(Offset(cx - 7 * sc, cy - 15 * sc), 4 * sc, Paint()..color = style.eyeGlowColor);
      canvas.drawCircle(Offset(cx + 7 * sc, cy - 15 * sc), 4 * sc, Paint()..color = style.eyeGlowColor);
    }
    if (style.hasBook) _drawGreatBook(canvas, Offset(cx, cy + 2 * sc), 0.22 * sc, glow: false);
  }

  void _drawBrumm(Canvas canvas, double cx, double cy, double sc) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 8 * sc), width: 45 * sc, height: 55 * sc), Paint()..color = const Color(0xFF795548));
    canvas.drawCircle(Offset(cx, cy - 20 * sc), 22 * sc, Paint()..color = const Color(0xFF8D6E63));
    canvas.drawLine(Offset(cx - 22 * sc, cy - 3 * sc), Offset(cx - 42 * sc, cy - 30 * sc), Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 7 * sc..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(cx + 22 * sc, cy - 3 * sc), Offset(cx + 42 * sc, cy - 30 * sc), Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 7 * sc..strokeCap = StrokeCap.round);
  }

  void _drawOva(Canvas canvas, double cx, double cy, double sc) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 34 * sc, height: 42 * sc), Paint()..color = const Color(0xFF8BC34A));
    canvas.drawCircle(Offset(cx, cy - 22 * sc), 17 * sc, Paint()..color = const Color(0xFFA5D66D));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 22 * sc, cy - 4 * sc), width: 16 * sc, height: 32 * sc), Paint()..color = const Color(0x665A8A40));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 22 * sc, cy - 4 * sc), width: 16 * sc, height: 32 * sc), Paint()..color = const Color(0x665A8A40));
  }

  @override
  bool shouldRepaint(covariant _FinalePainter oldDelegate) =>
      oldDelegate.seconds != seconds || oldDelegate.finoStyle != finoStyle;
}
