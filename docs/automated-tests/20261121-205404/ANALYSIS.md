# Analysis — 20261121-205404

- **Addon:** LibKa0s 1.109.0 (release run, `--release 1.109.0`; `addonVersion` reads 1.108.0, the tag
  the runner's `git describe` found nearest this commit, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `245dc3c` (`feat/2026-11-21-sync-followups`), clean: the whole v1.109.0 release but its
  own record. Since the previous run (`a0b017e`) the tree gained that run's record (`f70fbb5`) and the
  independent review's fixes (`245dc3c`: the Callout band row in `RESULTS.md` ruled, README's Options
  file count, two wordings, one case renamed). No payload or kit file moved, so every figure below is
  the previous run's; this run exists because the tag is cut on a commit whose parent the record
  measured. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate line)
  follows as one commit.
- **Previous run:** [`20261121-203937`](../20261121-203937/) (at `a0b017e`), this release's first run, superseded by this one for the tag.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.109.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.109.0 was verified
across **three** suites, not four.

The release is three pure moves and two documentation fixes. No function crossed CCN 15, so nothing
was split before the run.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261120-184818 (v1.108.0) |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 382 files | [`lint.txt`](lint.txt) | Yes: 378 -> 382 files |
| tests | pass | 5076 passed, 3 skipped, 0 failed, 5079 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No (three cases renamed by their re-pins) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 113699 |
| Functions | 16329 |
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

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5076
passed, 0 failed, 3 skipped, 5079 total.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** four files added, three changed. `Callout.lua` 6 (1416 -> 1113) with the new
  `CalloutRoute.lua` 1 and `CalloutSound.lua` 1; `OptionsCompose.lua` 21 (1217 -> 883) with the new
  `OptionsComposeMaster.lua` 1; `SkinPaintControls.lua` 20 (1114 -> 920) with the new
  `SkinPaintNav.lua` 1. Each a pure move on its census seam; the CHANGELOG's v1.109.0 block says
  what moved where. The kit moves to revision 59 (`README.md` counts, `Kit.VERSION`).
- **Contract changes:** none. Three majors move key, Callout 6.1.1.6, Options
  38.5.46.3.7.2.9.17.3.1.4.21.1.13.7.5.8.7.12.1.1.1.4 and Skin 18.1.28.10.20.19.2.1.20.1.4.9, each
  with its document and a members manifest naming the same members. No `NEEDS_*` floor rises.
- **Lint:** 378 -> 382 files, the four new payload files.
- **Tests:** 5079, unchanged in count; the Callout, OptionsCompose and kit-revision pins were re-pinned
  (`callout: the major loads at minor 6 ...`, `compose follow: OptionsCompose is at minor 21`, `the kit
  is revision 59`). The three skips are still declared skips, not passes.
- **Complexity:** NLOC 113617 -> 113699 and functions 16328 -> 16329 (the Master controls attach
  wrapper); the headers of the four new files are most of the NLOC. Averages and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, two fewer than at v1.108.0: `LibKa0s/OptionsCompose.lua` and `LibKa0s/SkinPaintControls.lua` left on their peels. `LibKa0s/Callout.lua` stays at 1113, both named seams taken and accepted with a new trigger (1250 lines, or the next Callout minor that adds a function). No other band file moved, and no re-check trigger fired at the close; each disposition is in `CLAUDE.md`'s census. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-21, by hand
- **Files reviewed:** none needed: the release moves none of step 5's minors (`Sim.lua`,
  `SimTimeline.lua`, `SimPanel.lua`, or `Widgets.lua`, which defines `W.TestStrip`).
- **Commits since the previous run touching them:** 0

## Actions

1. Tag `v1.109.0` on the record commit, locally only: the push, the merge to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks `docs/2026-11-21-SYNC_FOLLOWUPS/`).
2. Re-vendor every consumer (step 8): a host whose tests load library files by name adds the four new
   files after the files they were peeled from, and re-pins `Callout 5`, `OptionsCompose 20`,
   `SkinPaintControls 19` or `KIT_VERSION` 58 where it pins them. No facade member moves.
3. **Owed:** the 152 `zero — UNREAD` rows of `docs/api/CONSUMERS.md`, read by hand.
