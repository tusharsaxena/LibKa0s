# Analysis — 20261024-162023

- **Addon:** LibKa0s 1.77.0 (release run, `--release 1.77.0`; `addonVersion` reads 1.77.0, the
  newest tag, because the local `v1.77.0` tag already exists, cut on `78240f7` and moved to
  `afae2f7` by LK-95; that tag is moved again to the commit that adds this bundle)
- **Verdict:** green
- **Commit:** 7790dca (`feat/2026-10-24-keybinds-layout-strata`), clean
- **Previous run:** 20261024-121210 (1.77.0, release run, at `74d0bd3`), the second close of
  v1.77.0, which this run supersedes; before it, 20261024-074358 (at `3c2bb20`), the first close.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.77.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.77.0 was verified across **three** suites, not four. This is the run the
local `v1.77.0` tag is moved to; no function needed a split for the CCN 15 ceiling.

## Why this run exists

v1.77.0 was re-closed and its local tag moved to `afae2f7` (LK-95), then extended again before
any push with the owner's follow-up to item 015 of the 2026-10-24 run (Ka0sAddonsCommonTasks
`docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`, addendum-02): one key button and Clear per row on the
settings-panel Keybindings tab, OptionsKeybinds minor 4 (`LK-40`, `f627436` and its review fix
`7790dca`), with `Kit.keybindThroughTab` driving slot 2 through the model inside the still
unreleased test kit revision 42. The Options key moves to **30.2.34.3.5.9.2.11.4.2.1.4**; no
other file's minor moves, no kit revision moves, and the payload is still seventeen majors across
forty-one files. This run measures `7790dca`.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261024-121210 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 197 files | [`lint.txt`](lint.txt) | No: 197 files, 0/0 at both |
| tests | pass | 2753 passed, 2 skipped, 0 failed, 2755 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 2749 → 2755 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +152 NLOC, +23 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 55930 |
| Functions | 8572 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 1.9 |
| Max CCN | 15 |
| Avg tokens / function | 53.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same two as at both earlier closes: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against the second close, [`20261024-121210`](../20261024-121210/):

- **lint** reads the same 197 files, still 0/0 ([`lint.txt`](lint.txt)). No file was added.
- **tests** grow by 6 cases (2749 → 2755; 2747 → 2753 passed), in two existing suites:
  `test_options_keybinds` (26 → 30) and `test_kit_bindings` (15 → 17), both `LK-40`. No other
  suite changed its count. The per-suite list is in [`test-cases.md`](test-cases.md). None fails,
  and the skipped count stays at 2.
- **complexity** grows by 152 NLOC (55778 → 55930) and 23 functions (8549 → 8572): the two suites
  above, `testkit/bindings_xml.lua` and its vendored copy, and `LibKa0s/OptionsKeybinds.lua`
  (819 → 857). The averages hold (avg CCN 1.9, avg NLOC 6.5, avg tokens 53.8). Max CCN is 15 and
  no function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | 1320, 1375, 1251, 1350, 1444 | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`), carried verbatim in `RESULTS.md`. None moved: the extension touched only `OptionsKeybinds.lua` among the payload files (`git diff 74d0bd3..7790dca --stat -- LibKa0s/` lists that file alone). |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1464 | Carried forward in `RESULTS.md`; unchanged, 26 lines from the 1490 re-check trigger. |
| 1000–1500 (on notice) | `tests/test_sim_panel.lua` | 1056 | Carried forward in `RESULTS.md`; unchanged. |
| 1000–1500 (on notice) | `LibKa0s/DebugLog.lua` | 1008 | Carried forward in `RESULTS.md` and `CLAUDE.md`; unchanged. |
| 1000–1500 (on notice) | `tests/test_options_compose.lua` | 1012 | Carried forward in `RESULTS.md` and `CLAUDE.md`; unchanged. |
| under the band | `LibKa0s/OptionsKeybinds.lua`, `LibKa0s/OptionsCompose.lua`, `LibKa0s/Perf.lua`, `LibKa0s/SimPanel.lua` | 857, 758, 997, 956 | `OptionsKeybinds.lua` 819 → 857 with minor 4; the other three unchanged. |

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-10-24, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** the extension's diff (`git diff 74d0bd3..7790dca --stat`), which touches no
  `Sim*.lua`, `Widgets.lua`, `tests/fixture_sim_panel.lua`, `tests/test_sim_panel*.lua` or
  `docs/api/Sim/` file
- **Commits since the previous release run touching them:** 0
- **Note:** the keybindings follow-up touches no simulator or preview surface; it redraws the
  Keybindings tab's rows only.

## Actions

1. Move the local annotated tag `v1.77.0` from `afae2f7` to the commit that adds this bundle. The
   tag is not pushed: the branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 of `docs/releasing.md`: the roster consumers re-vendor again from the moved tag (the
   run's `<PFX>-RV3` items), replacing `libs/LibKa0s` and `tests/_kit` whole.
3. No band file reached its trigger. `LibKa0s/Perf.lua` still sits at 997: the next change that
   takes it past 1000 names a peel seam in the same change (`layout-§1`).
