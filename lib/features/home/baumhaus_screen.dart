import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../game/reward/baumhaus_upgrade.dart';
import '../../game/reward/inventory_state.dart';
import '../../game/reward/inventory_store.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_text_styles.dart';

class BaumhausScreen extends ConsumerStatefulWidget {
  const BaumhausScreen({super.key});

  @override
  ConsumerState<BaumhausScreen> createState() => _BaumhausScreenState();
}

class _BaumhausScreenState extends ConsumerState<BaumhausScreen> {
  final _inventoryStore = const InventoryStore();
  late Future<InventoryState> _inventoryFuture;
  String? _profileId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInventory();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);
    final profileId =
        profile?.id ?? ref.watch(appSettingsProvider).activeProfileId;
    if (_profileId != profileId) {
      _profileId = profileId;
      _inventoryFuture = _inventoryStore.loadForProfile(profileId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baumhaus'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<InventoryState>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          final inventory = snapshot.data ?? const InventoryState();
          final upgrade = baumhausLeafCanopyUpgrade;
          final unlocked = inventory.hasUpgrade(upgrade.id);
          final sternensamen = inventory.collectibleAmount(upgrade.resourceId);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Dein Baumhaus', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 16),
              _BaumhausPreview(unlocked: unlocked),
              const SizedBox(height: 20),
              Text(
                unlocked ? upgrade.unlockedLabel : upgrade.lockedLabel,
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: 24),
              _InventorySummary(sternensamen: sternensamen),
              const SizedBox(height: 16),
              _UpgradeTile(
                upgrade: upgrade,
                unlocked: unlocked,
                currentAmount: sternensamen,
              ),
            ],
          );
        },
      ),
    );
  }

  void _loadInventory() {
    final profileId = ref.read(appSettingsProvider).activeProfileId;
    _profileId = profileId;
    _inventoryFuture = _inventoryStore.loadForProfile(profileId);
  }
}

class _BaumhausPreview extends StatelessWidget {
  final bool unlocked;

  const _BaumhausPreview({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFE7F6E7) : const Color(0xFFF3F0EA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unlocked ? const Color(0xFF5DA05D) : AppColors.onSurfaceMuted,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(unlocked ? '🌳' : '🌲', style: const TextStyle(fontSize: 68)),
          const SizedBox(height: 10),
          Text(
            unlocked ? 'Baumhaus mit Blätterdach' : 'Einfaches Baumhaus',
            style: AppTextStyles.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _InventorySummary extends StatelessWidget {
  final int sternensamen;

  const _InventorySummary({required this.sternensamen});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('✦', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Sternensamen', style: AppTextStyles.titleLarge),
            ),
            Text('$sternensamen', style: AppTextStyles.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _UpgradeTile extends StatelessWidget {
  final BaumhausUpgrade upgrade;
  final bool unlocked;
  final int currentAmount;

  const _UpgradeTile({
    required this.upgrade,
    required this.unlocked,
    required this.currentAmount,
  });

  @override
  Widget build(BuildContext context) {
    final hasResources = currentAmount >= upgrade.resourceAmount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(upgrade.title, style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(upgrade.description),
            const SizedBox(height: 12),
            Text(
              unlocked
                  ? 'Freigeschaltet'
                  : hasResources
                  ? 'Bereit durch Quest-Belohnung'
                  : '${upgrade.resourceAmount} Sternensamen noetig',
            ),
          ],
        ),
      ),
    );
  }
}
