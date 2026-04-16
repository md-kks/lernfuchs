import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/subject.dart';
import '../../core/models/task_model.dart';
import '../../core/services/providers.dart';
import '../../services/season_service.dart';
import '../../services/streak_service.dart';
import 'daily_task_generator.dart';

class DailyTaskScreen extends ConsumerStatefulWidget {
  const DailyTaskScreen({super.key});

  @override
  ConsumerState<DailyTaskScreen> createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends ConsumerState<DailyTaskScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  DailyTaskConfig? _config;
  List<TaskModel> _tasks = const [];
  int _currentTaskIndex = 0;
  bool _showingIntro = true;
  bool _allComplete = false;
  int _streak = 0;
  String? _rewardItemId;
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _load();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await DailyTaskGenerator(
      learningEngine: ref.read(learningEngineProvider),
      profileId: ref.read(appSettingsProvider).activeProfileId,
      schoolModeService: ref.read(schoolModeProvider),
    ).generate('fluesterwald');
    final tasks = config.requests
        .map((request) => ref.read(learningEngineProvider).createSession(request).tasks.first)
        .toList();
    if (!mounted) return;
    setState(() {
      _config = config;
      _tasks = tasks;
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(ttsServiceProvider).speak(config.narrativeText);
    });
  }

  Future<bool> _confirmExit() async {
    if (_allComplete || _showingIntro) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Aufgabe beenden?'),
            content: const Text('Dein Fortschritt wird nicht gespeichert.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Weiterüben')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Beenden')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _submit(dynamic answer) async {
    if (_currentTaskIndex >= _tasks.length) return;
    final task = _tasks[_currentTaskIndex];
    final parsed = task.correctAnswer is int ? int.tryParse(answer.toString()) : answer;
    final result = ref.read(learningEngineProvider).evaluateTask(task, parsed);
    if (result.correct) {
      await ref.read(learningEngineProvider).recordResult(
            profileId: ref.read(appSettingsProvider).activeProfileId,
            subject: Subject.values.firstWhere((subject) => subject.id == task.subject),
            grade: task.grade,
            topic: task.topic,
            correct: true,
          );
      await ref.read(soundServiceProvider).playCorrect();
      if (_currentTaskIndex >= 2) {
        final streakService = StreakService();
        final streak = await streakService.recordTaskCompleted();
        String? item;
        if (streak == 1 && await streakService.awardBaumhausItem('baumhaus_bank')) item = 'baumhaus_bank';
        if (streak == 3 && await streakService.awardBaumhausItem('baumhaus_laterne')) item = 'baumhaus_laterne';
        if (streak == 7 && await streakService.awardBaumhausItem('baumhaus_goldener_schwanz')) item = 'baumhaus_goldener_schwanz';
        if (!mounted) return;
        setState(() {
          _streak = streak;
          _rewardItemId = item;
          _allComplete = true;
        });
        if (streak >= 2) {
          ref.read(audioServiceProvider).playSfx('streak');
        }
        await ref.read(ttsServiceProvider).speak('Wunderbar! Du hast alle drei Aufgaben gelöst!');
        if (streak >= 2) {
          await ref.read(ttsServiceProvider).speak('$streak Tage in Folge!');
        }
        if (item != null) {
          await ref.read(ttsServiceProvider).speak('Du hast ${baumhausItems[item]} für dein Baumhaus verdient!');
        }
      } else {
        setState(() {
          _currentTaskIndex++;
          _answerController.clear();
        });
      }
    } else {
      await ref.read(soundServiceProvider).playWrong();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final season = ref.read(seasonServiceProvider).context;
    return PopScope(
      canPop: _allComplete || _showingIntro,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmExit() && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (config == null || _tasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_showingIntro) {
              return _DailyIntro(
                config: config,
                season: season,
                t: _controller.value,
                onBack: () => Navigator.pop(context),
                onStart: () => setState(() => _showingIntro = false),
              );
            }
            if (_allComplete) {
              return _DailyCompletion(
                t: _controller.value,
                season: season,
                streak: _streak,
                rewardItemId: _rewardItemId,
                onMap: () => Navigator.pop(context),
              );
            }
            return _DailyTaskBody(
              task: _tasks[_currentTaskIndex],
              index: _currentTaskIndex,
              answerController: _answerController,
              onSubmit: _submit,
            );
          },
        ),
      ),
    );
  }
}

