# Analysis — 20261117-013407

- **Addon:** LibKa0s 1.105.0 (release run, `--release 1.105.0`; `addonVersion` is the tag the
  runner's `git describe` found nearest this commit, the local, unpushed `v1.105.0` cut at
  `8209c10`, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `c2c7ce3` (`feat/2026-11-16-libka0s-75-plus`), clean: `SR-REL`'s first commit, the
  v1.105.0 release record amended for smoke round 1 (Ka0sAddonsCommonTasks
  `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/SR1_SMOKE_ROUND1.md`). Since the previous run the branch
  gained `LK-FIX-1` (the kit's frame hold at no closure per frame) and the four smoke-round items
  `SR-L1` (attached tooltips above), `SR-L2` (a tooltip on every library title-bar control),
  `SR-L3` (title-bar rest and hover colors) and `SR-L4` (section-header bands). v1.105.0 is not
  released, so this is the same release re-measured: no minor moved and the kit stays at revision
  57. The record (this bundle, its `RESULTS.md` row and the changelog's release lines) follows as one
  commit, and the tag is re-cut on that commit.
- **Previous run:** [`20261116-184422`](../20261116-184422/) (at `fa7d5b5`), v1.105.0's first
  release run, now seven commits behind.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.105.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.105.0 was verified
across **three** suites, not four. No function grew past CCN 15 in the smoke-round items, so this
close needed no split.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261116-184422 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 369 files | [`lint.txt`](lint.txt) | Yes: 368 -> 369 files |
| tests | pass | 4891 passed, 3 skipped, 0 failed, 4894 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4873 -> 4894 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count, band |

| Metric | Value |
|---|---|
| Total NLOC | 110643 |
| Functions | 15876 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 14 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** no new file and no minor. The smoke-round items change files this release already
  bumps: `Tooltip.lua` 1 (`PlaceAttached` above and flipping below; `AttachTitleTip`,
  `CLOSE_STRINGS`, `SetCloseTip`, `CloseTip`), `WidgetsHeader.lua` 1, `WidgetsDragHandle.lua` 14 and
  `WidgetsDragHandleTip.lua` 1 (`DRAG_HANDLE_STRINGS`), `Core.lua` 18, `DebugLog.lua` 23 and
  `DebugLogWindow.lua` 5 (the console's tooltips and colors), `SkinDefs.lua` 28 and
  `SkinDefsOthers.lua` 10 (`close.rest` follows `icon.tint`; `list.header.bg` in every skin), and the
  hand fallbacks in `OptionsSkinPicker.lua` 12, `IconBrowser.lua` 2, `WidgetsDropdown.lua` 2,
  `WidgetsReorder.lua` 7, `SimPanel.lua` 11 and `Charts.lua` 2. Every major's key is the one the
  first run measured. The kit's `mock_base.lua` and `mock_events.lua` change inside revision 57
  (`LK-FIX-1`).
- **Contract changes:** the `CHANGELOG.md` block's *What a consumer owes* gains the smoke round's
  stub members (Widgets `DRAG_HANDLE_STRINGS`; the Tooltip major's four), a list of what a host's
  suite may re-pin (no-tooltip cases and `tips = false`, below-anchored attached tips, `icon.hot`
  and `text.link` hovers and `close.rest`, `list.header.bg`), and two visible changes (title-bar
  tooltips, section-header bands).
- **Lint:** 368 -> 369 files, the new `tests/fixture_title_tips.lua`.
- **Tests:** 4873 -> 4894, the smoke-round cases (the per-window title-bar tooltip acceptance cases,
  the per-skin title-bar color pins, the band floors, the solver's flip cases and the kit's frame-hook
  case). The three skips are still declared skips, not passes.
- **Complexity:** NLOC 110214 -> 110643 and functions 15807 -> 15876. Avg NLOC, avg CCN and the max
  did not move; avg tokens 60.5 -> 60.6.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_skin_defs.lua` | 1058 | New: 999 -> 1058 with `SR-L4`'s section-header floors; accepted in `CLAUDE.md`'s census at this close (a suite, the list-row contrast section is its seam, trigger 1100 lines or the next contrast floor) |
| out of the band | `LibKa0s/WidgetsDragHandle.lua` | 994 | 989 -> 994 with `SR-L2`'s default strip tooltips |
| out of the band | `LibKa0s/Core.lua` | 994 | 986 -> 994 with `SR-L2`'s close tooltip |
| 1000–1500 (on notice) | the other thirteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward at the previous run's figures. `LibKa0s/OptionsSkinPicker.lua` holds at 1399 (1 under its 1400 trigger) and `LibKa0s/IconBrowser.lua` at 1006 through `SR-L1`'s anchors. `LibKa0s/Skin.lua` (1121, trigger 1100) and `tests/test_media.lua` (1048, the next-face trigger) still carry triggers that fired before this release, left to the lead |

Fourteen, nothing over 1500.

## Preview and simulation data

- **Answer:** Refreshed
- **Asked:** 2026-11-17, by hand
- **Files reviewed:** `tests/fixture_sim_panel.lua`, `tests/test_sim_panel_render.lua`,
  `tests/test_sim_panel_controls.lua` and `docs/api/Sim/version-3.3.11.4-docs.md`, against the
  smoke-round changes. `Widgets.lua` (the `W.TestStrip` file) does not move.
- **Commits since the previous run touching them:** 2 (`8d290db` SR-L1, `c115635` SR-L2)
- **Note:** SimPanel minor 11's hand fallback for an unreadable geometry now attaches a tip above
  its control (`SR-L1`), and the sim panel's settings and close carry tooltips (`SR-L2`, pinned in
  `tests/test_sim_panel_render.lua` through `tests/fixture_title_tips.lua`). The placed path
  `tests/test_tooltip_sites.lua` pins is unchanged. Sim minor 3's sample characters and the first
  run's re-look stand.

## Actions

1. Re-cut the local tag `v1.105.0` on the commit that adds this bundle (the lead): it now points at
   `8209c10`, which precedes the smoke-round items. Push the tag only on the owner's go-ahead.
2. Re-copy the re-cut tag into every addon (`SR-<ABBR>` of the same bundle), with the amended
   *What a consumer owes* in each re-vendor commit, then each addon's own title-bar pass.
3. **Standards pointer:** v2.112.2, unchanged. The smoke round's rulings land in the standard's
   unreleased v2.113.0 wording (`SR-STD`).
4. **Band:** `tests/test_skin_defs.lua` is new and accepted with its seam; `LibKa0s/Skin.lua` and
   `tests/test_media.lua` still carry fired triggers, the lead's rulings.
5. **Kit note**, carried: `tests/_kit/run-automated-tests.sh` refuses a git worktree, so release runs
   need the main checkout or a clean clone.
