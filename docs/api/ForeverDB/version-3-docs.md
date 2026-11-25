# `LibKa0s-ForeverDB-1.0` — version 3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the ForeverDB surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-ForeverDB-1.0` |
| Files and minors | `ForeverDB.lua` minor **3** |
| Shipped in | v1.116.0 |
| Status | **Current** |
| Supersedes | [version 2](./version-2-docs.md) (shipped in v1.115.0) — an object's name was not read, so a host drew an object source as "Object <id>" |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`, no member called); `LibKa0s-Compat-1.0` at call time, with no floor; the ForeverDB addon at run time, optional |
| Confirm in-game | `LibStub("LibKa0s-ForeverDB-1.0").MODULES` → `{ ForeverDB = 3 }` |

## What changed at this version: objects with names (`ISF-LK-01`)

Item `ISF-LK-01` of Ka0sAddonsCommonTasks `docs/2026-11-25-ITEM_SEARCH_FEEDBACK/` (its `03_SPEC.md`
§2): one new function, so Drop Watcher's Item Search names an object source ("Large Solid Chest")
instead of drawing "Object <id>". Every version 2 member is unchanged.

| New member | Since | What it reads |
|---|---|---|
| `Object(id)` | 3 | `obj[id]` position 1, the name |

**The consumers change in the same run.** At version 2 the runtime consumers were Drop Watcher, Skill
Master and Outfitter Reborn. At version 3 **Drop Watcher is the only one**: Skill Master and Outfitter
Reborn stop reading ForeverDB in the same run (the owner's item G1 of 2026-11-25, that bundle's
`03_SPEC.md` §8), so ForeverDB is an optional dependency of Drop Watcher alone. Both keep their
vendored LibKa0s unchanged: a vendored component nobody calls looks nothing up and loads nothing.

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
(`tests/_kit/mock_foreverdb.lua`, kit revision 64) is invented data in ForeverDB's shape.

## Lib-level surface

| Member | Kind | Since | Contract |
|---|---|---|---|
| `Available()` | function | 1 | `ok, reason` (exactly two values). See *When it loads*. |
| `IsLoaded()` | function | 1 | Whether the client has ForeverDB loaded now, by any addon (`C_AddOns.IsAddOnLoaded`). Never loads anything; not gated on the client. |
| `Status()` | function | 1 | A new `{ present, loaded, version, build, hash }` for the diagnostics report: `present` (the client knows the addon) and `loaded` are booleans, `version` is the TOC `Version` (readable unloaded; read only when `present`), `build` and `hash` are `meta`'s and only when loaded. Never loads anything; not gated on the client. |
| `Meta()` | function | 1 | A new `{ version, build, hash, counts }`, or nil when unavailable. `counts` is a new table of `meta.counts`' numeric entries. |
| `NPC(id)` | function | 1 | A new `{ id, name, subname, minLevel, maxLevel, rank, faction }`, or nil. `faction` is `"A"`, `"H"`, `"AH"` or nil. |
| `Item(id)` | function | 1 | A new `{ id, name, quality, requiredLevel, itemLevel, classID, subclassID, inventoryType, icon }`, or nil. |
| `Object(id)` | function | 3 | A new `{ id, name }`, or nil: nil for an id with no row, a row that is not a table, or a row whose name is not a non-empty string. See *Objects*. |
| `Quest(id)` | function | 1 | A new `{ id, title, level, minLevel, givers, enders }`, or nil. `givers` and `enders` are arrays (possibly empty) of `{ kind = "npc" \| "object", id }`. |
| `ItemSources(id)` | function | 1 | A new `{ creatures, objects, items, vendors, worldMinLevel }`, or nil when ForeverDB names no source at all. See *Item sources*. |
| `VendorPrice(itemID)` | function | 1 | `price, npcID` (copper; exactly two values): the lowest price any vendor of the item was seen asking, or `nil, nil`. |
| `Spots(kind, id)` | function | 1 | A new `{ [uiMapID] = { { x = 0..1, y = 0..1 }, ... } }`, or nil. `kind` is `"npc"` or `"object"`. |
| `TrainerSpells(npcID)` | function | 1 | A new `{ [spellName] = { cost = copper, level = n } }`, or nil. |
| `SearchItems(query, limit)` | function | 2 | A new array of at most `limit` (default 50) new `{ id, name, quality, icon, requiredLevel }`, `{}` when nothing matches. See *Searching by name*. |
| `QuestsForItem(itemID)` | function | 2 | A new array, by quest id, of new `{ id, title, level, minLevel, races, classes, preQuests }`: the quests with the item among their objectives. `{}` when none. See *Quests for an item*. |
| `RewardFrom(itemID)` | function | 2 | A new array of new `{ id, title, level }`: the quests that reward the item, in `rew`'s order, once each. `{}` when none. |
| `StartsQuest(itemID)` | function | 2 | A new `{ id, title, level }`: the quest the item starts, or nil. |
| `SkinnedFrom(itemID)` | function | 2 | A new array of new `{ id, name, chance }`: the creatures the item is skinned from, most likely first as `ItemSources` sorts. `{}` when none. |

