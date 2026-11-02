# Analysis — 20261102-235338

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's ninth local re-cut, `R3-REL`; the
  manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** `8582037` (`feat/2026-11-01-full-skinning`), clean, the R3-REL hosts-owe commit: nothing but this record follows it
- **Previous run:** [`20261102-130954`](../20261102-130954/) (at `0d6babe`), the eighth re-cut, and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0 and max CCN is 15. **Perf was not measured**: this
repository ships no `tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261102-130954 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 291 files | [`lint.txt`](lint.txt) | Yes: 290 → 291 files (`tests/test_skin_ace_dropdown.lua`) |
| tests | pass | 3949 passed, 3 skipped, 0 failed, 3952 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3931 → 3952 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 87214 NLOC, 12601 functions, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | Yes: 86744 → 87214 NLOC, 12555 → 12601 functions; max CCN 15 at both |

The three skips are the previous run's: the declined kit prose gate, the diagnostics opt-out case and
`test_skin_values`, which is still a declared skip, not a pass.

## What moved

Against [`20261102-130954`](../20261102-130954/) (which this run supersedes as the gate record): the
owner's third smoke round (Ka0sAddonsCommonTasks `docs/2026-11-02-SMOKE_ROUND3/`) and its fonts addendum.
No file minor moved: every file touched was already above its v1.84.0 minor in this unshipped release.

- **`R3-DR-1L`**: `S.HudFont`, `S.Text` and the face-giving primitives hold the skin's face on a string
  given its own `SetFont` first (DpsRace's clocks). Kit revision 50's `mock_paint.lua` keeps a string's
  own font, as the client does.
- **`R3-L1`**: AceGUI Dropdown and the `Ka0sMedia_*` pickers wear the skinned WowStyle1 dropdown
  (`tests/test_skin_ace_dropdown.lua`, new).
- **`R3-L2`**, **`R3-L3`**: `S.FadeNineSlice` draws a 1 px edge in every skin; `S.IconBorder` draws a
  1 px outline in every skin and zooms the icon 0.07.
- **`R3-L4`**, **`R3-L5`**: Obsidian's body at 12, and every dark skin's `list.stripe` at least 8% off
  its window.
- **`R3-L6`**, **`R3-L7`**: `Ka0s Ubuntu` (static Ubuntu Regular, UFL 1.0) is WoW Default's face, and
  `Ka0s Friz Quadrata TT` leaves the payload; `Skin.RETIRED_FONTS` moves a stored override of it to
  Ubuntu. A new font file needs a full client restart before the owner's smoke.
- Tests: 21 cases more, 3952 total.

## Complexity watch list

### Functions the complexity suite warned on

None.

### Files by `layout-§1` band

Thirteen, nothing over 1500, against eleven at the previous run. Two came in:
`LibKa0s/SkinPaintExtras.lua` (1031) and `tests/test_media.lua` (1010), each ruled *accepted* in
`CLAUDE.md`'s band census with a seam and a re-check trigger, and both dispositions are filled in
[`RESULTS.md`](../RESULTS.md). `LibKa0s/SkinPaintControls.lua` (1054) now carries its census ruling
there too. `LibKa0s/Widgets.lua` (1037) did not move in this round and its cell stays blank, as at
the previous two runs: it is unruled, and that is stated here rather than filled in. `LibKa0s/Skin.lua`
is at 1097, 3 under its 1100 trigger.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-02, the lead's call under the owner's run guidelines; the owner was not asked
- **Files reviewed:** no `Sim*.lua`, `Widgets.lua` or `Launcher.lua` moved in this re-cut; every
  `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua` ran green

## Actions

1. The local annotated tag `v1.85.0` is re-cut on the commit that adds this bundle. It was never
   pushed. The branch is pushed; the merge to `master` and the tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer (`R3-RV`, `R3-FRIZ`). What hosts owe is one
   list in `docs/releasing.md`, the smoke round 3 paragraph.
3. In-client smoke is the owner's and none is marked passed here.