class _DailyIntro extends StatelessWidget {
  final DailyTaskConfig config;
  final SeasonContext? season;
  final double t;
  final VoidCallback onBack;
  final VoidCallback onStart;

  const _DailyIntro({required this.config, required this.season, required this.t, required this.onBack, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(painter: _TwilightPainter(t: t, speaker: config.narrativeSpeaker, dawn: false, season: season), child: const SizedBox.expand()),
        SafeArea(
          child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, color: Colors.white)),
        ),
        Align(
          alignment: const Alignment(0, 0.42),
          child: _WoodPanel(title: _speakerName(config.narrativeSpeaker), body: config.narrativeText),
        ),
        Align(
          alignment: const Alignment(0, 0.82),
          child: _StoneButton(text: '▶  Los gehts!', onTap: onStart),
        ),
      ],
    );
  }
}

class _DailyTaskBody extends StatelessWidget {
  final TaskModel task;
  final int index;
  final TextEditingController answerController;
  final ValueChanged<dynamic> onSubmit;

  const _DailyTaskBody({
    required this.task,
    required this.index,
    required this.answerController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final choices = (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Aufgabe ${index + 1} von 3', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: i < index ? const Color(0xFFFF8F00) : i == index ? const Color(0xFF4E8038) : const Color(0xFF2D1500),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const Spacer(),
            Text(task.question, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            if (choices.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: choices.take(4).map((choice) => _StoneButton(text: choice.toString(), onTap: () => onSubmit(choice))).toList(),
              )
            else
              Column(
                children: [
                  TextField(controller: answerController, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'Antwort')),
                  const SizedBox(height: 16),
                  _StoneButton(text: 'Prüfen', onTap: () => onSubmit(answerController.text)),
                ],
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _DailyCompletion extends StatelessWidget {
  final double t;
  final SeasonContext? season;
  final int streak;
  final String? rewardItemId;
  final VoidCallback onMap;

  const _DailyCompletion({required this.t, required this.season, required this.streak, required this.rewardItemId, required this.onMap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(painter: _TwilightPainter(t: t, speaker: 'fino', dawn: true, season: season), child: const SizedBox.expand()),
        Align(
          alignment: const Alignment(0, 0.32),
          child: _WoodPanel(
            title: 'Gut gemacht!',
            body: [
              if (streak >= 2) '$streak Tage in Folge!',
              if (rewardItemId != null) 'Neues Baumhaus-Item: ${baumhausItems[rewardItemId]}!',
            ].join('\n'),
          ),
        ),
        Align(alignment: const Alignment(0, 0.82), child: _StoneButton(text: 'Zur Karte', onTap: onMap)),
      ],
    );
  }
}

class _TwilightPainter extends CustomPainter {
  final double t;
  final String speaker;
  final bool dawn;
  final SeasonContext? season;

  const _TwilightPainter({required this.t, required this.speaker, required this.dawn, required this.season});

  @override
  void paint(Canvas canvas, Size size) {
    final sc = math.min(size.width / 280, size.height / 560);
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dawn ? const [Color(0xFF4A7A4A), Color(0xFF9DC49F)] : const [Color(0xFF2D4A2D), Color(0xFF4A7A4A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);
    canvas.drawCircle(Offset(size.width - 48 * sc, 60 * sc), 35 * sc, Paint()..color = const Color(0x1FFFFDE7));
    canvas.drawCircle(Offset(size.width - 48 * sc, 60 * sc), 20 * sc, Paint()..color = const Color(0xFFFFFDE7));
    for (final x in [8.0, 42.0, 230.0, 266.0]) {
      canvas.drawPath(Path()..moveTo(x * sc, size.height * 0.8)..lineTo((x + 24) * sc, size.height * 0.35)..lineTo((x + 48) * sc, size.height * 0.8)..close(), Paint()..color = const Color(0xFF1A2E1A));
    }
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(Offset((30 + i * 28 + math.sin(t * math.pi * 2 + i) * 4) * sc, (110 + (i % 4) * 38) * sc), 2 * sc, Paint()..color = const Color(0xB3FFFF64));
    }
    _drawSeasonalExtras(canvas, size, sc);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2), Paint()..color = const Color(0xFF1E1200));
    _drawCharacter(canvas, Offset(size.width / 2, size.height * 0.66 + math.sin(t * math.pi * 2) * 4 * sc), sc * 1.4, speaker);
  }

  void _drawSeasonalExtras(Canvas canvas, Size size, double sc) {
    final context = season;
    if (context == null) return;
    if (context.season == Season.winter) {
      final snowPaint = Paint()
        ..color = const Color(0xB3FFFFFF)
        ..strokeWidth = sc;
      for (var i = 0; i < 9; i++) {
        final x = (24 + i * 31) * sc;
        final y = (70 + (i % 4) * 42 + math.sin(t * math.pi * 2 + i) * 5) * sc;
        canvas.drawLine(Offset(x - 4 * sc, y), Offset(x + 4 * sc, y), snowPaint);
        canvas.drawLine(Offset(x, y - 4 * sc), Offset(x, y + 4 * sc), snowPaint);
      }
    } else if (context.season == Season.autumn) {
      for (var i = 0; i < 10; i++) {
        final p = Offset((18 + i * 27) * sc, (80 + (i % 5) * 44) * sc);
        canvas.drawOval(Rect.fromCenter(center: p, width: 5 * sc, height: 9 * sc), Paint()..color = [const Color(0xFFD84315), const Color(0xFFFF8F00), const Color(0xFF8D6E63)][i % 3]);
      }
    }
    if (context.isEvening || context.isNight) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x1F001428));
    }
    if (context.specialDay == SpecialDay.birthday) {
      for (var i = 0; i < 16; i++) {
        canvas.drawRect(Rect.fromLTWH((12 + i * 17) * sc, (44 + (i % 6) * 34) * sc, 3 * sc, 6 * sc), Paint()..color = const Color(0xFFFFD700));
      }
    }
  }

  void _drawCharacter(Canvas canvas, Offset p, double sc, String speaker) {
    if (speaker == 'brumm') {
      canvas.drawOval(Rect.fromCenter(center: p.translate(0, 16 * sc), width: 36 * sc, height: 44 * sc), Paint()..color = const Color(0xFF795548));
      canvas.drawCircle(p.translate(0, -14 * sc), 20 * sc, Paint()..color = const Color(0xFF795548));
    } else if (speaker == 'ova') {
      canvas.drawCircle(p, 16 * sc, Paint()..color = const Color(0xFFFF8F00));
      canvas.drawPath(Path()..moveTo(p.dx - 9 * sc, p.dy - 11 * sc)..lineTo(p.dx - 18 * sc, p.dy - 25 * sc)..lineTo(p.dx - 2 * sc, p.dy - 16 * sc)..close(), Paint()..color = const Color(0xFF5D4037));
      canvas.drawPath(Path()..moveTo(p.dx + 9 * sc, p.dy - 11 * sc)..lineTo(p.dx + 18 * sc, p.dy - 25 * sc)..lineTo(p.dx + 2 * sc, p.dy - 16 * sc)..close(), Paint()..color = const Color(0xFF5D4037));
    } else {
      canvas.drawOval(Rect.fromCenter(center: p.translate(0, 12 * sc), width: 30 * sc, height: 24 * sc), Paint()..color = const Color(0xFFE64A19));
      canvas.drawCircle(p.translate(0, -10 * sc), 14 * sc, Paint()..color = const Color(0xFFEF6C00));
    }
  }

  @override
  bool shouldRepaint(covariant _TwilightPainter oldDelegate) => oldDelegate.t != t || oldDelegate.dawn != dawn || oldDelegate.speaker != speaker || oldDelegate.season != season;
}

class _WoodPanel extends StatelessWidget {
  final String title;
  final String body;

  const _WoodPanel({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF3E2108), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFF8F00))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: const TextStyle(color: Color(0xFFFF8F00), fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE8D5B0), fontSize: 16)),
      ]),
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
      color: const Color(0xFF1B5E20),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Text(text, style: const TextStyle(color: Color(0xFFE8F5E9), fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

String _speakerName(String speaker) => switch (speaker) {
      'brumm' => 'Brumm',
      'fino' => 'Fino',
      _ => 'Ova',
    };
