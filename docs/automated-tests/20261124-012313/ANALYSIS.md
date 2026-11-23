# Analysis — 20261124-012313

- **Addon:** LibKa0s 1.112.0 (release run, `--release 1.112.0`; `addonVersion` reads 1.111.0, the tag
  the runner's `git describe` found nearest this commit, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `eb83fe29` (`feat/2026-11-24-feedback-batch`), clean: the whole v1.112.0 release but
  its own record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate and
  re-look lines) follows as one commit, and the local tag `v1.112.0` is cut on it.
- **Previous run:** [`20261123-231747`](../20261123-231747/) (at `79bb51a`, the v1.111.0 release record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.112.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.112.0 was verified
across **three** suites, not four.

A first release run on this branch, `20261124-012011` at `f559e050`, measured `lib.HeaderButtons`
at CCN 16 (the companion field inline). That bundle was discarded uncommitted, the function's answer
shell was split out (`eb83fe29`, no behavior change), and this run is the one the tag is cut from.

Since v1.111.0 the release adds Core minor 20 (the preview stand-in and `FollowColor`),
SkinPaintControls minor 21 (a disabled primary paints the plain button box), SkinDefsOthers minor 11
(High Contrast's HUD shadow 1, -1), WidgetsHeader minor 2 and WidgetsCopyWindow minor 7 (a companion
window carries no settings mark) and IconBrowserWindow minor 3. Lint gains two files and the suite
twenty-eight cases.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261123-231747 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 386 files | [`lint.txt`](lint.txt) | Files 384 -> 386; still 0/0 |
| tests | pass | 5155 passed, 3 skipped, 0 failed, 5158 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Total 5127 -> 5158 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Totals grew; averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 114653 |
| Functions | 16495 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 11 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5155
passed, 0 failed, 3 skipped, 5158 total.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** six files changed. `LibKa0s/Core.lua` 19 -> 20 (999 lines, its comments condensed to
  stay out of the band): `ClassColor` and `ResolveColor` take an optional `standIn`, and the new
  lib-level `FollowColor` is the class -> skin -> swatch ladder. `LibKa0s/SkinPaintControls.lua`
  20 -> 21: a disabled primary Button paints `btn.*` under `text.disabled`. `LibKa0s/SkinDefsOthers.lua`
  10 -> 11: High Contrast drops its 2, -2 HUD shadow. `LibKa0s/WidgetsHeader.lua` 1 -> 2,
  `LibKa0s/WidgetsCopyWindow.lua` 6 -> 7 and `LibKa0s/IconBrowserWindow.lua` 2 -> 3: `companion = true`.
  No `NEEDS_*` floor rises and no payload file is added.
- **Contract changes:** one member added (`Core.FollowColor`), two optional parameters (`standIn`),
  one spec field (`HeaderButtons`' `companion`) and three paint changes (a disabled primary, High
  Contrast's HUD shadow, the copy window's header). Each moved major has its document and members
  manifest, the previous ones Superseded with their *Moving to* sections.
- **Lint:** 384 -> 386 files, the two new suites; still 0/0.
- **Tests:** 5127 -> 5158 total (+31; 5124 -> 5155 passed): `tests/test_core_follow_color.lua` (9),
  `tests/test_skin_primary_disabled.lua` (19), two new header cases and one new HUD token case; 31
  cases were red before the change. The three skips are unchanged, declared skips, not passes.
- **Complexity:** NLOC 114451 -> 114653 and functions 16466 -> 16495. Averages are flat. Max CCN is
  still 15, with 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, the same eleven as the previous run, each disposition carried. `Core.lua` (999) and `SkinPaintControls.lua` (937) are not in the band. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-24, by hand
- **Files reviewed:** none needed. The release moved no minor of `Sim.lua`, `SimTimeline.lua`,
  `SimPanel.lua`, `SimPanelRender.lua` or `Widgets.lua` (the file that defines `W.TestStrip`).
- **Commits since the previous release touching them:** 0
- **Note:** `Core.FollowColor`'s `standIn` is for a host's preview, but it changes no library
  scenario or test-mode strip; the hosts that pass it (KickCD, Party Frame Enhanced, Absorb Tracker,
  Range Master) re-look at their own previews at their re-vendor, per the feedback batch's items.

## Actions

1. Cut the local tag `v1.112.0` on the record commit. Pushing it, merging to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks `docs/2026-11-24-FEEDBACK_BATCH/`).
2. Re-vendor every addon. Companion windows move to `companion = true` (Combat Trail, Drop Watcher,
   Bank Ledger, Loot History, Multi Meters, Skill Master; optionally Outfitter Reborn and Quick
   Comms); class-color ladders adopt `FollowColor` or its order (KickCD, Party Frame Enhanced, Skill
   Master, Combat Trail, Absorb Tracker, Range Master). Re-pin High Contrast's HUD shadow or a
   disabled primary's fill where a host pins it, and drop any case that clicked the copy window's gear.
