# Analysis — 20261031-165103

- **Addon:** LibKa0s 1.83.0 (release run, `--release 1.83.0`; a re-run for the same release, taken
  because `LK-A2` landed after the local tag was re-cut on `c8195be`)
- **Verdict:** green
- **Commit:** 4dd0412 (`feat/2026-10-31-font-pickers-skin-faces`), clean
- **Previous run:** [`20261031-163905`](../20261031-163905/) (`--release 1.83.0`, at `db02671`), the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.83.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.83.0 was verified across **three** suites, not four. This bundle supersedes
`20261031-163905` as the one the tag is cut from.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-163905 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 249 files | [`lint.txt`](lint.txt) | Yes: 248 → 249 files, 0/0 at both |
| tests | pass | 3469 passed, 2 skipped, 0 failed, 3471 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3456 → 3471 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +279 NLOC, +40 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 77018 |
| Functions | 11168 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 58.9 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 14 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same two as at the previous run: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against [`20261031-163905`](../20261031-163905/), all of it `LK-A2` of Ka0sAddonsCommonTasks
`docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/`:

- **lint** gains one file, `tests/test_options_skin_picker_faces.lua`, still 0/0.
- **tests** grow by fifteen cases (3456 → 3471; 3454 → 3469 passed), none failing, skipped count at
  2: that suite, ten of its cases seen red before the change.
- **complexity** grows by 279 NLOC (76739 → 77018) and 40 functions (11128 → 11168): that suite and
  the picker's new helpers. Avg CCN and avg tokens hold.

The payload differs from `db02671` by `LibKa0s/OptionsSkinPicker.lua` alone, and no minor moves:
OptionsSkinPicker minor 4 is this unreleased release's own.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

Still fourteen, nothing over 1500, and no band file moved. `LibKa0s/OptionsSkinPicker.lua` is 983,
out of the band and seventeen lines under it, and the new suite is 279, so
`tests/test_options_skin_picker.lua`'s trigger did not fire.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-10-31, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** none required. `git diff v1.82.0 -- LibKa0s/Sim.lua LibKa0s/SimTimeline.lua
  LibKa0s/SimPanel.lua LibKa0s/Widgets.lua` is empty
- **Commits since the previous release touching them:** none

## Actions

1. The local annotated tag `v1.83.0` is re-cut on the commit that adds this bundle. It was never
   pushed; the branch push, the merge to `master` and both tag pushes wait on the owner.
2. Step 8 re-vendors the tag into the Skin Tester and the addons (the run's M1 and M2).
3. In-client smoke is the owner's and none is marked passed here. These cases pin the calls the
   picker makes against the kit's fakes. They do not show what the client paints, and the cause of
   the blank Azeroth row is not proven, so the row is the owner's to re-check, after a full client
   restart.
4. The previous run's actions stand unchanged.
