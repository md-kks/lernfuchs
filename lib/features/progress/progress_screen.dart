import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/progress.dart';
import '../../core/services/providers.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_text_styles.dart';
import '../../shared/widgets/star_rating.dart';

/// Fortschritts-Screen — zeigt echte Lerndaten des aktiven Profils.
///
/// Datenquelle: [allProgressProvider] liest alle [TopicProgress]-Einträge
/// aus [StorageService] für das aktive Kinderprofil.
///
/// ### Struktur
/// - **Zusammenfassung**: Avatar, Name, Klasse, Gesamtsterne und Trefferquote.
/// - **Mathe-Bereich**: Alle Mathe-Themen mit Accuracy-Balken.
/// - **Deutsch-Bereich**: Alle Deutsch-Themen mit Accuracy-Balken.
///
/// Ist noch kein Fortschritt vorhanden, wird ein leerer Zustand angezeigt.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final allProgress = ref.watch(allProgressProvider);

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meine Fortschritte')),
        body: const Center(child: Text('Kein Profil ausgewählt.')),
      );
    }

    if (allProgress.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meine Fortschritte')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📊', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('Noch keine Übungen', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              const Text(
                'Hier erscheinen deine Fortschritte\nsobald du geübt hast.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final mathProgress =
        allProgress.where((p) => p.subject == 'math').toList();
    final germanProgress =
        allProgress.where((p) => p.subject == 'german').toList();

    final totalAttempts =
        allProgress.fold(0, (sum, p) => sum + p.totalAttempts);
    final totalCorrect =
        allProgress.fold(0, (sum, p) => sum + p.correctAttempts);
    final overallAccuracy =
        totalAttempts == 0 ? 0.0 : totalCorrect / totalAttempts;
    final stars = (overallAccuracy * 3).round().clamp(0, 3);

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Fortschritte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Zusammenfassung
          Card(
            color: AppColors.primary.withAlpha(20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(profile.avatarEmoji,
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(profile.name, style: AppTextStyles.headlineLarge),
                  Text('${profile.grade}. Klasse',
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 12),
                  StarRating(stars: stars),
                  const SizedBox(height: 8),
                  Text(
                    '$totalCorrect von $totalAttempts richtig '
                    '(${(overallAccuracy * 100).round()}%)',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (mathProgress.isNotEmpty) ...[
            _SubjectSection(
              title: 'Mathematik',
              icon: Icons.calculate_rounded,
              color: AppColors.grade2.primary,
              progress: mathProgress,
            ),
            const SizedBox(height: 16),
          ],

          if (germanProgress.isNotEmpty)
            _SubjectSection(
              title: 'Deutsch',
              icon: Icons.menu_book_rounded,
              color: AppColors.grade1.primary,
              progress: germanProgress,
            ),
        ],
      ),
    );
  }
}

class _SubjectSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<TopicProgress> progress;

  const _SubjectSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...progress.map((p) => _ProgressTile(progress: p, color: color)),
      ],
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final TopicProgress progress;
  final Color color;

  const _ProgressTile({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final accuracy = progress.accuracy;
    final accuracyColor = accuracy >= 0.7
        ? Colors.green
        : accuracy >= 0.4
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _topicLabel(progress.topic),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${(accuracy * 100).round()}%',
                  style: TextStyle(
                    color: accuracyColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: accuracy,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${progress.correctAttempts} von ${progress.totalAttempts} Aufgaben',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _topicLabel(String topic) {
    const labels = <String, String>{
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
      'groesser_kleiner': 'Größer/Kleiner/Gleich',
      'zahlenreihen': 'Zahlenreihen',
      'muster': 'Muster',
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
      'grosse_zahlen': 'Große Zahlen',
      'sachaufgaben_4': 'Sachaufgaben',
      'buchstaben': 'Buchstaben',
      'anlaute': 'Anlaute erkennen',
      'silben': 'Silben',
      'woerter_lesen': 'Wörter lesen',
      'reimwoerter': 'Reimwörter',
      'lueckenwoerter': 'Lückenwörter',
      'buchstaben_salat': 'Buchstaben-Salat',
      'handschrift': 'Handschrift',
      'artikel': 'Artikel',
      'wortarten': 'Wortarten',
      'einzahl_mehrzahl': 'Einzahl/Mehrzahl',
      'rechtschreibung_ie_ei': 'ie oder ei',
      'abc_sortieren': 'ABC sortieren',
      'saetze_bilden': 'Sätze bilden',
      'lesetext': 'Lesetext',
      'zeitformen': 'Zeitformen',
      'wortfamilien': 'Wortfamilien',
      'zusammengesetzte_nomen': 'Zusammengesetzte Nomen',
      'satzarten': 'Satzarten',
      'diktat': 'Diktat',
      'lernwoerter': 'Lernwörter',
      'vier_faelle': 'Vier Fälle',
      'satzglieder': 'Satzglieder',
      'das_dass': 'das / dass',
      'woertliche_rede': 'Wörtliche Rede',
      'fehlertext': 'Fehlertext',
      'kommasetzung': 'Kommasetzung',
      'textarten': 'Textarten',
    };
    return labels[topic] ?? topic;
  }
}
