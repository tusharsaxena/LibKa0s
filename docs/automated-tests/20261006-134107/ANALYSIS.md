# Analysis — 20261006-134107

- **Addon:** LibKa0s 1.69.0 (release run, `--release 1.69.0`; `addonVersion` reads 1.68.1, the
  newest tag, because a library has no `.toc` and v1.69.0 is not tagged yet)
- **Verdict:** green
- **Commit:** 37d4916 (`feat/2026-10-06-line-chart`), clean
- **Previous run:** 20261004-143758 (1.68.1, release run, at `84cd24a`, green; the run the `v1.68.1`
  tag was cut from)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.69.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and `complexity.blindFiles` is 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.69.0 was verified across **three**
suites, not four. This is the run the `v1.69.0` tag is cut from.

## Why this run exists

v1.69.0 adds `LibKa0s/WidgetsLineChart.lua` at minor 1 (`LibKa0s-Widgets-1.0` key 12.1.4.1): the
chrome constants `lib.LINE_CHART`, the pure `lib.ChartMath` and the pooled `lib.LineChart` widget,
built for LootHistory's Timeline tab. The test kit moves to revision 37, whose new
`testkit/mock_lines.lua` answers `CreateLine` on every tracked frame with a recording Line. This run
measures the release commit `TL-LK-04`, which finalizes the CHANGELOG block, `docs/releasing.md` and
the README for the thirty-third file.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261004-143758 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 151 files | [`lint.txt`](lint.txt) | Yes: 146 → 151 files, still 0/0 |
| tests | pass | 2054 passed, 2 skipped, 0 failed, 2056 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 2025 → 2056 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals grew; warnings still 0 |

| Metric | Value |
|---|---|
| Total NLOC | 41483 |
| Functions | 6243 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 54.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 6 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost, the chart's render cost included. **`tests` carries two skips**, the same two as at v1.68.1's
release run: the kit's own `tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s
`localization-§5` deviation row, and the diagnostics contract's opt-out case, a declared skip in a
repo that keeps the default.

## What moved

Against v1.68.1's release record, 20261004-143758:

- **lint** reads five more files (146 → 151), all 0/0: `LibKa0s/WidgetsLineChart.lua`,
  `testkit/mock_lines.lua`, `tests/test_mock_lines.lua`, `tests/test_widgets_linechart_math.lua` and
  `tests/test_widgets_linechart.lua`. The vendored `tests/_kit/mock_lines.lua` is excluded with the
  rest of `tests/_kit/`.
- **tests** grow by 31 cases (2025 → 2056), from the three new suites (the Line mock, the chart math
  and the widget) and the inventory and versioning cases that the new file and kit revision add.
  None fails.
- **complexity** grows by 676 NLOC (40807 → 41483) and 111 functions (6132 → 6243). The averages
  barely move (avg CCN 2.0, avg NLOC 6.7, avg tokens 54.4 → 54.6), max CCN stays at 15 and no
  function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | as in `RESULTS.md` | Carried forward verbatim in `RESULTS.md`; none of the five changed in this release. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1458 | 1456 → 1458: kit revision 37's two lines (load `mock_lines.lua`, decorate each tracked frame). The Line recorder went to its own file, per the rule in `RESULTS.md`. 32 lines from the 1490 re-check trigger. |
| under the band (watch) | `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua`, `testkit/framework.lua`, `tests/test_options.lua` | 999, 997, 994, 988 | Unchanged in length (`framework.lua`'s one edited line is the revision integer). |
| new, well under the band | `LibKa0s/WidgetsLineChart.lua` | 463 | A new file, far from the band. |

## Actions

1. Tag the commit that adds this bundle `v1.69.0`, **locally**. Merging the branch, pushing the
   branch and the tag, and a GitHub release wait on the owner's go-ahead.
2. Step 8 of `docs/releasing.md`: re-vendor every consumer from `v1.69.0`, each on
   `feat/2026-10-06-revendor-libka0s-v1.69.0`, and run each consumer's own suite.
3. Upstream follow-up (S2): the standard's `library-stack-§7` counts of majors and files need a
   recount in WowAddonStandards.
