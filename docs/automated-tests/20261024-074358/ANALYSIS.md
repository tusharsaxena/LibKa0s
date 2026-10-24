# Analysis — 20261024-074358

- **Addon:** LibKa0s 1.77.0 (release run, `--release 1.77.0`; `addonVersion` reads 1.76.0, the
  newest tag, because a library has no `.toc` and v1.77.0 is tagged only after this bundle is
  committed)
- **Verdict:** green
- **Commit:** 3c2bb20 (`feat/2026-10-24-keybinds-layout-strata`), clean
- **Previous run:** 20261024-073953 (1.77.0, release run, at `ea2cb09`), the first v1.77.0 release
  run, whose complexity suite warned on three functions; v1.76.0's release record is
  20261023-150627 (at `f9ce82a`).

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.77.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.77.0 was verified across **three** suites, not four. This is the run the
local `v1.77.0` tag is cut from; the run before it could not be, because three functions sat above
CCN 15, and the commit this run measured split them.

## Why this run exists

v1.77.0 is the library's share of the 2026-10-24 run (keybindings, settings layout, frame strata;
Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`). Minors move in twelve files:
Core 12 (`RaiseStaticPopups`); DebugLog 21, PerfPanel 9 and SimPanel 6 (toplevel tool windows that
re-raise a shown StaticPopup); Widgets 15 and WidgetsAutocomplete 3 (both popups clamped to the
screen) and WidgetsDragHandle 5 (`spec.level`, `spec.ignoreParentAlpha`, `ApplyLevel`); Options 30,
OptionsIds 3, OptionsCombat 2, OptionsCompose 8 (`StrataTooltip`) and the new twelfth Options file,
OptionsKeybinds 3 (the Keybindings tab). The payload is seventeen majors across forty-one files, and
the test kit moves to revision 42 (`mock_bindings.lua`, `mock_layers.lua`, `bindings_xml.lua`).

## Suites

| Suite | Status | Result | Artifact | Moved since 20261024-073953 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 194 files | [`lint.txt`](lint.txt) | No: 194 files, 0/0 at both |
| tests | pass | 2713 passed, 2 skipped, 0 failed, 2715 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No: 2715 at both |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: max CCN 18 → 15, warnings 3 → 0; +26 NLOC, +6 functions |

| Metric | Value |
|---|---|
| Total NLOC | 55325 |
| Functions | 8480 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 1.9 |
| Max CCN | 15 |
| Avg tokens / function | 53.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost, including the Keybindings tab's `UPDATE_BINDINGS` repaint or the tool windows' popup re-raise
on show. **`tests` carries two skips**, the same two as at v1.76.0's release run: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against the first v1.77.0 run, [`20261024-073953`](../20261024-073953/): lint and tests did not
move (194 files at 0/0; 2715 cases, 2713 passed, 0 failed, 2 skipped). Complexity grew by 26 NLOC
(55299 → 55325) and 6 functions (8474 → 8480), avg tokens 53.8 → 53.7, and the three warned
functions are gone: `lib.New` in `LibKa0s/Options.lua` (16), and `check` (18) and
`Kit.keybindThroughTab` (18) in `testkit/bindings_xml.lua`, each split into file-local halves with
no behavior change (`3c2bb20`). Max CCN is 15.

Against v1.76.0's release record, [`20261023-150627`](../20261023-150627/):

- **lint** reads 13 more files (181 → 194), still 0/0 ([`lint.txt`](lint.txt)): the new payload
  file `LibKa0s/OptionsKeybinds.lua`, the three new kit files under `testkit/` (`tests/_kit/` is
  excluded), and the new suites and bench.
- **tests** grow by 140 cases (2575 → 2715; 2573 → 2713 passed): new suites
  `test_options_keybinds` (26), `test_options_keybinds_model` (26), `test_mock_bindings` (17),
  `test_kit_bindings` (15), `test_options_keybinds_sync` (14), `test_widgets_draghandle_layers`
  (10), `test_tool_windows_layering` (8) and `test_mock_layers` (7); more in `test_options_compose`
  (45 → 51), `test_options_idsuggest_frames` (11 → 15), `test_sim_panel_render` (31 → 34),
  `test_perf_panel` (45 → 46), `test_sim_panel` (58 → 59), `test_widgets` (57 → 58) and
  `test_widgets_autocomplete` (36 → 37). The `test_sim_panel*` and `test_perf_panel` additions are
  v1.76.0's own step-label cases (`7e81ff7`, LK-91 of the 2026-10-23 run), which landed after that
  release's bundle. The per-suite list is in [`test-cases.md`](test-cases.md). None fails, and the
  skipped count stays at 2.
- **complexity** grows by 3178 NLOC (52147 → 55325) and 499 functions (7981 → 8480). The averages
  hold (avg CCN 1.9, avg NLOC 6.5; avg tokens 53.8 → 53.7). Max CCN is 15 at both releases and no
  function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | 1320, 1375, 1251, 1350, 1444 | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`), carried verbatim in `RESULTS.md`. `Options.lua` (1316 → 1320, the attach split) and `OptionsIds.lua` (1359 → 1375, minor 3) moved, each with no member added and under its trigger; none is at its re-check trigger. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1464 | Carried forward in `RESULTS.md`; unchanged by kit revision 42, 26 lines from the 1490 re-check trigger. |
