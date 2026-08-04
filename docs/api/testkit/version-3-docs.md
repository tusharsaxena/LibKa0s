# `testkit` — version 3

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **3** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.6.1 |
| Status | **Current** |
| Supersedes | [version 2](version-2-docs.md) — two runner bug fixes; nothing in the Lua surface changed |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `3` |

## What this is, and what it is not

The shared headless test harness for the Ka0s addon collection: the test registry and assertions,
the source loader, the universal half of the WoW-API mock, and — new in this revision — the
consolidated automated-test runner. The Lua surface runs under plain `lua` from a repo root; the
runner is a bash script invoked from the same place.

**Nothing in the Lua surface changed between version 2 and version 3**, and no file was added or
removed. The revision moved because `run-automated-tests.sh` changed, and the byte-identity gate
compares content as well as the file set — a consumer holding revision 2's script fails against a
revision 3 tag.

Two fixes, both found by using the thing rather than by a test:

- **Artifacts are written without ANSI escapes.** `luacheck` and the harness colour their output
  when they believe a terminal is attached, and the raw escapes (`\033[32m\033[1mOK`) were landing
  verbatim in `lint.txt` and `tests.txt` — unreadable in an editor and pure noise in a diff between
  two runs. The parsers had always stripped for their own use; the stored evidence now gets the same
  treatment, plus `--no-color` where `luacheck` supports it.
- **Run directories are stamped in local time as `YYYYMMDD-HHMMSS`**, not UTC as
  `YYYY-MM-DD-HHMMSS`. A record is read by the person who ran it, usually minutes later; a folder
  name that disagrees with their clock costs a mental conversion every glance. `startedAt` in the
  manifest now carries an explicit UTC offset, so the instant stays unambiguous once the record
  outlives the machine.

It is **not a LibStub library**. It registers nothing, no load order depends on it, and it must
never ship: it is vendored under `tests/`, which every addon's `.pkgmeta` already excludes via its
existing `- tests` entry. A standards audit must not flag it for a missing LibStub version registry,
because it does not have one and is not supposed to.

`Kit.VERSION` is not a LibStub minor and does not change that. Two copies never negotiate — the
gate is byte-identity, not version comparison. What the number buys is the one question
byte-identity cannot answer on its own: *which* kit is a given consumer holding? Before it,
"AbsorbTracker's kit is stale" was reachable only by diffing against this repo at the right commit.
Now the consumer can say so itself, and this document has a name.

### One number for three files

The kit vendors as a whole folder and its files are never adopted separately, so there is one
revision for all of them rather than a minor per file. That is the opposite of `LibKa0s/`, where
each file carries its own minor precisely because a host may hold a different vendored copy of each
major. Here a mixed copy is not a skew to be negotiated — it is a failed `cp -r`, and
`test_kitsync.lua` fails on it.

## `framework.lua` — registry, assertions, runner

`dofile("tests/_kit/framework.lua")` returns the `Kit` table.

| Name | Since | Meaning |
|---|---|---|
| `Kit.VERSION` | **1** | The kit revision — a positive integer, bumped on every released change to any file in `testkit/`. |
| `Kit.test(name, fn)` | 1 | Register one case. **Records only** — nothing executes until `Kit.run`. Each case is stamped with the suite file it came from. |
| `Kit.fail(msg, level)` | 1 | Raise a failure. `level` is passed through to `error`, offset so the reported line is the caller's rather than the kit's. |
| `Kit.assertEqual(got, want, msg)` | 1 | Identity comparison. The failure message renders both sides, with any table as `<table>`. |
| `Kit.assertTrue(c, msg)` / `Kit.assertFalse(c, msg)` | 1 | Truthiness, not identity — `assertTrue(1)` passes. |
| `Kit.assertNil(v, msg)` | 1 | `v` must be exactly `nil`; the message names what was found instead. |
| `Kit.assertNear(got, want, tolerance, msg)` | 1 | Float comparison with an **explicit** tolerance. Computed geometry is never compared with `==`. |
| `Kit.assertError(fn, msg)` | 1 | `fn` must raise. **Returns the error text**, so a caller can go on to assert on the message. |
| `Kit.expose(t)` | 1 | Merge `KIT_VERSION`, `test` and every assertion into the host's table and return it — how a repo keeps its own `_G.<X>_TEST` global name and key set without any suite file changing. |
| `Kit.run(opts)` | 1 | Load the suites, then either render the inventory or run everything. `opts = { dir = "tests/", suites = { … } }`. **Exits the process** — 0 on success, 1 on any failure — so the green gate is a plain shell check. |
| `Kit.__tests()` | 1 | The live registry, for the kit's own self-tests. |

