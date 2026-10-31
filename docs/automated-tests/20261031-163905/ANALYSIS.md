# Analysis — 20261031-163905

- **Addon:** LibKa0s 1.83.0 (release run, `--release 1.83.0`; a re-run for the same release, taken
  because `LK-A1` landed after the local tag was cut on `3122d87`, so `addonVersion` reads 1.83.0
  from `git describe`)
- **Verdict:** green
- **Commit:** db02671 (`feat/2026-10-31-font-pickers-skin-faces`), clean
- **Previous run:** [`20261031-152614`](../20261031-152614/) (`--release 1.83.0`, at `5b47cfb`), the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.83.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.83.0 was verified across **three** suites, not four. This bundle supersedes
`20261031-152614` as the one the tag is cut from.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-152614 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 248 files | [`lint.txt`](lint.txt) | No: 248 files, 0/0 at both |
| tests | pass | 3454 passed, 2 skipped, 0 failed, 3456 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3455 → 3456 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +14 NLOC, +2 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 76739 |
| Functions | 11128 |
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

Against [`20261031-152614`](../20261031-152614/), all of it `LK-A1` of Ka0sAddonsCommonTasks
`docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/`:

- **lint**: unchanged, 0/0 in 248 files.
- **tests** grow by one case (3455 → 3456; 3453 → 3454 passed), none failing, skipped count at 2:
  `tests/test_skin_width_parity.lua`'s nil-owner case under a ruRU `GetLocale`, seen red first with
  `LibKa0s/Skin.lua:873: table index is nil`.
- **complexity** grows by 14 NLOC (76725 → 76739) and 2 functions (11126 → 11128): that case, its
  locale mock and the one line in `withOverrides` that returns a nil owner's copy uncached. Avg CCN
  and avg tokens hold, and `withOverrides` is CCN 11.

The payload differs from `5b47cfb` by `LibKa0s/Skin.lua` alone, and no minor moves: Skin minor 10 is
this unreleased release's own.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

Still fourteen, nothing over 1500. `LibKa0s/Skin.lua` is 1223 (1221 at the previous run), the same
minor, so no re-check trigger fires beyond the three re-ruled at the previous run.

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
3. In-client smoke is the owner's and none is marked passed here. The fix was exercised headless
   under a mocked ruRU locale, not on a ruRU client.
4. The previous run's actions 3 and 4 stand unchanged.
