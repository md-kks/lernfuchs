import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/engine/curriculum.dart';
import '../../core/models/progress.dart';
import '../../core/services/providers.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_text_styles.dart';
import '../../shared/widgets/rounded_button.dart';

/// Erstmaliger Setup-Assistent — wird nur beim ersten App-Start angezeigt.
///
/// ### Seiten
/// 1. Willkommens-Seite mit App-Logo und Kurzvorstellung.
/// 2. Bundesland-Auswahl (Pflicht) — steuert den Lehrplan via [Curriculum].
/// 3. Bestätigungs-Seite mit Feature-Übersicht.
///
/// ### Abschluss
/// Beim letzten "Weiter"-Tippen werden:
/// - Das gewählte Bundesland in [appSettingsProvider] gespeichert.
/// - Ein Standard-[ChildProfile] angelegt (Name „Kind", Klasse 1).
/// - [AppSettings.onboardingDone] auf `true` gesetzt.
/// Danach navigiert die App zu `/home`. Der [GoRouter]-Redirect stellt sicher,
/// dass dieser Screen nie erneut angezeigt wird.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  String? _selectedState;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final notifier = ref.read(appSettingsProvider.notifier);
    final storage = ref.read(storageServiceProvider);

    // Bundesland speichern
    await notifier.updateFederalState(_selectedState ?? 'BY');

    // Standard-Profil anlegen (falls noch keines vorhanden)
    if (storage.profiles.isEmpty) {
      final id = 'default_${DateTime.now().millisecondsSinceEpoch}';
      final profile = ChildProfile(
        id: id,
        name: 'Kind',
        grade: 1,
        avatarEmoji: '🦊',
        createdAt: DateTime.now(),
      );
      await storage.saveProfile(profile);
      await notifier.switchProfile(id);
    }

    // Onboarding als abgeschlossen markieren
    await notifier.setOnboardingDone();

    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Seitenindikator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? AppColors.primary
                          : AppColors.primary.withAlpha(80),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _Page1(),
                  _Page2(
                    selectedState: _selectedState,
                    onSelect: (s) => setState(() => _selectedState = s),
                  ),
                  _Page3(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: RoundedButton(
                label: _currentPage < 2 ? 'Weiter' : 'Los geht\'s!',
                width: double.infinity,
                color: AppColors.primary,
                icon: _currentPage < 2
                    ? Icons.arrow_forward_rounded
                    : Icons.rocket_launch_rounded,
                onPressed: _currentPage == 1 && _selectedState == null
                    ? null
                    : _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🦊', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text(
            'Willkommen bei\nLernFuchs!',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Mathe & Deutsch üben für Klasse 1–4.\n100% offline. Kein Abo. Keine Daten.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _Page2 extends StatelessWidget {
  final String? selectedState;
  final ValueChanged<String> onSelect;

  const _Page2({required this.selectedState, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'In welchem Bundesland\nbist du?',
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text(
              'Das hilft uns, die Aufgaben an deinen Lehrplan anzupassen.'),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: kFederalStates.length,
              itemBuilder: (_, i) {
                final (code, name) = kFederalStates[i];
                final selected = selectedState == code;
                return InkWell(
                  onTap: () => onSelect(code),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withAlpha(30)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
}

class _Page3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🚀', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text(
            'Bereit zum Üben!',
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const _FeatureRow(emoji: '✅', text: '100% offline'),
          const _FeatureRow(emoji: '🔒', text: 'Keine Daten, kein Account'),
          const _FeatureRow(emoji: '♾️', text: 'Immer neue Aufgaben'),
          const _FeatureRow(emoji: '🖨️', text: 'Arbeitsblätter drucken'),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String text;
  const _FeatureRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
