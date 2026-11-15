# Analysis — 20261115-133322

- **Addon:** LibKa0s 1.101.0 (release run, `--release 1.103.0`; `addonVersion` is the newest tag the
  runner's `git describe` found on this branch, and `release` is the version this run is for. v1.102.0
  is a tag on another branch, `feat/2026-11-14-callout-defaults`, and is not in this tree's history)
- **Verdict:** green
- **Commit:** `fd70cbd` (`feat/2026-11-15-window-chrome`), clean: the release's first commit, cut from
  `master` `0fb6fab` (v1.101.0). It carries Widgets minor 27 (the Footer and the strip's docking), its
  two new suites, the API document and manifest, the dated `v1.103.0` heading in `CHANGELOG.md`, and
  the `docs/releasing.md` and README pointers at v1.103.0 (the standards pointer at v2.110.0). The
  record (this bundle, its `RESULTS.md` row and the changelog's release lines) follows as one commit,
  and the tag is cut on that commit. The battery ran in a clean clone of the branch, named `LibKa0s`,
  because the runner needs a `.git` directory and the worktree's `.git` is a file.
- **Previous run:** [`20261114-153100`](../20261114-153100/) (at `25c3ecd`), v1.101.0's release run.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.103.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.103.0 was verified
across **three** suites, not four. The band count holds at fifteen: `LibKa0s/Widgets.lua` grows from
559 to 924 and stays under the band's floor.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261114-153100 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 347 files | [`lint.txt`](lint.txt) | Yes: 345 -> 347 files |
| tests | pass | 4664 passed, 3 skipped, 0 failed, 4667 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4629 -> 4667 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count, avg tokens |

| Metric | Value |
|---|---|
| Total NLOC | 106062 |
| Functions | 15162 |
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

Against v1.101.0's run, v1.103.0:

- **Widgets minor 27** (Widgets key 26.1.6.13.7.8.5 -> 27.1.6.13.7.8.5): `W.Footer` and `W.FOOTER`
  (a window's 24 px footer with no fill, a divider hairline, two `text.muted` lines, a mark slot and
  the resize grip's corner through `Core.MakeResizable`'s `gripParent`), and the mode strip's docking
  (`opts.dock`, `W.DockTestStrip`: under a title bar, or on a HUD's top edge with the flip), with
  `Place`, `BodyOffset` and `IsFlipped`. No other minor, no `NEEDS_*` floor and no kit revision
  moves (56). No skin token and no Skin facade member is added.
- **Contract changes**: none for a host that changes nothing; an undocked strip is minor 26's. The
  major's member manifest gains `Footer`, `FOOTER` and `DockTestStrip`, which a host's Widgets stub
  owes at its re-vendor.
- Lint: 345 -> 347 files, the new `tests/test_widgets_footer.lua` and
  `tests/test_widgets_teststrip_dock.lua`. Tests: 4629 -> 4667 (38 cases). The three skips are still
  declared skips, not passes.
- Complexity: NLOC 105298 -> 106062 and functions 15013 -> 15162; avg tokens 60.6 -> 60.5; avg NLOC,
  avg CCN and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| under the band | `LibKa0s/Widgets.lua` | 924 | Grown 559 -> 924 with the footer and the docking, 76 under the floor. Its seams if it grows: the footer section, or the strip and its docking, each to a secondary paired on the shell |
| 1000–1500 (on notice) | the fifteen files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Carried forward unchanged; none was touched |

Fifteen, nothing over 1500.

## Preview and simulation data

- **Answer:** Refreshed
- **Asked:** 2026-11-15, by hand
- **Files reviewed:** `tests/test_widgets_teststrip.lua` (unchanged, green: an undocked strip is minor
  26's), the new `tests/test_widgets_teststrip_dock.lua`, `tests/fixture_sim_panel.lua` and the
  `tests/test_sim_*.lua` suites (untouched: no Sim minor moves), and the new
  `docs/api/Widgets/version-27.1.6.13.7.8.5-docs.md`
- **Commits since the previous release touching them:** 1 (`fd70cbd`, Widgets minor 27)
- **Note:** the docking changes where every host's test and sim strips sit (WowAddonStandards
  v2.110.0: under the title bar in a window, on the top edge of a HUD). Every host that draws a strip
  re-looks at its test-mode and sim placement at its re-vendor (step 8).

## Actions

1. Cut the tag `v1.103.0` on the commit that adds this bundle, and merge the branch to master.
2. Step 8: every roster addon with a window or HUD showing test or sim data, or a footer, re-vendors
   this payload and adopts the docking and the Footer (Drop Watcher on `feat/2026-11-14-rolls-ux`).
3. **Owner ruling, the library's own footer:** standalone-windows' *The footer* says a window the
   library draws is the library's to move in the same release; the debug console's status line
   (`LibKa0s/DebugLogWindow.lua`) is not moved in this release. A follow-up release or a register row.
4. **Kit note:** `tests/_kit/run-automated-tests.sh` refuses a git worktree (`[ ! -d .git ]`, where a
   worktree's `.git` is a file), so release runs keep needing a clean clone.
