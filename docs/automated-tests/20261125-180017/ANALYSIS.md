# Analysis — 20261125-180017

- **Addon:** LibKa0s 1.115.0 (release run, `--release 1.116.0`; `addonVersion` reads 1.115.0 because
  the local tag `v1.115.0` is the nearest `git describe` finds; `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `a23266df` (`feat/2026-11-25-item-search-feedback`), clean: the v1.116.0 release, all
  but its own record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate
  lines) follows as one commit, and the local tag `v1.116.0`, never pushed, is cut on it.
- **Previous run:** [`20261125-123730`](../20261125-123730/) (at `0ee74e5b`, the v1.115.0 record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.116.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.116.0 was verified
across **three** suites, not four.

The release moves one payload file, `LibKa0s/ForeverDB.lua` to minor 3 (`ISF-LK-01`: `Object`, an
object's name, for Drop Watcher's object sources), and the kit to revision 64 (the ForeverDB fake's
fixture gains the `obj` rows `Object` reads). The first run of this battery at this commit is this
one; nothing was discarded.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261125-123730 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 393 files | [`lint.txt`](lint.txt) | No (393 files) |
| tests | pass | 5238 passed, 3 skipped, 0 failed, 5241 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 5239 -> 5241 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | NLOC +68, functions +7; averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 116767 |
| Functions | 16753 |
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

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5238
passed, 0 failed, 3 skipped, 5241 total. The seed tool's own cases, `python3 -m pytest -q tools/seeds`,
ran outside the runner too: 18 passed. The complexity suite measures Lua only, so
`tools/seeds/libseeds.py` is not in its figures.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** one file changed, `LibKa0s/ForeverDB.lua` (687 lines, minor 3: `Object`, read through
  the same `id()`, `row()` and `str()` guards as `NPC` and `Item`). No file added, no `NEEDS_*` floor
  rises.
- **Kit:** revision 63 -> 64 (`testkit/mock_foreverdb.lua`'s invented fixture gains four `obj` rows,
  two sharing a name, one nameless, one not a table, the item that drops from them and two spots),
  `tests/_kit/` re-synced.
- **Contract changes:** `docs/api/ForeverDB/version-3-docs.md` and `members-3.json` are new and
  supersede version 2; the testkit document 64 supersedes 63. Drop Watcher becomes the major's only
  consumer (`docs/api/CONSUMERS.md`, `docs/releasing.md`'s Consumers row).
- **Lint:** 393 files, 0/0, unchanged (no file added).
- **Tests:** 5239 -> 5241: `tests/test_foreverdb.lua`'s two new `Object` cases; it, the lookups suite
  and `tests/test_kit_inventory.lua` re-pin minor 3, its member list and revision 64. The three skips
  are unchanged, declared skips, not passes.
- **Complexity:** NLOC 116699 -> 116767 and functions 16746 -> 16753, from `Object` and the new cases.
  Averages unchanged (6.8 NLOC, CCN 2.1, 61.0 tokens). Max CCN is still 15, with 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, the same eleven as the previous run, each disposition carried. `ForeverDB.lua` (687) is not in the band. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-25, by hand
- **Files reviewed:** none needed: no Sim file (`Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`,
  `SimPanelRender.lua`) and not `Widgets.lua` (the file that defines `W.TestStrip`) moved in this
  release.
- **Commits since the previous release touching them:** 0.
- **Note:** the release moves ForeverDB 3 only.

## Actions

1. Cut the local tag `v1.116.0` on this record commit. Pushing it (with the still-unpushed
   `v1.115.0`), merging to `master` and the re-vendor wait on the owner's go-ahead
   (Ka0sAddonsCommonTasks `docs/2026-11-25-ITEM_SEARCH_FEEDBACK/`).
2. Drop Watcher re-vendors v1.116.0 and adopts `Object` in the same run (that bundle's `03_SPEC.md`
   §2); it is the only addon that re-vendors in that run. Skill Master and Outfitter Reborn remove
   their ForeverDB reads there (§8) on their vendored copies, unchanged.
