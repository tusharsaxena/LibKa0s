# Analysis — 20261031-182948

- **Addon:** LibKa0s 1.83.0 (release run, `--release 1.83.0`; a re-run for the same release, taken
  because `LK-A3` landed after the local tag was re-cut on `ec41b22`)
- **Verdict:** green
- **Commit:** 17209cf (`feat/2026-10-31-font-pickers-skin-faces`), clean
- **Previous run:** [`20261031-165103`](../20261031-165103/) (`--release 1.83.0`, at `4dd0412`), the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.83.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.83.0 was verified across **three** suites, not four. This bundle supersedes
`20261031-165103` as the one the tag is cut from.

One run before this one failed the release gate and left no bundle. At `ce4f1ef` the complexity
suite warned on `lib.PaintAce` at CCN 17, its run stamped `20261031-182700`. That output was
discarded uncommitted, `17209cf` split the function, and this run measures the split.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-165103 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 251 files | [`lint.txt`](lint.txt) | Yes: 249 → 251 files, 0/0 at both |
| tests | pass | 3519 passed, 2 skipped, 0 failed, 3521 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3471 → 3521 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +1053 NLOC, +141 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 78071 |
| Functions | 11309 |
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
cost. **`tests` carries two skips**, the same two as at the previous run: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against [`20261031-165103`](../20261031-165103/), all of it `LK-A3` of Ka0sAddonsCommonTasks
`docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/`:

- **lint** gains two files, `tests/test_options_skin_picker_rows.lua` and `tests/fixture_media.lua`,
  still 0/0.
- **tests** grow by fifty cases (3471 → 3521; 3469 → 3519 passed), none failing, skipped count at 2.
- **complexity** grows by 1053 NLOC (77018 → 78071) and 141 functions (11168 → 11309): the picker's
  rows and their suite. Avg CCN holds; avg tokens move 58.9 → 59.0.

The payload differs from `4dd0412` in `LibKa0s/OptionsSkinPicker.lua`, `LibKa0s/OptionsAppearance.lua`,
`LibKa0s/OptionsMedia.lua`, `LibKa0s/Skin.lua` and `LibKa0s/SkinAce.lua`. One minor moves, SkinAce to
5; the others are this unreleased release's own.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None. `lib.PaintAce` was at 17 before `17209cf`, as the headline records.

### Files by `layout-§1` band

Fifteen, up from fourteen, nothing over 1500. `LibKa0s/OptionsSkinPicker.lua` enters the band at
1451, past the 1420 trigger, and is accepted for this release with its seam named and a new trigger
of 1480 lines or the next OptionsSkinPicker minor (`CLAUDE.md`). `LibKa0s/SkinAce.lua` is 934, under
the band. `tests/test_options_skin_picker.lua` is 1129, under its 1200 trigger.

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
3. In-client smoke is the owner's and none is marked passed here. These cases pin the calls the
   picker makes against the kit's fakes. They do not show what the client paints, so the picker's
   layout, previews and pull-outs are the owner's to check.
4. The previous run's actions stand unchanged.
