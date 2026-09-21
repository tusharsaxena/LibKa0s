# Analysis — 20260921-144300

- **Addon:** LibKa0s 1.50.0
- **Verdict:** green
- **Commit:** 61cf04f (master)
- **Previous run:** 20260921-120741 (v1.49.0 → v1.49.1)

## Headline

Green on every suite that ran, and the release gate's five conditions all hold: lint 0/0, 0 failed
tests, complexity measured with 0 functions over CCN 15. The only movement is this release's own
work — nine new test cases and 180 NLOC for LibKa0s #34's four `O.IdList` fixes — and every
complexity average is flat, so the growth is size and not density. Nothing newly crossed a
`layout-§1` band. Two long-standing watch-list entries remain owed a ruling (see Actions); neither
is new here and neither gates this release.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260921-120741 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 72 files | [`lint.txt`](lint.txt) | No. Same 72 files, same 0/0. |
| tests | pass | 1264 passed, 0 skipped, 0 failed, 1264 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +9 cases (1255 → 1264). All nine are this release's. |
| perf | skip | not measured — this library ships no `tests/perf.lua` | — | No. Skipped at the previous run too. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up, every average flat. |

**`perf` was not measured.** LibKa0s ships no `tests/perf.lua`, so there were no offline scenarios to
run. This is the one skip that satisfies the release gate rather than blocking it
(`automated-tests-§3`), and it means this release was verified across **three** suites, not four.

| Metric | Value |
|---|---|
| Total NLOC | 25125 |
| Functions | 3567 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 52.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 2 |

## What moved

- **lint** — nothing. 0 warnings / 0 errors across the same 72 files.
- **tests** — 1255 → **1264**, +9, all from LibKa0s #34: three pinning that the X's highlight covers
  its whole hit area and goes back on release, two that an entry label's `__wordWrap` and
  `__highlight` are cleared when AceGUI pools it, and four on the column fit and its per-style
  floors. Every one was negative-checked against the unpatched code before it was committed.
- **complexity, totals** — NLOC 24945 → **25125** (+180) and functions 3541 → **3567** (+26). That is
  `entryRemoveLit`, `entryRelease`, `idContentWidth`, `entryMinContent` and `fitIdColumns`, plus
  their comment blocks and the new cases.
- **complexity, averages** — **flat**: avg CCN 2.0 → 2.0, avg NLOC/function 6.6 → 6.6, max CCN 15 →
  15, avg tokens 52.1 → **52.2**. The added functions are guard-and-return shaped, so the density
  reading did not move and the growth reads as size.
- **bands** — unchanged: 9 files in 1000–1500, 2 over the cap. **Nothing newly crossed.**
  `LibKa0s/OptionsWidgets.lua` and `tests/test_options_widgets.lua` both grew with this release and
  both were already over the cap under their existing issues.

## Complexity watch list

Carried in full in [`RESULTS.md`](../RESULTS.md), which the runner regenerated from this run's own
`lizard` output. Summarised here:

### Functions `lizard` warned on

None. Zero functions above CCN 15, which is the condition the release gate enforces.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1465 | Accepted, re-ruled at v1.33.0; re-check at 1350 (carried) |
| 1000–1500 (on notice) | `LibKa0s/OptionsTabs.lua` | 1197 | *(blank — never ruled on)* |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1308 | Tracked as [`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7) |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1232 | Accepted since v1.27.0 — **shelf life crossed**, owed a peel or a deviation ID |
| 1000–1500 (on notice) | `testkit/framework.lua` | 1227 | *(blank — never ruled on)* |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1446 | On notice, 18 lines from breach; next kit change over 18 lines peels first |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1307 | **Owed a tracked ID since v1.8.3** — eleven minors and counting |
| 1000–1500 (on notice) | `tests/test_slash.lua` | 1327 | Newly crossed at v1.34.0; re-check at 1350 |
| 1000–1500 (on notice) | `tests/test_widgets.lua` | 1493 | Accepted, **7 lines from breach** |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua` | 3583 | Ruled 2026-09-08, tracked as [`#16`](https://github.com/tusharsaxena/LibKa0s/issues/16) |
| > 1500 (over cap) | `tests/test_options_widgets.lua` | 3882 | Ruled 2026-09-08, tracked as [`#8`](https://github.com/tusharsaxena/LibKa0s/issues/8) |

## Actions

None gate this release. Three are owed, all pre-existing and all re-stated rather than discovered
here:

1. `LibKa0s/Widgets.lua` (1232) has carried a bare *Accepted* since v1.27.0, well past
   `automated-tests-§4`'s three consecutive release runs. It is owed either a peel — per-widget
   files, each widget already being a self-contained constructor — or a tracked deviation ID with an
   owner.
2. `tests/test_options.lua` (1307) has read *owed a tracked ID* since v1.8.3, across eleven minor
   versions, and no ID exists. File it or peel it at `tests/test_options_render.lua`.
3. `LibKa0s/OptionsTabs.lua` (1197) and `testkit/framework.lua` (1227) carry **blank** dispositions:
   both crossed into the band and neither has been ruled on. A blank cell is this record saying
   nobody has decided yet, which is not the same as accepting it.

Two entries are close enough to matter at the next change rather than this one:
`tests/test_widgets.lua` is 7 lines under the 1500 cap and `testkit/mock_base.lua` is 18 under it.
