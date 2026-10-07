# Analysis — 20261007-102304

- **Addon:** LibKa0s 1.70.0 (release run, `--release 1.70.0`; `addonVersion` reads 1.69.0, the
  newest tag, because a library has no `.toc` and v1.70.0 is not tagged yet)
- **Verdict:** green
- **Commit:** 6b401e1 (`feat/2026-10-06-line-chart`), clean
- **Previous run:** 20261006-134107 (1.69.0, release run, at `37d4916`, green; the run the `v1.69.0`
  tag was cut from)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.70.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and `complexity.blindFiles` is 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.70.0 was verified across **three**
suites, not four. This is the run the `v1.70.0` tag is cut from.

## Why this run exists

v1.70.0 adds `LibKa0s/WidgetsAutocomplete.lua` at minor 1 (`lib.Autocomplete` and
`lib.AUTOCOMPLETE`, a suggestion list hung under a host's search box) and moves
`LibKa0s/WidgetsLineChart.lua` from minor 1 to 2 (the per-chart `opts.pxPerPoint`), so
`LibKa0s-Widgets-1.0` is key 12.1.4.2.1. The test kit stays at revision 37. This run measures the
release commit `TL-LK-09`, which finalizes the CHANGELOG block, `docs/releasing.md`, the README and
the two Widgets API documents for the thirty-fourth file.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261006-134107 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 153 files | [`lint.txt`](lint.txt) | Yes: 151 → 153 files, still 0/0 |
| tests | pass | 2087 passed, 2 skipped, 0 failed, 2089 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 2056 → 2089 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals grew; warnings still 0 |

| Metric | Value |
|---|---|
| Total NLOC | 42163 |
| Functions | 6382 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 54.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 6 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost, the autocomplete's provider debounce and the chart's thinning included. **`tests` carries two
skips**, the same two as at v1.69.0's release run: the kit's own `tests/_kit/test_prose.lua`,
declined under `CLAUDE.md`'s `localization-§5` deviation row, and the diagnostics contract's opt-out
case, a declared skip in a repo that keeps the default.

## What moved

Against v1.69.0's release record, 20261006-134107:

- **lint** reads two more files (151 → 153), both 0/0: `LibKa0s/WidgetsAutocomplete.lua` and
  `tests/test_widgets_autocomplete.lua`.
- **tests** grow by 33 cases (2056 → 2089): 30 in the new autocomplete suite and 3 for the line
  chart's `pxPerPoint` (the fallback, the larger spacing drawing fewer points, the endpoint and
  spike retention). None fails.
- **complexity** grows by 680 NLOC (41483 → 42163) and 139 functions (6243 → 6382). The averages
  barely move (avg CCN 2.0, avg NLOC 6.7, avg tokens 54.6 → 54.3), max CCN stays at 15 and no
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
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1458 | Unchanged: the kit stays at revision 37. 32 lines from the 1490 re-check trigger. |
| new, well under the band | `LibKa0s/WidgetsAutocomplete.lua` | 375 | A new file, far from the band. |
| well under the band | `LibKa0s/WidgetsLineChart.lua` | 465 | 463 → 465 for `pxPerPoint`. |

## Actions

1. Tag the commit that adds this bundle `v1.70.0`, **locally**. Merging the branch, pushing the
   branch and the tag, and a GitHub release wait on the owner's go-ahead.
2. Step 8 of `docs/releasing.md`: re-vendor every consumer from `v1.70.0` and run each consumer's own
   suite; LootHistory and BankLedger then adopt `Autocomplete`.
3. Owner ruling owed: the line chart's `library-stack-§7` row in `CLAUDE.md` reaches its re-check
   trigger with this release (still one consumer).
4. Upstream follow-up (S2): the standard's `library-stack-§7` counts of majors and files need a
   recount in WowAddonStandards for the thirty-fourth file.
