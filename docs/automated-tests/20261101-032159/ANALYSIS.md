# Analysis — 20261101-032159

- **Addon:** LibKa0s 1.84.0 (release run, `--release 1.84.0`, the tag's second local re-cut; the
  manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** 8b2293e (`feat/2026-10-31-findings-remediation`), clean
- **Previous run:** [`20261101-023319`](../20261101-023319/) (`--release 1.84.0`, at `4240039`), the first re-cut,
  and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.84.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.84.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-023319 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 273 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3613 passed, 2 skipped, 0 failed, 3615 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3616 → 3615 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: 11648 → 11645 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 80495 |
| Functions | 11645 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 59.1 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 7 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same two as at the previous run.

## What moved

Against [`20261101-023319`](../20261101-023319/), one commit, `LK-M4` (the owner's ruling of 2026-11-01 that
`lib.__PatchLSM30Border` goes with no stub):

- **tests** one fewer case: the pin that the no-op stayed went with it.
- **complexity** is three functions lighter: the no-op, the case and its stand-in constructor.
- **the band** is unchanged in membership. `LibKa0s/Options.lua` falls from 1286 to 1278 lines.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

Seven, nothing over 1500, none newly crossed. `CLAUDE.md`'s census row for `LibKa0s/Options.lua`
carries the new measure.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-10-31, the owner's answer to `docs/releasing.md` step 5, standing for the re-cut
- **Files reviewed:** none new. `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`, `SimPanelRender.lua` and
  `Widgets.lua` did not move since that answer
- **Commits since the previous cut touching them:** none

## Actions

1. The local annotated tag `v1.84.0` is deleted and re-cut on the commit that adds this bundle. It was
   never pushed (`git ls-remote` shows no such tag). The branch push, the merge to `master` and the
   tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into the sixteen consumers.
3. A consumer's test that calls the deleted member moves at that re-vendor.
4. In-client smoke is the owner's and none is marked passed here.
