# Analysis — 20261106-191446

- **Addon:** LibKa0s 1.91.0 (release run, `--release 1.91.0`; the manifest's `addonVersion` reads
  1.90.0 because `v1.90.0` is still the newest tag when the run starts)
- **Verdict:** green
- **Commit:** `1938837` (`feat/2026-11-06-followups-v1-91`), clean: `FU-L3`'s first commit, every
  version-bearing line moved to v1.91.0 over `FU-L1` (the line chart's pixel lines) and `FU-L2` (the
  four band-file peels). The release's record (this bundle, its `RESULTS.md` row and the changelog's
  release lines) follows it as the second commit, and the tag is cut on that commit. The battery ran
  in the main checkout.
- **Previous run:** [`20261106-155947`](../20261106-155947/) (at `104b7ec`), v1.90.0's refreshed
  release run, which is also the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.91.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.91.0 was verified
across **three** suites, not four. Nothing to act on before the tag.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261106-155947 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 313 files | [`lint.txt`](lint.txt) | Yes: 307 -> 313 files |
| tests | pass | 4211 passed, 3 skipped, 0 failed, 4214 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4212 -> 4214 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count, band |

| Metric | Value |
|---|---|
| Total NLOC | 94056 |
| Functions | 13523 |
| Avg NLOC / function | 6.9 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass. It is a standing skip, because the library ships no
offline scenarios (see *Perf* in `RESULTS.md`). It is not measured, and not passed.

## What moved

Against [`20261106-155947`](../20261106-155947/) (v1.90.0): the three follow-ups that run left open,
Ka0sAddonsCommonTasks `docs/2026-11-06-FOLLOWUPS_V1_91/00_PLAN.md`.

- **`FU-L1`** (`55d3b0f`): WidgetsLineChart minor 7 draws the chart's axis, grid, markers and
  crosshair one physical pixel thick, and a series `thickness` physical pixels (1.5 by default),
  re-laid on a scale change with no render, through Core minor 16's `__PixelSize`, `__WatchPixels`
  and `__OnPixelScale`.
- **`FU-L2`** (`d72dc4a`, `c1ed261`, `acc9640`, `3f7be30`): four pure moves, no behaviour change.
  `Core.lua` 1080 -> 949 (the pixel edges to `CorePixel.lua`, 162), `Widgets.lua` 1312 -> 559 (the
  dropdown and its shared menu to `WidgetsDropdown.lua`, 805), `SkinPaintExtras.lua` 1217 -> 922 (the
  confirmation box to `SkinAceConfirm.lua`, 189, and the HUD's shared looks to `SkinPaintHud.lua`,
  169), and `tests/test_toast.lua` 1302 -> 760 (the stack cases to `tests/test_toast_stack.lua`, 495,
  and the bench to `tests/fixture_toast.lua`, 89).
- Lint: 307 -> 313 files, the six new files above. Still 0/0.
- Tests: 4212 -> 4214, the two line-chart cases `FU-L1` added to
  `tests/test_widgets_pixel_edges.lua` (per [`test-cases.md`](test-cases.md)); both were red on
  v1.90.0's code. The peels added no case: `test_toast.lua`'s 91 are now 55 there and 36 in
  `test_toast_stack.lua`. The three skips are v1.89.0's, still declared skips, not passes.
- Complexity: 93873 -> 94056 NLOC and 13512 -> 13523 functions, from the line chart's pixel helpers
  and the peeled files' own headers and kit hand-offs. Averages unchanged. The new line-chart
  functions are well under the gate: `pxOf` CCN 4, `thick` 5, `chartsRefresh` 4, `chartsListener` 3,
  `watchChart` 4 and `seg` 3; the busiest moved function is `lib.__WatchPixels` at 13, unchanged by
  the move (per [`complexity.txt`](complexity.txt)).

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Thirteen, down from seventeen, nothing over 1500. The four that left are exactly the four `FU-L2`
peeled: `LibKa0s/Core.lua`, `LibKa0s/Widgets.lua`, `LibKa0s/SkinPaintExtras.lua` and
`tests/test_toast.lua`, which closes v1.90.0's standing gaps (Core's missing entry, Widgets' and
`test_toast.lua`'s missing rulings, SkinPaintExtras' fired trigger). None of the six new files is in
the band; the largest is `LibKa0s/WidgetsDropdown.lua` at 805. `tests/test_debuglog.lua` reads 1002,
two lines over its accepted 1000, from `FU-L2`'s file-list lines; its census ruling stands.

## Preview and simulation data

- **Answer:** Current
- **Files reviewed:** `Widgets.lua`'s minor moved (26), and it is the file that defines
  `W.TestStrip`. Re-read against the change: the strip's lines in `Widgets.lua` are v1.90.0's apart
  from line endings, `tests/test_widgets_teststrip.lua` passes unchanged, and the Widgets
  26.1.6.13.7.8.5 document keeps the strip's contract. `tests/fixture_sim_panel.lua` and
  `tests/test_sim_isolation.lua` only load `WidgetsDropdown.lua` beside `Widgets.lua`. No `Sim.lua`,
  `SimTimeline.lua`, `SimPanel.lua` or `SimPanelRender.lua` minor moved. No host's scenarios or
  test-mode strips are affected.

## Actions

1. Cut the local tag `v1.91.0` on the commit that adds this bundle. It is pushed, and the branch
   merged, only at the owner's go-ahead.
2. Step 8: every roster addon re-vendors v1.91.0 (`FU-RV-<X>`). A host whose tests load library
   files by name adds `CorePixel.lua`, `WidgetsDropdown.lua`, `SkinPaintHud.lua` and
   `SkinAceConfirm.lua` beside the files they were peeled from, in the same commit.
