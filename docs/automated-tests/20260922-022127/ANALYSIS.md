# Analysis — 20260922-022127

- **Addon:** LibKa0s 1.51.0
- **Verdict:** green
- **Commit:** the minor-28 bookkeeping commit on `feat/idlist-help-mark`
- **Previous run:** 20260921-144300 (v1.49.1 → v1.50.0)

## Headline

Green on every suite that ran, and the release gate's five conditions hold: lint 0/0, 0 failed
tests, 0 functions over CCN 15. The movement is this release's own — six new cases and 137 NLOC for
`O.IdList`'s help mark, its suggestion tag and the always-on row highlight. Every complexity average
is flat, so the growth is size rather than density, and nothing newly crossed a `layout-§1` band.
The watch-list debts are the same three carried at v1.50.0; none is new and none gates this release.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260921-144300 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 72 files | [`lint.txt`](lint.txt) | No. Same 72 files, same 0/0. |
| tests | pass | 1270 passed, 0 skipped, 0 failed | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +6 cases (1264 → 1270), all this release's. |
| perf | skip | not measured — this library ships no `tests/perf.lua` | — | No. Skipped at the previous run too. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up, every average flat. |

**`perf` was not measured.** LibKa0s ships no `tests/perf.lua`, so there were no offline scenarios
to run. This is the one skip that satisfies the release gate rather than blocking it
(`automated-tests-§3`), and it means this release was verified across **three** suites, not four.

| Metric | Value |
|---|---|
| Total NLOC | 25262 |
| Functions | 3580 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 52.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 2 |

## What moved

- **lint** — nothing. 0 warnings / 0 errors across the same 72 files.
- **tests** — 1264 → **1270**, +6: four pinning the help mark (drawn per list not per entry, dimmed
  and hoverless when empty, a string reading as one line, and the width coming out of the name),
  one for the suggestion tag, and one REWRITTEN rather than added — the one-column case now asserts
  that a row lights, where it used to assert the opposite.
- **complexity, totals** — NLOC 25125 → **25262** (+137) and functions 3567 →
  **3580** (+13): `entryHelpLines`, `listHasHelp`, `entryHelp`, the
  widened `entryNameRel` / `entryMinContent` / `fitIdColumns` signatures, and the new cases.
- **complexity, averages** — **flat**: avg CCN 2.0, avg NLOC/function 6.6, max
  CCN 15, avg tokens 52.2. The added functions are guard-and-return shaped.
- **bands** — unchanged: 9 files in 1000–1500, 2 over the cap.
  **Nothing newly crossed.**

## Complexity watch list

Carried in full in [`RESULTS.md`](../RESULTS.md), regenerated from this run's own `lizard` output.

### Functions `lizard` warned on

None. Zero functions above CCN 15, which is the condition the release gate enforces.

### Files by `layout-§1` band

Unchanged from v1.50.0 in membership. `LibKa0s/OptionsWidgets.lua` and
`tests/test_options_widgets.lua` both grew with this release and were already over the cap under
their existing issues ([#16](https://github.com/tusharsaxena/LibKa0s/issues/16) and
[#8](https://github.com/tusharsaxena/LibKa0s/issues/8)).

## Actions

None gate this release. The same three are owed as at v1.50.0, all pre-existing:

1. `LibKa0s/Widgets.lua` (1232) has carried a bare *Accepted* since v1.27.0, past
   `automated-tests-§4`'s three consecutive release runs. Owed a peel or a tracked deviation ID.
2. `tests/test_options.lua` (1307) has read *owed a tracked ID* since v1.8.3. File it or peel it.
3. `LibKa0s/OptionsTabs.lua` (1197) and `testkit/framework.lua` (1227) carry **blank** dispositions:
   both crossed and neither has been ruled on.
