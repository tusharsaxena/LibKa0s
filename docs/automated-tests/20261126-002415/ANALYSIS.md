# Analysis — 20261126-002415

- **Addon:** LibKa0s 1.116.0 (release run, `--release 1.117.0`; `addonVersion` reads 1.116.0 because
  the local tag `v1.116.0` is the nearest `git describe` finds; `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `1a61374e` (`feat/2026-11-25-item-search-round3`), clean: the v1.117.0 release, all
  but its own record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate
  lines) follows as one commit, and the local tag `v1.117.0`, never pushed, is cut on it.
- **Previous run:** [`20261125-180017`](../20261125-180017/) (at `a23266df`, the v1.116.0 record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.117.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.117.0 was verified
across **three** suites, not four.

The release moves one payload file, `LibKa0s/ForeverDB.lua` to minor 4 (`ISR3-LK-01`: `Spots` from
ForeverDB_Full's `spz` and the base `spw` world coordinates through the new `WorldToMap`, with an
origin; `VendorPriceAt` and `vendx` prices; `FullStatus`, `LoadFull` and `FullCost`), and the kit to
revision 65 (the ForeverDB fake gains map geometry, world coordinates, a `vendx` price and a
ForeverDB_Full fake). The first run of this battery at this commit is this one; nothing was
discarded.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261125-180017 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 394 files | [`lint.txt`](lint.txt) | 393 -> 394 files |
| tests | pass | 5260 passed, 3 skipped, 0 failed, 5263 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 5241 -> 5263 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | NLOC +776, functions +117; averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 117543 |
| Functions | 16870 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 61.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 12 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5260
passed, 0 failed, 3 skipped, 5263 total. The seed tool's own cases, `python3 -m pytest -q tools/seeds`,
ran outside the runner too: 18 passed. The complexity suite measures Lua only, so
`tools/seeds/libseeds.py` is not in its figures.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** one file changed, `LibKa0s/ForeverDB.lua` (687 -> 1050 lines, minor 4). No file added,
  no `NEEDS_*` floor rises. `DebugLogDiagnostics.lua` is unchanged at minor 12: the ForeverDB
  diagnostics line prints as before, and the Full state is in `Status()` for a host to print.
- **Kit:** revision 64 -> 65 (`testkit/mock_foreverdb.lua`: an invented continent in `umaa` with
  `zbord` zones, `spw` rows, a `vendx` price, a new creature, and the ForeverDB_Full fake behind
  `opts.full`; every earlier row unchanged), `tests/_kit/` re-synced.
- **Contract changes:** `docs/api/ForeverDB/version-4-docs.md` and `members-4.json` are new and
  supersede version 3; the testkit document 65 supersedes 64. `Spots` gains a second return and
  answers sources minor 3 had no spot for; `VendorPrice` can answer lower, from `vendx`. Drop Watcher
  stays the only consumer (`docs/api/CONSUMERS.md`, `docs/releasing.md`'s Consumers row).
- **Lint:** 393 -> 394 files, 0/0: the new suite `tests/test_foreverdb_spots.lua`.
- **Tests:** 5241 -> 5263: the new suite's 21 cases and one new case in
  `tests/test_mock_foreverdb.lua` (the Full fake); `tests/test_foreverdb.lua`, the lookups suite and
  `tests/test_kit_inventory.lua` re-pin minor 4, its member list and revision 65. The three skips are
  unchanged, declared skips, not passes.
- **Complexity:** NLOC 116767 -> 117543 and functions 16753 -> 16870, from minor 4's geometry, prices
  and Full sections, the kit's Full fake and the new cases. Averages unchanged (6.8 NLOC, CCN 2.1,
  61.0 tokens). Max CCN is still 15, with 0 warnings: `region` measured 17 in a pre-commit run of the
  shadow and was split (`bounds`) before `ISR3-LK-01` was committed.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/ForeverDB.lua` | 1050 | **New to the band at minor 4**, on notice and unruled; the disposition is in [`../RESULTS.md`](../RESULTS.md). |
| 1000–1500 (on notice) | the eleven other files [`../RESULTS.md`](../RESULTS.md) lists | see there | The same eleven as the previous run, each disposition carried; none moved. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-26, by hand
- **Files reviewed:** none needed: no Sim file (`Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`,
  `SimPanelRender.lua`) and not `Widgets.lua` (the file that defines `W.TestStrip`) moved in this
  release.
- **Commits since the previous release touching them:** 0.
- **Note:** the release moves ForeverDB 4 only.

## Actions

1. Cut the local tag `v1.117.0` on this record commit. Pushing it, merging to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks
   `docs/2026-11-25-ITEM_SEARCH_ROUND3/`).
2. Drop Watcher re-vendors v1.117.0 in the same run (`ISR3-DW-00`, that bundle's `03_SPEC.md` §3) and
   adopts `LoadFull`, `VendorPriceAt` and `Spots`' origin; it is the only addon that re-vendors.
3. `CLAUDE.md`'s band census gains `LibKa0s/ForeverDB.lua` (1050 at minor 4) at the next pass that
   edits it; the seam and the trigger are named in `RESULTS.md`'s row, and the ruling is the lead's.
