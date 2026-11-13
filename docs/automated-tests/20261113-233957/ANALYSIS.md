# Analysis — 20261113-233957

- **Addon:** LibKa0s 1.96.0 (release run, `--release 1.97.0`; `addonVersion` is the newest tag the
  runner's `git describe` found, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `f12a0b3` (`feat/2026-11-13-callout-fonts`), clean: the release's first commit, which
  dates the `v1.97.0` heading in `CHANGELOG.md` and closes the plan's L10 row
  (`docs/superpowers/plans/2026-11-13-callout.md`). The release's record (this bundle, its
  `RESULTS.md` row and the changelog's release lines) follows it as one commit, and the tag is cut on
  that commit. The battery ran in a clean clone of the branch, named `LibKa0s`, because the runner
  needs a `.git` directory and the worktree's `.git` is a file.
- **Previous run:** [`20261113-220138`](../20261113-220138/) (at `1c37022`), v1.96.0's release run.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.97.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.97.0 was verified
across **three** suites, not four. Two register re-check triggers fire with this release and wait on
the owner (*Actions*); neither is a gate condition.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261113-220138 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 333 files | [`lint.txt`](lint.txt) | No (333 files) |
| tests | pass | 4459 passed, 3 skipped, 0 failed, 4462 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4459 -> 4462 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 100849 |
| Functions | 14401 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

Against v1.96.0's run, v1.97.0:

- **Media minor 13** (`Ka0s Bebas Neue`, `Ka0s Russo One`; thirty-five faces), **SkinDefsOthers
  minor 9** (their `__FACE_SIZES` rows), **CalloutSettings minor 2** (`FONT_FACES` leads the font
  row; Callout key 1.2) and **test kit revision 56** (the glyph face list; the safe set stays 117).
  The branch review moved the font row once more inside the unreleased minor 2: a face the Media copy
  ships but a loaded LibSharedMedia does not list is no longer offered (`62ce2ef`).
- Lint: 333 files, unchanged (the faces add no Lua file). Tests: 4459 -> 4462, the Media, width
  parity and Callout settings cases. The three skips are still declared skips, not passes.
- Complexity: NLOC 100755 -> 100849 and functions 14387 -> 14401; the averages and the max did not
  move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_media.lua` | 1048 | **Re-check trigger fired**: the census row in `CLAUDE.md` reads "1100 lines, or the next face added to `FONTS`", and this release adds two. Under 1100; the ruling is the owner's (*Actions*) |
| 1000–1500 (on notice) | the other twelve files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged |

Thirteen, nothing over 1500, and no new file in the band. The two standing triggers the previous
run named (`LibKa0s/Skin.lua` at 1121, `tests/test_launcher.lua` at 1235) still stand, unchanged.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-13, by hand
- **Files reviewed:** none needed
- **Commits since the previous release touching them:** 0 that move a Sim, Widgets or `W.TestStrip` minor
- **Note:** v1.97.0 moves only Media 13, SkinDefsOthers 9, CalloutSettings 2 and the kit, so no
  host's scenarios or test-mode strips are affected.

## Actions

1. Cut the tag `v1.97.0` on the commit that adds this bundle, and merge the branch to master
   (pre-authorized by the owner, plan row L10).
2. **Owner ruling, Callout register row:** its one-release trigger fires at v1.97.0 with no second
   consumer named. `CLAUDE.md` records the ruling as pending; keep the module and renew the
   trigger, or move it into Combat Trail.
3. **Owner ruling, `tests/test_media.lua` census row:** its "next face added to `FONTS`" trigger
   fired with Bebas Neue and Russo One. Peel the font inventory section or renew the trigger.
4. Step 8: Ka0s Combat Trail re-vendors this payload in its own run; other hosts take it on their
   own schedule. A host's Callout stub, if any, gains `FONT_FACES`.
5. Rule on the two standing band triggers above before the next tag (carried from the previous run).
