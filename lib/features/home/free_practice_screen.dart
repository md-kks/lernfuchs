import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_text_styles.dart';

/// Freies Ueben — Klassenauswahl-Grid und Profilkopf.
///
/// Dieser Screen enthaelt den bisherigen freien Lernfluss. Die Zielrouten
/// `/home/subject/<grade>/<subject>` bleiben unveraendert, damit bestehende
/// Deep Links und Ruecknavigation weiter funktionieren.
class FreePracticeScreen extends ConsumerWidget {
  const FreePracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                avatarEmoji: profile?.avatarEmoji ?? '🦊',
                profileName: profile?.name,
                onProfileTap: () => context.push('/profiles'),
                onSettingsTap: () => context.push('/settings'),
                onProgressTap: () => context.push('/progress'),
                onParentTap: () => context.push('/parent'),
              ),
              const SizedBox(height: 32),
              Text(
                'Wähle deine Klasse!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: const [
                    _GradeCard(grade: 1),
                    _GradeCard(grade: 2),
                    _GradeCard(grade: 3),
                    _GradeCard(grade: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String avatarEmoji;
  final String? profileName;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onProgressTap;
  final VoidCallback onParentTap;

  const _Header({
    required this.avatarEmoji,
    required this.profileName,
    required this.onProfileTap,
    required this.onSettingsTap,
    required this.onProgressTap,
    required this.onParentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('🦊', style: TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Freies Üben',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                profileName == null
                    ? 'Mathe & Deutsch, Kl. 1–4'
                    : '$profileName · Mathe & Deutsch',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded),
          color: AppColors.onSurfaceMuted,
          tooltip: 'Fortschritte',
          onPressed: onProgressTap,
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          color: AppColors.onSurfaceMuted,
          tooltip: 'Einstellungen',
          onPressed: onSettingsTap,
        ),
        IconButton(
          icon: const Icon(Icons.supervisor_account_rounded),
          color: AppColors.onSurfaceMuted,
          tooltip: 'Eltern-Bereich',
          onPressed: onParentTap,
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Text(avatarEmoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradeCard extends StatelessWidget {
  final int grade;
  const _GradeCard({required this.grade});

  static const _labels = ['1. Klasse', '2. Klasse', '3. Klasse', '4. Klasse'];
  static const _emojis = ['🌱', '⭐', '🚀', '🏆'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.forGrade(grade);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/home/subject/$grade/math'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, colors.accent],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_emojis[grade - 1], style: const TextStyle(fontSize: 36)),
                const Spacer(),
                Text(
                  _labels[grade - 1],
                  style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
