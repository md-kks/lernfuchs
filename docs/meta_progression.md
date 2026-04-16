# Meta Progression

The first meta-progression slice is intentionally small and offline-only.

## Inventory State

`InventoryState` is stored per profile in SharedPreferences under
`lf_inventory_<profileId>`.

```json
{
  "collectibles": {
    "sternensamen": 3
  },
  "unlockedUpgradeIds": ["baumhaus_laterne", "baumhaus_bank"]
}
```

Quest-Belohnungsschritte werden zusätzlich in `QuestStatus.grantedRewardIds` getrackt, um doppelte Vergaben (Idempotenz) sicher auszuschließen. Der `InventoryStore` ist die maßgebliche Persistenzquelle für das Baumhaus.

## Baumhaus Upgrades

Das Baumhaus (gerendert durch den `BaumhausPainter`) reagiert direkt auf die in `unlockedUpgradeIds` gespeicherten IDs. Im aktuellen Vertical Slice sind folgende Upgrades integriert:

- `baumhaus_laterne`: Eine leuchtende Laterne am Baumhaus.
- `baumhaus_bank`: Eine gemütliche Holzbank vor dem Baumhaus.
- `baumhaus_kristall_blau`: Ein schwebender blauer Wissenskristall.
- `baumhaus_goldener_schwanz`: Ein besonderer Effekt für Fino.

Zusätzlich wächst das Baumhaus in Stufen (`baumhaus_stage`), gesteuert durch den Weltkarten-Fortschritt.

There is no economy balancing, spending, premium logic, cloud sync, or store
flow in this layer.
