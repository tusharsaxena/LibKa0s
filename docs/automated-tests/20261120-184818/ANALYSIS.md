# Analysis — 20261120-184818

- **Addon:** LibKa0s 1.108.0 (release run, `--release 1.108.0`; `addonVersion` reads 1.107.0, the tag
  the runner's `git describe` found nearest this commit, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `59c1f0a` (`feat/2026-11-20-libka0s-94-97-99-100`), clean: the whole v1.108.0 release
  but its own record. Since the previous run (`72653ec`) the tree gained v1.107.0's own record and
  its `#95` fold (`5e96365`, `87ae35f`, merged to `master` as `140d56d`), then this release's items:
  `SD-LK-94` (the footer lays only its shown marks, Widgets minor 30), `SD-LK-99` (a secret strip's
  tooltip above its nearest readable ancestor, WidgetsDragHandleTip minor 3), `SD-LK-100` (the
  call-out strip's close and settings marks, Callout minor 5), `SD-LK-97` Batches A to D with their
  review fixes (skin defaults across the composers, bars, charts, menus, the call-out, the waypoint
  arrow and host-skinned windows, LibKa0s#97), `SD-LK-GUARD` with two review rounds (test kit
  revision 58), and the `SD-LK-REL` release commit (below). The record (this bundle, its
  `RESULTS.md` row and the changelog's two lines) follows as one commit; none of it is read by a
  suite.
- **Previous run:** [`20261119-205557`](../20261119-205557/) (at `72653ec`), the v1.107.0 release run.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.108.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.108.0 was verified
across **three** suites, not four.

**Six functions were over CCN 15 before this run, and were split first.** A measurement of the
branch tip `f641c0a` through the runner's complexity suite (`--suite complexity --no-bundle`, then
the same sighted shadow read for the rows) warned on six functions, max CCN 23, each grown by an
`SD-LK-97` batch: `lib.ApplySkin` (`Core.lua`, 23), `lib.New` (`Charts.lua`, 17),
`lib.__checkOwner` (`Widgets.lua`, 17), `Shell` (`SkinPaint.lua`, 18), `textColor`
(`WaypointArrow.lua`, 20) and `surfaceProblem` (`testkit/skin_switch.lua`, 16). The release commit
`59c1f0a` splits each along its own seam as a pure move inside the minor this release already
moves: `ownerShell` (14; `ApplySkin` 10), `checkOwner` (3; `New` 15), `warnOwner` (8;
`__checkOwner` 10), the not-kept window's fade, edge and bands into the existing `shellBody` (8;
`Shell` 15, no function added to SkinPaint), `plainRGBA` (7; `textColor` 12) and
`familyFieldsProblem` (5; `surfaceProblem` 12, copied to `tests/_kit/`). Both clients' suites and
luacheck were green on that tree before it was committed, and no case changed. No bundle was
written for the pre-split measurement, so no trend line carries a tree that is not this one's
parent.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261119-205557 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 378 files | [`lint.txt`](lint.txt) | Yes: 373 -> 378 files |
| tests | pass | 5076 passed, 3 skipped, 0 failed, 5079 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4951 -> 5079 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 113617 |
| Functions | 16328 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5076
passed, 0 failed, 3 skipped, 5079 total.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** seventeen files. Core 19, Widgets 30, WidgetsDropdown 3, WidgetsDragHandle 16,
  WidgetsDragHandleTip 3, WidgetsLineChart 8, WidgetsBar 2, Callout 5, CalloutSettings 6,
  WaypointArrow 3, WaypointArrowSettings 3, Charts 3, ChartsRender 2, SkinPaint 20, SkinPaintHud 2,
  SkinPaintControls 19 and OptionsCompose 20; the CHANGELOG's v1.108.0 block says what each does.
  The kit moves to revision 58 (`skin_switch.lua`, `skin_values.lua` and their self-tests).
- **Contract changes:** seven majors move key: Core 19.1, Widgets 30.3.7.16.3.8.8.6.1.2, Callout 5.6,
  WaypointArrow 3.3, Charts 3.2, Skin 18.1.28.10.20.19.2.1.19.4.9 and Options
  38.5.46.3.7.2.9.17.3.1.4.20.13.7.5.8.7.12.1.1.1.4, each with its document and members manifest.
  Callout gains five members (`FROM_SKIN`, `MEANING`, `FOLLOW_FROM`, `FollowKeys`, `MoveToSkin`) and
  Widgets one (`OwnerWarnings`). No `NEEDS_*` floor rises and no file is added. **Defaults change**
  (LibKa0s#97, the owner's R-2): what a host left out now follows the skin.
- **Lint:** 373 -> 378 files, the five new suites (`test_options_compose_follow.lua`,
  `test_skin_follow_bars.lua`, `test_skin_follow_callout.lua`, `test_skin_follow_shells.lua`,
  `test_widgets_menu_follow.lua`).
- **Tests:** 4951 -> 5079 (4948 -> 5076 run): the five new suites, the footer, tooltip-site and
  call-out look cases of `SD-LK-94`, `-99` and `-100`, and the kit's revision-58 self-tests. The
  three skips are still declared skips, not passes.
- **Complexity:** NLOC 111203 -> 113617 and functions 15952 -> 16328. Avg tokens 60.7 -> 60.8; avg
  NLOC, avg CCN and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the thirteen files [`../RESULTS.md`](../RESULTS.md) lists | see there | Thirteen, nothing over 1500. Three re-check triggers fired on this branch and are carried unpeeled, each recorded in `CLAUDE.md`'s census as the lead's ruling: `LibKa0s/OptionsCompose.lua` 1217 (past 1150, Batch A), `LibKa0s/SkinPaintControls.lua` 1114 (past 1100, Batch B) and `LibKa0s/Callout.lua` 1416 (Batch C; its entry asks for an explicit ruling before the next change). `LibKa0s/WaypointArrow.lua` 1273 is 27 under its 1300 trigger and `LibKa0s/SkinPaint.lua` holds at 1048 with no function added. `LibKa0s/Core.lua` (999) and `LibKa0s/Widgets.lua` (998) stay out of the band. |

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-20, by hand
- **Files reviewed:** `LibKa0s/Widgets.lua` (the file that defines `W.TestStrip`) moves to minor 30:
  the footer lays only its shown marks (`SD-LK-94`) and every library widget, `W.TestStrip`
  included, runs the owner check at build (`SD-LK-97.1`), which reports through a registered sink
  and draws nothing. The strip's placement and look do not move: `tests/test_widgets_teststrip.lua`
  and `tests/test_widgets_teststrip_dock.lua` are green and unchanged since v1.107.0.
- **Commits since the previous run touching them:** 4: `87ae35f` (v1.107.0's own `#95` fold, the
  dock's secret geometry, Widgets minor 29), `93633f4`, `082272f` and `59c1f0a` (the `SD-LK-REL`
  split of `__checkOwner`)
- **Note:** no Sim, SimTimeline or SimPanel minor moves.

## Actions

1. Tag `v1.108.0` on the record commit, locally only: the push, the merge to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks
   `docs/2026-11-20-LIBKA0S_94_97_99_100/`).
2. Re-vendor every consumer (step 8): the CHANGELOG's v1.108.0 block lists what each host owes
   (companion AceDB defaults, the one-time moves through `Skin.ResetToSkin` or
   `Callout:MoveToSkin`, Combat Trail's `onClose` / `onSettings`, Quick Comms' `skinBands`, Skill
   Master's arrow repaint on a skin switch), and kit revision 58's skin guards may turn a host's
   suite red, which is intended.
3. **Band rulings owed** (the lead's): OptionsCompose, SkinPaintControls and Callout, above.
4. **Kit note**, carried: `tests/_kit/run-automated-tests.sh` refuses a git worktree, so release runs
   need the main checkout or a clean clone.
