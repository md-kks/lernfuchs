import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/learning.dart';
import '../../core/models/subject.dart';
import '../../core/models/task_model.dart';
import '../../core/services/providers.dart';
import '../../services/streak_service.dart';
import 'expedition_generator.dart';

class ExpeditionScreen extends ConsumerStatefulWidget {
  final String worldId;

  const ExpeditionScreen({super.key, required this.worldId});

  @override
  ConsumerState<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends ConsumerState<ExpeditionScreen> {
  ExpeditionConfig? _config;
  List<TaskModel> _tasks = const [];
  int _currentStationIndex = 0;
  bool _showingIntro = true;
  bool _allComplete = false;
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await ExpeditionGenerator().generate(widget.worldId);
    if (!mounted) return;
    if (config == null) {
      Navigator.pop(context);
      return;
    }
    final tasks = config.stationIds
        .map(_requestForStation)
        .map((request) => ref.read(learningEngineProvider).createSession(request).tasks.first)
        .toList();
    setState(() {
      _config = config;
      _tasks = tasks;
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(ttsServiceProvider).speak(config.storyIntro.map((f) => f.text).join(' '));
    });
  }

  LearningRequest _requestForStation(String stationId) {
    return switch (stationId) {
      'lichtung' => const LearningRequest(subject: Subject.math, grade: 1, topic: 'zahlen_bis_10', difficulty: 1, count: 1),
      'alter_baum' => const LearningRequest(subject: Subject.german, grade: 1, topic: 'buchstaben', difficulty: 1, count: 1),
      'bruecke' => const LearningRequest(subject: Subject.german, grade: 1, topic: 'silben', difficulty: 1, count: 1),
      'waldsee' => const LearningRequest(subject: Subject.math, grade: 1, topic: 'muster', difficulty: 1, count: 1),
      _ => const LearningRequest(subject: Subject.math, grade: 1, topic: 'zahlen_bis_20', difficulty: 1, count: 1),
    };
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
    if (_currentStationIndex >= _tasks.length) return;
    final task = _tasks[_currentStationIndex];
    final parsed = task.correctAnswer is int ? int.tryParse(answer.toString()) : answer;
    final result = ref.read(learningEngineProvider).evaluateTask(task, parsed);
    if (!result.correct) {
      await ref.read(soundServiceProvider).playWrong();
      return;
    }
    await ref.read(learningEngineProvider).recordResult(
          profileId: ref.read(appSettingsProvider).activeProfileId,
          subject: Subject.values.firstWhere((subject) => subject.id == task.subject),
          grade: task.grade,
          topic: task.topic,
          correct: true,
        );
    await ref.read(soundServiceProvider).playCorrect();
    if (_currentStationIndex >= 2) {
      final config = _config!;
      await ExpeditionGenerator().recordExpeditionPlayed(config.worldId, config.storyId);
      await StreakService().awardBaumhausItem('baumhaus_kristall_blau');
      if (!mounted) return;
      setState(() => _allComplete = true);
      await ref.read(ttsServiceProvider).speak(config.storyOutro);
    } else {
      setState(() {
        _currentStationIndex++;
        _answerController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return PopScope(
      canPop: _allComplete || _showingIntro,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmExit() && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Expedition')),
        body: config == null || _tasks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _body(config),
      ),
    );
  }

  Widget _body(ExpeditionConfig config) {
    if (_showingIntro) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(config.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            for (final frame in config.storyIntro) Text(frame.text, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton(onPressed: () => setState(() => _showingIntro = false), child: const Text('▶  Expedition starten')),
          ],
        ),
      );
    }
    if (_allComplete) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💎 💎 💎', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 20),
            Text(config.storyOutro, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('Expedition abgeschlossen! Die Erinnerung ist wieder da.'),
            const SizedBox(height: 28),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Zurück zur Karte')),
          ],
        ),
      );
    }
    final task = _tasks[_currentStationIndex];
    final choices = (task.metadata['choices'] as List?)?.cast<dynamic>() ?? const [];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Expedition: Station ${_currentStationIndex + 1} von 3', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          Text(task.question, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          if (choices.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: choices.take(4).map((choice) => ElevatedButton(onPressed: () => _submit(choice), child: Text(choice.toString()))).toList(),
            )
          else
            Column(
              children: [
                TextField(controller: _answerController, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'Antwort')),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => _submit(_answerController.text), child: const Text('Prüfen')),
              ],
            ),
          const Spacer(),
        ],
      ),
    );
  }
}
