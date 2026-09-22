# Analysis — 20260922-095841

- **Addon:** LibKa0s 1.52.0
- **Verdict:** green
- **Commit:** 2df8347 (`feat/help-mark-severity`)
- **Previous run:** 20260922-022127 (v1.50.0 → v1.51.0)

## Headline

Green on every suite that ran; the release gate's five conditions hold. This release is mostly a
**regression fix in the library's own previous release**: v1.51.0's help mark reserved too little of
the row for its absolute frame and silently collapsed every list that adopted it to one column. Six
new cases, 92 NLOC, every complexity average flat. Nothing newly crossed a `layout-§1` band, and the
three watch-list debts are the same ones carried since v1.50.0.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260922-022127 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 72 files | [`lint.txt`](lint.txt) | No. |
| tests | pass | 1276 passed, 0 skipped, 0 failed | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +6 (1270 → 1276). |
| perf | skip | not measured — no `tests/perf.lua` | — | No. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up, averages flat. |

**`perf` was not measured.** LibKa0s ships no `tests/perf.lua`, so there were no offline scenarios to
run. This is the one skip that satisfies the release gate rather than blocking it
(`automated-tests-§3`): this release was verified across **three** suites, not four.

| Metric | Value |
|---|---|
| Total NLOC | 25354 |
| Functions | 3589 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 52.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 2 |

## What moved

- **lint** — nothing.
- **tests** — 1270 → **1276**, +6: the reserve regression (a helped list still gets two columns on a
  canvas that pays for them — **red at the old 0.05**), the severity tints, an unknown level reading
  as `info`, the hover restoring the entry's OWN color rather than the default gold, and the icon
  fallback when Media is absent.
- **complexity, totals** — NLOC 25262 → **25354** (+92), functions 3580 →
  **3589** (+9): the level table, the icon resolver and the widened
  tint path.
- **complexity, averages** — **flat**: avg CCN 2.0, avg NLOC/function 6.6, max
  CCN 15, avg tokens 52.3.
- **bands** — unchanged: 9 in 1000–1500, 2 over the cap. Nothing
  newly crossed.

## Complexity watch list

Carried in full in [`RESULTS.md`](../RESULTS.md), regenerated from this run's own `lizard` output.

### Functions `lizard` warned on

None. Zero functions above CCN 15, which is the gate's condition.

### Files by `layout-§1` band

Unchanged in membership from v1.51.0. `LibKa0s/OptionsWidgets.lua` and
`tests/test_options_widgets.lua` both grew again and were already over the cap under issues
[#16](https://github.com/tusharsaxena/LibKa0s/issues/16) and
[#8](https://github.com/tusharsaxena/LibKa0s/issues/8).

## Actions

None gate this release. One is worth recording **because this release is a fix for the last one**:

1. **The bench hid the bug.** `listBench` draws into `LIST_BENCH_WIDTH = 1000`, which paid for the
   broken 720px floor, so the whole suite was green while every real canvas collapsed to one column.
   The new case pins a realistic width. Worth asking, the next time a width-sensitive option lands,
   whether the bench's width is doing the same favour again.

The three pre-existing debts are unchanged: `LibKa0s/Widgets.lua` (bare *Accepted* since v1.27.0),
`tests/test_options.lua` (owed a tracked ID since v1.8.3), and the blank dispositions on
`LibKa0s/OptionsTabs.lua` and `testkit/framework.lua`.
