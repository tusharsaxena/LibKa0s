# Analysis — 20261103-200402

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's sixteenth local re-cut, `R5-REL`
  after `R5-L1` to `R5-L5`; the manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** `875c89c` (`feat/2026-11-01-full-skinning`), clean, the CCN split: nothing but this record follows it
- **Previous run:** [`20261103-195859`](../20261103-195859/) (at `0af3b93`), the same re-cut's first battery,
  which found two functions over CCN 15. The baseline for *What moved* below is the fifteenth re-cut,
  [`20261103-160531`](../20261103-160531/) (at `ef88399`).

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261103-160531 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 296 files | [`lint.txt`](lint.txt) | Yes: 292 -> 296 files (four new suites) |
| tests | pass | 4030 passed, 3 skipped, 0 failed, 4033 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3989 -> 4033 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 89063 NLOC, 12871 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 87978 -> 89063 NLOC, 12707 -> 12871 functions; max CCN 15 at both |

The three skips are the previous runs': the declined kit prose gate, the diagnostics opt-out case and
`test_skin_values`, which is still a declared skip, not a pass.

## What moved

Against [`20261103-160531`](../20261103-160531/): the owner's fifth smoke round (Ka0sAddonsCommonTasks
`docs/2026-11-03-SMOKE_ROUND5/`, the lead's calls in its `00_PLAN.md`, the header shade C in `R5_SIGNOFF.md`).

- **`R5-L1`, SkinDefs minor 27**: Ka0s Default's title band is option C, `#262006` over `#141103`,
  `title.bg` `#1D1805`, and the picker's second swatch with it.
- **`R5-L2`, SkinPaint minor 18, Toast minor 3**: `S.Shell`'s top band draws above a backdrop window's
  fill (BACKGROUND 3), a bare `Shell` repeats the owner's opts, toasts opt out with `noTopBar`.
- **`R5-L3`, Skin minor 16, SkinPaintExtras 17, DebugLogWindow 4, WidgetsCopyWindow 5, PerfPanel 13,
  SimPanelRender 3, OptionsSkinPicker 10**: `S.Band` and `S.Header`, every library window's header on
  the band's middle.
- **`R5-L4`, OptionsSkinPicker minor 10 (unvendored, no bump)**: the skin list closes on an outside press.
- **`R5-L5`, OptionsIdList 9, OptionsIdSuggest 2, Widgets 22, WidgetsAutocomplete 7**: the icon rule,
  `W.IconText`, and `docs/api/README.md`'s *Icon art: the rule*.
- **`R5-REL`**: `S.Header` and `S.Shell`, measured at CCN 17 and 18 by the first battery, split under
  the cap with no behavior change (`layBars`, `headerTitle`; `shellBody`, no SkinPaint function added).
- Keys: Skin 16.1.27.8.18.17.17.4.9, Options 37.4.44.2.7.2.9.15.2.4.18.13.5.5.7.6.10.1.1.4, Widgets
  22.5.12.6.7.5, DebugLog 22.6.1.4, Perf 15.1.1.13, Sim 2.3.10.3, Toast 3; kit revision 50, no kit file moved.
- Tests: 44 cases more, 4033 total, in four new suites (`tests/test_shell_band.lua`,
  `tests/test_header_band.lua`, `tests/test_options_skin_picker_close.lua`, `tests/test_icon_rule.lua`)
  and the moved pins in `tests/test_skin_defs.lua`, `tests/test_toast.lua` and
  `tests/test_options_skin_picker.lua`.

## Complexity watch list

### Functions the complexity suite warned on

None. `Shell` is at 15 and `Header` at 6 after the split.

### Files by `layout-§1` band

Fourteen, the same fourteen, nothing over 1500, none came in or left. `LibKa0s/SkinPaintExtras.lua`
grew 1095 -> 1228 (`R5-L3`'s band and header, then the split's two helpers): **both halves of its
re-check trigger fired**, 1100 lines and the next minor. This re-cut carries it unpeeled; the peel is a
new shipped file and a change to every host's pinned load list, so `CLAUDE.md`'s census row leaves it to
the lead and the owner, and its Disposition cell in RESULTS.md now says so. `LibKa0s/SkinPaint.lua` is at
1045, 5 under its 1050 trigger, and its split added no function, so its trigger did not fire.
`LibKa0s/OptionsSkinPicker.lua` (1309 -> 1372) is under its 1400 trigger, `LibKa0s/OptionsIdList.lua`
(1304 -> 1339) under its 1350, `LibKa0s/Skin.lua` (1097 -> 1096) under its 1100. `LibKa0s/Widgets.lua`
(1037 -> 1058) is unruled, and its cell stays blank, as at the previous runs: that is stated here rather
than filled in.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-03, the lead's call under the owner's run guidelines; the owner was not asked
- **Files reviewed:** `Widgets.lua` moved to minor 22 (`d1ac6fd`) for `lib.IconText` alone, and
  `lib.TestStrip` did not move; `SimPanelRender.lua` moved to minor 3 (`43da5e8`) in the owned panel's
  header only; no `Sim.lua`, `SimTimeline.lua` or `SimPanel.lua` moved. Every `tests/test_sim_*.lua` and
  `tests/test_widgets_teststrip.lua` ran green. No scenario, step, control or strip changes, so step 5
  names no hosts.

## Actions

1. The local annotated tag `v1.85.0` is re-cut on the commit that adds this bundle. It was never
   pushed. The merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer (`R5-RV`). What hosts owe is the five round 5
   paragraphs of `docs/releasing.md`'s hosts-owe list, closed by the `R5-REL` line: in the re-vendor
   commit itself, the facade names `Band`, `Header` and `IconText` and MultiMeters' `title.bg` fallback
   `#1D1805`; then each host's `R5-WIN`, `R5-DD` and `R5-ICON` items.
3. The SkinPaintExtras peel, whose trigger fired on both halves, and the SkinPaintControls peel are the
   lead's and the owner's call.
4. In-client smoke is the owner's and none is marked passed here.
