# Analysis — 20261124-194116

- **Addon:** LibKa0s 1.113.0 (release run, `--release 1.113.0`; `addonVersion` reads 1.113.0 because
  the local tag `v1.113.0`, then on the earlier record `cded10bb`, is the nearest `git describe`
  finds; `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `92cccaee` (`feat/2026-11-24-feedback-batch`), clean: the v1.113.0 release with the
  owner's ruling on the selection's color, `FB2-LK-04`, all but its own record. The record (this
  bundle, its `RESULTS.md` row and the changelog's release-gate line) follows as one commit, and the
  local tag `v1.113.0`, never pushed, moves onto it.
- **Previous run:** [`20261124-110824`](../20261124-110824/) (at `b4bca425`, the second v1.113.0
  record, which this run supersedes)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.113.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.113.0 was verified
across **three** suites, not four.

Since the second v1.113.0 record the selection rule changed, still WidgetsDropdown minor 4. The
owner's ruling of 2026-11-24: an owned menu's selected row is Ka0s Default's gold `1, 0.82, 0` in
every skin, and only where the gold stands under 20 CIEDE2000 off the skin's `menu.text` does the
skin's `menu.textSel` stand in (the gold again when that is under the floor too). The earlier rule
kept a skin's accent while it stood 20 off, so every addon on WoW Forever painted its selection in
that skin's tan `#C9A07A`, which the owner saw on Loot History's Character dropdown. No shipped skin
falls back: Azeroth's parchment is the nearest to the gold, at 20.7.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261124-110824 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 388 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 5184 passed, 3 skipped, 0 failed, 5187 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No (5187; three case names changed) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | NLOC +18, functions +1; averages flat but tokens 60.8 -> 60.9 |

| Metric | Value |
|---|---|
| Total NLOC | 115329 |
| Functions | 16566 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.9 |
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

- **Payload:** one file changed since `b4bca425`. `LibKa0s/WidgetsDropdown.lua` (976 lines, out of
  the band): `distinctSel` answers the gold first, the skin's `menu.textSel` only where the gold
  sits under the floor off `menu.text`; the shared menu's palette and `lib.SelectedColor(owner)` read
  it, and a title row keeps the raw `menu.textSel`. The comments (the minor-4 header note, THE
  SELECTION'S CONTRAST) say the new rule. No minor moves (minor 4 has not shipped), no member is
  added or removed, and no `NEEDS_*` floor rises.
- **Contract changes:** the selection's color in the Widgets 30.4.7.17.3.8.8.7.2.2 document, its
  predecessor's *Moving to* note and the api index; the members manifest is unchanged. Over the whole
  release: Sim minor 5 (every successful `Start` shows the step panel; `SampleCrowd` and
  `CROWD_MAX`) and WidgetsDropdown minor 4 (the selection's gold, ticked context-menu rows,
  `SelectedColor`).
- **Lint:** 388 files, 0/0, unchanged.
- **Tests:** 5187 total, unchanged. `tests/test_widgets_menu_selected.lua` keeps nine cases, with
  the pinned list inverted (skins whose `menu.text` sits too near the gold: none), the gold asserted
  for every shipped skin, and WoW Forever's case (gold selection, title row on its raw accent) in
  place of Azeroth's. Red first against the old rule: 5177 passed, 7 failed. One case in
  `tests/test_widgets_skin.lua` re-pins Obsidian's selected row at the gold. The three skips are
  unchanged, declared skips, not passes.
- **Complexity:** NLOC 115311 -> 115329 and functions 16565 -> 16566 (the test file's `fallsBack`).
  Max CCN is still 15, with 0 warnings.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the eleven files [`../RESULTS.md`](../RESULTS.md) lists | see there | Eleven, nothing over 1500, the same eleven as the previous run, each disposition carried. `WidgetsDropdown.lua` (976) is not in the band. |

## Preview and simulation data

- **Answer:** Unchanged since `20261124-104546`
- **Asked:** 2026-11-24, by hand
- **Files reviewed:** no Sim file and not `Widgets.lua` (the file that defines `W.TestStrip`) moved
  since the previous record; the first record's re-look stands.
- **Commits since the previous release touching them:** none since `220a596c`.

## Actions

1. Move the local tag `v1.113.0` onto this record commit (it was never pushed; `v1.112.0` stays at
   `1f1904ee`). Pushing it, merging to `master` and the re-vendor wait on the owner's go-ahead
   (Ka0sAddonsCommonTasks `docs/2026-11-24-FEEDBACK_BATCH/`).
2. Each addon re-vendors v1.113.0 again: under any skin but Ka0s Default a dropdown's selected row
   turns from the skin's accent to the gold, so every addon's smoke line reads "the selected row is
   gold" (WoW Forever first, Loot History's Character dropdown). An addon that draws its own menu or
   picker list paints its selected row in `W.SelectedColor(owner)`, never the raw `menu.textSel`
   (WowAddonStandards v2.120.0, skinning-§4), and a host suite that pinned a selection at a skin's
   `menu.textSel` re-pins it at the gold.
