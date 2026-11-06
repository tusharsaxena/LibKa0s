# Analysis — 20261106-142901

- **Addon:** LibKa0s 1.90.0 (release run, `--release 1.90.0`; the manifest's `addonVersion` reads
  1.89.0 because it is taken from the newest tag, and `v1.90.0` is cut after this bundle)
- **Verdict:** green
- **Commit:** `4ac9f3c` (`feat/2026-11-06-revendor-libka0s-v1-89`), clean: the release's pointers and
  consumer sweep, with nothing but this record after it. The battery ran in the main checkout.
- **Previous run:** [`20261105-234356`](../20261105-234356/) (at `f11b9c0`), v1.89.0's release run,
  which is also the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.90.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.90.0 was verified
across **three** suites, not four. Nothing to act on before the tag.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261105-234356 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 307 files | [`lint.txt`](lint.txt) | Yes: 306 -> 307 files |
| tests | pass | 4205 passed, 3 skipped, 0 failed, 4208 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4200 -> 4208 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count, band count |

| Metric | Value |
|---|---|
| Total NLOC | 93751 |
| Functions | 13501 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 17 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, because the library ships no
offline scenarios (see *Perf* in `RESULTS.md`). It is not measured, not passed.

## What moved

Against [`20261105-234356`](../20261105-234356/) (v1.89.0): the owner's first smoke feedback on the
v1.89.0 re-vendor (Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/SF1_SMOKE_FEEDBACK.md`).

- **`SF1-L1`** (`7d42f4e`): every Widgets edge of 1 UI unit is one physical pixel. Core minor 16
  takes the pixel size and watch the Skin major had, and adds `__PixelBackdrop`; Widgets minor 24
  and WidgetsAutocomplete minor 8 pass the dropdown, the search box, every menu level and the list
  to it; SkinPaint minor 19 and SkinPaintExtras minor 18 call Core's and size a non-flat holder edge
  on such a frame in physical pixels.
- **`SF1-L2`** (`b9f7651`): Skin minor 17's `RegisterOwner` `keepScope`, which OptionsAppearance
  minor 7's `lib.__copySkinTo` honors: skin and media copied, the Scope never written.
- **Docs only** (`4ac9f3c`): the version lines, the standards pointer (v2.101.0 -> v2.102.2), the
  step 9 sweep record and the regenerated case list; no code.
- Lint: 306 -> 307 files, the new `tests/test_widgets_pixel_edges.lua`.
- Tests: 4200 -> 4208, eight cases more: the seven of `tests/test_widgets_pixel_edges.lua` and
  `tests/test_options_appearance_overrides.lua`'s *a copy carries skin and media to an owner
  registered keepScope, never its Scope* (per [`test-cases.md`](test-cases.md)). Each was red against
  the v1.89.0 payload before its change. The three skips are v1.89.0's, still declared skips, not
  passes.
- Complexity: 93505 -> 93751 NLOC and 13463 -> 13501 functions (Core's pixel section and the new
  cases' closures); avg NLOC 6.9 -> 6.8 by rounding, avg CCN 2.1 and avg tokens 60.2 unchanged. The
  new `P.pxEdge` measures CCN 8. `P.box` stays at CCN 15: the new call took it to 17 in a pre-commit
  measurement, and choosing the backdrop's edge with one `if` instead of two `and`/`or` pairs
  brought it back.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Seventeen, nothing over 1500. `LibKa0s/Core.lua` (1080) came in with Core minor 16's pixel edges,
unruled, its seam named in `CLAUDE.md`'s band census. `LibKa0s/Widgets.lua` (1263) is still unruled.
`LibKa0s/SkinPaintExtras.lua` fell to 1217, but the minor half of its trigger fired again at minor
18 and the file stays unpeeled, the lead's and the owner's call. `LibKa0s/Skin.lua` (1098) and
`LibKa0s/SkinPaint.lua` (1048, no function added) stay under their triggers. `tests/test_toast.lua`
(1302) is still unruled. These are standing gaps for the lead, two of them (`Core.lua`'s entry and
`SkinPaintExtras.lua`'s fired trigger) arriving with this release.

## Preview and simulation data

- **Answer:** Current
- **Files reviewed:** `Widgets.lua`'s minor moved (24), the file that defines `W.TestStrip`. Re-read
  against the change: `tests/test_widgets_teststrip.lua` and the Widgets 24.5.12.6.8.5 document. The
  strip draws no backdrop and is not passed to `__PixelBackdrop`, so `SF1-L1` does not reach it, and
  its cases pass unchanged. No `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua` or `SimPanelRender.lua`
  minor moved. No host's scenarios or test-mode strips are affected.

## Actions

1. Tag `v1.90.0` locally on the commit that adds this bundle. It is pushed, and the branch merged,
   only at the owner's go-ahead.
2. Step 8: every roster addon re-vendors from the tag (`SF1-RV-<X>`), and Ka0s Skin Tester registers
   with `keepScope = true` (`SF1-ST`).
3. `LibKa0s/Core.lua`'s band entry, `LibKa0s/Widgets.lua`'s and `tests/test_toast.lua`'s rulings, and
   `LibKa0s/SkinPaintExtras.lua`'s peel remain the lead's calls.
