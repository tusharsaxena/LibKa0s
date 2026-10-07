# Analysis — 20261007-193954

- **Addon:** LibKa0s 1.71.0 (release run, `--release 1.71.0`; `addonVersion` reads 1.70.0, the
  newest tag, because a library has no `.toc` and v1.71.0 is not tagged yet)
- **Verdict:** green
- **Commit:** fae715e (`feat/2026-10-07-review-audit-remediation`), clean
- **Previous run:** 20261007-102304 (1.70.0, release run, at `6b401e1`, green; the run the `v1.70.0`
  tag was cut from)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.71.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and `complexity.blindFiles` is 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.71.0 was verified across **three**
suites, not four. This is the run the `v1.71.0` tag is cut from.

## Why this run exists

v1.71.0 is the library's share of the 2026-10-07 review and standards audit remediation. Six files'
minors move and none is added: `WidgetsLineChart.lua` 3 (segments clipped to the plot, the hover
re-synced on every render, the new `ChartMath.ClipSegment`) and `WidgetsAutocomplete.lua` 2 (hooks
re-installed on every call, `maxRows` floored), so `LibKa0s-Widgets-1.0` is key 12.1.4.3.2;
`Slash.lua` 20 and `SlashParse.lua` 2 (a number row refuses `nan` and the infinities); `Env.lua` 2
and `OptionsIdList.lua` 4 (the dead bare-global addon-API rungs are gone). The test kit moves to
revision 38: `--list`'s Totals count only the cases that run, and the new `testkit/secrets.lua`
publishes `Kit.secret`. This run measures the release commit `LK-12 (1/2)`, which dates the
CHANGELOG block, moves the README's standards pointer to v2.77.0 and restamps the consumer census.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261007-102304 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 155 files | [`lint.txt`](lint.txt) | Yes: 153 → 155 files, still 0/0 |
| tests | pass | 2139 passed, 2 skipped, 0 failed, 2141 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 2089 → 2141 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals grew; warnings still 0 |

| Metric | Value |
|---|---|
| Total NLOC | 42644 |
| Functions | 6483 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 54.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 6 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost, the chart's per-segment clip and the autocomplete's re-hook included. **`tests` carries two
skips**, the same two as at v1.70.0's release run: the kit's own `tests/_kit/test_prose.lua`,
declined under `CLAUDE.md`'s `localization-§5` deviation row, and the diagnostics contract's opt-out
case, a declared skip in a repo that keeps the default.

## What moved

Against v1.70.0's release record, 20261007-102304:

- **lint** reads two more files (153 → 155), both 0/0: `testkit/secrets.lua` and
  `tests/test_kit_secrets.lua`.
- **tests** grow by 52 cases (2089 → 2141), across the kit's secret-value simulator and inventory
  Totals, the line chart's clip and hover re-sync, the autocomplete's re-hook and row floor, the
  number-row refusals and the bare-global probes (the per-suite list is in
  [`test-cases.md`](test-cases.md)). None fails, and the skipped count stays at 2.
- **complexity** grows by 481 NLOC (42163 → 42644) and 101 functions (6382 → 6483). The averages
  do not move beyond rounding (avg CCN 2.0, avg NLOC 6.7, avg tokens 54.3 → 54.2), max CCN stays at
  15 and no function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | as in `RESULTS.md` | Tracked as one `CLAUDE.md` § *Documented deviations* row (`LK-09`), carried verbatim in `RESULTS.md`; none of the four changed in this release. |
| 1000–1500 (on notice) | `LibKa0s/OptionsIdList.lua` | 1247 | Same tracked row; 1246 → 1247 for minor 4's `C_AddOns`-only guard. 103 lines from its 1350 re-check trigger. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1458 | Unchanged at kit revision 38 (`secrets.lua` is loaded by `framework.lua`, not here). 32 lines from the 1490 re-check trigger. |
| well under the band | `LibKa0s/WidgetsLineChart.lua` | 522 | 465 → 522 for the clip and the hover re-sync. |
| well under the band | `LibKa0s/WidgetsAutocomplete.lua` | 393 | 375 → 393 for the generation-guarded re-hook. |
| new, well under the band | `testkit/secrets.lua` | 112 | A new kit file. `testkit/framework.lua` is 917, under 1000 after the Totals renderer moved to `inventory.lua` (629). |

## Actions

1. Tag the commit that adds this bundle `v1.71.0`, **locally**. Pushing the branch at the M1
   checkpoint, and the tag, the merge and any GitHub release, wait on the owner's go-ahead.
2. Step 8 of `docs/releasing.md`: re-vendor every consumer from the local `v1.71.0` tag, regenerate
   each consumer's `docs/test-cases.md` in the same commit, and run each consumer's own suite;
   WhatGroup then adopts `Kit.secret`.
3. New here: the census tool, `Ka0sAddonsCommonTasks/docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/plan-data/census.lua`,
   reads `ADDONS.md`'s Folder column as a link and finds no addon since standard v2.77.0 made it
   plain code text; the v1.71.0 census ran on a patched scratch copy
   ([`docs/api/CONSUMERS.md`](../../api/CONSUMERS.md), *Method*). The tool wants the same fix.
