# Analysis — 20261024-121210

- **Addon:** LibKa0s 1.77.0 (release run, `--release 1.77.0`; `addonVersion` reads 1.77.0, the
  newest tag, because the local `v1.77.0` tag cut on `78240f7` already exists; that tag is moved to
  the commit that adds this bundle)
- **Verdict:** green
- **Commit:** 74d0bd3 (`feat/2026-10-24-keybinds-layout-strata`), clean
- **Previous run:** 20261024-074358 (1.77.0, release run, at `3c2bb20`), the first close of
  v1.77.0, which this run supersedes; before it, 20261024-073953 (at `ea2cb09`), whose complexity
  suite warned on three functions.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.77.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.77.0 was verified across **three** suites, not four. This is the run the
local `v1.77.0` tag is moved to; no function needed a split for the CCN 15 ceiling.

## Why this run exists

v1.77.0 was closed and tagged locally at `78240f7` (LK-90), then extended before any push with
M3 of the 2026-10-24 run, the settings layout (item 020; Ka0sAddonsCommonTasks
`docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`): OptionsCompose minor 9 (`MasterControls` `notes`,
`resetPositionTooltip` and `lockIsPreview`, the *Master opacity* label and the frameless packing,
`LK-30`), minor 10 (`tooltips` on the group composers, `LK-31`) and minor 11
(`O.ResetAllTooltip`, `LK-32`). The Options key moves to **30.2.34.3.5.9.2.11.4.2.1.3**; no other
file's minor moves, and the payload is still seventeen majors across forty-one files at test kit
revision 42. `LK-95` re-closed the release (`74d0bd3`), and this run measures that commit.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261024-074358 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 197 files | [`lint.txt`](lint.txt) | Yes: 194 → 197 files, 0/0 at both |
| tests | pass | 2747 passed, 2 skipped, 0 failed, 2749 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 2715 → 2749 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +453 NLOC, +69 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 55778 |
| Functions | 8549 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 1.9 |
| Max CCN | 15 |
| Avg tokens / function | 53.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same two as at the first close: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against the first close, [`20261024-074358`](../20261024-074358/):

- **lint** reads 3 more files (194 → 197), still 0/0 ([`lint.txt`](lint.txt)): the three new
  suites below. No payload file was added.
- **tests** grow by 34 cases (2715 → 2749; 2713 → 2747 passed), all in three new suites:
  `test_options_compose_master` (15, `LK-30`), `test_options_compose_tooltips` (12, `LK-31`) and
  `test_options_reset_tooltip` (7, `LK-32`). No pre-existing suite changed its count. The per-suite
  list is in [`test-cases.md`](test-cases.md). None fails, and the skipped count stays at 2.
- **complexity** grows by 453 NLOC (55325 → 55778) and 69 functions (8480 → 8549): the new suites
  and `LibKa0s/OptionsCompose.lua` (637 → 758, `MasterControls` split into file-local helpers so no
  function nears the ceiling). The averages hold (avg CCN 1.9, avg NLOC 6.5; avg tokens
  53.7 → 53.8). Max CCN is 15 and no function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | 1320, 1375, 1251, 1350, 1444 | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`), carried verbatim in `RESULTS.md`. None moved: the extension touched only `OptionsCompose.lua` among the payload files (`git diff 78240f7..74d0bd3 -- LibKa0s/OptionsTabs.lua LibKa0s/OptionsWidgets.lua` is empty). |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1464 | Carried forward in `RESULTS.md`; unchanged, 26 lines from the 1490 re-check trigger. |
| 1000–1500 (on notice) | `tests/test_sim_panel.lua` | 1056 | Carried forward in `RESULTS.md`; unchanged. |
| 1000–1500 (on notice) | `LibKa0s/DebugLog.lua` | 1008 | Carried forward in `RESULTS.md` and `CLAUDE.md`; unchanged. |
| 1000–1500 (on notice) | `tests/test_options_compose.lua` | 1012 | Carried forward in `RESULTS.md` and `CLAUDE.md`; unchanged, because OptionsCompose minors 9-11 put their cases in suites of their own, so its "next OptionsCompose minor that adds cases here" trigger did not fire. |
| under the band | `LibKa0s/OptionsCompose.lua`, `LibKa0s/Perf.lua`, `LibKa0s/SimPanel.lua` | 758, 997, 956 | `OptionsCompose.lua` 637 → 758 with minors 9-11; the other two unchanged. |

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-10-24, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** the extension's diff (`git diff 78240f7..74d0bd3 --stat`), which touches no
  `Sim*.lua`, `Widgets.lua`, `tests/fixture_sim_panel.lua`, `tests/test_sim_panel*.lua` or
  `docs/api/Sim/` file
- **Commits since the previous release run touching them:** 0
- **Note:** the settings-layout extension touches no simulator or preview surface. Test mode's
  composed row only gains the `omit.locked` packing (OptionsCompose minor 9): with `locked`
  omitted, *Minimap button* sits beside *Debug console* and *Test mode* opens its own line. Its
  path, tooltip and behavior are unchanged.

## Actions

1. Move the local annotated tag `v1.77.0` from `78240f7` to the commit that adds this bundle. The
   tag is not pushed: the branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 of `docs/releasing.md`: the roster consumers re-vendor again from the moved tag (the
   run's `<PFX>-RV2` items), each adding `ResetAllTooltip` to its Options degradation stub and
   updating any suite that pinned "Master alpha".
3. No band file reached its trigger. `LibKa0s/Perf.lua` still sits at 997: the next change that
   takes it past 1000 names a peel seam in the same change (`layout-§1`).