### Collect-then-run, deliberately

`test()` only records; nothing runs until `Kit.run`. Some runners in the collection execute each
case body at registration time and short-circuit it in list mode, which makes `--list` a second code
path through the same file — so the inventory can disagree with the run. Here `--list` is a pure
filter over the registry and cannot drift from what actually runs.

`--list` renders the whole body of `docs/test-cases.md`, **CRLF-terminated**, and exits 0 without
running a case. The CRLF is written by the kit rather than left to a `| sed 's/$/\r/'` in the shell:
the repos pin `*.md text eol=crlf`, a plain redirect writes LF, and a regeneration command with a
pipeline in it is one someone eventually runs without the pipeline.

A `suites` entry naming a file that does not exist yet is **skipped rather than fatal**, so a suite
can be listed while it is being written without taking the run down.

## `loader.lua` — headless source loading

`dofile("tests/_kit/loader.lua")` returns the `Loader` table.

Each file's chunk runs in an environment where WoW globals resolve to the mock set, falling back to
`_G`. Addon chunks are called with `("<AddonName>", NS)`, matching the client's
`local addonName, NS = ...` header; library chunks are called with no arguments.

| Name | Since | Meaning |
|---|---|---|
| `Loader.addonName` | 1 | Set by the consuming `tests/run.lua` before loading addon files; decides whether a chunk is called with `(name, NS)` or with nothing. **Library-only repos leave it nil.** |
| `Loader.makeEnv(mocks)` | 1 | The sandbox metatable. Reads fall through mocks → `_G`; **writes land in `_G`**, so an addon's SavedVariables global and any `StaticPopupDialogs` registration behave like the real client. Without that, a sandboxed write to a WoW global is silently lost and the SavedVariables migration paths become untestable. |
| `Loader.load(path, NS, mocks)` | 1 | Load and run one file. |
| `Loader.loadAll(paths, NS, mocks)` | 1 | `load` over a list, in order. |
| `Loader.loadSource(src, chunkname, NS, mocks)` | 1 | Load source held in a **string**. The multi-copy / minor-skew tests need two builds of the same file at different LibStub minors, which exists only as a patched copy — loading the real file twice would re-run the same minor and register nothing the second time. |
| `Loader.readFile(path)` | 1 | Read a file into a string. Errors name the repo-root assumption, because that is the mistake being made when it fails. |
| `Loader.tocFiles(tocPath)` | 1 | An addon's own `.lua` files, in TOC order, as forward-slash paths. Skips blank lines, comments, every `## Directive:`, and — importantly — every `libs\` line. |

### Why `tocFiles` derives rather than duplicates

A repo typically has several load lists: the TOC (what the client reads), `tests/run.lua`, an
offline perf runner, a degraded-path list. Not all of them are under the green gate, and an ungated
copy rots silently while the figures it produces are still trusted. Deriving from the TOC removes
one of them.

