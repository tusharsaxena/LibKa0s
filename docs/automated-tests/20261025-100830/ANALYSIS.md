# Analysis — 20261025-100830

- **Addon:** LibKa0s 1.77.0 (release run, `--release 1.78.0`; `addonVersion` reads 1.77.0, the
  newest tag, because a library repo has no TOC and the runner falls back to `git describe`; the
  local `v1.78.0` tag is cut on the commit that adds this bundle)
- **Verdict:** green
- **Commit:** dc52324 (`feat/2026-10-25-skinning`), clean
- **Previous run:** 20261024-162023 (1.77.0, release run, at `7790dca`), the final close of v1.77.0.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.78.0 was verified across **three** suites, not four. No function needed a
split for the CCN 15 ceiling.

## Why this run exists

v1.78.0 is leg 1 of the skinning run (Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`): the new
major `LibKa0s-Skin-1.0` (the engine, the nine skins, the paint primitives, the EllesmereUI provider
and the AceGUI rows), the skin owner threaded through Core, Widgets, DebugLog, Options, Perf and Sim,
the Appearance tab, Media minor 6's skin faces and Glass art, and test kit revision 43's paint
recorder. It is now eighteen majors across fifty-one files. The first close commit (`dc52324`,
`LK-90`) dated the block and moved the pointers; this run measures it.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261024-162023 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | Yes: 197 → 223 files, 0/0 at both |
| tests | pass | 3001 passed, 2 skipped, 0 failed, 3003 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 2755 → 3003 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +9367 NLOC, +1203 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 65297 |
| Functions | 9775 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 56.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 8 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost, and the skin engine's repaint cost in particular is unmeasured here. **`tests` carries two
skips**, the same two as at the previous run: the kit's own `tests/_kit/test_prose.lua`, declined
under `CLAUDE.md`'s `localization-§5` deviation row, and the diagnostics contract's opt-out case, a
declared skip in a repo that keeps the default.

## What moved

Against the final v1.77.0 close, [`20261024-162023`](../20261024-162023/):

- **lint** reads 26 more files (197 → 223), still 0/0 ([`lint.txt`](lint.txt)): ten payload files
  (`Skin.lua`, `SkinDefs.lua`, `SkinPaint.lua`, `SkinPaintExtras.lua`, `SkinPaintControls.lua`,
  `SkinEUI.lua`, `SkinAce.lua`, `WidgetsCopyWindow.lua`, `DebugLogWindow.lua`,
  `OptionsAppearance.lua`), `testkit/mock_paint.lua`, three fixtures and twelve new suites.
- **tests** grow by 248 cases (2755 → 3003; 2753 → 3001 passed), mostly in the twelve new suites
  (`test_mock_paint`, `test_skin`, `test_skin_defs`, `test_skin_paint`, `test_skin_paint_controls`,
  `test_skin_eui`, `test_skin_ace`, `test_widgets_skin`, `test_options_skin`,
  `test_options_compose_skin`, `test_options_appearance`, `test_tool_windows_skin`). The per-suite
  list is in [`test-cases.md`](test-cases.md). None fails, and the skipped count stays at 2.
- **complexity** grows by 9367 NLOC (55930 → 65297) and 1203 functions (8572 → 9775), the new
  major and its suites above. The averages rise slightly (avg CCN 1.9 → 2.0, avg NLOC 6.5 → 6.6,
  avg tokens 53.8 → 56.0): the paint primitives and the token tables are denser than the suite code
  that dominates the totals. Max CCN is 15 and no function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | 1332, 1378, 1268, 1380, 1447 | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`), carried verbatim in `RESULTS.md`. Each grew with its skin-owner minor and none reached its trigger: `Options.lua` added no member (the attach-row exception), `OptionsTabs.lua` is 20 lines under its 1400, `OptionsWidgets.lua` three lines under its 1450 with no maker added. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1465 | Carried forward in `RESULTS.md`; 1464 → 1465 with kit revision 43's one comment line (the recorder itself is `testkit/mock_paint.lua`, following the rule), 25 lines from the 1490 re-check trigger. |
| 1000–1500 (on notice) | `tests/test_sim_panel.lua` | 1056 | Carried forward in `RESULTS.md`; unchanged in length (SimPanel minor 7 moved only its two minor pins to "at least"). |
| 1000–1500 (on notice) | `tests/test_options_compose.lua` | 1012 | Carried forward in `RESULTS.md` and `CLAUDE.md`; unchanged (OptionsCompose minor 12's cases are in `tests/test_options_compose_skin.lua`). |
| left the band | `LibKa0s/DebugLog.lua` | 663 | 1008 → 663: the console window peeled to `LibKa0s/DebugLogWindow.lua` (575) on its named seam. |
| under the band | `LibKa0s/Perf.lua`, `LibKa0s/SimPanel.lua`, `LibKa0s/Widgets.lua`, `LibKa0s/SkinPaint.lua` | 997, 997, 758, 840 | `Perf.lua` unchanged; `SimPanel.lua` 956 → 997 with minor 7, three under 1000; `Widgets.lua` 758 after the `WidgetsCopyWindow.lua` peel; `SkinPaint.lua` the largest new file. |

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-10-25, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** `tests/fixture_sim_panel.lua`, `tests/test_sim_panel.lua` (the two minor
  pins only), `tests/test_sim_panel_render.lua`, `tests/test_widgets_teststrip.lua` (unchanged),
  `tests/test_tool_windows_skin.lua` and `tests/test_widgets_skin.lua` (the owner paths),
  `docs/api/Sim/version-2.3.7-docs.md` and `docs/api/Widgets/version-16.2.6.4.4.1-docs.md`
- **Commits since the previous release touching them:** 2 (`556946d`, Widgets minor 16;
  `7a782f0`, SimPanel minor 7)
- **Note:** both changes paint through a registered skin owner only; an unowned sim panel and test
  strip draw as at v1.77.0, and the strip's amber and cyan stay the library's meaning colors. No
  scenario, step or test-mode data changes. Hosts affected for step 8 (Sim and `TestStrip`):
  BankLedger, DropWatcher, LootHistory, MultiMeters and KickCD; only LootHistory re-vendors and
  registers an owner in this leg.

## Actions

1. Cut the local annotated tag `v1.78.0` on the commit that adds this bundle. The tag is not
   pushed: the branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 of `docs/releasing.md` is deferred by the lead's call: only LootHistory re-vendors from
   the tag in this run (`LH-RV`); every other consumer stays on v1.77.0 until leg 2.
3. No band file reached its trigger. `LibKa0s/Perf.lua` and `LibKa0s/SimPanel.lua` sit at 997:
   the next change that takes either past 1000 names a peel seam in the same change (`layout-§1`).
