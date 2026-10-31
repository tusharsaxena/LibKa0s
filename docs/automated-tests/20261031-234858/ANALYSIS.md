# Analysis — 20261031-234858

- **Addon:** LibKa0s 1.84.0 (release run, `--release 1.84.0`; the manifest's `addonVersion` reads
  1.83.0 because it is read from the newest tag, which this run precedes)
- **Verdict:** green
- **Commit:** ec46aae (`feat/2026-10-31-findings-remediation`), clean
- **Previous run:** [`20261031-213552`](../20261031-213552/) (label `findings-remediation`, at
  `e7363f3`), the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.84.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.84.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-213552 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 273 files | [`lint.txt`](lint.txt) | Yes: 256 → 273 files |
| tests | pass | 3613 passed, 2 skipped, 0 failed, 3615 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3524 → 3615 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: band 11 → 7; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 80532 |
| Functions | 11651 |
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

Against [`20261031-213552`](../20261031-213552/), the `LK-M2-*` items of Ka0sAddonsCommonTasks
`docs/2026-10-31-FINDINGS_REMEDIATION/M2_LIBRARY_RELEASE.md`:

- **lint** covers 17 more files, the peels' new files, the Charts major and their suites.
- **tests** grow by 91 cases (3524 → 3615; 3522 → 3613 passed), none failing, skipped count at 2.
- **the band** falls from 11 files to 7. `LibKa0s/OptionsIds.lua`, `LibKa0s/SkinDefs.lua`,
  `LibKa0s/SimPanel.lua` and `testkit/mock_base.lua` left it on their named seams.
- **complexity** grows to 11651 functions and 80532 NLOC (11318 and 78167 at the previous run), with avg CCN unchanged at 2.1.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

Seven, nothing over 1500, none newly crossed. The dispositions of `LibKa0s/OptionsSkinPicker.lua`,
`LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` and `LibKa0s/Skin.lua` now name the seam left
after each peel and the trigger `CLAUDE.md` rules. `LibKa0s/OptionsTabs.lua` stands 11 lines under its
1300 trigger.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-10-31, the owner's answer to `docs/releasing.md` step 5
- **Files reviewed:** `LibKa0s/SimPanel.lua`, `LibKa0s/SimPanelRender.lua`, on the owner's reading of
  the split as a pure move (284907a). `Sim.lua`, `SimTimeline.lua` and `Widgets.lua` did not move
- **Commits since the previous release touching them:** one, 284907a

## Actions

1. The local annotated tag `v1.84.0` is cut on the commit that adds this bundle. It is not pushed;
   the branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the tag into the sixteen consumers.
3. In-client smoke is the owner's and none is marked passed here.
4. LibKa0s#68's in-client sweep and the line chart's tracked promotion remain open.
