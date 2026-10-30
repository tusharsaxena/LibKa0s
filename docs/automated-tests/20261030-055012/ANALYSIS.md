# Analysis — 20261030-055012

- **Addon:** LibKa0s 1.80.0 (release run, `--release 1.81.0`; `addonVersion` reads 1.80.0, the
  newest tag, because a library repo has no TOC and the runner falls back to `git describe`; the
  local `v1.81.0` tag is cut on the commit that adds this bundle)
- **Verdict:** green
- **Commit:** a7e04c1 (`feat/2026-10-30-skin-library-followups`), clean
- **Previous run:** 20261030-054311 (release run, `--release 1.81.0`, at `aa6365f`), the first
  v1.81.0 release run, which failed the tag's complexity precondition. Before it, 20261029-032426
  (`--release 1.80.0`, at `663b0fb`), the final measurement of v1.80.0, is the baseline for *What
  moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.81.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.81.0 was verified across **three** suites, not four.

This is the second release run of the close. The first,
[`20261030-054311`](../20261030-054311/), measured `aa6365f` with the same lint and test figures but
complexity 2 warnings, max CCN 17 (`lib.ReorderList` 17, `lib.TestStrip` 16), so the tag could not
be cut from it. `a7e04c1` split both, with no change in behavior, and this run measured it.

## Why this run exists

v1.81.0 is the skinning rollout's library follow-ups (M1 of Ka0sAddonsCommonTasks
`docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS/`, closed by `LK-90`), meeting the owner's rulings R-1 to
R-11: *Ignore fonts* reaches the HUD (`LK-01`), `opts.stockDefault` is retired (`LK-02`), a close
button gets its own tint back (`LK-03`), every skin has a HUD face of its own (`LK-04`), `S.Text`,
the reorder list and every other custom widget obey the Scope switches (`LK-05`, `LK-06a` to
`LK-06d`), `ResetToSkin` sets an absent companion (`LK-07`), the drag handle's tooltip takes the
skin's colors (`LK-08`), the quality colors are the client's exactly (`LK-09`), `Skin:DrawsKey` is
public (`LK-10`) and the picker reads "Choose a skin" (`LK-11`), plus `LK-A1` (no font height of 0
reaches `SetFont`). Twenty-four files moved their minors across seven majors (Skin
8.16.12.6.10.2.4, Widgets 17.3.7.5.5.2, Options 34.4.36.5.7.11.3.13.9.4.3.6.3.2, Sim 2.3.8, Core 14,
DebugLog 22.5.1.2, Perf 15.1.1.11). Still nineteen majors across fifty-three files, test kit
revision 44.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261029-032426 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 237 files | [`lint.txt`](lint.txt) | Yes: 233 → 237 files, 0/0 at both |
| tests | pass | 3297 passed, 2 skipped, 0 failed, 3299 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3222 → 3299 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +1901 NLOC, +263 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 73030 |
| Functions | 10721 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 58.1 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 12 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost; the extra `P.font` paints on menus, strips and tool windows, the hover-time tooltip palette
reads and the panel-scope checks on every repaint in particular are unmeasured here. **`tests`
carries two skips**, the same two as at the previous runs: the kit's own `tests/_kit/test_prose.lua`,
declined under `CLAUDE.md`'s `localization-§5` deviation row, and the diagnostics contract's opt-out
case, a declared skip in a repo that keeps the default.

## What moved

Against the final v1.80.0 measurement, [`20261029-032426`](../20261029-032426/):

- **lint** reads four more files (233 → 237), still 0/0 ([`lint.txt`](lint.txt)): four new suites,
  `tests/test_options_chrome_skin.lua`, `tests/test_options_tooltip_skin.lua`,
  `tests/test_tool_windows_scope.lua` and `tests/test_widgets_skin_scope.lua`. No payload file is new.
- **tests** grow by 77 cases (3222 → 3299; 3220 → 3297 passed): 15 in the new
  `test_options_chrome_skin`, 13 in `test_widgets_skin_scope`, 10 in `test_tool_windows_scope`, 6 in
  `test_options_tooltip_skin`; and 6 more in `test_skin`, 5 each in `test_skin_override`,
  `test_skin_paint` and `test_widgets_skin`, 3 each in `test_skin_paint_controls`,
  `test_tool_windows_skin` and `test_options_skin_picker`, 2 in `test_skin_defs` and 1 in
  `test_options_compose_skin`. `test_skin_stock_default` was rewritten to pin the retirement and
  keeps 9. The per-suite list is in [`test-cases.md`](test-cases.md). None fails, and the skipped
  count stays at 2.