| 1000–1500 (on notice) | `tests/test_sim_panel.lua` | 1056 | Carried forward in `RESULTS.md`; SimPanel minor 6 added no case here (its cases are `tests/test_tool_windows_layering.lua`'s), so its trigger has not fired. |
| 1000–1500 (on notice), new | `LibKa0s/DebugLog.lua` | 1008 | New in the band: 999 → 1008 with DebugLog minor 21's toplevel console and its guarded re-raise (`LK-01`). Accepted in `RESULTS.md` and `CLAUDE.md`: the seam is the console window, to `LibKa0s/DebugLogWindow.lua`; re-check 1100 lines. |
| 1000–1500 (on notice), new | `tests/test_options_compose.lua` | 1012 | New in the band: 944 → 1012 with OptionsCompose minor 8's six `O.StrataTooltip` cases (`LK-20`). Accepted in `RESULTS.md` and `CLAUDE.md`: the seam is the record-backed arm, to `tests/test_options_compose_arm.lua`; re-check 1200 lines or the next OptionsCompose minor that adds cases here. |
| under the band | `LibKa0s/Perf.lua`, `LibKa0s/SimPanel.lua` | 997, 956 | `Perf.lua` unchanged, three lines under the band; `SimPanel.lua` 949 → 956 with minor 6. |

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-10-24, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** `tests/fixture_sim_panel.lua`, `tests/test_sim_panel.lua`,
  `tests/test_sim_panel_render.lua` and `docs/api/Sim/version-2.3.6-docs.md`; and, because
  `Widgets.lua` (the file that defines `W.TestStrip`) also moved, its diff against v1.76.0 and
  `tests/test_widgets_teststrip.lua`
- **Commits since the previous release touching them:** 1 (`665bf63` LK-01, the two SimPanel minor
  pins in `tests/test_sim_panel.lua`)
- **Note:** SimPanel minor 6 adds `SetToplevel(true)` and the guarded StaticPopup re-raise on show
  to the panel's chrome and nothing else; no scenario, step, verb or control changes, and the
  fixture needed no change. Widgets minor 15 clamps the shared dropdown menu to the screen and does
  not touch `W.TestStrip` or its flavors, so no test-mode strip changes. Hosts affected for step 8:
  none beyond the re-vendor report's note that the sim panel (like the debug console and the perf
  panel) is now toplevel.

## Actions

1. Tag the commit that adds this bundle `v1.77.0`, locally and annotated. The tag is not pushed:
   the branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 of `docs/releasing.md`: the roster consumers re-vendor from the local tag on their own
   `feat/2026-10-24-keybinds-layout-strata` branches (the run's `<PFX>-RV` items), each adding the
   four new Options stub members (`KeybindingsTab`, `KeybindRows`, `KEYBINDS_UNCHANGED`,
   `StrataTooltip`) and each report naming the toplevel tool windows.
3. `LibKa0s/DebugLog.lua` (1008) and `tests/test_options_compose.lua` (1012) entered the band here;
   their seams and triggers are ruled in `RESULTS.md` and `CLAUDE.md`. `LibKa0s/Perf.lua` still sits
   at 997: the next change that takes it past 1000 names a peel seam in the same change
   (`layout-§1`).
