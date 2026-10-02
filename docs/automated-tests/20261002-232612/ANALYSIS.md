# Analysis — 20261002-232612

- **Addon:** LibKa0s 1.68.0 (release run, `--release 1.68.0`; `addonVersion` reads 1.68.0 because a
  local `v1.68.0` tag already existed when this run started, see *Why this run exists*)
- **Verdict:** green
- **Commit:** 6ffa4ca (`feat/2026-10-02-drag-attach`), clean
- **Previous run:** 20261002-231513 (1.68.0, release run, at `3cd411d`, green, superseded before the
  tag was pushed)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.68.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and `complexity.blindFiles` is 0. **Perf was not
measured**: this repository ships no `tests/perf.lua`, so v1.68.0 was verified across **three**
suites, not four. This is the run the `v1.68.0` tag is cut from.

## Why this run exists

The previous run, 20261002-231513, measured `3cd411d`, and the local `v1.68.0` tag was first cut on
`3fe6b43` (`DA-LK-05R`), the measured commit's grandparent. That breaks the precondition in
`docs/releasing.md` that `.git.sha` is the commit being tagged or its parent, and it meant the tagged
tree differed from the measured one by more than the record and its `CHANGELOG.md` line. The tag had
not been pushed, so it was re-cut rather than left standing.

Review also found two prose defects in the unreleased entry, and they were fixed in `6ffa4ca`
(`DA-LK-06R`), the commit this run measures. `CHANGELOG.md`'s v1.68.0 entry gave
`tests/test_widgets_draghandle.lua` as 814 lines; it is 813 at every commit on the branch. The
Consumers table's Widgets row in `docs/releasing.md` joined two sentences with no separator.
20261002-231513's `ANALYSIS.md` repeats the 814 figure (its *What moved* section); that bundle is
frozen and is not edited, and this paragraph is its correction.

No payload or test file changed between `3cd411d` and `6ffa4ca`; the two commits between them
(`ee9dcfe`, `3fe6b43`) and `6ffa4ca` itself touch the record, `CLAUDE.md`, `CHANGELOG.md`,
`DEPENDENCIES.md` and `docs/releasing.md` only. That is why every figure below matches the previous
run exactly.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261002-231513 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 146 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 2023 passed, 2 skipped, 0 failed, 2025 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | No |

| Metric | Value |
|---|---|
| Total NLOC | 40807 |
| Functions | 6132 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 54.4 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 6 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries two skips**, the same two as at v1.67.0's release run: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

`RESULTS.md` now says the case count has been flat at 2025 across the last three runs. Here that
comes from measuring one release three times (20261002-231003, 20261002-231513 and this run), not
from a suite that stopped growing: against v1.67.0's record the count rose by ten.

## What moved

Against v1.67.0's release record, 20261002-012529:

- **lint**: 144 → 146 files, 0/0. The two new files are `tests/test_widgets_draghandle_place.lua`
  and `tests/fixture_draghandle.lua`; no payload file was added.
- **tests**: 2015 → 2025 (+10), all in `tests/test_widgets_draghandle_place.lua`, for
  WidgetsDragHandle minor 4's `tooltipPlace` and a descriptor's `place`.
- **complexity**: NLOC 40568 → 40807, functions 6095 → 6132, average NLOC 6.7 flat, average CCN 2.0
  flat, average tokens 54.5 → 54.4, max CCN 15 flat, blind files 0 flat.
- **band**: 6 files, the same six as at v1.67.0, every disposition carried forward. No re-check
  trigger is reached. `tests/test_widgets_draghandle.lua` is at 813 lines,
  `tests/test_widgets_draghandle_place.lua` at 241 and `LibKa0s/WidgetsDragHandle.lua` at 675.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `testkit/mock_base.lua` | as in `RESULTS.md` | Carried forward verbatim in `RESULTS.md`; none of the six changed in this release. |
| under the band (watch) | `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua`, `testkit/framework.lua`, `tests/test_options.lua` | 999, 997, 994, 988 | Unchanged since v1.66.0, each within a dozen lines of the band. |

## Actions

1. Move the local annotated tag `v1.68.0` to the commit that adds this bundle (not pushed; the push
   and the branch's merge wait on the owner).
2. Step 8 of `docs/releasing.md`: re-vendor every consumer. AuraMaster's re-vendor and its
   `tooltipPlace` adoption ride on its own `feat/2026-10-02-drag-attach` branch (AuraMaster#22),
   and the strip tooltip's side is an in-game smoke check this run cannot measure.
