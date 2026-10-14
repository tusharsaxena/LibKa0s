# Analysis — 20261014-215316

- **Addon:** LibKa0s 1.72.0 (release run, `--release 1.72.0`; `addonVersion` reads 1.71.0, the
  newest tag, because a library has no `.toc` and v1.72.0 is not tagged)
- **Verdict:** green
- **Commit:** 0521d49 (`feat/2026-10-14-drop-watcher-review-audit`), clean
- **Previous run:** 20261007-193954 (1.71.0, release run, at `fae715e`, green; the run the `v1.71.0`
  tag was cut from)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.72.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and `complexity.blindFiles` is 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.72.0 was verified across **three**
suites, not four. This is the run a `v1.72.0` tag would be cut from, but no tag is cut here: the
tag waits on the owner's approval of the merge.

## Why this run exists

v1.72.0 is the library's share of Ka0s Drop Watcher's 2026-10-14 review and audit remediation.
One file's minor moves and none is added: `Perf.lua` 15, whose `Perf.Note` takes `false` as the
parent of an observation made at top level, so `LibKa0s-Perf-1.0` is key 15.1.1.6. The test kit
moves to revision 39: `M.__fireUnconditional` reaches a handler registered under a method name
after unregister, and the new `testkit/latch.lua` publishes `Kit.assertLatchHoldOrder`. This run
measures the release commit `DW-P11 (1/2)`, which dates the CHANGELOG block and moves the README's
standards pointer to v2.81.0.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261007-193954 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 158 files | [`lint.txt`](lint.txt) | Yes: 155 → 158 files, still 0/0 |
| tests | pass | 2160 passed, 2 skipped, 0 failed, 2162 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 2141 → 2162 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals grew; warnings still 0 |

| Metric | Value |
|---|---|
| Total NLOC | 42982 |
| Functions | 6534 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 54.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 6 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost, including the cost of Perf 15's third parent state. **`tests` carries two skips**, the same
two as at v1.71.0's release run: the kit's own `tests/_kit/test_prose.lua`, declined under
`CLAUDE.md`'s `localization-§5` deviation row, and the diagnostics contract's opt-out case, a
declared skip in a repo that keeps the default.

## What moved

Against v1.71.0's release record, 20261007-193954:

- **lint** reads three more files (155 → 158), all 0/0: `testkit/latch.lua`,
  `tests/test_kit_latch.lua` and `tests/test_perf_toplevel.lua`.
- **tests** grow by 21 cases (2141 → 2162): seven in the new `tests/test_perf_toplevel.lua`, five
  in `tests/test_mock_record.lua` for the unconditional fire's reach, and nine in the new
  `tests/test_kit_latch.lua` (the per-suite list is in [`test-cases.md`](test-cases.md)). None
  fails, and the skipped count stays at 2.
- **complexity** grows by 338 NLOC (42644 → 42982) and 51 functions (6483 → 6534). The averages do
  not move beyond rounding (avg CCN 2.0, avg NLOC 6.7, avg tokens 54.2 → 54.3), max CCN stays at
  15 and no function is warned on.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua` | as in `RESULTS.md` | Tracked as one `CLAUDE.md` § *Documented deviations* row (`LK-09`), carried verbatim in `RESULTS.md`; none of the five changed in this release. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1464 | 1458 → 1464 for kit revision 39's `__kitEver` record. 26 lines from the 1490 re-check trigger; six lines is under the trigger's 30-lines-per-change limit. |
| under the band | `LibKa0s/Perf.lua` | 997 | 975 → 997 for minor 15's third parent state. **Three lines under the band**: the next change that takes it past 1000 names its peel seam in that change. |
| new, well under the band | `testkit/latch.lua` | 137 | A new kit file, loaded by `testkit/framework.lua` (917 → 919). |

## Actions

1. No tag here. When the owner approves the merge, tag the commit that adds this bundle `v1.72.0`
   (decision D4 of DropWatcher's `docs/superpowers/specs/2026-10-14-drop-watcher-review-audit-design.md`).
2. Step 8 of `docs/releasing.md`: DropWatcher re-vendors from this branch head on its own
   `feat/2026-10-14-drop-watcher-review-audit`; the other thirteen consumers re-vendor after the
   tag.
3. `LibKa0s/Perf.lua` sits at 997 lines. The next change that takes it past 1000 names a peel seam
   in the same change (`layout-§1`).
