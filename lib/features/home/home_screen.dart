import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feature_flags.dart';
import '../../core/services/providers.dart';
import '../../services/streak_service.dart';
import '../baumhaus/baumhaus_screen.dart';
import '../daily/daily_task_generator.dart';
import '../daily/daily_task_screen.dart';
import '../expedition/expedition_generator.dart';
import 'world_map_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  static bool _ttsSpokenThisSession = false;
  late final AnimationController _controller;
  bool _playedToday = false;
  bool _expeditionAvailable = false;
  bool _gameCompleted = false;
  int _streak = 0;
  DailyTaskConfig? _dailyConfig;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final streakService = StreakService();
    final played = await streakService.playedToday;
    final streak = await streakService.currentStreak;
    final config = await DailyTaskGenerator(
      learningEngine: ref.read(learningEngineProvider),
      profileId: ref.read(appSettingsProvider).activeProfileId,
      schoolModeService: ref.read(schoolModeProvider),
    ).generate('fluesterwald');
    final expedition = await ExpeditionGenerator().shouldTriggerExpedition(
      'fluesterwald',
    );
    final gameCompleted = ref
        .read(storageServiceProvider)
        .getBoolValue('game_fully_completed', defaultValue: false);
    if (!mounted) return;
    setState(() {
      _playedToday = played;
      _streak = streak;
      _dailyConfig = config;
      _expeditionAvailable = expedition;
      _gameCompleted = gameCompleted;
    });
    if (!_ttsSpokenThisSession) {
      _ttsSpokenThisSession = true;
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        ref
            .read(ttsServiceProvider)
            .speak(
              gameCompleted
                  ? 'Der Flüsterwald ist für immer in Sicherheit. Fino ist so stolz auf dich - und ich auch.'
                  : played
                  ? 'Schön dass du wieder da bist, Fino!'
                  : config.narrativeText,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _dailyConfig;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              CustomPaint(
                painter: _HomeForestPainter(
                  t: _controller.value,
                  playedToday: _playedToday,
                ),
                // game completion sparkles are drawn by the foreground painter.
                child: const SizedBox.expand(),
              ),
              if (_gameCompleted)
                CustomPaint(
                  painter: _GoldenSparklePainter(t: _controller.value),
                  child: const SizedBox.expand(),
                ),
              SafeArea(
                child: Stack(
                  children: [
                    if (!_playedToday && config != null)
                      Align(
                        alignment: const Alignment(0, 0.40),
                        child: _HomePanel(
                          text: config.narrativeText,
                          streak: _streak,
                          onDaily: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyTaskScreen(),
                            ),
                          ).then((_) => _load()),
                        ),
                      ),
                    if (_playedToday)
                      const Align(
                        alignment: Alignment(0.7, -0.72),
                        child: _DoneBadge(),
                      ),
                    if (_gameCompleted && _playedToday)
                      const Align(
                        alignment: Alignment(0, 0.42),
                        child: _CompletedCampaignPanel(),
                      ),
                    if (FeatureFlags.enableGameWorld)
                      Align(
                        alignment: const Alignment(0, 0.88),
                        child: _HomeButton(
                          text: _gameCompleted
                              ? 'Erinnerungen →'
                              : 'Flüsterwald erkunden →',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WorldMapScreen(),
                            ),
                          ),
                        ),
                      ),
                    if (_expeditionAvailable)
                      Positioned(
                        top: 16,
                        left: MediaQuery.of(context).size.width / 2 - 32,
                        child: Tooltip(
                          message: 'Neue Expedition verfügbar!',
                          child: Transform.scale(
                            scale:
                                1 +
                                math.sin(_controller.value * math.pi * 2) *
                                    0.08,
                            child: const Text(
                              '✉️',
                              style: TextStyle(fontSize: 42),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _BaumhausButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BaumhausScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompletedCampaignPanel extends StatelessWidget {
  const _CompletedCampaignPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xDD3E2108),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Der Flüsterwald ist für immer in Sicherheit.\nFino ist so stolz auf dich - und ich auch.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFE8D5B0),
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _GoldenSparklePainter extends CustomPainter {
  final double t;

  const _GoldenSparklePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x99FFD700);
    for (var i = 0; i < 22; i++) {
      final x = ((17 + i * 43) % 280) / 280 * size.width;
      final y = ((31 + i * 71 + t * 40) % 560) / 560 * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * math.pi * 2 + i);
      final s = 2.5 + (i % 3);
      canvas.drawLine(Offset(-s, 0), Offset(s, 0), paint);
      canvas.drawLine(Offset(0, -s), Offset(0, s), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenSparklePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _BaumhausButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BaumhausButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xCC3E2108),
            border: Border.all(color: const Color(0xFFFF8F00), width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(24, 20),
                painter: _HouseIconPainter(),
              ),
              const SizedBox(height: 2),
              const Text(
                'Baumhaus',
                style: TextStyle(
                  color: Color(0xFFE8D5B0),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HouseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFF8F00);
    canvas.drawPath(
      Path()
        ..moveTo(size.width / 2, 1)
        ..lineTo(size.width - 2, size.height * 0.45)
        ..lineTo(size.width - 5, size.height * 0.45)
        ..lineTo(size.width - 5, size.height - 2)
        ..lineTo(5, size.height - 2)
        ..lineTo(5, size.height * 0.45)
        ..lineTo(2, size.height * 0.45)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HouseIconPainter oldDelegate) => false;
}

class _HomeForestPainter extends CustomPainter {
  final double t;
  final bool playedToday;

  const _HomeForestPainter({required this.t, required this.playedToday});

  @override
  void paint(Canvas canvas, Size size) {
    final sc = math.min(size.width / 280, size.height / 560);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D4A2D), Color(0xFF4A7A4A)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      Offset(size.width - 48 * sc, 60 * sc),
      35 * sc,
      Paint()..color = const Color(0x1FFFFDE7),
    );
    canvas.drawCircle(
      Offset(size.width - 48 * sc, 60 * sc),
      20 * sc,
      Paint()..color = const Color(0xFFFFFDE7),
    );
    for (final x in const [10.0, 42.0, 208.0, 246.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x * sc, size.height * 0.82)
          ..lineTo((x + 24) * sc, size.height * 0.34)
          ..lineTo((x + 48) * sc, size.height * 0.82)
          ..close(),
        Paint()..color = const Color(0xFF1A2E1A),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.80, size.width, size.height * 0.20),
      Paint()..color = const Color(0xFF1E1200),
    );
    final center = playedToday
        ? Offset(size.width - 58 * sc, 138 * sc)
        : Offset(size.width / 2, size.height * 0.61);
    final scale = playedToday ? sc * 0.8 : sc * 1.5;
    final flap = math.sin(t * math.pi * 8) * 5 * scale;
    canvas.drawCircle(
      center,
      16 * scale,
      Paint()..color = const Color(0xFFFF8F00),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 9 * scale, center.dy - 11 * scale)
        ..lineTo(center.dx - 18 * scale, center.dy - 25 * scale - flap)
        ..lineTo(center.dx - 2 * scale, center.dy - 16 * scale)
        ..close(),
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + 9 * scale, center.dy - 11 * scale)
        ..lineTo(center.dx + 18 * scale, center.dy - 25 * scale + flap)
        ..lineTo(center.dx + 2 * scale, center.dy - 16 * scale)
        ..close(),
      Paint()..color = const Color(0xFF5D4037),
    );
  }

  @override
  bool shouldRepaint(covariant _HomeForestPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.playedToday != playedToday;
}

class _HomePanel extends StatelessWidget {
  final String text;
  final int streak;
  final VoidCallback onDaily;

  const _HomePanel({
    required this.text,
    required this.streak,
    required this.onDaily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.84,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3E2108),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF8F00)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (streak >= 2)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '🔥 $streak Tage',
                style: const TextStyle(
                  color: Color(0xFFFF8F00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE8D5B0),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _HomeButton(text: '▶  Tagesaufgabe', onTap: onDaily),
        ],
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF3E2108),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4E8038)),
      ),
      child: const Text(
        'Heute erledigt ✓',
        style: TextStyle(color: Color(0xFFE8F5E9), fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _HomeButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B5E20),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE8F5E9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