- **complexity** grows by 1901 NLOC (71129 → 73030) and 263 functions (10458 → 10721). Avg CCN and
  avg NLOC hold at 2.1 and 6.7; avg tokens rise 57.7 → 58.1. Max CCN is 15 and no function is
  warned on, after `a7e04c1` moved `lib.ReorderList`'s colors into `listColors` (CCN 14) and
  `lib.TestStrip`'s icon and line into `stripLine`.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None. (At [`20261030-054311`](../20261030-054311/): `lib.ReorderList` 17 and `lib.TestStrip` 16,
both fixed before the tag, with their dispositions in the `RESULTS.md` that commit `a7e04c1` carries.)

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/SkinDefs.lua` | 1005 | **New to the band**, 959 → 1005 with SkinDefs minor 16's tokens. Accepted in `CLAUDE.md` and `RESULTS.md`: seam the eight other skins, to a secondary file paired on the Skin shell; re-check at 1100 lines, or a release that adds more than 40 lines here. |
| 1000–1500 (on notice) | `LibKa0s/SimPanel.lua` | 1018 | **New to the band**, 997 → 1018 with SimPanel minor 8. Accepted: seam the renderer section, to a file of its own, when the next SimPanel minor grows it. |
| 1000–1500 (on notice) | `tests/test_options_skin_picker.lua` | 1064 | **New to the band**, 966 → 1064 with OptionsSkinPicker minor 2's cases. Accepted: seam the *one window across addons* section; re-check at 1200 lines, or the next OptionsSkinPicker minor that adds cases here. |
| 1000–1500 (on notice) | `LibKa0s/Skin.lua` | 1081 | Grew 1044 → 1081 outside the owner-token block its trigger watches; 69 lines under the 1150 re-check. |
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | 1335, 1412, 1290, 1382, 1447 | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`). `OptionsIds.lua` (+34) and `OptionsIdList.lua` (+22) grew, under their 1450 and 1350 triggers; `OptionsTabs.lua` +2 (18 under 1400), `OptionsWidgets.lua` unchanged (3 under 1450), `Options.lua` untouched. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1465 | Carried forward; unchanged (kit revision 44 unchanged), 25 lines from the 1490 re-check trigger. |
| 1000–1500 (on notice) | `tests/test_sim_panel.lua`, `tests/test_options_compose.lua` | 1056, 1012 | Carried forward; unchanged (the new SimPanel and OptionsCompose cases went to other suites). |
| under the band | `LibKa0s/Perf.lua`, `LibKa0s/SkinPaint.lua` | 997, 979 | `Perf.lua` unchanged; `SkinPaint.lua` shrank 994 → 979 with the stock look's retirement. |

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-10-30, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** `tests/fixture_sim_panel.lua`, every `tests/test_sim_*.lua`,
  `tests/test_widgets_teststrip.lua`, and the new `docs/api/Sim/version-2.3.8-docs.md` and
  `docs/api/Widgets/version-17.3.7.5.5.2-docs.md`
- **Commits since the previous release touching them:** `Widgets.lua` minor 17 (`aebb719` LK-06a,
  `a7e04c1` the CCN split) and `SimPanel.lua` minor 8 (`ce3f8c3` LK-06d, `dca3d25` LK-06b); `Sim.lua`
  and `SimTimeline.lua` untouched
- **Note:** the reviewed fixtures and suites are untouched by the release and green: they pin the
  scenarios, steps, controls and an owner-less strip, none of which moved. What moved is look only
  (owned panels' labels, dropdowns, tooltip colors and grip; owned strips' line and `panel` flag),
  pinned in `tests/test_tool_windows_scope.lua`, `tests/test_tool_windows_skin.lua` and
  `tests/test_widgets_skin_scope.lua`. Hosts named for step 8's re-look of their smoke checks:
  sim panels in BankLedger, Drop Watcher and LootHistory; strips in BankLedger, DpsRace, Drop
  Watcher, KickCD, LootHistory, MultiMeters and Ka0s Skin Tester; Quick Comms' preview window, which
  mirrors the sim panel's step buttons. No host's scenario or test-mode data changes.

## Actions

1. The local annotated tag `v1.81.0` is cut on the commit that adds this bundle. It is not pushed:
   the branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 of `docs/releasing.md` is the follow-ups' M2: the fifteen addons that vendor the Skin
   major, LootHistory included, re-vendor the tag in their `<PFX>-RV` items and drop the workarounds
   it makes unnecessary; Ka0s Skin Tester carries the showroom samples (`ST-01`).
3. Standard v2.92.0 (`WS-01`), which this release is built to, is on WowAddonStandards'
   `feat/2026-10-30-skin-library-followups`; it merges with this release.
4. `LibKa0s/Perf.lua` (997) sits just under 1000, and `LibKa0s/OptionsWidgets.lua` 3 lines under
   its 1450 trigger: the next change that takes either past names its peel in the same change.
5. In-client smoke for the release's look changes (the Oxanium strings of D-13, the HUD faces, the
   picker's owner line) is the owner's, in the run's `06_SMOKE_TESTS.md`; none is marked passed here.