`libs\` lines are skipped because vendored libraries come in through their own XML, which this
cannot see — so a runner that needs them prepends its own explicit lib list. That is why a consuming
`tests/run.lua` spells out every file of `LibKa0s.xml` in XML order before calling `tocFiles`.

## `mock_base.lua` — the universal half of the WoW-API mock

`dofile("tests/_kit/mock_base.lua")` returns a **builder**, not a table: call it to get a fresh,
isolated environment per run. An addon's own `tests/wow_mock.lua` calls the builder and then
overwrites the handful of keys that are genuinely its own (bag APIs, spell APIs, absorb APIs).
Plain per-key overwrite — no merge machinery, because every call already hands back a fresh table.

**What belongs here:** an API every addon in the collection touches, or would if it grew a window.
**What does not:** anything only one addon calls. A mock that stubs every addon's APIs for everyone
is one more thing every future test has to reason about, and it hides a missing stub behind a
neighbour's.

| Group | Keys |
|---|---|
| Time / string | `time`, `date`, `GetTime`, `format`, `debugprofilestop`, `wipe`, `tinsert`, `tremove` |
| Unit / world | `UnitName`, `UnitClass`, `UnitLevel`, `UnitExists`, `UnitAffectingCombat`, `InCombatLockdown`, `IsInGroup`, `IsInRaid`, `IsInInstance`, `GetNumGroupMembers`, `GetRealmName`, `GetZoneText`, `GetSubZoneText`, `GetLocale`, `GetSpecialization`, `GetSpecializationInfo` |
| UI | `CreateFrame`, `UIParent`, `UISpecialFrames`, `DEFAULT_CHAT_FRAME`, `GameTooltip`, `CreateColor`, `PlaySound`, `Settings`, `SettingsPanel`, `StaticPopupDialogs`, `StaticPopup_Show`, `StopwatchFrame`, `Stopwatch_Clear`, `C_Timer`, `hooksecurefunc` |
| LibStub + Ace fakes | `LibStub` (with a real minor registry), AceDB / AceConsole / AceGUI stand-ins |

### Test seams

Anything prefixed `__` is a handle for a test to observe or drive, not part of the emulated API:

| Seam | Since | Meaning |
|---|---|---|
| `__now` | 1 | Backs `GetTime()`. Settable, so time is a variable a test controls. |
| `__profileMs` | 1 | Millisecond CPU clock backing the Perf brackets. A settable counter rather than a real clock, so a test can assert **exact** bucket totals — a wall-clock reading would make every timing assertion flaky. |
| `__timers` / `__fireTimers` | 1 | Queued `C_Timer` callbacks, and the way to run them. |
| `__inCombat` / `__unitExists` | 1 | Drive the combat gate and unit existence. |
| `__context` | 1 | Capture-context lookups, so a test can assert what a record stamped. |
| `__libs` | 1 | The LibStub registry, for the multi-copy and minor-skew suites. |
| `__stubFrame` / `__deepcopy` | 1 | Exposed so an addon's own mock can build extra frame-shaped objects (GameTooltip stand-ins, `StopwatchFrame`) without duplicating the stub. |
| `__makeAceGUIWidget` | 1 | Build an AceGUI widget stand-in, including its `__fire`. |
| `__mainPanel` / `__subcategories` / `__settingsClosed` | 1 | What the Settings-canvas registration recorded. |
| `__stopwatch` | 1 | Stopwatch state, for the Perf run's start/stop calls. |

### The five fidelity rules

These are why this is one file rather than eight, and each has already caught a real bug:

1. **A stub that silently succeeds is worse than no stub.** If production code branches on a return
   value, the mock must return something a branch can distinguish — not the frame, not nil.
2. **Getters used in arithmetic or concatenation must return real numbers and strings.**
   `LibKa0s-Options-1.0`'s scrollbar patch multiplies `GetHeight()` and concatenates `GetName()`;
   both raise on a table, and a blanket "return the frame" metatable supplies exactly that.
3. **Anything a test needs to observe must be recorded, not no-opped.** Event registration, script
   handlers and widget creation order are all load-bearing for at least one suite: a no-op
   `RegisterUnitEvent` would let a widened or dropped per-unit filter pass the entire suite.
4. **Anything a test needs to drive must be fireable.** `__fire` on frames and on AceGUI widgets is
   what makes the lazy first-OnShow render and the `OnValueChanged` write path reachable at all.
5. **Model the awkward real behaviour, not the convenient one.** AceDB's `copyDefaults` merges in
   place and AceConsole's `Embed` clobbers a same-named custom `Print` — both reproduced here,
   because both have already caused a real bug a friendlier mock would have hidden.

### Known divergence, deliberately kept

`CreateTexture` and `CreateFontString` answer from the metatable and so return the **frame itself**
rather than a distinct object. WhatGroup's and KickCD's mocks make distinct objects and treat that as
a correctness requirement, and they are right — a font string and its parent are not one object, and
the aliasing has already forced a workaround in `PerfPanel.lua`, which records `__label`/`__state`
on the button instead of asking the FontString.

It is kept because changing it is not a harness change: AbsorbTracker's `tests/perf.lua` memoises
frame proxies *because* `bar.valueText` and `bar.statusBar` are the same table, so distinct objects
move the api/iter parity figure.

`strsplit` and `strtrim` are deliberately **absent**. Neither consumer calls them, and a hand-rolled
reimplementation of a WoW string function that nothing exercises is a subtly-wrong shared helper
waiting to be adopted. The addon that first needs one adds it to its own extender.

## `run-automated-tests.sh` — the consolidated automated-test runner

New in version 2. Runs the four out-of-game suites and records every result as one frozen bundle
under `docs/automated-tests/<YYYYMMDD-HHMMSS>/`, then rolls the run into
`docs/automated-tests/RESULTS.md`. The normative rules for the artifact live in the standard's
`automated-tests` section; this document covers the script's interface.

```sh
tests/_kit/run-automated-tests.sh [--suite lint|tests|perf|complexity]... \
                                  [--label TEXT] [--release X.Y.Z] [--no-bundle]
