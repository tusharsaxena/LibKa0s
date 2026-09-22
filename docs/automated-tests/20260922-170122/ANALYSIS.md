# Analysis — 20260922-170122

- **Addon:** LibKa0s 1.53.0
- **Verdict:** green
- **Commit:** 8f85c64 (`master`)
- **Previous run:** 20260922-095841 (v1.51.0 → v1.52.0)

## Headline

Green on every suite that ran, and the release gate's five conditions hold. The smallest release
this library has cut: **one number**, in one call, in `O.IdInput` — the Add button's height. One new
case, 8 NLOC, one function, every average flat. Nothing newly crossed a `layout-§1` band and the
watch-list debts are the same ones carried since v1.50.0.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260922-095841 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 72 files | [`lint.txt`](lint.txt) | No. |
| tests | pass | 1277 passed, 0 skipped, 0 failed | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +1 (1276 → 1277). |
| perf | skip | not measured — no `tests/perf.lua` | — | No. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up by one function, averages flat. |

**`perf` was not measured.** LibKa0s ships no `tests/perf.lua`, so there were no offline scenarios
to run. This is the one skip that satisfies the release gate rather than blocking it
(`automated-tests-§3`): this release was verified across **three** suites, not four.

| Metric | Value |
|---|---|
| Total NLOC | 25362 |
| Functions | 3590 |
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
- **tests** — 1276 → **1277**, +1: the Add button is the height of the box beside it, red under the
  `SetHeight` going away (which puts AceGUI's 24 back).
- **complexity, totals** — NLOC 25354 → **25362** (+8), functions 3589 →
  **3590** (+1): the new case and the one call.
- **complexity, averages** — **flat**: avg CCN 2.0, avg NLOC/function 6.6, max
  CCN 15, avg tokens 52.3.
- **bands** — unchanged: 9 in 1000–1500, 2 over the cap.

## Complexity watch list

Carried in full in [`RESULTS.md`](../RESULTS.md), regenerated from this run's own `lizard` output.

### Functions `lizard` warned on

None. Zero functions above CCN 15, which is the gate's condition.

### Files by `layout-§1` band

Unchanged in membership from v1.52.0. `LibKa0s/OptionsWidgets.lua` and
`tests/test_options_widgets.lua` are both over the cap under issues
[#16](https://github.com/tusharsaxena/LibKa0s/issues/16) and
[#8](https://github.com/tusharsaxena/LibKa0s/issues/8).

## Actions

None gate this release. One is worth recording, because it is the second release running where the
lesson was about measuring rather than guessing:

1. **The report named the wrong thing, and the fix was elsewhere.** "The Add button is slightly
   higher than the textbox" describes an anchoring fault, and the anchoring was correct — AceGUI
   publishes `alignoffset = 30` on a labeled EditBox and Flow honors it, so the two centers were one
   pixel apart. What was wrong was that the button is 24 tall against a 20-tall border art, so it
   overhung at both ends and the two overhangs read differently against what sits above and below.
   Measuring the screenshot found that in one pass; three rounds of anchor tuning on the same page
   the day before had not. Measure the pixels before moving an anchor.

The three pre-existing debts are unchanged: `LibKa0s/Widgets.lua` (bare *Accepted* since v1.27.0),
`tests/test_options.lua` (owed a tracked ID since v1.8.3), and the blank dispositions on
`LibKa0s/OptionsTabs.lua` and `testkit/framework.lua`.
