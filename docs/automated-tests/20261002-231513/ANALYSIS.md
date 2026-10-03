# Analysis — 20261002-231513

- **Addon:** LibKa0s 1.68.0 (release run, `--release 1.68.0`; `addonVersion` reads 1.67.0, the last tag)
- **Verdict:** green
- **Commit:** 3cd411d (`feat/2026-10-02-drag-attach`), clean
- **Previous run:** 20261002-231003 (1.68.0, release run, at `1382135`, green, superseded before the tag)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.68.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and `complexity.blindFiles` is 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.68.0 was verified across **three**
suites, not four. This is the run the `v1.68.0` tag is cut from.

A small release. One minor moves (WidgetsDragHandle 4, the `tooltipPlace` hook for AuraMaster#22),
no payload file is added and the kit stays at revision 35. The previous run, 20261002-231003, was
green on the tree before `DA-LK-04` and was superseded because it brought
`tests/test_widgets_draghandle.lua` into the `layout-§1` band; this run measures the tree after that
suite's placement cases moved to a suite of their own.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261002-231003 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 146 files | [`lint.txt`](lint.txt) | 144 → 146 files (the new suite and its bench), 0/0 |
| tests | pass | 2023 passed, 2 skipped, 0 failed, 2025 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No (2025; ten cases moved suite, none added) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | band 7 → 6; warnings 0 and blind 0 flat |

| Metric | Value |
|---|---|
| Total NLOC | 40807 |
| Functions | 6132 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 54.4 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 6 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same two as at v1.67.0's release run: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against v1.67.0's release record, 20261002-012529:

- **lint**: 144 → 146 files, 0/0. The two new files are `tests/test_widgets_draghandle_place.lua`
  and `tests/fixture_draghandle.lua`; no payload file was added.
- **tests**: 2015 → 2025 (+10), all in `tests/test_widgets_draghandle_place.lua`, for
  WidgetsDragHandle minor 4's `tooltipPlace` and a descriptor's `place`: the minor-3 call sequence
  pinned for both owners, the ANCHOR_NONE own-draw-Show-place sequence, the frame each of the three
  frames hands the hook, the cursor fallback on a raise and on every answer but `true` (with the
  lines evaluated once), the descriptor-over-spec precedence, a non-function ignored, and the minor.
- **complexity**: NLOC 40568 → 40807, functions 6095 → 6132, average NLOC 6.7 flat, average CCN 2.0
  flat, average tokens 54.5 → 54.4, max CCN 15 flat, blind files 0 flat. The hook sits in four small
  helpers in `LibKa0s/WidgetsDragHandle.lua` (`dhPlacer`, `dhTooltipLines`, `dhDrawTooltip`,
  `dhShowPlaced`), none near CCN 15.
- **band**: 6 files, the same six as at v1.67.0, every disposition carried forward. No re-check
  trigger is reached, because no file in the band changed. `tests/test_widgets_draghandle.lua` is at
  814, `LibKa0s/WidgetsDragHandle.lua` at 675.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `testkit/mock_base.lua` | as in `RESULTS.md` | Carried forward verbatim in `RESULTS.md`; none of the six changed in this release. |
| under the band (watch) | `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua`, `testkit/framework.lua`, `tests/test_options.lua` | 999, 997, 994, 988 | Unchanged since v1.66.0, each within a dozen lines of the band. |

## Actions

1. Cut the local annotated tag `v1.68.0` on the commit that adds this bundle (not pushed; the push
   and the branch's merge wait on the owner).
2. Step 8 of `docs/releasing.md`: re-vendor every consumer. AuraMaster's re-vendor and its
   `tooltipPlace` adoption ride on its own `feat/2026-10-02-drag-attach` branch (AuraMaster#22),
   and the strip tooltip's side is an in-game smoke check this run cannot measure.
