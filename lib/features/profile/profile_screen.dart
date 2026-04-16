import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/progress.dart';
import '../../core/services/providers.dart';
import '../../shared/constants/app_colors.dart';

/// Auswählbare Emoji-Avatare für ein Kinderprofil.
const _kAvatarEmojis = [
  '🦊', '🐻', '🐼', '🦁', '🐯', '🐨',
  '🦄', '🐸', '🐧', '🦋', '⭐', '🚀',
  '🌈', '🎈', '🦕', '🐙',
];

/// Profil-Verwaltungs-Screen — CRUD für [ChildProfile].
///
/// ### Funktionen
/// - Liste aller Profile mit aktivem Profil hervorgehoben.
/// - Neues Profil anlegen: Avatar, Name, Klasse.
/// - Bestehendes Profil bearbeiten via PopupMenu.
/// - Profil löschen (mindestens 1 Profil muss verbleiben).
/// - Profil wechseln: Tippen auf ein inaktives Profil → [AppSettingsNotifier.switchProfile].
///
/// Daten werden direkt in [StorageService] persistiert.
/// Nach Änderungen wird [allProfilesProvider] via `ref.invalidate()` neu berechnet.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(allProfilesProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProfileDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Neues Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: profiles.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🦊', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    'Noch kein Profil vorhanden.',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text('Lege ein Profil für dein Kind an.'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: profiles.length,
              itemBuilder: (_, i) {
                final profile = profiles[i];
                final isActive = profile.id == settings.activeProfileId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isActive
                        ? const BorderSide(color: AppColors.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: isActive
                          ? AppColors.primary.withAlpha(30)
                          : Colors.grey.shade100,
                      child: Text(profile.avatarEmoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                    title: Row(
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Aktiv',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle:
                        Text('${profile.grade}. Klasse · ${profile.totalStars} ⭐'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'select') {
                          await ref
                              .read(appSettingsProvider.notifier)
                              .switchProfile(profile.id);
                        } else if (action == 'edit') {
                          if (context.mounted) {
                            _showProfileDialog(context, ref, profile);
                          }
                        } else if (action == 'delete') {
                          if (context.mounted) {
                            _confirmDelete(context, ref, profile, profiles.length);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        if (!isActive)
                          const PopupMenuItem(
                            value: 'select',
                            child: ListTile(
                              leading: Icon(Icons.check_circle_outline),
                              title: Text('Auswählen'),
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_rounded),
                            title: Text('Bearbeiten'),
                          ),
                        ),
                        if (profiles.length > 1)
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_rounded,
                                  color: Colors.red),
                              title: Text('Löschen',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      if (!isActive) {
                        await ref
                            .read(appSettingsProvider.notifier)
                            .switchProfile(profile.id);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showProfileDialog(
      BuildContext context, WidgetRef ref, ChildProfile? existing) async {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    int grade = existing?.grade ?? 1;
    String avatar = existing?.avatarEmoji ?? '🦊';
    String? nameError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Neues Profil' : 'Profil bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar picker
                const Text('Avatar wählen:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _kAvatarEmojis.map((emoji) {
                    final selected = avatar == emoji;
                    return GestureDetector(
                      onTap: () => setState(() => avatar = emoji),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withAlpha(40)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Name
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Name des Kindes',
                    errorText: nameError,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => nameError = null),
                ),
                const SizedBox(height: 16),

                // Grade selector
                const Text('Klasse:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(4, (i) {
                    final g = i + 1;
                    final selected = grade == g;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => grade = g),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.forGrade(g).primary
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$g',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: selected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  setState(() => nameError = 'Bitte Namen eingeben');
                  return;
                }
                final storage = ref.read(storageServiceProvider);
                if (existing == null) {
                  final id =
                      '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
                  final profile = ChildProfile(
                    id: id,
                    name: name,
                    grade: grade,
                    avatarEmoji: avatar,
                    createdAt: DateTime.now(),
                  );
                  await storage.saveProfile(profile);
                  await ref
                      .read(appSettingsProvider.notifier)
                      .switchProfile(id);
                } else {
                  existing.name = name;
                  existing.grade = grade;
                  existing.avatarEmoji = avatar;
                  await storage.saveProfile(existing);
                }
                ref.invalidate(allProfilesProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      ChildProfile profile, int profileCount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profil löschen?'),
        content: Text(
          'Soll das Profil von ${profile.name} wirklich gelöscht werden? '
          'Alle Fortschritte gehen verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final storage = ref.read(storageServiceProvider);
      final remaining =
          storage.profiles.where((p) => p.id != profile.id).toList();
      await storage.saveProfiles(remaining);
      // Aktives Profil wechseln falls nötig
      if (ref.read(appSettingsProvider).activeProfileId == profile.id &&
          remaining.isNotEmpty) {
        await ref
            .read(appSettingsProvider.notifier)
            .switchProfile(remaining.first.id);
      }
      ref.invalidate(allProfilesProvider);
    }
  }
}
