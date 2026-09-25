# Analysis — 20260925-170346

- **Addon:** LibKa0s 1.58.0 → 1.59.0 (release run, `--release 1.59.0`)
- **Verdict:** green
- **Commit:** e8faa5d (`feat/2026-09-25-draghandle-close`), clean
- **Previous run:** 20260924-234934 (1.57.0 → 1.58.0)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.59.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.59.0 was verified across **three** suites, not four. The run
measured one change, `WidgetsDragHandle.lua` minor 3 (`LibKa0s-Widgets-1.0` 10.3, an opt-in close
mark on `DragHandle`, AuraMaster feedback batch 8 `CX-1`), and there are 11 more cases than at
v1.58.0's release run. Nothing to act on in this repository.

`addonVersion` reads `1.58.0` because a library repo has no TOC and the runner falls back to the
newest tag; `release` is the field that names the version this bundle records.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260924-234934 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 93 files | [`lint.txt`](lint.txt) | No: 93 files, still 0/0 |
| tests | pass | 1676 passed, 1 skipped, 0 failed, 1677 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +11 cases (1666 → 1677) |
| perf | skip | not measured — no `tests/perf.lua` | — | No. |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Totals up, averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 34348 |
| Functions | 4820 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 2.0 |
| Max CCN | 15 |
| Avg tokens / function | 51.9 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 2 |

**`perf` was not measured.** The manifest's `skipReason` is *no tests/perf.lua — this addon ships no
offline scenarios*: `automated-tests-§3`'s first sanctioned reason, nothing to run. It is a known
hole in this repository's gate, not a pass, and the `CHANGELOG.md` block says so in its
release-notes line.

**`tests` carries one skip**, the same one as the previous run: the kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row and
`tests/test_prose.lua` runs in its place ([`tests.txt`](tests.txt), line 1). It is counted in the
total and not in `passed`.

## What moved

- **lint**: unchanged at 93 files, 0/0. No file was added; the two changed Lua files were already in
  the checked set.
- **tests**: 1666 → 1677. `tests/test_widgets_draghandle.lua` gains eleven cases (35 → 46) and loses
  none: one pins, as literals, that a spec with no `onClose` draws exactly the minor-2 strip (two
  frames, a reserve of 29, the label bounds, `Measure()` 88, the help mark's geometry and every
  `DRAG_HANDLE` value); one checks the minor; nine cover the X (geometry, fallback art, the
  symmetric reserve and its clearance, left and right click, left-only registration, drag
  pass-through, hover tint and tooltip, a cursor owner, a strip whose `?` could not be built)
  ([`test-cases.md`](test-cases.md)).
- **complexity**: NLOC 34110 → 34348 and functions 4787 → 4820; avg NLOC 6.6 and avg CCN 2.0 do not
  move, avg tokens 51.8 → 51.9, max CCN stays 15 with 0 warnings. The growth is `dhBuildClose`,
  `dhReserve` and `handle:Reserve()` in `LibKa0s/WidgetsDragHandle.lua` (520 → 621 lines) and the
  new cases in `tests/test_widgets_draghandle.lua` (683 → 901). Neither file is in the band, and
  band and over-cap counts are unchanged (13 and 2).

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None warned on at this run.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | the thirteen files in `RESULTS.md` | unchanged | Carried forward; no file entered or left the band and none moved. |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua`, `tests/test_options_widgets.lua` | 3852, 4086 | Carried forward (census rows #32, #33). |

No entry is new, so no Disposition cell in `RESULTS.md` is blank: the runner carried every one
forward verbatim, and this release touches none of the files they name.

## Consumer note

A `DragHandle` host that passes no `onClose` draws the same pixels and registers the same clicks as
at v1.58.0, which the literal-pin case above holds; ConsumableMaster, KickCD and AbsorbTracker need
nothing but the copy on their next re-vendor. AuraMaster adopts the X in batch 8 (`CX-3`), and its
`tests/test_anchors.lua` hard-codes the strip's reserve as `RESERVE2 = 58`, which becomes 94 with an
X (`2 * (29 + 18)`) and should read `handle:Reserve()` instead.

## Actions

None in this repository. The AuraMaster re-vendor and adoption is batch 8's `CX-3`.
