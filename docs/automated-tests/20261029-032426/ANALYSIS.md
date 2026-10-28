# Analysis — 20261029-032426

- **Addon:** LibKa0s 1.79.0 (release run, `--release 1.80.0`; `addonVersion` reads 1.79.0, the
  newest tag, because a library repo has no TOC and the runner falls back to `git describe`; the
  local `v1.80.0` tag is cut by the lead on the commit that adds this bundle)
- **Verdict:** green
- **Commit:** 663b0fb (`feat/2026-10-29-skinning-rollout`), clean
- **Previous run:** 20261028-223958 (release run, `--release 1.79.0`, at `3c9225f`), the final
  measurement of v1.79.0.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.80.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.80.0 was verified across **three** suites, not four.

This is the first and only release run of the close; nothing was re-run.

## Why this run exists

v1.80.0 is the library half of the skinning rollout to the fourteen remaining Ka0s addons (M1 of
Ka0sAddonsCommonTasks `docs/2026-10-29-SKINNING_ROLLOUT/`, closed by `LK-90`). It carries the
rung-2 items that meet the M0 inventory's gaps: owner tokens (Skin minor 7, `LK-01`), the slot remap
`opts.tokens` on `Shell`, `Panel`, `Inset`, `Card` and `Button` (SkinPaint minor 11, SkinPaintExtras
minor 5, SkinPaintControls minor 9, SkinEUI minor 2, `LK-02`), `Skin:AliasAceType` and a `TreeGroup`
painter (SkinAce minor 4, `LK-03`), the icon border family (SkinDefs minor 15, OptionsCompose minor
13, `LK-04`) and `opts.stockDefault` (`LK-05`), plus the independent review's fixes to them. Still
nineteen majors across fifty-three files, test kit revision 44. The close commit `663b0fb` dated the
block and moved the pointers.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261028-223958 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 233 files | [`lint.txt`](lint.txt) | Yes: 228 → 233 files, 0/0 at both |
| tests | pass | 3220 passed, 2 skipped, 0 failed, 3222 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3158 → 3222 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +1534 NLOC, +167 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 71129 |
| Functions | 10458 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 57.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost; the owner-token overlay in `__Tokens`, the remap on every repaint and the `TreeGroup`'s
`RefreshTree` hook in particular are unmeasured here. **`tests` carries two skips**, the same two as
at the previous run: the kit's own `tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s
`localization-§5` deviation row, and the diagnostics contract's opt-out case, a declared skip in a
repo that keeps the default.

## What moved

Against the final v1.79.0 measurement, [`20261028-223958`](../20261028-223958/):

- **lint** reads five more files (228 → 233), still 0/0 ([`lint.txt`](lint.txt)): five new suites,
  `tests/test_skin_owner_tokens.lua`, `tests/test_skin_remap.lua`, `tests/test_skin_ace_tree.lua`,
  `tests/test_skin_icon_border.lua` and `tests/test_skin_stock_default.lua`. No payload file is new.
- **tests** grow by 64 cases (3158 → 3222; 3156 → 3220 passed): 16 in `test_skin_owner_tokens`, 14 in
  `test_skin_ace_tree`, 12 in `test_skin_remap`, 9 in `test_skin_stock_default`, 8 in
  `test_skin_icon_border` and 5 more in `test_options_compose_skin` (10 → 15). The per-suite list is
  in [`test-cases.md`](test-cases.md). None fails, and the skipped count stays at 2.
- **complexity** grows by 1534 NLOC (69595 → 71129) and 167 functions (10291 → 10458). Avg CCN and
  avg NLOC hold at 2.1 and 6.7; avg tokens rise 57.0 → 57.7, the owner-token validation and the
  remap carrying longer argument lists than the suite code that dominates the totals. Max CCN is 15
  and no function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Skin.lua` | 1044 | **New to the band**, 802 → 1044 with Skin minor 7's owner tokens, the slot remap's resolution and `__DrawsKey`. Accepted at the close and recorded in `RESULTS.md` and `CLAUDE.md`: the seam is the owner-token block, to a secondary file of its own paired on the Skin shell; re-check at 1150 lines, or the next Skin minor that adds to that block. |
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | 1335, 1378, 1268, 1380, 1447 | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`), carried verbatim in `RESULTS.md`. None moved since v1.79.0. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1465 | Carried forward in `RESULTS.md`; unchanged (kit revision 44 unchanged), 25 lines from the 1490 re-check trigger. |
| 1000–1500 (on notice) | `tests/test_sim_panel.lua` | 1056 | Carried forward in `RESULTS.md`; unchanged. |
| 1000–1500 (on notice) | `tests/test_options_compose.lua` | 1012 | Carried forward in `RESULTS.md` and `CLAUDE.md`; unchanged (OptionsCompose minor 13's cases went to `tests/test_options_compose_skin.lua`). |
| under the band | `LibKa0s/Perf.lua`, `LibKa0s/SimPanel.lua`, `LibKa0s/SkinPaint.lua` | 997, 997, 994 | `Perf.lua` and `SimPanel.lua` unchanged; `SkinPaint.lua` stays under 1000 because `Panel`, `Inset`, `FadeRegions` and `FadeNineSlice` moved, unchanged, to `SkinPaintExtras.lua` (449). |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-10-29, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** none needed: `git diff --stat v1.79.0 -- LibKa0s/Sim.lua LibKa0s/SimTimeline.lua
  LibKa0s/SimPanel.lua LibKa0s/Widgets.lua` prints nothing
- **Commits since the previous release touching them:** 0
- **Note:** the release moved none of step 5's minors, so no host's scenarios or test-mode strips
  change and step 8 names no host for a re-look.

## Actions

1. The lead cuts the local annotated tag `v1.80.0` on the commit that adds this bundle. The tag is
   not pushed: the branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 of `docs/releasing.md` is the rollout's M2: the fourteen addons other than LootHistory
   re-vendor the tag in their `<PFX>-RV` items; Ka0s Skin Tester carries the showroom samples.
3. Standard v2.91.0 (`WS-01`), which this release is built to, is on WowAddonStandards'
   `feat/2026-10-29-skinning-rollout`; it merges with this release.
4. `LibKa0s/SkinPaint.lua` (994), `LibKa0s/Perf.lua` and `LibKa0s/SimPanel.lua` (997) sit just under
   1000: the next change that takes any past 1000 names a peel seam in the same change (`layout-§1`).
5. Carried from v1.79.0: standard v2.90.0's *Resizing* subsection names the library's own windows,
   and `Core.MakeResizable` does not yet coalesce its per-tick layout to one pass per frame.
