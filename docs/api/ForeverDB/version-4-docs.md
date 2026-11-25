# `LibKa0s-ForeverDB-1.0` — version 4

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the ForeverDB surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-ForeverDB-1.0` |
| Files and minors | `ForeverDB.lua` minor **4** |
| Shipped in | v1.117.0 |
| Status | **Current** |
| Supersedes | [version 3](./version-3-docs.md) (shipped in v1.116.0) — `Spots` read only the base `spm` slice (5000 keys), so most vendors and many drop sources had no spot; `vendx` prices were not read; ForeverDB_Full was never read |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`, no member called); `LibKa0s-Compat-1.0` at call time, with no floor; the ForeverDB addon at run time, optional; ForeverDB_Full at run time, optional, loaded only through `LoadFull()` |
| Confirm in-game | `LibStub("LibKa0s-ForeverDB-1.0").MODULES` → `{ ForeverDB = 4 }` |

## What changed at this version: spots from world coordinates and Full, `vendx` prices (`ISR3-LK-01`)

Item `ISR3-LK-01` of Ka0sAddonsCommonTasks `docs/2026-11-25-ITEM_SEARCH_ROUND3/` (its `03_SPEC.md`
§1): Drop Watcher's Item Search showed no zone and no waypoint for most vendors and for many drop
sources, because the base `spm` slice is capped at 5000 keys, and no price for most vendors, because
`vp` is sparse. Version 4 reads three more tables of the base addon and, when a host has loaded it,
one of ForeverDB_Full's.

