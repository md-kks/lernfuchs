import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/engine/curriculum.dart';
import '../../core/services/providers.dart';

/// Einstellungs-Screen — reagiert auf [AppSettings] via Riverpod.
///
/// ### Bereiche
/// - **Bundesland**: Öffnet einen Dialog mit [kFederalStates]-Auswahl.
///   Ändert den Lehrplan-Kontext für [SubjectOverviewScreen].
/// - **Töne & Sprache**: Sound-Toggle → [AppSettingsNotifier.toggleSound],
///   TTS-Toggle → [AppSettingsNotifier.toggleTts] + [TtsService.setEnabled].
/// - **Eltern-Bereich**: PIN setzen/ändern/entfernen via Dialog.
///   4-stellige Ziffern-PIN; `null` = kein Schutz.
/// - **App-Info**: Statische Versionsinformationen, Datenschutzhinweis.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final tts = ref.read(ttsServiceProvider);

    final stateName = kFederalStates
        .firstWhere(
          (s) => s.$1 == settings.federalState,
          orElse: () => ('BY', 'Bayern'),
        )
        .$2;

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Bundesland'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_rounded),
              title: const Text('Bundesland'),
              subtitle: Text(stateName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  _showFederalStateDialog(context, ref, settings.federalState),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader('Töne & Sprache'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: const Text('Soundeffekte'),
                  value: settings.soundEnabled,
                  onChanged: (v) => notifier.toggleSound(v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.record_voice_over_rounded),
                  title: const Text('Aufgaben vorlesen'),
                  subtitle: const Text('Text-to-Speech (de-DE)'),
                  value: settings.ttsEnabled,
                  onChanged: (v) {
                    notifier.toggleTts(v);
                    tts.setEnabled(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader('Barrierefreiheit'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.contrast_rounded),
                  title: const Text('Hochkontrast'),
                  subtitle: const Text('Dunkles Theme mit starken Farben'),
                  value: settings.highContrast,
                  onChanged: (v) => notifier.toggleHighContrast(v),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.text_fields_rounded),
                  title: const Text('Schriftgröße'),
                  subtitle: Text(_fontSizeLabel(settings.fontSize)),
                  trailing: SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 1.0, label: Text('A')),
                      ButtonSegment(
                          value: 1.15,
                          label: Text('A+',
                              style: TextStyle(fontSize: 15))),
                      ButtonSegment(
                          value: 1.3,
                          label: Text('A++',
                              style: TextStyle(fontSize: 17))),
                    ],
                    selected: {settings.fontSize},
                    onSelectionChanged: (s) =>
                        notifier.updateFontSize(s.first),
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader('Eltern-Bereich'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_rounded),
              title: Text(settings.parentPin != null
                  ? 'PIN ändern / entfernen'
                  : 'PIN setzen'),
              subtitle: Text(settings.parentPin != null
                  ? 'Elternbereich ist geschützt'
                  : 'Kein PIN gesetzt'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPinDialog(context, ref, settings.parentPin),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader('App-Info'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Version'),
                  trailing: Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Datenschutz'),
                  subtitle: const Text(
                    'Diese App erhebt keine Daten.',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fontSizeLabel(double factor) {
    if (factor <= 1.0) return 'Normal';
    if (factor <= 1.15) return 'Groß';
    return 'Sehr groß';
  }

  Future<void> _showFederalStateDialog(
      BuildContext context, WidgetRef ref, String current) async {
    final notifier = ref.read(appSettingsProvider.notifier);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bundesland wählen'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: kFederalStates.length,
            itemBuilder: (_, i) {
              final (code, name) = kFederalStates[i];
              return RadioListTile<String>(
                value: code,
                groupValue: current,
                title: Text(name),
                onChanged: (v) {
                  if (v != null) notifier.updateFederalState(v);
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPinDialog(
      BuildContext context, WidgetRef ref, String? existingPin) async {
    final notifier = ref.read(appSettingsProvider.notifier);
    final controller = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existingPin != null ? 'PIN verwalten' : 'PIN setzen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (existingPin != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.lock_open_rounded, color: Colors.red),
                  title: const Text('PIN entfernen'),
                  onTap: () {
                    notifier.clearParentPin();
                    Navigator.of(ctx).pop();
                  },
                ),
                const Divider(),
                const Text('Oder neuen PIN setzen:'),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '4-stelliger PIN',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => error = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final pin = controller.text.trim();
                if (pin.length != 4 || int.tryParse(pin) == null) {
                  setState(() => error = 'Bitte 4 Ziffern eingeben');
                  return;
                }
                notifier.setParentPin(pin);
                Navigator.of(ctx).pop();
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              fontSize: 12,
            ),
      ),
    );
  }
}
