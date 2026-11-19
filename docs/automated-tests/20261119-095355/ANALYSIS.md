# Analysis — 20261119-095355

- **Addon:** LibKa0s 1.106.0 (release run, `--release 1.106.0`; `addonVersion` reads 1.105.0, the tag
  the runner's `git describe` found nearest this commit, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `d9cd43b` (`feat/2026-11-19-hud-dock-guard`), clean: the whole v1.106.0 release but
  its own record. Since v1.105.0 the branch gained one commit, the HUD dock's guarded measurements
  (`Widgets.lua` minor 27 -> 28, RangeMaster#17), with its test, API document, members manifest,
  changelog block, `docs/releasing.md` and `README.md` lines and the regenerated case list. The
  record (this bundle, its `RESULTS.md` row and the changelog's two fixed lines) follows as one
  commit; none of it is read by a suite.
- **Previous run:** [`20261117-113302`](../20261117-113302/) (at `12cf13d`), the v1.105.0 release run.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.106.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.106.0 was verified
across **three** suites, not four. No function is above CCN 15, so no split was needed.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261117-113302 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 372 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 4945 passed, 3 skipped, 0 failed, 4948 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4947 -> 4948 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 111171 |
| Functions | 15943 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** one file. `Widgets.lua` (minor 27 -> 28): the HUD dock's every measurement
  (`GetTop`, `GetBottom`, `GetHeight`, `GetEffectiveScale` of the target, the clear frame, the strip
  and UIParent) goes through a guarded `measure`, so a read the client refuses on a region anchored
  to a nameplate answers nil and the strip docks unflipped instead of raising. No kit file changed.
- **Contract changes:** the Widgets key moves to 28.2.7.14.1.7.8.6.1.1 (its document and members
  manifest). No member moved, so the members manifest lists the same surface.
- **Lint:** 372 files, unchanged.
- **Tests:** 4947 -> 4948 (4944 -> 4945 run): `tests/test_widgets_teststrip_dock.lua` gains the
  refused-measure case, red under minor 27 (checked by running the suite against the minor-27 file:
  it failed with the client's own message). The three skips are still declared skips, not passes.
- **Complexity:** NLOC 111148 -> 111171 and functions 15939 -> 15943 (the `measure` helper and the
  test's closures). Avg NLOC, avg CCN, avg tokens and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the thirteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Unchanged by this release. `LibKa0s/Widgets.lua` grows 924 -> 942 and stays out of the band |

Thirteen, nothing over 1500.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-19, by hand
- **Files reviewed:** `LibKa0s/Widgets.lua`'s docking section, `tests/test_widgets_teststrip.lua`,
  `tests/test_widgets_teststrip_dock.lua` and the new `docs/api/Widgets/` document.
- **Commits since the previous run touching them:** 1 (`d9cd43b`)
- **Note:** the strip's text, colors and flavors do not move; only where a refused measurement
  leaves it. The host the change affects is Ka0s Range Master (its nameplate containers' strips),
  named for step 8.

## Actions

1. Tag `v1.106.0` on the record commit, merge to `master` and push (the owner asked for the full
   release, 2026-11-19).
2. Re-vendor every consumer (step 8). A host owes nothing beyond the copy and the provenance line; a
   suite that pins `Widgets 27` re-pins it at 28. Range Master drops its hand-anchored plate strip.
3. **Standards pointer:** v2.112.2 -> v2.114.0. v2.113.0, v2.113.1 and v2.114.0 bind hosts (the
   v1.105.0 surfaces at adoption, the roster, the tagged drag handle as a preview marker); none moves
   a rule `library-stack-§7` applies here.
4. **Kit note**, carried: `tests/_kit/run-automated-tests.sh` refuses a git worktree, so release runs
   need the main checkout or a clean clone.
