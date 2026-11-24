# `testkit` — version 61

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 57 lists, **plus `mock_foreverdb.lua`** |
| Version | **61** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | never released alone: v1.114.0 ships [version 62](version-62-docs.md) |
| Status | Superseded |
| Supersedes | [version 60](version-60-docs.md) — the kit had no fake of the ForeverDB data addon, so no suite could prove that `LibKa0s-ForeverDB-1.0` loads it only at a host's first lookup |
| Superseded by | [version 62](version-62-docs.md) — `client_globals_forever.lua` regenerated at Ketho/BlizzardInterfaceResources `forever` `e230342` |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `61` |

Everything revision 60 describes is unchanged here except what follows. One file is added,
`mock_foreverdb.lua`, opt-in like `mock_screen.lua`: nothing loads it unless a suite does, so a
consumer that never reads ForeverDB sees no change. `README.md` gains its row and `framework.lua`'s
`Kit.VERSION` is 61, which is all that changes in either. No public member of any other file is
added, removed or renamed, and no kit case is added, removed or renamed. The item is `SF-LK-01` of
Ka0sAddonsCommonTasks `docs/2026-11-25-SEEDS_AND_FOREVERDB/` (LibKa0s#105).

## What changed

### `mock_foreverdb.lua`: the opt-in fake of the ForeverDB data addon

ForeverDB is a LoadOnDemand addon: its `ForeverDB` global does not exist until something calls
`C_AddOns.LoadAddOn("ForeverDB")`, and `LibKa0s-ForeverDB-1.0` promises to make that call only at a
host's first lookup, once. The fake counts the load and hands the global over **at** the load, never
before it, so a suite can prove both halves.

```lua
local FDB = dofile("tests/_kit/mock_foreverdb.lua")
local fake = FDB.install(M, { preset = "present", client = "forever" })
-- ... the first adapter lookup loads it
assert(fake.loads == 1)
fake.restore()
```

The file returns a module:

| Member | What it is |
|---|---|
| `FDB.install(M, opts)` | Installs the fake on mock `M` and returns the handle below. Raises on an unknown `preset` or `client`. |
| `FDB.fixture()` | A fresh copy of the invented database, in ForeverDB's shape. |
| `FDB.IDS` | The invented ids the fixture uses, by role (`gnoll`, `kobold`, `vendor`, `trainer`, `blade`, `pebble`, `coffer`, `errand`, `crate`, `mapA`, `mapB`). |
| `FDB.VERSION` | The TOC `Version` the fake answers by default, `2099.01.01.1`. |
| `FDB.PRESETS` | `{ "present", "missing", "loadfails", "reshaped" }`. |

`opts`:

| Field | Default | Effect |
|---|---|---|
| `preset` | `"present"` | `present`: installed, and `LoadAddOn` answers `true` and sets `M.ForeverDB`. `missing`: `DoesAddOnExist` answers false, `GetAddOnInfo`'s reason is `MISSING`, `LoadAddOn` answers `false, "MISSING"`. `loadfails`: installed, `LoadAddOn` answers `false, opts.reason`. `reshaped`: loads, and `M.ForeverDB` is `opts.value`. |
| `data` | `FDB.fixture()` | The database a `present` load installs. |
| `reason` | `"DISABLED"` | `loadfails`' reason, also `GetAddOnInfo`'s. |
| `value` | `"ForeverDB"` | What `reshaped` puts on `M.ForeverDB` (not a table). |
| `loaded` | false | Already loaded by another addon when the case starts: `IsAddOnLoaded` answers true and `M.ForeverDB` is set, with `loads` at 0. |
| `version` | `FDB.VERSION` | The TOC `Version` `GetAddOnMetadata` answers, loaded or not. |
| `client` | nil | `"forever"` or `"retail"` also sets `WOW_PROJECT_ID`, `WOW_PROJECT_MAINLINE` and `WOW_PROJECT_CAMELOT` on `M` (18 / 1 / 18, or 1 / 1 / nil), so a case means the same under both kit profiles; nil leaves the profile's alone. Install after the profile is applied (a suite's shared mock, or `Loader.makeEnv(M)` on a fresh one), or the profile's first apply overwrites them. |

The handle: `loads` (the `LoadAddOn("ForeverDB")` calls so far), `data` (what the load installs; nil
for `missing` and `loadfails`), `preset`, `loadNow()` (another addon loads it now; `loads` does not
move) and `restore()` (puts back `M.C_AddOns`, `M.ForeverDB` and, with `client`, the constants).

**What is installed.** `M.C_AddOns` is replaced by a new table that keeps every member the mock
already had and adds, for the name `ForeverDB` only, `DoesAddOnExist`, `GetAddOnInfo` (`name, title,
notes, loadable, reason, security`), `IsAddOnLoaded` (`loadedOrLoading, loaded`), `LoadAddOn`
(`loaded, reason`) and `GetAddOnMetadata`. Any other name falls through to the mock's own member, or
answers as an addon that does not exist.

**The data is invented** (licensing). ForeverDB's data is GPL-3.0 and the kit is MIT and vendored into
every consumer, so no row of the real database appears in the fake or may appear in any fixture built
on it. What is copied is the shape alone: the table names, a row's positional layout, the `c<id>` and
`o<id>` keys, the 0..10000 chance scale (0 = rate unknown) and the 0..1000 coordinate scale. Every id
is in 990000..990999 and every map id in 9901..9909, ranges no row of ForeverDB v2026.11.24.46 uses,
and every name is made up.

`tests/test_mock_foreverdb.lua` pins each preset's answers, the global handed over at the load, the
load count, the consumer's own `C_AddOns` members kept and restored, `loaded` and `loadNow`, the
client constants, and the fixture's shape and id range.

## What a consumer owes

The whole-folder copy of `tests/_kit/`, as at every revision. A suite that pins `KIT_VERSION` at 60
re-pins it at 61. Nothing else; a consumer that adopts `LibKa0s-ForeverDB-1.0` tests its feature on
this fake.
