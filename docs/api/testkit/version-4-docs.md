# `testkit` — version 4

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **4** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.6.2 |
| Status | **Current** |
| Supersedes | [version 3](version-3-docs.md) — the manifest records all eight `lizard` footer fields; nothing in the Lua surface changed |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `4` |

## What this is, and what it is not

The shared headless test harness for the Ka0s addon collection: the test registry and assertions,
the source loader, the universal half of the WoW-API mock, and — new in this revision — the
consolidated automated-test runner. The Lua surface runs under plain `lua` from a repo root; the
runner is a bash script invoked from the same place.

**Nothing in the Lua surface changed between version 3 and version 4**, and no file was added or
removed. The revision moved because `run-automated-tests.sh` changed, and the byte-identity gate
compares content as well as the file set.

**The manifest now records all eight fields of `lizard`'s footer**, not four:

```
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
      7532       6.5     1.7       45.9     1047            2      0.00    0.02
```

Revision 3 kept the totals and `AvgCCN` and dropped `Avg.NLOC`, `Avg.token`, `Fun Rt` and `nloc Rt`,
which meant an analysis could only ever report totals. The averages are what make one run comparable
to another **across a change in size**: a total that rose because the addon grew is a different fact
from an average that rose because it got denser, and only the second is a complexity signal. Reporting
totals alone makes a growing addon look like a degrading one, every release, until nobody reads the
row.

`suites.complexity` in `manifest.json` therefore carries `nloc`, `functions`, `avgNloc`, `avgCcn`,
`maxCcn`, `avgToken`, `warnings`, `warnFunRatio`, `warnNlocRatio`, `bandFiles` and `overCapFiles`.

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
