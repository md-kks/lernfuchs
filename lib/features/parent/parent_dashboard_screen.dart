import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/progress.dart';
import '../../core/services/providers.dart';
import '../../shared/constants/app_colors.dart';

/// PIN-geschützter Eltern-Dashboard-Screen.
///
/// ### Zugangsschutz
/// Ist in [AppSettings] ein [AppSettings.parentPin] gesetzt, wird beim Öffnen
/// ein PIN-Dialog angezeigt. Erst nach korrekter Eingabe werden die Daten
/// sichtbar. Ist kein PIN gesetzt, ist der Bereich ungeschützt.
///
/// ### Inhalt
/// - Übersicht aller [ChildProfile]e mit Gesamtstatistik
///   (Versuche, Trefferquote, Sterne).
/// - Pro Profil: Mathe- und Deutsch-Auswertung mit Trefferquote je Thema.
/// - Schnelllink zu [WorksheetScreen] für jedes Thema via `/worksheet/:g/:s/:t`.
///
/// Navigiert zu `/parent` aus dem [HomeScreen] (Icon in der Kopfzeile).
class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    final pin = ref.read(appSettingsProvider).parentPin;
    if (pin == null) {
      _authenticated = true; // Kein PIN gesetzt → direkt freischalten
    } else {
      // PIN-Dialog nach dem ersten Frame anzeigen
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPinDialog(pin));
    }
  }

  Future<void> _showPinDialog(String correctPin) async {
    final controller = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Eltern-Bereich'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const Text('Bitte gib den PIN ein:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => error = null),
                onSubmitted: (v) => _checkPin(
                  ctx,
                  v,
                  correctPin,
                  controller,
                  (e) => setState(() => error = e),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (mounted && !_authenticated) context.pop();
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => _checkPin(
                ctx,
                controller.text,
                correctPin,
                controller,
                (e) => setState(() => error = e),
              ),
              child: const Text('Öffnen'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  void _checkPin(
    BuildContext ctx,
    String input,
    String correct,
    TextEditingController ctrl,
    void Function(String?) setError,
  ) {
    if (input.trim() == correct) {
      Navigator.of(ctx).pop();
      setState(() => _authenticated = true);
    } else {
      ctrl.clear();
      setError('Falscher PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Eltern-Bereich')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profiles = ref.watch(allProfilesProvider);
    final settings = ref.watch(appSettingsProvider);
    final learning = ref.read(learningEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eltern-Bereich'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Einstellungen',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('👶', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('Noch keine Profile angelegt.'),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Profil anlegen'),
                    onPressed: () => context.push('/profiles'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              itemBuilder: (_, i) {
                final profile = profiles[i];
                final allProgress = learning.allProgressForProfile(profile.id);
                final isActive = profile.id == settings.activeProfileId;
                return _ProfileCard(
                  profile: profile,
                  allProgress: allProgress,
                  isActive: isActive,
                  federalState: settings.federalState,
                );
              },
            ),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  final ChildProfile profile;
  final List<TopicProgress> allProgress;
  final bool isActive;
  final String federalState;

  const _ProfileCard({
    required this.profile,
    required this.allProgress,
    required this.isActive,
    required this.federalState,
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final totalAttempts = widget.allProgress.fold(
      0,
      (sum, p) => sum + p.totalAttempts,
    );
    final totalCorrect = widget.allProgress.fold(
      0,
      (sum, p) => sum + p.correctAttempts,
    );
    final overallAccuracy = totalAttempts == 0
        ? 0.0
        : totalCorrect / totalAttempts;

    final mathProgress = widget.allProgress
        .where((p) => p.subject == 'math')
        .toList();
    final germanProgress = widget.allProgress
        .where((p) => p.subject == 'german')
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: widget.isActive
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // Profil-Kopfzeile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withAlpha(20),
              child: Text(
                widget.profile.avatarEmoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            title: Row(
              children: [
                Text(
                  widget.profile.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                if (widget.isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Aktiv',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '${widget.profile.grade}. Klasse · '
              '${widget.profile.totalStars} ⭐ · '
              '$totalAttempts Aufgaben · '
              '${(overallAccuracy * 100).round()}% richtig',
            ),
            trailing: IconButton(
              icon: Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),

          // Detailansicht
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mathProgress.isNotEmpty) ...[
                    _SubjectHeader(
                      label: 'Mathematik',
                      icon: Icons.calculate_rounded,
                      color: AppColors.grade2.primary,
                    ),
                    const SizedBox(height: 8),
                    ...mathProgress.map(
                      (p) =>
                          _TopicRow(progress: p, grade: widget.profile.grade),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (germanProgress.isNotEmpty) ...[
                    _SubjectHeader(
                      label: 'Deutsch',
                      icon: Icons.menu_book_rounded,
                      color: AppColors.grade1.primary,
                    ),
                    const SizedBox(height: 8),
                    ...germanProgress.map(
                      (p) =>
                          _TopicRow(progress: p, grade: widget.profile.grade),
                    ),
                  ],
                  if (widget.allProgress.isEmpty)
                    const Text(
                      'Noch keine Übungen absolviert.',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SubjectHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TopicRow extends StatelessWidget {
  final TopicProgress progress;
  final int grade;

  const _TopicRow({required this.progress, required this.grade});

  @override
  Widget build(BuildContext context) {
    final accuracy = progress.accuracy;
    final accuracyColor = accuracy >= 0.7
        ? Colors.green
        : accuracy >= 0.4
        ? Colors.orange
        : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _topicLabel(progress.topic),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${(accuracy * 100).round()}%',
                      style: TextStyle(
                        color: accuracyColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${progress.correctAttempts}/${progress.totalAttempts})',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: accuracy,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Arbeitsblatt-Schnelllink
          IconButton(
            icon: const Icon(Icons.print_rounded, size: 18),
            tooltip: 'Arbeitsblatt',
            color: Colors.grey,
            onPressed: () => context.push(
              '/worksheet/$grade/${progress.subject}/${progress.topic}',
            ),
          ),
        ],
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
      'formen': 'Formen',
      'groesser_kleiner': 'Größer/Kleiner',
      'zahlenreihen': 'Zahlenreihen',
      'muster': 'Muster',
      'schriftliche_addition': 'Schriftl. Addition',
      'schriftliche_subtraktion': 'Schriftl. Subtraktion',
      'multiplikation': 'Multiplikation',
      'division_mit_rest': 'Division m. Rest',
      'groessen_umrechnen': 'Größen umrechnen',
      'geometrie': 'Geometrie',
      'textaufgaben_3': 'Textaufgaben',
      'schriftliche_multiplikation': 'Schriftl. Multiplikation',
      'schriftliche_division': 'Schriftl. Division',
      'brueche': 'Brüche',
      'dezimalzahlen': 'Dezimalzahlen',
      'diagramme': 'Diagramme',
      'grosse_zahlen': 'Große Zahlen',
      'sachaufgaben_4': 'Sachaufgaben',
      'buchstaben': 'Buchstaben',
      'anlaute': 'Anlaute',
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
      'zusammengesetzte_nomen': 'Zus. Nomen',
      'satzarten': 'Satzarten',
      'diktat': 'Diktat',
      'lernwoerter': 'Lernwörter',
      'vier_faelle': 'Vier Fälle',
      'satzglieder': 'Satzglieder',
      'das_dass': 'das/dass',
      'woertliche_rede': 'Wörtliche Rede',
      'fehlertext': 'Fehlertext',
      'kommasetzung': 'Kommasetzung',
      'textarten': 'Textarten',
    };
    return labels[topic] ?? topic;
  }
}
