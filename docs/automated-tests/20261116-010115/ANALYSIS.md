# Analysis — 20261116-010115

- **Addon:** LibKa0s 1.102.0 (release run, `--release 1.104.0`; `addonVersion` is the tag the
  runner's `git describe` found nearest this commit, and `release` is the version this run is for.
  Both v1.102.0 and v1.103.0 are reachable after the merge; `describe` names the one with fewer
  commits between it and this one, `v1.102.0-7-g3235d426`)
- **Verdict:** green
- **Commit:** `3235d42` (`feat/2026-11-16-v1.104.0`), clean: the release's first commit. The branch
  was cut from `master` `e37c353` (v1.103.0), merged `feat/2026-11-14-callout-defaults` (v1.102.0,
  `2748549`) at `0f4e272`, and `3235d42` retires the register's three one-consumer rows, records each
  ruling in its major's API document, dates the `v1.104.0` heading in `CHANGELOG.md` and moves the
  `docs/releasing.md` and README pointers to v1.104.0 (the standards pointer stays at v2.110.0). The
  record (this bundle, its `RESULTS.md` row and the changelog's release lines) follows as one commit,
  and the tag is cut on that commit. The battery ran in the main checkout, named `LibKa0s`, because
  the runner refuses a worktree (its `.git` is a file).
- **Previous run:** [`20261115-133322`](../20261115-133322/) (at `fd70cbd`), v1.103.0's release run;
  v1.102.0's, [`20261114-163156`](../20261114-163156/) (at `715b291`), is the other parent's.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.104.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.104.0 was verified
across **three** suites, not four. No payload code changes against either parent tag: this run is
the first to measure v1.102.0's Callout and v1.103.0's Widgets in one tree.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261115-133322 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 347 files | [`lint.txt`](lint.txt) | No (347 files) |
| tests | pass | 4665 passed, 3 skipped, 0 failed, 4668 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4667 -> 4668 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 106113 |
| Functions | 15164 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 15 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

Against v1.103.0's run, v1.104.0 adds v1.102.0's change and nothing of its own in the payload:

- **Callout minor 4 and CalloutSettings minor 5** (Callout key 3.4 -> 4.5, as v1.102.0 shipped them):
  the owner's Look defaults and no sample line in the one tab. No other minor, no `NEEDS_*` floor and
  no kit revision moves (56). Widgets stays at minor 27.
- **Contract changes**: none against either tag. A host coming from v1.103.0 owes v1.102.0's two
  visible Callout changes (the defaults, `view.preview` nil in `layout = "side"`); one coming from
  v1.102.0 owes v1.103.0's Widgets members and the standard's v2.110.0 MUSTs.
- **Documents**: the register's three one-consumer rows (Options `Drawer`, `LibKa0s-Callout-1.0`,
  `LibKa0s-WaypointArrow-1.0`) are retired under WowAddonStandards v2.109.0, each ruling moved into
  its major's current API document; no document is superseded.
- Lint: 347 files, unchanged (the two parents' new suites were already counted on each side, and
  v1.102.0 added no file). Tests: 4667 -> 4668, the one case v1.102.0 added beside v1.101.0's
  4629. The three skips are still declared skips, not passes.
- Complexity: NLOC 106062 -> 106113 and functions 15162 -> 15164, v1.102.0's Callout changes; avg
  NLOC, avg CCN, avg tokens and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Callout.lua` | 1283 | v1.102.0's minor 4 (from 1277), 17 under the ~1300 split point, as `CLAUDE.md`'s census records |
| 1000–1500 (on notice) | the other fourteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged; none was touched |

Fifteen, nothing over 1500.

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-16, by hand
- **Files reviewed:** none needed: no Sim minor moves and Widgets stays at v1.103.0's minor 27;
  v1.102.0 moved neither
- **Commits since the previous release touching them:** 0
- **Note:** v1.103.0's re-look (the strip's docking) still binds every host re-vendoring from
  v1.102.0 or earlier.

## Actions

1. Cut the tag `v1.104.0` on the commit that adds this bundle, merge the branch to master, and
   delete `feat/2026-11-14-callout-defaults` (local and remote) and its worktree.
2. Step 8: Ka0s Combat Trail vendors v1.102.0 and lacks v1.103.0's Footer and docking; its next
   re-vendor takes v1.104.0. Every other host re-vendors on its own schedule.
3. **Standards pointer:** the live standard is v2.112.2; v2.112.0's tooltip placers are owed by the
   library first, and the README pointer moves with the release that builds them.
4. **Kit note**, carried from the previous run: `tests/_kit/run-automated-tests.sh` refuses a git
   worktree (`[ ! -d .git ]`), so release runs need the main checkout or a clean clone.