`MAJOR`, `MINOR` and `MODULES` are the usual bookkeeping and are not listed in the member manifest.
`__reset()` forgets the cached `Available()` answer and, from version 2, the two session indexes; it
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
  only place this library calls `C_AddOns.LoadAddOn`: once a session, and only when the addon is not
  already loaded (another addon, Command Center for one, may have loaded it). Loading the library loads
  nothing; neither do `IsLoaded()`, `Status()` or the diagnostics report.
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
| `VendorPrice` | `vend[item]` × `vp[npc][item] = { price, seen }` |
| `Spots` | `spm["c<id>" \| "o<id>"] = { [uiMap] = { x, y, x, y, ... } }` on 0..1000 → each pair becomes a named point `{ x = x / 1000, y = y / 1000 }`; a pair with either value outside 0..1000 is skipped |
| `TrainerSpells` | `trn[npc] = { [spellName] = { cost, level, ... } }` → named fields `{ cost = cost, level = level }` |
| `Meta` | `meta = { build, hash, counts, ... }` and the TOC `Version` |
| `SearchItems` | `item[id]` positions 1 (name), 2 (quality), 3 (required level) and 8 (icon) → `name`, `quality`, `requiredLevel`, `icon` |
| `QuestsForItem` | `qx[quest] = { raceMask, classMask, preQuestsA, preQuestsB, ..., [10] = { itemId, ... }, ... }` → `races`, `classes`, `preQuests` (positions 3 and 4 merged), indexed by position 10; `quest[id]` → `title`, `level`, `minLevel` |
| `RewardFrom` | `rew[item] = { questId, ... }`; `quest[id]` → `title`, `level` |
| `StartsQuest` | `start[item] = questId`; `quest[id]` → `title`, `level` |
| `SkinnedFrom` | `skin[item] = { npcId, chancePer10000, ... }` (flat pairs, scaled as `ItemSources`' are); `npc[id]` position 1 → `name` |

A table this version does not read (`spf`, Shortest Path Forever's data, among them) is simply not
reached. `ForeverDB_Full` and `ForeverDB_Locales`, ForeverDB's two companion addons, are not read in
version 3; reading them is a later minor.

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
- **Globals are read bare and at call time** (`ForeverDB`, `C_AddOns`), never through the global table
  and never captured at load, pinned by a case.
- **No pcall, and no raise** on a missing, old or reshaped ForeverDB: a table that is not a table or a
  row that is not a table is no answer, and a field of the wrong type reads nil. An unknown kind or
  entry inside a list is skipped.
- **Every answer is a fresh table** built here, never one of ForeverDB's rows, so a caller can sort,
  keep or edit it without touching the database every addon on the client shares.
- **Ids are plain positive numbers**; a string id or anything else is no answer.

## What a headless harness answers

The kit's fake, `tests/_kit/mock_foreverdb.lua` (kit revision 61, rows for version 2's lookups since
revision 63, `obj` rows for version 3's `Object` since revision 64,
[its document](../testkit/version-64-docs.md)):

```lua
local FDB = dofile("tests/_kit/mock_foreverdb.lua")
local fake = FDB.install(M, { preset = "present", client = "forever" })
-- ... the first adapter lookup loads it: fake.loads == 1
fake.restore()
```

Presets `present`, `missing`, `loadfails` and `reshaped`; `fake.loads` counts the loads, so a host
proves that nothing loads at its login. Because the adapter keeps its answer for the session, a host
suite that switches presets calls `LibStub("LibKa0s-ForeverDB-1.0").__reset()` between them.
`tests/test_foreverdb.lua` is this library's own suite: the client gate, every failure answer, every
member's mapping, the chance and coordinate scaling, fresh tables, a reshaped database, no load at file
load, and the diagnostics line with and without the addon loaded. `tests/test_foreverdb_lookups.lua`
covers version 2's five: the search order, the limit, the digit match, both session indexes and
their rebuild, every field mapping, bad entries skipped, and every degraded answer. Version 3's
`Object` is in `tests/test_foreverdb.lua`: the name, a shared name, a nameless row, a row that is
not a table, a non-string or empty name, an absent `obj`, a fresh table, and nil when unavailable.

## Degradation

A host resolves the major with `LibStub("LibKa0s-ForeverDB-1.0", true)` and needs a stand-in when it
is absent (a partial payload). The stand-in answers the all-absent values: `Available()` →
`false, "missing"`; `IsLoaded()` → `false`; `Status()` → `{ present = false, loaded = false }`;
`VendorPrice()` → `nil, nil`; `SearchItems()`, `QuestsForItem()`, `RewardFrom()` and `SkinnedFrom()` →
`{}`; every other member (`StartsQuest` and `Object` among them) → nil.

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

## Adopting it

1. Re-vendor v1.114.0 or later, whole-folder (v1.115.0 or later for the version 2 lookups, v1.116.0
   or later for `Object`).
2. Add `ForeverDB` to the TOC's `## OptionalDeps` (and, if wanted, `forever-db` to `.pkgmeta`'s
   `optional-dependencies`). Never to `## Dependencies`.
3. Gate the feature on Forever (clients-§4), and make its first lookup where the player asked for it.
4. Show the feature only when `Available()` answers true; where the player would look for it, say
   that it needs ForeverDB.
5. Test it on the kit's fake with `present`, `missing` and `reshaped`, and on the Retail profile that
   it stays inert.
6. Record the memory the load adds in the perf ceiling of the addon that loads it.

## What is not here

- **ForeverDB's other tables.** Achievements, areas, flight paths, quest texts, Shortest Path
  Forever's data and the rest are not read in version 3; a later minor adds what a host asks for.
- **Reagents.** ForeverDB carries no recipe reagent lists, so "what is this item crafted into" is not
  here; Drop Watcher ships its own table from the client's DB2.
- **A verdict on a quest.** `QuestsForItem` answers the masks and prequests; whether the player can take
  the quest, has it or has done it is the host's to read from the client.
- **`ForeverDB_Full` and `ForeverDB_Locales`.**
- **Any copy of the data.** This major reads the live global and copies only the fields it answers.
- **Events.** ForeverDB is static data; nothing here watches anything.
