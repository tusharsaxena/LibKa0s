# Analysis — 20261102-020922

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's fifth local re-cut; the
  manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** ed23709 (`feat/2026-11-01-full-skinning`), clean
- **Previous run:** [`20261102-000358`](../20261102-000358/) (`--release 1.85.0`, at `ca76511`), the
  fourth re-cut, and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261102-000358 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 289 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3918 passed, 3 skipped, 0 failed, 3921 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3909 → 3921 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 86572 NLOC, 12528 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 12462 → 12528 functions; max CCN 15 at both |

The three skips are the previous run's. `test_skin_values` is still a declared skip, not a pass.

## What moved

Against [`20261102-000358`](../20261102-000358/): `SF-L6` to `SF-L8` and `SF-F1`, `SF-F2` of the owner's
smoke feedback (Ka0sAddonsCommonTasks `docs/2026-11-01-SMOKE_FEEDBACK/`), and the `SF-REL` commit that
writes what hosts owe.

- **`Core.lua` minor 15** (new, `docs/api/Core/version-15-docs.md`): `MakeResizable` puts a frame
  anchored to another frame back on its anchor after a drag. No member added.
- **`SkinPaintControls.lua` 16**: `S.Dropdown` handles `WowStyle1DropdownTemplate`.
- **`WidgetsLineChart.lua` 6**: `series[i].fill`, an area fill; the register row for the chart retired.
- **`Widgets.lua` 21**: a right-click on `W.TestStrip` opens `W.ContextMenu` (`opts.sim`, `opts.onEnd`,
  `opts.L`). A strip given neither takes no mouse.
- **`Launcher.lua` 6**: `opts.openSkinPicker` adds Open skin selector to the right-click menu.
- Only Core is a new minor; the others were already moved in this unshipped release, so they did not bump.
- **The band** is eleven files, up from nine: `LibKa0s/SkinPaintControls.lua` (1027) and
  `LibKa0s/Widgets.lua` (1037) crossed 1000 with these commits, and nothing is over 1500. Their
  dispositions are not written: an agent of this run does not edit `CLAUDE.md`, so the next
  sync-docs pass owes both rows, with `OptionsSkinPicker.lua`'s and the rest from the last re-cut.
  No function above CCN 15 was added.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Eleven, nothing over 1500, two newly crossed (above).

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-02, the lead's call under the owner's run guidelines, standing for this re-cut;
  the owner was not asked
- **Files reviewed:** `Widgets.lua` moved (`lib.TestStrip` gained a right-click menu, `SF-F1`) and
  `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua` and `SimPanelRender.lua` did not; the strip tests
  (`tests/test_widgets_teststrip.lua`, four cases added) and every `tests/test_sim_*.lua` ran green here
- **Effect:** none by default. A strip draws and lays out as before; it takes the mouse only when a
  host passes `sim` or `onEnd`, so no existing preview or simulation changes until a host opts in.

## Actions

1. The local annotated tag `v1.85.0` is deleted and re-cut on the commit that adds this bundle. It was
   never pushed. The branch push, the merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer on the run's branch. What hosts owe is one list
   in `docs/releasing.md` (`openSkinPicker`, `onEnd` and `sim`).
3. In-client smoke is the owner's and none is marked passed here.
