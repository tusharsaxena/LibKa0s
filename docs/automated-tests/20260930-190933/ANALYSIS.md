# Analysis — 20260930-190933

- **Addon:** LibKa0s 1.64.0 (release run, `--release 1.64.0`)
- **Verdict:** green
- **Commit:** 0a95227 (`feat/2026-09-30-debug-logs-and-resize`), clean
- **Previous run:** 20260930-183150 (1.64.0, release run, at `d1d0824`)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.64.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.64.0 was verified across **three** suites, not four.

This run supersedes 20260930-183150 as the v1.64.0 release record, and the tag moves to the commit
that adds it. Between the two, `0a95227` (`DL-LIB-03`, the rollout's addendum A2) folded a second
change into the still-unpublished v1.64.0: running the diagnostics report turns debug logging on for
the session, through `SetEnabled(true)`, before it writes, unless the descriptor sets
`diagnosticsEnablesLogging = false` (`debug-logging-§14` at v2.71.0). `DebugLogDiagnostics.lua`
moves from minor 1 to **2** and `DebugLog.lua` from 16 to **17** (comments only; key 17.2), and the
kit from revision 33 to **34**. The earlier bundle stays as it was, frozen.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260930-183150 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 127 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 1832 passed, 2 skipped, 0 failed, 1834 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 1827 → 1834 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: totals up, averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 37575 |
| Functions | 5254 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 1.9 |
| Max CCN | 15 |
| Avg tokens / function | 51.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 10 |
| Files over the 1500 cap | 0 |

**`perf` was not measured**, for the same sanctioned reason as the previous run (`automated-tests-§3`,
nothing to run). **`tests` carries two skips.** One is the same as before: the kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row. The
other is new and by design: kit revision 34's *an addon that opts out lands the report and leaves
logging off* is a declared skip in any repo that keeps the default, and this repo's fixture host
does (its turn-on case runs instead). The library's own suite covers the opt-out directly.

## What moved

- **tests**: 1827 → 1834. In `tests/test_debuglog_diagnostics.lua`, the case *the report is
  ungated: it lands with logging off and leaves the flag alone* became *a run with logging off turns
  it on first, through the one seam* (one `setEnabled`, the enable line, the `[Init]` summary and
  then the report, the header printing `on`, the ack before the report's line), and five cases are
  new: the opt-out (ungated, flag stays off), only `false` opting out, already on (no second enable
  line), never off, and the link opted out. The link's click case now expects logging on;
  `BuildDiagnostics` and `DebugVerb` gained flag assertions; four existing cases re-pinned for the
  two extra console lines and the extra chat line (or run with logging already on). In the kit's
  contract, one case retired and three added (one a declared skip here), and
  `tests/test_kit_inventory.lua` pins revision 34. Written before the library change, eleven cases
  failed on the first run (the turn-on cases in both suites, `true` not opting out, `DebugVerb`, the
  link's click, the two that pin the file's minor, the append case re-pinned for the extra lines, and
  the three kit-revision checks). The
  opt-out, already-on and never-off cases, in the library's suite and the kit's, passed then too:
  the old behavior satisfies them, and they pin what the change must not break.
- **complexity**: NLOC 37481 → 37575 and functions 5247 → 5254, the new cases and the kit's
  `enables` helper. `RunDiagnostics` goes from CCN 4 to 6 with the enable's two conditions.
  Averages unchanged; max CCN 15, none warned on.
- **band**: still 10 files, 0 over the cap. `LibKa0s/DebugLog.lua` stays at 999 lines: its change is
  comments only, and the descriptor field's one new line was paid for by tightening the
  diagnostics-install comment from five lines to four.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `LibKa0s/Perf.lua`, `LibKa0s/Widgets.lua`, `testkit/mock_base.lua`, `tests/test_options.lua`, `tests/test_schema.lua` | unchanged | Carried forward verbatim in `RESULTS.md`. |
| under the band (watch) | `LibKa0s/DebugLog.lua` | 999 | Not in the band. Named because it is one line short of it; the next addition to that file puts it on notice. |

## Consumer note

The `CHANGELOG.md` v1.64.0 block, *What a consumer owes*, now carries the diagnostics line: no
instance member moves, so no DebugLog degradation stub does; a host suite that asserts the report
leaves logging off, or counts the buffer or the chat after a run with logging off, re-pins; the kit's
contract case names change, so `docs/test-cases.md` is regenerated; and an addon that keeps logging
off sets `diagnosticsEnablesLogging = false` in its descriptor and `enablesLogging = false` in
`Kit.diagnostics`. A consumer already on the branch's earlier v1.64.0 copy (DebugLog 16.1, kit 33)
re-vendors to take 17.2 and kit 34.

## Actions

1. Move the local annotated tag `v1.64.0` to the commit that adds this bundle, its message naming
   DebugLog 17, DebugLogDiagnostics 2 and kit revision 34 (not pushed; the push and the branch's
   merge wait on the owner).
2. In-game, not measurable here: `/<prefix> diagnostics`, `/<prefix> debug diagnostics` and a click on
   the Diagnostics link with logging off each turn it on (the title bar's toggle reads `Debug: ON`,
   the chat ack prints, the enable line and the summary sit above the report), a second run adds no
   second enable line, and a `/reload` leaves logging off again.
