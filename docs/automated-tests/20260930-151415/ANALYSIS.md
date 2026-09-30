# Analysis — 20260930-151415

- **Addon:** LibKa0s 1.64.0 (release run, `--release 1.64.0`; the manifest's `addonVersion` reads
  1.63.0, the newest tag at the time of the run, because the tag this bundle is for is cut after it)
- **Verdict:** green
- **Commit:** db21b60 (`feat/2026-09-30-debug-logs-and-resize`), clean
- **Previous run:** 20260930-084657 (1.63.0, release run, at `06cc010`)

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.64.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, and `complexity.warnings` is 0. **Perf was not measured**: this repository
ships no `tests/perf.lua`, so v1.64.0 was verified across **three** suites, not four.

This is the v1.64.0 release run, and the one the tag is cut from. The release is the library's half
of the 2026-09-30 resizable-windows item: Core minor 9's `MakeResizable`, the debug console
(DebugLog 15), every copy window (Widgets 11) and the perf panel (PerfPanel 6) resizable, and kit
revision 33's `mock_resize.lua`. Two earlier release runs of this version were taken and discarded
uncommitted, each followed by a fix commit before this one: lizard's Lua reader reads `#` as a line
comment, which hid `consoleMinWidth` and three test helpers from the complexity record (`0687d64`),
and `buildCopyFrame` had reached CCN 14 with the resize wiring inline (`db21b60`, now 12).

## Suites

| Suite | Status | Result | Artifact | Moved since 20260930-084657 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 127 files | [`lint.txt`](lint.txt) | Yes: 123 → 127 files, four new, all clean |
| tests | pass | 1817 passed, 1 skipped, 0 failed, 1818 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 1778 → 1818 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: totals up, averages flat |

| Metric | Value |
|---|---|
| Total NLOC | 37273 |
| Functions | 5211 |
| Avg NLOC / function | 6.6 |
| Avg CCN | 1.9 |
| Max CCN | 15 |
| Avg tokens / function | 51.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 10 |
| Files over the 1500 cap | 0 |

**`perf` was not measured.** The manifest's `skipReason` is *no tests/perf.lua — this addon ships no
offline scenarios*: `automated-tests-§3`'s first sanctioned reason, nothing to run. It is a known
hole in this repository's gate, not a pass, and the `CHANGELOG.md` block says so in its
release-gate line.

**`tests` carries one skip**, the same one as the previous run: the kit's own
`tests/_kit/test_prose.lua` is declined under `CLAUDE.md`'s `localization-§5` deviation row and
`tests/test_prose.lua` runs in its place ([`tests.txt`](tests.txt), line 1).

## What moved

- **lint**: four more files in scope, `testkit/mock_resize.lua` and the three new suites
  (`tests/test_core_resize.lua`, `tests/test_resize_windows.lua`, `tests/test_mock_resize.lua`), each
  `OK` in [`lint.txt`](lint.txt). Still 0/0.
- **tests**: 1778 → 1818, all forty from the three new suites in
  [`test-cases.md`](test-cases.md): `test_core_resize.lua` 14, `test_resize_windows.lua` 20 and
  `test_mock_resize.lua` 6. One existing case is renamed, the kit pin in
  `tests/test_kit_inventory.lua` ("the kit is revision 33", was 32). No case was removed.
- **complexity**: NLOC 36639 → 37273 and functions 5099 → 5211, the new helper, its callers and the
  three suites. The averages did not get denser: avg NLOC 6.6 (unchanged), avg CCN 2.0 → 1.9, avg
  tokens 51.7 → 51.6. Max CCN is 15, reached by the same six functions as the previous run
  (`lib.Catalog`, `lib.GetSpellCooldown`, `idHelpIcon`, `liveTimers`, `M.__fire`, `audit`), none
  warned on. The new functions' highest is `lib.MakeResizable` at CCN 10; `buildCopyFrame` is 12, as
  it was ([`complexity.txt`](complexity.txt)).
- **band**: still 10 files, 0 over the cap. Two band entries grew: `LibKa0s/Widgets.lua` 1266 → 1298
  and `testkit/mock_base.lua` 1454 → 1456.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua`, `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsTabs.lua`, `LibKa0s/OptionsWidgets.lua`, `LibKa0s/Perf.lua`, `tests/test_options.lua`, `tests/test_schema.lua` | 1261, 1193, 1358, 1293, 1422, 1319, 1339, 1335 (unchanged) | Carried forward verbatim in `RESULTS.md`. |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1298 | Still issue #36. Cell extended in `RESULTS.md` with the 1266 → 1298 step (minor 11's resizable copy window). |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1456 | Re-read at this run: 44 lines from breach, under its 1490 trigger, and the change added 2 lines, under its 30-line trigger. The new recorders went to their own file, `testkit/mock_resize.lua`, which is the rule the cell states. Cell updated in `RESULTS.md`. |

## Consumer note

A consumer re-vendors both payloads whole (`libs/LibKa0s/` and `tests/_kit/`; a kit copy missing
`mock_resize.lua` fails at load) and rolls its provenance line, in one commit. A Core degradation
stub under a by-name `assertSurfaceParity` case gains `MakeResizable`, a function answering `nil`,
or names it in that case's `ignore` list. `IsResizable()`, `IsUserPlaced()` and `GetResizeBounds()`
on a mock frame now answer real values. See the `CHANGELOG.md` v1.64.0 block, *What a consumer owes*.

## Actions

1. Cut the local annotated tag `v1.64.0` on the commit that adds this bundle (not pushed; the push
   and the branch's merge wait on the owner).
2. In-game, not measurable here: resize each window, `/reload`, and confirm the default size is back,
   for a window that was dragged first and one that was not. That is when the client applies its
   layout cache, which no headless suite can see (the Core version-9 document). Owned by each
   consumer's smoke checks (`DL-<XX>-01`).
