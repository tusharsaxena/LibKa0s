# Analysis — 20261105-064630

- **Addon:** LibKa0s 1.88.0 (release run, `--release 1.88.0`; the manifest's `addonVersion` reads
  1.87.0 because it is taken from the newest tag, and `v1.88.0` is cut after this bundle)
- **Verdict:** green
- **Commit:** `1fdaed5` (`feat/2026-11-05-toast-stack`), clean: the release's pointers and consumer
  sweep, with nothing but this record after it. The battery ran in a clean clone of that commit,
  because the kit's library path asks for a `.git` directory and the branch's worktree has a `.git`
  file; the sha, branch and `dirty: false` in the manifest are that commit's.
- **Previous run:** [`20261105-030351`](../20261105-030351/) (at `95feb1b`), v1.87.0's release run,
  which is also the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.88.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.88.0 was verified
across **three** suites, not four. Nothing to act on before the tag.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261105-030351 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 306 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 4196 passed, 3 skipped, 0 failed, 4199 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4162 -> 4199 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: band files 15 -> 16 |

| Metric | Value |
|---|---|
| Total NLOC | 93469 |
| Functions | 13460 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 16 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, because the library ships no
offline scenarios (see *Perf* in `RESULTS.md`). It is not measured, not passed.

## What moved

Against [`20261105-030351`](../20261105-030351/) (v1.87.0): stacked toasts for Ka0s Drop Watcher
(its issue #14, `LK-T1`).

- **Toast minor 4, key 4** (`ef66de6`, `3ad83c2`, `2119e27`, `2f7d940`, `ff2c4f8`): the opt-in stack
  (`stack`, `stackGrow`, `stackGap`, `SetStack`, `Visible`, `FrameFor`), then four fixes inside the
  unreleased minor: a drag holds every countdown, `Refresh` hands the stack back to the descriptor,
  `Attach` before the first `Show` builds the first frame, and a toast sent back to wait drops no
  payload. `LibKa0s/Toast.lua` is the only payload file that moved; every other key is unchanged
  from v1.87.0; kit revision 50, no kit file moved.
- **Docs only** (`835e8e2`, `1fdaed5`): the README, the release guide, the consumers census and the
  version pointers; no code.
- Lint: 306 files, unchanged (no file added).
- Tests: 4162 -> 4199, 37 cases more, all in `test_toast.lua` (54 -> 91 running cases, per
  [`test-cases.md`](test-cases.md)). The three skips are v1.87.0's, still declared skips, not passes.
- Complexity: 92851 -> 93469 NLOC and 13385 -> 13460 functions; avg NLOC 6.8 and avg CCN 2.1
  unchanged, avg tokens 60.1 -> 60.2. `LibKa0s/Toast.lua`'s highest function is still `playSound`
  at CCN 10; the stack's new `draw` and `applyLayout` are 8.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Sixteen, nothing over 1500. **`tests/test_toast.lua` came in at 1302** with `LK-T1`'s stack cases;
its Disposition in `RESULTS.md` says it is unruled, a suite whose peel is no release, its seam and
re-check trigger the lead's call. `LibKa0s/Toast.lua` (725) is out of the band. `LibKa0s/Widgets.lua`
(1249) still has a blank Disposition, as at v1.85.0, v1.86.0 and v1.87.0; a standing gap for the
lead, not something this release introduced. No other band file moved.

## Preview and simulation data

- **Answer:** Not applicable
- **Files reviewed:** no `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`, `SimPanelRender.lua` or
  `Widgets.lua` minor moved (`git diff --stat 95feb1b 1fdaed5 -- LibKa0s/` names `Toast.lua` alone),
  so step 5's re-look has nothing to re-read and names no hosts.

## Actions

1. Tag `v1.88.0` on the commit that adds this bundle. The merge to `master` and any push wait for
   the owner.
2. Step 8: Drop Watcher re-vendors from the tag and takes the stack (its issue #14); the other hosts
   take v1.88.0 at their next re-vendor, since no surface they call moved.
3. `tests/test_toast.lua`'s band entry (1302 lines) and `LibKa0s/Widgets.lua`'s blank Disposition
   (1249 lines) are the lead's rulings.
4. In-client smoke of the stack is the owner's, and none is marked passed here.
