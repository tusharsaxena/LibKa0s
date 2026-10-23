# Analysis — 20261023-150627

- **Addon:** LibKa0s 1.76.0 (release run, `--release 1.76.0`; `addonVersion` reads 1.75.2, the
  newest tag, because a library has no `.toc` and v1.76.0 is tagged only after this bundle is
  committed)
- **Verdict:** green
- **Commit:** f9ce82a (`feat/2026-10-23-sim-preview-mode-strips`), clean
- **Previous run:** 20261022-155222 (1.75.0, release run, at `2df9193`). v1.75.1 and v1.75.2 were
  tagged without a release run of their own, so this is the first bundle since v1.75.0.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.76.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.76.0 was verified across **three** suites, not four. This is the run the
local `v1.76.0` tag is cut from.

## Why this run exists

v1.76.0 is the library's share of the 2026-10-23 run (sim auto-run, QC preview selector, mode
strips, MM/KCD simulators). Three files' minors move: `SimTimeline.lua` 3 and `SimPanel.lua` 5
(`LibKa0s-Sim-1.0` key 2.3.5: a verb or panel start plays on its own, a manual step or click holds
the run, Run all is gone) and `Widgets.lua` 14 (`LibKa0s-Widgets-1.0` key 14.1.4.3.2:
`W.TestStrip`'s `kind = "sim"` flavor and `strip.kind`, no member added). The payload stays
seventeen majors across forty files, and the test kit stays at revision 41: `testkit/` is
untouched, so no kit revision moves.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261022-155222 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 181 files | [`lint.txt`](lint.txt) | Yes: 180 → 181 files, still 0/0 |
| tests | pass | 2573 passed, 2 skipped, 0 failed, 2575 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 2536 → 2575 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: +793 NLOC, +130 functions; max CCN 15 at both |

| Metric | Value |
|---|---|
| Total NLOC | 52147 |
| Functions | 7981 |
| Avg NLOC / function | 6.5 |
| Avg CCN | 1.9 |
| Max CCN | 15 |
| Avg tokens / function | 53.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 7 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost, including the simulator's new auto-play tick or the strip's second palette. **`tests` carries
two skips**, the same two as at v1.75.0's release run: the kit's own `tests/_kit/test_prose.lua`,
declined under `CLAUDE.md`'s `localization-§5` deviation row, and the diagnostics contract's opt-out
case, a declared skip in a repo that keeps the default.

## What moved

Against v1.75.0's release record, [`20261022-155222`](../20261022-155222/), across v1.75.1,
v1.75.2 and this release:

- **lint** reads one more file (180 → 181), the new `tests/test_sim_autoplay.lua`, still 0/0
  ([`lint.txt`](lint.txt)).
- **tests** grow by 39 passing cases (2534 → 2573; 2536 → 2575 in total): 16 in the new
  `test_sim_autoplay`, 14 more in `test_sim_panel` (44 → 58), 5 more in `test_widgets_teststrip`
  (12 → 17), 3 more in `test_sim_session` (52 → 55, from the v1.75.0 tag's late Sim minor 2
  commits, which landed after that bundle's commit) and 1 more in `test_sim_timeline` (40 → 41).
  The per-suite list is in [`test-cases.md`](test-cases.md). None fails, and the skipped count
  stays at 2.
- **complexity** grows by 793 NLOC (51354 → 52147) and 130 functions (7851 → 7981). The averages
  hold (avg CCN 1.9, avg NLOC 6.5; avg tokens 53.7 → 53.8). Max CCN is 15 at both releases and no
  function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | as in `RESULTS.md` | Tracked as one `CLAUDE.md` § *Documented deviations* row (`automated-tests-§4`), carried verbatim in `RESULTS.md`. None moved in this release and none is at its re-check trigger. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1464 | Carried forward in `RESULTS.md`; unchanged, 26 lines from the 1490 re-check trigger. |
| 1000–1500 (on notice), new | `tests/test_sim_panel.lua` | 1039 | New in the band: 933 → 1039 with SimPanel minor 5's controls cases (`LK-01`). Ruled in `RESULTS.md`: the seam is the *frame, the picker and the controls* section, to `tests/test_sim_panel_controls.lua`; re-check trigger 1200 lines or the next SimPanel minor that adds cases here. |
| under the band | `LibKa0s/Perf.lua` | 997 | Unchanged, three lines under the band. |
| under the band | `LibKa0s/SimPanel.lua`, `LibKa0s/Widgets.lua`, `LibKa0s/Sim.lua`, `LibKa0s/SimTimeline.lua` | 929, 853, 730, 647 | The files this release touched (and `Sim.lua`), all under the band. |

## Preview and simulation data

- **Answer:** Refreshed
- **Asked:** 2026-10-23, by hand (`docs/releasing.md` step 5, *The preview and simulation re-look*)
- **Files reviewed:** `tests/fixture_sim_panel.lua`; every `tests/test_sim_*.lua` (`autoplay`,
  `host`, `isolation`, `panel`, `panel_render`, `seam`, `session`, `stub`, `timeline`, `verbs`);
  `tests/test_widgets_teststrip.lua`; `docs/api/Sim/version-2.3.5-docs.md` and
  `docs/api/Widgets/version-14.1.4.3.2-docs.md`
- **Commits since the previous release touching them:** 2 (`d728cc4` LK-01, `d5fa6e9` LK-10)
- **Note:** The release moved `SimTimeline.lua` 3, `SimPanel.lua` 5 and `Widgets.lua` 14, so the
  re-look applies. LK-01 re-trued the panel, timeline and verb suites to auto-play and added
  `test_sim_autoplay.lua`; LK-10 added the strip's `kind` cases. The fixture needed no change and
  carries no Run all reference; the only `RUN_ALL` mentions left in the suites assert it is gone.
  Hosts the change affects, for step 8's re-vendor reports: BankLedger, DropWatcher and LootHistory
  (Sim auto-play and the sim strip), MultiMeters (the sim strip), and MultiMeters and KickCD as new
  Sim and sim-strip adopters in this run's M3.

## Actions

1. Tag the commit that adds this bundle `v1.76.0`, locally and annotated. The tag is not pushed:
   the branch push and the merge to `master` wait on the owner.
2. Step 8 of `docs/releasing.md`: the roster consumers re-vendor from the local tag on their own
   `feat/2026-10-23-sim-preview-mode-strips` branches (the run's RV items), each report naming the
   re-look's change to the hosts listed above.
3. `tests/test_sim_panel.lua` entered the band at 1039 (new here); its seam and trigger are ruled
   in `RESULTS.md`. `LibKa0s/Perf.lua` still sits at 997: the next change that takes it past 1000
   names a peel seam in the same change (`layout-§1`).
