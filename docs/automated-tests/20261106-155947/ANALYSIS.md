# Analysis — 20261106-155947

- **Addon:** LibKa0s 1.90.0 (release run, `--release 1.90.0`, the refresh of the local tag; the
  manifest's `addonVersion` reads 1.90.0 because the first cut's `v1.90.0` is already the newest tag)
- **Verdict:** green
- **Commit:** `104b7ec` (`feat/2026-11-06-revendor-libka0s-v1-89`), clean: `SF2-L1`, the three
  remaining one-UI-unit lines. The refresh's record (`SF2-L2`: this bundle, the changelog's release
  lines, `docs/releasing.md`'s refresh paragraph and the regenerated `docs/test-cases.md`) follows it
  as one commit, and the tag moves to that commit. The battery ran in the main checkout.
- **Previous run:** [`20261106-142901`](../20261106-142901/) (at `4ac9f3c`), the first cut's release
  run, which is also the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.90.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.90.0 was verified
across **three** suites, not four. Nothing to act on before the tag moves.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261106-142901 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 307 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 4209 passed, 3 skipped, 0 failed, 4212 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4208 -> 4212 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 93873 |
| Functions | 13512 |
| Avg NLOC / function | 6.9 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 17 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass. It is a standing skip, because the library ships no
offline scenarios (see *Perf* in `RESULTS.md`). It is not measured, and not passed.

## What moved

Against [`20261106-142901`](../20261106-142901/) (v1.90.0's first cut): the owner's request in
Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/SF2_REMAINING_EDGES.md`.

- **`SF2-L1`** (`104b7ec`): the shared menu's divider rule (every cascade depth), the ReorderList
  row boxes and the DragHandle strips are one physical pixel at any UI scale and re-size on a scale
  change. Widgets minor 25 adds the internal `lib.__pixelLine`, built on Core minor 16's
  `__PixelSize`, `__WatchPixels` and `__OnPixelScale`; WidgetsReorder minor 6 and WidgetsDragHandle
  minor 13 draw their edges through it. No `NEEDS_*` floor rises and no Skin file moves. The Widgets
  key is now 25.6.13.6.8.5, and its document replaces the unreleased 24.5.12.6.8.5 one.
- Lint: 307 files, unchanged. The new cases went into the existing
  `tests/test_widgets_pixel_edges.lua`.
- Tests: 4208 -> 4212, the four *pixel lines* cases of `tests/test_widgets_pixel_edges.lua` (per
  [`test-cases.md`](test-cases.md)). All four were red on the first cut's code before the change. The
  three skips are v1.89.0's, still declared skips, not passes.
- Complexity: 93751 -> 93873 NLOC and 13501 -> 13512 functions, from the pixel-line helpers and the
  new cases' closures. Avg NLOC 6.8 -> 6.9 and avg tokens 60.2 -> 60.3; avg CCN 2.1 unchanged. The
  new and touched functions are well under the gate: `pixelLine` CCN 7, `pxLineApply` 4,
  `sizeRowBox` 5, `paintRowBox` 9, `paintRowKind` 9 and `dhDrawEdge` 7 (per
  [`complexity.txt`](complexity.txt)).

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Seventeen, nothing over 1500, the same seventeen as the first cut. `LibKa0s/Widgets.lua` grew to
1312 at minor 25 and is still unruled, 188 under the cap. `LibKa0s/WidgetsDragHandle.lua` is at 1022
at minor 13, under its 1100 trigger. `LibKa0s/WidgetsReorder.lua` (802) stays out of the band. The
first cut's standing gaps are unchanged: `LibKa0s/Core.lua`'s entry, `LibKa0s/Widgets.lua`'s and
`tests/test_toast.lua`'s rulings, and `LibKa0s/SkinPaintExtras.lua`'s fired trigger.

## Preview and simulation data

- **Answer:** Current
- **Files reviewed:** `Widgets.lua`'s minor moved again (25). It is the file that defines
  `W.TestStrip`. Re-read against the change: `tests/test_widgets_teststrip.lua` and the Widgets
  25.6.13.6.8.5 document. The strip draws no backdrop, no menu divider, no row box and no
  drag-handle edge, so `SF2-L1` does not reach it, and its cases pass unchanged. No `Sim.lua`,
  `SimTimeline.lua`, `SimPanel.lua` or `SimPanelRender.lua` minor moved. No host's scenarios or
  test-mode strips are affected.

## Actions

1. Move the local tag `v1.90.0` to the commit that adds this bundle. It is pushed, and the branch
   merged, only at the owner's go-ahead.
2. Step 8 again: every roster addon re-copies the refreshed tag (`SF2-RV-<X>`), and smoke `SM-12`
   checks the three lines in game.
3. The first cut's band rulings remain the lead's calls.