```

| Flag | Effect |
|---|---|
| `--suite <name>` | Repeatable. Run only the named suites. Default: all four. |
| `--label TEXT` | Free-text label recorded in the manifest and passed to `tests/perf.lua`. |
| `--release X.Y.Z` | Marks the bundle a release record (`"release": "X.Y.Z"` in the manifest). Set by the release flow, not by hand. |
| `--no-bundle` | Run and print; write nothing. Same exit code, so a hook can call it. |

| Suite | Command | Gating |
|---|---|---|
| `lint` | `luacheck .` | **yes** |
| `tests` | `lua tests/run.lua` | **yes** |
| `perf` | `lua tests/perf.lua` | no — recorded only |
| `complexity` | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` | no — recorded only |

**`perf` and `complexity` never fail the run.** `performance-§9`/`§10` are explicit that a
wall-clock or complexity threshold which fails a run teaches everyone to reach for `--no-verify`,
after which the gate protects nothing and the habit remains. They are measured, recorded and
diffed; a regression in them yields `amber`, which is a signal rather than a stop.

**A missing tool is a skip, not a failure**, and the skip is recorded with its reason — so a green
run that measured nothing cannot be mistaken for a green run that measured everything.

Verdict: `red` if a gating suite failed; `amber` if a gating suite was skipped or `perf` failed its
own deterministic assertions; `green` otherwise. Exit code is non-zero only on `red`.

### It is LF, and must stay LF

Every other file in this collection is CRLF, pinned by `.gitattributes`. A `#!/usr/bin/env bash`
line followed by CRLF makes the kernel look for an interpreter literally named `bash\r`, and every
`case`/`in` becomes a syntax error. A CRLF-pinned repo that ships a `.sh` **MUST** carve it out:

```gitattributes
*.sh   text eol=lf
```

That line is required in this repo **and in every consumer**, before the first re-vendor. Without
it the vendored copy is broken on every checkout — not in one contributor's working tree, in all of
them. `cp` also does not always carry the executable bit, so re-vendoring ends with
`chmod +x <Addon>/tests/_kit/run-automated-tests.sh`.

## Vendoring

Whole-folder, from the library repo's root — the same cwd `docs/releasing.md` assumes:

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

**Never edit `tests/_kit/` in a consumer.** A kit problem is a finding to fix here and re-vendor; a
local patch is a fork nobody knows about, and the next re-vendor silently reverts it.

LibKa0s is a consumer on the same terms as every addon: it reaches its own kit through `tests/_kit/`
rather than into `testkit/` directly, so `diff -r testkit tests/_kit` is the same gate here as it is
downstream, and a kit change that would break a consumer breaks this repo first.

## A consuming `tests/run.lua`

The runner keeps only what is genuinely per-addon: the load list, the lifecycle kick, and the suite
list.

```lua
local Kit    = dofile("tests/_kit/framework.lua")
local Loader = dofile("tests/_kit/loader.lua")
local mocks  = dofile("tests/wow_mock.lua")()   -- the addon's own extender

Loader.addonName = "AbsorbTracker"
local NS = {}
-- Libs first, and every file of LibKa0s.xml spelled out in XML order: the TOC pulls them through
-- the XML, so Loader.tocFiles cannot see them.
Loader.loadAll({ "libs/LibKa0s/Core.lua", ... , "libs/LibKa0s/PerfPanel.lua" }, NS, mocks)
Loader.loadAll(Loader.tocFiles("AbsorbTracker.toc"), NS, mocks)

NS:InitDB()
NS.CreateOptionsPanel()

_G.AT_TEST = Kit.expose{ NS = NS, mocks = mocks }
```

## Compatibility

The kit surface is **additive-only** on the same terms as the library: a function or seam may be
added in a later revision, never removed or repurposed, so a suite written against version 1 keeps
working unmodified.

The difference is what happens when copies disagree. The library negotiates — LibStub compares
minors and the highest wins. The kit does not: a consumer whose `tests/_kit/` differs from this
repo's `testkit/` by a single byte is **out of sync**, not on an older supported version, and the
fix is always to re-vendor rather than to read an older document. This document exists so that a
consumer that has not yet been re-vendored can still be reasoned about — not to make staying behind
a supported state.

## Bumping the revision

1. Change the kit, with its test.
2. Bump `Kit.VERSION` at the top of `testkit/framework.lua`.
3. Write `docs/api/testkit/version-<N>-docs.md`; mark this one `Superseded` and fill in its
   `Superseded by`. `tests/test_kitsync.lua` fails if the document for the live version is missing.
4. Re-vendor into `tests/_kit/` here **and** into every consumer's `tests/_kit/`, then run each
   repo's suite.
5. Add the row to [`../README.md`](../README.md).
