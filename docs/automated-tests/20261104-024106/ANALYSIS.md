# Analysis — 20261104-024106

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's eighteenth local re-cut, `R6-REL2`
  after `R6-SIM-L`; the manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** `0dfe377` (`feat/2026-11-01-full-skinning`), clean, the `masterRows` split: nothing but this
  record follows it
- **Previous run:** [`20261104-023511`](../20261104-023511/) (at `d71df6f`), the same re-cut's first battery,
  which found one function over CCN 15. The baseline for *What moved* below is the seventeenth re-cut,
  [`20261104-002816`](../20261104-002816/) (at `4fd5b47`).

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are 0.
**Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.85.0 was verified across
**three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261104-002816 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 298 files | [`lint.txt`](lint.txt) | Yes: 297 -> 298 files (one new suite) |
| tests | pass | 4069 passed, 3 skipped, 0 failed, 4072 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4056 -> 4072 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 89793 NLOC, 12977 functions, avg NLOC 6.8, avg CCN 2.1, avg tokens 59.8, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 89503 -> 89793 NLOC, 12937 -> 12977 functions; averages unchanged; max CCN 15 at both |

The totals rose because the library grew (`R6-SIM-L`'s Sim mode row and its suite); the averages did
not move, so this is not a density signal. The three skips are the previous runs': the declined kit
prose gate, the diagnostics opt-out case and `test_skin_values`, which is still a declared skip, not a
pass.

## What moved

Against [`20261104-002816`](../20261104-002816/): the owner's addendum to the sixth smoke round
(Ka0sAddonsCommonTasks `docs/2026-11-03-SMOKE_ROUND6/` `R6_ADDENDUM_SIM_RENAME_FINISH.md`, "Add a sim
checkbox in settings (next to test) for all Ka0s addons that support it").

- **`R6-SIM-L`, OptionsCompose minor 19** (`e98a178`): `O.MasterControls` takes the launcher's own
  `isSimMode` / `toggleSim` pair and, with both, draws a session-only Sim mode checkbox beside Test mode,
  or beside Lock frame when there is no Test mode. Ticking starts the sim as `/<slash> sim` does,
  unticking stops it, Reset all settings stops a running sim, and nothing is stored. A host that passes
  neither function draws exactly the tab it drew.
- **`R6-REL2`** (`d71df6f`, `0dfe377`): the hosts-owe line, then `masterRows`, measured at CCN 22 by the
  first battery, split under the cap with no behavior change (the Minimap button, Test mode and
  Sim-beside-Test rows to `masterTail`); still minor 19, which no host vendors.
- Keys: Options 37.4.44.2.7.2.9.15.2.4.19.13.5.5.7.6.11.1.1.4; Skin 16.1.27.8.18.17.17.4.9, Widgets
  22.5.12.6.7.5, DebugLog 22.6.1.4, Perf 15.1.1.13, Sim 2.3.10.3 and Toast 3 unchanged; kit revision 50,
  no kit file moved.
- Tests: 16 cases more, 4072 total, in one new suite (`tests/test_options_compose_sim.lua`) and the
  moved minor pin.

## Complexity watch list

### Functions the complexity suite warned on

None. `masterRows` is under the cap after the split.

### Files by `layout-§1` band

Fifteen: `LibKa0s/OptionsCompose.lua` came in (974 -> 1073 with `R6-SIM-L`, 1080 with the split),
nothing over 1500, none left. `CLAUDE.md`'s census row accepts it with its seam (the Master controls
block, to a file of its own) and its re-check trigger (1150 lines, or the next OptionsCompose minor
that adds a composer), and its Disposition cell in RESULTS.md now says so. `OptionsSkinPicker.lua`
(1493) did not move; its fired 1400 trigger is still the lead's and the owner's call. No other band
file moved.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-04, the lead's call under the owner's run guidelines; the owner was not asked
- **Files reviewed:** only `OptionsCompose.lua` moved, a settings row that calls the host's own sim
  pair. No `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`, `SimPanelRender.lua` or `Widgets.lua` moved,
  and `lib.TestStrip` did not move. Every `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua`
  ran green. No scenario, step, control or strip changes, so step 5 names no hosts.

## Actions

1. The local annotated tag `v1.85.0` is re-cut on the commit that adds this bundle. It was never
   pushed. The merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer (`R6-RV2`). What hosts owe is the `R6-SIM-L`
   paragraph of `docs/releasing.md`'s hosts-owe list, closed by the `R6-REL2` line: nothing in the
   re-vendor commit itself over the round 6 cut; then each sim host's `R6-SIM` item, the launcher
   pair on its `MasterControls` spec, with one smoke check per host.
3. The OptionsSkinPicker peel (the queue), whose trigger fired, and the SkinPaintExtras and
   SkinPaintControls peels are the lead's and the owner's call.
4. In-client smoke is the owner's and none is marked passed here.
