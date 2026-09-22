# Analysis — 20260922-202214

- **Addon:** LibKa0s 1.54.0
- **Verdict:** green
- **Commit:** 1040f3d (`master`)
- **Previous run:** 20260922-170122 (v1.52.0 → v1.53.0)

## Headline

Green on every suite that ran, and the release gate's five conditions hold. **One file added to the
test kit and nothing else moved**: `testkit/test_prose.lua`, the US-English gate of
`localization-5`, which eleven repositories had otherwise been writing by hand. `framework.lua`
changes by one integer, the kit revision. No library file changes at all, so the
`LibKa0s-Options-1.0` version key and every other major's are exactly v1.53.0's.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260922-170122 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 73 files | [`lint.txt`](lint.txt) | +1 file — the new kit suite. |
| tests | pass | 1277 passed, 0 skipped, 0 failed | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No. |
| perf | skip | not measured — no `tests/perf.lua` | — | No. |
| lizard / complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up, averages flat. |

**`perf` was not measured.** LibKa0s ships no `tests/perf.lua`, so there were no offline scenarios
to run. This is the one skip that satisfies the release gate rather than blocking it
(`automated-tests-3`): this release was verified across **three** suites, not four.

| Metric | Value |
|---|---|
| Total NLOC | 25542 |
| Functions | 3594 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 52.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 2 |

## What moved

- **lint** — 72 → **73** files: the new kit suite is linted like any other authored Lua.
- **tests** — **unchanged at 1277**, and that is the point worth reading twice. The new suite ships
  in `testkit/` and is mirrored to `tests/_kit/`, but this repo already declares a `test_prose` of
  its own — a *different* gate, over the shipped payload rather than the tracked tree — so the name
  is already declared and the kit copy does not run here. Six consumers are in the same position by
  the same accident of naming; six are not and will redden on re-vendor until they declare it.
  That is the intended failure, not a regression.
- **complexity, totals** — NLOC 25362 → **25542** (+180), functions 3590 →
  **3594** (+4): the gate's own helpers.
- **complexity, averages** — **flat**: avg CCN 2.0, avg NLOC/function 6.6, max
  CCN 15, avg tokens 52.3.
- **bands** — 9 in 1000–1500, 2 over the cap.

## Complexity watch list

Carried in full in [`RESULTS.md`](../RESULTS.md), regenerated from this run's own `lizard` output.

### Functions `lizard` warned on

None. Zero functions above CCN 15, which is the gate's condition.

### Files by `layout-1` band

Unchanged in membership. `LibKa0s/OptionsWidgets.lua` and `tests/test_options_widgets.lua` are both
over the cap under issues [#16](https://github.com/tusharsaxena/LibKa0s/issues/16) and
[#8](https://github.com/tusharsaxena/LibKa0s/issues/8).

## Actions

None gate this release. Two are worth recording, and both are about what the kit can and cannot
police:

1. **A kit suite is declared by NAME, not by path.** `Kit.assertSuiteInventory` compares the names
   in `tests/_kit/` against the runner's declared set, so a repo that already declares a suite
   called `test_prose` satisfies the check and silently keeps running its own. Six consumers are in
   exactly that state. It is the right outcome — `localization-5` says wire one or the other, never
   both — but it is reached by coincidence rather than by decision, and a consumer that wanted the
   kit's copy would have to notice on its own.
2. **The shipped payload cannot waive, so it must not quote.** This repo's own prose gate holds
   `libs/` and `testkit/` to the rule with no per-file waiver, deliberately: those bytes reach every
   consumer and no consumer can fix them. That is why the kit gate and the kit README *describe* the
   forbidden spellings instead of quoting them, and why the one exemption is the gate's own copy of
   the `BRITISH` list — ninety-one British spellings the standard obliges it to carry whole.

The three pre-existing debts are unchanged: `LibKa0s/Widgets.lua` (bare *Accepted* since v1.27.0),
`tests/test_options.lua` (owed a tracked ID since v1.8.3), and the blank dispositions on
`LibKa0s/OptionsTabs.lua` and `testkit/framework.lua`.
