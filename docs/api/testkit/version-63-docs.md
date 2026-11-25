# `testkit` — version 63

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files [version 61](version-61-docs.md) lists |
| Version | **63** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.115.0 |
| Status | Superseded |
| Supersedes | [version 62](version-62-docs.md) — the ForeverDB fake carried no `qx`, `rew`, `start` or `skin` rows, so nothing could exercise `LibKa0s-ForeverDB-1.0` minor 2's lookups |
| Superseded by | [version 64](version-64-docs.md) — `mock_foreverdb.lua`'s fixture gains the `obj` rows ForeverDB minor 3's `Object` reads, and the relic that drops from them |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `63` |

Everything revision 62 describes is unchanged here except what follows. No file is added or removed,
no public member of any file is added, removed or renamed, and no kit case is added, removed or
renamed. `framework.lua`'s `Kit.VERSION` is 63. The item is `IS-LK-01` of Ka0sAddonsCommonTasks
`docs/2026-11-25-ITEM_SEARCH/` (its `03_SPEC.md` §3).

## What changed

### `mock_foreverdb.lua`: rows for ForeverDB minor 2

`FDB.fixture()` gains the tables `LibKa0s-ForeverDB-1.0` minor 2's lookups read
([its document](../ForeverDB/version-2-docs.md)), in ForeverDB's shape and **invented**, like every
other row of the fake (ForeverDB's data is GPL-3.0; the kit is MIT):

| Table | Rows | What a case can prove with them |
|---|---|---|
| `item` | five more: `leather`, `hide`, `shard` ("Bladed Fixture Shard", a name that starts with "blade"), `cloak` ("Fixture Bladeweave Cloak", a longer name holding "blade") and `letter` | `SearchItems`' order: prefix, then length, then id (three 14-character names tie on id) |
| `quest` | two more: `hunt` and `summons` | titles and levels for the quest lookups |
| `qx` | `errand` (race mask 5, no class mask, objectives `leather` and `hide`) and `hunt` (race mask 0, class mask 9, prequests in both positions with a repeat, objective `leather`) | `QuestsForItem`: the item index, the masks with 0 and nil as any, the merged prequests |
| `rew` | `blade` ← `errand`; `cloak` ← `hunt`, `errand` | `RewardFrom` in `rew`'s order |
| `start` | `letter` → `summons` | `StartsQuest` |
| `skin` | `leather` ← `gnoll` 2500, `kobold` 7500; `hide` ← `gnoll` 0 (rate unknown) | `SkinnedFrom`'s sort and its unknown rate |

`FDB.IDS` gains `leather` (990104), `hide` (990105), `shard` (990106), `cloak` (990107), `letter`
(990108), `hunt` (990202) and `summons` (990203), every one inside the fake's invented range.
`meta.counts` reads `item = 8` and `quest = 3`. Every row revision 61 had is unchanged, so a consumer
case that read the old fixture reads the same answers.

## What a consumer owes

The whole-folder copy of `tests/_kit/`, as at every revision. A suite that pins `KIT_VERSION` at 62
re-pins it at 63. A consumer case that counts the fixture's items or quests (`#` over `item`, or
`meta.counts`) re-counts them.
