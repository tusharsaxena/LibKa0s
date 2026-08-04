# `testkit` — version 6

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **6** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.7.0 |
| Status | **Current** |
| Supersedes | [version 5](version-5-docs.md) — `Max CCN` measured over every function, not over the warnings block |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `6` |

## What changed at this version

**One fix, in the runner only. No Lua surface changed, and no file was added or removed.**

**`Max CCN` is measured over every function, not over lizard's warnings block.** The field was read
from the `!!!! Warnings` section, so it reported the highest CCN *among warned functions* rather than
the highest CCN in the addon. Those two numbers are equal for as long as at least one warned function
exists, which is why the bug survived five revisions — and they diverge exactly when the addon reaches
**zero warnings**, at which point the field reads `0`.

That is the worst possible moment for it to be wrong. An addon that has just eliminated its last
CCN > 15 function writes a `RESULTS.md` row whose trend column reads **`36 -> 0`**, which a reader
takes as complexity having vanished rather than as the field having had no input; `manifest.json`
records `"maxCcn": 0` beside a truthful `"functions": 2051`; and the ANALYSIS prose written from that
manifest repeats it. The record reads as measured and is false, which `performance-§10` names as worse
than an absent one.

The awk now scans every row carrying an `@` — lizard's main table is
`NLOC CCN token PARAM length name@start-end@path`, so column 2 of such a row is that function's CCN,
and the footer line has no `@` and is skipped by the same test.

**Consumers must re-vendor and regenerate.** A bundle produced by revision 5 carries the wrong
`maxCcn` whenever its `warnings` count is 0. The value is not recoverable from the manifest — but it
is recoverable from the bundle's own `complexity.txt`, which is the raw lizard output and always had
the right numbers in it.

## What this is, and what it is not

The shared headless test harness for the Ka0s addon collection: the test registry and assertions,
the source loader, the universal half of the WoW-API mock, and — new in this revision — the
consolidated automated-test runner. The Lua surface runs under plain `lua` from a repo root; the
runner is a bash script invoked from the same place.

**Nothing in the Lua surface changed between version 4 and version 5**, and no file was added or
removed. Three changes to `RESULTS.md`, all about what the trend table can be trusted to say.

**The table carries size and averages, not just totals.** Columns are now Run, Version, Lint w/e,
Files, Tests, Perf, NLOC, Funcs, Avg NLOC, Avg CCN, Max CCN, CCN warn, Verdict. An average without
its total, or a total without its average, cannot be read across a change in size — which is exactly
what a trend line is for.

**A suite that was not selected renders as `—`, not as its zeroed counters.** A `--suite lint` run
previously wrote `0/0` into the Tests column, indistinguishable from a full run that found no tests,
and the trend line would have carried that lie forever. `skip` (tool absent) and `—` (not asked for)
are different facts about why a number is missing, and both differ from zero.

**A changed column set no longer silently recreates the file.** The runner appends by matching the
header; when it does not match, it now warns and leaves the file alone rather than starting a fresh
table, because rewriting the header drops every previous row — the one thing a trend line must never
do.

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
