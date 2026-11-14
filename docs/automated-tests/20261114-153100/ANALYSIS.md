# Analysis — 20261114-153100

- **Addon:** LibKa0s 1.100.0 (release run, `--release 1.101.0`; `addonVersion` is the newest tag the
  runner's `git describe` found, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `25c3ecd` (`feat/2026-11-14-arrow-text-position-menu`), clean: the release's first
  commit, which dates the `v1.101.0` heading in `CHANGELOG.md`, moves the `docs/releasing.md` and
  README pointers to v1.101.0 and records the owner's ruling on the shared line's shape. It sits on
  the branch's seven commits off `master` `1dd9680` (v1.100.0): L0 (the slider box), L1 to L4 (the
  arrow's size, text, position and menu), L5 (documents and record) and LFIX (the review's fixes).
  The record (this bundle, its `RESULTS.md` row and the changelog's release lines) follows as one
  commit, and the tag is cut on that commit. The battery ran in a clean clone of the branch, named
  `LibKa0s`, because the runner needs a `.git` directory and the worktree's `.git` is a file.
- **Previous run:** [`20261114-120613`](../20261114-120613/) (at `a4775f4`), v1.100.0's release run.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.101.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.101.0 was verified
across **three** suites, not four. The band count rises from fourteen to fifteen:
`LibKa0s/WaypointArrow.lua` enters it at 1253, on notice and unruled (*Actions*); that is not a gate
condition.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261114-120613 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 345 files | [`lint.txt`](lint.txt) | Yes: 342 -> 345 files |
| tests | pass | 4626 passed, 3 skipped, 0 failed, 4629 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4578 -> 4629 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count, averages |

| Metric | Value |
|---|---|
| Total NLOC | 105298 |
| Functions | 15013 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 15 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

Against v1.100.0's run, v1.101.0:

- **WaypointArrow minor 2** and **WaypointArrowSettings minor 2** (WaypointArrow key 1.1 -> 2.2): the
  art 1.25x larger at scale 1; the text's Font block, text position, name line and distance units;
  `x`, `y` and `lock`, with a drag written through the host's `d.paths` / `d.set`; a right-click
  context menu (Clear waypoint, Share in chat, Show on map, Lock / Unlock, Reset position) a host can
  extend. **OptionsWidgets minor 46**: a number row's slider box puts junk text back. The Options key
  moves one place. No other minor, no `NEEDS_*` floor and no kit revision moves (56).
- **Contract changes** for the one consumer, Skill Master: the arrow's frame is the art box plus its
  hit pad, so the same default point draws about 11 px lower than 1.1; the text no longer reads the
  skin's Text role; offsets and saved points are in the parent's units; `SettingsRows` returns a
  second value (the afterSubgroup hooks). Skill Master adopts all of it in its round 9 (R9-1 to R9-3).
- Lint: 342 -> 345 files, the new `tests/test_waypoint_arrow_text.lua`,
  `tests/test_waypoint_arrow_position.lua` and `tests/test_waypoint_arrow_menu.lua`. Tests: 4578 ->
  4629 (51 cases). The three skips are still declared skips, not passes.
- Complexity: NLOC 103890 -> 105298 and functions 14813 -> 15013; avg NLOC 6.9 -> 6.8 and avg
  tokens 60.5 -> 60.6; avg CCN and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/WaypointArrow.lua` | 1253 | **New to the band**: 778 at minor 1 -> 1204 with L1 to L4 -> 1253 with the review's fixes. On notice and unruled, its seam named (the menu section or the font section, to a secondary paired on the shell). `CLAUDE.md`'s census still reads 1204, measured before the fixes (*Actions*) |
| 1000–1500 (on notice) | `LibKa0s/OptionsWidgets.lua` | 1164 | Grown in the band, 1117 -> 1164 with L0's slider-box guard; tracked by its register row as before |
| 1000–1500 (on notice) | the other thirteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged |

Fifteen, nothing over 1500. `WaypointArrowSettings.lua` (437) stays under the band.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-14, by hand
- **Files reviewed:** none needed
- **Commits since the previous release touching them:** 0 that move a Sim, Widgets or `W.TestStrip` minor
- **Note:** v1.101.0 moves only WaypointArrow 2, WaypointArrowSettings 2 and OptionsWidgets 46. The
  arrow's menu calls `W.ContextMenu` but does not change it, so no host's scenarios or test-mode strips
  are affected.

## Actions

1. Cut the tag `v1.101.0` on the commit that adds this bundle, and merge the branch to master on the
   owner's go-ahead.
2. Correct `CLAUDE.md`'s band census for `LibKa0s/WaypointArrow.lua` from 1204 to 1253 after the tag.
3. **Lead ruling, the Callout register row:** its trigger "v1.101.0 ships with no second consumer
   named" fires with this release. The choice between keeping the row and moving the module into
   Combat Trail is reopened for the owner.
4. **Lead ruling, `LibKa0s/WaypointArrow.lua` band row:** new to the band at 1253; trigger 1300 lines
   or the next minor.
5. Step 8: Ka0s Skill Master re-vendors this payload (its round-9 plan row R9-RV).
