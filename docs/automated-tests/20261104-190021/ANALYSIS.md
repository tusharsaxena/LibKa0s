# Analysis — 20261104-190021

- **Addon:** LibKa0s 1.86.0 (release run, `--release 1.86.0`; the manifest's `addonVersion` reads
  1.85.0 because it is taken from the newest tag, and `v1.86.0` is cut after this bundle)
- **Verdict:** green
- **Commit:** `3b69e82` (`feat/2026-11-04-icon-browser`), clean: the `Src.Tabs` peel, with nothing
  but this record after it
- **Previous run:** [`20261104-185100`](../20261104-185100/) (at `d78f4d1`), this release's first
  battery, which found one function over CCN 15. The baseline for *What moved* below is v1.85.0's
  release run, [`20261104-024106`](../20261104-024106/) (at `0dfe377`).

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.86.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.86.0 was verified
across **three** suites, not four. Nothing to act on before the tag.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261104-185100 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 305 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 4141 passed, 3 skipped, 0 failed, 4144 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: max CCN 17 -> 15, warnings 1 -> 0 |

| Metric | Value |
|---|---|
| Total NLOC | 92405 |
| Functions | 13322 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.1 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 15 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, because the library ships no
offline scenarios (see *Perf* in `RESULTS.md`). It is not measured, not passed.

## What moved

Against [`20261104-024106`](../20261104-024106/) (v1.85.0): the icon browser's promotion from Ka0s
Quick Comms (OutfitterReborn `docs/superpowers/plans/2026-11-04-sheet-window-feedback.md`, M1).

- **A new major, `LibKa0s-IconBrowser-1.0`, key 1.1.1** (`566d981`, `13a2d4b`, `38bdca4`, `cad00dc`):
  `IconBrowserSources.lua` (tabs as descriptors), `IconBrowserWindow.lua` and `IconBrowser.lua`
  (`IB:New(spec)`, a browser per host). **DebugLogDiagnostics minor 7** names it on the report's
  `LibKa0s running:` line. Every other key is unchanged from v1.85.0; kit revision 50, no kit file
  moved.
- **Smoke round 7** (`06eae81`, merged after v1.85.0's tag): the Sim mode rule's cases, no minor moved.
- **The release commit** (`d78f4d1`): docs, pointers, the consumer census and the regenerated case
  list; no code.
- **The peel** (`3b69e82`): the first battery measured `Src.Tabs` at CCN 17; its host-tab loop is a
  local `hostTabs` now, with no behavior change. Minor 1 has not shipped, so it does not move.
- Lint: 298 -> 305 files (the three new payload files and four new suites, the fixture among them).
- Tests: 4072 -> 4144, 72 cases more: 68 in the three new icon browser suites
  (`test_icon_browser_sources.lua` 26, `test_icon_browser.lua` 28, `test_icon_browser_search.lua` 14,
  per [`test-cases.md`](test-cases.md)), and 4 from smoke round 7's `R7-L1` merged after v1.85.0's tag
  (`test_launcher.lua` 56 -> 57, `test_options_compose_sim.lua` 16 -> 19). The three skips are v1.85.0's: the declined kit prose gate,
  the diagnostics opt-out case and `test_skin_values`, still declared skips, not passes.
- Complexity: 89793 -> 92405 NLOC and 12977 -> 13322 functions as the library grew; avg NLOC 6.8 and
  avg CCN 2.1 unchanged, avg tokens 59.8 -> 60.1. That is growth, not density.

## Complexity watch list

### Functions the complexity suite warned on

None. `Src.Tabs` is under the cap after the peel.

### Files by `layout-§1` band

Fifteen, the same fifteen as v1.85.0, nothing over 1500. The three new payload files are out of the
band (`IconBrowser.lua` 958, `IconBrowserSources.lua` 563, `IconBrowserWindow.lua` 377) and no
band file moved. `LibKa0s/Widgets.lua` (1058) still has a blank Disposition, as it did at v1.85.0;
that is a standing gap for the lead, not something this release introduced.

## Preview and simulation data

- **Answer:** Not applicable
- **Files reviewed:** no `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`, `SimPanelRender.lua` or
  `Widgets.lua` minor moved, so step 5's re-look has nothing to re-read and names no hosts.

## Actions

1. Tag `v1.86.0` on the commit that adds this bundle, on `feat/2026-11-04-icon-browser`, and push
   the branch and the tag (the owner's ruling for this run). The merge to `master` waits for the
   owner.
2. Step 8: Quick Comms (M2) and Outfitter Reborn (M3) re-vendor from the tag; the other hosts take
   v1.86.0 at their next re-vendor, since no surface they call moved.
3. In-client smoke of the icon browser is the owner's (CP4), and none is marked passed here.
