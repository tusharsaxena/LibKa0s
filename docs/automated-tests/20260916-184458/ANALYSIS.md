# Analysis — 20260916-184458

- **Library:** LibKa0s 1.39.0
- **Verdict:** green
- **Commit:** 62040f3586274075ad883b70923c192c4d17fbbc (master), clean
- **Previous run:** `20260916-130819` (1.38.0 → 1.39.0)

## Headline

Both gating suites pass: `luacheck .` is 0/0 over 61 files and the headless harness is 1071/1071 with
no skipped case ([`manifest.json`](manifest.json)). `perf` is the standing `skip` this repo always
reports — it ships no `tests/perf.lua`, so this record says nothing about runtime cost. Complexity is
unchanged in every shape that matters: max CCN still 14, avg CCN still 2.0, avg NLOC still 6.5, zero
warned functions. Nothing newly crossed a band; the only movement is two new cases and 66 more lines
in `tests/test_options_widgets.lua`, a file already tracked as a cap breach.

This is a library, not an addon. Where the playbook assumes addon artifacts — a TOC version, a slash
surface, a settings schema, a `PerfSetup.lua` wiring — `library-stack-§7`'s applicability list removes
them; what remains, and what this run measures, is the four repo-shaped suites, which bind a library
repo unchanged.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260916-130819` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 61 files | [`lint.txt`](lint.txt) | No change — 0/0 over 61 files in both runs |
| tests | pass | 1071 passed, 0 skipped, 0 failed, 1071 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +2 cases (1069 → 1071), both in `test_options_widgets.lua` |
| perf | skip | no `tests/perf.lua` — this repo ships no offline scenarios | *(no artifact — nothing was measured)* | No change — permanent skip, as in every prior row |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up with size; every average flat |

**Complexity in full.** Every value is `suites.complexity` in [`manifest.json`](manifest.json); the
per-function and per-file detail behind them is [`complexity.txt`](complexity.txt).

| Metric | Value |
|---|---|
| Total NLOC | 21225 |
| Functions | 3011 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 2.0 |
| Max CCN | 14 |
| Avg tokens / function | 51.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 7 |
| Files over the 1500 cap | 2 |

The two totals rose and every average held. That is growth, not densification: 32 more NLOC across 3
more functions keeps avg NLOC at 6.5 and avg CCN at 2.0, and avg tokens moved 51.7 → 51.8, which is
rounding on a 3011-function corpus rather than a signal. Max CCN has sat at 14 for every run since
`20260907-235828`, so the recent `LibKa0s-Launcher-1.0` major and the options-composer minors for the
minimap/broker adoption arrived as more code of the same shape, not as harder code.

**`perf` — the one suite that is not a pass.** It is a `skip`, and a skip is not a pass. Nothing about
runtime cost was measured in this run, and `performance-§9`'s zero-overhead evidence does not exist
for this repo. This is the first of `automated-tests-§3`'s two sanctioned reasons (*nothing to run*),
not a ratified `performance-§12` exemption. It is also the reading `library-stack-§7` predicts: the
library **writes** the `LibKa0s-Perf-1.0` harness and is measured through its consumers, which is why
the perf-wiring MUSTs do not bind here. It remains a real gap in evidence, not a cleared requirement.

## What moved

- **lint** — 0/0 over 61 files, identical to the previous run. Scope unchanged, so this is a genuine
  no-move rather than an unexamined one.
- **tests** — 1069 → 1071. Both new cases are in `test_options_widgets.lua`, covering the tabbed-page
  fallback when `OptionsTabs.lua` is absent and the tab half drawing its banner without the widget
  half's tooltip attacher ([`test-cases.md`](test-cases.md)) — characterization for the half-vendored
  pair that HEAD's commit describes. No case skipped, in either run.
- **complexity totals** — NLOC 21193 → 21225 (+32), functions 3008 → 3011 (+3).
- **complexity averages** — avg NLOC 6.5 → 6.5, avg CCN 2.0 → 2.0, max CCN 14 → 14, warned functions
  0 → 0, warning rate 0.00 → 0.00. Flat on every axis.
- **bands** — 7 files in the 1000–1500 band and 2 over the cap, the same counts and the same files as
  the previous run. One LOC figure moved: `tests/test_options_widgets.lua` 3219 → 3285, from the two
  cases above. It is already the larger of the two tracked breaches.
- **perf** — skip, as in all 55 rows of `RESULTS.md`.
- **file count** — 61 both runs; no source file was added or removed.

## Complexity watch list

### Functions `lizard` warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|
| — | — | — | None. |

No function in the repo exceeds CCN 15; the worst is 14. The nearest neighbours are the two CCN-13
functions in `LibKa0s/Widgets.lua` (`list`, `paintMenuRow`) named in `RESULTS.md`'s file rows. Read
that with `lizard`'s Lua caveat in front of it: every `and`/`or` short-circuit counts as a decision,
so a `t.k = rec.k or D.k` defaulting run scores without branching. At a corpus-wide avg CCN of 2.0 and
zero warnings, nothing here needs that distinction drawn to be ruled on.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1312 | **Accepted, carried forward** — unchanged since the v1.34.0 re-ruling; re-check at 1350. Dense defaulting, not tangle: no function in it warns. |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1231 | **Already tracked as [`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7)** (owner: @tusharsaxena), carried forward. Breadth, not knots — worst function `groupContext` at CCN 11, file avg CCN 3.4. |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1232 | **Accepted — and past its shelf life.** Carried as a bare *Accepted* since the v1.27.0 release run, well beyond `automated-tests-§4`'s three consecutive release runs; flagged as crossed at `20260916-093057` and still unresolved here. Owed a peel or a tracked ID with an owner. Its avg CCN of 4.4 is the highest in the band, so this one is real control flow, not `or`-defaulting. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1499 | **On notice, one line from breach**, carried forward. Flat builder of independent fakes — breadth, not tangle. The next kit change that adds a line peels first or opens an issue naming the Ace-fakes seam. Re-check at 1490, already passed. |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1303 | **Owed a tracked ID — clock expired**, carried forward. Crossed at v1.8.3 and has read *owed a tracked ID* across eleven minors with no ID filed. A flat case list: length is case count, not tangle. |
| 1000–1500 (on notice) | `tests/test_slash.lua` | 1054 | **Accepted**, carried forward from its v1.34.0 crossing. Flat case list mirroring `LibKa0s/Slash.lua`; no seam of its own before the module has one. Re-check at 1350. |
| 1000–1500 (on notice) | `tests/test_widgets.lua` | 1493 | **Accepted — seven lines from breach, and past its shelf life.** Flat since the v1.27.0 release run and carried as a bare *Accepted* ever since. The next case added puts the repo in breach. Wants an issue before it crosses, not after. |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua` | 2812 | **Tracked as [`#16`](https://github.com/tusharsaxena/LibKa0s/issues/16)** (owner: @tusharsaxena), carried forward. Ruled 2026-09-08 (`M4-14`); seam named (tab and page chrome out to `OptionsTabs.lua`). Unchanged this run. |
| > 1500 (over cap) | `tests/test_options_widgets.lua` | 3285 | **Tracked as [`#8`](https://github.com/tusharsaxena/LibKa0s/issues/8)** (owner: @tusharsaxena), carried forward — **and it grew again this run**, 3219 → 3285 for the two new cases. Peels along whatever seam `#16` chooses, in that file's own commit, per `testing-§1`'s one-suite-one-module pairing. |

**Nothing newly crossed** a band or the cap at this run: the same seven band files and same two breach
files as `20260916-130819`, and no Disposition cell arrived blank. Two rows are nonetheless overdue
rather than settled — `LibKa0s/Widgets.lua` and `tests/test_widgets.lua`, both carried as a bare
*Accepted* since the v1.27.0 release run, which is past `automated-tests-§4`'s three-consecutive-release
shelf life. `tests/test_options.lua` is in the same position by a different route: its row has asked for
an ID since v1.8.3 and none exists. Re-accepting any of the three a further time is the thing the shelf
life exists to stop.

## Actions

1. File the tracked deviation ID for `LibKa0s/Widgets.lua` (1232, band) and `tests/test_widgets.lua`
   (1493, seven lines from the cap), with @tusharsaxena as owner and the widget-family split as the
   named seam — pairing the two, since `testing-§1` forbids peeling the suite on a partition the
   module has not chosen. Both are past their shelf life; this is not new to this run, but it is the
   oldest open item in the record.
2. File the ID `tests/test_options.lua`'s row has been owed since v1.8.3, or peel its render/refresh
   block to `tests/test_options_render.lua`. Either closes it; a twelfth *Accepted* does not.
3. Watch `testkit/mock_base.lua` (1499) — one line from `layout-§1`'s cap. The next kit revision that
   touches it must peel the Ace-fakes seam or open an issue naming it, before the line lands.
4. Nothing to act on in lint, tests or the CCN watch list: both gating suites are clean, no function
   warns, and no average moved.

No action is proposed for the `perf` skip. A library has no addon to wire the harness into
(`library-stack-§7`), so the absence is structural; what it costs is stated above rather than fixed
here.