| Member | Since | What changed |
|---|---|---|
| `Spots(kind, id)` | 1, changed at 4 | Reads ForeverDB_Full's `spz` (when loaded), then `spm`, then `spw` converted by `WorldToMap`; a **second return**, `origin` (`"spz"`, `"spm"` or `"spw"`) |
| `WorldToMap(continent, x, y)` | 4 | New: a world position to `uiMapID, x, y` through `umaa` and `zbord` |
| `VendorPriceAt(npcID, itemID)` | 4 | New: one vendor's price and its origin (`vendx`, then `vp`) |
| `VendorPrice(itemID)` | 1, changed at 4 | The lowest across `vendx` and `vp` for every vendor in `vend`; its two returns unchanged |
| `FullStatus()` | 4 | New: whether ForeverDB_Full is loaded, loadable, missing or disabled, without loading it |
| `LoadFull()` | 4 | New: the one load of ForeverDB_Full, never in combat, measured |
| `FullCost()` | 4 | New: what that load cost, `{ kb, ms }` |
| `Status()` | 1, changed at 4 | Gains `full` (FullStatus's answer) and `fullCost` |

**What a version 3 caller sees.** Every version 3 member keeps its signature. `Spots` answers more
sources (a source with no `spm` row now answers from `spw`, or from `spz` once Full is loaded), and
from `spz` a source's maps can differ from what `spm` said; a caller that takes one value is
unaffected by the second return. `VendorPrice` can answer a lower price than version 3 did, where a
vendor's `vendx` price is below every `vp` price. Everything else answers as version 3 did.

### Version 3's change: objects with names (`ISF-LK-01`)

Item `ISF-LK-01` of Ka0sAddonsCommonTasks `docs/2026-11-25-ITEM_SEARCH_FEEDBACK/` added `Object(id)`,
an object's name from `obj[id]` position 1, and made Drop Watcher the major's only consumer (Skill
Master and Outfitter Reborn stopped reading ForeverDB in that run). Its contract is below, unchanged.

### Version 2's change: Item Search's lookups (`IS-LK-01`)

Item `IS-LK-01` of Ka0sAddonsCommonTasks `docs/2026-11-25-ITEM_SEARCH/` (its `03_SPEC.md` §3) added
five functions for Drop Watcher's Item Search: `SearchItems`, `QuestsForItem`, `RewardFrom`,
`StartsQuest` and `SkinnedFrom`. Their contracts are below, unchanged at this version.

## What this major is

**ForeverDB** (<https://github.com/foreverfraddons/forever-db>, CurseForge `forever-db`) is a WoW
Forever data addon: QuestieDB, VMaNGOS, cMaNGOS and pfQuest merged and cross-checked, plus in-game
recordings. It carries what the client's own data (DB2) cannot: which creature drops an item and how
often, who sells it and for how much, where a creature or an object stands, who gives and ends a
quest, what a trainer teaches. It is a **LoadOnDemand** addon of some 12 MB (`ForeverDB`, global
`ForeverDB`), built as immutable `vYYYY.MM.DD.N` tags. Its tables are short names (`npc`, `item`,
`drop`, `spm`, ...) holding **positional** rows; its README's table list is the authority for what each
position means.

This major is the one place that knows those positions, the one place that decides **when** the
12 MB load happens, and the one place that answers plainly when ForeverDB is not there. A host never
reads `ForeverDB` itself (WowAddonStandards clients-§11).

**ForeverDB is optional for every player.** A host lists it in `## OptionalDeps` and MAY list it under
`.pkgmeta`'s `optional-dependencies`; it never lists it in `## Dependencies` or `required-dependencies`
(ForeverDB's own README asks consumers to require it; this collection deliberately does not). Without
it the host works unchanged, and the one feature that would read it says so where the player sees the
feature.

**Licensing.** ForeverDB's data is GPL-3.0; LibKa0s is MIT and vendored into every consumer. Nothing in
this library, its tests or the kit holds a row of ForeverDB. The kit's fake
(`tests/_kit/mock_foreverdb.lua`, kit revision 65) is invented data in ForeverDB's shape. The measured
numbers below are counts and percentages only, never a row.

## Lib-level surface

| Member | Kind | Since | Contract |
|---|---|---|---|
| `Available()` | function | 1 | `ok, reason` (exactly two values). See *When it loads*. |
| `IsLoaded()` | function | 1 | Whether the client has ForeverDB loaded now, by any addon (`C_AddOns.IsAddOnLoaded`). Never loads anything; not gated on the client. |
| `Status()` | function | 1 | A new `{ present, loaded, version, build, hash, full, fullCost }` for the diagnostics report: `present` (the client knows the addon) and `loaded` are booleans, `version` is the TOC `Version` (readable unloaded; read only when `present`), `build` and `hash` are `meta`'s and only when loaded; from version 4 `full` is `FullStatus()`'s answer and `fullCost` a new copy of `FullCost()`'s (nil before this library loaded Full). Never loads anything; not gated on the client. |
| `FullStatus()` | function | 4 | `"loaded"`, `"available"`, `"missing"`, `"disabled"`, `"client"` or `"base"`. Never loads anything and never calls `Available()`. See *ForeverDB_Full*. |
| `LoadFull()` | function | 4 | `ok, reason` (exactly two values): the one `C_AddOns.LoadAddOn("ForeverDB_Full")`. See *ForeverDB_Full*. |
| `FullCost()` | function | 4 | A new `{ kb = n, ms = n \| nil }`, or nil before `LoadFull()` loaded Full. |
| `Meta()` | function | 1 | A new `{ version, build, hash, counts }`, or nil when unavailable. `counts` is a new table of `meta.counts`' numeric entries. |
| `NPC(id)` | function | 1 | A new `{ id, name, subname, minLevel, maxLevel, rank, faction }`, or nil. `faction` is `"A"`, `"H"`, `"AH"` or nil. |
| `Item(id)` | function | 1 | A new `{ id, name, quality, requiredLevel, itemLevel, classID, subclassID, inventoryType, icon }`, or nil. |
| `Object(id)` | function | 3 | A new `{ id, name }`, or nil: nil for an id with no row, a row that is not a table, or a row whose name is not a non-empty string. See *Objects*. |
| `Quest(id)` | function | 1 | A new `{ id, title, level, minLevel, givers, enders }`, or nil. `givers` and `enders` are arrays (possibly empty) of `{ kind = "npc" \| "object", id }`. |
| `ItemSources(id)` | function | 1 | A new `{ creatures, objects, items, vendors, worldMinLevel }`, or nil when ForeverDB names no source at all. See *Item sources*. |
| `VendorPrice(itemID)` | function | 1 | `price, npcID` (copper; exactly two values): the lowest price any vendor of the item was seen asking, across `vendx` and `vp` from version 4, or `nil, nil`. |
| `VendorPriceAt(npcID, itemID)` | function | 4 | `price, origin` (copper; exactly two values): `vendx[npc][item].p` (origin `"vendx"`), else `vp[npc][item][1]` (origin `"vp"`), else `nil, nil`. See *Vendor prices*. |
| `Spots(kind, id)` | function | 1 | `spots, origin`: a new `{ [uiMapID] = { { x = 0..1, y = 0..1 }, ... } }` and, from version 4, the table it came from (`"spz"`, `"spm"` or `"spw"`); or nil. `kind` is `"npc"` or `"object"`. See *Spots*. |
| `WorldToMap(continent, worldX, worldY)` | function | 4 | `uiMapID, x, y` (x and y on 0..1), or nil. Pure: reads `umaa` and `zbord`, no client map API. See *World to map*. |
| `TrainerSpells(npcID)` | function | 1 | A new `{ [spellName] = { cost = copper, level = n } }`, or nil. |
| `SearchItems(query, limit)` | function | 2 | A new array of at most `limit` (default 50) new `{ id, name, quality, icon, requiredLevel }`, `{}` when nothing matches. See *Searching by name*. |
| `QuestsForItem(itemID)` | function | 2 | A new array, by quest id, of new `{ id, title, level, minLevel, races, classes, preQuests }`: the quests with the item among their objectives. `{}` when none. See *Quests for an item*. |
| `RewardFrom(itemID)` | function | 2 | A new array of new `{ id, title, level }`: the quests that reward the item, in `rew`'s order, once each. `{}` when none. |
| `StartsQuest(itemID)` | function | 2 | A new `{ id, title, level }`: the quest the item starts, or nil. |
| `SkinnedFrom(itemID)` | function | 2 | A new array of new `{ id, name, chance }`: the creatures the item is skinned from, most likely first as `ItemSources` sorts. `{}` when none. |

`MAJOR`, `MINOR` and `MODULES` are the usual bookkeeping and are not listed in the member manifest.
`__reset()` forgets the cached `Available()` answer and, from version 2, the two session indexes, and
from version 4 the kept `LoadFull()` answer, its cost, the parsed map geometry and the `spw` memo; it
is private, for tests, and a host never calls it.

## When it loads

`Available()` answers the first of these that applies, and keeps the answer for the session:

| # | Answer | When |
|---|---|---|
| 1 | `false, "client"` | The client is not WoW Forever (Compat's `IsForever`, read at call time; without Compat, not Forever) |
| 2 | `false, "missing"` | The client does not know the addon (`C_AddOns.DoesAddOnExist`, else `GetAddOnInfo`'s `MISSING` reason), or there is no `C_AddOns` |
| 3 | `false, <reason>` | It was not loaded, and `C_AddOns.LoadAddOn("ForeverDB")` failed: the client's own reason (`"DISABLED"`, `"DEP_MISSING"`, ...), or `"failed"` when it gave none |
| 4 | `false, "reshaped"` | It loaded, but the `ForeverDB` global is not a table |
| 5 | `true, nil` | Otherwise |

- **The first lookup is what loads.** Every lookup calls `Available()` first, and `Available()` is the
  only place this library calls `C_AddOns.LoadAddOn("ForeverDB")`: once a session, and only when the
  addon is not already loaded (another addon, Command Center for one, may have loaded it). Loading the
  library loads nothing; neither do `IsLoaded()`, `Status()`, `FullStatus()` or the diagnostics
  report. **ForeverDB_Full loads only when a host calls `LoadFull()`**, never in combat, and never
  from a lookup (see *ForeverDB_Full*).
- **A load costs some 12 MB and a hitch**, so a host makes its first call where the player asked for
  the feature (a tooltip opened, a detail view shown), never at login or on a timer, and records the
  memory in its perf ceiling (WowAddonStandards clients-§11).
- On any answer but `true`, every version 1 lookup answers nil (`VendorPrice` answers `nil, nil`);
  the version 2 lookups answer `{}`, and `StartsQuest` nil; version 3's `Object` answers nil (see
  *Degradation*).
- **The session indexes are built at the first call that needs them**, not at the load: a host that
  wants the cost off a hover makes one `SearchItems` and one `QuestsForItem` call where it loads.

## The field mapping

| Member | ForeverDB table and positions |
|---|---|
| `NPC` | `npc[id] = { name, sub, minLv, maxLv, rank }` → `name`, `subname`, `minLevel`, `maxLevel`, `rank`; `nfac[id]` → `faction` |
| `Item` | `item[id] = { name, quality, reqLevel, itemLevel, class, subclass, inventoryType, icon, ... }` → `name`, `quality`, `requiredLevel`, `itemLevel`, `classID`, `subclassID`, `inventoryType`, `icon`. The positions past the icon (allowable classes, required skill and rank, allowable races, faction and reputation) are not read in this version. |
| `Object` | `obj[id] = { name, ... }` → `name`; the positions past the name are not read in this version |
| `Quest` | `quest[id] = { title, level, minLevel }`; `qg[id]` and `qe[id] = { "c<id>", "o<id>", ... }` → `givers`, `enders` (`c` a creature, `kind = "npc"`; `o` an object, `kind = "object"`; any other entry skipped) |
| `ItemSources` | `drop[id]`, `odrop[id]`, `idrop[id] = { sourceId, chancePer10000, ... }`; `vend[id] = { npcId, ... }`; `world[id]`. `chance` is the per-10000 figure over 10000, and nil (the rate unknown) unless it is above 0 and at most 10000 |
| `VendorPrice` | `vend[item]` × `VendorPriceAt(npc, item)` for each vendor |
| `VendorPriceAt` | `vendx[npc] = { [item] = { p = price, s = stock, r = { requirement, ... } } }` → `p` (position `s` and `r` are not read); else `vp[npc][item] = { price, seen }` → `price`. A price that is not a number, or is negative, is no answer from that table |
| `Spots` | ForeverDB_Full's `spz[key]` (when loaded), else `spm[key]`, both `{ [uiMap] = { x, y, x, y, ... } }` on 0..1000 with `key` `"c<id>"` or `"o<id>"` → each pair becomes a named point `{ x = x / 1000, y = y / 1000 }`, a pair with either value outside 0..1000 skipped; else `spw[key] = { { continent, worldX, worldY, worldX, worldY, ... }, ... }` (a list of runs), each point through `WorldToMap` |
| `WorldToMap` | `umaa[assignment] = { uiMap, continent, areaID, uiMinX, uiMinY, uiMaxX, uiMaxY, minX, minY, minZ, maxX, maxY, maxZ }` (positions 10 and 13, the Z bounds, are not read); `zbord[areaID] = { c = continent, m = { { x, y, x, y, ... }, ... } }` on the zone's 0..1000 map scale |
| `FullStatus`, `LoadFull` | `C_AddOns.DoesAddOnExist`, `GetAddOnInfo`, `IsAddOnLoaded` and `LoadAddOn` for `"ForeverDB_Full"`; the `ForeverDBFull` global |
| `TrainerSpells` | `trn[npc] = { [spellName] = { cost, level, ... } }` → named fields `{ cost = cost, level = level }` |
| `Meta` | `meta = { build, hash, counts, ... }` and the TOC `Version` |
| `SearchItems` | `item[id]` positions 1 (name), 2 (quality), 3 (required level) and 8 (icon) → `name`, `quality`, `requiredLevel`, `icon` |
| `QuestsForItem` | `qx[quest] = { raceMask, classMask, preQuestsA, preQuestsB, ..., [10] = { itemId, ... }, ... }` → `races`, `classes`, `preQuests` (positions 3 and 4 merged), indexed by position 10; `quest[id]` → `title`, `level`, `minLevel` |
| `RewardFrom` | `rew[item] = { questId, ... }`; `quest[id]` → `title`, `level` |
| `StartsQuest` | `start[item] = questId`; `quest[id]` → `title`, `level` |
| `SkinnedFrom` | `skin[item] = { npcId, chancePer10000, ... }` (flat pairs, scaled as `ItemSources`' are); `npc[id]` position 1 → `name` |

A table this version does not read (`spf`, Shortest Path Forever's data, among them) is simply not
reached. Of ForeverDB_Full, version 4 reads `spz` alone; ForeverDB_Locales is not read.

## Spots

`Spots(kind, id)` answers `spots, origin`. The order is:

1. **`ForeverDBFull.spz[key]`**, when ForeverDB_Full is loaded (its global is a table). Same shape as
   `spm`. It held 16536 keys at ForeverDB v2026.11.25.48 against `spm`'s 5000.
2. **`ForeverDB.spm[key]`**, the base slice, read as version 3 read it.
3. **`ForeverDB.spw[key]`**, world coordinates (15877 keys at v2026.11.25.48), each point converted on
   its own by `WorldToMap` and grouped under the map it lands on. A point that lands on no map, or off
   0..1 there, is skipped; if none converts, this table gives no answer.

A table whose row gives no usable point is passed over for the next, so a malformed `spz` row falls
to `spm`. The answer is always a fresh table. The converted `spw` answer is **memoized per key for the
session**, kept with the `spw` table and the parsed geometry it was built from (a swapped table is
converted afresh), and each call hands out a deep copy. The first `spw` answer of a session also parses
`umaa` and `zbord` once.

## World to map

`WorldToMap(continent, worldX, worldY)` answers `uiMapID, x, y`, or nil. It reads only ForeverDB's
`umaa` (61 rows at v2026.11.25.48) and `zbord` (48 of those rows have one), and no client map API, so it
works headless and needs no probe. **The conversion**, for a `umaa` row whose continent matches and
whose world region holds the point (`minX ≤ worldX ≤ maxX`, `minY ≤ worldY ≤ maxY`):

```
u = (maxY − worldY) / (maxY − minY)        -- world Y runs east to west; map x runs west to east
v = (maxX − worldX) / (maxX − minX)        -- world X runs south to north; map y runs north to south
x = uiMinX + u · (uiMaxX − uiMinX)
y = uiMinY + v · (uiMaxY − uiMinY)
```

**Which map, when several regions hold the point.** Zone rectangles overlap, so of the rows that hold
it, smallest world area first:

1. the first whose `zbord` polygons (for its `areaID`, on its continent) hold `(x · 1000, y · 1000)`,
   by the even-odd rule;
2. otherwise the smallest that has no `zbord` entry, normally the continent's own map, so the point is
   still at the right place in the world;
3. otherwise nil.

A `umaa` row with a field the conversion needs missing or not a number, a whole-number continent below
0, or an empty world or map range is skipped. A `zbord` polygon with fewer than three points or a value
that is not a number is skipped, and a `zbord` entry whose `c` names another continent is not read; a
zone with no usable polygon is treated as having no `zbord` entry.

**Measured offline** at ForeverDB v2026.11.25.48 (the client folder read-only, from a scratch script in
no repo), over the 1517 keys that are in both `spm` and `spw`, converting each key's `spw` with its
`spm` row hidden:

| Measure | Value |
|---|---|
| The map holding most converted points is one of `spm`'s maps | 1428 keys (94.1%); another map on 88; no map on 1 |
| Each `spm` point to the nearest converted point on the same map | median 0.89% of the map's width, p90 2.53% (9892 points) |
| Each converted point to the nearest `spm` point on the same map | median 1.53%, p90 12.77% (33480 points; `spw` holds spawns the capped `spm` slice leaves out) |
| The same, with the map's x and y swapped | median 16.73%: the axis order above is the right one |
| `spw` keys with no `spm` row | 14360, of which 11637 convert |
| Time, cold memo, Lua 5.1 `os.clock` | 0.24 s over the 1517 shared keys, 0.38 s over the 14360 others |

The planning recon (that bundle's `inputs/RECON.md`) measured 93.4% agreement and a 0.31% median by a
method it does not spell out; the numbers above are this version's own, by the method in the table. A
point near a zone border can land on the neighbor's map or the continent's (about 6% of the measured
keys), and it is still at the right place in the world.

## Vendor prices

- `VendorPriceAt(npcID, itemID)` answers `price, origin`: `vendx[npc][item].p` (`"vendx"`), else
  `vp[npc][item][1]` (`"vp"`), else `nil, nil`. Copper.
- `VendorPrice(itemID)` takes the lowest `VendorPriceAt` price across every vendor in `vend[item]`; the
  first vendor in `vend`'s order still wins a tie. Its returns are version 1's.
- Both tables are sparse: at v2026.11.25.48 `vendx` holds 6 vendors and 60 entries, `vp` 32 vendors and
  443 entries. A host that wants a price for every vendor records what the merchant window shows.

## ForeverDB_Full

ForeverDB_Full is a LoadOnDemand companion addon (global `ForeverDBFull`, some 20 MB of Lua in seven
files) holding the uncapped database. Version 4 reads its `spz` once it is loaded; **the library never
decides when to load it**. That is the host's policy.

`FullStatus()` answers the first that applies, and never loads anything:

| Answer | When |
|---|---|
| `"client"` | Not WoW Forever |
| `"loaded"` | The client has ForeverDB_Full loaded and `ForeverDBFull` is a table |
| `"missing"` | The client does not know ForeverDB_Full (`DoesAddOnExist`, else `GetAddOnInfo`'s `MISSING`) |
| `"base"` | The base ForeverDB is not available: the client does not know it, `GetAddOnInfo` gives Full a `DEP_*` reason, or `Available()` has already answered false |
| `"disabled"` | `GetAddOnInfo` says Full is not loadable, for any other reason (`DISABLED`, `INTERFACE_VERSION`, ...) |
| `"available"` | Otherwise: installed and loadable (`DEMAND_LOADED`) |

`LoadFull()` answers `ok, reason`:

1. `false, "combat"` while `InCombatLockdown()` answers true. **Not kept**: a later call tries again.
2. `false, "client"` off WoW Forever.
3. `false, "base"` unless `Available()` answers true (this call may load the base addon, as any lookup
   does).
4. `false, "missing"`, `"disabled"` or `"base"` as `FullStatus()` reports.
5. Otherwise it loads, once a session, and keeps the answer: `true, nil`; the client's load reason
   (`"failed"` when it gives none); or `false, "reshaped"` when `ForeverDBFull` is still not a table.
   When another addon already loaded Full, nothing loads and the answer is `true, nil`.

**The load is measured**: `collectgarbage("count")` before and after (KB), and `debugprofilestop()`
before and after (ms) where the client has it. `FullCost()` answers a fresh `{ kb, ms }` after a load
this library made (a reshaped one included), and nil before one or when another addon loaded Full.
`Status()` carries the same as `full` and `fullCost`.

## Item sources

`ItemSources(id)` answers:

- `creatures` (from `drop`), `objects` (`odrop`) and `items` (`idrop`, the containers the item comes
  out of): arrays of `{ id = sourceID, chance = 0..1 }`. `chance` is the database's per-10000 figure
  over 10000, and **nil where the database says 0**, its "rate unknown". Each array is sorted **most
  likely first**, an unknown rate last, ties by id, so a host that shows the top three takes the first
  three.
- `vendors`: an array of creature ids, in `vend`'s order.
- `worldMinLevel`: the minimum level of a world drop, or nil.

Every array is present, empty when it has none. The answer is nil only when all four arrays are empty
and there is no world level. Names are a second call: `NPC(id)` for a creature or a vendor, `Item(id)`
for a container, and from version 3 `Object(id)` for an object.

## Objects

`Object(id)` answers `{ id, name }` from `obj[id]`'s first position, and nothing else: the name is
the one fact about an object this version reads. It is nil for an id with no row, for a row that is
not a table, and for a row whose name is not a string or is empty, so a host never has a nameless
object to draw. What a host does with the answers is its own:

- **Many object ids share a name** in ForeverDB (one chest drawn on several maps, say). The library
  answers each id on its own; a host that wants one row per name merges by `name` itself, and its
  merged row takes what it chooses of the parts (Drop Watcher: the highest chance, the union of the
  spots).
- **An object source with no name is the host's to leave out.** The library does not guess one, and a
  host that would draw "Object <id>" drops the source (Drop Watcher counts it in its debug log).

## Searching by name

`SearchItems(query, limit)`:

- **Plain and case-insensitive.** `query` is trimmed and lower-cased and found with a plain find, so
  `%`, `.` and the other pattern characters are themselves. A `query` that is not a string, or is
  under two characters once trimmed, answers `{}` and looks nothing up (so it never loads).
- **Order:** names that **start** with the query first, then shorter names, then lower ids. A `query` of
  digits alone also matches the item with **that id**, which comes first and is never listed twice.
- **`limit`** is a number of at least 1 (floored); anything else is the default, 50. The id match counts
  toward it.
- **The index.** The first call builds, once a session, a lower-cased copy of every item name with a
  numeric id (32,279 rows at ForeverDB v2026.11.24.46), kept by the library with the `item` table it
  was built from; later calls only scan it. The rows answered are read off `item` at answer time,
  in the database's own spelling.

## Quests for an item

`QuestsForItem(itemID)` answers every quest whose item objectives (`qx` position 10) list the item,
ordered by quest id. Each row:

| Field | From | Notes |
|---|---|---|
| `id` | the quest id | |
| `title`, `level`, `minLevel` | `quest[id]` positions 1–3 | nil when `quest` has no row for it; the quest is still answered |
| `races`, `classes` | `qx` positions 1 and 2 | the masks as numbers; **nil means any** (a 0 or a missing mask reads as nil) |
| `preQuests` | `qx` positions 3 and 4 | one new array, position 3's ids then position 4's, without repeats; empty when none |

The item → quests index is built once a session at the first call, from `qx`, and kept with the `qx`
table it was built from. A host filters by the player's race and class itself (`bit.band` on the
masks): the library answers the facts, not a verdict.

## The rules every member obeys

- **WoW Forever only**, through Compat's `IsForever` at call time (clients-§3). The Retail answer is
  "not available".
- **Globals are read bare and at call time** (`ForeverDB`, `ForeverDBFull`, `C_AddOns`,
  `InCombatLockdown`, `debugprofilestop`), never through the global table and never captured at load,
  pinned by a case.
- **No pcall, and no raise** on a missing, old or reshaped ForeverDB: a table that is not a table or a
  row that is not a table is no answer, and a field of the wrong type reads nil. An unknown kind or
  entry inside a list is skipped.
- **Every answer is a fresh table** built here, never one of ForeverDB's rows, so a caller can sort,
  keep or edit it without touching the database every addon on the client shares.
- **Ids are plain positive numbers**; a string id or anything else is no answer.

## What a headless harness answers

The kit's fake, `tests/_kit/mock_foreverdb.lua` (kit revision 61, rows for version 2's lookups since
revision 63, `obj` rows for version 3's `Object` since revision 64, and since revision 65 an invented
continent in `umaa` with `zbord` zones, `spw` world coordinates, a `vendx` price and a ForeverDB_Full
fake, `opts.full`; [its document](../testkit/version-65-docs.md)):

```lua
local FDB = dofile("tests/_kit/mock_foreverdb.lua")
local fake = FDB.install(M, { preset = "present", client = "forever" })
-- ... the first adapter lookup loads it: fake.loads == 1
fake.restore()
```

Presets `present`, `missing`, `loadfails` and `reshaped`; `fake.loads` counts the loads, so a host
proves that nothing loads at its login. `opts.full` (`present`, `missing`, `disabled`, `loadfails`,
`reshaped`) adds the ForeverDB_Full fake, with `fake.fullLoads` and `opts.onFullLoad` for a case that
measures the load. Because the adapter keeps its answer for the session, a host
suite that switches presets calls `LibStub("LibKa0s-ForeverDB-1.0").__reset()` between them.
`tests/test_foreverdb.lua` is this library's own suite: the client gate, every failure answer, every
member's mapping, the chance and coordinate scaling, fresh tables, a reshaped database, no load at file
load, and the diagnostics line with and without the addon loaded. `tests/test_foreverdb_lookups.lua`
covers version 2's five: the search order, the limit, the digit match, both session indexes and
their rebuild, every field mapping, bad entries skipped, and every degraded answer. Version 3's
`Object` is in `tests/test_foreverdb.lua`: the name, a shared name, a nameless row, a row that is
not a table, a non-string or empty name, an absent `obj`, a fresh table, and nil when unavailable.
`tests/test_foreverdb_spots.lua` covers version 4: each `Spots` origin and their precedence, the
formula on hand-worked points, the overlap pick, the no-polygon fallback and nil off every region,
malformed `umaa`, `zbord`, `spw` and `spz` rows, the memo's fresh tables and rebuild, `VendorPriceAt`'s
two origins and `VendorPrice`'s lowest-of-both, `FullStatus` never loading, `LoadFull`'s combat refusal
(not kept), its single load, its cost, its refusals and `"reshaped"`, and `Status`' Full fields.

## Degradation

A host resolves the major with `LibStub("LibKa0s-ForeverDB-1.0", true)` and needs a stand-in when it
is absent (a partial payload). The stand-in answers the all-absent values: `Available()` →
`false, "missing"`; `IsLoaded()` → `false`; `Status()` → `{ present = false, loaded = false }`;
`VendorPrice()` and `VendorPriceAt()` → `nil, nil`; `SearchItems()`, `QuestsForItem()`, `RewardFrom()`
and `SkinnedFrom()` → `{}`; `FullStatus()` → `"missing"`; `LoadFull()` → `false, "missing"`; every
other member (`StartsQuest`, `Object`, `Spots`, `WorldToMap` and `FullCost` among them) → nil.

The library itself answers the same way when the major is present but ForeverDB is not readable
(off Forever, missing, a failed load, a reshaped global), and when a table it reads is absent or not
a table:

| Member | Unavailable, or its table absent | A bad id | Bad entries |
|---|---|---|---|
| `SearchItems` | `{}` | n/a (a non-string or short query is `{}`) | a row that is not a table, or has no string name, or a non-numeric key, is not indexed |
| `QuestsForItem` | `{}` | `{}` | a non-numeric quest or item id, a position 10 that is not a list, a non-numeric prequest is skipped |
| `RewardFrom` | `{}` | `{}` | a non-numeric quest id is skipped; a repeat is answered once |
| `StartsQuest` | nil | nil | a `start` value that is not an id is nil |
| `SkinnedFrom` | `{}` | `{}` | a pair with a bad creature id is skipped; a chance outside 0..10000 is nil |
| `Object` | nil | nil | a row that is not a table, or a name that is not a non-empty string, is nil |
| `Spots` | nil | nil | see *Spots*: a row with no usable point passes to the next table |
| `WorldToMap` | nil | nil (a non-number or a continent that is not a whole number from 0) | see *World to map* |
| `VendorPriceAt` | `nil, nil` | `nil, nil` | a price that is not a number, or is negative, is no answer from that table |

## Adopting it

1. Re-vendor v1.114.0 or later, whole-folder (v1.115.0 or later for the version 2 lookups, v1.116.0
   or later for `Object`, v1.117.0 or later for version 4's spots, prices and ForeverDB_Full).
2. Add `ForeverDB` to the TOC's `## OptionalDeps` (and, if wanted, `forever-db` to `.pkgmeta`'s
   `optional-dependencies`). Never to `## Dependencies`.
3. Gate the feature on Forever (clients-§4), and make its first lookup where the player asked for it.
4. Show the feature only when `Available()` answers true; where the player would look for it, say
   that it needs ForeverDB.
5. Test it on the kit's fake with `present`, `missing` and `reshaped`, and on the Retail profile that
   it stays inert.
6. Record the memory the load adds in the perf ceiling of the addon that loads it.
7. To read ForeverDB_Full, call `LoadFull()` where the player asked for the feature (never from a
   tooltip, never in combat: wait for `PLAYER_REGEN_ENABLED`), check `FullStatus()` first, list
   `ForeverDB_Full` in `## OptionalDeps` too, clear whatever the host cached from `Spots` once it
   loads, and record `FullCost()` in the host's diagnostics and perf notes.

## What is not here

- **ForeverDB's other tables.** Achievements, areas, flight paths, quest texts, Shortest Path
  Forever's data and the rest are not read in version 4; a later minor adds what a host asks for.
  `vendx`'s stock (`s`) and requirements (`r`) are not read.
- **Reagents.** ForeverDB carries no recipe reagent lists, so "what is this item crafted into" is not
  here; Drop Watcher ships its own table from the client's DB2.
- **A verdict on a quest.** `QuestsForItem` answers the masks and prequests; whether the player can take
  the quest, has it or has done it is the host's to read from the client.
- **ForeverDB_Full beyond `spz`, and ForeverDB_Locales.**
- **`C_Map.GetMapPosFromWorldPos`.** The conversion is the library's own, over ForeverDB's tables, so
  it is pure and headless; the client API is unprobed on Forever. A host may compare the two in game.
- **A diagnostics-line change.** `LibKa0s-DebugLog-1.0`'s report prints the ForeverDB line as version 3
  did; the Full state is in `Status()` for a host's own diagnostics to print.
- **Any copy of the data.** This major reads the live global and copies only the fields it answers.
- **Events.** ForeverDB is static data; nothing here watches anything.
