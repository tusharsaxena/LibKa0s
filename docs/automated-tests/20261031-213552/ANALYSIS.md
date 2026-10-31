# Analysis — 20261031-213552

- **Addon:** LibKa0s 1.83.0 (label `findings-remediation`; not a release run)
- **Verdict:** green
- **Commit:** e7363f3 (`feat/2026-10-31-findings-remediation`), clean
- **Previous run:** [`20261031-202020`](../20261031-202020/) (label `pre-merge`, at `6c816fd`), the
  baseline for *What moved* below.

## Headline

Green on the three suites that ran, per [`manifest.json`](manifest.json): lint, tests and complexity
are `pass`, no function is above CCN 15, and no file is blind, crashed or over the 1500 cap. The
remediation moved test code and nothing else that this record measures: the same cases passed in
different files, and the 1000–1500 band fell from 15 files to 11. **Perf was not measured**: this
repository ships no `tests/perf.lua`.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261031-202020 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 256 files | [`lint.txt`](lint.txt) | Files 251 → 256 |
| tests | pass | 3522 passed, 2 skipped, 0 failed, 3524 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No, the cases only changed files |
| perf | skip | not measured: no `tests/perf.lua`, 0 scenarios | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC 78123 → 78167; band 15 → 11 |

| Metric | Value |
|---|---|
| Total NLOC | 78167 |
| Functions | 11318 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 59.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 11 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, the same sanctioned skip as every run of this repository
(`automated-tests-§3`): there is no `tests/perf.lua`, so this record says nothing about runtime cost.
At a release gate this reads as NOT EVALUATED, not as a pass. **`tests` carries two skips**, the same
two as the previous run, both named in [`tests.txt`](tests.txt): the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

Against [`20261031-202020`](../20261031-202020/), at the same 1.83.0:

- **lint:** still 0 warnings / 0 errors. The file count rose by 5, 251 to 256: the four suites and one
  fixture the peels added, `tests/test_options_appearance_overrides.lua`,
  `tests/test_options_compose_arm.lua`, `tests/test_options_skin_picker_shared.lua`,
  `tests/test_sim_panel_controls.lua` and `tests/fixture_appearance.lua`.
- **tests:** did not move. Sorted, `tests.txt` holds exactly the lines the previous run's holds, so
  no case was added, lost or renamed. `test-cases.md` differs only in its section structure: 25 of
  `test_options_appearance.lua`'s 60 cases, 12 of `test_options_compose.lua`'s 51, 10 of
  `test_options_skin_picker.lua`'s 47 and 18 of `test_sim_panel.lua`'s 59 now sit in the four new
  suites. `RESULTS.md`'s generated note that the count is flat at 3524 across the last 3 runs is
  true, and is not a coverage gap here: no file under `LibKa0s/` or `testkit/` changed between the
  two commits, so there was no new behavior to cover.
- **perf:** did not move; still skip.
- **complexity:** NLOC rose by 44, 78123 to 78167, which is file headers and shared setup from the
  peels. Functions (11318), avg NLOC (6.8), avg CCN (2.1), max CCN (15), avg tokens (59.0) and
  warnings (0) did not move, so the addon did not get denser. The band fell by four, 15 to 11:
  `tests/test_options_appearance.lua`, `tests/test_options_compose.lua`,
  `tests/test_options_skin_picker.lua` and `tests/test_sim_panel.lua` left it. Overs, blind files and
  crashed files stayed at 0.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1335 | tracked, `CLAUDE.md` `automated-tests-§4` row (2026-10-07) |
| 1000–1500 (on notice) | `LibKa0s/OptionsIdList.lua` | 1290 | tracked, `CLAUDE.md` `automated-tests-§4` row (2026-10-07) |
| 1000–1500 (on notice) | `LibKa0s/OptionsIds.lua` | 1412 | tracked, `CLAUDE.md` `automated-tests-§4` row (2026-10-07) |
| 1000–1500 (on notice) | `LibKa0s/OptionsSkinPicker.lua` | 1455 | tracked, `FX-LK-SIZE` row |
| 1000–1500 (on notice) | `LibKa0s/OptionsTabs.lua` | 1382 | tracked, `CLAUDE.md` `automated-tests-§4` row (2026-10-07) |
| 1000–1500 (on notice) | `LibKa0s/OptionsWidgets.lua` | 1375 | tracked, `CLAUDE.md` `automated-tests-§4` row (2026-10-07) |
| 1000–1500 (on notice) | `LibKa0s/SimPanel.lua` | 1018 | tracked, `FX-LK-SIZE` row |
| 1000–1500 (on notice) | `LibKa0s/Skin.lua` | 1232 | tracked, `FX-LK-SIZE` row |
| 1000–1500 (on notice) | `LibKa0s/SkinDefs.lua` | 1104 | tracked, `FX-LK-SIZE` row |
| 1000–1500 (on notice) | `LibKa0s/SkinPaint.lua` | 1002 | tracked, `FX-LK-SIZE` row |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1465 | tracked, `FX-LK-SIZE` row |

These are shortened here; `RESULTS.md` holds each disposition in full, all carried forward unchanged.
No row arrived blank and none is new. No entry is carried as *accepted*, so none is on the
`automated-tests-§4` shelf-life clock.

## Actions

None. Both actions of [`20261031-202020`](../20261031-202020/ANALYSIS.md) are closed: every band row
now has a tracked deviation with an id and an owner, and the four suites it named left the band.
