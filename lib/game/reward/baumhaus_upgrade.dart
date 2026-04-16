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

const baumhausLaterneUpgrade = BaumhausUpgrade(
  id: 'baumhaus_laterne',
  title: 'Sonnentau-Laterne',
  description: 'Ein warmes Licht für dunkle Nächte im Flüsterwald.',
  resourceId: 'sternensamen',
  resourceAmount: 5,
  lockedLabel: 'Die Dunkelheit umhüllt das Haus.',
  unlockedLabel: 'Die Laterne leuchtet hell am Eingang.',
);

const baumhausBankUpgrade = BaumhausUpgrade(
  id: 'baumhaus_bank',
  title: 'Waldgeister-Bank',
  description: 'Ein gemütlicher Platz zum Ausruhen nach dem Lernen.',
  resourceId: 'sternensamen',
  resourceAmount: 3,
  lockedLabel: 'Kein Platz zum Rasten.',
  unlockedLabel: 'Eine bequeme Holzbank lädt zum Verweilen ein.',
);

const baumhausKristallBlauUpgrade = BaumhausUpgrade(
  id: 'baumhaus_kristall_blau',
  title: 'Hüter-Kristall',
  description: 'Ein magischer Kristall, der das Wissen des Hains bewahrt.',
  resourceId: 'sternensamen',
  resourceAmount: 3,
  lockedLabel: 'Die Magie fehlt noch.',
  unlockedLabel: 'Der blaue Kristall pulsiert voller Energie.',
);

const baumhausGoldenerSchwanzUpgrade = BaumhausUpgrade(
  id: 'baumhaus_goldener_schwanz',
  title: 'Goldener Fuchsschwanz',
  description: 'Ein Zeichen wahrer Meisterschaft in der Silbenkunde.',
  resourceId: 'sternensamen',
  resourceAmount: 2,
  lockedLabel: 'Dein Schweif ist noch gewöhnlich.',
  unlockedLabel: 'Dein Schweif leuchtet nun in strahlendem Gold!',
);

const baumhausUpgrades = [
  baumhausLeafCanopyUpgrade,
  baumhausLaterneUpgrade,
  baumhausBankUpgrade,
  baumhausKristallBlauUpgrade,
  baumhausGoldenerSchwanzUpgrade,
];
