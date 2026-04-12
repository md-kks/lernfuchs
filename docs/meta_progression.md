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
  "unlockedUpgradeIds": ["leaf_canopy"]
}
```

Quest reward steps are still tracked in `QuestStatus.grantedRewardIds` to avoid
duplicate grants. When a reward is first granted, `QuestRuntime` also applies it
to the profile inventory through `InventoryStore`.

## Baumhaus Upgrades

The first upgrade is `leaf_canopy`. It is unlocked by the sample quest reward
and gives the Baumhaus screen two visible states:

- locked: simple Baumhaus
- unlocked: Baumhaus with Blätterdach

There is no economy balancing, spending, premium logic, cloud sync, or store
flow in this layer.
