# Analysis — 20260930-153012

- **Addon:** LibKa0s 1.64.0 (release run, `--release 1.64.0`)
- **Verdict:** green
- **Commit:** 7b4fbe8 (`feat/2026-09-30-debug-logs-and-resize`), clean
- **Previous run:** 20260930-151415 (1.64.0, release run, at `db21b60`)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.64.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.64.0 was verified across **three** suites, not four.

This run supersedes 20260930-151415 as the v1.64.0 release record, and the tag moves to the commit
that adds it. Between the two, an independent review of `DL-LIB-01` found two places where Core
minor 9's grip (16 px square, 1 px in, ten levels above the window) sat on another control, and
`7b4fbe8` (`DL-LIB-01R`) fixed both: the debug console's line counter drew its last digits under the
grip at its 10 px right inset, now 22 px; and the copy window's scroll frame, at a 10 px bottom inset,
left the lower part of `UIPanelScrollFrameTemplate`'s scroll-down button under the grip, so a click
there started a resize. That inset is now 18 px. The earlier bundle stays as it was, frozen.

## Suites

| Suite | Status | Result | Artifact | Moved since 20260930-151415 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 127 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 1819 passed, 1 skipped, 0 failed, 1820 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 1818 → 1820 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: totals up, averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 37339 |
| Functions | 5221 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 1.9 |
| Max CCN | 15 |
| Avg tokens / function | 51.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 10 |
| Files over the 1500 cap | 0 |

**`perf` was not measured**, for the same sanctioned reason as the previous run (`automated-tests-§3`,
nothing to run). **`tests` carries one skip**, the same one: the kit's own `tests/_kit/test_prose.lua`
is declined under `CLAUDE.md`'s `localization-§5` deviation row.

## What moved

- **tests**: 1818 → 1820, both in `tests/test_resize_windows.lua`: "the line counter sits clear of
  the grip" and "the scroll bar's down button sits above the grip". Each measures the grip's reach
  from the anchor and size Core actually gave it, and each was confirmed red with its inset put back
  to 10. No case was renamed or removed.
- **complexity**: NLOC 37273 → 37339 and functions 5211 → 5221, the two cases and their helpers
  (`recordPoints`, `offsets`, `gripReach`). Averages unchanged; max CCN 15, the same six functions,
  none warned on.
- **band**: still 10 files, 0 over the cap. `LibKa0s/Widgets.lua` 1298 → 1303 (the named inset and
  its comment); its `RESULTS.md` cell is extended with that step.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `LibKa0s/Perf.lua`, `testkit/mock_base.lua`, `tests/test_options.lua`, `tests/test_schema.lua` | unchanged | Carried forward verbatim in `RESULTS.md`. |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1303 | Still issue #36. Cell extended in `RESULTS.md` with the 1298 → 1303 step. |

## Consumer note

Unchanged from the previous run: see the `CHANGELOG.md` v1.64.0 block, *What a consumer owes*. The two
insets are visual only and move no member, descriptor field or string.

## Actions

1. Move the local annotated tag `v1.64.0` to the commit that adds this bundle (not pushed; the push
   and the branch's merge wait on the owner).
2. In-game, not measurable here: resize each window, `/reload`, and confirm the default size is back,
   dragged and undragged; and confirm the console's line counter and the copy window's scroll-down
   button are both clear of the grip. Owned by each consumer's smoke checks (`DL-<XX>-01`).
