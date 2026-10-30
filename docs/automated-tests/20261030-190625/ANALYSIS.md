# Analysis — 20261030-190625

- **Addon:** LibKa0s 1.81.0 (release run, `--release 1.82.0`; `addonVersion` reads 1.81.0, the
  newest tag, because a library repo has no TOC and the runner falls back to `git describe`; the
  local `v1.82.0` tag is cut on the commit that adds this bundle)
- **Verdict:** green
- **Commit:** c6a9fb7 (`feat/2026-10-30-skin-fonts-feedback`), clean
- **Previous run:** 20261030-055012 (`--release 1.81.0`, at `a7e04c1`), the final measurement of
  v1.81.0, is the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.82.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.82.0 was verified across **three** suites, not four.

This is the only release run of the close. A pre-release pass over the same sighted shadow, taken
before `c6a9fb7` and writing no bundle, found one function over the budget: `dhLendFont` in
`LibKa0s/WidgetsDragHandle.lua` at CCN 17. `c6a9fb7` moved its font-object comparison, unchanged,
into a file-local `dhObjectDraws`, and this run measured the result.

## Why this run exists

v1.82.0 is the owner's skin fonts and feedback batch (M1 of Ka0sAddonsCommonTasks
`docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/`, closed by `LK-90`): the payload ships Prototype, Fira
Sans Medium and Expressway and retires five faces (`LK-01`, `LK-A1`); Ka0s Default draws Prototype,
WoW Forever's body Fira Sans Medium and Obsidian Expressway (`LK-02`); text is outlined by default
with a per-owner *Font outline* (`LK-03`); every element's flags follow it from the skin (`LK-04`);
every skin's text, and HUD text through `S.HudFontSize`, is as wide as Ka0s Default's (`LK-05`,
`LK-06`); choosing another skin resets the overrides and the Skin tab gets Reset font, Reset texture
and one grid (`LK-07`, `LK-08`); a fitted drag handle re-fits after every repaint (`LK-09`);
`shownWhen` takes an OR, in the new `OptionsSwitch.lua` (`LK-10`); `O.SkinVerb` backs every addon's
`/xx skin` (`LK-11`); the kit guards display strings against glyphs a face cannot draw (`LK-12`,
kit revision 45); and an enabled button's label is opaque again (`LK-14`). Eleven files moved their
minors and one is new, across four majors (Media 10.1, Skin 9.17.13.7.11.2.4, Options
34.4.37.5.7.11.3.14.9.4.3.6.4.3.1, Widgets 17.3.8.5.5.2). Still nineteen majors, now across
fifty-four files.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261030-055012 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 246 files | [`lint.txt`](lint.txt) | Yes: 237 → 246 files, 0/0 at both |
| tests | pass | 3409 passed, 2 skipped, 0 failed, 3411 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3299 → 3411 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +2451 NLOC, +269 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 75481 |
| Functions | 10990 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 58.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 14 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost; the outline-mode read in `__Tokens` on every token resolution, the drag handle's re-fit after
every repaint and `S.HudFontSize`'s per-paint scale in particular are unmeasured here. **`tests`
carries two skips**, the same two as at the previous run: the kit's own `tests/_kit/test_prose.lua`,
declined under `CLAUDE.md`'s `localization-§5` deviation row, and the diagnostics contract's opt-out
case, a declared skip in a repo that keeps the default.

## What moved

Against the final v1.81.0 measurement, [`20261030-055012`](../20261030-055012/):

- **lint** reads nine more files (237 → 246), still 0/0 ([`lint.txt`](lint.txt)): one new payload
  file, `LibKa0s/OptionsSwitch.lua`; the kit's new `testkit/glyphs.lua` (its byte copy under
  `tests/_kit/` is excluded); and seven under `tests/`: `fixture_skin_picker.lua`,
  `test_glyph_guard.lua`, `test_options_compose_flags.lua`, `test_options_skin_verb.lua`,
  `test_skin_button_contrast.lua`, `test_skin_outline.lua` and `test_skin_width_parity.lua`.
- **tests** grow by 112 cases (3299 → 3411; 3297 → 3409 passed): 17 in the new `test_skin_outline`,
  12 in `test_glyph_guard`, 11 in `test_skin_width_parity`, 10 in `test_skin_button_contrast`, 7 in
  `test_options_skin_verb` and 5 in `test_options_compose_flags`; and 22 more in
  `test_options_appearance`, 8 in `test_options_skin_picker`, 7 each in `test_options_switched` and
  `test_widgets_skin_scope`, 3 in `test_widgets_draghandle`, and 1 each in `test_media`,
  `test_mock_paint` and `test_skin_override`. The per-suite list is in
  [`test-cases.md`](test-cases.md). None fails, and the skipped count stays at 2.
