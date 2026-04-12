import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/progress.dart';
import '../../core/services/providers.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_text_styles.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(allProfilesProvider);
    final settings = ref.watch(appSettingsProvider);
    final activeProfileId =
        profiles.any((p) => p.id == settings.activeProfileId)
        ? settings.activeProfileId
        : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _HubHeader(
              activeProfileId: activeProfileId,
              profiles: profiles,
              onProfileChanged: (profileId) => ref
                  .read(appSettingsProvider.notifier)
                  .switchProfile(profileId),
              onManageProfiles: () => context.push('/profiles'),
              onSettings: () => context.push('/settings'),
            ),
            const SizedBox(height: 28),
            Text('Wohin möchtest du?', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _HubTile(
                  title: 'Baumhaus',
                  icon: Icons.park_rounded,
                  onTap: () => context.go('/home/baumhaus'),
                ),
                _HubTile(
                  title: 'Weltkarte',
                  icon: Icons.map_rounded,
                  onTap: () => context.go('/home/weltkarte'),
                ),
                _HubTile(
                  title: 'Tagespfad',
                  icon: Icons.today_rounded,
                  onTap: () => context.go('/home/tagespfad'),
                ),
                _HubTile(
                  title: 'Freies Üben',
                  icon: Icons.school_rounded,
                  onTap: () => context.go('/home/freies-ueben'),
                ),
                _HubTile(
                  title: 'Elternbereich',
                  icon: Icons.supervisor_account_rounded,
                  onTap: () => context.go('/home/elternbereich'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  final String? activeProfileId;
  final List<ChildProfile> profiles;
  final ValueChanged<String> onProfileChanged;
  final VoidCallback onManageProfiles;
  final VoidCallback onSettings;

  const _HubHeader({
    required this.activeProfileId,
    required this.profiles,
    required this.onProfileChanged,
    required this.onManageProfiles,
    required this.onSettings,
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
                'LernFuchs',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              profiles.isEmpty
                  ? TextButton(
                      onPressed: onManageProfiles,
                      child: const Text('Profil anlegen'),
                    )
                  : DropdownButton<String>(
                      value: activeProfileId,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      items: profiles
                          .map(
                            (profile) => DropdownMenuItem<String>(
                              value: profile.id,
                              child: Text(
                                '${profile.avatarEmoji} ${profile.name}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) onProfileChanged(value);
                      },
                    ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.person_rounded),
          tooltip: 'Profile',
          color: AppColors.onSurfaceMuted,
          onPressed: onManageProfiles,
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Einstellungen',
          color: AppColors.onSurfaceMuted,
          onPressed: onSettings,
        ),
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _HubTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 30),
              const Spacer(),
              Text(title, style: AppTextStyles.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
