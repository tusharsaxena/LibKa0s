# 05 — Final summary (LibKa0s, 2026-10-07): written for after implementation

> This summary is written in advance. It assumes `02_PROPOSED_CHANGES.md` was implemented as planned and every check in `03_SMOKE_TESTS.md` passed. Nothing in it has been implemented as of this bundle.

## Headline

This cycle hardens the two widgets LibKa0s added in v1.69.0 and v1.70.0:
- The line chart now clips what it draws to its own plot, so an outlier can no longer make it create an unbounded number of permanent line regions.
- The chart re-syncs its hover when its data changes, so hosts no longer have to remember to.
- The search-box autocomplete can be re-attached after a host replaces one of its scripts, and it contains a host callback that raises.
- The slash CLI refuses `nan` and `inf` as numbers.

Everything ships as LibKa0s v1.71.0 and reaches all 11 addons through the usual re-vendor.

## Counts

Critical fixed: 0, High fixed: 0, Medium fixed: 2 (F-001, F-002), Low fixed: 7 (F-003, F-005, F-006, F-007, F-008, F-009, F-011).

**Deferred:**
- F-004: double render, unmeasured. Measure before changing the API.
- F-010: chart month labels. The library documents its default; the fix, if the in-client observation confirms the premise, is LootHistory's `formatX`.

## Changes by theme

### A — The line chart bounds its own work
- **What changed:** segments and the single-point tick are clipped to the plot rectangle, through a new pure `ChartMath.Clip`. `SetData` re-arms the hover, and `Render` re-anchors a live crosshair.
- **Why it mattered:** a point a million pixels off-plot produced 142 858 dashes in a headless measurement, and each dash is a permanent client region. The hover contract made every host carry a workaround.
- **Findings:** F-001, F-003. **Changes:** C-01, C-02.
- **Files:** `LibKa0s/WidgetsLineChart.lua`, `tests/test_widgets_linechart.lua`, `tests/test_widgets_linechart_math.lua`.

### B — The autocomplete survives its host
- **What changed:**
  - Hooks are generation-tagged and re-installed on every `Autocomplete` call.
  - `provider` and `onPick` run under `pcall`, and a raise goes to the client's error handler and closes the list.
  - `maxRows` is floored.
  - The backdrop is set once.
  - A misleading weak-table comment is corrected.
- **Why it mattered:** a host's later `SetScript` silently and permanently disabled the list.
- **Findings:** F-002, F-005, F-007, F-008, F-009. **Change:** C-03.
- **Files:** `LibKa0s/WidgetsAutocomplete.lua`, `tests/test_widgets_autocomplete.lua`, and `testkit/` only if the mock needed hook fidelity.

### C — The CLI refuses non-finite numbers
- **What changed:** `ParseValue` answers `ERR_NUMBER` for `nan`, `inf`, `-inf` and overflow.
- **Why it mattered:** an unbounded number row could store a non-finite value.
- **Finding:** F-006. **Change:** C-04.
- **Files:** `LibKa0s/SlashParse.lua`, `tests/test_slash_parse.lua`.

### D — Records
- **What changed:** each negative case in the three newest suites records the mutation that reddens it. The chart's API document states the default x-label locale.
- **Findings:** F-011, F-010 (documentation half). **Changes:** C-05, C-06.

## API and behavior changes

- `lib.ChartMath.Clip` is a new member (`LibKa0s-Widgets-1.0`).
- `chart:SetData` clears the hover index without calling `onHover(nil)`; the next hover tick re-fires `onHover` against the new data.
- `lib.Autocomplete` re-installs hooks on each call. The API document now states the "set host scripts first, call again to recover" precondition.
- `/<slash> set <number path> nan|inf` is refused.

Minors: WidgetsLineChart 3, WidgetsAutocomplete 2 (Widgets key 12.1.4.3.2), SlashParse 2 (Slash key 19.2). The kit moves to 38 only if the hook-fidelity mock fix was needed.

## Migration notes

None. No SavedVariables shape changes.

## Dependency changes

None.

## Performance impact

To be filled from measurement only: the headless region-count case for C-01 (lines drawn for a 1e6 px off-plot point, before and after), and the C-01 smoke memory delta. No estimate is given here.

## Test movement

Before: 2087 passed / 2 skipped / 2089 total (2026-10-07, `353f286`). After: the count rises by the new cases in C-01 to C-04. `docs/test-cases.md` is regenerated in the release commit (`testing-§5`). LibKa0s carries no README test badge. No `RESULTS.md` watch-list entry is expected to move.

## Known follow-ups

- **F-004:** measure double render in LootHistory's Timeline layout, then decide on a seam change.
- **F-010:** LootHistory `formatX`, if the deDE/frFR observation in C-05 confirms English month names.
- LootHistory's now-redundant `self.chart:ClearHover()` (`modules/Timeline.lua:308`) may be dropped at the consumer's discretion.

## Verification evidence

- `03_SMOKE_TESTS.md` sign-off table (owner).
- Commit range on `feat/2026-10-07-review-audit-remediation` in LibKa0s, and the re-vendor commits in the 11 consumers.

## Suggested commit or PR description

```
LibKa0s v1.71.0: harden LineChart and Autocomplete; CLI refuses non-finite numbers

- F-001 + F-003: WidgetsLineChart minor 3 - segments clipped to the plot (new ChartMath.Clip);
  SetData re-arms the hover so hosts need no ClearHover.
- F-002 + F-005 + F-007 + F-008 + F-009: WidgetsAutocomplete minor 2 - generation-tagged hooks
  re-installed per call; provider/onPick under pcall to geterrorhandler; maxRows floored;
  backdrop set once; weak-table comment corrected.
- F-006: SlashParse minor 2 - nan/inf refused with ERR_NUMBER.
- F-011: red-under notes on the v1.69/v1.70 widget suites.
Deferred: F-004 (unmeasured), F-010 (consumer formatX, pending locale observation).
Review: docs/reviews/2026-10-07/.
```
