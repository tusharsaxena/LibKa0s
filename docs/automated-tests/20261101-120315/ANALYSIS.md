# Analysis — 20261101-120315

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`; the manifest's `addonVersion` is read
  from the newest tag)
- **Verdict:** green
- **Commit:** 2ea32ae (`feat/2026-11-01-full-skinning`), clean
- **Previous run:** [`20261101-032159`](../20261101-032159/) (`--release 1.84.0`, at `8b2293e`), the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-032159 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 279 files | [`lint.txt`](lint.txt) | Yes: 273 → 279 files |
| tests | pass | 3728 passed, 2 skipped, 0 failed, 3730 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3615 → 3730 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: 11645 → 11981 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 82923 |
| Functions | 11981 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 59.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same count as at the previous run.

## What moved

Against [`20261101-032159`](../20261101-032159/), the library half of the full skinning run
(Ka0sAddonsCommonTasks `docs/2026-11-01-FULL_SKINNING/`), `FS-L1` to `FS-L9`, `FS-D1`, `FS-T1`,
`FS-A4` and `FS-FIX`:

- **tests** 115 more cases, for the marks, the step arrows, the title shape, the HUD tokens, the
  delete confirmation and the small misses.
- **lint** six more files, the suites and fixtures those cases brought.
- **complexity** 336 more functions, max CCN unchanged.
- **the band** 7 → 9: `LibKa0s/WidgetsDragHandle.lua` and `tests/test_launcher.lua` crossed.

An earlier `--release 1.85.0` run at `fa30be0` was refused: `P.unpaint` measured CCN 16. It was
discarded and this bundle's commit carries the fix (`0f0eeab`, SkinPaint minor 16); that commit's
message is its record.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

Nine, nothing over 1500. **Newly crossed:** `LibKa0s/WidgetsDragHandle.lua` (1016) and
`tests/test_launcher.lua` (1108), each ruled with a seam and a trigger in `CLAUDE.md`.
`LibKa0s/SkinPaint.lua` (1018): its next-minor trigger fired, and the tenth register row records
why the window block waits. `LibKa0s/Skin.lua` (1053) stays *Accepted*, carried across this
release's run and v1.84.0's; if the entry is carried once more it is owed a fix or a tracked
deviation ID (anti-pattern #53).

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-01, the lead's call under the owner's run guidelines, recorded for the owner's
  smoke; the owner was not asked
- **Files reviewed:** `tests/fixture_sim_panel.lua`, every `tests/test_sim_*.lua`,
  `tests/test_widgets_teststrip.lua`, `docs/api/Sim/version-2.3.10.2-docs.md` and
  `docs/api/Widgets/version-20.5.12.6.6.4-docs.md`
- **Commits since `v1.84.0` touching them:** five on the source files: `954daaa`, `cda17e0`,
  `5a29047`, `e6a6e3e`, `153b906`
- **Note:** no scenario, step, control or strip API moved, only the look

## Actions

1. The local annotated tag `v1.85.0` is cut on the commit that adds this bundle. The branch push,
   the merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the tag into every consumer on the run's branch, and each flip follows the
   Options document's *Moving to this version*.
3. The hosts step 5 named re-look at their scenarios or strips at their next release.
4. In-client smoke is the owner's and none is marked passed here.
