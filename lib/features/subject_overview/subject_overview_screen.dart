import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/subject.dart';
import '../../core/services/providers.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/task_card.dart';

/// Themenübersicht für ein Fach und eine Klasse.
///
/// Liest das aktive Bundesland aus [appSettingsProvider] und baut die Themen
/// via [LearningEngine] auf. Jede Kachel führt zu [ExerciseScreen].
///
/// Der Fach-Wechsler ([_SubjectToggle]) navigiert zwischen Mathe und Deutsch
/// innerhalb derselben Klasse.
class SubjectOverviewScreen extends ConsumerWidget {
  final int grade;
  final String subjectId;

  const SubjectOverviewScreen({
    super.key,
    required this.grade,
    required this.subjectId,
  });

  Subject get subject => Subject.values.firstWhere((s) => s.id == subjectId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final federalState = ref.watch(appSettingsProvider).federalState;
    final learning = ref.watch(learningEngineProvider);
    final topics = learning.topicsFor(
      federalState: federalState,
      subject: subject,
      grade: grade,
    );
    final colors = AppColors.forGrade(grade);

    return Scaffold(
      appBar: AppBar(
        title: Text('${subject.label} — $grade. Klasse'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Fach-Wechsler
          _SubjectToggle(grade: grade, activeSubject: subjectId),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              itemBuilder: (_, i) {
                final topic = topics[i];
                final profileId = ref
                    .watch(appSettingsProvider)
                    .activeProfileId;
                final progress = ref.watch(
                  topicProgressProvider((
                    profileId: profileId,
                    subject: subjectId,
                    grade: grade,
                    topic: topic,
                  )),
                );
                final stars = (progress.accuracy * 3).round().clamp(0, 3);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(
                    title: _topicLabel(topic),
                    subtitle: _topicSubtitle(topic),
                    color: colors.primary,
                    stars: stars,
                    progress: progress.accuracy,
                    onTap: () => context.go(
                      '/home/subject/$grade/$subjectId/exercise/$topic',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _topicLabel(String topic) {
    final labels = <String, String>{
      'zahlen_bis_10': 'Zahlen bis 10',
      'zahlen_bis_20': 'Zahlen bis 20',
      'addition_bis_10': 'Addition bis 10',
      'subtraktion_bis_10': 'Subtraktion bis 10',
      'addition_bis_100': 'Addition bis 100',
      'subtraktion_bis_100': 'Subtraktion bis 100',
      'einmaleins': 'Einmaleins',
      'uhrzeit': 'Uhrzeit',
      'geld': 'Geld zählen',
      'zahlenmauern': 'Zahlenmauern',
      'rechenketten': 'Rechenketten',
      'textaufgaben': 'Textaufgaben',
      'formen': 'Formen erkennen',
      'groesser_kleiner': 'Größer / Kleiner / Gleich',
      'zahlenreihen': 'Zahlenreihen',
      'muster': 'Muster fortsetzen',
      'schriftliche_addition': 'Schriftliche Addition',
      'schriftliche_subtraktion': 'Schriftliche Subtraktion',
      'multiplikation': 'Multiplikation',
      'division_mit_rest': 'Division mit Rest',
      'groessen_umrechnen': 'Größen umrechnen',
      'geometrie': 'Geometrie',
      'textaufgaben_3': 'Textaufgaben',
      'schriftliche_multiplikation': 'Schriftliche Multiplikation',
      'schriftliche_division': 'Schriftliche Division',
      'brueche': 'Brüche',
      'dezimalzahlen': 'Dezimalzahlen',
      'diagramme': 'Diagramme lesen',
      'grosse_zahlen': 'Große Zahlen & Runden',
      'sachaufgaben_4': 'Sachaufgaben',
      'buchstaben': 'Buchstaben',
      'anlaute': 'Anlaute erkennen',
      'silben': 'Silben',
      'woerter_lesen': 'Wörter lesen',
      'reimwoerter': 'Reimwörter',
      'lueckenwoerter': 'Lückenwörter',
      'buchstaben_salat': 'Buchstaben-Salat',
      'handschrift': 'Handschrift üben',
      'artikel': 'Artikel (der/die/das)',
      'wortarten': 'Wortarten',
      'einzahl_mehrzahl': 'Einzahl / Mehrzahl',
      'rechtschreibung_ie_ei': 'ie oder ei?',
      'abc_sortieren': 'ABC sortieren',
      'saetze_bilden': 'Sätze bilden',
      'lesetext': 'Lesetext & Fragen',
      'zeitformen': 'Zeitformen',
      'wortfamilien': 'Wortfamilien',
      'zusammengesetzte_nomen': 'Zusammengesetzte Nomen',
      'satzarten': 'Satzarten',
      'diktat': 'Diktat',
      'lernwoerter': 'Lernwörter',
      'vier_faelle': 'Die vier Fälle',
      'satzglieder': 'Satzglieder',
      'das_dass': 'das oder dass?',
      'woertliche_rede': 'Wörtliche Rede',
      'fehlertext': 'Fehlertext korrigieren',
      'kommasetzung': 'Kommasetzung',
      'textarten': 'Bericht & Erzählung',
    };
    return labels[topic] ?? topic;
  }

  String _topicSubtitle(String topic) {
    final subs = <String, String>{
      'addition_bis_10': 'z.B. 3 + 4 = ?',
      'subtraktion_bis_10': 'z.B. 7 – 3 = ?',
      'addition_bis_100': 'z.B. 24 + 38 = ?',
      'einmaleins': '1×1 bis 10×10',
      'division_mit_rest': 'z.B. 17 ÷ 5 = 3 Rest 2',
      'artikel': 'der Hund, die Katze, das Haus',
      'einzahl_mehrzahl': 'Hund → Hunde',
      'das_dass': 'Das Kind / Ich glaube, dass …',
      'wortarten': 'Nomen, Verb, Adjektiv',
    };
    return subs[topic] ?? '$grade. Klasse';
  }
}

class _SubjectToggle extends StatelessWidget {
  final int grade;
  final String activeSubject;

  const _SubjectToggle({required this.grade, required this.activeSubject});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.forGrade(grade).primary,
      child: Row(
        children: [
          _Tab(
            label: 'Mathe',
            icon: Icons.calculate_rounded,
            active: activeSubject == 'math',
            onTap: () => context.go('/home/subject/$grade/math'),
          ),
          _Tab(
            label: 'Deutsch',
            icon: Icons.menu_book_rounded,
            active: activeSubject == 'german',
            onTap: () => context.go('/home/subject/$grade/german'),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white.withAlpha(40) : Colors.transparent,
            border: active
                ? const Border(
                    bottom: BorderSide(color: Colors.white, width: 3),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
