# Analysis — 20261123-231747

- **Addon:** LibKa0s 1.111.0 (release run, `--release 1.111.0`; `addonVersion` reads 1.110.0, the tag
  the runner's `git describe` found nearest this commit, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `79bb51a5` (`feat/2026-11-23-strip-right-click`), clean: the whole v1.111.0 release but
  its own record. The record (this bundle, its `RESULTS.md` row and the changelog's release-gate and
  re-look lines) follows as one commit, and the local tag `v1.111.0` is cut on it.
- **Previous run:** [`20261122-101023`](../20261122-101023/) (at `8deb4b0`, the v1.110.0 release record)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.111.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.111.0 was verified
across **three** suites, not four.

Since v1.110.0 the release adds WidgetsDragHandle minor 17 (a strip with the settings mark and no
`onRightClick` answers a right-click with the settings mark's own action), so lint gains one file and
the suite nine cases. Nothing to act on in the library; the actions below are the release's own next
steps.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261122-101023 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 384 files | [`lint.txt`](lint.txt) | Files 383 -> 384; still 0/0 |
| tests | pass | 5124 passed, 3 skipped, 0 failed, 5127 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Total 5118 -> 5127 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Totals grew; averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 114451 |
| Functions | 16466 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 11 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5124
passed, 0 failed, 3 skipped, 5127 total.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** one file changed, `LibKa0s/WidgetsDragHandle.lua` 16 -> 17 (998 lines): the strip
  resolves its right-click once at build (`dhRightClick`) for the strip and every mark, the host's
  `onRightClick`, else the settings mark's action, else none. Four older header notes were condensed
  so the file stays out of the 1000–1500 band. No `NEEDS_*` floor rises and no member is added or
  removed.
- **Contract changes:** behavioral, on one field. A strip with a gear and no `onRightClick`, which
  through 16 registered no click, now answers a right-click. Widgets key 30.3.7.17.3.8.8.6.1.2 has
  its document and members manifest; the 30.3.7.16 document is Superseded with its *Moving to*
  section.
- **Lint:** 383 -> 384 files, the new suite `tests/test_widgets_draghandle_rightclick.lua`; still 0/0.
- **Tests:** 5118 -> 5127 (+9), the new suite's cases (six red under minor 16). The three skips are
  unchanged, declared skips, not passes.
- **Complexity:** NLOC 114347 -> 114451 and functions 16439 -> 16466, the new suite and
  `dhRightClick`. Averages are flat. Max CCN is still 15, with 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, the same eleven as the previous run, each disposition carried. `WidgetsDragHandle.lua` (998) is not in the band. |

## Preview and simulation data

- **Answer:** Not applicable
- **Asked:** 2026-11-23, by hand
- **Files reviewed:** none needed. The release moved no minor of `Sim.lua`, `SimTimeline.lua`,
  `SimPanel.lua`, `SimPanelRender.lua` or `Widgets.lua` (the file that defines `W.TestStrip`).
- **Commits since the previous release touching them:** 0
- **Note:** only `WidgetsDragHandle.lua` moved. A strip's right-click is not test or sim data, so no
  scenario or test-mode strip changes, and step 8 lists no host for a re-look.

## Actions

1. Cut the local tag `v1.111.0` on the record commit. Pushing it, merging to `master` and the
   re-vendor wait on the owner's go-ahead (Ka0sAddonsCommonTasks
   `docs/2026-11-23-STRIP_RIGHT_CLICK/`).
2. Re-vendor every addon with an unlock strip (the bundle's audit table). KickCD and Quick Comms drop
   the `onRightClick` that opens their root page; Aura Master and Range Master may drop theirs as
   redundant. Re-pin `WidgetsDragHandle 16` where a host pins it.
