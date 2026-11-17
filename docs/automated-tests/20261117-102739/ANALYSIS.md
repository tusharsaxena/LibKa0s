# Analysis — 20261117-102739

- **Addon:** LibKa0s 1.105.0 (release run, `--release 1.105.0`; `addonVersion` is the tag the
  runner's `git describe` found nearest this commit, the local, unpushed `v1.105.0`, now cut at
  `11f8d3f`, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `8de56c0` (`feat/2026-11-16-libka0s-75-plus`), clean: the second `SR2-REL` record
  commit, the v1.105.0 release record amended for `SR2-L3` (Ka0sAddonsCommonTasks
  `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/SR2_SMOKE_ROUND2.md`, the owner's answer 3). Since the
  previous run the branch gained the first re-close's record commit, `SR2-L3` (a footer button's
  hovered label at least 20 CIEDE2000 off its rest in every skin) and this record commit. v1.105.0
  is not released, so this is the same release re-measured: no minor moved and the kit stays at
  revision 57. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate line)
  follows as one commit.
- **Previous run:** [`20261117-094753`](../20261117-094753/) (at `4f92909`), smoke round 2's first
  re-close, now three commits behind.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.105.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.105.0 was verified
across **three** suites, not four. No function grew past CCN 15 in `SR2-L3`, so this pass needed no
split.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261117-094753 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 372 files | [`lint.txt`](lint.txt) | Yes: 370 -> 372 files |
| tests | pass | 4929 passed, 3 skipped, 0 failed, 4932 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4899 -> 4932 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 110982 |
| Functions | 15924 |
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

- **Payload:** three files, each inside a minor this release already bumps, so every major's key is
  the one the previous run measured. `SkinDefsOthers.lua` (minor 10): Azeroth's `btn.hover` is
  `#FFF800` and WoW Midnight's `btnPrimary.hover` its link `#FFC94A`. `SimPanel.lua` (minor 11) and
  `SimPanelRender.lua` (minor 4): the panel's footer buttons hover `text.link` (TOKENS `hot`), an
  owner-less panel's `DEFAULT.hot` the orange `HOT_LINK`; rows still hover `text.accent`. No kit file
  changed.
- **Contract changes:** the `CHANGELOG.md` block's *What a consumer owes* re-pin list gains the
  `SR2-L3` line (Azeroth's `btn.hover`, WoW Midnight's `btnPrimary.hover`, a sim panel button's
  hover at `text.link`), and its visible changes name the footer buttons. No member moved, so every
  members manifest regenerates unchanged.
- **Lint:** 370 -> 372 files, the new `tests/test_footer_button_hover.lua` and
  `tests/fixture_de00.lua`.
- **Tests:** 4899 -> 4932 (4896 -> 4929 run): `SR2-L3`'s 33 cases in
  `tests/test_footer_button_hover.lua` (the `btn` and `btnPrimary` floors and legibility in every
  skin, the exempt primaries, the retuned values, the sim controls' floor, and the picker, AceGUI
  Button and sim Start repainting on enter and leave in all nine skins). The CIEDE2000 helper moved,
  unchanged, from `tests/test_skin_defs.lua` to `tests/fixture_de00.lua`. The three skips are still
  declared skips, not passes.
- **Complexity:** NLOC 110804 -> 110982 and functions 15895 -> 15924, the new suite. Avg NLOC, avg
  CCN, avg tokens and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the thirteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Unchanged by `SR2-L3`. `LibKa0s/OptionsSkinPicker.lua` holds at 1399 (1 under its 1400 trigger). `LibKa0s/Skin.lua` (1121, trigger 1100) and `tests/test_media.lua` (1048, the next-face trigger) still carry triggers that fired before this release, left to the lead |

Thirteen, nothing over 1500. `tests/test_skin_defs.lua` fell 983 -> 941; `LibKa0s/SkinDefsOthers.lua`
(857), `LibKa0s/SimPanel.lua` (694), `LibKa0s/SimPanelRender.lua` (421) and `tests/test_skin.lua`
(840) stay out of the band.

## Preview and simulation data

- **Answer:** Refreshed (the release's answer stands; `SR2-L3` adds the panel buttons' hover color)
- **Asked:** 2026-11-17, by hand
- **Files reviewed:** the `git log` of `LibKa0s/Sim*.lua`, `LibKa0s/Widgets.lua`,
  `tests/fixture_sim_panel.lua`, `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua`
  since the previous run.
- **Commits since the previous run touching them:** 1 (`SR2-L3`, `SimPanel.lua` and
  `SimPanelRender.lua`)
- **Note:** the sim panel's Start and controls light their label in `text.link` instead of
  `text.accent`, inside SimPanel minor 11 and SimPanelRender minor 4. No fixture and no
  `tests/test_sim_*.lua` changed; the new cases are in `tests/test_footer_button_hover.lua`. Every
  Sim host's step panel shows it, and each host's re-vendor report names it.

## Actions

1. **`SR2-L4` is not on the branch yet** (every flat popup, menu and tooltip edge 1px, the owner's
   answer to this round's call). When it lands, the v1.105.0 record needs one more `SR2-REL` pass,
   including the `SR2-L2` Skin entry, which still lists Azeroth's and WoW Midnight's 2px popup and
   menu edges as the owner's call.
2. Re-cut the local tag `v1.105.0` (the lead), after the last record commit of this round: it now
   points at `11f8d3f`, the first re-close's record commit, which precedes `SR2-L3`. Push the tag only on the owner's
   go-ahead.
3. Re-copy the re-cut tag into every addon (`SR2-<ABBR>` of the same bundle), with the amended
   *What a consumer owes* in each re-vendor commit; a host suite that pins a moved token value or a
   sim button's hover color re-pins it.
4. **Owner call, carried from `SR2-L3`:** the Obsidian, Glass, Ember and WoW Forever primary
   buttons are exempt from the footer floor (accent fill, link under 3:1 on it, no palette label
   clears both).
5. **Standards pointer:** v2.112.2, unchanged (`SR2-STD`'s v2.113.0 wording is unreleased).
6. **Band:** `LibKa0s/Skin.lua` and `tests/test_media.lua` still carry fired triggers, the lead's
   rulings.
7. **Kit note**, carried: `tests/_kit/run-automated-tests.sh` refuses a git worktree, so release runs
   need the main checkout or a clean clone.