- **complexity** grows by 2451 NLOC (73030 → 75481) and 269 functions (10721 → 10990). Avg CCN
  holds at 2.1; avg NLOC rises 6.7 → 6.8 and avg tokens 58.1 → 58.8. Max CCN is 15 and no function
  is warned on, after `c6a9fb7` split `dhLendFont` (CCN 17 before the split).

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None. (The pre-release pass, which wrote no bundle: `dhLendFont` 17 in
`LibKa0s/WidgetsDragHandle.lua`, split in `c6a9fb7` before this run.)

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_options_appearance.lua` | 1231 | **New to the band**, 797 → 1231 with OptionsAppearance minor 4's cases. Accepted in `CLAUDE.md` and `RESULTS.md`: seam the three minor-4 sections to `tests/test_options_appearance_v4.lua`; re-check at 1300 lines, or the next OptionsAppearance minor that adds cases here. |
| 1000–1500 (on notice) | `LibKa0s/SkinPaint.lua` | 1002 | **New to the band**, 979 → 1002 with SkinPaint minor 13. Accepted: seam the window block, to `LibKa0s/SkinPaintExtras.lua`; re-check at 1050 lines, or the next SkinPaint minor. |
| 1000–1500 (on notice) | `LibKa0s/Skin.lua` | 1149 | Grew 1081 → 1149 with Skin minor 9's outline mode, outside the owner-token block its trigger watches; one line under the 1150 re-check, so the next line added fires it. |
| 1000–1500 (on notice) | `LibKa0s/SkinDefs.lua` | 1043 | Grew 1005 → 1043 (38 lines) with SkinDefs minor 17, under the 40-line-per-release trigger. |
| 1000–1500 (on notice) | `tests/test_options_skin_picker.lua` | 1131 | Grew 1064 → 1131; its trigger fired at OptionsSkinPicker minor 3's cases (1220), and the bench then moved, unchanged, to `tests/fixture_skin_picker.lua`, under the 1200 re-check. |
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | 1335, 1412, 1290, 1382, 1370 | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`). `OptionsWidgets.lua` peeled at its trigger (1447 → 1370) on its named seam to the new `LibKa0s/OptionsSwitch.lua` (163); the other four are unchanged. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1465 | Carried forward; unchanged by kit revision 45 (the guard is the new `glyphs.lua`), 25 lines from the 1490 re-check trigger. |
| 1000–1500 (on notice) | `tests/test_sim_panel.lua`, `tests/test_options_compose.lua`, `LibKa0s/SimPanel.lua` | 1056, 1012, 1018 | Carried forward; unchanged. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-10-30, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** none required. `git diff v1.81.0 -- LibKa0s/Sim.lua LibKa0s/SimTimeline.lua
  LibKa0s/SimPanel.lua LibKa0s/Widgets.lua` moves no minor, and `Widgets.lua` is the file that
  defines `W.TestStrip` (`grep -l 'TestStrip' LibKa0s/*.lua` also lists `SkinPaintExtras.lua`, which
  only paints the strip's fill and mentions the strip in comments)
- **Commits since the previous release touching them:** none
- **Note:** the skin-wide changes (Prototype under Ka0s Default, the outline by default, equal
  widths) reach owned sim panels and strips through Skin and SkinDefs, not through the four files
  step 5 names, so no scenario, step or test-mode datum moves; each host's smoke checks of the look
  move with the rest of its skin checks in the run's M2.

## Actions

1. The local annotated tag `v1.82.0` is cut on the commit that adds this bundle. It is not pushed:
   the branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 of `docs/releasing.md` is the run's M2: each addon's `<PFX>-01` re-vendors the tag and
   carries every stub, facade and schema row it needs in that one commit (D-23); Ka0s Skin Tester
   carries the showcase faces, outline and widths (`ST-01`).
3. Standard v2.93.0 (`WS-01`), which this release is built to, is on WowAddonStandards'
   `feat/2026-10-30-skin-fonts-feedback`; it merges with this release.
4. `LibKa0s/Skin.lua` is one line under its 1150 trigger and `LibKa0s/SkinDefs.lua` will fire its
   40-line trigger with the next 3 lines of a release: an `LK-A<n>` fix during M2 that grows either
   names its peel in the same change.
5. In-client smoke for the release's look changes is the owner's, in the run's smoke-test record;
   none is marked passed here.
