# Analysis — 20261019-105203

- **Addon:** LibKa0s 1.74.0 (release run, `--release 1.74.0`; `addonVersion` reads 1.73.0, the
  newest tag, because a library has no `.toc` and v1.74.0 is tagged only after this bundle is
  committed)
- **Verdict:** green
- **Commit:** 2d10ec0 (`feat/2026-10-19-icons-and-polish`), clean
- **Previous run:** 20261014-215316 (1.72.0, release run, at `0521d49`, green)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.74.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and `complexity.blindFiles` is 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.74.0 was verified across **three**
suites, not four. This is the run the local `v1.74.0` tag is cut from.

## Why this run exists

v1.74.0 is the library's share of Ka0s Quick Comms' icons-and-polish batch. One file is added and
one file's minor moves: `MediaIcons.lua` 1 (generated, the packed names of three icon sets) and
`Media.lua` 5 (`ICON_SETS`, prefix resolution in `Icon`, `IconAuthor`), so `LibKa0s-Media-1.0` is
key 5.1 and the payload is fifteen majors across thirty-six files. The kit stays at revision 39.
This run measures the release commit `Release v1.74.0 (1/2)`, which completes the CHANGELOG block,
moves the README's standards pointer to v2.84.0 and adds a versioning case for the two pointers
`docs/releasing.md` step 7 moves.

**This record also covers v1.73.0.** v1.73.0 (`OptionsDrawer.lua` 1, `Options.lua` 29) was released
on its branch with no release run, so its changes have no bundle of their own; they first appear
measured here, and the deltas below include them.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261014-215316 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 161 files | [`lint.txt`](lint.txt) | Yes: 158 → 161 files, still 0/0 |
| tests | pass | 2196 passed, 2 skipped, 0 failed, 2198 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 2162 → 2198 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals grew; warnings still 0 |

| Metric | Value |
|---|---|
| Total NLOC | 44542 |
| Functions | 6650 |
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
cost, including the load-time cost of splitting 5,723 packed names into `ICONS` or the drawer's
render. **`tests` carries two skips**, the same two as at v1.72.0's release run: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against v1.72.0's release record, 20261014-215316:

- **lint** reads three more files (158 → 161), all 0/0: `LibKa0s/OptionsDrawer.lua` and
  `tests/test_options_drawer.lua` (v1.73.0) and `LibKa0s/MediaIcons.lua` (v1.74.0).
- **tests** grow by 36 cases (2162 → 2198): 26 in the new `tests/test_options_drawer.lua` and one
  in `tests/test_options_render.lua` (v1.73.0); eight in `tests/test_media.lua` (20 → 28) and one in
  `tests/test_versioning.lua` (9 → 10), the release-pointer case (v1.74.0). The per-suite list is in
  [`test-cases.md`](test-cases.md). None fails, and the skipped count stays at 2.
- **complexity** grows by 1560 NLOC (42982 → 44542) and 116 functions (6534 → 6650). The averages
  do not move beyond rounding (avg CCN 2.0, avg NLOC 6.7, avg tokens 54.3 → 54.4), max CCN stays at
  15 and no function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | as in `RESULTS.md` | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`), carried verbatim in `RESULTS.md`; none of the four changed since the previous run. |
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1314 | Same row. 1288 → 1314 for Options minor 29 (v1.73.0: the drawer's attach and the scroll-offset restore); 86 lines under its 1400 re-check trigger. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1464 | Unchanged; the kit did not move. 26 lines from the 1490 re-check trigger. |
| under the band | `LibKa0s/Perf.lua` | 997 | Unchanged, three lines under the band: the next change that takes it past 1000 names its peel seam in that change. |
| new, under the band | `LibKa0s/MediaIcons.lua` | 793 | Generated by `tools/artwork/icon_cleaner.py`, packed several names per line so it stays under the cap as the sets grow. |
| new, under the band | `LibKa0s/OptionsDrawer.lua` | 414 | v1.73.0's new file. |

## Actions

1. Tag the commit that adds this bundle `v1.74.0`, locally; the branch is pushed, and the tag push
   and the merge to `master` wait on the owner.
2. Step 8 of `docs/releasing.md`: Quick Comms re-vendors from the local tag on its own
   `feat/2026-10-19-icons-and-polish` (its plan's task Q6, which also measures its
   `tests/test_vendor_sync.lua` against the ~28 MB larger payload); the owner re-vendors the other
   thirteen consumers later (attribution tracked by LibKa0s#55).
3. `LibKa0s/Perf.lua` sits at 997 lines. The next change that takes it past 1000 names a peel seam
   in the same change (`layout-§1`).
