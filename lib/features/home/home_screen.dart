import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                    Align(
                      alignment: const Alignment(0, 0.28),
                      child: _MainMenuPanel(
                        narrativeText: _gameCompleted && _playedToday
                            ? 'Der Flüsterwald ist für immer in Sicherheit.'
                            : _playedToday
                            ? 'Heute erledigt. Du kannst frei weiterlernen.'
                            : config?.narrativeText ??
                                  'Was möchtest du heute machen?',
                        streak: _streak,
                        gameCompleted: _gameCompleted,
                        gameWorldEnabled: FeatureFlags.enableGameWorld,
                        onFreePractice: () =>
                            context.push('/home/freies-ueben'),
                        onAdventure: FeatureFlags.enableGameWorld
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WorldMapScreen(),
                                ),
                              )
                            : null,
                        onDaily: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailyTaskScreen(),
                          ),
                        ).then((_) => _load()),
                        onBaumhaus: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BaumhausScreen(),
                          ),
                        ),
                      ),
                    ),
                    if (_playedToday)
                      const Align(
                        alignment: Alignment(0.7, -0.72),
                        child: _DoneBadge(),
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
                      left: 16,
                      child: _MoreHomeMenuButton(
                        onIntro: () => context.push('/onboarding/child'),
                        onPlacement: () =>
                            context.push('/onboarding/placement'),
                        onParent: () => context.push('/parent'),
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

class _MainMenuPanel extends StatelessWidget {
  final String narrativeText;
  final int streak;
  final bool gameCompleted;
  final bool gameWorldEnabled;
  final VoidCallback onFreePractice;
  final VoidCallback? onAdventure;
  final VoidCallback onDaily;
  final VoidCallback onBaumhaus;

  const _MainMenuPanel({
    required this.narrativeText,
    required this.streak,
    required this.gameCompleted,
    required this.gameWorldEnabled,
    required this.onFreePractice,
    required this.onAdventure,
    required this.onDaily,
    required this.onBaumhaus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: math.min(MediaQuery.of(context).size.width - 32, 520),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xDD3E2108),
        border: Border.all(color: const Color(0xFFFF8F00), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hauptmenü',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (streak >= 2)
                Text(
                  '$streak Tage',
                  style: const TextStyle(
                    color: Color(0xFFFF8F00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            narrativeText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE8D5B0),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width >= 520 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.28,
            children: [
              _MainMenuTile(
                title: 'Freies Lernen',
                subtitle: 'Mathe und Deutsch',
                icon: Icons.school_rounded,
                onTap: onFreePractice,
              ),
              _MainMenuTile(
                title: gameCompleted ? 'Erinnerungen' : 'Abenteuer',
                subtitle: gameWorldEnabled
                    ? 'Flüsterwald erkunden'
                    : 'Bald verfügbar',
                icon: Icons.map_rounded,
                enabled: gameWorldEnabled,
                onTap: onAdventure,
              ),
              _MainMenuTile(
                title: 'Tagesaufgabe',
                subtitle: 'Heute weiterkommen',
                icon: Icons.today_rounded,
                onTap: onDaily,
              ),
              _MainMenuTile(
                title: 'Baumhaus',
                subtitle: 'Belohnungen ansehen',
                icon: Icons.cottage_rounded,
                onTap: onBaumhaus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainMenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _MainMenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = enabled
        ? const Color(0xFFE8D5B0)
        : const Color(0x99E8D5B0);
    final accent = enabled ? const Color(0xFFFF8F00) : const Color(0x66FF8F00);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF2D1808) : const Color(0x992D1808),
            border: Border.all(color: accent, width: 1.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 26),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
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

enum _MoreHomeAction { intro, placement, parent }

class _MoreHomeMenuButton extends StatelessWidget {
  final VoidCallback onIntro;
  final VoidCallback onPlacement;
  final VoidCallback onParent;

  const _MoreHomeMenuButton({
    required this.onIntro,
    required this.onPlacement,
    required this.onParent,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MoreHomeAction>(
      tooltip: 'Weitere Aktionen',
      color: const Color(0xFF3E2108),
      position: PopupMenuPosition.under,
      onSelected: (action) {
        switch (action) {
          case _MoreHomeAction.intro:
            onIntro();
            break;
          case _MoreHomeAction.placement:
            onPlacement();
            break;
          case _MoreHomeAction.parent:
            onParent();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _MoreHomeAction.intro,
          child: Text(
            'Abenteuer-Intro',
            style: TextStyle(color: Color(0xFFE8D5B0)),
          ),
        ),
        PopupMenuItem(
          value: _MoreHomeAction.placement,
          child: Text(
            'Einstufung starten',
            style: TextStyle(color: Color(0xFFE8D5B0)),
          ),
        ),
        PopupMenuItem(
          value: _MoreHomeAction.parent,
          child: Text(
            'Elternbereich',
            style: TextStyle(color: Color(0xFFE8D5B0)),
          ),
        ),
      ],
      child: Material(
        color: Colors.transparent,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x993E2108),
            border: Border.all(color: const Color(0x99FF8F00), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Mehr',
            style: TextStyle(
              color: Color(0xFFE8D5B0),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
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
