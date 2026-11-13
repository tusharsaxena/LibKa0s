# Analysis — 20261113-220138

- **Addon:** LibKa0s 1.95.0 (release run, `--release 1.96.0`; `addonVersion` is the newest tag the
  runner's `git describe` found, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `1c37022` (`feat/2026-11-13-callout`), clean: the release's first commit, which dates
  the `v1.96.0` heading in `CHANGELOG.md` and closes the plan's L9 row
  (`docs/superpowers/plans/2026-11-13-callout.md`). The release's record (this bundle, its
  `RESULTS.md` row and the changelog's release lines) follows it as one commit, and the tag is cut on
  that commit. The battery ran in a clean clone of the branch, because the worktree carries the
  plan's blocked L2 font work uncommitted and that work is not part of this release.
- **Previous run:** [`20261110-090851`](../20261110-090851/) (at `1266068`), v1.95.0's release run.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.96.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.96.0 was verified
across **three** suites, not four. Nothing to act on before the tag.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261110-090851 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 333 files | [`lint.txt`](lint.txt) | Yes: 326 -> 333 files |
| tests | pass | 4456 passed, 3 skipped, 0 failed, 4459 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4303 -> 4459 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 100755 |
| Functions | 14387 |
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

Against v1.95.0's run, v1.96.0:

- **`LibKa0s-Callout-1.0` key 1.1**, a new major (Callout minor 1, CalloutSettings minor 1), with its
  two voice packs under `media/sounds/`; **DebugLogDiagnostics minor 9** names Callout; the test kit
  moves to **revision 55** (the `LibKa0s sounds:` line and the sound prune).
- Lint: 326 -> 333 files. Tests: 4303 -> 4459, most of them the four Callout suites and the kit's
  sound-subset cases. The three skips are still declared skips, not passes.
- Complexity: NLOC 97152 -> 100755 and functions 13898 -> 14387; the averages (6.8 NLOC, 2.1 CCN)
  and the max (15) did not move, so the growth is size, not density.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the same thirteen files as the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged |

Thirteen, nothing over 1500, and no new file in the band: `LibKa0s/Callout.lua` is 977 lines and
`LibKa0s/CalloutSettings.lua` 608. The two re-check triggers the previous run named
(`LibKa0s/Skin.lua` at 1121, `tests/test_launcher.lua` at 1235) still stand, unchanged by this
release.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-13, by hand
- **Files reviewed:** none needed
- **Commits since the previous release touching them:** 0 that move a Sim, Widgets or `W.TestStrip` minor
- **Note:** v1.96.0 moves only Callout 1, CalloutSettings 1 and DebugLogDiagnostics 9, so no host's
  scenarios or test-mode strips are affected.

## Actions

1. Cut the tag `v1.96.0` on the commit that adds this bundle, and merge the branch to master
   (pre-authorized by the owner for this release, plan row L9).
2. Step 8: Ka0s Combat Trail, the planned first consumer, re-vendors this payload in its own run.
   Other hosts take it on their own schedule; a host suite pinning `DebugLogDiagnostics 8` re-pins at 9.
3. Rule on the two standing band triggers above before the next tag (carried from the previous run).
