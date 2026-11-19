# Analysis — 20261119-205557

- **Addon:** LibKa0s 1.107.0 (release run, `--release 1.107.0`; `addonVersion` reads 1.106.0, the tag
  the runner's `git describe` found nearest this commit, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `72653ec` (`feat/2026-11-19-adoption-feedback`), clean: the whole v1.107.0 release but
  its own record. Since v1.106.0 the branch gained five commits: `AF-LK-01` (+ LibKa0s#96, the drag
  strip's marks, `WidgetsDragHandle.lua` minor 14 -> 15), `AF-LK-02` (the strip's tooltip above the
  strip, `WidgetsDragHandleTip.lua` minor 1 -> 2), `AF-DR-LK` (DpsRace out of the live consumer
  lists), the `AF-LK-03` release commit (changelog date, `docs/releasing.md` and `README.md` pointers,
  case list) and an `AF-LK-03` test fix (below). The record (this bundle, its `RESULTS.md` row and the
  changelog's two fixed lines) follows as one commit; none of it is read by a suite.
- **Previous run:** [`20261119-095355`](../20261119-095355/) (at `d9cd43b`), the v1.106.0 release run.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.107.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.107.0 was verified
across **three** suites, not four. No function is above CCN 15, so no split was needed.

**One earlier attempt at this release was not kept.** A `--release 1.107.0` run at `24b9cea`
(20261119-205329) passed lint (0/0, 373 files) and tests (4948 passed, 3 skipped, 4951) but its
complexity suite failed on one blind file: lizard listed 20 of the 23 functions in
`tests/test_widgets_draghandle_place.lua`, thrown by a table literal of anonymous functions beside a
string and a table in the new retired-hook case. That bundle was discarded uncommitted, the four
hooks were named as locals (`72653ec`, the case unchanged), and this run is the first of the
release on that tree. It is reported here rather than recorded as a bundle, so no trend line carries
a run whose tree is not this one's parent.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261119-095355 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 373 files | [`lint.txt`](lint.txt) | Yes: 372 -> 373 files |
| tests | pass | 4948 passed, 3 skipped, 0 failed, 4951 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4948 -> 4951 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 111203 |
| Functions | 15952 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** two files. `WidgetsDragHandle.lua` (minor 14 -> 15): the strip's marks read `?`,
  settings, close left to right, the X in the corner; each mark frame is `HELP_HIT` 14 wide (18) at
  `HELP_INSET` 6 (4), so arts sit 6 px apart (10) and `RESERVE` stays 29; the marks rest in
  `icon.tint` and light in `text.link` (the X `close.rest` / `close.hot`), the window header's
  colors; the settings mark is built unless `settings = false`; `ApplyLevel` re-levels it
  (LibKa0s#96). The three builders now share one frame maker (`dhMarkFrame`) and one hover
  (`dhMarkHover`). `WidgetsDragHandleTip.lua` (minor 1 -> 2): the strip's tooltip and its marks'
  always attach above the strip; `tooltipPlace` and a descriptor's `place` are retired, accepted
  and never called. No kit file changed.
- **Contract changes:** the Widgets key moves to 28.2.7.15.2.7.8.6.1.1 (its document and members
  manifest; the 28.2.7.14 document superseded). No member moved, so the members manifest lists the
  same surface; three `DRAG_HANDLE` values moved and two spec keys were retired.
- **Lint:** 372 -> 373 files, the new `tests/test_widgets_draghandle_marks.lua`.
- **Tests:** 4948 -> 4951 (4945 -> 4948 run). New: the marks suite (7 cases: order, the corner
  without an X, the gap, the reserve, the tint against a real `HeaderButton` and a real
  `Core.MakeCloseButton`, the default-on settings mark, no X without `onClose`), the #96 case in the
  layers suite; the placement suite rewritten for the retired hook (10 cases to 5). Every new or
  rewritten case was run against the v1.106.0 file it changes and failed there (DragHandle 14: the
  seven marks cases and #96; DragHandleTip 1: the hook, `place`, the minor floor and the tooltip
  site case). Cases that pinned minor 14's literals were re-pinned, and the drag bench's minimal
  spec takes `settings = false` so the `?` and X suites keep pinning their own arithmetic. The three
  skips are still declared skips, not passes.
- **Complexity:** NLOC 111171 -> 111203 and functions 15943 -> 15952 (the new suite's cases and
  helpers, the shared mark frame and hover). Avg NLOC, avg CCN, avg tokens and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the thirteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Unchanged by this release. `LibKa0s/WidgetsDragHandle.lua` grows 989 -> 998 and stays out of the band, 2 under its floor; `CLAUDE.md`'s census names its marks (`dhMarkFrame` through `dhBuildHelp`) as the peel before the next addition |

Thirteen, nothing over 1500.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-19, by hand
- **Files reviewed:** none required: the release moved neither `Sim.lua`, `SimTimeline.lua`,
  `SimPanel.lua` nor `Widgets.lua` (the file that defines `W.TestStrip`), the minors step 5's
  re-look keys on.
- **Commits since the previous run touching them:** 0
- **Note:** a host whose test-mode strip is a tagged drag handle (standard v2.114.0) sees the marks'
  order, pitch and tints move with every other strip; that is the re-vendor's smoke line, not a
  preview re-look.

## Actions

1. Tag `v1.107.0` on the record commit, locally only: the push, the merge to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks `docs/2026-11-19-ADOPTION_FEEDBACK/`,
   M4).
2. Re-vendor every consumer (step 8, the run's `AF-RV-*`): a strip with no `settings` field gains the
   settings mark and the `settings` icon must be declared; every strip passes `onClose`; a host's
   strip `tooltipPlace` is deleted (`AF-STRIP-*`); suites that pinned strip literals or the hook
   re-pin.
3. **Standards pointer:** v2.114.0 -> v2.115.0, on the run's unmerged standard branch: the HUD header
   rule (which marks a window owes, the drag strip's marks and their order) and DPS Race retired.
   It binds hosts; on the library side this release is that rule's drag strip half.
4. **DpsRace** left the live consumer lists; `docs/api/CONSUMERS.md` keeps the v1.83.0 scan with a
   note until its next re-run, which owes three hand verdicts (Core `RaiseStaticPopups`, Skin
   `Untrack`, Toast `PREVIEW`).
5. **Kit note**, carried: `tests/_kit/run-automated-tests.sh` refuses a git worktree, so release runs
   need the main checkout or a clean clone.
