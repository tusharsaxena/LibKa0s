# Analysis — 20261116-184422

- **Addon:** LibKa0s 1.104.0 (release run, `--release 1.105.0`; `addonVersion` is the tag the
  runner's `git describe` found nearest this commit, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `fa7d5b5` (`feat/2026-11-16-libka0s-75-plus`), clean: the release's first commit,
  `LK-REL` of Ka0sAddonsCommonTasks `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/`. The branch was cut
  from `master` at v1.104.0 and carries the run's items `LK-P1` to `LK-87` (the peels, then LibKa0s
  #75, #78, #79, #80, #81, #82, #84, #86, #87, #90 and #92), and `fa7d5b5` dates the `v1.105.0`
  heading, completes the release record and splits three functions back under CCN 15. The record
  (this bundle, its `RESULTS.md` row and the changelog's release lines) follows as one commit, and
  the tag is cut on that commit.
- **Previous run:** [`20261116-010115`](../20261116-010115/) (at `3235d42`), v1.104.0's release run.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.105.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.105.0 was verified
across **three** suites, not four. A complexity measurement taken before `fa7d5b5`, outside any
bundle, found three of this release's functions over the cap (`buildChrome` 19, `lib.HeaderButton`
16, `EnsureFrame` 22, all grown by `LK-86`); `fa7d5b5` splits them, and this run is the first record
of the tree with the split.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261116-010115 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 368 files | [`lint.txt`](lint.txt) | Yes: 347 -> 368 files |
| tests | pass | 4870 passed, 3 skipped, 0 failed, 4873 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4668 -> 4873 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count, band |

| Metric | Value |
|---|---|
| Total NLOC | 110214 |
| Functions | 15807 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** one new major, `LibKa0s-Tooltip-1.0` (`Tooltip.lua` minor 1), and four more new
  files (`WidgetsDragHandleTip.lua`, `WidgetsHeader.lua`, `WidgetsBar.lua`,
  `OptionsSkinPickerQueue.lua`), eighty-two `.lua` files in all. Eleven majors' keys move: Core
  18.1, Tooltip 1, Options (OptionsSkinPicker 12, OptionsSkinPickerQueue 1), DebugLog 23.11.1.5, Sim
  3.3.11.4, Skin (SkinDefs 28, SkinDefsOthers 10), Widgets 27.2.7.14.1.7.8.6.1.1, Charts 2.1,
  Launcher 11, IconBrowser 1.2.2 and Perf 16.1.1.14. No `NEEDS_*` floor rises. The test kit moves to
  revision 57 (the held registered frame, `mock_screen.lua`, `settings` in `LIBRARY_MARKS`).
- **Contract changes:** what a consumer owes is the `CHANGELOG.md` block's *What a consumer owes*:
  DebugLog stub `Report` and `Serialize`, five loader lines, `settings` on every `LibKa0s icons:` list,
  nineteen re-pinnable minors, and the visible changes (skin row and hot colors, the library windows'
  settings marks, the console's footer and plain Copy, the placed library tooltips).
- **Lint:** 347 -> 368 files, the five payload files and sixteen new suites and fixtures.
- **Tests:** 4668 -> 4873. The three skips are still declared skips, not passes.
- **Complexity:** NLOC 106113 -> 110214 and functions 15164 -> 15807. Avg NLOC, avg CCN and the max
  did not move; avg tokens 60.5, unchanged.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None. The three this release first grew past the cap (above) were split in `fa7d5b5`, before this run.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/IconBrowser.lua` | 1006 | New: 958 -> 1006 at minor 2, LibKa0s#92's placed cell tooltips; on notice, unruled (`CLAUDE.md`'s census) |
| 1000–1500 (on notice) | `LibKa0s/OptionsSkinPicker.lua` | 1399 | 1493 -> 1396 with the `LK-P1` queue peel, 1399 at the close; 1 under its 1400 trigger |
| out of the band | `LibKa0s/WidgetsDragHandle.lua` | 989 | Left on the `LK-92B` tooltip-half peel (1022 -> 910), then 989 with `LK-86`'s settings mark |
| out of the band | `tests/test_launcher.lua` | 965 | Left on the `LK-P2` suite peel (1235 -> 963) |
| out of the band | `tests/test_debuglog.lua` | 946 | Left on the `LK-P3` suite peel (1002 -> 939) |
| 1000–1500 (on notice) | the other eleven files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged. Two carry triggers that fired before this release, recorded at the close: `LibKa0s/Skin.lua` (1121, trigger 1100) and `tests/test_media.lua` (1048, the next-face trigger); both are left to the lead |

Thirteen, nothing over 1500.

## Preview and simulation data

- **Answer:** Refreshed
- **Asked:** 2026-11-16, by hand
- **Files reviewed:** `tests/fixture_sim_panel.lua`, `tests/test_sim_panel_controls.lua`,
  `tests/test_sim_panel_render.lua`, the new `tests/test_sim_sample.lua`, and
  `docs/api/Sim/version-3.3.11.4-docs.md`. `Widgets.lua` (the `W.TestStrip` file) does not move, so
  `tests/test_widgets_teststrip.lua` needed nothing.
- **Commits since the previous release touching them:** 4 (`d9b0b4a` LK-78, `1a86098` LK-92B,
  `41c05aa` LK-86, `8fba5c4` LK-87)
- **Note:** Sim minor 3 adds the sample characters (`SAMPLE`, `Sample`), which hosts move their own
  sample data onto at adoption. SimPanel minor 11's default title and placed tips and SimPanelRender
  minor 4's header marks change what every Sim host's step panel shows (the Consumers table's Sim row:
  Drop Watcher, Loot History, Bank Ledger, KickCD, Multi Meters, AbsorbTracker, DPS Race). Each of those
  hosts' re-vendor reports names the change.

## Actions

1. Cut the local tag `v1.105.0` on the commit that adds this bundle (the lead). Push the tag only on
   the owner's go-ahead.
2. Step 8: re-vendor v1.105.0 into all nineteen addons (phase [2] of the run), with the
   *What a consumer owes* fixes in each re-vendor commit.
3. **Standards pointer:** v2.112.2, the live standard. The adoption rules land in v2.113.0
   (`STD-01`, `STD-02`); the pointer moves to it with the next release.
4. **Band:** `LibKa0s/Skin.lua` and `tests/test_media.lua` carry fired triggers that predate this
   release, and `LibKa0s/IconBrowser.lua` is new and unruled. All three rulings are the lead's.
5. **Kit note**, carried: `tests/_kit/run-automated-tests.sh` refuses a git worktree, so release runs
   need the main checkout or a clean clone.
