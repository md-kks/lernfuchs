import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/learning/learning.dart';
import '../../core/models/subject.dart';
import '../../core/models/task_model.dart';
import '../../core/services/providers.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_text_styles.dart';

/// Arbeitsblatt-Screen — druckbares Layout mit 10 generierten Aufgaben.
///
/// ### Parameter
/// - [grade]: Klassenstufe 1–4
/// - [subjectId]: `'math'` oder `'german'`
/// - [topic]: Themenbezeichner, z.B. `'addition_bis_100'`
///
/// Die 10 Aufgaben werden deterministisch via [LearningEngine.createSession]
/// mit `seed = day * grade` erzeugt — dasselbe Datum und dieselbe Klasse
/// produzieren immer dasselbe Blatt.
///
/// Das Layout ist einem Schulheft-Arbeitsblatt nachempfunden:
/// Kopfzeile mit Logo, Name/Datum-Zeile, nummerierte Aufgaben,
/// Ergebnis-Zeile am Ende. Der Print-Button gibt einen Hinweis,
/// da plattformabhängiges Drucken nicht implementiert ist.
class WorksheetScreen extends ConsumerWidget {
  final int grade;
  final String subjectId;
  final String topic;

  const WorksheetScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.topic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<TaskModel> tasks;
    try {
      final subject = Subject.values.firstWhere((s) => s.id == subjectId);
      final session = ref
          .read(learningEngineProvider)
          .createSession(
            LearningRequest(
              subject: subject,
              grade: grade,
              topic: topic,
              difficulty: 2,
              count: 10,
              seed: DateTime.now().day * grade,
            ),
          );
      tasks = session.tasks;
    } catch (_) {
      tasks = [];
    }

    final colors = AppColors.forGrade(grade);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arbeitsblatt'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Drucken',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Drucken ist auf diesem Gerät nicht verfügbar.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🖨️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'Kein Arbeitsblatt für dieses Thema verfügbar.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Kopfzeile
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.background,
                    border: Border.all(color: colors.secondary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('🦊', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LernFuchs',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                'Klasse $grade · Arbeitsblatt',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              topic.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: _LabeledLine(label: 'Name:')),
                          const SizedBox(width: 16),
                          const Expanded(child: _LabeledLine(label: 'Datum:')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Aufgaben
                ...tasks.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorksheetTask(
                      number: entry.key + 1,
                      task: entry.value,
                      color: colors.primary,
                    ),
                  ),
                ),

                // Auswertungszeile
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.secondary, width: 2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '✓  richtig:  _____ / 10',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _LabeledLine extends StatelessWidget {
  final String label;
  const _LabeledLine({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
        const Expanded(child: Divider(thickness: 1.5, color: Colors.black54)),
      ],
    );
  }
}

class _WorksheetTask extends StatelessWidget {
  final int number;
  final TaskModel task;
  final Color color;

  const _WorksheetTask({
    required this.number,
    required this.task,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withAlpha(30),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Antwortzeil
          Container(
            height: 36,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
