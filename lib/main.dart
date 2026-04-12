import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/tts_service.dart';
import 'core/services/sound_service.dart';
import 'core/services/providers.dart';

/// App-Einstiegspunkt — initialisiert alle Singletons vor `runApp`.
///
/// ### Initialisierungsreihenfolge
/// 1. [StorageService.init] — SharedPreferences laden
/// 2. [TtsService.create] — TTS-Engine konfigurieren (de-DE, 0.45x, 1.1 Pitch)
/// 3. [SoundService.create] — SoundService auf TTS-Basis erstellen
/// 4. [ProviderScope] mit `overrides` — TTS und Sound als Provider verfügbar
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  // TTS + Sound einmalig initialisieren und als Provider-Override bereitstellen
  final tts = await TtsService.create();
  final sound = SoundService.create(tts);

  runApp(
    ProviderScope(
      overrides: [
        ttsServiceProvider.overrideWithValue(tts),
        soundServiceProvider.overrideWithValue(sound),
      ],
      child: const LernFuchsApp(),
    ),
  );
}

/// Root-Widget — reagiert auf Barrierefreiheits-Einstellungen.
///
/// Beobachtet [appSettingsProvider] und passt an:
/// - **Schriftgröße**: [AppSettings.fontSize] als [TextScaler] (1.0 normal,
///   1.3 groß — einstellbar in [SettingsScreen]).
/// - **Hochkontrast**: [AppSettings.highContrast] wechselt zum
///   [AppTheme.highContrast]-Theme mit stärkeren Farbkontrasten.
class LernFuchsApp extends ConsumerWidget {
  const LernFuchsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      title: 'LernFuchs',
      theme: settings.highContrast ? AppTheme.highContrast : AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(settings.fontSize),
        ),
        child: child!,
      ),
    );
  }
}
