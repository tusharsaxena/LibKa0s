# `LibKa0s-ForeverDB-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the ForeverDB surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-ForeverDB-1.0` |
| Files and minors | `ForeverDB.lua` minor **1** |
| Shipped in | v1.114.0 |
| Status | **Current** |
| Supersedes | — (the first version of this major) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`, no member called); `LibKa0s-Compat-1.0` at call time, with no floor; the ForeverDB addon at run time, optional |
| Confirm in-game | `LibStub("LibKa0s-ForeverDB-1.0").MODULES` → `{ ForeverDB = 1 }` |

## What changed at this version: the major is new (`SF-LK-01`)

LibKa0s#105, item `SF-LK-01` of Ka0sAddonsCommonTasks `docs/2026-11-25-SEEDS_AND_FOREVERDB/` (its
`03_SPEC.md` §4 and the owner's answers in §8): one reader of ForeverDB for every Ka0s addon that
wants it. Eleven functions. The five consumers the owner named on 2026-11-25 (Drop Watcher, Loot
History, Bank Ledger, Skill Master and Outfitter Reborn) adopt it in the same run, so the major has no
one-consumer promotion to record.

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
(`tests/_kit/mock_foreverdb.lua`, kit revision 61) is invented data in ForeverDB's shape.

## Lib-level surface

| Member | Kind | Since | Contract |
|---|---|---|---|
| `Available()` | function | 1 | `ok, reason` (exactly two values). See *When it loads*. |
| `IsLoaded()` | function | 1 | Whether the client has ForeverDB loaded now, by any addon (`C_AddOns.IsAddOnLoaded`). Never loads anything; not gated on the client. |
| `Status()` | function | 1 | A new `{ present, loaded, version, build, hash }` for the diagnostics report: `present` (the client knows the addon) and `loaded` are booleans, `version` is the TOC `Version` (readable unloaded), `build` and `hash` are `meta`'s and only when loaded. Never loads anything; not gated on the client. |
| `Meta()` | function | 1 | A new `{ version, build, hash, counts }`, or nil when unavailable. `counts` is a new table of `meta.counts`' numeric entries. |
| `NPC(id)` | function | 1 | A new `{ id, name, subname, minLevel, maxLevel, rank, faction }`, or nil. `faction` is `"A"`, `"H"`, `"AH"` or nil. |
| `Item(id)` | function | 1 | A new `{ id, name, quality, requiredLevel, itemLevel, classID, subclassID, inventoryType, icon }`, or nil. |
| `Quest(id)` | function | 1 | A new `{ id, title, level, minLevel, givers, enders }`, or nil. `givers` and `enders` are arrays (possibly empty) of `{ kind = "npc" \| "object", id }`. |
| `ItemSources(id)` | function | 1 | A new `{ creatures, objects, items, vendors, worldMinLevel }`, or nil when ForeverDB names no source at all. See *Item sources*. |
| `VendorPrice(itemID)` | function | 1 | `price, npcID` (copper; exactly two values): the lowest price any vendor of the item was seen asking, or `nil, nil`. |
| `Spots(kind, id)` | function | 1 | A new `{ [uiMapID] = { { x, y }, ... } }`, x and y on 0..1, or nil. `kind` is `"npc"` or `"object"`. |
| `TrainerSpells(npcID)` | function | 1 | A new `{ [spellName] = { cost, level } }`, or nil. |

`MAJOR`, `MINOR` and `MODULES` are the usual bookkeeping and are not listed in the member manifest.
`__reset()` forgets the cached `Available()` answer; it is private, for tests, and a host never calls
it.

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
- On any answer but `true`, every lookup answers nil (`VendorPrice` answers `nil, nil`).

## The field mapping

| Member | ForeverDB table and positions |
|---|---|
| `NPC` | `npc[id] = { name, sub, minLv, maxLv, rank }` → `name`, `subname`, `minLevel`, `maxLevel`, `rank`; `nfac[id]` → `faction` |
| `Item` | `item[id] = { name, quality, reqLevel, itemLevel, class, subclass, inventoryType, icon, ... }` → `name`, `quality`, `requiredLevel`, `itemLevel`, `classID`, `subclassID`, `inventoryType`, `icon`. The positions past the icon (allowable classes, required skill and rank, allowable races, faction and reputation) are not read in this version. |
| `Quest` | `quest[id] = { title, level, minLevel }`; `qg[id]` and `qe[id] = { "c<id>", "o<id>", ... }` → `givers`, `enders` (`c` a creature, `kind = "npc"`; `o` an object, `kind = "object"`; any other entry skipped) |
| `ItemSources` | `drop[id]`, `odrop[id]`, `idrop[id] = { sourceId, chancePer10000, ... }`; `vend[id] = { npcId, ... }`; `world[id]` |
| `VendorPrice` | `vend[item]` × `vp[npc][item] = { price, seen }` |
| `Spots` | `spm["c<id>" \| "o<id>"] = { [uiMap] = { x, y, x, y, ... } }` on 0..1000 |
| `TrainerSpells` | `trn[npc] = { [spellName] = { cost, level, ... } }` |
| `Meta` | `meta = { build, hash, counts, ... }` and the TOC `Version` |

A table this version does not read (`spf`, Shortest Path Forever's data, among them) is simply not
reached. `ForeverDB_Full` and `ForeverDB_Locales`, ForeverDB's two companion addons, are not read in
version 1; reading them is a later minor.

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
for a container; an object's name is not read in this version.

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

The kit's fake, `tests/_kit/mock_foreverdb.lua` (kit revision 61, [its document](../testkit/version-61-docs.md)):

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
load, and the diagnostics line with and without the addon loaded.

## Degradation

A host resolves the major with `LibStub("LibKa0s-ForeverDB-1.0", true)` and needs a stand-in when it
is absent (a partial payload). The stand-in answers the all-absent values: `Available()` →
`false, "missing"`; `IsLoaded()` → `false`; `Status()` → `{ present = false, loaded = false }`;
`VendorPrice()` → `nil, nil`; every other member → nil.

## Adopting it

1. Re-vendor v1.114.0 or later, whole-folder.
2. Add `ForeverDB` to the TOC's `## OptionalDeps` (and, if wanted, `forever-db` to `.pkgmeta`'s
   `optional-dependencies`). Never to `## Dependencies`.
3. Gate the feature on Forever (clients-§4), and make its first lookup where the player asked for it.
4. Show the feature only when `Available()` answers true; where the player would look for it, say
   that it needs ForeverDB.
5. Test it on the kit's fake with `present`, `missing` and `reshaped`, and on the Retail profile that
   it stays inert.
6. Record the memory the load adds in the perf ceiling of the addon that loads it.

## What is not here

- **ForeverDB's other tables.** Achievements, areas, flight paths, quest texts and rewards, Shortest
  Path Forever's data and the rest are not read in version 1; a later minor adds what a host asks for.
- **`ForeverDB_Full` and `ForeverDB_Locales`.**
- **Any copy of the data.** This major reads the live global and copies only the fields it answers.
- **Events.** ForeverDB is static data; nothing here watches anything.
