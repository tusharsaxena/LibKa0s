# Analysis — 20261125-021723

- **Addon:** LibKa0s 1.113.0 (release run, `--release 1.114.0`; `addonVersion` reads 1.113.0 because
  the tag `v1.113.0` is the nearest `git describe` finds; `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `6e8d2484` (`feat/2026-11-25-seeds-foreverdb`), clean: the v1.114.0 release, all but its
  own record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate lines)
  follows as one commit, and the local tag `v1.114.0`, never pushed, is cut on it.
- **Previous run:** [`20261124-194116`](../20261124-194116/) (at `92cccaee`, the v1.113.0 record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.114.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.114.0 was verified
across **three** suites, not four.

The release adds `LibKa0s-ForeverDB-1.0` (LibKa0s#105), the library's seed contract (LibKa0s#93) and
kit revision 62, whose forever name set is regenerated at Ketho's `forever` `e230342`. A first run of
this battery at `4296bd05` (bundle `20261125-021400`, discarded and not committed) was red on the
release gate's complexity condition: `lib.Spots` in `LibKa0s/ForeverDB.lua` at CCN 17. `6e8d2484`
peels it into two file-local helpers with no behavior change, and this run measures max CCN 15.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261124-194116 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 392 files | [`lint.txt`](lint.txt) | 388 -> 392 files |
| tests | pass | 5220 passed, 3 skipped, 0 failed, 5223 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 5187 -> 5223 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | NLOC +947, functions +127; averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 116276 |
| Functions | 16693 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.9 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 11 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5220
passed, 0 failed, 3 skipped, 5223 total. The seed tool's own cases, `python3 -m pytest -q tools/seeds`
(a gate line in `CLAUDE.md` from this release), ran outside the runner too: 17 passed. The complexity
suite measures Lua only, so `tools/seeds/libseeds.py` is not in its figures.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** one file added, `LibKa0s/ForeverDB.lua` (448 lines, minor 1, the new major, which `LibKa0s.xml`
  loads after `Item.lua`), and one changed, `LibKa0s/DebugLogDiagnostics.lua` (minor 12: the report names ForeverDB and prints one
  `ForeverDB:` identity line). No `NEEDS_*` floor rises.
- **Kit:** revision 60 -> 62 (revision 61's opt-in `testkit/mock_foreverdb.lua`; revision 62's
  `client_globals_forever.lua` regenerated, 10545 -> 10559 names), `tests/_kit/` re-synced.
- **Contract changes:** `docs/api/ForeverDB/version-1-docs.md` and its manifest are new;
  `docs/api/DebugLog/version-23.12.1.5-docs.md` supersedes 23.11.1.5; the testkit documents 61 and 62.
- **Lint:** 388 -> 392 files, 0/0: `LibKa0s/ForeverDB.lua`, `testkit/mock_foreverdb.lua`,
  `tests/test_foreverdb.lua` and `tests/test_mock_foreverdb.lua`.
- **Tests:** 5187 -> 5223: the two new suites, `tests/test_foreverdb.lua` and
  `tests/test_mock_foreverdb.lua`, and re-pins in the diagnostics, report and kit-inventory suites. The
  three skips are unchanged, declared skips, not passes.
- **Complexity:** NLOC 115329 -> 116276 and functions 16566 -> 16693, from the new major, its fake and
  their suites. Averages unchanged (6.8 NLOC, CCN 2.1, 60.9 tokens). Max CCN is still 15, with 0
  warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, the same eleven as the previous run, each disposition carried. `ForeverDB.lua` (448) is not in the band. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-25, by hand
- **Files reviewed:** none needed: no Sim file (`Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`,
  `SimPanelRender.lua`) and not `Widgets.lua` (the file that defines `W.TestStrip`) moved in this
  release.
- **Commits since the previous release touching them:** 0.
- **Note:** the release moves ForeverDB 1 and DebugLogDiagnostics 12 only.

## Actions

1. Cut the local tag `v1.114.0` on this record commit. Pushing it, merging to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks `docs/2026-11-25-SEEDS_AND_FOREVERDB/`).
2. The five ForeverDB consumers (Drop Watcher, Loot History, Bank Ledger, Skill Master, Outfitter
   Reborn) re-vendor v1.114.0 and adopt the major in the same run (that bundle's `03_SPEC.md` §9); every
   other addon re-vendors for kit revision 62 and `DebugLogDiagnostics 12`.
3. After the tag, WowAddonStandards' `library-stack-§7` recount (twenty-six majors) is owed, as its
   `SF-STD-01` commit records.
