# Analysis — 20261114-111504

- **Addon:** LibKa0s 1.98.0 (release run, `--release 1.99.0`; `addonVersion` is the newest tag the
  runner's `git describe` found, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `68392b6` (`feat/2026-11-14-waypoint-arrow`), clean: the release commit that moves the
  version-bearing lines to v1.99.0, on top of `160b5d7`, which merges `master` (v1.98.0) into the
  branch. The release's record (this bundle, its `RESULTS.md` row and the changelog's release lines)
  follows it as one commit, and the tag is cut on that commit. The battery ran in a clean clone of the
  branch, named `lk-rel`, because the runner needs a `.git` directory and the worktree's `.git` is a
  file.
- **Previous run:** [`20261114-003644`](../20261114-003644/) (at `17c1497`), v1.98.0's release run.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.99.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.99.0 was verified
across **three** suites, not four. No file enters or leaves the 1000–1500 band.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261114-003644 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 339 files | [`lint.txt`](lint.txt) | Yes: 334 -> 339 files |
| tests | pass | 4530 passed, 3 skipped, 0 failed, 4533 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4487 -> 4533 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 102760 |
| Functions | 14675 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 14 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

Against v1.98.0's run, v1.99.0:

- **A new major, `LibKa0s-WaypointArrow-1.0`** (key 1.1): `LibKa0s/WaypointArrow.lua` minor 1 (778
  lines) and `LibKa0s/WaypointArrowSettings.lua` minor 1 (139), with a fifth media folder,
  `media/waypoint/`, and the generator `tools/artwork/waypoint_arrow.py`. **DebugLogDiagnostics
  minor 10** (key 22.10.1.4) names the major on the report's `LibKa0s running:` line. No `NEEDS_*`
  floor and no kit revision moves.
- Lint: 334 -> 339 files: the two payload files, the two suites (`tests/test_waypoint_arrow.lua`,
  `tests/test_waypoint_arrow_settings.lua`) and the generator. Tests: 4487 -> 4533 (46 cases), 45 of them the two new
  suites' cases. The three skips are still declared skips, not passes.
- Complexity: NLOC 101466 -> 102760 and functions 14482 -> 14675; the averages and the max did not
  move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the fourteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged; the new files are well under the band (778 and 139) |

Fourteen, nothing over 1500. The standing triggers the previous run named still stand, unchanged.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-14, by hand
- **Files reviewed:** none needed
- **Commits since the previous release touching them:** 0 that move a Sim, Widgets or `W.TestStrip` minor
- **Note:** v1.99.0 adds a new major and moves DebugLogDiagnostics; no host's scenarios or test-mode
  strips are affected.

## Actions

1. Cut the tag `v1.99.0` on the commit that adds this bundle, and merge the branch to master (on the
   owner's go-ahead of 2026-11-14).
2. Step 8: Ka0s Skill Master re-vendors this payload from the tag, retiring its commit-pinned
   provenance deviation. No other consumer owes a change: the major is additive, and a host that
   does not adopt it owes no loader line.
3. **Owner ruling, WaypointArrow register row:** one consumer, accepted 2026-11-14; its trigger is a
   second consumer.
4. Rule on the standing band triggers before the next tag (carried from the previous runs).
