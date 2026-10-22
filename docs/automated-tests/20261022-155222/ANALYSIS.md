# Analysis — 20261022-155222

- **Addon:** LibKa0s 1.75.0 (release run, `--release 1.75.0`; `addonVersion` reads 1.74.0, the
  newest tag, because a library has no `.toc` and v1.75.0 is tagged only after this bundle is
  committed)
- **Verdict:** green
- **Commit:** 2df9193 (`feat/2026-10-22-libka0s-issues-45-58`), clean
- **Previous run:** 20261022-154939 (1.75.0, release run, at `43c4663`, green on its verdict but
  failing the release gate: one function above CCN 15)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.75.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.75.0 was verified across **three** suites, not four. This is the run the
local `v1.75.0` tag is cut from.

## Why this run exists

v1.75.0 is the library's share of the LibKa0s issues #45-#58 run. Four files are added (`Glow.lua`
1, a new major; `Sim.lua` 1, `SimTimeline.lua` 1 and `SimPanel.lua` 1, the new major
`LibKa0s-Sim-1.0`) and eight files' minors move (`Item` 3, `Widgets` 13, `OptionsTabs` 9,
`DebugLogDiagnostics` 3, and the comment-only `Core` 11, `DebugLog` 20, `OptionsIdList` 5 and
`PerfPanel` 7), so the payload is seventeen majors across forty files. The kit moves to revision
41, the first whose complexity suite records `crashedFiles` (this run's 0 is a measurement, not a
missing field).

**This is the second release run for 1.75.0.** The first,
[`20261022-154939`](../20261022-154939/), measured the release commit `LK-22 (1/2)` at `43c4663`
and found `pinHeight` in `LibKa0s/SimPanel.lua` at CCN 16, above `automated-tests-§3`'s ceiling of
15, so no tag could be cut from it. Commit `2df9193` (`LK-16: split SimPanel's pinHeight ...`)
split the function into two file-local halves with no behavior change, and this run measures that
commit.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261022-154939 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 180 files | [`lint.txt`](lint.txt) | No: 180 files, 0/0 |
| tests | pass | 2534 passed, 2 skipped, 0 failed, 2536 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No: 2536 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: max CCN 16 → 15, warnings 1 → 0 |

| Metric | Value |
|---|---|
| Total NLOC | 51354 |
| Functions | 7851 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 1.9 |
| Max CCN | 15 |
| Avg tokens / function | 53.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 6 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost, including the simulator's step machine, the docked panel's render or the Glow driver's calls
into `LibCustomGlow-1.0`. **`tests` carries two skips**, the same two as at v1.74.0's release run:
the kit's own `tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation
row, and the diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against the previous run, 20261022-154939 (one commit earlier): lint and tests do not move (180
files at 0/0; 2536 cases). Complexity grows by 3 NLOC (51351 → 51354) and 2 functions (7849 →
7851), the two halves `pinHeightBounds` and `pinHeightLegacy`; max CCN falls 16 → 15 and the
warned count 1 → 0. The averages do not move.

Against v1.74.0's release record, [`20261019-105203`](../20261019-105203/), which is the
comparison a reader of the release wants:

- **lint** reads nineteen more files (161 → 180), all 0/0 ([`lint.txt`](lint.txt)): the four new
  payload files, their fourteen suites and the Sim panel fixture, and `tools/prune-icons.lua` (kit
  revision 40's prune tool).
- **tests** grow by 338 cases (2198 → 2536): 260 across the nine new Sim suites
  (`test_sim_seam` 27, `test_sim_session` 52, `test_sim_timeline` 40, `test_sim_verbs` 42,
  `test_sim_panel` 44, `test_sim_panel_render` 31, `test_sim_isolation` 11, `test_sim_stub` 6,
  `test_sim_host` 7); 19 in the new `test_kit_vendor_sync`; 16 in `test_widgets_searchbox`, 15 in
  `test_glow` and 12 in `test_widgets_teststrip`; 8 more in `test_item` (15 → 23), 7 more in
  `test_kit_runner` (13 → 20) and 1 more in `test_debuglog_diagnostics` (46 → 47). The per-suite
  list is in [`test-cases.md`](test-cases.md). None fails, and the skipped count stays at 2.
- **complexity** grows by 6812 NLOC (44542 → 51354) and 1201 functions (6650 → 7851). The
  averages fall slightly (avg CCN 2.0 → 1.9, avg NLOC 6.7 → 6.5, avg tokens 54.4 → 53.7): the
  new code is less dense than the old. Max CCN is 15 at both releases and no function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | as in `RESULTS.md` | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`), carried verbatim in `RESULTS.md`. `OptionsIdList.lua` reads 1251 (minor 5's comment); none is at its re-check trigger. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1464 | Carried forward in `RESULTS.md`; 26 lines from the 1490 re-check trigger. |
| under the band | `LibKa0s/Perf.lua` | 997 | Three lines under the band: the next change that takes it past 1000 names its peel seam in that change. |
| new, under the band | `LibKa0s/SimPanel.lua`, `LibKa0s/Sim.lua`, `LibKa0s/SimTimeline.lua`, `LibKa0s/Glow.lua` | 867, 685, 576, 143 | v1.75.0's new files, all under the band. |

## Actions

1. Tag the commit that adds this bundle `v1.75.0`, locally and annotated. The tag is not pushed:
   it stays movable until finalize (OWNER_SCOPE B), and the branch push and the merge to `master`
   wait on the owner.
2. Step 8 of `docs/releasing.md`: the roster consumers re-vendor from the local tag on their own
   `feat/2026-10-22-libka0s-issues-45-58` branches (the run's RV items). A Sim gap found by
   DropWatcher's migration or the LootHistory and BankLedger simulators lands additively here, takes
   a fresh release run and moves the local tag.
3. `LibKa0s/Perf.lua` still sits at 997 lines. The next change that takes it past 1000 names a peel
   seam in the same change (`layout-§1`).
