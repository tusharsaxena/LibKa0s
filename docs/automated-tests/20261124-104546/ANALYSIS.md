# Analysis — 20261124-104546

- **Addon:** LibKa0s 1.113.0 (release run, `--release 1.113.0`; `addonVersion` reads 1.112.0, the tag
  the runner's `git describe` found nearest this commit, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `220a596c` (`feat/2026-11-24-feedback-batch`), clean: the whole v1.113.0 release but
  its own record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate and
  re-look lines) follows as one commit, and the local tag `v1.113.0` is cut on it.
- **Previous run:** [`20261124-012313`](../20261124-012313/) (at `eb83fe29`, the v1.112.0 release record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.113.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.113.0 was verified
across **three** suites, not four.

Since v1.112.0 the release adds Sim minor 5 (every successful `Start` shows the step panel; the
sample crowd `SampleCrowd` and `CROWD_MAX`, the naming convention's rule 6 retired, LibKa0s#104) and
WidgetsDropdown minor 4 (an owned menu's selected row stands 20 CIEDE2000 off a plain one, else Ka0s
Default's gold; a ticked context-menu row paints selected). Lint gains two files and the suite
twenty-eight cases.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261124-012313 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 388 files | [`lint.txt`](lint.txt) | Files 386 -> 388; still 0/0 |
| tests | pass | 5183 passed, 3 skipped, 0 failed, 5186 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Total 5158 -> 5186 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Totals grew; averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 115280 |
| Functions | 16563 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 11 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5183
passed, 0 failed, 3 skipped, 5186 total.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** two files changed. `LibKa0s/Sim.lua` 4 -> 5 (973 lines, out of the band): `sim:Start`
  shows the step panel on success, read at call time under `pcall`, so every start route shows it
  and a headless session stays headless; and the lib-level `SampleCrowd(client, n, seed)` and
  `CROWD_MAX` (64), a seeded crowd beyond the five protagonists on the convention's rules 1 to 5.
  `LibKa0s/WidgetsDropdown.lua` 3 -> 4 (951 lines): the selection's contrast rule (CIEDE2000 in the
  payload, held to `tests/fixture_de00.lua`'s), which only Azeroth (16.3) falls under, and ticked
  `W.ContextMenu` rows painted selected. No `NEEDS_*` floor rises and no payload file is added.
- **Contract changes:** two lib-level members added (`Sim.SampleCrowd`, `Sim.CROWD_MAX`) and two
  paint and behavior changes (a start shows the panel; the selected row's color). Each moved major
  has its document and members manifest, the previous ones Superseded with their *Moving to* sections.
- **Lint:** 386 -> 388 files, the two new suites; still 0/0.
- **Tests:** 5158 -> 5186 total (+28; 5155 -> 5183 passed): `tests/test_sim_start_panel.lua` (11),
  `tests/test_widgets_menu_selected.lua` (8) and nine crowd cases in `tests/test_sim_sample.lua`;
  each change's cases were red before it. The three skips are unchanged, declared skips, not passes.
- **Complexity:** NLOC 114653 -> 115280 and functions 16495 -> 16563. Averages are flat. Max CCN is
  still 15, with 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, the same eleven as the previous run, each disposition carried. `Sim.lua` (973) and `WidgetsDropdown.lua` (951) are not in the band. |

## Preview and simulation data

- **Answer:** Refreshed
- **Asked:** 2026-11-24, by hand
- **Files reviewed:** `Sim.lua` moved (minor 5), so `tests/fixture_sim_panel.lua`, every
  `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua` were re-read against `Start`'s new
  panel call and the crowd; `tests/test_sim_start_panel.lua` is new and `tests/test_sim_sample.lua`
  extended, and `docs/api/Sim/version-5.3.11.4-docs.md` written. `Widgets.lua` (the file that
  defines `W.TestStrip`) did not move.
- **Commits since the previous release touching them:** `75f285d8`, `b0d0b780`, `fe9d6440` (Sim);
  `9385671f`, `591e0636` (the dropdown).
- **Note:** every host with a simulation re-looks at its start routes and its sample names at its
  re-vendor: Drop Watcher, Loot History, Bank Ledger, KickCD, Multi Meters and Absorb Tracker (the
  Consumers table's Sim row) and Combat Trail, Range Master, Skill Master and What Group (the
  v1.109.0 sweep's).

## Actions

1. Cut the local tag `v1.113.0` on the record commit. Pushing it, merging to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks `docs/2026-11-24-FEEDBACK_BATCH/`).
2. Re-vendor every addon (round 2's `FB2-<AB>-01`): drop any hide of the step panel after a start,
   draw its own menus' selections apart (Combat Trail's character dropdown), move every named sample
   person onto `Sim.Sample` and `Sim.SampleCrowd`, and re-pin an Azeroth selection or a pinned
   `Sim 4` / `WidgetsDropdown 3` where a host suite pins one.
