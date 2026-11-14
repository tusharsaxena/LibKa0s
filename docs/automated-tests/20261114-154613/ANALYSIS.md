# Analysis — 20261114-154613

- **Addon:** LibKa0s 1.100.0 (release run, `--release 1.101.0`; `addonVersion` is the newest tag the
  runner's `git describe` found, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `050b1dd` (`feat/2026-11-14-callout-defaults`), clean: the review fix that lands after
  the first record, a comment-only correction to `LibKa0s/Callout.lua`'s minor-4 header note, which
  called the new default shadow (`shadowX = 1`, `shadowY = 1`) "down and to the right" where
  `SetShadowOffset` draws a positive y up, so the shadow is up and to the right. No default, member
  or minor moves. It sits on `e338dcd`, the first record (bundle `20261114-153219` at `6cfa001`),
  which no longer measures the tree the tag would carry, so the record is redone here: this bundle,
  its `RESULTS.md` row and the changelog's release-gate line follow the fix as one commit, and the
  tag is cut on that commit. The battery ran in a clean clone of the branch, named `LibKa0s`,
  because the runner needs a `.git` directory and the worktree's `.git` is a file.
- **Previous run:** [`20261114-153219`](../20261114-153219/) (at `6cfa001`), v1.101.0's first release
  run, superseded by this one.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.101.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.101.0 was verified
across **three** suites, not four. The band count holds at fourteen; `LibKa0s/Callout.lua` grows
inside it to 1283, still on notice and unruled (*Actions*); that is not a gate condition.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261114-153219 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 342 files | [`lint.txt`](lint.txt) | No: 342 files |
| tests | pass | 4576 passed, 3 skipped, 0 failed, 4579 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No: 4579 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | No: every figure identical |

| Metric | Value |
|---|---|
| Total NLOC | 103941 |
| Functions | 14815 |
| Avg NLOC / function | 6.9 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 14 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

Against `20261114-153219`, v1.101.0's first release run: nothing but one comment line.
`LibKa0s/Callout.lua`'s minor-4 header note now reads "a 1 px shadow up and to the right"; the code,
its defaults, every minor and the kit revision (56) are as that run measured them. Lint 342 files,
tests 4579 (4576 passed, 3 declared skips, 0 failed), NLOC 103941, functions 14815, avg CCN 2.1,
max CCN 15: all unchanged.

What v1.101.0 moves against v1.100.0 is as the first run's write-up records it
([`../20261114-153219/ANALYSIS.md`](../20261114-153219/ANALYSIS.md), *What moved*): Callout minor 4,
the owner's Look defaults (Oxanium SemiBold, the shadow at 1, 1, a black glow at full intensity,
1 px thick, at 1, -1), and CalloutSettings minor 5 (no sample line in the one tab); key 4.5, no API
break.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Callout.lua` | 1283 | **Grown in the band**: 1277 at v1.100.0 -> 1283 with L17's defaults and their header note, no function added, and unchanged by the review fix (one comment line reworded); 17 under the ~1300 split point `CLAUDE.md`'s census names. On notice and unruled, its seam named (the write-route section, or the sound section, to a secondary paired on the shell); a peel is a new shipped file and so a release, and the ruling is the lead's (*Actions*) |
| 1000–1500 (on notice) | the other thirteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged |

Fourteen, nothing over 1500. `CalloutSettings.lua` (917) stays under the band. The standing
triggers the previous runs named still stand, unchanged.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-14, by hand
- **Files reviewed:** none needed
- **Commits since the previous release touching them:** 0 that move a Sim, Widgets or `W.TestStrip` minor
- **Note:** v1.101.0 moves only Callout 4 and CalloutSettings 5, so no host's scenarios or
  test-mode strips are affected.

## Actions

1. Cut the tag `v1.101.0` on the commit that adds this bundle, and merge the branch to master (the
   run's orchestrator's, on the owner's go-ahead, plan row L17).
2. **Owner ruling, the register's Callout row:** its v1.101.0 trigger fires with this release, which
   ships with no second consumer named. The choice between the row and moving the module into
   Combat Trail is the owner's, and this release does not rule on it.
3. **Lead ruling, `LibKa0s/Callout.lua` band row:** 1283, 17 under the ~1300 split point. The next
   Callout change should peel the write-route or sound section to a paired secondary, or the lead
   accepts it with a trigger.
4. Step 8: Ka0s Combat Trail re-vendors this payload. A suite pinning the Callout's `MODULES`
   re-pins 4 and 5; a suite pinning the old Look defaults or a schema row's default re-pins the
   owner's; a suite reading `view.preview` from `layout = "side"` reads nil. No stub changes.
5. Rule on the standing band triggers before the next tag (carried from the previous runs).
