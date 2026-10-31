# Analysis — 20261031-185000

- **Addon:** LibKa0s 1.83.0 (release run, `--release 1.83.0`; a re-run for the same release, taken
  because a further `LK-A3` commit landed after the local tag was re-cut on `bd4fb11`)
- **Verdict:** green
- **Commit:** 8cffb7a (`feat/2026-10-31-font-pickers-skin-faces`), clean
- **Previous run:** [`20261031-182948`](../20261031-182948/) (`--release 1.83.0`, at `17209cf`), the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.83.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.83.0 was verified across **three** suites, not four. This bundle supersedes
`20261031-182948` as the one the tag is cut from.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-182948 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 251 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3522 passed, 2 skipped, 0 failed, 3524 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3521 → 3524 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +52 NLOC, +9 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 78123 |
| Functions | 11318 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 59.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 15 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost, the new `OnUpdate`'s included. **`tests` carries two skips**, the same two as at the previous
run: the kit's own `tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5`
deviation row, and the diagnostics contract's opt-out case, a declared skip in a repo that keeps the
default.

## What moved

Against [`20261031-182948`](../20261031-182948/), all of it `LK-A3` of Ka0sAddonsCommonTasks
`docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/`:

- **tests** grow by three cases (3521 → 3524; 3519 → 3522 passed), none failing, skipped count at 2.
- **complexity** grows by 52 NLOC (78071 → 78123) and 9 functions (11309 → 11318): the wake and its
  cases. Avg CCN and avg tokens hold.

The payload differs from `17209cf` in `LibKa0s/OptionsSkinPicker.lua` alone: the window registers no
event, and a throttled `OnUpdate` runs only while rows are drawn locked. No minor moves.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

Fifteen, unchanged, nothing over 1500. `LibKa0s/OptionsSkinPicker.lua` moves 1451 → 1455, under its
1480 trigger.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-10-31, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** none required. `git diff v1.82.0 -- LibKa0s/Sim.lua LibKa0s/SimTimeline.lua
  LibKa0s/SimPanel.lua LibKa0s/Widgets.lua` is empty
- **Commits since the previous release touching them:** none

## Actions

1. The local annotated tag `v1.83.0` is re-cut on the commit that adds this bundle. It was never
   pushed; the branch push, the merge to `master` and both tag pushes wait on the owner.
2. Step 8 re-vendors the tag into the Skin Tester and the addons.
3. In-client smoke is the owner's and none is marked passed here. The cases pin the calls the
   picker makes against the kit's fakes, so whether locked rows wake after real combat is the
   owner's to check.
4. The previous run's actions stand unchanged.
