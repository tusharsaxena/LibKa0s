# Analysis — 20260824-153936

- **Addon:** LibKa0s 1.11.2 (manifest `release` 1.12.0 — the pre-tag release run)
- **Verdict:** green
- **Commit:** 69e679b (master, dirty)
- **Previous run:** [`20260824-133151`](../20260824-133151/) — the pre-tag release run for v1.11.2

## Headline

Green: `luacheck` clean over 14 files, 568 of 568 harness cases, complexity zero above CCN 15 for the
fifteenth consecutive run. `LibKa0s-Widgets-1.0` moves to minor 4 and nothing else in the library
moves at all.

**This release is the first of this major that is not a bug fix, and the first that came from an
adoption that had not happened yet.** The two before it were patches an adopter tripped over after
wiring the widget up. This one comes from LootHistory, which has not adopted: it carries the third
hand-rolled copy of this widget in the collection — the copy the major exists to delete — and that
copy has two seams the library does not. A row whose `value` is not among the values it selects
("Character: Current" picks the current player's key) could not light up, because `rowSelected` only
ever asked whether the row's own value was in the set; and clicking it filtered on the literal
string, because `ToggleSelected` only ever toggled the row's own value in. Adopting without the
seams meant either losing the behavior or keeping the copy, so the seams came upstream:
`opt.isActive(dd)` and `dd.presets`, both optional and both inert for a host that sets neither.

**The collapsed label moves, and that part is a behavior change rather than an addition.**
`UpdateMultiLabel` computed its summary by walking `_options` and asking which were selected, so a
value in `_selected` with no row in the *current* option list was invisible to it — and these option
lists are data-driven, so a character with no rows in today's dataset is not in the list and the
button read "Character: All" while the filter was on. It now labels every value in `_selected`. A
host whose option list always contains everything selectable sees no difference; a host whose
selection can outlive its list will see a summary where it saw "All". Version 3's *Moving to version
4* section says so where an adopter still on that copy will read it.

**Thirteen new cases, nine of them red before the change** — and, more to the point, **the collapsed
label had no case at all before this release.** Four of the thirteen were green on arrival and stay
as regression guards: the ordinary toggle, the empty selection, the single in-list selection, and a
preset row correctly staying dark. One drives a preset row through a **real** row build rather than
a seeded stand-in, which is the discipline the last release bought and this one keeps: a seeded row
bypasses `makeMenuRow` entirely, and that is the gap that let 553 green cases sail over a crash on
first click.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260824-133151` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 14 files | [`lint.txt`](lint.txt) | No change |
| tests | pass | 568 passed, 0 skipped, 0 failed, 568 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+13 cases**, all in `test_widgets.lua` |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | **NLOC +130**, functions +22; every average and the max unmoved |

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 9847 | 9717 |
| Functions | 1432 | 1410 |
| Average NLOC | 6.3 | 6.3 |
| Average CCN | 1.9 | 1.9 |
| Max CCN | 14 | 14 |
| Average tokens | 48.6 | 48.6 |
| Functions above CCN 15 | 0 | 0 |
| Warning rate | 0.00 | 0.00 |

Most of the move is test code — thirteen cases and two helpers. `Widgets.lua` itself gains three
file-local functions and two branches; `UpdateMultiLabel` gets *simpler* by the metric, because the
counting loop it used to carry moved out into `selectionLabels` and `summarizeSelection`. Max CCN is
unmoved at 14, which is the same function it has been for fifteen runs and is not in this file.

## What this run does not cover

- **That any of it draws.** No suite renders a pixel. The mock now models the client's `Font not
  set`, which is one specific class of draw-time failure and not a rendering test.
- **The label change against a live host.** The two shipped consumers' suites are in their own
  repos; nothing here can tell whether either has a selection that outlives its option list. That is
  a re-vendor-time question for BankLedger and MultiMeters, and a smoke-test line.
- **Every other place a mock is friendlier than the client.** Still no inventory of the rest.
- **The `d.name` trap**, the art itself, and LibSharedMedia's real behavior.
