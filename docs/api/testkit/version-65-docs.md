# `testkit` — version 65

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files [version 61](version-61-docs.md) lists |
| Version | **65** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.117.0 |
| Status | **Current** |
| Supersedes | [version 64](version-64-docs.md) — the ForeverDB fake had no world coordinates, map geometry, `vendx` price or ForeverDB_Full, so nothing could exercise `LibKa0s-ForeverDB-1.0` minor 4's `Spots` origins, `WorldToMap`, `VendorPriceAt` or `LoadFull` |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `65` |

Everything revision 64 describes is unchanged here except what follows. No file is added or removed,
and no kit case is added, removed or renamed. `framework.lua`'s `Kit.VERSION` is 65. The item is
`ISR3-LK-01` of Ka0sAddonsCommonTasks `docs/2026-11-25-ITEM_SEARCH_ROUND3/` (its `03_SPEC.md` §1.5).

## What changed

### `mock_foreverdb.lua`: map geometry, world coordinates, `vendx` and ForeverDB_Full

`FDB.fixture()` gains the rows `LibKa0s-ForeverDB-1.0` minor 4 reads
([its document](../ForeverDB/version-4-docs.md)), in ForeverDB's shape and **invented**, like every
other row of the fake (ForeverDB's data is GPL-3.0; the kit is MIT):

| Table | Rows | What a case can prove with them |
|---|---|---|
| `umaa` | three, keyed 990401 to 990403, on the invented continent 99: its own map `mapCont` (9903; world X and Y -1000..1000, area 0), and two zones that overlap at world X 0..200, `mapNorth` (9904; X 0..1000, Y -500..500) and `mapSouth` (9905; X -600..200, Y -500..500) | the conversion formula, the smallest-region order, and the continent map as the no-polygon fallback |
| `zbord` | `areaNorth` (990501): a polygon leaving out the zone's southern tenth (map y above 900); `areaSouth` (990502): one leaving out its northern quarter (map y below 250) | the overlap decided by a polygon, not by size, and a point no polygon holds |
| `spw` | `c<wanderer>`: one run with a point in each zone alone, one in the overlap only the north polygon holds, one no polygon holds, one off every region, then a run on a continent no `umaa` row names; `c<gnoll>`: one point, under its `spm` row | `Spots`' `"spw"` origin and grouping, skipped points, and `spm` winning over `spw` |
| `vendx` | `vendor` → `blade` at 1400 (`p`, with a stock `s`) | `VendorPriceAt`'s `"vendx"` origin; it is dearer than the trainer's `vp` 1200, so `VendorPrice(blade)` answers as at revision 64 |
| `npc` | one more: `wanderer` ("Fixture Wanderer", 990005), with no `spm` row | a source whose only spot is in world coordinates |

`FDB.IDS` gains `wanderer`, `continent` (99, which no `umaa` row of ForeverDB v2026.11.25.48 carries),
`mapCont`, `mapNorth`, `mapSouth`, `areaNorth` and `areaSouth`. `meta.counts` reads `npc = 5`.
Every row revision 64 had is unchanged.

**The ForeverDB_Full fake.** Two new public members, `FDB.fullFixture()` (a fresh invented Full
database whose `spz` holds the gnoll on `mapB`, where its `spm` row says `mapA`, and the vendor, which
has no `spm` row) and `FDB.FULL_PRESETS`. `FDB.install` takes, beside its earlier options:

| Option | Meaning |
|---|---|
| `full` | nil (the default) leaves the name `ForeverDB_Full` to the mock's own `C_AddOns`, exactly as before; else a preset: `missing`, `present` (loadable, `GetAddOnInfo`'s reason `DEMAND_LOADED`; the load sets `M.ForeverDBFull`), `disabled` (not loadable, `DISABLED`), `loadfails` (loadable, but the load answers `opts.fullReason`, default `CORRUPT`), `reshaped` (the load sets the string `"ForeverDBFull"`) |
| `fullData` | the Full database the load installs (default `FDB.fullFixture()`) |
| `fullLoaded` | another addon already loaded it when the case starts |
| `onFullLoad` | called inside `LoadAddOn("ForeverDB_Full")` before the global is set, so a case can move the mock's clock (`M.__profileMs`) or a stubbed heap reading the load is measured with |

The handle gains `fullLoads` (the Full loads, counted apart from `loads`) and `fullData`, and
`restore()` also puts back `M.ForeverDBFull`.

## What a consumer owes

The whole-folder copy of `tests/_kit/`, as at every revision. A suite that pins `KIT_VERSION` at 64
re-pins it at 65. A consumer case that counts the fixture's creatures (`#` over `npc`, or
`meta.counts.npc`) re-counts them. A consumer case that asserted the gnoll's `Spots` answer is
unchanged; one that cleared the gnoll's `spm` row and expected no spot now sees its `spw` point.
