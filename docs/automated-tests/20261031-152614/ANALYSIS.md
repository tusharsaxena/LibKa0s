# Analysis — 20261031-152614

- **Addon:** LibKa0s 1.83.0 (release run, `--release 1.83.0`; `addonVersion` reads 1.82.0 because a
  library repo has no TOC and the runner falls back to `git describe`, which finds `v1.82.0` until
  `v1.83.0` is cut on the commit that adds this bundle)
- **Verdict:** green
- **Commit:** 5b47cfb (`feat/2026-10-31-font-pickers-skin-faces`), clean
- **Previous run:** [`20261030-194244`](../20261030-194244/) (`--release 1.82.0`, at `9d83cd4`), the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.83.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.83.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261030-194244 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 248 files | [`lint.txt`](lint.txt) | Yes: 246 → 248 files, 0/0 at both |
| tests | pass | 3453 passed, 2 skipped, 0 failed, 3455 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3414 → 3455 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +1195 NLOC, +131 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 76725 |
| Functions | 11126 |
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

Against [`20261030-194244`](../20261030-194244/), all of it the font pickers and skin faces batch
(`LK-F01` to `LK-F06`, `LK-F90` of Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/`):

- **lint** covers two more files, `LibKa0s/OptionsMedia.lua` and `tests/test_options_media.lua`, still
  0/0.
- **tests** grow by 41 cases (3414 → 3455; 3412 → 3453 passed), none failing, skipped count at 2:
  mainly `tests/test_options_media.lua`, new with 30 cases, and the width-parity and outline suites.
- **complexity** grows by 1195 NLOC (75530 → 76725) and 131 functions (10995 → 11126): OptionsMedia,
  its suite, and the larger skin and media tables. Avg CCN holds at 2.1 and avg tokens goes 58.8 →
  58.9. A pre-release pass, which wrote no bundle, found `withOverrides` in `LibKa0s/Skin.lua` at
  CCN 19; it split into `ownerMedia` and `layOverrides` in `5b47cfb`, no behavior change, no minor.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

Still fourteen, nothing over 1500. Three re-check triggers fired this release, and `CLAUDE.md` and
`RESULTS.md` re-rule them rather than peel: `LibKa0s/Skin.lua` (1221, past 1150),
`LibKa0s/SkinDefs.lua` (1104, past 1100 and 61 lines added against a 40-line limit) and
`tests/test_options_appearance.lua` (1266, OptionsAppearance minor 5's cases). A peel at the close
would land after the release's independent review and, for the two payload files, move the Skin key
again. Each seam now peels in the next change that fires its trigger.
`tests/test_options_skin_picker.lua` (1133) gained no case, so its trigger did not fire.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-10-31, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** none required. `git diff v1.82.0 -- LibKa0s/Sim.lua LibKa0s/SimTimeline.lua
  LibKa0s/SimPanel.lua LibKa0s/Widgets.lua` is empty
- **Commits since the previous release touching them:** none

## Actions

1. The local annotated tag `v1.83.0` is cut on the commit that adds this bundle. It is not pushed;
   the branch push, the merge to `master` and both tag pushes wait on the owner.
2. Step 8 re-vendors the tag into the Skin Tester and the addons (the run's M1 and M2).
3. In-client smoke is the owner's and none is marked passed here. The picker's redress against a
   blank first draw (review finding 3) is unconfirmed without a client.
4. The Skin, SkinDefs and `tests/test_options_appearance.lua` seams peel in the next change that
   fires their re-ruled triggers.
