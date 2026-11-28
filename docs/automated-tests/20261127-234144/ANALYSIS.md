# Analysis — 20261127-234144

- **Addon:** LibKa0s 1.118.0 (release run, `--release 1.119.0`; `addonVersion` reads 1.118.0 because
  the tag `v1.118.0` is the nearest `git describe` finds; `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `55a7c6dc` (`feat/2026-11-27-itemsearch-split`), clean: the v1.119.0 release, all
  but its own record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate
  lines) follows as one commit. No tag is cut in this run's task: the tag waits on the owner's
  go-ahead for the merge (Drop Watcher's plan `docs/superpowers/plans/2026-11-27-itemsearch-split.md`,
  task G1; ruling R8).
- **Previous run:** [`20261126-131708`](../20261126-131708/) (at `c06c772c`, the v1.118.0 record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.119.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.119.0 was verified across **three** suites, not four.

The release adds a major, `LibKa0s-Verdict-1.0` (eleven new payload files, each at minor 1: Drop
Watcher's verdict engine, promoted on the owner's ruling R4 for Drop Watcher and Ka0s Item Search),
and moves `LibKa0s/DebugLogDiagnostics.lua` to minor 13. The kit stays at revision 65. **This is
the second run at this release.** The first, `20261127-233727` at `39fc0021`, was discarded and
not committed: it measured one function over CCN 15 (`seed` in `tests/test_verdict_golden.lua`, CCN
18), which the tag gate forbids, and commit `55a7c6dc` split it in three with no case changed.

**Where it ran.** The run's branch is checked out in a git worktree, where `.git` is a file, and
the vendored runner refuses a root without a `.git` directory. So the run was taken in a fresh
`git clone` of the same branch at the same commit, under a folder named `LibKa0s`, and the bundle
and `RESULTS.md` were copied back unchanged. The manifest's `sha` and `dirty` are the clone's, and
the clone's tree is this commit's. The refusal is a kit limitation, reported for a kit fix and not
patched here (`tests/_kit/` is vendored).

## Suites

| Suite | Status | Result | Artifact | Moved since 20261126-131708 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 421 files | [`lint.txt`](lint.txt) | 394 -> 421 files |
| tests | pass | 5544 passed, 3 skipped, 0 failed, 5547 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 5263 -> 5544 passed |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | NLOC +7661, functions +960; Avg CCN 2.1 -> 2.2 |

| Metric | Value |
|---|---|
| Total NLOC | 125259 |
| Functions | 17834 |
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

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5544
passed, 0 failed, 3 skipped, 5547 total. The seed tool's own cases, `python3 -m pytest -q tools/seeds`,
ran outside the runner too: 18 passed.

## What moved

- **Payload:** eleven new files, loaded by `LibKa0s.xml` directly after `ForeverDB.lua`: `Verdict.lua`
  and its ten secondaries (`VerdictConstants`, `VerdictClassData`, `VerdictTierTokens`,
  `VerdictEvaluate`, `VerdictReads`, `VerdictCollect`, `VerdictFacts`, `VerdictScore`, `VerdictGear`,
  `VerdictSettings`), each minor 1, key 1.1.1.1.1.1.1.1.1.1.1. `DebugLogDiagnostics.lua` minor 12 ->
  13 (the report names Verdict). No `NEEDS_*` floor rises.
- **Contract changes:** `docs/api/Verdict/version-1.1.1.1.1.1.1.1.1.1.1-docs.md` and its manifest are
  new; `docs/api/DebugLog/version-23.13.1.5-docs.md` supersedes 23.12.1.5. Additive only.
- **Lint:** 394 -> 421 files: the eleven payload files and sixteen new suite and fixture files.
- **Tests:** 5263 -> 5544 passed: the Verdict suites (`tests/test_verdict*.lua`, Drop Watcher's kernel,
  facts, scoring, gear, collection and settings cases ported, with the golden table and the plan's
  review focus cases). The three skips are unchanged, declared skips, not passes.
- **Complexity:** NLOC 117598 -> 125259 and functions 16874 -> 17834, the new major and its suites.
  Avg CCN 2.1 -> 2.2, Avg tokens 61.1 -> 61.9: the moved engine is a little denser than the
  library's average. Max CCN still 15, 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_verdict_kernel.lua` | 1092 | **New to the band at `IS-B1`**: Drop Watcher's kernel suites, ported whole. Accepted, case count rather than tangle; a suite, so a peel is no release. Seam: the WoW Forever list section, to a suite of its own. Re-check trigger 1250 lines. |
| 1000–1500 (on notice) | the twelve other files [`../RESULTS.md`](../RESULTS.md) lists | see there | The same twelve as the previous run, each disposition carried; none moved. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-27, by hand
- **Files reviewed:** none needed: no Sim file and not `Widgets.lua` moved in this release.
- **Commits since the previous release touching them:** 0.
- **Note:** the release adds the Verdict major and moves DebugLogDiagnostics 13 only.

## Actions

1. Tag `v1.119.0` on this record commit only at the owner's go-ahead (task G1 of Drop Watcher's plan).
2. Drop Watcher re-vendors this build and moves onto the major (task C1); Ka0s Item Search vendors it
   from its first commit (tasks C2 and C3).
3. New here: the vendored runner refuses a git worktree (`.git` a file, not a directory); the fix
   belongs in `testkit/run-automated-tests.sh`, a test such as `-e .git` or `git rev-parse`.
