# Analysis — 20261128-053702

- **Addon:** LibKa0s 1.118.0 (release run, `--release 1.119.0`; `addonVersion` reads 1.118.0 because
  the tag `v1.118.0` is the nearest `git describe` finds; `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `0d17ea0e` (`feat/2026-11-27-itemsearch-split`), clean: the v1.119.0 release with the
  `IS-F1` review fixes, all but its own record. The record (this bundle, its `RESULTS.md` row and the
  changelog's release-gate lines) follows as one commit. No tag is cut: the tag waits on the owner's
  go-ahead (Drop Watcher's plan `docs/superpowers/plans/2026-11-27-itemsearch-split.md`, task G1).
- **Previous run:** [`20261127-234144`](../20261127-234144/) (at `55a7c6dc`, the first v1.119.0 record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.119.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.119.0 was verified across **three** suites, not four.

This run supersedes `20261127-234144` as v1.119.0's release record: the branch review of 2026-11-28
(`docs/reviews/2026-11-28/`) was fixed inside the release (`IS-F1.1` to `IS-F1.7`), every Verdict
file still at minor 1, and the test kit moved to revision 66. **It ran in the git worktree itself**:
revision 66's runner accepts a worktree and names it by its repository, so the manifest's `addon`
reads `LibKa0s` with no fresh clone, which closes the previous run's action 3.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261127-234144 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 421 files | [`lint.txt`](lint.txt) | No (421 files) |
| tests | pass | 5552 passed, 3 skipped, 0 failed, 5555 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 5544 -> 5552 passed |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | NLOC +188, functions +21; averages unchanged |

| Metric | Value |
|---|---|
| Total NLOC | 125447 |
| Functions | 17855 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.2 |
| Max CCN | 15 |
| Avg tokens / function | 61.9 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5552
passed, 0 failed, 3 skipped, 5555 total. The seed tool's own cases, `python3 -m pytest -q tools/seeds`,
ran outside the runner too: 18 passed.

## What moved

- **Payload:** no file minor moves (every Verdict file unreleased, still 1; key
  1.1.1.1.1.1.1.1.1.1.1). The changes: each Verdict secondary re-runs when a file before it in load
  order ran after it did (`lib.__Stale` / `lib.__Ran`, F-001); `lib.EventsFor(client)` and
  `v:Events()` (F-002, additive); `StandUp` protects each registration (F-003); `v:Config()` fills a
  missing key from `Settings.DEFAULTS` (F-004); a stood-down instance asks for no item and a waiter is
  kept once (F-005, F-006); the Pawn import says nothing without `spec.print` (F-009).
- **Kit:** revision 65 -> 66 (`docs/api/testkit/version-66-docs.md`): the runner in a git worktree.
- **Contract changes:** the Verdict document and manifest gain `EventsFor` and `Events`; additive only.
- **Lint:** 421 files, unchanged: no file added under lint's scope.
- **Tests:** 5544 -> 5552 passed: eight new cases in `tests/test_verdict_instances.lua`,
  `tests/test_verdict_settings.lua` and `tests/test_kit_runner.lua`. The three skips are unchanged
  declared skips, not passes.
- **Complexity:** NLOC 125259 -> 125447, functions 17834 -> 17855; Avg CCN, Avg NLOC and Avg tokens
  unchanged. Max CCN still 15, 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the thirteen files [`../RESULTS.md`](../RESULTS.md) lists | see there | The same thirteen as the previous run, each disposition carried; `tests/test_verdict_kernel.lua` did not move (1092). |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-28, by hand
- **Files reviewed:** none needed: no Sim file and not `Widgets.lua` moved in this release.
- **Commits since the previous release touching them:** 0.
- **Note:** the release adds the Verdict major, moves DebugLogDiagnostics 13 and the kit to 66 only.

## Actions

1. Tag `v1.119.0` on this record commit only at the owner's go-ahead (task G1 of Drop Watcher's plan).
2. Drop Watcher and Ka0s Item Search re-vendor this build (`libs/LibKa0s/` and `tests/_kit/`, kit
   revision 66) and may move their hand-kept verdict `EVENTS` lists onto `EventsFor`.
3. Open for the owner, from the review: F-010, the weight slider's 0 to 5 range against an import
   that accepts any number (widen the slider or clamp the import).
