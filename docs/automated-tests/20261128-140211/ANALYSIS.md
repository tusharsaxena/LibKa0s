# Analysis — 20261128-140211

- **Addon:** LibKa0s 1.119.0 (release run, `--release 1.120.0`; `addonVersion` reads 1.119.0 because
  the tag `v1.119.0` is the nearest `git describe` finds; `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `df1b9704` (`feat/2026-11-28-issue-fixes`), clean: the v1.120.0 release, all but its own
  record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate lines)
  follows as one commit. No tag is cut: the tag waits on the owner's go-ahead (Drop Watcher's plan
  `docs/superpowers/plans/2026-11-28-issue-fixes.md`, task G1).
- **Previous run:** [`20261128-053702`](../20261128-053702/) (at `0d17ea0e`, v1.119.0's release record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.120.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.120.0 was verified across **three** suites, not four.

The run was taken in the git worktree itself (kit revision 67's runner, as revision 66 allowed). One
file is new to the `layout-§1` band: `LibKa0s/Sim.lua`, 973 -> 1039 with minor 6's `Sim:Cover`
(below). It is on notice and unruled.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261128-053702 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 421 files | [`lint.txt`](lint.txt) | No (421 files) |
| tests | pass | 5578 passed, 3 skipped, 0 failed, 5581 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 5552 -> 5578 passed |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | NLOC +515, functions +102; Avg CCN 2.2 -> 2.1 |

| Metric | Value |
|---|---|
| Total NLOC | 125962 |
| Functions | 17957 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 61.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 14 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5578
passed, 0 failed, 3 skipped, 5581 total. The seed tools' own cases, `python3 -m pytest -q tools/seeds`
(`libseeds.py` and `L5`'s new `classseeds.py`), ran outside the runner too: 51 passed.

## What moved

- **Payload:** four file minors move, no file is added. `Verdict.lua` 1 -> 3, `VerdictGear.lua` 1 -> 2
  and `VerdictSettings.lua` 1 -> 2 (key 1.1.1.1.1.1.1.1.1.1.1 -> 3.1.1.1.1.1.1.1.1.2.2): the weight
  slider runs -5..20 and stretches to a stored weight (`L1`, LibKa0s#107), `StandUp{ lazy = true }`
  (`L2`, LibKa0s#108), and `v.R` as a forwarder per read (`L4`, LibKa0s#111). `Sim.lua` 5 -> 6 (key
  6.3.11.4): `Sim:Cover` (`L4`). No `NEEDS_*` floor rises.
- **Kit:** revision 66 -> 67 (`docs/api/testkit/version-67-docs.md`): the vendor-sync gate skips a
  provenance tag the sibling cannot resolve (`L3`, LibKa0s#110).
- **Contract changes:** additive, with one identity change: a Verdict instance's `v.R.X` is no longer
  `rawequal` to the host's or the library's function (every answer the same). The Verdict and Sim
  member manifests carry `Settings.WeightRange` and `Sim:Cover`.
- **Tools:** `tools/seeds/classseeds.py` and its 33 cases (`L5`, LibKa0s#109), outside the payload.
- **Lint:** 421 files, unchanged: no Lua file added under lint's scope.
- **Tests:** 5552 -> 5578 passed: 26 new cases in `tests/test_verdict_settings.lua`,
  `tests/test_verdict_gear.lua`, `tests/test_kit_vendor_sync.lua`, `tests/test_verdict_instances.lua`,
  `tests/test_sim_seam.lua` and `tests/test_sim_session.lua`. The three skips are unchanged declared
  skips, not passes.
- **Complexity:** NLOC 125447 -> 125962, functions 17855 -> 17957; Avg CCN 2.2 -> 2.1, Avg tokens
  61.9 -> 61.8, Avg NLOC unchanged. Max CCN still 15, 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Sim.lua` | 1039 | **New to the band at minor 6 (`L4`, LibKa0s#111). On notice, unruled; not yet in `CLAUDE.md`'s band census.** 973 -> 1039 with `Sim:Cover` and its header note. Seam: the sample people section (`lib.SAMPLE` through `lib.SampleCrowd`, about 230 lines), to a secondary paired on the Sim shell; a peel is a new shipped file and so a release, and the ruling is the lead's. **Re-check trigger: 1100 lines, or the next Sim minor.** |
| 1000–1500 (on notice) | the other thirteen files [`../RESULTS.md`](../RESULTS.md) lists | see there | The same thirteen as the previous run, each disposition carried. |

## Preview and simulation data

- **Answer:** Refreshed
- **Asked:** 2026-11-28, by hand
- **Files reviewed:** `tests/fixture_sim_panel.lua`, every `tests/test_sim_*.lua`,
  `tests/test_widgets_teststrip.lua` and `docs/api/Sim/version-6.3.11.4-docs.md`, against `Sim.lua`
  minor 6. `tests/test_sim_seam.lua` and `tests/test_sim_session.lua` are extended (`Cover`'s idle and
  active paths) and `tests/test_sim_sample.lua` re-pins minor 6; the fixture and the strip suite are
  unchanged.
- **Commits since the previous release touching them:** 1 (`197783ad`).
- **Note:** `Cover` is additive and lib-level. No sample character, scenario, step or test-mode strip
  moves and `Widgets.lua` does not move, so no host's start route or strip needs a re-look; Drop
  Watcher is the one host that adopts `Cover`, in the same run (its task D2).

## Actions

1. Tag `v1.120.0` on this record commit only at the owner's go-ahead (task G1 of Drop Watcher's plan).
2. Drop Watcher and Ka0s Item Search re-vendor this build (`libs/LibKa0s/` and `tests/_kit/`, kit
   revision 67), re-pin `Verdict 3`, `VerdictGear 2`, `VerdictSettings 2`, `Sim 6` and `KIT_VERSION`
   67 where their suites pin them, and adopt `StandUp{ lazy = true }` and the read seam (tasks D1, D2
   and I1).
3. Open for the lead: `LibKa0s/Sim.lua`'s band entry (seam and trigger above) for `CLAUDE.md`'s band
   census.
