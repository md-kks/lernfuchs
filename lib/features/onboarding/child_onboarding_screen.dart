import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';

class ChildOnboardingScreen extends ConsumerStatefulWidget {
  const ChildOnboardingScreen({super.key});

  @override
  ConsumerState<ChildOnboardingScreen> createState() =>
      _ChildOnboardingScreenState();
}

class _ChildOnboardingScreenState extends ConsumerState<ChildOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _frameIndex = 0;

  static const _frames = [
    _ChildFrame(
      speaker: 'Fino',
      text: 'Hallo! Ich bin Fino. Ich erforsche den Flüsterwald!',
    ),
    _ChildFrame(
      speaker: 'Fino',
      text:
          'Aber der Nebelschatten hat das Große Buch des Waldes zerstört!',
      brummText: 'Wir brauchen deine Hilfe, Fino!',
    ),
    _ChildFrame(
      speaker: 'Ova',
      text:
          'Kannst du Fino helfen? Lass mich zuerst sehen was du schon kannst!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakFrame());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _speakFrame() async {
    final frame = _frames[_frameIndex];
    await ref.read(ttsServiceProvider).speak(frame.text);
    if (frame.brummText != null) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await ref.read(ttsServiceProvider).speak(frame.brummText!);
    }
  }

  void _advance() {
    if (_frameIndex < _frames.length - 1) {
      setState(() => _frameIndex++);
      _speakFrame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frames[_frameIndex];
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                CustomPaint(
                  painter: _ChildOnboardingPainter(
                    t: _controller.value,
                    frameIndex: _frameIndex,
                  ),
                  child: const SizedBox.expand(),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Spacer(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _SpeechBubble(
                            speaker: frame.speaker,
                            text: frame.text,
                          ),
                        ),
                        if (frame.brummText != null) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _SpeechBubble(
                              speaker: 'Brumm',
                              text: frame.brummText!,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (_frameIndex == _frames.length - 1)
                          _StoneButton(
                            text: 'Ich helfe gerne!',
                            onTap: () => context.go('/onboarding/placement'),
                          )
                        else
                          const Text(
                            'Tippe zum Weiter',
                            style: TextStyle(
                              color: Color(0xFFFF8F00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChildFrame {
  final String speaker;
  final String text;
  final String? brummText;

  const _ChildFrame({
    required this.speaker,
    required this.text,
    this.brummText,
  });
}

class _ChildOnboardingPainter extends CustomPainter {
  final double t;
  final int frameIndex;

  const _ChildOnboardingPainter({required this.t, required this.frameIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF9DC49F), Color(0xFF4A7A4A)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;

    paint.color = const Color(0xFF2D4A2D);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.34), 86, paint);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.32), 104, paint);
    paint.color = const Color(0xFF1E1200);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.70, size.width, size.height * 0.30),
      paint,
    );

    if (frameIndex == 1) {
      paint.color = Colors.black.withOpacity(0.25);
      canvas.drawRect(rect, paint);
    }

    final finoX = frameIndex == 0
        ? -30 + (size.width * 0.5 + 30) * Curves.easeOut.transform(t)
        : size.width * 0.46;
    _drawFino(
      canvas,
      Offset(finoX, size.height * 0.66 + math.sin(t * math.pi * 2) * 2),
      1.15,
    );
    _drawOva(
      canvas,
      Offset(size.width * 0.55, size.height * 0.23),
      frameIndex == 2 ? 1.0 + math.sin(t * math.pi * 8) * 0.03 : 1.0,
    );
    if (frameIndex >= 1) {
      _drawBrumm(
        canvas,
        Offset(size.width * 0.76, size.height * 0.66),
        1.1,
      );
    }
  }

  void _drawFino(Canvas canvas, Offset c, double scale) {
    final paint = Paint()..color = const Color(0xFFEF6C00);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 42 * scale, height: 54 * scale),
      paint,
    );
    paint.color = const Color(0xFFFFB74D);
    canvas.drawCircle(c.translate(0, -28 * scale), 20 * scale, paint);
    final ears = Path()
      ..moveTo(c.dx - 16 * scale, c.dy - 42 * scale)
      ..lineTo(c.dx - 8 * scale, c.dy - 64 * scale)
      ..lineTo(c.dx, c.dy - 42 * scale)
      ..moveTo(c.dx + 16 * scale, c.dy - 42 * scale)
      ..lineTo(c.dx + 8 * scale, c.dy - 64 * scale)
      ..lineTo(c.dx, c.dy - 42 * scale);
    canvas.drawPath(ears, paint);
    paint.color = const Color(0xFF3E2108);
    canvas.drawCircle(c.translate(-7 * scale, -30 * scale), 2 * scale, paint);
    canvas.drawCircle(c.translate(7 * scale, -30 * scale), 2 * scale, paint);
  }

  void _drawBrumm(Canvas canvas, Offset c, double scale) {
    final paint = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 54 * scale, height: 62 * scale),
      paint,
    );
    paint.color = const Color(0xFFBCAAA4);
    canvas.drawCircle(c.translate(0, -30 * scale), 22 * scale, paint);
    paint.color = const Color(0xFF3E2108);
    canvas.drawCircle(c.translate(-7 * scale, -33 * scale), 2.5 * scale, paint);
    canvas.drawCircle(c.translate(7 * scale, -33 * scale), 2.5 * scale, paint);
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
        center: c.translate(-18 * scale, 0),
        width: 17 * scale,
        height: 27 * scale,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(18 * scale, 0),
        width: 17 * scale,
        height: 27 * scale,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ChildOnboardingPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.frameIndex != frameIndex;
}

class _SpeechBubble extends StatelessWidget {
  final String speaker;
  final String text;

  const _SpeechBubble({required this.speaker, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3E2108),
        border: Border.all(color: const Color(0xFFFF8F00), width: 1.3),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            speaker,
            style: const TextStyle(
              color: Color(0xFFFF8F00),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE8D5B0),
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoneButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _StoneButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            border: Border.all(color: const Color(0xFF1B5E20), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE8F5E9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
