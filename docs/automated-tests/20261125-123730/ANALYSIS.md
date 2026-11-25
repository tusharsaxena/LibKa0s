# Analysis — 20261125-123730

- **Addon:** LibKa0s 1.114.0 (release run, `--release 1.115.0`; `addonVersion` reads 1.114.0 because
  the tag `v1.114.0` is the nearest `git describe` finds; `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `0ee74e5b` (`feat/2026-11-25-item-search`), clean: the v1.115.0 release, all but its
  own record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate lines)
  follows as one commit, and the local tag `v1.115.0`, never pushed, is cut on it.
- **Previous run:** [`20261125-021723`](../20261125-021723/) (at `6e8d2484`, the v1.114.0 record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.115.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.115.0 was verified
across **three** suites, not four.

The release moves one payload file, `LibKa0s/ForeverDB.lua` to minor 2 (`IS-LK-01`: `SearchItems`,
`QuestsForItem`, `RewardFrom`, `StartsQuest` and `SkinnedFrom` for Drop Watcher's Item Search), and the
kit to revision 63 (the ForeverDB fake's fixture gains the rows those lookups read). The first run of
this battery at this commit is this one; nothing was discarded.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261125-021723 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 393 files | [`lint.txt`](lint.txt) | 392 -> 393 files |
| tests | pass | 5236 passed, 3 skipped, 0 failed, 5239 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 5223 -> 5239 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | NLOC +423, functions +53; averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 116699 |
| Functions | 16746 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 61.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 11 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5236
passed, 0 failed, 3 skipped, 5239 total. The seed tool's own cases, `python3 -m pytest -q tools/seeds`,
ran outside the runner too: 18 passed. The complexity suite measures Lua only, so
`tools/seeds/libseeds.py` is not in its figures.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** one file changed, `LibKa0s/ForeverDB.lua` (667 lines, minor 2: five new lookups and
  two session indexes, a name index over `item` and an item -> quests index over `qx`). No file added,
  no `NEEDS_*` floor rises.
- **Kit:** revision 62 -> 63 (`testkit/mock_foreverdb.lua`'s invented fixture gains `qx`, `rew`,
  `start` and `skin` rows, five items and two quests), `tests/_kit/` re-synced.
- **Contract changes:** `docs/api/ForeverDB/version-2-docs.md` and `members-2.json` are new and
  supersede version 1; the testkit document 63 supersedes 62.
- **Lint:** 392 -> 393 files, 0/0: the new `tests/test_foreverdb_lookups.lua`.
- **Tests:** 5223 -> 5239: the new suite's sixteen cases; `tests/test_foreverdb.lua` and
  `tests/test_kit_inventory.lua` re-pin minor 2, its member list and revision 63. The three skips are
  unchanged, declared skips, not passes.
- **Complexity:** NLOC 116276 -> 116699 and functions 16693 -> 16746, from the five lookups, their
  helpers and the new suite. Averages unchanged (6.8 NLOC, CCN 2.1); average tokens 60.9 -> 61.0. Max
  CCN is still 15, with 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, the same eleven as the previous run, each disposition carried. `ForeverDB.lua` (667) is not in the band. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-25, by hand
- **Files reviewed:** none needed: no Sim file (`Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`,
  `SimPanelRender.lua`) and not `Widgets.lua` (the file that defines `W.TestStrip`) moved in this
  release.
- **Commits since the previous release touching them:** 0.
- **Note:** the release moves ForeverDB 2 only.

## Actions

1. Cut the local tag `v1.115.0` on this record commit. Pushing it, merging to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks `docs/2026-11-25-ITEM_SEARCH/`).
2. Drop Watcher re-vendors v1.115.0 and adopts the five lookups in the same run (that bundle's
   `03_SPEC.md` §4.1); it is the only addon that re-vendors in that run. Loot History and Bank Ledger
   remove their ForeverDB features there (§5, §6) on their vendored v1.114.0.
