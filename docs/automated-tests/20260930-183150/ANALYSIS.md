# Analysis — 20260930-183150

- **Addon:** LibKa0s 1.64.0 (release run, `--release 1.64.0`)
- **Verdict:** green
- **Commit:** d1d0824 (`feat/2026-09-30-debug-logs-and-resize`), clean
- **Previous run:** 20260930-153012 (1.64.0, release run, at `7b4fbe8`)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.64.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.64.0 was verified across **three** suites, not four.

This run supersedes 20260930-153012 as the v1.64.0 release record, and the tag moves to the commit
that adds it. Between the two, `d1d0824` (`DL-LIB-02`, the rollout's addendum A1) folded a change
into the still-unpublished v1.64.0: the debug console's title bar draws an orange **Diagnostics**
link beside the Debug On/Off toggle, which runs `D:RunDiagnostics()` on a click, and DebugLog moves
from minor 15 to **16** (key 16.1). The earlier bundle stays as it was, frozen.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260930-153012 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 127 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 1826 passed, 1 skipped, 0 failed, 1827 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 1820 → 1827 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: totals up, averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 37481 |
| Functions | 5247 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 1.9 |
| Max CCN | 15 |
| Avg tokens / function | 51.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 10 |
| Files over the 1500 cap | 0 |

**`perf` was not measured**, for the same sanctioned reason as the previous run (`automated-tests-§3`,
nothing to run). **`tests` carries one skip**, the same one: the kit's own `tests/_kit/test_prose.lua`
is declined under `CLAUDE.md`'s `localization-§5` deviation row.

## What moved

- **tests**: 1820 → 1827. Six `diag link:` cases in `tests/test_debuglog_diagnostics.lua` (drawn
  with the report, not drawn without it, the `L` override of its label, anchored to the toggle's
  font string with the 10 px gap, orange at rest and brighter under the pointer, a click running the
  report with logging off and leaving it off), and one in `tests/test_resize_windows.lua` (the
  minimum width grows with the link). The two existing minimum-width cases now build their consoles
  without the report, so they still pin minor 15's arithmetic. All seven were red before the change.
  No case was renamed or removed.
- **complexity**: NLOC 37339 → 37481 and functions 5221 → 5247, the cases, their recorders and three
  functions in `LibKa0s/DebugLog.lua` (`textWidth` CCN 5, `buildDiagnosticsLink` 4, and
  `consoleMinWidth`, 7 → 4 now that it measures the title through `textWidth`). Averages unchanged;
  max CCN 15, none warned on.
- **band**: still 10 files, 0 over the cap. `LibKa0s/DebugLog.lua` is 999 lines (957 before), one
  under the band; the change's comments were cut to keep it there, and the next addition to that
  file puts it on notice.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `LibKa0s/Perf.lua`, `LibKa0s/Widgets.lua`, `testkit/mock_base.lua`, `tests/test_options.lua`, `tests/test_schema.lua` | unchanged | Carried forward verbatim in `RESULTS.md`. |
| under the band (watch) | `LibKa0s/DebugLog.lua` | 999 | Not in the band. Named because it is one line short of it. |

## Consumer note

The `CHANGELOG.md` v1.64.0 block, *What a consumer owes*, now carries the link's line: no instance
member moves, so no DebugLog degradation stub does, and a host suite that pins the console's minimum
width, or counts the frames its title bar builds, re-pins with the link in. A consumer already on
the branch's first v1.64.0 copy (DebugLog 15) re-vendors to take 16.

## Actions

1. Move the local annotated tag `v1.64.0` to the commit that adds this bundle, its message naming
   DebugLog 16 (not pushed; the push and the branch's merge wait on the owner).
2. In-game, not measurable here: the link's look beside the toggle (orange, the gap, no button art),
   its hover, a click writing the report with logging off, and the console's minimum width keeping
   the link clear of the title. AuraMaster's preview (`DL-AM-03`) is the first check, before the other
   ten consumers take it.
