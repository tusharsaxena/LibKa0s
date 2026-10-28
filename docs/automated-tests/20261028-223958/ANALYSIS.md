# Analysis — 20261028-223958

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.79.0`; `addonVersion` reads 1.78.0, the
  newest tag, because a library repo has no TOC and the runner falls back to `git describe`; the
  local `v1.79.0` tag is cut on the commit that adds this bundle)
- **Verdict:** green
- **Commit:** 3c9225f (`feat/2026-10-28-skin-overrides-picker`), clean
- **Previous run:** 20261028-120744 (release run, `--release 1.78.0`, at `2224a8c`), the final
  measurement of v1.78.0.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.79.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.79.0 was verified across **three** suites, not four.

This is the second release run of the close. The first, on the close commit `d66fc1f`, read
complexity `fail` (verdict amber): `O.SkinPicker` and the case helper `assertNamedMedia` at CCN 16,
and lizard blind in `tests/test_toast.lua` (109 of 110 functions, a function literal in a `for`
header). `3c9225f` split the two functions and hoisted the literal, with no change in behavior or
assertions, and that run's bundle was not kept. This run measures the fixed tree.

## Why this run exists

v1.79.0 closes two lines of work on one branch (`SO-05` of Ka0sAddonsCommonTasks
`docs/2026-10-28-SKIN_OVERRIDES_AND_PICKER/`): the new major `LibKa0s-Toast-1.0` and DebugLogDiagnostics
minor 5 (LibKa0s#60, merged to `master` after v1.78.0's tag), and the skin work: an owner's font and
texture overrides (Skin minor 6, LibKa0s#63), `S.BarTexture` (SkinPaintExtras minor 4), the Skin tab's
*Font and texture* section (OptionsAppearance minor 3), the first-run skin picker (Options minor 34,
OptionsSkinPicker minor 1, OptionsRegistry minor 4, LibKa0s#64), Ka0s Default's Oxanium face and a
generated bar texture for every skin but WoW Default (Media minor 9, SkinDefs minor 14), and test kit
revision 44. Now nineteen majors across fifty-three files. The close commit `d66fc1f` dated the block
and moved the pointers.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261028-120744 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 228 files | [`lint.txt`](lint.txt) | Yes: 223 → 228 files, 0/0 at both |
| tests | pass | 3156 passed, 2 skipped, 0 failed, 3158 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3033 → 3158 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +3411 NLOC, +435 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 69595 |
| Functions | 10291 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 57.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 8 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost; the overrides' repaint and the picker's preview in particular are unmeasured here. **`tests`
carries two skips**, the same two as at the previous run: the kit's own `tests/_kit/test_prose.lua`,
declined under `CLAUDE.md`'s `localization-§5` deviation row, and the diagnostics contract's opt-out
case, a declared skip in a repo that keeps the default.

## What moved

Against the final v1.78.0 measurement, [`20261028-120744`](../20261028-120744/):

- **lint** reads five more files (223 → 228), still 0/0 ([`lint.txt`](lint.txt)): two payload files
  (`LibKa0s/Toast.lua`, `LibKa0s/OptionsSkinPicker.lua`) and three new suites
  (`tests/test_toast.lua`, `tests/test_skin_override.lua`, `tests/test_options_skin_picker.lua`).
- **tests** grow by 125 cases (3033 → 3158; 3031 → 3156 passed), mostly in those three suites, with
  more in `test_media`, `test_skin_defs`, `test_options_appearance`, `test_options_render` and
  `test_mock_paint`. The per-suite list is in [`test-cases.md`](test-cases.md). None fails, and the
  skipped count stays at 2.
- **complexity** grows by 3411 NLOC (66184 → 69595) and 435 functions (9856 → 10291). The averages
  rise slightly (avg CCN 2.0 → 2.1, avg NLOC 6.6 → 6.7, avg tokens 56.4 → 57.0): the picker's window
  and queue carry more branching per function than the suite code that dominates the totals. Max CCN
  is 15 and no function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None. (The first run's two, `O.SkinPicker` and `assertNamedMedia`, were split in `3c9225f`, to
CCN 10 with `pickerTarget` at 8, and to 10 with `assertNamedFile` at 7.)

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | 1335, 1378, 1268, 1380, 1447 | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`), carried verbatim in `RESULTS.md`. Only `Options.lua` moved, 1332 → 1335 with minor 34's one guarded attach line and its two header lines; it added no member, and is under its 1400 trigger. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1465 | Carried forward in `RESULTS.md`; unchanged (kit revision 44 changed `testkit/mock_paint.lua` only), 25 lines from the 1490 re-check trigger. |
| 1000–1500 (on notice) | `tests/test_sim_panel.lua` | 1056 | Carried forward in `RESULTS.md`; unchanged. |
| 1000–1500 (on notice) | `tests/test_options_compose.lua` | 1012 | Carried forward in `RESULTS.md` and `CLAUDE.md`; unchanged. |
| under the band | `LibKa0s/Perf.lua`, `LibKa0s/SimPanel.lua`, `LibKa0s/OptionsSkinPicker.lua`, `tests/test_options_skin_picker.lua` | 997, 997, 765, 966 | `Perf.lua` and `SimPanel.lua` unchanged; the picker and its suite are the largest new files. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-10-28, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** none needed: `git diff --stat v1.78.0 -- LibKa0s/Sim.lua LibKa0s/SimTimeline.lua
  LibKa0s/SimPanel.lua LibKa0s/Widgets.lua` prints nothing
- **Commits since the previous release touching them:** 0
- **Note:** the release moved none of step 5's minors, so no host's scenarios or test-mode strips
  change and step 8 names no host for a re-look.

## Actions

1. Cut the local annotated tag `v1.79.0` on the commit that adds this bundle. The tag is not
   pushed: the branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 of `docs/releasing.md` is LootHistory and Ka0s Skin Tester (`LH-02`, `ST-02`), from the
   tag; every other consumer re-vendors at the collection-wide skinning adoption pass.
3. The two pending standard changes (library-stack-§7's `Toast` row and the recount to fifty-three
   files; frame-layering-§6's toast and skin-picker rows) land upstream before the tag is pushed.
4. Standard v2.90.0's *Resizing* subsection names the library's own windows; `Core.MakeResizable`
   does not yet coalesce its per-tick layout to one pass per frame. Open for a later release.
5. No band file reached its trigger. `LibKa0s/Perf.lua` and `LibKa0s/SimPanel.lua` sit at 997:
   the next change that takes either past 1000 names a peel seam in the same change (`layout-§1`).
