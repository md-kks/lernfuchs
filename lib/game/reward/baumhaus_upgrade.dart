class BaumhausUpgrade {
  final String id;
  final String title;
  final String description;
  final String resourceId;
  final int resourceAmount;
  final String lockedLabel;
  final String unlockedLabel;

  const BaumhausUpgrade({
    required this.id,
    required this.title,
    required this.description,
    required this.resourceId,
    required this.resourceAmount,
    required this.lockedLabel,
    required this.unlockedLabel,
  });
}

const baumhausLeafCanopyUpgrade = BaumhausUpgrade(
  id: 'leaf_canopy',
  title: 'Blätterdach',
  description: 'Ovas erster Zahlenwald-Fund macht das Baumhaus lebendiger.',
  resourceId: 'sternensamen',
  resourceAmount: 3,
  lockedLabel: 'Ein schlichtes Baumhaus wartet auf den ersten Fund.',
  unlockedLabel: 'Ein frisches Blätterdach wächst über dem Baumhaus.',
);

const baumhausUpgrades = [baumhausLeafCanopyUpgrade];
