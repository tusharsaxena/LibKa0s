# Analysis — 20261117-094753

- **Addon:** LibKa0s 1.105.0 (release run, `--release 1.105.0`; `addonVersion` is the tag the
  runner's `git describe` found nearest this commit, the local, unpushed `v1.105.0`, now cut at
  `2cd727d`, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `4f92909` (`feat/2026-11-16-libka0s-75-plus`), clean: `SR2-REL`'s first commit, the
  v1.105.0 release record amended for smoke round 2 (Ka0sAddonsCommonTasks
  `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/SR2_SMOKE_ROUND2.md`). Since the previous run the branch
  gained `SR-REL`'s record commit and the two smoke-round-2 items, `SR2-L1` (the title-bar hover at
  least 20 CIEDE2000 off its rest in every skin, `text.link` raised in Azeroth, Glass, WoW Midnight
  and WoW Forever) and `SR2-L2` (window edges one 1px line in WoW Midnight, Azeroth and Ember).
  v1.105.0 is not released, so this is the same release re-measured: no minor moved and the kit stays
  at revision 57. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate
  line) follows as one commit, and the tag is re-cut on that commit.
- **Previous run:** [`20261117-013407`](../20261117-013407/) (at `c2c7ce3`), smoke round 1's
  re-close, now four commits behind.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.105.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.105.0 was verified
across **three** suites, not four. No function grew past CCN 15 in the smoke-round-2 items, so this
close needed no split.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261117-013407 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 370 files | [`lint.txt`](lint.txt) | Yes: 369 -> 370 files |
| tests | pass | 4896 passed, 3 skipped, 0 failed, 4899 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4894 -> 4899 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count, band |

| Metric | Value |
|---|---|
| Total NLOC | 110804 |
| Functions | 15895 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** one file, `SkinDefsOthers.lua`, inside the minor 10 this release already bumps, so
  every major's key is the one the previous run measured. `SR2-L1` sets `text.link` to Azeroth
  `#FFEB33` (its `text.linkHot` `#FFF6C8`), Glass `#66F0FF`, WoW Midnight `#FFC94A` and WoW Forever
  `#FFAA33`, with no `icon.tint` moved. `SR2-L2` makes WoW Midnight's `win.border` 1px `#B08A3E`
  with no `win.inner`, Azeroth's one 1px `#8A6A36` edge and Ember's one 1px `#955727` edge, and
  leaves popup, menu and tooltip edges alone. No kit file changed.
- **Contract changes:** the `CHANGELOG.md` block's *What a consumer owes* re-pin list carries both
  smoke-round-2 items (the four `text.link` values; WoW Midnight's `win.borderSize`, three skins'
  `win.inner` and `win.border`, and the header band's inset), and its visible changes name the new
  hover colors and the 1px window edges. No member moved, so every members manifest regenerates
  unchanged.
- **Lint:** 369 -> 370 files, the new `tests/test_skin_row_contrast.lua`.
- **Tests:** 4894 -> 4899: `SR2-L1`'s four cases (the CIEDE2000 helper against Sharma et al.'s
  pairs, the 20 floor in every skin, legibility on the title band, the four raised skins) and
  `SR2-L2`'s one (a Shell window's 1px edge with no inner rule in four skins). Seven list-row cases
  moved, unchanged, from `tests/test_skin_defs.lua` to `tests/test_skin_row_contrast.lua`. The three
  skips are still declared skips, not passes.
- **Complexity:** NLOC 110643 -> 110804 and functions 15876 -> 15895, most of it the CIEDE2000
  helper and the new cases. Avg NLOC, avg CCN, avg tokens and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| out of the band | `tests/test_skin_defs.lua` | 983 | Left at `SR2-L1`: 1058 -> 1183 with the hover floors fired its trigger (the next contrast floor), and the list-row contrast section peeled on its named seam to `tests/test_skin_row_contrast.lua` (262); 980 -> 983 with `SR2-L2`'s Midnight re-pin |
| 1000–1500 (on notice) | the other thirteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Unchanged by smoke round 2. `LibKa0s/OptionsSkinPicker.lua` holds at 1399 (1 under its 1400 trigger). `LibKa0s/Skin.lua` (1121, trigger 1100) and `tests/test_media.lua` (1048, the next-face trigger) still carry triggers that fired before this release, left to the lead |

Thirteen, nothing over 1500. `LibKa0s/SkinDefsOthers.lua` (847), `tests/test_skin_paint.lua` (864)
and `tests/test_header_band.lua` (337) grew and stay out of the band.

## Preview and simulation data

- **Answer:** Refreshed (the release's answer stands; smoke round 2 adds nothing to it)
- **Asked:** 2026-11-17, by hand
- **Files reviewed:** the `git log` of `LibKa0s/Sim*.lua`, `LibKa0s/Widgets.lua`,
  `tests/fixture_sim_panel.lua`, `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua`
  since the previous run.
- **Commits since the previous run touching them:** 0
- **Note:** smoke round 2 moves token values in `SkinDefsOthers.lua` only. The sim panel's title-bar
  hover takes the new `text.link` and its window edge the new 1px line under the three skins, through
  the tokens, with no Sim, SimPanel or Widgets change.

## Actions

1. Re-cut the local tag `v1.105.0` on the commit that adds this bundle (the lead): it now points at
   `2cd727d`, which precedes `SR2-L1` and `SR2-L2`. Push the tag only on the owner's go-ahead.
2. Re-copy the re-cut tag into every addon (`SR2-<ABBR>` of the same bundle), with the amended
   *What a consumer owes* in each re-vendor commit; a host suite that pins one of the moved token
   values re-pins it.
3. **Owner call:** the flat popup and menu edges still above 1px, Azeroth's and WoW Midnight's 2px
   (`SR2_SMOKE_ROUND2.md`'s ruling 2 leaves them unchanged and lists them).
4. **Standards pointer:** v2.112.2, unchanged.
5. **Band:** `LibKa0s/Skin.lua` and `tests/test_media.lua` still carry fired triggers, the lead's
   rulings.
6. **Kit note**, carried: `tests/_kit/run-automated-tests.sh` refuses a git worktree, so release runs
   need the main checkout or a clean clone.
