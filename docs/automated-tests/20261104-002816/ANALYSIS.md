# Analysis — 20261104-002816

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's seventeenth local re-cut, `R6-REL`
  after `R6-L1`; the manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** `4fd5b47` (`feat/2026-11-01-full-skinning`), clean, the round 6 hosts-owe line: nothing but this
  record follows it
- **Previous run:** [`20261104-002116`](../20261104-002116/) (at `62ba52f`), the same re-cut's first battery,
  which found one function over CCN 15. The baseline for *What moved* below is the sixteenth re-cut,
  [`20261103-200402`](../20261103-200402/) (at `875c89c`).

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are 0.
**Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.85.0 was verified across
**three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261103-200402 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 297 files | [`lint.txt`](lint.txt) | Yes: 296 -> 297 files (one new suite) |
| tests | pass | 4053 passed, 3 skipped, 0 failed, 4056 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4033 -> 4056 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 89503 NLOC, 12937 functions, avg NLOC 6.8, avg CCN 2.1, avg tokens 59.8, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 89063 -> 89503 NLOC, 12871 -> 12937 functions; averages unchanged; max CCN 15 at both |

The totals rose because the library grew (`R6-L1`'s preview contract and its suite); the averages did
not move, so this is not a density signal. The three skips are the previous runs': the declined kit
prose gate, the diagnostics opt-out case and `test_skin_values`, which is still a declared skip, not a
pass.

One battery between the first and this one, `20261104-002602` at `4fd5b47`, went red on a single case,
`eol: every tracked file carries the terminator .gitattributes declares for it`: the first battery's
`ANALYSIS.md` had been written to disk with bare LF where `.gitattributes` declares CRLF. The file was
repaired with `rm` and `git checkout --` (28 CR for 28 LF), that run's bundle and `RESULTS.md` row were
not kept, and the battery ran again on the same commit: this one. No code changed between them.

## What moved

Against [`20261103-200402`](../20261103-200402/): the owner's sixth smoke round (Ka0sAddonsCommonTasks
`docs/2026-11-03-SMOKE_ROUND6/`, the lead's call 1 in its `00_PLAN.md`, the owner's images 62, 63 and 66).

- **`R6-L1`, OptionsSkinPicker minor 11** (`14fcbab`, and the independent review's fix `62ba52f`):
  `spec.preview = { mode, enter, exit, isActive, isShown }`. A fresh show with the surface hidden and
  the mode off enters the mode; the eye toggles it, lit or dimmed, with a tooltip per mode and state;
  every close route restores what the picker and its eye moved. `spec.onPreview` alone keeps the
  one-shot eye. The review's fix rewords the tooltip an eye click leaves shown.
- **`R6-REL`** (`043b5b8`): `paintEye`, measured at CCN 18 by the first battery, split under the cap
  with no behavior change (the tooltip's wording to `eyeTip`); still minor 11, which no host vendors.
- Keys: Options 37.4.44.2.7.2.9.15.2.4.18.13.5.5.7.6.11.1.1.4; Skin 16.1.27.8.18.17.17.4.9, Widgets
  22.5.12.6.7.5, DebugLog 22.6.1.4, Perf 15.1.1.13, Sim 2.3.10.3 and Toast 3 unchanged; kit revision 50,
  no kit file moved.
- Tests: 23 cases more, 4056 total, in one new suite (`tests/test_options_skin_picker_preview.lua`) and
  the moved minor pin in `tests/test_options_skin_picker.lua`.

## Complexity watch list

### Functions the complexity suite warned on

None. `paintEye` is under the cap after the split.

### Files by `layout-§1` band

Fourteen, the same fourteen, nothing over 1500, none came in or left. `LibKa0s/OptionsSkinPicker.lua`
grew 1372 -> 1493 (`R6-L1`'s preview contract and its notes, the review's fix, then the split's
helper): **its 1400 re-check trigger fired**, 7 lines under the cap. This re-cut carries it unpeeled;
the peel on its named seam, the queue, is a new shipped file and a change to every host's pinned load
list, so `CLAUDE.md`'s census row leaves it to the lead and the owner, and its Disposition cell in
RESULTS.md now says so. The independent review recorded the same: the queue peel is owed before any
further picker change. No other band file moved.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-04, the lead's call under the owner's run guidelines; the owner was not asked
- **Files reviewed:** only `OptionsSkinPicker.lua` moved. No `Sim.lua`, `SimTimeline.lua`, `SimPanel.lua`,
  `SimPanelRender.lua` or `Widgets.lua` moved, and `lib.TestStrip` did not move. Every
  `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua` ran green. No scenario, step, control or
  strip changes, so step 5 names no hosts.

## Actions

1. The local annotated tag `v1.85.0` is re-cut on the commit that adds this bundle. It was never
   pushed. The merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer (`R6-RV`). What hosts owe is the `R6-L1`
   paragraph of `docs/releasing.md`'s hosts-owe list, closed by the `R6-REL` line: nothing in the
   re-vendor commit itself over the round 5 cut; then each host's `R6-PV` item, `spec.preview` per the
   round's mode table, with one smoke check per host.
3. The OptionsSkinPicker peel (the queue), whose trigger fired, and the SkinPaintExtras and
   SkinPaintControls peels are the lead's and the owner's call.
4. In-client smoke is the owner's and none is marked passed here.
