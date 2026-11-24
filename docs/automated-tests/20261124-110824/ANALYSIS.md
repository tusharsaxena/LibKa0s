# Analysis — 20261124-110824

- **Addon:** LibKa0s 1.113.0 (release run, `--release 1.113.0`; `addonVersion` reads 1.113.0 because
  the local tag `v1.113.0`, cut on the earlier record `53a5b128`, is the nearest `git describe`
  finds; `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `b4bca425` (`feat/2026-11-24-feedback-batch`), clean: the v1.113.0 release with the
  independent review's fix `FB2-LK-REV`, all but its own record. The record (this bundle, its
  `RESULTS.md` row and the changelog's release-gate line) follows as one commit, and the local tag
  `v1.113.0`, never pushed, moves onto it.
- **Previous run:** [`20261124-104546`](../20261124-104546/) (at `220a596c`, the first v1.113.0
  record, which this run supersedes)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.113.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.113.0 was verified
across **three** suites, not four.

Since the first v1.113.0 record the release adds one lib-level member, `W.SelectedColor(owner)`
(still WidgetsDropdown minor 4): the color the shared menu paints an owner's selected row in, for a
host that draws its own menu. The review found that the contrast rule lived only inside the shared
menu's paint, so a host menu reading the raw `menu.textSel` token, as the standard told it to, kept
Azeroth's too-close accent.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261124-104546 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 388 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 5184 passed, 3 skipped, 0 failed, 5187 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Total 5186 -> 5187 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | NLOC +31, functions +2; averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 115311 |
| Functions | 16565 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 11 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

The suite was also run under `KA0S_KIT_CLIENT=forever` on the same tree, outside the runner: 5184
passed, 0 failed, 3 skipped, 5187 total.

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** one file changed since `220a596c`. `LibKa0s/WidgetsDropdown.lua` (967 lines, out of
  the band) gains `lib.SelectedColor(owner)`, which answers `r, g, b` from the same `distinctSel`
  the shared menu paints with, read at call time, and Ka0s Default's gold for an unregistered or
  missing owner. No minor moves (minor 4 has not shipped) and no `NEEDS_*` floor rises.
- **Contract changes:** one member added to the Widgets 30.4.7.17.3.8.8.7.2.2 document and its
  members manifest. Over the whole release: Sim minor 5 (every successful `Start` shows the step
  panel; `SampleCrowd` and `CROWD_MAX`) and WidgetsDropdown minor 4 (the selection's contrast, ticked
  context-menu rows, `SelectedColor`).
- **Lint:** 388 files, 0/0, unchanged.
- **Tests:** 5186 -> 5187 total (5183 -> 5184 passed): one case in
  `tests/test_widgets_menu_selected.lua` holds `W.SelectedColor` to the shared menu's own paint in
  every shipped skin, red before the member existed. The three skips are unchanged, declared skips,
  not passes.
- **Complexity:** NLOC 115280 -> 115311 and functions 16563 -> 16565. Max CCN is still 15, with 0
  warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, the same eleven as the previous run, each disposition carried. `WidgetsDropdown.lua` (967) is not in the band. |

## Preview and simulation data

- **Answer:** Unchanged since `20261124-104546`
- **Asked:** 2026-11-24, by hand
- **Files reviewed:** no Sim file and not `Widgets.lua` (the file that defines `W.TestStrip`) moved
  since the previous record; that record's re-look stands.
- **Commits since the previous release touching them:** none since `220a596c`.

## Actions

1. Move the local tag `v1.113.0` onto this record commit (it was never pushed; `v1.112.0` stays at
   `1f1904ee`). Pushing it, merging to `master` and the re-vendor wait on the owner's go-ahead
   (Ka0sAddonsCommonTasks `docs/2026-11-24-FEEDBACK_BATCH/`).
2. Each addon that draws its own menu or picker list (Combat Trail's character dropdown first)
   paints its selected row in `W.SelectedColor(owner)` at its re-vendor, never the raw `menu.textSel`
   (WowAddonStandards v2.120.0, skinning-§4).
