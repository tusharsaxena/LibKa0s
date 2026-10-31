# Analysis — 20261031-202020

- **Addon:** LibKa0s 1.83.0 (label `pre-merge`; not a release run)
- **Verdict:** green
- **Commit:** 6c816fd (`feat/2026-10-31-font-pickers-skin-faces`), clean
- **Previous run:** [`20261031-185000`](../20261031-185000/) (`--release 1.83.0`, at `8cffb7a`), the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, per [`manifest.json`](manifest.json): lint, tests and complexity
are `pass`, no function is above CCN 15, and no file is blind, crashed or over the 1500 cap. Nothing
moved since the previous run, because the only commit between them records that run. **Perf was not
measured**: this repository ships no `tests/perf.lua`. The owner asked for CCN and NLOC flags to be
fixed, and this run found none to fix, so no code changed.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-185000 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 251 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3522 passed, 2 skipped, 0 failed, 3524 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No |
| perf | skip | not measured: no `tests/perf.lua`, 0 scenarios | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | No |

| Metric | Value |
|---|---|
| Total NLOC | 78123 |
| Functions | 11318 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 59.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 15 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, the same sanctioned skip as every run of this repository
(`automated-tests-§3`): there is no `tests/perf.lua`, so this record says nothing about runtime cost.
**`tests` carries two skips**, the same two as the previous run: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Nothing. Against [`20261031-185000`](../20261031-185000/), `tests.txt`, `lint.txt`, `complexity.txt`
and `test-cases.md` are byte-identical, and every figure in `manifest.json`'s suites other than the
durations is the same. The one commit between the two, `6c816fd`, touches only
`docs/automated-tests/` and `CHANGELOG.md`, so no Lua changed.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1335 | tracked, `CLAUDE.md` `automated-tests-§4` row |
| 1000–1500 (on notice) | `LibKa0s/OptionsIdList.lua` | 1290 | tracked, `CLAUDE.md` `automated-tests-§4` row |
| 1000–1500 (on notice) | `LibKa0s/OptionsIds.lua` | 1412 | tracked, `CLAUDE.md` `automated-tests-§4` row |
| 1000–1500 (on notice) | `LibKa0s/OptionsSkinPicker.lua` | 1455 | accepted, under its 1480 re-check |
| 1000–1500 (on notice) | `LibKa0s/OptionsTabs.lua` | 1382 | tracked, `CLAUDE.md` `automated-tests-§4` row |
| 1000–1500 (on notice) | `LibKa0s/OptionsWidgets.lua` | 1375 | tracked, `CLAUDE.md` `automated-tests-§4` row |
| 1000–1500 (on notice) | `LibKa0s/SimPanel.lua` | 1018 | accepted, third release run (see Actions) |
| 1000–1500 (on notice) | `LibKa0s/Skin.lua` | 1232 | accepted, fourth release run (see Actions) |
| 1000–1500 (on notice) | `LibKa0s/SkinDefs.lua` | 1104 | accepted, third release run (see Actions) |
| 1000–1500 (on notice) | `LibKa0s/SkinPaint.lua` | 1002 | accepted, under its 1050 re-check |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1465 | on notice, under its 1490 re-check |
| 1000–1500 (on notice) | `tests/test_options_appearance.lua` | 1266 | accepted, under its 1300 re-check |
| 1000–1500 (on notice) | `tests/test_options_compose.lua` | 1012 | accepted, seventh release run (see Actions) |
| 1000–1500 (on notice) | `tests/test_options_skin_picker.lua` | 1129 | accepted, third release run (see Actions) |
| 1000–1500 (on notice) | `tests/test_sim_panel.lua` | 1056 | on notice, under its 1200 re-check |

These are shortened here; `RESULTS.md` holds each disposition in full, all carried forward unchanged,
and no row arrived blank. Every LOC figure and band count is the runner's own. The release counts
come from the band table in `RESULTS.md` at each release's commit, v1.77.0 through v1.83.0.

## Actions

1. **New here, no tracker.** Five band rows have been *accepted* across three or more consecutive
   release runs, so `automated-tests-§4` owes each a fix or a tracked deviation with an id and an
   owner: `tests/test_options_compose.lua` (v1.77.0 on), `LibKa0s/Skin.lua` (v1.80.0 on, re-ruled at
   v1.83.0), and `LibKa0s/SimPanel.lua`, `LibKa0s/SkinDefs.lua` (re-ruled at v1.83.0) and
   `tests/test_options_skin_picker.lua` (v1.81.0 on). The change is to add them to `CLAUDE.md`'s
   `automated-tests-§4` row, or to peel each on its named seam. Neither is done here: this run was
   scoped to change no code, and a size in the band is not a CCN or NLOC flag.
2. **New here, no tracker.** `testkit/mock_base.lua` and `tests/test_sim_panel.lua` carry *on notice*
   rather than *accepted*, and have stood in the band across at least eight release runs (v1.75.0
   and v1.76.0 on). They have triggers and seams but sit outside the tracked row, so they should be
   ruled on with action 1.
